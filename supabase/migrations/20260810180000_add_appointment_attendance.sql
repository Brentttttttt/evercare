-- Appointment attendance is reconciled while EverCare is open or resumed.
-- The database clock is authoritative for the 24-hour Missed threshold and
-- for completion timestamps; the client only derives states for responsive UI.

alter table public.appointments
  add column if not exists completed_at timestamptz;

alter table public.appointments
  drop constraint if exists appointments_status_check;

alter table public.appointments
  add constraint appointments_status_check
  check (status in ('upcoming', 'completed', 'missed', 'cancelled'));

alter table public.appointments
  add constraint appointments_completed_at_check
  check (completed_at is null or status = 'completed');

create or replace function public.enforce_appointment_attendance_transition()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.status <> 'upcoming' then
      raise exception using
        errcode = '22000',
        message = 'New appointments must begin as upcoming.';
    end if;
    new.completed_at := null;
    return new;
  end if;

  if new.status = old.status then
    if old.status = 'upcoming'
       and new.starts_at is distinct from old.starts_at
       and old.starts_at <= now() then
      raise exception using
        errcode = '22007',
        message = 'An appointment cannot be rescheduled after its scheduled time.';
    end if;
    -- Ordinary title, schedule, hospital, or notes edits cannot manufacture or
    -- alter an attendance timestamp.
    new.completed_at := old.completed_at;
    return new;
  end if;

  if new.starts_at is distinct from old.starts_at then
    raise exception using
      errcode = '22000',
      message = 'The appointment schedule and attendance status cannot change together.';
  end if;

  if old.status = 'upcoming' and new.status = 'cancelled' then
    if old.starts_at + interval '24 hours' <= now() then
      raise exception using
        errcode = '22007',
        message = 'This appointment is already past the 24-hour missed threshold.';
    end if;
    new.completed_at := null;
    return new;
  end if;

  if old.status = 'upcoming' and new.status = 'missed' then
    if old.starts_at + interval '24 hours' > now() then
      raise exception using
        errcode = '22007',
        message = 'An appointment cannot be marked missed before 24 hours have passed.';
    end if;
    new.completed_at := null;
    return new;
  end if;

  if old.status in ('upcoming', 'missed') and new.status = 'completed' then
    if old.starts_at > now() then
      raise exception using
        errcode = '22007',
        message = 'An appointment cannot be completed before its scheduled time.';
    end if;
    new.completed_at := coalesce(old.completed_at, now());
    return new;
  end if;

  raise exception using
    errcode = '22000',
    message = format(
      'Appointment status cannot change from %s to %s.',
      old.status,
      new.status
    );
end;
$$;

drop trigger if exists appointments_enforce_attendance_transition
  on public.appointments;
create trigger appointments_enforce_attendance_transition
before insert or update on public.appointments
for each row execute function public.enforce_appointment_attendance_transition();

create index if not exists appointments_pending_start_idx
  on public.appointments(user_id, starts_at)
  where status = 'upcoming';

create or replace function public.reconcile_missed_appointments()
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare
  affected bigint;
begin
  update public.appointments
  set status = 'missed'
  where user_id = (select auth.uid())
    and status = 'upcoming'
    and starts_at + interval '24 hours' <= now();

  get diagnostics affected = row_count;
  return affected;
end;
$$;

create or replace function public.complete_appointment(p_appointment_id uuid)
returns public.appointments
language plpgsql
security invoker
set search_path = ''
as $$
declare
  result public.appointments;
begin
  select *
  into result
  from public.appointments
  where id = p_appointment_id
    and user_id = (select auth.uid())
  for update;

  if result.id is null then
    raise exception using
      errcode = '42501',
      message = 'The appointment is unavailable for the signed-in user.';
  end if;

  if result.status = 'cancelled' then
    raise exception using
      errcode = '22000',
      message = 'A cancelled appointment cannot be marked as completed.';
  end if;

  if result.status = 'completed' then
    return result;
  end if;

  if result.starts_at > now() then
    raise exception using
      errcode = '22007',
      message = 'An appointment cannot be completed before its scheduled time.';
  end if;

  update public.appointments
  set status = 'completed',
      completed_at = coalesce(completed_at, now())
  where id = p_appointment_id
    and user_id = (select auth.uid())
    and status in ('upcoming', 'missed')
  returning * into result;

  if result.id is null then
    raise exception using
      errcode = '40001',
      message = 'The appointment changed while it was being updated. Refresh and try again.';
  end if;

  return result;
end;
$$;

create or replace function public.cancel_appointment(p_appointment_id uuid)
returns public.appointments
language plpgsql
security invoker
set search_path = ''
as $$
declare
  result public.appointments;
begin
  select *
  into result
  from public.appointments
  where id = p_appointment_id
    and user_id = (select auth.uid())
  for update;

  if result.id is null then
    raise exception using
      errcode = '42501',
      message = 'The appointment is unavailable for the signed-in user.';
  end if;

  if result.status = 'cancelled' then
    return result;
  end if;

  if result.status <> 'upcoming' then
    raise exception using
      errcode = '22000',
      message = 'A completed or missed appointment cannot be cancelled.';
  end if;

  if result.starts_at + interval '24 hours' <= now() then
    raise exception using
      errcode = '22007',
      message = 'This appointment is already past the 24-hour missed threshold.';
  end if;

  update public.appointments
  set status = 'cancelled'
  where id = p_appointment_id
    and user_id = (select auth.uid())
    and status = 'upcoming'
  returning * into result;

  if result.id is null then
    raise exception using
      errcode = '40001',
      message = 'The appointment changed while it was being updated. Refresh and try again.';
  end if;

  return result;
end;
$$;

revoke execute on function public.reconcile_missed_appointments()
  from public, anon;
revoke execute on function public.complete_appointment(uuid)
  from public, anon;
revoke execute on function public.cancel_appointment(uuid)
  from public, anon;

grant execute on function public.reconcile_missed_appointments()
  to authenticated;
grant execute on function public.complete_appointment(uuid)
  to authenticated;
grant execute on function public.cancel_appointment(uuid)
  to authenticated;
