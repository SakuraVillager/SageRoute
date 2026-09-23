-- User-planned routes and their ordered waypoints.
-- Routes belong to a single auth user; RLS isolates each owner.
-- Waypoint coordinates are denormalized (name/lat/lon) so the preview and
-- edit surfaces can render the map without joining the public Location table;
-- location_id is kept as an optional reference back to the catalog row.
create table if not exists public.user_routes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  title text not null check (length(trim(title)) > 0),
  date_range text,
  duration text,
  distance text,
  figure_id bigint,
  figure_name text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_route_waypoints (
  id bigint generated always as identity primary key,
  route_id uuid not null references public.user_routes on delete cascade,
  sort_order integer not null check (sort_order >= 0),
  name text not null,
  latitude double precision not null,
  longitude double precision not null,
  location_id bigint,
  visit_duration_min integer,
  categories text,
  -- The final waypoint has no outgoing leg, so this value must be nullable.
  transport_to_next text null check (transport_to_next in ('driving', 'walking')),
  created_at timestamptz not null default timezone('utc', now()),
  unique (route_id, sort_order)
);

create index if not exists user_routes_user_id_created_idx
  on public.user_routes (user_id, created_at desc);

create index if not exists user_route_waypoints_route_id_sort_idx
  on public.user_route_waypoints (route_id, sort_order);

alter table public.user_routes enable row level security;
alter table public.user_route_waypoints enable row level security;

-- Supabase projects created with opt-in Data API exposure do not grant table
-- access automatically. The Flutter client always uses an authenticated JWT;
-- RLS policies below still restrict every row to its owner.
revoke all on table public.user_routes, public.user_route_waypoints from anon;
grant select, insert, update, delete
  on table public.user_routes, public.user_route_waypoints
  to authenticated;
grant usage, select on sequence public.user_route_waypoints_id_seq
  to authenticated;

-- Owners manage their own routes.
drop policy if exists "Users manage own routes" on public.user_routes;
create policy "Users manage own routes"
  on public.user_routes
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Waypoints are readable/writable only through their owning route.
drop policy if exists "Users manage own waypoints" on public.user_route_waypoints;
create policy "Users manage own waypoints"
  on public.user_route_waypoints
  for all
  to authenticated
  using (exists (
    select 1 from public.user_routes r
    where r.id = route_id and r.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.user_routes r
    where r.id = route_id and r.user_id = auth.uid()
  ));

-- Keep updated_at fresh on edit.
create or replace function public.touch_user_routes_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists user_routes_touch_updated_at on public.user_routes;
create trigger user_routes_touch_updated_at
  before update on public.user_routes
  for each row execute function public.touch_user_routes_updated_at();
