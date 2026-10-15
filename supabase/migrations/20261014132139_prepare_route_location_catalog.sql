-- Catalog integration; old IDs remain stable for saved route references.
create schema if not exists catalog_archive;
revoke all on schema catalog_archive from public, anon, authenticated;
create table if not exists catalog_archive.snapshots (
  batch text not null, table_name text not null, row_key text not null,
  row_data jsonb not null, archived_at timestamptz not null default now(),
  primary key(batch,table_name,row_key)
);
revoke all on catalog_archive.snapshots from public, anon, authenticated;

alter table public."Location"
  add column if not exists heritage_grade text,
  add column if not exists period text,
  add column if not exists historical_event text,
  add column if not exists related_literature text,
  add column if not exists literature_source text,
  add column if not exists research_notes text,
  add column if not exists themes text[] not null default '{}',
  add column if not exists photos jsonb not null default '[]',
  add column if not exists coordinate_system text,
  add column if not exists coordinate_status text,
  add column if not exists coordinate_note text,
  add column if not exists catalog_key text,
  add column if not exists source_document text,
  add column if not exists source_section text,
  add column if not exists is_core_site boolean not null default false,
  add column if not exists data_status text not null default 'pending_review',
  add column if not exists route_eligible boolean not null default false;
alter table public."Location" add constraint location_heritage_grade_valid
  check (heritage_grade is null or heritage_grade in ('确证','疑似','已佚'));
alter table public."Location" add constraint location_photo_array_valid
  check (jsonb_typeof(photos)='array');
create unique index if not exists location_catalog_key_unique
  on public."Location"(catalog_key) where catalog_key is not null;

create table public.location_topic_memberships (
  location_id bigint not null references public."Location"("id (PK)"),
  topic_id bigint not null references public."Topic"(id) on delete cascade,
  display_order integer not null default 0,
  primary key(location_id,topic_id)
);
create index on public.location_topic_memberships(topic_id,display_order);
create table public.location_theme_tags (
  name text primary key, description text not null,
  aliases text[] not null default '{}'
);
create table public.location_tag_memberships (
  location_id bigint not null references public."Location"("id (PK)"),
  tag_name text not null references public.location_theme_tags(name),
  source text not null,
  primary key(location_id,tag_name)
);
alter table public.dongpo_sites add column if not exists location_id bigint
  references public."Location"("id (PK)");
create unique index on public.dongpo_sites(location_id) where location_id is not null;

alter table public.location_topic_memberships enable row level security;
alter table public.location_theme_tags enable row level security;
alter table public.location_tag_memberships enable row level security;
create policy "Read editorial route memberships" on public.location_topic_memberships
  for select to anon,authenticated using(true);
create policy "Read editorial theme tags" on public.location_theme_tags
  for select to anon,authenticated using(true);
create policy "Read editorial tag memberships" on public.location_tag_memberships
  for select to anon,authenticated using(true);
revoke all on public.location_topic_memberships,public.location_theme_tags,public.location_tag_memberships from anon,authenticated;
grant select on public.location_topic_memberships,public.location_theme_tags,public.location_tag_memberships to anon,authenticated;

-- Routes are selected by Topic; tags and icon categories are distinct concepts.
create view public.route_topic_locations with(security_invoker=true) as
  select t.id as topic_id,t.name as theme_name,m.display_order,l.*
  from public.location_topic_memberships m
  join public."Topic" t on t.id=m.topic_id
  join public."Location" l on l."id (PK)"=m.location_id;
grant select on public.route_topic_locations to anon,authenticated;
