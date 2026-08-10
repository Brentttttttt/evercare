-- Keep adherence mutations authoritative on the database clock. The Flutter
-- UI derives responsive in-app states, while these functions validate the
-- final Taken, Missed, and course-completion writes under existing RLS.

do $$
begin
  if exists (
    select 1
    from public.medication_dose_events
    where (status = 'taken' and taken_at is null)
       or (status <> 'taken' and taken_at is not null)
  ) then
    raise exception using
      errcode = '23514',
      message = 'Medication dose events contain inconsistent status and taken_at values.',
      hint = 'Review the inconsistent medication_dose_events rows before applying this migration; no adherence history was changed.';
  end if;
end;
$$;

alter table public.medication_dose_events
  add constraint medication_dose_events_taken_consistency_check check (
    (status = 'taken' and taken_at is not null)
    or (status <> 'taken' and taken_at is null)
  );

create or replace function public.record_medication_dose_taken(
  p_medication_id uuid,
  p_scheduled_for timestamptz
)
returns public.medication_dose_events
language plpgsql
security invoker
set search_path = ''
as $$
declare
  result public.medication_dose_events;
begin
  if p_scheduled_for > now() then
    raise exception using
      errcode = '22007',
      message = 'A future medication dose cannot be marked as taken.';
  end if;

  if p_scheduled_for < now() - interval '7 days' then
    raise exception using
      errcode = '22007',
      message = 'This medication occurrence is too old to update in the daily reminder.';
  end if;

  if not exists (
    select 1
    from public.medications
    where id = p_medication_id
      and user_id = (select auth.uid())
  ) then
    raise exception using
      errcode = '42501',
      message = 'The medication is unavailable for the signed-in user.';
  end if;

  insert into public.medication_dose_events (
    user_id,
    medication_id,
    scheduled_for,
    taken_at,
    status
  ) values (
    (select auth.uid()),
    p_medication_id,
    p_scheduled_for,
    now(),
    'taken'
  )
  on conflict (medication_id, scheduled_for) do update
    set status = 'taken',
        taken_at = now()
    where medication_dose_events.user_id = (select auth.uid())
  returning * into result;

  if result.id is null then
    raise exception using
      errcode = '42501',
      message = 'The medication dose could not be updated by this user.';
  end if;

  return result;
end;
$$;

create or replace function public.record_medication_dose_missed(
  p_medication_id uuid,
  p_scheduled_for timestamptz
)
returns public.medication_dose_events
language plpgsql
security invoker
set search_path = ''
as $$
declare
  result public.medication_dose_events;
begin
  if p_scheduled_for + interval '1 hour' > now() then
    raise exception using
      errcode = '22007',
      message = 'A medication dose cannot be marked missed before one hour has passed.';
  end if;

  if p_scheduled_for < now() - interval '7 days' then
    raise exception using
      errcode = '22007',
      message = 'This medication occurrence is too old to update in the daily reminder.';
  end if;

  if not exists (
    select 1
    from public.medications
    where id = p_medication_id
      and user_id = (select auth.uid())
  ) then
    raise exception using
      errcode = '42501',
      message = 'The medication is unavailable for the signed-in user.';
  end if;

  insert into public.medication_dose_events (
    user_id,
    medication_id,
    scheduled_for,
    taken_at,
    status
  ) values (
    (select auth.uid()),
    p_medication_id,
    p_scheduled_for,
    null,
    'missed'
  )
  on conflict (medication_id, scheduled_for) do update
    set status = 'missed',
        taken_at = null
    where medication_dose_events.user_id = (select auth.uid())
      and medication_dose_events.status = 'scheduled'
  returning * into result;

  if result.id is null then
    select *
    into result
    from public.medication_dose_events
    where medication_id = p_medication_id
      and scheduled_for = p_scheduled_for
      and user_id = (select auth.uid());
  end if;

  if result.id is null then
    raise exception using
      errcode = '42501',
      message = 'The medication dose could not be updated by this user.';
  end if;

  return result;
end;
$$;

create or replace function public.complete_medication(p_medication_id uuid)
returns public.medications
language plpgsql
security invoker
set search_path = ''
as $$
declare
  result public.medications;
begin
  update public.medications
  set is_active = false,
      completed_at = coalesce(completed_at, now())
  where id = p_medication_id
    and user_id = (select auth.uid())
  returning * into result;

  if result.id is null then
    raise exception using
      errcode = '42501',
      message = 'The medication is unavailable for the signed-in user.';
  end if;

  return result;
end;
$$;

revoke execute on function public.record_medication_dose_taken(uuid, timestamptz)
  from public, anon;
revoke execute on function public.record_medication_dose_missed(uuid, timestamptz)
  from public, anon;
revoke execute on function public.complete_medication(uuid)
  from public, anon;

grant execute on function public.record_medication_dose_taken(uuid, timestamptz)
  to authenticated;
grant execute on function public.record_medication_dose_missed(uuid, timestamptz)
  to authenticated;
grant execute on function public.complete_medication(uuid)
  to authenticated;
