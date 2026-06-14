# SageRoute UI 说明文档

**版本**: v20260614 | **最后更新**: 2026-06-14 | **平台**: Flutter (Material 3)

> 本文档按页面分类，说明 `lib/` 下每个 UI 代码块对应的可视化功能，帮助后续程序员快速理解进度与结构。

---

## 目录

1. [入口与导航结构](#1-入口与导航结构)
2. [引导页 (LandingPage)](#2-引导页-landingpage)
3. [主界面 (MainScreen + BottomNav)](#3-主界面-mainscreen--bottomnav)
4. [首页 (HomePage)](#4-首页-homepage)
5. [人物列表 (FiguresListPage)](#5-人物列表-figureslistpage)
6. [人物详情 (FigureDetailPage)](#6-人物详情-figuredetailpage)
7. [景点详情 (LocationDetailPage)](#7-景点详情-locationdetailpage)
8. [创建路线向导 (CreateRouteWizard)](#8-创建路线向导-createroutewizard)
9. [路线规划 (RoutePlannerPage)](#9-路线规划-routeplannerpage)
10. [收藏页 (SavedRoutesPage)](#10-收藏页-savedroutespage)
11. [个人页 (ProfilePage)](#11-个人页-profilepage)
12. [地图探索 (MapExplorerPage)](#12-地图探索-mapexplorerpage)
13. [导览页 (GuidePage)](#13-导览页-guidepage)
14. [名人选择 (CelebritySelectionPage)](#14-名人选择-celebrityselectionpage)
15. [设置页 (SettingsPage)](#15-设置页-settingspage)
16. [共享组件](#16-共享组件)
17. [主题系统](#17-主题系统)

---

## 1. 入口与导航结构

### `lib/main.dart`

| 代码区域 | 行号（基于原项目） | 可视化功能 |
|---------|------|-----------|
| `SageRouteApp` | 80-146 | 应用根组件。初始化 DatabaseService → 解析高德 Key → 渲染 `AppLaunchDecider` |
| `AppLaunchDecider` | 148-199 | 判断是否显示引导页：`SharedPreferences` 中 `hasSeenOnboarding` 为 false → LandingPage，否则 → MainScreen |
| `MainScreen` | 201-347 | **主导航框架**。4-tab IndexedStack（惰性构建，防 ANR）+ 底部自定义导航栏 + 规划按钮 push 路线向导 |
| `_resolveAmapKey()` | 36-61 | 高德 Key 解析链: dart-define → assets/env.env → dart_define.json → missing |

**导航结构**: LandingPage → MainScreen (4 tabs) + 可 push: CreateRouteWizard + FigureDetailPage + LocationDetailPage + GuidePage

---

## 2. 引导页 (LandingPage)

**文件**: `lib/views/landing_page.dart`

登录/品牌欢迎页。

| 代码区域/Widget | 行号 | 可视化功能 |
|--------------|------|-----------|
| Hero Image + Gradient Mask | 48-81 | 全屏 Unsplash 图片，半透明渐隐到底色 `#F5F0EA` |
| Badge | 125-148 | 毛玻璃圆角标签：`历史足迹 \| 跨越时空的旅途` |
| `_TitleRow` | 426-453 | 品牌标题 `Sage —— Route` (44px, 加粗) |
| 主按钮 | 219-283 | `开启旅程` → 黑色背景 + 陶土色箭头圆圈 + 阴影 |
| 副按钮 | 287-309 | `登录以继续` → 描边按钮 |
| 三方登录 | 337-385 | 谷歌 / 苹果 / 微信 三个品牌按钮（均为 UI 占位） |
| 条款文字 | 388-418 | 使用条款与隐私政策链接文本 |

---

## 3. 主界面 (MainScreen + BottomNav)

### `lib/main.dart` — MainScreen

| 行号 | 功能 |
|------|------|
| 208-213 | 状态: `_selectedIndex`, 4 个 tabs + 名人弹层 + `_newRouteDrafts` 路线草稿列表 |
| 219-220 | 惰性 tab 构建: 只首次访问时才构建页面 |
| 224 | `_navToTab` 映射: 导航栏 0→首页, 1→人物, 3→收藏, 4→我的 |
| 242-258 | 中间按钮(索引2)触发 `Navigator.push(CreateRouteWizard)`，await 返回 `NewRouteDraft`，存入列表 + 跳转首页 + 显示 SnackBar "行程已保存" |
| 304-347 | `Stack` 布局: 底部导航栏始终显示 + 可选名人选择 Overlay 弹层 |

### `lib/components/bottom_nav.dart` — SageRouteBottomNav

| 代码区域 | 功能 |
|---------|------|
| 5-tab 布局 | 5 个导航项: 首页 / 人物 / **规划(中间)** / 收藏 / 我的 |
| `_buildCenterTab()` | 中间 `规划` 按钮: 46px 圆形陶土色 `#C37153` + 白色 `+` 图标 |
| 激活态 | 选中 tab 背景变圆 `#EAE4D8` |
| 视觉风格 | 半透明米色背景 `#F4F0E8`, 顶部边框线 |

---

## 4. 首页 (HomePage)

**文件**: `lib/views/home_page.dart`

| 代码区域 | 行号 | 可视化功能 |
|---------|------|-----------|
| Header | 51-123 | 左侧: `你好，旅行者` + `准备好探索历史了吗？` |
| 图标区 | 83-97 | 通知铃铛(圆背景) + 头像(陶土色描边环 + Unsplash 头像) |
| 已创建路线 | 128-170 | 遍历 `createdRoutesListenable` 渲染 TicketCard |
| 示例卡片 | 147-166 | 白居易江南遗迹(4天3晚) / 苏轼杭州诗意行(WEEKEND WALK 印章) |

**TicketCard 组件** (`lib/components/ticket_card.dart`):

| 代码区域 | 功能 |
|---------|------|
| 左白主体 | 定位图标 + 标题 + 日期 + 成员信息 |
| 右存根 | TRAVEL JOURNAL 标识 + 时长/里程数据 |
| 剪票缺口 | 左右分界处的圆形空洞 |
| 文化印章 | 右下角旋转 -15° 的圆形印章线（如 MY TRIP / PASSED） |

---

## 5. 人物列表 (FiguresListPage)

**文件**: `lib/views/figures_list_page.dart`

与 Web 版 `FiguresList.tsx` 对应。

| 代码区域 | 行号 | 可视化功能 |
|---------|------|-----------|
| 品牌 Header | 88-129 | `Sage —— Route` + 通知铃铛 + 头像 |
| 标题区 | 133-175 | `历史人物`(小标注) + `历史名人`(大标题, 30px) + 描述 |
| 搜索栏 | 179-228 | 圆角搜索栏 + 搜索图标 + 占位文字 + 右侧 Filter 按钮 |
| 朝代筛选 | 233-264 | 水平滚动胶囊: 全部/唐朝/宋朝/汉朝/周朝/明朝 |
| 主题筛选 | 267-287 | 水平滚动胶囊: 全部/诗词/哲学/帝王/军事(带 Emoji) |
| 精选人物卡片 | 429-611 | 全宽图片(4:3) + 朝代标签 + 角色标签 + 书签 + 统计(遗址/路线) |
| 精选路线 | 334-399 | 横向短路线卡片: 庐山隐居/浔阳贬谪/长安岁月 |
| 全部人物网格 | 690-715 | 2 列网格: 每卡片含图片 + 朝代绿标 + 书签 + 名称 + 年限 + 角色 + 查看按钮 |
| 加载更多 | 719-747 | `加载更多人物` 禁用按钮(UI 占位) |
| `_FigureCard` | 872-1098 | 单个人物卡片组件: 图片区(圆角) + 朝代标签(绿色 `#84A98C`) + 书签 + 底部统计+查看 |

---

## 6. 人物详情 (FigureDetailPage)

**文件**: `lib/views/figure_detail_page.dart`

5段滚动详情页，使用 `CustomScrollView + SliverAppBar` + `DetailScrollSpyController`。

| 代码区域 | 行号 | 可视化功能 |
|---------|------|-----------|
| SliverAppBar | 101-171 | 展开高度 280px，渐变背景，返回/收藏/分享按钮，可折叠 |
| Tab 栏 | 162-170 | 5 个可滚动 tab: **生平 / 遗址 / 名言 / 地图 / 作品**，吸顶固定 |
| 个人资料 | 237-312 | 名称 + 拼音(Georgia 斜体) + 年代 + 角色标签(诗人绿/官员金/哲学家红) |
| 统计卡片 | 318-370 | 4 项指标: 遗址(陶土红) / 旅程(绿) / 诗编(金) / 评分(星) |
| 操作按钮 | 376-436 | `规划路线`(黑色主按钮) + `地图`(描边) |
| 生平段落 | 446-480 | 按空行分段的人物简介文字 |
| 遗址列表 | 498-533 | 遗址卡片: 首字头像 + 名称 + 地区 + 标签 → 点击跳转 LocationDetailPage |
| 名言区块 | 540-555 | 引用框: 左边框陶土红线 + 引文 + 出处 |
| 地图示意 | 562-598 | 180px 高容器，虚线路径 + 标注点(长安/九江/杭州/洛阳) |
| 作品列表 | 604-619 | 作品名 + 类型标签(绿色) |

**关键工具类**: `lib/utils/detail_scroll_spy_controller.dart` — 滚动监听，自动切换高亮 Tab，支持点击 Tab 跳转段落。

---

## 7. 景点详情 (LocationDetailPage)

**文件**: `lib/views/location_detail_page.dart`

与人物详情统一设计语言。

| 代码区域 | 行号 | 可视化功能 |
|---------|------|-----------|
| Hero 图片 AppBar | 107-262 | 展开 340px，图片 + 渐变遮罩 + 照片数量角标 + 面包屑导航 |
| Tab 栏 | 252-261 | 5 tab: **故事 / 背景 / 意义 / 图像 / 旅行** |
| 标题区 | 316-427 | 名称 + 拼音 + 地区 + 评分星标(白色卡片) |
| 标签 | 434-461 | 4 色主题标签(地标绿/关联红/遗产金/免费青) |
| 统计仪表 | 468-516 | 全长 / 游览时间 / 相关诗篇 / 摄影 |
| 操作按钮 | 522-581 | `加入路线` + `导航` |
| 故事/背景/意义 | 588-618 | 内容段落 |
| 图像网格 | 621-653 | 2列网格，4 张 Unsplash 图片 |
| 旅行(游记) | 655-666 | 占位: `暂无游记内容` |

---

## 8. 创建路线向导 (CreateRouteWizard)

**文件**: `lib/views/create_route_wizard/create_route_wizard.dart`  
**Part 文件**: `lib/views/create_route_wizard/create_route_wizard_widgets.dart` — 剧场票据卡片、日历、面板等共享组件  
**步骤文件**: `lib/views/create_route_wizard/steps/step{1,2,3}_*.dart`

4 步全屏创建路线流程（2026-06-14 合并：原 NewRouteTheatreOverlay 的剧场入场 + 日历选择现为 Step 1）。

### 框架 (create_route_wizard.dart)

| 代码 | 功能 |
|------|------|
| `CreateRouteWizard` | **无参数** Widget。通过 `Navigator.push` 进入，`pop(NewRouteDraft)` 返回结果，null 表示取消 |
| Header | 返回按钮(圆圈箭头) + `STEP X OF 4` 标注 + 步骤标题 |
| 进度条 | 4 段横条: 已完成「陶土色」/ 未完成「浅灰」动画过渡 |
| PopScope | `canPop: _currentStep == 1` — 步骤 2/3/4 时系统返回先回退到上一步 |
| 底部按钮 | 步骤 2-3: `下一步`；步骤 4: `保存行程`（含禁用态判断）；步骤 1 无底部按钮(由面板内按钮接管) |
| 归档动画 | 步骤 4 点击保存后: 半透明遮罩覆盖层 + 缩放对勾图标 + "行程已保存" 文字 → 1.8s 后 `pop(draft)` 返回 |

### Step 1 — 行程规划 / 剧场入场 (原 NewRouteTheatreOverlay)

| 阶段/代码 | 可视化效果 |
|----------|-----------|
| `_TheatrePhase` 状态机 | 4 阶段: hidden → flyIn → zoomTitle → datePicker |
| 入场动画 | 票据从下方飞入(850ms easeOutBack) → 放大标题进入焦点(950ms) → 显示输入面板 |
| 票据卡片 (`_TheatreTicketCard`) | 左右分色(白/米) + 打孔缺口 + 左:定位图标/标题/日期 + 右:TRAVEL JOURNAL/时长/里程 |
| 空态骨架屏 | 标题/日期为空时显示灰色骨架线动画 |
| 标题输入面板 | `行程标题` TextField + `继续选取日期` 确认按钮 |
| 日历选择面板 | 6月日历网格(30天), 日期范围选择 + 起点/终点陶土圆 + 区间半透明高亮 |
| `_DayCell` | 单日格子: 起点/终点圆形陶土色, 区间半透明, 未选中无背景 |
| 完成按钮 | `完成并开始规划` → 进入 Step 2 |

### Step 2 — 选择人物 (step1_figure.dart)

| 代码 | 功能 |
|------|------|
| 标题 | `您想追随哪位名人的足迹？` |
| 列表 | 联系人风格: 首字头像 + 姓名 + 朝代·简介 |
| 选中态 | 背景高亮 + 头像色变化 + 圆形 check 图标 |
| 查看详情 | 每个条目右侧 info 按钮 → FigureDetailPage |

### Step 3 — 选择主题 (step2_theme.dart)

| 代码 | 功能 |
|------|------|
| 3 主题卡片 | 诗词足迹(🍃) / 地方美食(🥢) / 名胜古迹(🏛️) |
| 选中态 | 边框变为陶土色 + check 圆圈 |
| 预览区 | 选中后显示横向预览图片(带渐变遮罩和标签) |

### Step 4 — 探索地图 (step3_map.dart)

| 代码 | 功能 |
|------|------|
| AMapWidget | 高德地图底图 |
| 可拖拽面板 | 从底部弹出，上下拖拽调整高度(18%~72%) |
| 左侧已选地点 | 带序号 + 可拖拽排序(ReorderableListView) + 删除按钮 |
| 右侧可用地点 | 点击添加，按名字排序 |
| 面板拉手 | 顶部横条拖动指示器 |

**注意**: 原 `step4_plan.dart`（行程规划页）已被 Step 1 的剧院流程取代，该文件保留但不再在向导中使用。

---

## 9. 路线规划 (RoutePlannerPage)

**文件**: `lib/views/route_planner_page.dart`

独立的日期与节奏选择页 (`Step4Plan` 的独立版本)。

| 代码 | 功能 |
|------|------|
| 日期卡片 | 出发/返程双卡片，日历图标 + 日期 + 年份 |
| 节奏选择 | 三个并排卡片: 悠闲(🌿) / 适中(⚖️) / 紧凑(⚡) |

---

## 10. 收藏页 (SavedRoutesPage)

**文件**: `lib/views/saved_routes_page.dart`

| 代码 | 行号 | 功能 |
|------|------|------|
| Header | 64-87 | `我的收藏` + `保存的路线与历史遗迹` |
| Tab 栏 | 91-103 | 3 tab: 保存的路线(含计数) / 历史人物(占位) / 地点(占位) |
| 空态 | 153-182 | 无收藏时: 书签图标 + `还没有收藏的路线` |
| 路线卡片 | 211-517 (`_RouteCard`) | 图片头(渐变遮罩) + 日期角标 + 名称 + 统计(天/景点/公里/地名) + 人物头像重叠 + 查看行程按钮 |
| 头像重叠 | 427-465 | 人物头像 + 错位 `+8` 计数徽标 |

---

## 11. 个人页 (ProfilePage)

**文件**: `lib/views/profile_page.dart`

| 代码 | 行号 | 功能 |
|------|------|------|
| Header | 96-152 | 头像(96px 圆 + 装饰环) + 名称 + 简介 + 设置图标(右上角) |
| 统计行 | 180-229 | 解锁成就(陶土色) / 探索地点(绿) / 完成路线(金) → 竖线分隔 |
| 成就卡片 | 246-353 | 横向滑动: 图标圆 + 名称 + 描述，未解锁半透明+锁 |
| 成就映射 | 336-352 | icon 名→Material Icon 映射: book/compass/crown/star/camera/quote |
| 设置列表 | 357-453 | 账号信息 / 旅行偏好 / 语言设置(简体中文) / Debug → 带箭头跳转 |
| 退出按钮 | 457-484 | `退出登录` 按钮(米色背景 + 陶土色文字 + 图标) |

---

## 12. 地图探索 (MapExplorerPage)

**文件**: `lib/views/map_explorer_page.dart`

独立的浏览用地图页，使用高德地图 SDK。

| 代码 | 行号 | 功能 |
|------|------|------|
| AMapWidget | 42-51 | 高德地图(初始位置: 杭州西湖 30.259, 120.147, zoom 14) |
| 搜索栏 | 54-59 | 顶部白色圆角 + 搜索图标 + `搜索附近的历史遗迹...` + Filter 图标 |
| 筛选胶囊 | 62-67 | 水平滑动: 全部历史遗迹 / 白居易路线-杭州 / 宋代 |
| 浮动按钮 | 70-73 | 右下方: 指南针 + 定位(白色圆+阴影) |
| 底部预览卡片 | 76-84 | 定位图标 + 图片(带朝代角标) + 名称 + 地区 + 距您距离 |

---

## 13. 导览页 (GuidePage)

**文件**: `lib/pages/guide/guide_page.dart` + 5 个 `part` 文件

全屏高德地图导览页，用于实地导航。

| Part 文件 | 功能 |
|-----------|------|
| `guide_page.dart` | 主页面: AMapController + 定位权限 + 预览点动画(随机漂移+落定) + 缓存标记 |
| `guide_location_logic.dart` | 定位逻辑: 权限申请 + 定位触发 + 定位图标合成 |
| `guide_map_assets.dart` | 地图资源: 自定义 Marker 图标 Bitmap 加载 |
| `guide_marker_builder.dart` | Marker 构建: 将数据库 LocationRecord 转为高德 Marker |
| `guide_preview_animation.dart` | 预览点动画: 随机方向漂移 + 落定动画 |
| `location_detail_sheet.dart` | 景点详情 Sheet: 底部弹出详情面板 |

当前状态：高德地图 SDK 已集成，定位/权限/Marker 逻辑已完成，但未正式接入后端数据。

---

## 14. 名人选择 (CelebritySelectionPage)

**文件**: `lib/pages/celebrity_selection/celebrity_selection_page.dart`  
**Part 文件**: `celebrity_overlay_animation.dart`, `celebrity_overlay_painter.dart`, `celebrity_carousel_widgets.dart`

从底部圆形展开的全屏名人选择器。

| 代码 | 功能 |
|------|------|
| 圆形展开动画 | 从底部按钮位置圆形扩散，背景 `AnimatedBuilder` 驱动 |
| 加载态 | 圆形进度指示器 + `加载人物中...` |
| 空态/错误态 | 分别显示 `暂无人物数据` / `人物数据加载失败` |
| 人物轮播 | 横向滑动切换 + 手势 `onHorizontalDragEnd` |
| 两阶段 | character(选人) → reveal(选主题后展示) |
| 话题选择 | 按人物加载话题列表，默认选中第一个 |

---

## 15. 设置页 (SettingsPage)

**文件**: `lib/pages/settings_page.dart`

| 代码 | 功能 |
|------|------|
| 设置标题 | `设置` |
| 切换人物 | Card + ListTile: 图标 + `切换人物` + 描述 + 箭头 → CelebritySelectionPage |

---

## 16. 共享组件

| 组件文件 | 用途 |
|---------|------|
| `lib/components/bottom_nav.dart` | 5-tab 自定义底部导航栏 |
| `lib/components/ticket_card.dart` | 行程票据卡片（首页复用） |
| `lib/components/detail_content_section.dart` | 详情页段落包装（标题 — 副标题 + 内容 + 可选"查看全部"） |
| `lib/components/detail_circle_button.dart` | 详情页圆形小按钮（返回/收藏/分享） |
| `lib/components/detail_scroll_tab_bar.dart` | 详情页可滑动的吸顶 Tab 栏 |
| `lib/components/sage_search_bar.dart` | 通用搜索栏 |
| `lib/components/sage_tab_bar.dart` | 通用分段 Tab 栏（收藏页使用） |
| `lib/components/section_title.dart` | 区块标题组件 |
| `lib/components/detail_circle_button.dart` | 提供 `DetailCircleButton` + `DetailCircleButton.back()` |

---

## 17. 主题系统

**文件**: `lib/theme/color_schemes.dart` / `app_theme.dart` / `components.dart` / `typography.dart`

| 文件 | 内容 |
|------|------|
| `color_schemes.dart` | `AppColors` 品牌色板: sageBg(#F5EFEB), sageAccent(#B96144 陶土色), sageText(#2D2825), sageGreen(#84A98C) |
| `app_theme.dart` | Material 3 `lightTheme` / `darkTheme` 构建 |
| `typography.dart` | 自定义字体配置 |
| `components.dart` | 组件主题覆盖 (Card/Button/Input 等) |

### 品牌色定义

```
sageBg        #F5EFEB   — 页面背景米色
sageCard      #FAF7F2   — 卡片背景
sageText      #2D2825   — 主要文字
sageMuted     #857F75   — 次要文字
sageAccent    #B96144   — 强调色/陶土红
sageBorder    #E8E2D9   — 边框
sageGreen     #84A98C   — 绿色点缀
sageGold      #D4AF37   — 金色点缀
primaryLight  #C37153   — 浅色主要色
```

---

## 当前状态总结

### 已完成
- ✅ 完整导航框架 (MainScreen + 5-tab BottomNav)
- ✅ 引导页 (LandingPage) — UI 完成
- ✅ 首页 (HomePage) — Header + TicketCard 展示
- ✅ 人物列表 (FiguresListPage) — 筛选栏 + 精选卡片 + 双列网格
- ✅ 人物详情 (FigureDetailPage) — 5 段 Tab 滚动
- ✅ 景点详情 (LocationDetailPage) — 5 段 Tab + 图片网格
- ✅ 创建路线向导 (CreateRouteWizard) — 4 步合并流程：剧场入场+日历(Step1) → 人物(Step2) → 主题(Step3) → 地图(Step4) + 归档动画
- ✅ 收藏页 (SavedRoutesPage) — 路线卡片展示 + 空态
- ✅ 个人页 (ProfilePage) — 头像 + 成就 + 设置列表
- ✅ 地图探索 (MapExplorerPage) — AMap + UI 覆盖层
- ✅ 导览页 (GuidePage) — AMap + 定位 + Marker
- ✅ 名人选择 (CelebritySelectionPage) — 轮播选择器
- ✅ 设置页 (SettingsPage) — 基本结构
- ✅ 主题系统 — Material 3 亮/暗主题

### 待开发/已知占位
- ⬜ 真实搜索功能
- ⬜ 筛选逻辑（朝代/主题/类别）
- ⬜ 后端数据对接（当前使用 mock 数据）
- ⬜ 收藏/登录/社交登录真实功能
- ⬜ 收藏页子 Tab（历史人物/地点）
- ⬜ 路线规划完整性（保存/分享）
- ⬜ 游记内容
