-- Private bucket for patient photos and lab / imaging attachments.
-- Run after 20261025_surgery_patients.sql. Same note on `anon` access applies.

insert into storage.buckets (id, name, public)
values ('surgery_patient_files', 'surgery_patient_files', false)
on conflict (id) do nothing;

drop policy if exists "surgery_patient_files_all" on storage.objects;
create policy "surgery_patient_files_all" on storage.objects
  for all to anon, authenticated
  using (bucket_id = 'surgery_patient_files')
  with check (bucket_id = 'surgery_patient_files');
