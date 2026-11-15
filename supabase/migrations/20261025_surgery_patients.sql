-- Surgery department patient records (general surgery and oncology surgery).
-- Run this once in the Supabase SQL editor.

create table if not exists public.surgery_patients (
  id uuid primary key default gen_random_uuid(),
  department text not null check (department in ('general', 'oncology')),
  name text not null,
  file_number text not null default '',
  room_number text not null default '',
  diagnosis text not null default '',
  status_label text not null default '',
  doctor text not null default '',
  residence text not null default '',
  phone text not null default '',
  photo_path text,
  photo_name text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists surgery_patients_department_created_idx
  on public.surgery_patients (department, created_at desc);

alter table public.surgery_patients enable row level security;

-- The app currently signs in with the publishable key only (no user login),
-- so these policies allow the anon role. This exposes patient data to anyone
-- holding the key: once the app has authentication, replace `anon, authenticated`
-- with `authenticated` (or a role check) before using real patient data.
drop policy if exists "surgery_patients_select" on public.surgery_patients;
drop policy if exists "surgery_patients_insert" on public.surgery_patients;
drop policy if exists "surgery_patients_update" on public.surgery_patients;
drop policy if exists "surgery_patients_delete" on public.surgery_patients;

create policy "surgery_patients_select" on public.surgery_patients
  for select to anon, authenticated using (true);
create policy "surgery_patients_insert" on public.surgery_patients
  for insert to anon, authenticated with check (true);
create policy "surgery_patients_update" on public.surgery_patients
  for update to anon, authenticated using (true) with check (true);
create policy "surgery_patients_delete" on public.surgery_patients
  for delete to anon, authenticated using (true);

-- Make PostgREST pick up the new table immediately.
-- (Storage bucket for attachments: run 20261025_surgery_patient_files.sql.)
notify pgrst, 'reload schema';
