# 行程协作与发现

Supabase 执行同学请先阅读 [Supabase 交接说明](supabase_handoff.md)，按其中顺序核对前置结构、执行升级和验收。

## 产品方案

- 行程页提供分享与协作：只读邀请、可编辑邀请、按邮箱邀请。邀请链接 7 天有效，可撤销；邮箱邀请出现在收件人的首页，接受后加入共同的行程列表。
- 创建者负责邀请、移除成员、删除行程；编辑者可调整地点和交通方式；只读成员可查看。保存使用数据库事务和版本号，禁止静默覆盖他人的更新。
- 统一分享域名为 `https://sageroute.jijiz.cn`。网页保留邀请地址完成登录；Android 客户端接收同一路径。Android App Links 使用站点关联文件，邀请网页也提供显式打开客户端的入口。本次不配置 iOS 发布。
- 「发现」替换「我的收藏」，以文字随手记与路线分享两种内容组成信息流。支持发布、点赞、评论、删除自己的帖子；游客可浏览，登录后可互动。
- 路线帖只允许发布自己的行程，公开的是发布时的地点快照；私人旅行日期、协作成员和后续编辑不会随帖子公开。读者可查看路线并保存为自己的新行程。

## 部署边界

应用代码、数据库权限、域名关联文件共同组成该功能。当前管理连接未获得 SageRoute 项目的访问权限；不会将脚本应用到其他项目。数据库启用和真账号双人联调须在获得实际项目权限后完成。

## 启用数据库

在 **SageRoute 实际项目**的 Supabase SQL Editor 中运行 `supabase/setup_collaboration_and_discovery.sql`。这是事务化、可重复执行的升级脚本，不会写入示例帖子或邀请真实用户。先确保已有路线迁移已应用，尤其是 `20260923021719_allow_nullable_transport_to_next.sql`（最后一站没有后续交通方式）。新项目依次应用现有路线迁移，再应用本脚本。

脚本会创建成员、邀请、社区表及访问权限，提供原子编辑 RPC，并将 `user_routes` 加入已存在的 Realtime publication。私有函数所在的 `private` schema **不要**加入 Data API exposed schemas。执行后可只读检查：

```sql
select to_regclass('public.route_access_index'), to_regclass('public.community_posts');
select public.sr_feed(); -- 初始是 []，不会伪造社区内容
```

需要先升级数据库，再发布新版客户端：新版编辑保存依赖事务 RPC，旧版的删除再插入接口会被撤销权限。尚未启用时，已有行程仍可读取；分享和发现显示服务暂不可用，编辑不会退回不安全的覆盖保存。

邀请邮箱是**站内邀请**，不发送电子邮件。收件人用该已验证邮箱登录，在首页刷新即可看到邀请；接受后获得成员身份。通用链接可多人使用，7 天到期。撤销链接阻止后续加入；已经加入的人需单独移除。移除成员时，也应撤销仍可能被其使用的有效通用邀请。

## Android 签名与统一链接

已经从当前 `app-release.apk` 提取 SHA-256，生成 `web/.well-known/assetlinks.json`。包名为 `com.sageroute.sageroute`，指纹为：

```text
67:6E:D2:EF:FE:2D:94:72:52:41:A0:64:08:6C:12:FF:17:CB:A4:BA:F9:82:D1:83:C2:E8:0E:30:9A:23:25:07
```

当前 Gradle 的 release 使用团队开发证书；这份关联文件与当前实际签署的 APK 匹配。将来换正式发布密钥，或由应用商店重新签名，必须改为最终分发 APK 的证书指纹。生成脚本只读取公开证书，不读取私钥或密码：

```powershell
flutter build apk --release --dart-define-from-file=dart_define.json
python tool/configure_app_links.py --apk build/app/outputs/flutter-apk/app-release.apk
```

随后重新构建网页并部署，确保 `https://sageroute.jijiz.cn/.well-known/assetlinks.json` 返回该 JSON、HTTP 200，无登录要求、无重定向。Android Manifest 已声明此域名及 `/invite/`、`/discover/posts/`、`/routes/` 路径。应用接收冷启动和运行中链接，认证回调继续由 Supabase 处理。用户系统的“打开支持的链接”设置也会影响自动打开；未安装时直接进入网页。

设备连接后，可检查系统域名验证结果：

```powershell
adb shell pm verify-app-links --re-verify com.sageroute.sageroute
adb shell pm get-app-links com.sageroute.sageroute
```

## EdgeOne Pages 发布

```powershell
flutter build web --release --no-web-resources-cdn --dart-define-from-file=dart_define.web.json
python tool/check_web_build.py
python tool/package_edgeone.py
```

上传整个 `build/web` 目录内容，或 `build/sageroute-edgeone.zip`；根目录应直接包含 `index.html`、`edgeone.json`、`.well-known/assetlinks.json`。不要漏掉以点开头的目录。已有重写规则覆盖邀请与发现页面，不把关联 JSON 改写为应用首页。公开域名默认是本次确认的域名，Web 和 Android 都可用 `APP_PUBLIC_URL` 编译参数覆盖；若更换域名，还必须同步 Manifest 和站点关联文件。

## 验证

本地 PostgreSQL 测试使用隔离的内存引擎和虚拟用户，不触碰线上数据：

```powershell
npm install --prefix build/sql-validation --no-audit --no-fund @electric-sql/pglite@0.5.10
node tool/test_social_database.mjs
flutter analyze
flutter test
```

覆盖邀请接受、邮箱约束、过期/撤销、成员列表、只读/编辑权限、版本冲突、事务回滚、公开路线快照隔离，以及点赞、评论、删除权限。正式项目启用后，还需用两个真实账号验证邀请收件箱、同时保存的冲突提示、撤销权限，以及已安装 Android 通过正式域名打开链接；这些云端和设备行为尚未宣称验收完成。
