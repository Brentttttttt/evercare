// Bounded source invariants, not a replacement for deployed Storage/RLS tests.
const migrationUrl = new URL(
  "../migrations/20260923090000_profile_picture_storage.sql",
  import.meta.url,
);

function normalizedSql(source: string): string {
  return source.replace(/--[^\n]*/g, "").replace(/\s+/g, " ").trim()
    .toLowerCase();
}

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("profile picture bucket is private with a bounded image allowlist", async () => {
  const sql = normalizedSql(await Deno.readTextFile(migrationUrl));
  assert(
    /insert into storage\.buckets \( id, name, public, file_size_limit, allowed_mime_types \) values \( 'profile-pictures', 'profile-pictures', false, 5242880, array\['image\/jpeg', 'image\/png', 'image\/webp'\] \)/
      .test(sql),
    "Bucket must remain private, limited to 5 MiB, and restricted to JPEG/PNG/WebP.",
  );
  assert(
    sql.includes("on conflict (id) do update set public = false,"),
    "An existing bucket must not retain public visibility.",
  );
});

Deno.test("profile pictures have exactly owner-scoped insert/select/delete policies", async () => {
  const sql = normalizedSql(await Deno.readTextFile(migrationUrl));
  const policies = [...sql.matchAll(/create policy [\s\S]+?;/g)].map((match) =>
    match[0]
  );
  assert(policies.length === 3, "Expected three explicit Storage policies.");
  for (const command of ["insert", "select", "delete"]) {
    const matches = policies.filter((policy) =>
      policy.includes(`on storage.objects for ${command} to authenticated `)
    );
    assert(
      matches.length === 1,
      `Expected one authenticated ${command} policy.`,
    );
    assert(
      matches[0].includes("bucket_id = 'profile-pictures'"),
      `${command} must be limited to the profile-pictures bucket.`,
    );
    assert(
      matches[0].includes(
        "(storage.foldername(name))[1] = (select auth.uid())::text",
      ),
      `${command} must check the signed-in user's folder.`,
    );
  }
  assert(
    !/on storage\.objects for (update|all)\b/.test(sql),
    "Overwrites must not be permitted.",
  );
});

Deno.test("profile photo migration preserves existing profiles and unrelated policies", async () => {
  const sql = normalizedSql(await Deno.readTextFile(migrationUrl));
  assert(
    !/\b(alter|update|insert into|delete from|drop)\s+(table\s+)?public\.profiles\b/
      .test(sql),
    "The photo migration must not alter or rewrite profile records.",
  );
  assert(
    !/\b(drop policy|grant|truncate|delete from)\b/.test(sql),
    "The migration must not remove existing policies/data or add broad grants.",
  );
  assert(
    !/\b(add column|create table)\b/.test(sql),
    "Use the existing avatar_path column; do not add a duplicate schema.",
  );
});

Deno.test("repository Storage policies do not include unscoped or public object grants", async () => {
  const directory = new URL("../migrations/", import.meta.url);
  let storagePolicies = 0;
  for await (const file of Deno.readDir(directory)) {
    if (!file.isFile || !file.name.endsWith(".sql")) continue;
    const sql = normalizedSql(
      await Deno.readTextFile(new URL(file.name, directory)),
    );
    for (const match of sql.matchAll(/create policy [\s\S]+?;/g)) {
      const policy = match[0];
      if (!policy.includes("on storage.objects ")) continue;
      storagePolicies++;
      assert(
        policy.includes("to authenticated "),
        `${file.name}: object policy must require authentication.`,
      );
      assert(
        /bucket_id = '(journal-photos|profile-pictures)'/.test(policy),
        `${file.name}: object policy must target an explicitly private bucket.`,
      );
      assert(
        policy.includes("(storage.foldername(name))[1] = "),
        `${file.name}: object policy must check the owner folder.`,
      );
      assert(
        policy.includes("auth.uid()"),
        `${file.name}: object policy must bind the authenticated owner.`,
      );
    }
  }
  assert(
    storagePolicies >= 6,
    "Expected the journal and profile picture policies to be inspected.",
  );
});
