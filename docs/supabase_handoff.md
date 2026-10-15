# SageRoute · Supabase 交接说明

交接日期：2026-10-15。适用功能：行程分享、多人编辑、邀请收件箱和「发现」社区。

**队友需要做的事：确认实际项目与现有结构 → 补齐必要的路线迁移 → 执行本次升级脚本 → 配置认证与 Realtime → 用真实账号验收 → 配合发布新版客户端。** 表、字段、函数和权限已写成 SQL，不需要在 Table Editor 中逐项手动创建。

本地实现和隔离数据库测试已完成；交接时，执行环境没有 SageRoute 实际项目的管理权限，**不能视为云端已升级或已通过双账号验收**。请在下方交接记录中填写真实执行结果。

## 1. 先确认目标项目

当前 Web 本地配置指向：

- Project ref：`msjzwtigdinhdygpmnuh`。
- API URL：`https://msjzwtigdinhdygpmnuh.supabase.co`。
- 正式网站：`https://sageroute.jijiz.cn`。

由有权限的队友进入对应 Supabase Dashboard，核对 Project ref。项目名称可能调整，以实际发布配置中的 URL 和 Project ref 为准；同时核对 Android 使用的配置，保证两端连接同一个项目。不要因为另一个项目可以访问，就把脚本执行到另一个项目。

准备一个拥有 SQL Editor 和数据库对象修改权限的管理账号。按团队现有方式保存升级前的数据库备份，并保留路线表的结构、函数、触发器、RLS 策略和授权定义；只导出路线 CSV 不足以恢复权限配置。建议先在测试环境演练。

本次不需要给前端新增服务端密钥。客户端只使用现有 publishable/anon Key；`service_role`、secret Key、数据库密码不能放入 Dart 配置、网页或交接截图。

## 2. 一起交接的文件

| 文件 | 用途 |
|---|---|
| [setup_collaboration_and_discovery.sql](../supabase/setup_collaboration_and_discovery.sql) | 本次必须执行的升级脚本，包含事务、表、权限、RPC 和 Realtime 配置 |
| [check_collaboration_and_discovery.sql](../supabase/check_collaboration_and_discovery.sql) | 升级后的只读结构与权限检查，不返回用户内容、邀请 token 或密钥 |
| `supabase/migrations/20260919_create_user_routes.sql` | 首次创建路线基础结构；已有项目需要先核对，不应盲目重跑 |
| `supabase/migrations/20260920_add_waypoint_categories.sql` | 为旧路线途经点补充分类字段，并按条件回填 |
| `supabase/migrations/20260923021719_allow_nullable_transport_to_next.sql` | 允许最后一站的后续交通方式为空 |
| `supabase/migrations/20260923_secure_user_route_persistence.sql` | 路线旧版权限基础脚本；如需补齐，必须先于本次升级执行 |
| [collaboration_and_discovery.md](collaboration_and_discovery.md) | 产品行为、Android 域名关联和 EdgeOne 发布说明 |

本次主脚本是独立的 `setup_*.sql`，不是自动执行的 CLI migration。仅拉取代码或发布网页，不会自动修改云端数据库。团队如用迁移流水线管理，请将实际执行结果纳入自己的迁移记录，避免后续重复执行旧权限脚本。

配套 `supabase-handoff.zip` 只包含交接文档、所需 SQL 和隔离数据库测试脚本，不包含客户端、密钥或数据库备份。需要运行 Flutter 验证、构建和发布时，仍需使用完整项目仓库。

## 3. 执行前只读核对

打开目标项目 **SQL Editor → New query**，运行：

```sql
select current_database(), current_user,
       current_setting('server_version') as postgres_version;

select to_regclass('public.user_routes') as routes,
       to_regclass('public.user_route_waypoints') as waypoints;

select table_name, column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('user_routes', 'user_route_waypoints')
order by table_name, ordinal_position;

select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('user_routes', 'user_route_waypoints')
order by tablename, policyname;

select tgname, pg_get_triggerdef(oid) as definition
from pg_trigger
where tgrelid = to_regclass('public.user_routes') and not tgisinternal;
```

核对要求：

- PostgreSQL 为 15 或更高版本；本次视图使用 `security_invoker`。
- `user_routes` 至少具备 `id`、`user_id`、`title`、`date_range`、`duration`、`distance`、`figure_id`、`figure_name`、`route_snapshot`、`created_at`、`updated_at`。
- `user_route_waypoints` 至少具备 `id`、`route_id`、`sort_order`、`name`、`latitude`、`longitude`、`location_id`、`visit_duration_min`、`categories`、`transport_to_next`。
- `transport_to_next` 必须允许空值；`user_routes_touch_updated_at` 触发器必须存在并启用。
- 留存现有策略结果。如存在仓库脚本以外的额外策略，先核对其用途：本次脚本只替换已知策略，不会自动清理所有自定义策略；额外宽松策略可能让访问范围大于预期。

### 缺少基础结构时如何补齐

**已具备上述结构的项目直接进入第 4 节。** 缺少某些前置变更时，只补对应变更；不要为求方便重跑整个目录。

全新路线数据库的顺序为：

1. `20260919_create_user_routes.sql`。
2. `20260920_add_waypoint_categories.sql`。
3. `20260923021719_allow_nullable_transport_to_next.sql`。
4. `20260923_secure_user_route_persistence.sql`。
5. 本次 `setup_collaboration_and_discovery.sql`。

现有表如果缺少其他必需列，应先与基础脚本逐列比较，准备相应 `ALTER TABLE`，在测试环境核对存量数据后再执行。`CREATE TABLE IF NOT EXISTS` 不会自动修复已存在表的缺列或类型差异。

**本次升级之后不要再重跑旧版权限脚本。** 它会重新开放本次收紧的写入权限。

## 4. 执行本次升级

1. 与前端同学确认新版 Web 和 Android 包已准备好，安排切换时段，暂停售改路线。
2. 在 SQL Editor 打开新的查询，完整复制 `supabase/setup_collaboration_and_discovery.sql`。
3. 一次执行整个文件，包括开头 `BEGIN` 和结尾 `COMMIT`；确认成功后进入下一节。
4. 记录执行时间、执行者和错误信息。若事务报错，不要继续手动运行余下半段；确认事务已回滚，修复原因后重新完整执行。

脚本在结构符合预期时可重复执行，不会插入示例帖子、替真实用户创建邀请或批量加入行程。它也不会自动迁移旧收藏到社区。

**兼容性：旧版客户端通过“删除再插入途经点”保存编辑，本次会撤销直接删除权限。新版使用 `sr_replace_waypoints`。数据库升级与新版发布需要配合完成；仍使用旧 APK 的用户不能保证继续编辑。不能只撤销新版网页、保留新数据库，就认为已经恢复旧版兼容性。**

### 数据库会有哪些变化

| 对象 | 变化与用途 |
|---|---|
| `user_routes.revision` | 新增非空整数，默认 0；路线更新时递增，用于检查并发编辑 |
| `touch_user_routes_updated_at()` | 更新原有触发器函数，同时维护时间和版本；依赖已有触发器绑定 |
| `route_members` | 存放行程成员与 `editor`／`viewer` 角色；创建者仍由路线 `user_id` 表示 |
| `route_invitations` | 存放邀请 token、权限、可选邮箱、7 天有效期和撤销时间 |
| `route_access_index` | 客户端查询自己创建及参与的行程，附带角色与人数；以调用者权限查询 |
| `community_posts` | 随手记和路线快照；正文 1–2000 字 |
| `community_comments` | 评论，正文 1–500 字 |
| `community_likes` | 点赞，同一用户对同一帖子只有一条记录 |
| `private` schema | 放置内部权限判断和受控函数；不要暴露到 Data API |

本次没有图片上传、社区图片 Storage bucket、邮件邀请服务或额外 Edge Function。

### 应有的访问规则

| 身份 | 私人行程 | 编辑地点／交通 | 邀请与管理成员 | 删除行程 | 社区 |
|---|---|---|---|---|---|
| 未登录游客 | 不可读取 | 不可 | 不可 | 不可 | 可读帖子和评论，不可发布、点赞、评论 |
| 行程创建者 | 可读自己的 | 可 | 可 | 可 | 可发布自己的路线快照 |
| `editor` 成员 | 可读加入的 | 可 | 不可管理其他成员 | 不可 | 可互动，不可公开他人行程 |
| `viewer` 成员 | 可读加入的 | 不可 | 不可管理其他成员 | 不可 | 可互动，不可公开他人行程 |
| 其他已登录用户 | 不可读取未加入的 | 不可 | 不可 | 不可 | 可浏览、发布自己的内容及互动 |

移除成员 RPC 也允许成员退出自己，但当前分享界面没有单独提供退出按钮。

## 5. Dashboard 还需要检查的配置

### Data API 与权限

在 Data API 配置中确认 `public` 是 exposed schema；**不要加入 `private`**。脚本已显式设置表和函数授权，不依赖新表是否自动开放。表授权决定能执行哪类操作，RLS 决定能访问哪些行，两者都要保持。[Supabase 官方说明](https://supabase.com/docs/guides/database/postgres/row-level-security)

所有相关业务表保持 RLS 开启。邀请表不能通过普通客户端直接读取；创建、预览和接受邀请走 RPC。不要用关闭 RLS、向 `anon` 开放私人路线、把视图改为默认权限模式的方式处理报错。

### Realtime

确认 publication `supabase_realtime` 包含 `public.user_routes`。如果该 publication 已存在，主脚本会自动补入路线表；如果不存在，主脚本不会自动创建它，需要先按项目的 Realtime 配置补齐。

只读查看当前状态：

```sql
select pubname from pg_publication where pubname = 'supabase_realtime';
select schemaname, tablename
from pg_publication_tables
where pubname = 'supabase_realtime' and tablename = 'user_routes';
```

可使用 Dashboard 的 replication/publication 配置将路线表加入；publication 已存在且缺少该表时，也可重新完整运行主脚本。不要为这次功能把包含 token 的邀请表一并广播。客户端监听路线更新后会重新通过 RLS 拉取数据，保存时仍由版本号检查保证不会静默覆盖。[Postgres Changes 官方说明](https://supabase.com/docs/guides/realtime/postgres-changes)

### Authentication

在 Authentication 的 URL Configuration 中设置或核对：

```text
Site URL:
https://sageroute.jijiz.cn

Redirect URLs:
https://sageroute.jijiz.cn/auth/callback
sageroute://login-callback/
```

本地调试才额外保留实际使用的 `http://127.0.0.1:8080/auth/callback` 或 `http://localhost:8080/auth/callback`。邀请路径 `/invite/<token>` 是应用页面，不是认证回调，不必把每一个邀请地址加入认证回调白名单。[认证跳转地址官方说明](https://supabase.com/docs/guides/auth/redirect-urls)

邮箱绑定邀请依赖 `auth.users.email_confirmed_at`：收件人必须用对应的**已验证邮箱**登录。不要手工改邮箱或验证时间绕过匹配。邀请属于站内通知；本次没有发送邀请邮件。Supabase 原有的注册确认／找回密码邮件属于另一条认证流程，继续使用项目原有设置。

游客模式是应用本地的浏览状态，本次不要求启用 Supabase Anonymous Sign-ins。公开昵称来自 `raw_user_meta_data.nickname`，仅用于显示；授权使用登录用户 ID、创建者关系和成员表，不使用用户可编辑的昵称或 metadata 充当权限。

## 6. 执行后检查与验收

### A. 运行只读检查脚本

完整运行 `supabase/check_collaboration_and_discovery.sql`。预期每行 `passed = true`；它检查结构、RLS 开关、公开 RPC 的调用授权、视图安全模式、版本触发器和 Realtime。`realtime_user_routes = false` 表示还没有完成路线更新订阅配置。

此脚本不包含业务写入，不展示用户记录。但 **SQL Editor 管理员查询成功，不等于普通用户通过了 RLS 验收**；还必须完成下面的真实账号检查。结合项目的 Database/Security Advisors 检查新增对象，特别注意意外开放的表或额外策略。

可另行执行：

```sql
select public.sr_feed();
```

没有帖子时返回 `[]` 是正常结果；已有帖子时返回公开动态。不要为让发现页“看起来有内容”向正式项目导入本地示例数据。

### B. 双账号与游客验收

准备已验证邮箱的测试账号 A、B，使用独立浏览器配置或一端网页、一端 Android。测试行程使用明确的验收名称，不改动真实用户行程。

| 步骤 | 操作与预期 |
|---|---|
| 私有隔离 | A 创建一条含两站的行程。B 尚未加入时，通过其地址不能读取行程；游客也不能读取 |
| 邮箱邀请 | A 用 B 的已验证邮箱创建编辑邀请。B 首页刷新后看到邀请；接受后行程出现在 B 的列表，角色为可编辑 |
| 链接加入 | 使用新行程测试通用链接；未登录打开时先看邀请摘要，登录后仍返回该邀请，接受后进入行程 |
| 邮箱约束 | 用不匹配账号接受邮箱绑定链接时，应被拒绝；不会新增成员 |
| 编辑同步 | B 修改地点或交通并保存；A 重开／刷新后看到最新内容，在线订阅正常时能收到更新 |
| 同时编辑 | A、B 先打开相同版本。A 保存后 B 再保存，应出现冲突提示；B 的改动不应静默覆盖 A 的结果 |
| 只读权限 | A 创建只读邀请让 B 加入另一条行程。B 可读但不能编辑、删除或管理其他成员；直接尝试写接口也应被拒绝 |
| 撤销与移除 | 撤销邀请后，未加入的人不能再通过该链接加入；已加入成员不会因此自动退出，需单独移除。移除后重新读取／保存应被拒绝 |
| 社区互动 | A 发布随手记。B 点赞、取消点赞、评论；游客能读，但不能写。B 不能删除 A 的帖子 |
| 路线快照 | A 发布自己的路线帖；公开内容不包含私人出行日期和成员。之后修改私人行程，原帖子快照不随之改变 |
| 快照归属 | B 不能把仅受邀参与的 A 的行程直接公开；B 可将公开路线另存为自己的新行程 |

如果 B 已是某条行程的编辑者，再接受该行程的只读邀请不会降级；反过来，接受有效编辑邀请可以将只读成员升级。测试只读权限应另建行程。移除某人时，也要撤销其仍可能持有的有效通用邀请，避免再次加入。

邀请默认 7 天有效；本地隔离测试已覆盖过期校验。需要立即验证真实过期行为时，请在独立测试环境对专门的测试邀请缩短有效期，不批量修改正式邀请。

### C. 本地验证状态

交接前结果：`flutter analyze` 无问题，432 项 Flutter 测试、18 项浏览器专项测试通过；Web 与 Android release 构建成功。隔离 PostgreSQL 引擎已验证主脚本重复执行、邀请与权限、版本冲突、事务回滚和公开快照隔离。这些结果不能替代实际 Supabase 上的账号权限与 Realtime 验收。

队友可在仓库根目录运行：

```powershell
npm install --prefix build/sql-validation --no-audit --no-fund @electric-sql/pglite@0.5.10
node tool/test_social_database.mjs
```

该测试使用内存数据库和虚拟用户，不连接实际 Supabase，不会邀请真实用户或发布正式帖子。

## 7. 常见问题定位

| 现象 | 优先检查 |
|---|---|
| `PGRST202`／找不到 `sr_*` 函数 | 是否升级了正确项目；脚本是否完整提交；Data API 是否包含 `public`。脚本结尾已通知刷新 schema cache |
| `PGRST205`／找不到表或视图 | 前置路线结构、本次对象是否存在；客户端配置是否仍连到另一个项目 |
| `42501`／permission denied | 先区分对象授权与 RLS。核对登录身份和成员角色，不要先关闭 RLS |
| `null value ... transport_to_next` | 最后一站允许空值的迁移是否生效 |
| B 看不到邮箱邀请 | B 邮箱是否已验证、是否匹配；邀请是否过期／撤销；是否刷新；B 若已是成员，不再显示为待接受邀请 |
| 保存显示 `route_conflict`／`40001` | 并发版本检查生效。保留当前草稿，让用户载入最新版本后调整，不应自动重试覆盖 |
| 发现页为空 | `sr_feed()` 返回 `[]` 时是正常空社区；服务暂不可用则先查对象、权限和 API 配置 |
| 改动未实时出现，但刷新后可见 | 检查 Realtime publication、连接与订阅；与数据库是否已经保存是不同问题 |
| 网页能打开，Android 无法自动唤起 | 检查 EdgeOne 的 `/.well-known/assetlinks.json`、APK 签名和 Android 支持的链接设置；这不是创建新 Supabase 表能解决的问题 |

邀请 token 相当于持有人可用的加入凭据，不放进公开日志、截图或问题单。排查时优先记录错误码、函数名和时间。

## 8. 失败处理与发布交接

**主脚本未提交时：** 事务失败不会保留该事务的部分改动；如会话仍处于失败事务，先回滚，核对原因后重跑完整文件。前面单独执行过的历史迁移不在本事务内，不会一起自动回滚。

**主脚本已提交时：** 优先保留数据并修复具体结构／权限问题。不要通过删除新表、清空成员或重跑旧授权脚本“快速回退”。如果必须回到旧版本，需要使用升级前保存的结构、函数、触发器、策略及授权定义，制定并演练回退方案；本仓库没有提供已验收的自动回退脚本。已产生的邀请和社区内容也需纳入保留方案。

数据库验收通过后，通知前端发布已准备的新版 Web 和 Android，确认两端 Supabase URL 相同。Android 与网页共用 `https://sageroute.jijiz.cn` 分享链接；站点关联文件由 EdgeOne 提供，不上传到 Supabase Storage。只需 Android，本次不配置 iOS。

前端发布与域名关联见 [行程协作与发现](collaboration_and_discovery.md)。客户端实际自动打开链接仍需部署后真机验收。

### 队友回传记录

| 项目 | 填写结果 |
|---|---|
| 目标 Project ref / 执行者 / 执行时间 | 待填 |
| 升级前备份与配置记录位置 | 待填（不要填写密钥） |
| 补执行的历史脚本 | 待填，未补则写“结构已满足” |
| 主脚本结果 | 待填 |
| 只读检查失败项 | 待填，通过则写“全部 true” |
| Data API / Auth 回调 / Realtime 配置 | 待填 |
| A、B、游客验收结果与遗留问题 | 待填 |
| Web / Android 发布版本与旧 APK 处理方式 | 待填 |
| Android 正式域名真机打开链接结果 | 待填 |
