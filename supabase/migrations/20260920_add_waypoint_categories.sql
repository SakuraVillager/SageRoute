-- Preserve location categories with denormalized route waypoints so route
-- preview/edit markers keep their semantic icon without joining Location.
alter table public.user_route_waypoints
  add column if not exists categories text;

-- Backfill routes saved before this column existed. Cast to text deliberately:
-- the Location table has appeared with both array-like and text category
-- representations, while marker matching only needs the category labels.
do $$
begin
  if to_regclass('public."Location"') is not null then
    execute '
      update public.user_route_waypoints w
      set categories = l.categories::text
      from public."Location" l
      where w.categories is null
        and w.location_id = l.id
        and l.categories is not null
    ';
  end if;
end;
$$;
