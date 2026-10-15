# SageRoute Web 构建与静态部署

Android 与 Web 共用 Dart 业务、仓储和规划协调器。地图适配集中在 `lib/components/map/`，Web SDK 桥接位于 `web/sage_maps.js`。Web 不需要运行应用服务器，发布内容为 `build/web`。

## 本地配置

复制 `dart_define.web.example.json` 为已忽略的 `dart_define.web.json`，填写：

| 参数 | 用途 |
|---|---|
| `SUPABASE_URL` | 现有 Supabase 项目 URL |
| `SUPABASE_ANON_KEY` | 客户端 publishable/anon Key，绝不能填 service_role 或 secret Key |
| `AMAP_WEB_KEY` | 独立的高德 JavaScript API Web Key；Android Key 不能替代 |
| `AMAP_WEB_SECURITY_CODE` | 与 Web Key 配套的安全密钥 |
| `AMAP_SERVICE_HOST` | 可选代理入口，首版留空；本仓库不提供代理服务器 |

这些参数会进入客户端构建产物，访问者可以读取。纯静态模式采用直接配置安全密钥的已确认取舍；正式发布时使用独立 Web Key，限定允许域名并配置服务权限。设置 `AMAP_SERVICE_HOST` 时它优先于安全密钥，必须是按高德要求独立部署的服务地址，不能随意填写本站 URL。参见[高德安全密钥说明](https://lbs.amap.com/api/javascript-api-v2/guide/abc/jscode)。

通用 `dart_define.json` 与 `assets/env.env` 仅进入原生平台资源，不进入 Web 资源。Android 的原有配置方式继续使用。

## Web 调试运行

Web 的 `String.fromEnvironment` 参数必须在每次编译启动时传入；存在 `dart_define.web.json` 文件不会自动加载它。运行：

```powershell
flutter run -d edge --web-port=8080 --dart-define-from-file=dart_define.web.json
```

VS Code 在「运行和调试」中选择 `SageRoute Web (Edge debug)` 后按 F5；配置位于 `.vscode/launch.json`。若使用已安装的 Chrome，可将设备改为 `chrome`。Android Studio 的 Flutter Run Configuration 在 Additional run args 中填写 `--dart-define-from-file=dart_define.web.json --web-port=8080`，并选择浏览器设备。

若出现 `Failed to launch browser after 3 tries`，表示 Flutter 未能启动或连接浏览器调试实例。可选择 `SageRoute Web (manual browser)`，或在终端运行：

```powershell
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8080 --dart-define-from-file=dart_define.web.json
```

看到服务地址后，手动在浏览器打开 `http://127.0.0.1:8080/`，并保持运行终端开启。这种方式无需 Flutter 自动启动 Edge；浏览器调试支持有限，参见 [Flutter Web 开发配置](https://docs.flutter.dev/platform-integration/web/setup)。

如果 Python 预览仍占用 8080，先在运行它的终端按 Ctrl+C。也可使用其他端口，但真实邮件认证回调需要在 Supabase 中配置对应地址。更改编译参数后必须停止调试并重新启动，不能仅热重载。

Python 只提供已有 `build/web` 文件；之前成功构建时参数已经编入产物，所以它能显示正常页面。直接调试或重新构建属于另一次编译，需要再次传入 Web 配置。普通 Android 启动配置使用的 `dart_define.json` 不能替代专用 Web 配置。

## Release 构建与预览

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=dart_define.web.json
python tool/check_web_build.py
python tool/serve_web.py --port 8080
```

访问 `http://127.0.0.1:8080/`。此服务器仅用于本机验收，提供 SPA 回退；资源不存在时返回 404。正式站点必须使用 HTTPS。缺少地图 Key 时显示地图错误与重试入口，不阻止登录、列表和其他页面。

## 认证回调

Web 使用当前站点 `/auth/callback`；Android 使用原有 `sageroute://login-callback/`。在 Supabase Authentication → URL Configuration 保留 Android 地址，并加入实际使用的精确地址，例如：

```text
http://127.0.0.1:8080/auth/callback
http://localhost:8080/auth/callback
https://YOUR_DOMAIN/auth/callback
```

开发端口改变时也要更新允许列表。正式 `Site URL` 使用正式站点。回调页等待初始化及 SDK 会话处理完成；恢复密码回调进入重置页，成功及失败后均清理认证 URL 参数。PKCE 邮件链接需要在发起请求的浏览器中完成；没有有效会话时显示重新发送入口。参见 [Supabase 回调配置](https://supabase.com/docs/guides/auth/redirect-urls)。

Web 启动时删除遗留 `savedLoginPassword`；记住邮箱只保存邮箱和时间。登录会话由 Supabase SDK 持久化，密码表单支持浏览器自动填充。昵称、简介、语言和旅行偏好目前依旧是设备本地数据。

## URL 与草稿

欢迎页和登录页提供「游客进入」。游客模式使用本地浏览标记，支持刷新后继续浏览人物、地点和规划路线；不会创建 Supabase 匿名账号。游客访问公共内容仍使用原有 anon 权限，云端个人路线继续要求真实登录，后台 RLS 无变更。个人中心和收藏页会提示登录。

游客新建行程的 Web 草稿保存在当前标签页，保存时引导登录并保留草稿；登录成功后迁移至该账号的草稿空间。失败或取消登录不清除游客草稿。退出游客模式会清除当前标签页的行程草稿。原生端保存时打开登录页，返回后继续当前规划。

| URL | 页面 |
|---|---|
| `/welcome`、`/login`、`/register`、`/forgot-password` | 引导及认证 |
| `/auth/callback`、`/reset-password` | 邮件回调、重置密码 |
| `/home`、`/figures`、`/saved`、`/profile` | 主导航 |
| `/settings`、`/settings/account`、`/settings/travel`、`/settings/language` | 设置 |
| `/figures/:id`、`/locations/:id`、`/articles/:id` | 按 ID 重新读取详情 |
| `/routes/new`、`/routes/:id`、`/routes/:id/edit` | 创建、预览与编辑行程 |

受保护链接先进入登录，登录后回到原地址；内容不存在或不能读取时显示状态。旧演示人物/地点的字符串 ID 仍读取现有模拟记录。辅助选择页继续使用现有页面栈。

创建和编辑草稿使用 `sessionStorage`，键包含用户 ID 及新建/行程 ID。保存、确认放弃和退出登录清理草稿。刷新恢复输入和步骤，预览重新计算。不同标签页独立；浏览器复制标签页可能复制初始 sessionStorage 快照，之后各自变化。存储被禁用或容量不足时页面仍能编辑，但刷新恢复不保证成功。

## 静态托管

按域名根路径发布。托管商需支持 HTTPS、SPA 路径回退、缓存头、正确 MIME 类型和压缩。参考 `docs/deployment/nginx-static.conf`；它只服务静态文件。其他托管商应使用同样规则：

1. 业务路径返回 `index.html`，例如直接访问 `/routes/<ID>`。
2. `/assets/`、`/canvaskit/`、`/icons/` 及文件扩展名请求，找不到时返回 404，不能返回 HTML。
3. `index.html`、bootstrap、主 JS、manifest 使用重新验证缓存策略。当前 Flutter 文件名未带内容哈希，不设一年 immutable；示例对资源使用一小时并重新验证。只有实际带版本号/内容哈希的资源才允许长期 immutable。
4. 完整上传 `build/web`，包含同站点 CanvasKit 与字体。不要只上传 `index.html` 和主 JS。
5. 首版 bootstrap 不注册离线 Service Worker，不提供离线缓存。若域名曾部署旧 Flutter Service Worker，验收时先卸载旧 worker 并清理其缓存。

## 发布与回滚

### EdgeOne Pages 直接上传

`web/edgeone.json` 会随 Flutter Web 构建复制到产物根目录：业务路径重写到 `index.html`，静态资源仍按原路径读取；未带哈希的资源使用重新验证缓存策略。新加业务 URL 时也需更新该文件。

在项目根目录执行：

```powershell
flutter build web --release --dart-define-from-file=dart_define.web.json
python tool/check_web_build.py
Compress-Archive -Path build/web/* -DestinationPath build/sageroute-edgeone.zip -Force
```

前一条命令成功后再执行下一条。在 EdgeOne Pages 新建项目，选择直接上传，上传 `build/sageroute-edgeone.zip`。ZIP 根目录应直接包含 `index.html` 和 `edgeone.json`，不能多套一层 `web/`。不要上传整个源码目录或本地配置文件。直接上传使用已经编译进 JS 的参数，控制台环境变量不会修改该产物中的 Dart 配置。

部署后将实际 HTTPS 域名加入高德 Web Key 的允许域名；按上文配置 Supabase Site URL 和 `/auth/callback`。检查登录、邮件回调、地图加载，以及直接访问和刷新 `/home`、`/routes/new`。若使用自定义域名，按平台给出的 DNS 记录配置并等待 HTTPS 生效。

参考：[直接上传](https://pages.edgeone.ai/zh/document/direct-upload)、[edgeone.json](https://pages.edgeone.ai/zh/document/edgeone-json)。

### 通用发布流程

1. 发布前运行自动检查，并完成 `docs/web_validation.md` 的账号与真机验收清单。
2. 将完整产物放入新的版本目录（例如 `releases/<发布编号>/`），保存版本号、配置的 Key 标识和构建日志，勿把原始私密配置上传。
3. 验证 Key 的域名/权限、Supabase 精确回调、入口、详情刷新、地图规划及定位；确认 Web 产物中没有本地配置资源。
4. 托管平台原子切换整站版本；Nginx 示例可以切换 `current` 指向新目录。保留上一完整目录，避免逐个覆盖形成新旧混用。
5. 清理 CDN 对入口和未带版本文件的缓存，让浏览器重新验证。发布前已打开的旧标签页需刷新后使用新版本；不要假设所有活动标签页会同步更新。
6. 回滚时切回上一完整版本，清理相同缓存，再验证入口及详情路径。此适配没有新增数据库迁移，回滚不需要撤销数据库结构。

## 自动测试

```powershell
flutter test --platform chrome test/web
node --test test/web/sage_maps_bridge_test.cjs
flutter build apk --dart-define-from-file=dart_define.json
```

Chrome 没有安装时可用 `CHROME_EXECUTABLE` 指定 Edge。当前 Windows Flutter 3.41.4 的测试宿主缺少 `#play` 元素，且 CanvasKit/套件 URL 处理混用了 Windows 路径分隔符。该版本可运行：

```powershell
powershell -NoProfile -File tool/test_web.ps1
# 或显式使用 Chrome
powershell -NoProfile -File tool/test_web.ps1 -BrowserExecutable 'C:/Program Files/Google/Chrome/Application/chrome.exe'
```

脚本从 Flutter tools 源码运行，仅在测试期间修正上述宿主问题，`finally` 恢复 SDK 文件原始字节，不升级 SDK、不修改其 snapshot。请勿并发运行这个脚本；强制结束整个 PowerShell 主进程会阻止 finally。已修复这些问题的 SDK 使用正常 Flutter 命令即可。浏览器测试使用模拟 HTTP、模拟地图桥接，不调用真实 Supabase 或高德。

## 坐标与平台边界

JS API 接收 `[经度, 纬度]`，规划结果转换为业务沿用的 `[纬度, 经度]`；距离为米，时长为秒构造 `Duration`。Web 定位使用高德 `convert: true`，只接受标注 GCJ-02 的结果。原生导览继续沿用已有定位链；通用系统 GPS 服务返回结果明确标注 WGS-84，不能未经转换作为高德地图输入。浏览器不会调用系统设置入口。

驾车 shortest 对应 JS `LEAST_DISTANCE`，默认对应 `LEAST_TIME`；步行使用 `Walking`。复用现有分段上限、混合交通、防抖和过期结果丢弃规则。加载和查询错误都是真实失败，保留确认保存交互。首站导航使用高德 HTTPS 页面，实际是否唤起原生 APP 由高德和浏览器决定。参见[高德 JS API 2.0](https://a.amap.com/jsapi/static/doc/index.html)。
