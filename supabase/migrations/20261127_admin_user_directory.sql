-- Admin user directory and "last seen" tracking.
-- * touch_last_seen(): signed-in users stamp their own last activity.
-- * admin_list_users(): admins list every registered account (for the e-mail
--   picker when adding a user) together with its last activity.
--
-- Run this once in the Supabase SQL editor, after 20261118_service_access.sql.

create table if not exists public.user_presence (
  user_id uuid primary key references auth.users (id) on delete cascade,
  last_seen_at timestamptz not null default now()
);

alter table public.user_presence enable row level security;
revoke all on public.user_presence from anon, authenticated;

create or replace function public.touch_last_seen()
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.user_presence (user_id, last_seen_at)
  select auth.uid(), now()
  where auth.uid() is not null
  on conflict (user_id) do update set last_seen_at = excluded.last_seen_at
$$;

create or replace function public.admin_list_users()
returns table (user_id uuid, email text, last_seen_at timestamptz)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_app_admin() then
    raise exception 'Only admins can list users.' using errcode = '42501';
  end if;
  return query
    select u.id,
           lower(u.email::text),
           greatest(p.last_seen_at, u.last_sign_in_at)
    from auth.users u
    left join public.user_presence p on p.user_id = u.id
    where u.email is not null
    order by lower(u.email::text);
end;
$$;

revoke all on function public.touch_last_seen() from public, anon;
revoke all on function public.admin_list_users() from public, anon;
grant execute on function public.touch_last_seen() to authenticated;
grant execute on function public.admin_list_users() to authenticated;

notify pgrst, 'reload schema';
