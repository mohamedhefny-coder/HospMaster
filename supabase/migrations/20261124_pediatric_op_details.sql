-- Dated operation / event lines for each pediatric surgery waiting-list patient.
-- Run once in the Supabase SQL editor.

alter table public.pediatric_surgery_waiting_patients
  add column if not exists op_details jsonb not null default '[]'::jsonb;

notify pgrst, 'reload schema';
