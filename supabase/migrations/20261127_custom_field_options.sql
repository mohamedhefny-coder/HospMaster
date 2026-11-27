-- Items added to the surgery patient form dropdowns (diagnosis, doctor, signs,
-- symptoms, history, labs, imaging, conscious level) so they appear in the
-- lists for every later patient. Run once in the Supabase SQL editor, after
-- 20261118_service_access.sql.

create table if not exists public.custom_field_options (
  id uuid primary key default gen_random_uuid(),
  field text not null,
  value text not null check (length(btrim(value)) > 0),
  created_at timestamptz not null default now()
);

create unique index if not exists custom_field_options_field_value_idx
  on public.custom_field_options (field, lower(value));

alter table public.custom_field_options enable row level security;

drop policy if exists "custom_field_options_select" on public.custom_field_options;
drop policy if exists "custom_field_options_insert" on public.custom_field_options;

create policy "custom_field_options_select" on public.custom_field_options
  for select to authenticated
  using (
    public.has_service('general_surgery')
    or public.has_service('oncology_surgery')
  );

create policy "custom_field_options_insert" on public.custom_field_options
  for insert to authenticated
  with check (
    public.has_service('general_surgery')
    or public.has_service('oncology_surgery')
  );

notify pgrst, 'reload schema';
