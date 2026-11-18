-- Per-service access control.
-- Users sign in, request the services they need, and an admin approves them.
-- Admins (auth.users.raw_app_meta_data -> role = 'admin') can also pre-approve
-- an email address; the user gets the services as soon as they sign up / sign
-- in with that email. Keep "Confirm email" enabled in Supabase Auth so nobody
-- can claim an e-mail address they do not own.
--
-- Run this once in the Supabase SQL editor, after the earlier migrations.
-- It replaces their open `anon` policies, so run it before real patient data
-- is stored, and do not re-run the older policy blocks afterwards.

create table if not exists public.service_access (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  email text not null,
  service text not null check (
    service in (
      'general_surgery',
      'oncology_surgery',
      'pediatric_surgery',
      'obgyn_clinic',
      'pediatrics_clinic'
    )
  ),
  status text not null default 'pending' check (
    status in ('pending', 'approved', 'rejected')
  ),
  requested_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references auth.users (id) on delete set null
);

create unique index if not exists service_access_email_service_idx
  on public.service_access (lower(email), service);
create index if not exists service_access_user_idx
  on public.service_access (user_id);

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'admin'
$$;

create or replace function public.has_service(p_service text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_app_admin() or exists (
    select 1
    from public.service_access sa
    where sa.service = p_service
      and sa.status = 'approved'
      and (
        sa.user_id = auth.uid()
        or lower(sa.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      )
  )
$$;

revoke all on function public.is_app_admin() from public, anon;
revoke all on function public.has_service(text) from public, anon;
grant execute on function public.is_app_admin() to authenticated;
grant execute on function public.has_service(text) to authenticated;

alter table public.service_access enable row level security;

drop policy if exists "service_access_select" on public.service_access;
drop policy if exists "service_access_insert" on public.service_access;
drop policy if exists "service_access_update" on public.service_access;
drop policy if exists "service_access_delete" on public.service_access;

create policy "service_access_select" on public.service_access
  for select to authenticated
  using (
    public.is_app_admin()
    or user_id = auth.uid()
    or lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );

-- Users can only file a pending request for themselves; admins can insert
-- any row (used to pre-approve an e-mail address).
create policy "service_access_insert" on public.service_access
  for insert to authenticated
  with check (
    public.is_app_admin()
    or (
      status = 'pending'
      and user_id = auth.uid()
      and lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  );

create policy "service_access_update" on public.service_access
  for update to authenticated
  using (public.is_app_admin())
  with check (public.is_app_admin());

create policy "service_access_delete" on public.service_access
  for delete to authenticated
  using (public.is_app_admin());

-- Surgery patients: general / oncology are separate services.
drop policy if exists "surgery_patients_select" on public.surgery_patients;
drop policy if exists "surgery_patients_insert" on public.surgery_patients;
drop policy if exists "surgery_patients_update" on public.surgery_patients;
drop policy if exists "surgery_patients_delete" on public.surgery_patients;

create policy "surgery_patients_select" on public.surgery_patients
  for select to authenticated
  using (
    public.has_service(
      case department when 'oncology' then 'oncology_surgery' else 'general_surgery' end
    )
  );
create policy "surgery_patients_insert" on public.surgery_patients
  for insert to authenticated
  with check (
    public.has_service(
      case department when 'oncology' then 'oncology_surgery' else 'general_surgery' end
    )
  );
create policy "surgery_patients_update" on public.surgery_patients
  for update to authenticated
  using (
    public.has_service(
      case department when 'oncology' then 'oncology_surgery' else 'general_surgery' end
    )
  )
  with check (
    public.has_service(
      case department when 'oncology' then 'oncology_surgery' else 'general_surgery' end
    )
  );
create policy "surgery_patients_delete" on public.surgery_patients
  for delete to authenticated
  using (
    public.has_service(
      case department when 'oncology' then 'oncology_surgery' else 'general_surgery' end
    )
  );

drop policy if exists "surgery_patient_files_all" on storage.objects;
create policy "surgery_patient_files_all" on storage.objects
  for all to authenticated
  using (
    bucket_id = 'surgery_patient_files'
    and (public.has_service('general_surgery') or public.has_service('oncology_surgery'))
  )
  with check (
    bucket_id = 'surgery_patient_files'
    and (public.has_service('general_surgery') or public.has_service('oncology_surgery'))
  );

-- Pediatric surgery waiting list.
drop policy if exists "pediatric_waiting_all" on public.pediatric_surgery_waiting_patients;
create policy "pediatric_waiting_all" on public.pediatric_surgery_waiting_patients
  for all to authenticated
  using (public.has_service('pediatric_surgery'))
  with check (public.has_service('pediatric_surgery'));

drop policy if exists "pediatric_surgery_patient_images_all" on storage.objects;
create policy "pediatric_surgery_patient_images_all" on storage.objects
  for all to authenticated
  using (
    bucket_id = 'pediatric_surgery_patient_images'
    and public.has_service('pediatric_surgery')
  )
  with check (
    bucket_id = 'pediatric_surgery_patient_images'
    and public.has_service('pediatric_surgery')
  );

notify pgrst, 'reload schema';
