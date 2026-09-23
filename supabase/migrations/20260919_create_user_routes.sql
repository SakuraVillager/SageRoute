-- Persist routes created by an authenticated SageRoute user.
create table if not exists public.user_routes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  date_range text not null default '',
  duration text not null default '',
  distance text not null default '',
  figure_id bigint,
  figure_name text not null default '',
  route_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_route_waypoints (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.user_routes(id) on delete cascade,
  sort_order integer not null default 0 check (sort_order >= 0),
  name text not null default '',
  location_name text not null default '',
  latitude double precision not null,
  longitude double precision not null,
  location_id bigint,
  visit_duration_min integer check (visit_duration_min is null or visit_duration_min >= 0),
  average_visit_duration_min integer check (average_visit_duration_min is null or average_visit_duration_min >= 0),
  transport_to_next text not null default 'driving' check (transport_to_next in ('driving', 'walking')),
  transport_type text not null default 'driving' check (transport_type in ('driving', 'walking')),
  topic text,
  categories text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists user_routes_user_id_created_at_idx
  on public.user_routes (user_id, created_at desc);
create index if not exists user_route_waypoints_route_id_sort_idx
  on public.user_route_waypoints (route_id, sort_order);

create or replace function public.set_user_routes_updated_at()
returns trigger
language plpgsql
security invoker
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists user_routes_set_updated_at on public.user_routes;
create trigger user_routes_set_updated_at
before update on public.user_routes
for each row execute function public.set_user_routes_updated_at();

alter table public.user_routes enable row level security;
alter table public.user_route_waypoints enable row level security;

grant select, insert, update, delete on table public.user_routes to authenticated;
grant select, insert, update, delete on table public.user_route_waypoints to authenticated;

drop policy if exists "Users can read own routes" on public.user_routes;
create policy "Users can read own routes" on public.user_routes
for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Users can insert own routes" on public.user_routes;
create policy "Users can insert own routes" on public.user_routes
for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Users can update own routes" on public.user_routes;
create policy "Users can update own routes" on public.user_routes
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Users can delete own routes" on public.user_routes;
create policy "Users can delete own routes" on public.user_routes
for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "Users can read own route waypoints" on public.user_route_waypoints;
create policy "Users can read own route waypoints" on public.user_route_waypoints
for select to authenticated using (exists (
  select 1 from public.user_routes r
  where r.id = route_id and r.user_id = auth.uid()
));
drop policy if exists "Users can insert own route waypoints" on public.user_route_waypoints;
create policy "Users can insert own route waypoints" on public.user_route_waypoints
for insert to authenticated with check (exists (
  select 1 from public.user_routes r
  where r.id = route_id and r.user_id = auth.uid()
));
drop policy if exists "Users can update own route waypoints" on public.user_route_waypoints;
create policy "Users can update own route waypoints" on public.user_route_waypoints
for update to authenticated using (exists (
  select 1 from public.user_routes r
  where r.id = route_id and r.user_id = auth.uid()
)) with check (exists (
  select 1 from public.user_routes r
  where r.id = route_id and r.user_id = auth.uid()
));
drop policy if exists "Users can delete own route waypoints" on public.user_route_waypoints;
create policy "Users can delete own route waypoints" on public.user_route_waypoints
for delete to authenticated using (exists (
  select 1 from public.user_routes r
  where r.id = route_id and r.user_id = auth.uid()
));
