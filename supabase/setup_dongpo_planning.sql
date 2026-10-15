-- Optional planning metadata sync. Run with an authorized management connection.
-- Standalone setup SQL; does not create a migration history entry.
begin;
alter table public."Location" add column if not exists heritage_grade text;
alter table public."Location" add column if not exists themes text[] not null default '{}';
do $block$ begin
  if not exists (select 1 from pg_constraint where conrelid = 'public."Location"'::regclass and conname = 'location_heritage_grade_check') then
    alter table public."Location" add constraint location_heritage_grade_check
      check (heritage_grade is null or heritage_grade in ('确证', '疑似', '已佚'));
  end if;
end $block$;
insert into public."Topic" (celebrity, name, description)
select '苏轼', '东坡杭州行迹', '37 处杭州行迹，沿着治水、交游与诗文认识东坡。'
where not exists (select 1 from public."Topic" where celebrity = '苏轼' and name in ('东坡杭州行迹', '苏轼·杭州行迹', '苏轼杭州行迹'));
-- Source 1: 杭州州治（凤凰山）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['民生善政', '交游酬唱', '诗词题咏']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州凤凰山景区（中和堂）', '杭州凤凰山景区');
-- Source 2: 望海楼
update public."Location" as location
set heritage_grade = '已佚',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州凤凰山景区（望海楼）');
-- Source 3: 钱塘六井（相国井等）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['水利治绩', '民生善政']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市上城区解放路与浣纱路交叉口附近（相国井遗迹）');
-- Source 4: 安乐坊
update public."Location" as location
set heritage_grade = '疑似',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['民生善政']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市上城区庆春路与浣纱路交叉口', '杭州市（具体位置不可考）');
-- Source 5: 吉祥寺
update public."Location" as location
set heritage_grade = '已佚',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州市拱墅区仙林苑小区遗址');
-- Source 6: 祥符寺
update public."Location" as location
set heritage_grade = '已佚',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['诗词题咏']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市拱墅区灯芯巷一带（遗址）');
-- Source 8: 杭州府学（贡士饯行）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['民生善政', '交游酬唱']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市上城区劳动路杭州孔庙');
-- Source 9: 介亭（凤凰山）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州凤凰山景区圣果寺遗址');
-- Source 10: 安济亭（钱塘江观潮）
update public."Location" as location
set heritage_grade = '已佚',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市钱塘江（观潮）');
-- Source 13: 孤山（访惠勤惠思）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州孤山景区');
-- Source 14: 六一泉
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州孤山景区（六一泉）');
-- Source 15: 智果院（应梦记）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市西湖区栖霞岭（智果寺遗址）');
-- Source 16: 苏堤
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['水利治绩', '民生善政', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州西湖苏堤景区');
-- Source 17: 望湖楼
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市西湖区北山路宝石山麓', '杭州西湖北山街望湖楼景区');
-- Source 18: 冷泉亭
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市西湖区灵隐景区灵隐寺前飞来峰下');
-- Source 19: 大麦岭摩崖题刻
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州西湖区大麦岭');
-- Source 24: 龙井（风篁岭、过溪亭）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州西湖区龙井村');
-- Source 25: 灵隐寺
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州灵隐寺景区');
-- Source 26: 西湖（乞开西湖状）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['水利治绩', '民生善政', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州西湖景区', '浙江省杭州市上城区西湖景区');
-- Source 30: 富阳（普照寺、富阳道中）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['民生善政', '交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市富阳区普照寺');
-- Source 32: 风水洞
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州西湖区双浦镇灵山村', '浙江省杭州市富阳区风水洞');
-- Source 33: 佛日山净慧寺
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市佛日山');
-- Source 34: 临平山
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('杭州临平区临平山公园');
-- Source 35: 安隐寺（安平泉）
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市临平区临平山南麓安平泉景区');
-- Source 36: 西兴浦口
update public."Location" as location
set heritage_grade = '确证',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['交游酬唱', '诗词题咏', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('浙江省杭州市滨江区西兴街道');
-- Source 37: 钱塘江石门（开石门河状）
update public."Location" as location
set heritage_grade = '已佚',
    themes = array(select distinct tag from unnest(
      array_remove(coalesce(location.themes, '{}'::text[]), '自然山水') ||
      array['水利治绩', '民生善政', '自然景观']::text[]
    ) as labels(tag) order by tag)
where name_modern in ('钱塘江上游石门段（地望后世失考，约今富阳区与桐庐县交界江段）');
-- Read-back verification: the editorial source remains 37 records.
select count(*) as dongpo_site_count from public.dongpo_sites;
select heritage_grade, count(*) from public."Location"
where heritage_grade is not null group by heritage_grade;
commit;
