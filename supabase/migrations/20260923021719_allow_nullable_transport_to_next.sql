-- The app stores no transport choice for the final waypoint because it has no
-- outgoing segment. Match the live schema to that persistence contract.
alter table public.user_route_waypoints
  alter column transport_to_next drop not null;

notify pgrst, 'reload schema';
