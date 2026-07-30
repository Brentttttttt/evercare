-- EverCare's initial production schema.
-- This migration intentionally contains no sample patients or health records.

create extension if not exists pgcrypto with schema extensions;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.safe_date(value text)
returns date
language plpgsql
stable
security invoker
set search_path = ''
as $$
begin
  return nullif(pg_catalog.btrim(value), '')::date;
exception
  when invalid_datetime_format or datetime_field_overflow then
    return null;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone_number text,
  birth_date date,
  user_type text not null default 'senior'
    check (user_type in ('senior', 'caregiver', 'family_member')),
  address text,
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medical_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade
    default auth.uid(),
  blood_type text,
  allergies text[] not null default '{}',
  conditions text[] not null default '{}',
  preferred_hospital text,
  medical_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade
    default auth.uid(),
  name text not null check (length(trim(name)) > 0),
  dosage text not null check (length(trim(dosage)) > 0),
  purpose text,
  frequency text,
  instructions text,
  schedule_time time,
  start_date date,
  end_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_date is null or start_date is null or end_date >= start_date)
);

create table public.medication_dose_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade
    default auth.uid(),
  medication_id uuid not null references public.medications(id) on delete cascade,
  scheduled_for timestamptz not null,
  taken_at timestamptz,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'taken', 'skipped')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade
    default auth.uid(),
  title text not null check (length(trim(title)) > 0),
  doctor_name text,
  specialty text,
  starts_at timestamptz not null,
  clinic text,
  address text,
  notes text,
  status text not null default 'upcoming'
    check (status in ('upcoming', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade
    default auth.uid(),
  entry_at timestamptz not null default now(),
  title text not null default '',
  body text not null default '',
  mood text,
  symptoms text[] not null default '{}',
  activities text[] not null default '{}',
  tags text[] not null default '{}',
  bookmarked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (length(trim(title)) > 0 or length(trim(body)) > 0)
);

create table public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade
    default auth.uid(),
  name text not null check (length(trim(name)) > 0),
  relationship text,
  phone_number text not null check (length(trim(phone_number)) > 0),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index emergency_contacts_one_primary_per_user
  on public.emergency_contacts(user_id)
  where is_primary;

create table public.caregiver_relationships (
  id uuid primary key default gen_random_uuid(),
  older_adult_id uuid not null
    constraint caregiver_relationships_older_adult_id_fkey
    references public.profiles(id) on delete cascade,
  caregiver_id uuid not null
    constraint caregiver_relationships_caregiver_id_fkey
    references public.profiles(id) on delete cascade,
  relationship_label text,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'revoked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (older_adult_id <> caregiver_id),
  unique (older_adult_id, caregiver_id)
);

create table public.blood_pressure_readings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade
    default auth.uid(),
  systolic integer not null check (systolic > 0 and systolic <= 350),
  diastolic integer not null check (diastolic > 0 and diastolic <= 250),
  pulse integer not null check (pulse > 0 and pulse <= 300),
  measured_at timestamptz not null,
  source text not null check (source in ('ble', 'manual')),
  monitor_name text,
  decoder_name text,
  raw_packet_hex text,
  capture_metadata jsonb not null default '{}'::jsonb,
  notes text,
  is_medically_verified boolean not null default false
    check (is_medically_verified = false),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade
    default auth.uid(),
  title text not null check (length(trim(title)) > 0),
  body text,
  kind text not null default 'general',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index medications_user_active_idx
  on public.medications(user_id, is_active, schedule_time);
create index medication_dose_events_user_schedule_idx
  on public.medication_dose_events(user_id, scheduled_for desc);
create index appointments_user_start_idx
  on public.appointments(user_id, starts_at desc);
create index journal_entries_user_entry_idx
  on public.journal_entries(user_id, entry_at desc);
create index emergency_contacts_user_idx
  on public.emergency_contacts(user_id, is_primary desc);
create index caregiver_relationships_older_idx
  on public.caregiver_relationships(older_adult_id, status);
create index caregiver_relationships_caregiver_idx
  on public.caregiver_relationships(caregiver_id, status);
create index blood_pressure_readings_user_measured_idx
  on public.blood_pressure_readings(user_id, measured_at desc);
create unique index blood_pressure_readings_unique_ble_result_idx
  on public.blood_pressure_readings(user_id, source, measured_at, raw_packet_hex);
create index notifications_user_created_idx
  on public.notifications(user_id, created_at desc);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();
create trigger medical_profiles_set_updated_at
before update on public.medical_profiles
for each row execute function public.set_updated_at();
create trigger medications_set_updated_at
before update on public.medications
for each row execute function public.set_updated_at();
create trigger medication_dose_events_set_updated_at
before update on public.medication_dose_events
for each row execute function public.set_updated_at();
create trigger appointments_set_updated_at
before update on public.appointments
for each row execute function public.set_updated_at();
create trigger journal_entries_set_updated_at
before update on public.journal_entries
for each row execute function public.set_updated_at();
create trigger emergency_contacts_set_updated_at
before update on public.emergency_contacts
for each row execute function public.set_updated_at();
create trigger caregiver_relationships_set_updated_at
before update on public.caregiver_relationships
for each row execute function public.set_updated_at();
create trigger blood_pressure_readings_set_updated_at
before update on public.blood_pressure_readings
for each row execute function public.set_updated_at();

create or replace function public.prevent_care_connection_party_change()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.older_adult_id <> old.older_adult_id
    or new.caregiver_id <> old.caregiver_id
    or new.relationship_label is distinct from old.relationship_label then
    raise exception 'Care connection participants and label cannot be changed';
  end if;
  return new;
end;
$$;

create trigger caregiver_relationships_keep_parties
before update on public.caregiver_relationships
for each row execute function public.prevent_care_connection_party_change();

create or replace function public.prevent_blood_pressure_capture_change()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
    or new.user_id is distinct from old.user_id
    or new.systolic is distinct from old.systolic
    or new.diastolic is distinct from old.diastolic
    or new.pulse is distinct from old.pulse
    or new.measured_at is distinct from old.measured_at
    or new.source is distinct from old.source
    or new.monitor_name is distinct from old.monitor_name
    or new.decoder_name is distinct from old.decoder_name
    or new.raw_packet_hex is distinct from old.raw_packet_hex
    or new.capture_metadata is distinct from old.capture_metadata
    or new.is_medically_verified is distinct from old.is_medically_verified
    or new.created_at is distinct from old.created_at then
    raise exception 'Saved measurement capture fields cannot be changed';
  end if;
  return new;
end;
$$;

create trigger blood_pressure_readings_keep_capture
before update on public.blood_pressure_readings
for each row execute function public.prevent_blood_pressure_capture_change();

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
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(trim(new.raw_user_meta_data ->> 'phone_number'), ''),
    public.safe_date(new.raw_user_meta_data ->> 'birth_date'),
    case
      when new.raw_user_meta_data ->> 'user_type'
        in ('senior', 'caregiver', 'family_member')
        then new.raw_user_meta_data ->> 'user_type'
      else 'senior'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Backfill a profile if authentication users existed before this migration.
insert into public.profiles (
  id,
  full_name,
  phone_number,
  birth_date,
  user_type
)
select
  id,
  coalesce(raw_user_meta_data ->> 'full_name', ''),
  nullif(trim(raw_user_meta_data ->> 'phone_number'), ''),
  public.safe_date(raw_user_meta_data ->> 'birth_date'),
  case
    when raw_user_meta_data ->> 'user_type'
      in ('senior', 'caregiver', 'family_member')
      then raw_user_meta_data ->> 'user_type'
    else 'senior'
  end
from auth.users
on conflict (id) do nothing;

create or replace function public.get_my_caregiver_relationships()
returns table (
  id uuid,
  caregiver_id uuid,
  status text,
  relationship_label text,
  created_at timestamptz,
  caregiver jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    connection.id,
    connection.caregiver_id,
    connection.status,
    connection.relationship_label,
    connection.created_at,
    case
      when connection.status = 'accepted' then
        pg_catalog.jsonb_build_object(
          'id', caregiver_profile.id,
          'full_name', caregiver_profile.full_name,
          'phone_number', caregiver_profile.phone_number,
          'avatar_path', caregiver_profile.avatar_path
        )
      else null
    end as caregiver
  from public.caregiver_relationships connection
  join public.profiles caregiver_profile
    on caregiver_profile.id = connection.caregiver_id
  where connection.older_adult_id = (select auth.uid())
  order by connection.created_at;
$$;

alter table public.profiles enable row level security;
alter table public.medical_profiles enable row level security;
alter table public.medications enable row level security;
alter table public.medication_dose_events enable row level security;
alter table public.appointments enable row level security;
alter table public.journal_entries enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.caregiver_relationships enable row level security;
alter table public.blood_pressure_readings enable row level security;
alter table public.notifications enable row level security;

create policy "Users can read their own profile"
on public.profiles for select to authenticated
using (id = auth.uid());
create policy "Users can update their own profile"
on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());
create policy "Users can create their own missing profile"
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy "Users own their medical profile"
on public.medical_profiles for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users own their medications"
on public.medications for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users own their medication events"
on public.medication_dose_events for all to authenticated
using (user_id = auth.uid())
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.medications medication
    where medication.id = medication_dose_events.medication_id
      and medication.user_id = auth.uid()
  )
);
create policy "Users own their appointments"
on public.appointments for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users own their journal entries"
on public.journal_entries for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users own their emergency contacts"
on public.emergency_contacts for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users can read their care connections"
on public.caregiver_relationships for select to authenticated
using (older_adult_id = auth.uid() or caregiver_id = auth.uid());
create policy "Care recipients can create care connections"
on public.caregiver_relationships for insert to authenticated
with check (older_adult_id = auth.uid() and status = 'pending');
create policy "Care recipients can revoke care connections"
on public.caregiver_relationships for update to authenticated
using (older_adult_id = auth.uid())
with check (older_adult_id = auth.uid() and status = 'revoked');
create policy "Caregivers can answer care connections"
on public.caregiver_relationships for update to authenticated
using (caregiver_id = auth.uid() and status = 'pending')
with check (
  caregiver_id = auth.uid()
  and status in ('accepted', 'declined')
);
create policy "Both parties can delete care connections"
on public.caregiver_relationships for delete to authenticated
using (older_adult_id = auth.uid() or caregiver_id = auth.uid());
create policy "Users own their blood pressure readings"
on public.blood_pressure_readings for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users read their notifications"
on public.notifications for select to authenticated
using (user_id = auth.uid());
create policy "Users update their notification read state"
on public.notifications for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

revoke all on table
  public.profiles,
  public.medical_profiles,
  public.medications,
  public.medication_dose_events,
  public.appointments,
  public.journal_entries,
  public.emergency_contacts,
  public.caregiver_relationships,
  public.blood_pressure_readings,
  public.notifications
from anon, authenticated;
grant usage on schema public to authenticated;
grant select, insert, update, delete on table
  public.profiles,
  public.medical_profiles,
  public.medications,
  public.medication_dose_events,
  public.appointments,
  public.journal_entries,
  public.emergency_contacts,
  public.caregiver_relationships,
  public.blood_pressure_readings
to authenticated;
grant select on table public.notifications to authenticated;
grant update (is_read) on table public.notifications to authenticated;

revoke execute on function public.set_updated_at()
  from public, anon, authenticated;
revoke execute on function public.safe_date(text)
  from public, anon, authenticated;
revoke execute on function public.prevent_care_connection_party_change()
  from public, anon, authenticated;
revoke execute on function public.prevent_blood_pressure_capture_change()
  from public, anon, authenticated;
revoke execute on function public.handle_new_user()
  from public, anon, authenticated;
revoke execute on function public.get_my_caregiver_relationships()
  from public, anon, authenticated;
grant execute on function public.get_my_caregiver_relationships()
  to authenticated;
