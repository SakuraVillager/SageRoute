-- Reconcile the already-deployed route tables with the Flutter persistence
-- contract. The Data API receives an authenticated Supabase JWT from the app;
-- permissions allow that role to reach the tables and RLS limits each user to
-- their own routes and route waypoints.

alter table public.user_routes enable row level security;
alter table public.user_route_waypoints enable row level security;

revoke all on table public.user_routes, public.user_route_waypoints from anon;
grant select, insert, update, delete
  on table public.user_routes, public.user_route_waypoints
  to authenticated;

drop policy if exists "Users manage own routes" on public.user_routes;
create policy "Users manage own routes"
  on public.user_routes
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users manage own waypoints" on public.user_route_waypoints;
create policy "Users manage own waypoints"
  on public.user_route_waypoints
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.user_routes routes
      where routes.id = route_id
        and routes.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.user_routes routes
      where routes.id = route_id
        and routes.user_id = (select auth.uid())
    )
  );
