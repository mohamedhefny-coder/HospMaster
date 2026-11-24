-- Waiting lists for the other medical departments.
-- Admins create a list, name it and add its doctors; users with the
-- "other_waiting_lists" service (approved by an admin) can use the lists.
--
-- Run once in the Supabase SQL editor, after 20261118_service_access.sql.

-- 1) New service that can be requested / approved.
alter table public.service_access
  drop constraint if exists service_access_service_check;
alter table public.service_access
  add constraint service_access_service_check check (
    service in (
      'general_surgery',
      'oncology_surgery',
      'pediatric_surgery',
      'obgyn_clinic',
      'pediatrics_clinic',
      'other_waiting_lists'
    )
  );

-- 2) Lists and their doctors.
create table if not exists public.waiting_lists (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);
create unique index if not exists waiting_lists_name_idx
  on public.waiting_lists (lower(name));

create table if not exists public.waiting_list_doctors (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.waiting_lists (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);
create unique index if not exists waiting_list_doctors_name_idx
  on public.waiting_list_doctors (list_id, lower(name));

-- 3) Patients of those lists (same shape as the pediatric surgery list).
create table if not exists public.waiting_list_patients (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.waiting_lists (id) on delete cascade,
  name text not null default '',
  age text not null default '',
  diagnosis text not null default '',
  doctor text not null default '',
  date text not null default '',
  priority text not null default '',
  workflow_stage text not null default 'waiting',
  phone text not null default '',
  notes text not null default '',
  images jsonb not null default '[]'::jsonb,
  operation_list_date text,
  call_status text not null default '',
  op_details jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists waiting_list_patients_list_idx
  on public.waiting_list_patients (list_id);

-- 4) Row level security.
alter table public.waiting_lists enable row level security;
alter table public.waiting_list_doctors enable row level security;
alter table public.waiting_list_patients enable row level security;

drop policy if exists "waiting_lists_select" on public.waiting_lists;
drop policy if exists "waiting_lists_admin_insert" on public.waiting_lists;
drop policy if exists "waiting_lists_admin_update" on public.waiting_lists;
drop policy if exists "waiting_lists_admin_delete" on public.waiting_lists;
create policy "waiting_lists_select" on public.waiting_lists
  for select to authenticated
  using (public.has_service('other_waiting_lists'));
create policy "waiting_lists_admin_insert" on public.waiting_lists
  for insert to authenticated with check (public.is_app_admin());
create policy "waiting_lists_admin_update" on public.waiting_lists
  for update to authenticated
  using (public.is_app_admin()) with check (public.is_app_admin());
create policy "waiting_lists_admin_delete" on public.waiting_lists
  for delete to authenticated using (public.is_app_admin());

drop policy if exists "waiting_list_doctors_select" on public.waiting_list_doctors;
drop policy if exists "waiting_list_doctors_admin_insert" on public.waiting_list_doctors;
drop policy if exists "waiting_list_doctors_admin_update" on public.waiting_list_doctors;
drop policy if exists "waiting_list_doctors_admin_delete" on public.waiting_list_doctors;
create policy "waiting_list_doctors_select" on public.waiting_list_doctors
  for select to authenticated
  using (public.has_service('other_waiting_lists'));
create policy "waiting_list_doctors_admin_insert" on public.waiting_list_doctors
  for insert to authenticated with check (public.is_app_admin());
create policy "waiting_list_doctors_admin_update" on public.waiting_list_doctors
  for update to authenticated
  using (public.is_app_admin()) with check (public.is_app_admin());
create policy "waiting_list_doctors_admin_delete" on public.waiting_list_doctors
  for delete to authenticated using (public.is_app_admin());

drop policy if exists "waiting_list_patients_all" on public.waiting_list_patients;
create policy "waiting_list_patients_all" on public.waiting_list_patients
  for all to authenticated
  using (public.has_service('other_waiting_lists'))
  with check (public.has_service('other_waiting_lists'));

-- 5) Patient images.
insert into storage.buckets (id, name, public)
values ('waiting_list_patient_images', 'waiting_list_patient_images', false)
on conflict (id) do nothing;

drop policy if exists "waiting_list_patient_images_all" on storage.objects;
create policy "waiting_list_patient_images_all" on storage.objects
  for all to authenticated
  using (
    bucket_id = 'waiting_list_patient_images'
    and public.has_service('other_waiting_lists')
  )
  with check (
    bucket_id = 'waiting_list_patient_images'
    and public.has_service('other_waiting_lists')
  );

notify pgrst, 'reload schema';
