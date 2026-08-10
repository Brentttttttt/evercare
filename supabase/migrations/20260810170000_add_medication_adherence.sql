-- Add weekday scheduling and per-occurrence adherence state without changing
-- or inferring meaning from the legacy free-text frequency column.

alter table public.medications
  add column schedule_days smallint[] not null default '{}'::smallint[],
  add column completed_at timestamptz,
  add constraint medications_schedule_days_valid_check check (
    array_position(schedule_days, null) is null
    and schedule_days <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]
    and cardinality(schedule_days) =
      (case when 1 = any(schedule_days) then 1 else 0 end) +
      (case when 2 = any(schedule_days) then 1 else 0 end) +
      (case when 3 = any(schedule_days) then 1 else 0 end) +
      (case when 4 = any(schedule_days) then 1 else 0 end) +
      (case when 5 = any(schedule_days) then 1 else 0 end) +
      (case when 6 = any(schedule_days) then 1 else 0 end) +
      (case when 7 = any(schedule_days) then 1 else 0 end)
  ),
  add constraint medications_completed_inactive_check check (
    completed_at is null or is_active = false
  );

comment on column public.medications.schedule_days is
  'Selected ISO weekdays (Monday=1 through Sunday=7). An empty array means a legacy or unconfirmed schedule; the EverCare form requires at least one day for new and updated records.';

comment on column public.medications.completed_at is
  'When the user manually marked the medication course as done. Completed medications must be inactive; historical dose events remain unchanged.';

alter table public.medication_dose_events
  drop constraint medication_dose_events_status_check,
  add constraint medication_dose_events_status_check check (
    status in ('scheduled', 'taken', 'missed', 'skipped')
  );

comment on column public.medication_dose_events.status is
  'Per-occurrence state. EverCare marks an unresolved scheduled dose as missed once it is at least one hour overdue during an in-app adherence sync.';

-- The unique occurrence index is required for idempotent client upserts. Stop
-- with a clear error instead of silently deleting or merging health history if
-- an older integration has already inserted duplicate occurrences.
do $$
declare
  duplicate_occurrence record;
begin
  select
    medication_id,
    scheduled_for,
    count(*) as duplicate_count
  into duplicate_occurrence
  from public.medication_dose_events
  group by medication_id, scheduled_for
  having count(*) > 1
  order by medication_id, scheduled_for
  limit 1;

  if found then
    raise exception using
      errcode = '23505',
      message = format(
        'Cannot add medication occurrence uniqueness: medication %s has %s dose events scheduled for %s.',
        duplicate_occurrence.medication_id,
        duplicate_occurrence.duplicate_count,
        duplicate_occurrence.scheduled_for
      ),
      hint = 'Review and resolve duplicate medication_dose_events rows before applying this migration; no health-history rows were changed.';
  end if;
end;
$$;

create unique index medication_dose_events_medication_schedule_unique_idx
  on public.medication_dose_events(medication_id, scheduled_for);

create index medication_dose_events_user_overdue_idx
  on public.medication_dose_events(user_id, scheduled_for)
  where status = 'scheduled';

-- Existing table ownership, authenticated grants, and row-level security
-- policies apply to these additions unchanged.
