-- Grey.D'Studio Sales Pipeline: database setup for Supabase
-- Run once in Supabase: SQL Editor -> New query -> paste all of this -> Run.
-- Safe to run again.

-- 1. Tables: one row per record, the record itself is stored as JSON
create table if not exists public.projects (id text primary key, data jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());
create table if not exists public.team     (id text primary key, data jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());
create table if not exists public.settings (id text primary key, data jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());
create table if not exists public.notes    (id text primary key, data jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now());

-- 2. Who is signed in? A login counts only when an admin has linked it to a team member (team.data.uid)
create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.team where data->>'uid' = auth.uid()::text);
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.team where data->>'uid' = auth.uid()::text and coalesce((data->>'admin')::boolean, false));
$$;

revoke all on function public.is_member() from public, anon;
revoke all on function public.is_admin()  from public, anon;
grant execute on function public.is_member() to authenticated;
grant execute on function public.is_admin()  to authenticated;

-- 3. Row-level security: the public (not logged in) can read and write nothing
alter table public.projects enable row level security;
alter table public.team     enable row level security;
alter table public.settings enable row level security;
alter table public.notes    enable row level security;

revoke all on public.projects, public.team, public.settings, public.notes from anon;
grant select, insert, update, delete on public.projects, public.team, public.settings, public.notes to authenticated;

drop policy if exists "members read projects"  on public.projects;
drop policy if exists "members write projects" on public.projects;
create policy "members read projects"  on public.projects for select to authenticated using (public.is_member());
create policy "members write projects" on public.projects for all    to authenticated using (public.is_member()) with check (public.is_member());

drop policy if exists "members read settings"  on public.settings;
drop policy if exists "members write settings" on public.settings;
create policy "members read settings"  on public.settings for select to authenticated using (public.is_member());
create policy "members write settings" on public.settings for all    to authenticated using (public.is_member()) with check (public.is_member());

drop policy if exists "members read notes"  on public.notes;
drop policy if exists "members write notes" on public.notes;
create policy "members read notes"  on public.notes for select to authenticated using (public.is_member());
create policy "members write notes" on public.notes for all    to authenticated using (public.is_member()) with check (public.is_member());

-- Team: everyone on the team can see the list; only admins can add, edit or remove members
drop policy if exists "members read team" on public.team;
drop policy if exists "admins write team" on public.team;
create policy "members read team" on public.team for select to authenticated using (public.is_member());
create policy "admins write team" on public.team for all    to authenticated using (public.is_admin()) with check (public.is_admin());

-- 4. Live updates (changes show on every open screen)
do $$
declare t text;
begin
  foreach t in array array['projects','team','settings','notes'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
