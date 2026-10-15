create table public.heritage_marker_styles (
 style_key text primary key, heritage_grade text unique, label text not null,
 background_hex text not null check(background_hex ~ '^#[0-9A-Fa-f]{6}$'),
 check(heritage_grade is null or heritage_grade in ('确证','疑似','已佚'))
);
insert into public.heritage_marker_styles values
 ('confirmed','确证','确证','#237A4B'),('suspected','疑似','疑似','#B88309'),
 ('lost','已佚','已佚','#BA4242'),('default',null,'未评级','#96615A');
alter table public.heritage_marker_styles enable row level security;
revoke all on public.heritage_marker_styles from anon,authenticated;
grant select on public.heritage_marker_styles to anon,authenticated;
create policy "Read marker style tokens" on public.heritage_marker_styles for select to anon,authenticated using(true);
comment on column public."Location".heritage_grade is '历史证据等级：确证/疑似/已佚；NULL 表示未评级，不是确证。与坐标精度、图标类别独立。';
comment on column public."Location".route_eligible is '待后续规划UI接入：仅point精度可直接作为导航终点；area与unlocated需人工确认。';
comment on column public."Location".themes is '专题标签；不是主题路线，也不是地图图标分类。规范名在location_theme_tags。';
