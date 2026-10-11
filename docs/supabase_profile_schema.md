# 「我的」页 Supabase 数据表方案（草案）

**状态**：方案，未在 Supabase 执行
**适用页面**：`lib/views/profile_page.dart`（我的）、`lib/pages/settings_page.dart`（设置）及其子页面
**关联代码**：`lib/services/profile_preferences.dart`（本地存储，先上线）、`lib/models/achievement.dart` + `lib/data/local_achievement_repository.dart`（成就本地优先）、`lib/models/user_profile.dart`、`lib/services/auth_service.dart`

> **落地策略更新（成就本地优先）**：按当前产品决定，成就数据只存本地
> （`models/achievement.dart` + `data/local_achievement_repository.dart` +
> SharedPreferences 解锁时间），**暂不创建云端成就表**。
> 因此本文 §2.2 `achievement_definitions`、§2.3 `user_achievements`、§4.3 成就结算函数
> 仅作为后续「特殊成就 / 多端同步」的备选方案保留，现在执行没有收益。
> 如果以后要先上云，只需落地 §2.1 `profiles`（昵称/简介/偏好）+ §2.4/§2.5
> （保存路线、探索足迹），统计交给 §2.6 视图聚合；成就相关章节可以整体跳过。

> 执行本方案前，必须先做第 0 节的 schema 核对。`auth_service.dart` 注册流程的注释提到
> “nickname 会写入 metadata，供 profiles 表触发器读取”，说明服务端**可能已经存在**
> `profiles` 表与触发器；本文所有建表语句都写成 `if not exists` / `drop ... if exists`
> 的幂等形式，但字段是否冲突仍需人工确认。

---

## 0. 执行前核对清单

在 Supabase Dashboard → SQL Editor 依次执行：

```sql
-- 1) 现有表
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;

-- 2) profiles 表已有列（若表存在）
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
order by ordinal_position;

-- 3) auth.users 上已有的触发器
select trigger_name, event_manipulation, action_statement
from information_schema.triggers
where event_object_schema = 'auth' and event_object_table = 'users';

-- 4) profiles 上已有的 RLS 策略
select policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'profiles';
```

需要记录并同步到本文档的结论：

| 核对项 | 结论 | 影响 |
|---|---|---|
| `profiles` 是否已存在 | 待填 | 存在则只 `alter table ... add column if not exists` |
| 是否已有 `handle_new_user` 触发器 | 待填 | 已有则不要重复创建，改为在函数内补字段 |
| nickname 当前存在哪里 | 待填（`raw_user_meta_data.nickname`？） | 决定存量用户数据回填方式 |
| 现有表的命名风格 | PascalCase 与 snake_case 混用 | 决定新表命名，见 §1.2 |

---

## 1. 设计原则

1. **认证与业务分离**：`auth.users` 由 Supabase 管理，业务表只存 `id` 外键，不复制邮箱/密码。
2. **用户数据行级隔离**：所有用户数据表以 `user_id = auth.uid()` 作为 RLS 边界。
3. **定义与进度分离**：成就的文案/条件放在 `achievement_definitions`，用户进度放在 `user_achievements`，避免客户端硬编码。
4. **统计不冗余**：三格统计（解锁成就 / 探索地点 / 完成路线）由视图实时聚合，不额外存计数，避免不一致。
5. **客户端可降级**：本地 `ProfilePreferences` 保留为离线缓存，网络失败时页面仍可展示上次数据（Phase 2 实施）。
6. **成就由服务端发放**：客户端只读 `user_achievements`，写入走 RPC / Edge Function，防止刷成就。

### 1.2 命名说明

现有表混用命名：`Celebrity` / `Location` / `Topic` / `Dynasty` / `Icons` / `Article` 是 PascalCase，
`article_images`、`poi_celebrity_relatian` 是 snake_case。新表建议统一 snake_case（Postgres 惯例，
也免去 Supabase Dashboard 中大小写加引号的麻烦）；若团队决定延续 PascalCase，本文 SQL 需整体改名。

---

## 2. 表结构

### 2.1 profiles —— 用户资料

```sql
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nickname    text not null default '' check (char_length(nickname) <= 20),
  avatar_url  text,
  bio         text not null default '' check (char_length(bio) <= 60),
  language    text not null default 'zh-Hans',
  preferences jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.profiles is '用户资料，与 auth.users 一一对应';
comment on column public.profiles.language is '界面语言代码，目前仅 zh-Hans';
comment on column public.profiles.preferences is
  '旅行偏好：{"dynasties":["唐"],"themes":["诗词"],"pace":"balanced","transport":"driving"}';
```

字段与客户端映射：

| 列 | Flutter 侧 | 说明 |
|---|---|---|
| `nickname` | 头部昵称（优先于 `user_metadata.nickname`） | 有本地覆盖时以服务端为准 |
| `bio` | 头部副标题 / 账号信息页 | 空串表示未填写 |
| `language` | `ProfilePreferences.defaultLanguage` | 多语言上线后接入 |
| `preferences` | `TravelPreferences.toJson()` | jsonb 直接存模型结构 |

### 2.2 achievement_definitions —— 成就定义

```sql
create table if not exists public.achievement_definitions (
  id               text primary key,
  name             text not null,
  description      text not null default '',
  icon             text not null default '',
  condition_type   text not null check (condition_type in (
                     'route_completed', 'route_saved',
                     'location_visited', 'photo_uploaded', 'poem_recited')),
  condition_value  int  not null default 1 check (condition_value > 0),
  condition_meta   jsonb not null default '{}'::jsonb,
  sort_order       int  not null default 0,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now()
);

comment on column public.achievement_definitions.condition_meta is
  '额外条件，如 {"dynasty":"唐"}；配合 condition_type 表达“完成所有唐代诗人路线”';
```

与 `lib/data/mock_achievements.dart` 的 6 条本地种子对应（仅在未来启用云端成就时使用）：

```sql
insert into public.achievement_definitions
  (id, name, description, icon, condition_type, condition_value, condition_meta, sort_order)
values
  ('song-ci-tracker',    '宋词寻踪者', '完成一条宋词相关的文化路线', 'book',    'route_completed',  1, '{}',                 1),
  ('beginner-explorer',  '初级探险家', '累计探索 5 个文化景点',       'compass', 'location_visited', 5, '{}',                 2),
  ('tang-poetry-master', '大唐盛世',   '完成所有唐代诗人路线',        'crown',   'route_completed',  1, '{"dynasty":"唐"}',   3),
  ('route-collector',    '路线收藏家', '收藏 10 条文化路线',          'star',    'route_saved',     10, '{}',                 4),
  ('photo-enthusiast',   '摄影爱好者', '上传 20 张景点照片',          'camera',  'photo_uploaded',  20, '{}',                 5),
  ('poem-reciter',       '诗词背诵者', '背诵 10 首景点相关古诗词',    'quote',   'poem_recited',    10, '{}',                 6)
on conflict (id) do update
  set name = excluded.name,
      description = excluded.description,
      icon = excluded.icon,
      condition_type = excluded.condition_type,
      condition_value = excluded.condition_value,
      condition_meta = excluded.condition_meta,
      sort_order = excluded.sort_order,
      is_active = true;
```

### 2.3 user_achievements —— 用户成就进度

```sql
create table if not exists public.user_achievements (
  user_id        uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null references public.achievement_definitions(id) on delete cascade,
  progress       int  not null default 0 check (progress >= 0),
  unlocked_at    timestamptz,
  updated_at     timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

comment on table public.user_achievements is
  '用户成就进度；unlocked_at 非空表示已解锁。客户端只读，写入由服务端 RPC 完成';
```

### 2.4 user_saved_routes —— 保存 / 完成的路线

```sql
create table if not exists public.user_saved_routes (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  route_id       text not null,
  route_snapshot jsonb not null default '{}'::jsonb,
  status         text not null default 'saved' check (status in ('saved', 'planned', 'completed')),
  completed_at   timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (user_id, route_id)
);

comment on column public.user_saved_routes.route_snapshot is
  '保存时的行程快照（CreateRouteWizard 产出的 NewRouteDraft 序列化结果）';
```

### 2.5 user_visited_locations —— 探索过的地点

```sql
create table if not exists public.user_visited_locations (
  user_id         uuid not null references auth.users(id) on delete cascade,
  location_id     text not null,
  visited_at      timestamptz not null default now(),
  source_route_id text,
  primary key (user_id, location_id)
);
```

### 2.6 user_profile_stats —— 个人页三格统计视图

```sql
create or replace view public.user_profile_stats
with (security_invoker = true) as
select
  p.id            as user_id,
  p.nickname,
  p.avatar_url,
  p.bio,
  (select count(*) from public.user_achievements ua
    where ua.user_id = p.id and ua.unlocked_at is not null) as achievements_unlocked,
  (select count(*) from public.user_visited_locations v
    where v.user_id = p.id) as locations_explored,
  (select count(*) from public.user_saved_routes r
    where r.user_id = p.id and r.status = 'completed') as routes_completed
from public.profiles p;
```

> `security_invoker = true` 需要 PostgreSQL 15+（Supabase 默认满足）。
> 若项目还在 PG14，去掉该选项，改为在视图上显式授权。

---

## 3. 索引

```sql
create index if not exists user_achievements_unlocked_idx
  on public.user_achievements (user_id, unlocked_at desc);

create index if not exists user_saved_routes_status_idx
  on public.user_saved_routes (user_id, status);

create index if not exists user_visited_locations_visited_idx
  on public.user_visited_locations (user_id, visited_at desc);
```

---

## 4. 触发器与函数

### 4.1 注册时自动建 profile

```sql
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nickname)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'nickname', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

### 4.2 updated_at 自动刷新

```sql
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists user_saved_routes_touch_updated_at on public.user_saved_routes;
create trigger user_saved_routes_touch_updated_at
  before update on public.user_saved_routes
  for each row execute function public.touch_updated_at();
```

### 4.3 成就结算（示例，规则需再细化）

```sql
create or replace function public.evaluate_achievements(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_locations int;
  v_completed int;
  v_saved     int;
begin
  select count(*) into v_locations
    from public.user_visited_locations where user_id = p_user_id;
  select count(*) into v_completed
    from public.user_saved_routes where user_id = p_user_id and status = 'completed';
  select count(*) into v_saved
    from public.user_saved_routes where user_id = p_user_id;

  insert into public.user_achievements (user_id, achievement_id, progress, unlocked_at)
  select
    p_user_id,
    d.id,
    case d.condition_type
      when 'location_visited' then v_locations
      when 'route_completed'  then v_completed
      when 'route_saved'      then v_saved
      else 0
    end,
    case
      when (case d.condition_type
              when 'location_visited' then v_locations
              when 'route_completed'  then v_completed
              when 'route_saved'      then v_saved
              else 0
            end) >= d.condition_value
      then now()
    end
  from public.achievement_definitions d
  where d.is_active
  on conflict (user_id, achievement_id) do update
    set progress    = excluded.progress,
        unlocked_at = coalesce(public.user_achievements.unlocked_at, excluded.unlocked_at),
        updated_at  = now();
end;
$$;
```

调用时机（二选一，推荐后者）：

- 客户端在“保存/完成路线、打卡地点”后调用 `rpc('evaluate_achievements', ...)`；
- 或在 `user_saved_routes` / `user_visited_locations` 的 `after insert or update` 触发器里调用，
  由数据库统一结算，客户端无法伪造。

---

## 5. RLS 策略

```sql
-- 5.1 profiles
alter table public.profiles enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- 5.2 成就定义：登录用户可读
alter table public.achievement_definitions enable row level security;

drop policy if exists achievement_definitions_read on public.achievement_definitions;
create policy achievement_definitions_read on public.achievement_definitions
  for select using (auth.role() = 'authenticated');

-- 5.3 用户成就：只读自己的（写入只允许 service_role / security definer 函数）
alter table public.user_achievements enable row level security;

drop policy if exists user_achievements_select_own on public.user_achievements;
create policy user_achievements_select_own on public.user_achievements
  for select using (auth.uid() = user_id);

-- 5.4 保存路线：本人增删改查
alter table public.user_saved_routes enable row level security;

drop policy if exists user_saved_routes_all_own on public.user_saved_routes;
create policy user_saved_routes_all_own on public.user_saved_routes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 5.5 探索地点：本人增删改查
alter table public.user_visited_locations enable row level security;

drop policy if exists user_visited_locations_all_own on public.user_visited_locations;
create policy user_visited_locations_all_own on public.user_visited_locations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

验收方式（用两个测试账号）：

```sql
-- 账号 A 登录后只能看到自己的行
select * from public.profiles;
select * from public.user_achievements;
select * from public.user_profile_stats;
```

---

## 6. 与 Flutter 侧的映射（Phase 2 落地）

| 现有代码 / 模型 | 接入方式 |
|---|---|
| `lib/models/achievement.dart` + `lib/data/local_achievement_repository.dart` | **当前实现：纯本地**。若后续要同步特殊成就，再把本地仓库包装成「先本地、后云端」的双写实现 |
| `lib/data/mock_achievements.dart` | 本地成就种子（解锁时间由仓库持久化）；云端仅在未来启用 §2.2/§2.3 时作为种子导入源 |
| `lib/models/user_profile.dart` 的 `UserProfile` / `Achievement` | 与 `user_profile_stats` + `achievement_definitions` + `user_achievements` 对齐；补充 `fromMap` 别名 |
| `lib/data/mock_user.dart` | 降级为离线兜底与本地开发数据 |
| 新增 `lib/data/user_profile_repository.dart` | 继承/复用 `SupabaseTableRepository`，沿用 `fetcher` 注入模式（仓库约定） |
| 新增 `ProfileController`（ChangeNotifier） | 聚合 profile、stats、achievements；本地 `ProfilePreferences` 作为缓存与离线回退 |
| `lib/views/profile_page.dart` | `StreamBuilder` 只保留给登录态；资料区改为 controller 驱动，带 loading / empty / error / 下拉刷新 |
| `lib/models/travel_preferences.dart` | `toJson()/fromJson()` 直接对应 `profiles.preferences` jsonb |
| 昵称/简介保存（AccountInfoPage） | 本地先写 + 后台 `profiles.upsert`，失败保留本地并提示 |
| 头像（Phase 3） | 新建 Storage bucket `avatars`，路径 `{user_id}/avatar.{ext}`，写入 `profiles.avatar_url` |

---

## 7. 迁移步骤与回滚

**执行顺序**

1. 完成 §0 核对，把结论补回本文档。
2. 执行 §2 建表（已存在则跳过/改 `alter`），再执行 §3 索引。
3. 执行 §4 触发器与函数。
4. 执行 §5 RLS。
5. 执行 §2.2 成就种子数据。
6. 用测试账号验证：注册新用户 → `profiles` 自动生成 → 客户端可读写自己的 `preferences`。
7. 回填存量用户：`insert into profiles (id, nickname) select id, coalesce(raw_user_meta_data->>'nickname','') from auth.users on conflict do nothing;`
8. 客户端按 §6 分步接入，`ProfilePreferences` 保留为缓存。

**回滚**

```sql
drop view if exists public.user_profile_stats;
drop table if exists public.user_visited_locations;
drop table if exists public.user_saved_routes;
drop table if exists public.user_achievements;
drop table if exists public.achievement_definitions;
drop table if exists public.profiles;
drop function if exists public.evaluate_achievements(uuid);
drop function if exists public.handle_new_user();
drop function if exists public.touch_updated_at();
```

> 回滚会丢失用户资料与进度，执行前先 `pg_dump` 备份。

---

## 8. 未决问题

1. 现有 `profiles` 表（如果存在）的字段、权限、触发器与本文的差异需要人工合并。
2. 表名最终采用 snake_case 还是延续现有 PascalCase？
3. 成就结算放在客户端 RPC、数据库触发器还是 Edge Function？需要确定“完成路线”的判定入口。
4. 头像 Storage 的 bucket 命名、大小限制与 RLS 策略（Phase 3）。
5. 多设备冲突策略：本地缓存与云端资料的时间戳合并规则。
6. 语言字段上线后与 `flutter_localizations` 的 ARB 文案如何对应。
