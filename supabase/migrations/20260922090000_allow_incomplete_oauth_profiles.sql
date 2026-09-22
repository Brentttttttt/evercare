-- OAuth providers do not know how a person uses EverCare. Keep that choice
-- unset until the person supplies it, rather than inventing a Senior role.
-- Existing profile values and the three valid role choices remain unchanged.
alter table public.profiles
  alter column user_type drop not null,
  alter column user_type drop default;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    full_name,
    phone_number,
    birth_date,
    user_type
  )
  values (
    new.id,
    coalesce(
      nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'name'), ''),
      ''
    ),
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'phone_number'), ''),
    public.safe_date(new.raw_user_meta_data ->> 'birth_date'),
    case
      when new.raw_user_meta_data ->> 'user_type'
        in ('senior', 'caregiver', 'family_member')
        then new.raw_user_meta_data ->> 'user_type'
      else null
    end
  )
  -- Automatic identity linking may retain an existing auth user/profile. Never
  -- overwrite that person's chosen role, name, or other profile information.
  on conflict (id) do nothing;
  return new;
end;
$$;

-- This trigger is not a client RPC. Its existing execution privileges are
-- preserved by CREATE OR REPLACE; keep them explicitly restricted as well.
revoke execute on function public.handle_new_user()
  from public, anon, authenticated;
