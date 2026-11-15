-- Pediatric surgery waiting list (table + private bucket for patient images).
-- Run once in the Supabase SQL editor of the target project.

create table if not exists public.pediatric_surgery_waiting_patients (
  id uuid primary key default gen_random_uuid(),
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.pediatric_surgery_waiting_patients
  add column if not exists name text not null default '',
  add column if not exists age text not null default '',
  add column if not exists diagnosis text not null default '',
  add column if not exists doctor text not null default '',
  add column if not exists date text not null default '',
  add column if not exists priority text not null default '',
  add column if not exists workflow_stage text not null default 'waiting',
  add column if not exists phone text not null default '',
  add column if not exists notes text not null default '',
  add column if not exists images jsonb not null default '[]'::jsonb,
  add column if not exists operation_list_date text,
  add column if not exists call_status text not null default '',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.pediatric_surgery_waiting_patients enable row level security;

-- Same note as 20261025_surgery_patients.sql: these policies allow the anon
-- role because the app signs in with the publishable key only.
drop policy if exists "pediatric_waiting_all" on public.pediatric_surgery_waiting_patients;
create policy "pediatric_waiting_all" on public.pediatric_surgery_waiting_patients
  for all to anon, authenticated using (true) with check (true);

insert into storage.buckets (id, name, public)
values ('pediatric_surgery_patient_images', 'pediatric_surgery_patient_images', false)
on conflict (id) do nothing;

drop policy if exists "pediatric_surgery_patient_images_all" on storage.objects;
create policy "pediatric_surgery_patient_images_all" on storage.objects
  for all to anon, authenticated
  using (bucket_id = 'pediatric_surgery_patient_images')
  with check (bucket_id = 'pediatric_surgery_patient_images');

notify pgrst, 'reload schema';
