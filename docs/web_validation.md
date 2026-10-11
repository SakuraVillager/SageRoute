# SageRoute Web 实施与验证记录

记录日期：2026-10-10。状态：平台适配代码已实现，本地构建和自动检查可运行；真实服务、多账号权限及完整设备矩阵尚未验收，不能视为已上线交付。

## 基线与功能对照

环境为 Flutter 3.41.4 / Dart 3.11.1。保留已有未提交修改，在重叠文件上增量实现；没有更换 SDK 或大规模升级依赖。新增 go_router、package:web、pointer_interceptor 与 SDK flutter_web_plugins，依赖由 pubspec.lock 锁定。基线 analyze 有 54 项提示；基线首页示例测试因 SharedPreferences 异步测试未配置失败，现已补上确定性偏好和等待。

| 功能 | Android 原有数据/能力 | Web 实施 |
|---|---|---|
| 注册、登录、验证、找回密码 | Supabase Auth | 共用服务，站点回调、恢复页、过期重发、邮箱记忆与会话保持 |
| 首页及历史行程 | 远端 user_routes + 本地示例/示例删除偏好 | 延续现状；宽屏侧导航、稳定 URL |
| 人物、专题和文章列表/搜索 | 现有 Supabase 仓储 | 共用仓储，按 ID 恢复详情 |
| 人物关联地点/部分详情 | 远端人物资料，部分地点与内容仍为 mock | 继续保留模拟部分，不声称已补齐后台数据 |
| 地点导览 | Location、Icon 仓储 + 原生地图 | JS 地图、分类图标、地点点击、宽屏操作区、按用户点击定位 |
| 地图探索 | 演示数据，搜索/筛选/浮动按钮为展示占位 | 替换地图底座与宽屏容器；占位交互保持现状 |
| 创建、编辑、预览、删除行程 | 现有规划协调器、user_routes / user_route_waypoints | Web JS 网关、混合方式、分段颜色、顺序、首站 HTTPS 导航、草稿恢复 |
| 收藏页 | 模拟路线、内存收藏 ID，部分内容“即将上线” | 维持原状；不新增远端收藏同步 |
| 个人资料、旅行偏好、语言 | ProfilePreferences 本地存储；仅简体中文启用 | 按浏览器设备独立保存 |
| 成就与统计 | 本地成就/模拟统计 | 沿用现状，不宣称两端同步或新增已完成业务 |

## 自动检查结果

| 检查 | 结果 |
|---|---|
| flutter pub get | 成功；Windows 插件链接权限问题通过已有插件目录 junction 处理，没有修改系统设置 |
| flutter analyze | 无问题 |
| flutter test | 371 项通过、2 项跳过 |
| Web 专项组件/服务测试 | 16 项通过，使用 Edge Chromium，Windows SDK 宿主兼容脚本 |
| JS SDK 桥接 Node 测试 | 5 项通过 |
| flutter build web --release | 成功；使用本地公开 Supabase 参数及已配置的高德 Web Key |
| flutter build apk | 成功；原生回归构建，未等同于 Android 真机验收 |

浏览器测试覆盖经纬度/策略输入、密码不落盘、用户隔离草稿、定位拒绝、地图覆盖物更新与释放、弹窗阻止地图事件、保护详情 URL 登录回跳、无效认证链接、确认放弃草稿、宽窄屏切换保持首页状态。JS 测试覆盖 SDK 单次加载/失败重试、步行/驾车策略映射、路径转换、无路线/授权失败/超时、GCJ-02 定位选项、尺寸变化与释放。原有规划测试继续覆盖多站点、混合交通、过期结果等规则。

本地日志位于 `.dart_tool/web_*.log`，Web 资源检查与体积输出位于 `.dart_tool/web_build_metrics.json`。这些本地文件不作为产品静态资源上传。

## 浏览器与真机范围

| 环境 | 状态 |
|---|---|
| Edge Chromium 自动专项集合 | 已通过，使用模拟服务 |
| 内嵌 Chromium Release 页面 | 已检查启动、认证普通页和宽窄屏；配置后地图 SDK 可加载，步行/驾车实测路线均返回结果 |
| 桌面独立 Chrome | 本机未安装，未验证 |
| Firefox / Safari | 未验证 |
| Android Chrome / iPhone Safari 真机 | 缺少可用设备，未验证；桌面窄屏截图不等同于真机结论 |
| Android APK | 已构建；原生高德与定位真机回归仍待执行 |

## 上线前必须补齐的真实闭环

- [x] 配置高德独立 Web Key 和配套安全密钥；本机 localhost 下步行、驾车路线请求均成功。
- [ ] 确认正式域名白名单和 Driving/Walking/Geolocation 服务权限，并在正式 HTTPS 域名验收定位与瓦片渲染。
- [ ] 配置 Supabase 精确 Web 回调，注册→邮件验证→登录→刷新→退出→找回密码→重置密码；同时回归 Android 协议回调。
- [ ] 同账号 Android/Web 创建和读取多站点行程，验证步行/驾车、换序、编辑、删除和刷新恢复。
- [ ] 真实地图标记、折线、拒绝定位、断网、错误 Key、无路线及重试恢复；确认地图上弹窗和面板不穿透。
- [ ] 从人物、地点、文章及已保存行程 URL 直接进入，验证无权限/删除状态、浏览器前进后退。
- [ ] 两个独立账号与匿名请求验证私人路线和途经点 RLS；不能仅以客户端筛选或 UI 无记录作为证据。
- [ ] 桌面 Chrome/Edge/Firefox/Safari、Android Chrome、iPhone Safari；软键盘、横竖屏、导航到首站。
- [ ] 正式 HTTPS 托管的深链接刷新、资源 404、缓存发布和整站回滚。

目标 Supabase 项目与当前已连接的 MCP 项目不一致，未读取或修改其他项目。现有 `20260919_create_user_routes.sql` 与 `20260923_secure_user_route_persistence.sql` 在仓库中定义了路线/途经点 RLS；这不能证明线上已部署。没有执行新增迁移。可在目标项目 SQL Editor 做只读检查：

已使用本地公开客户端 Key 对目标项目的两张路线表进行匿名 REST 检查，查询为 `select=id&limit=0`，没有请求任何数据行。两者均返回 HTTP 401 / PostgreSQL `42501`，证明当前匿名读取被拒绝；这仍不能证明登录用户之间的隔离。可用 `python tool/check_anonymous_route_access.py` 重复此只读检查，完整结果在 `.dart_tool/web_anonymous_access.json`。

```sql
select schemaname, tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('user_routes', 'user_route_waypoints');

select relname, relrowsecurity
from pg_class
where oid in ('public.user_routes'::regclass,
              'public.user_route_waypoints'::regclass);
```

随后用 A 账号创建路线，B 账号及匿名访问该 ID/途经点、尝试更新及删除，要求被数据库拒绝或返回空结果；最后确认 A 账号数据未变。缺失安全策略时先修复现有后端部署，再发布 Web，不能把服务端管理 Key放入客户端。

## 性能与已知限制

构建使用本地字体和 CanvasKit，SDK 按需加载，不阻塞普通页。保留现有完整中文字体，尚未针对动态内容做字集裁剪。产物体积由 `python tool/check_web_build.py` 实测，完整目录大小包含多个渲染运行时，并非首次网络传输量。

本次产物包含 52 个文件，总未压缩体积约 63.6 MB；主 JS 约 3.38 MB，gzip 后约 0.99 MB，现有中文字体约 25.7 MB。这里使用十进制 MB，不代表正式 CDN 的实际传输量。

Release 视觉记录：[桌面登录](screenshots/web/login-desktop.jpg)、[手机宽度登录](screenshots/web/login-mobile.jpg)、[手机宽度注册](screenshots/web/register-mobile.jpg)。已检查直接 `/login` 启动、按钮打开 `/forgot-password` 时地址更新、返回登录以及注册页；未使用真实账号提交注册或发送邮件。配置高德后本机地图实例创建成功，步行返回 4495 米/3596 秒/203 个折线点，驾车返回 5013 米/1381 秒/130 个折线点。浏览器截图中的地图画布呈浅灰色，因此瓦片视觉渲染尚未确认，不将地图显示验收标为通过。

首次显示、可操作时间、地图就绪时间尚没有正式目标网络的测量；本地 localhost 检查不能替代。正式测量应固定浏览器/设备、网络条件、冷/热缓存和版本，分别记录导航开始→首帧、可点击、首次地图 complete 事件，并记录 DevTools 实际压缩传输量。未提供未经测量的性能承诺。

首版不支持离线编辑、离线地图、后台持续导航、SEO 内容站。浏览器定位须用户主动请求，拒绝后仍能浏览/规划。纯静态的高德安全密钥可读风险按已确认方案保留，代理仅预留配置。地图路线服务已在本机验证，地图瓦片显示、定位、真实认证、双账号权限和完整设备矩阵仍待验收；全部项完成后，才能按计划的最终完成标准签收。

## 2026-10-10 Web 布局重设计

详见 [布局说明与截图](web_layout_redesign.md)。网页侧栏、规划嵌入工作区、紧凑日期弹层、双栏欢迎与认证以及首页和个人中心桌面布局已调整。静态检查无问题；Flutter 测试仍为 371 通过、2 跳过；Web 浏览器集合扩展到 16 项。新一轮日志位于 `.dart_tool/web_redesign_*.log`。规划截图使用示例人物，不能视为真实地图或保存路线的验收证据。
