-- Standalone schema setup; NOT a migration history entry.
-- Public editorial information, kept separate from existing multi-figure Location rows.
begin;
create table if not exists public.dongpo_sites (
  id integer primary key check (id between 1 and 37),
  catalog_key text not null unique,
  name_modern text not null,
  name_ancient text not null,
  address text not null,
  period text not null,
  historical_event text not null,
  related_literature text not null,
  literature_source text not null,
  heritage_grade text not null check (heritage_grade in ('确证', '疑似', '已佚')),
  research_notes text not null,
  description text not null,
  "Topic" text not null default '苏轼杭州行迹',
  categories text[] not null default '{}',
  themes text[] not null check (
    cardinality(themes) > 0 and
    themes <@ array['水利治绩', '交游酬唱', '诗词题咏', '民生善政', '自然山水']::text[]
  ),
  coordinates double precision[] not null default '{}',
  coordinate_note text not null,
  coordinate_system text not null default 'GCJ-02' check (coordinate_system = 'GCJ-02'),
  coordinate_status text not null check (coordinate_status in ('point', 'area', 'unlocated')),
  photos jsonb not null default '[]'::jsonb check (jsonb_typeof(photos) = 'array'),
  is_core_site boolean not null default false,
  source_document text not null,
  source_section text not null,
  check (cardinality(coordinates) = 0 or
    (cardinality(coordinates) = 2 and coordinates[1] between -180 and 180
     and coordinates[2] between -90 and 90)),
  check ((coordinate_status = 'unlocated') = (cardinality(coordinates) = 0))
);

alter table public.dongpo_sites enable row level security;
revoke all on public.dongpo_sites from anon, authenticated;
grant select on public.dongpo_sites to anon, authenticated;
grant all on public.dongpo_sites to service_role;
drop policy if exists "Public read dongpo editorial catalog" on public.dongpo_sites;
create policy "Public read dongpo editorial catalog" on public.dongpo_sites
for select to anon, authenticated using (true);
commit;
