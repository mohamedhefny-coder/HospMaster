-- Pediatric surgery doctors (one waiting list per doctor).
-- Any user with the pediatric_surgery service can read and add doctors;
-- only admins can rename or delete them.
--
-- Run once in the Supabase SQL editor, after 20261118_service_access.sql.

create table if not exists public.pediatric_surgery_doctors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists pediatric_surgery_doctors_name_idx
  on public.pediatric_surgery_doctors (lower(name));

alter table public.pediatric_surgery_doctors enable row level security;

drop policy if exists "pediatric_doctors_select" on public.pediatric_surgery_doctors;
drop policy if exists "pediatric_doctors_insert" on public.pediatric_surgery_doctors;
drop policy if exists "pediatric_doctors_update" on public.pediatric_surgery_doctors;
drop policy if exists "pediatric_doctors_delete" on public.pediatric_surgery_doctors;

create policy "pediatric_doctors_select" on public.pediatric_surgery_doctors
  for select to authenticated
  using (public.has_service('pediatric_surgery'));

create policy "pediatric_doctors_insert" on public.pediatric_surgery_doctors
  for insert to authenticated
  with check (public.has_service('pediatric_surgery'));

create policy "pediatric_doctors_update" on public.pediatric_surgery_doctors
  for update to authenticated
  using (public.is_app_admin())
  with check (public.is_app_admin());

create policy "pediatric_doctors_delete" on public.pediatric_surgery_doctors
  for delete to authenticated
  using (public.is_app_admin());

-- Default doctors, plus every doctor that already has patients.
insert into public.pediatric_surgery_doctors (name, created_at)
values
  ('د. أحمد أبو الحسب', now() - interval '2 seconds'),
  ('د. حمدي السيد', now() - interval '1 second')
on conflict do nothing;

insert into public.pediatric_surgery_doctors (name)
select distinct regexp_replace(btrim(doctor), '^د\.\s*', 'د. ')
from public.pediatric_surgery_waiting_patients
where btrim(doctor) <> ''
on conflict do nothing;

notify pgrst, 'reload schema';
