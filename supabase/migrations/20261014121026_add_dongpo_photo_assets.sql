create table if not exists public.dongpo_photo_assets (
 asset_id integer primary key, site_id integer references public.dongpo_sites(id) on delete set null,
 site_label text not null, photo jsonb not null, created_at timestamptz not null default now()
);
alter table public.dongpo_photo_assets enable row level security;
revoke all on public.dongpo_photo_assets from anon, authenticated;
grant select on public.dongpo_photo_assets to anon, authenticated;
drop policy if exists "Public read dongpo photo assets" on public.dongpo_photo_assets;
create policy "Public read dongpo photo assets" on public.dongpo_photo_assets for select to anon, authenticated using (true);
