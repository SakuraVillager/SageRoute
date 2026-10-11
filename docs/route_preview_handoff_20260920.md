# 首页票据 → 路线预览/编辑页 + 路线 Supabase 持久化 — 交接文档

日期：2026-09-20
分支：figure配置V1（工作区未提交改动）
状态：代码完成，全部测试通过（298 个），**待手动执行数据库 migration 后真机验收**

---

## 一、需求背景

首页（`home_page.dart`）上的行程票据此前点击无任何跳转；路线保存是模拟的（假延迟后弹回一个只有 5 个字符串的 `NewRouteDraft`，重启即丢）。本轮实现：

1. 点击首页新建票据 → 打开**导航/预览页**（高德地图 + 行程面板，即规划向导第 3 步的只读形态），右上角可进入编辑；
2. **编辑页**与向导第 3 步完全一致的编辑能力，保存后更新路线并返回预览页刷新；
3. 路线数据（含人物、途经点坐标、每段交通方式）**真实落库 Supabase**。

已确认的决策：「开始导航」为占位按钮（点击弹"即将上线"）；两张预设票据（白居易/苏轼）不开放入口；编辑页是独立页面托管 `Step3Map`，不套向导框架。

## 二、改动清单（按层）

### 1. 数据库（⚠️ 需手动执行）

- **`supabase/migrations/20260919_create_user_routes.sql`**（新文件）
  - `user_routes`：id/uuid、user_id（关联 auth.users，级联删除）、title、date_range、duration、distance、figure_id、figure_name、created_at/updated_at（触发器自动刷新）。
  - `user_route_waypoints`：route_id 外键级联删除、sort_order、name/latitude/longitude（坐标**冗余存储**，预览/编辑不 join Location 表）、location_id（可选回链）、visit_duration_min、transport_to_next（driving/walking）。
  - 两张表均开启 RLS：仅路线属主可增删改查（waypoint 通过 exists 子查询校验归属）。
  - **项目无 supabase CLI，migration 只是 SQL 文件，需在 Supabase 控制台 SQL 编辑器手动执行。**

### 2. 数据层

- `lib/data/supabase_table_repository.dart`
  - 基类原本**只有读方法**，新增 `insertRaw`（返回写入行，含数据库生成的 id）、`insertAllRaw`、`updateRaw`、`deleteRaw`。
  - 沿用既有模式：底层走 `DatabaseService.runQueryWithRetry`，可注入 `RawTableWriter` 便于测试。
- `lib/models/saved_route.dart`（新文件）
  - `SavedRoute`（id/title/dateRange/duration/distance/figureId/figureName/waypoints）与 `RouteWaypoint`（name/lat/lon/locationId/visitDurationMin/transportToNext），含 `fromMap/toMap`、`copyWith`。
  - 转换边界：`RouteWaypoint.fromRoutePlace(place, transportToNext:)` 与 `toRoutePlace()`——规划引擎用 `RoutePlace`，持久化用 `RouteWaypoint`。
- `lib/data/user_route_repository.dart`（新文件）
  - `fetchUserRoutes()`（当前用户全部路线，新→旧，途经点按 sort_order 组装）、`fetchRouteById()`、`createRoute()`（插入路线行 + 批量插途经点，返回新 id）、`updateWaypoints()`（delete + 重插全量替换）。
  - user id 取自 `DatabaseService.client.auth.currentUser`；未登录抛 `StateError`。routes/waypoints 两个表仓库与 userId 提供器均可注入（测试用）。
  - 注意：fetch 是"每路线一次 waypoint 查询"的 N+1，当前数据量小可接受，后续可改 `in` 查询。
- `lib/data/celebrity_repository.dart`：新增 `fetchById(int id)`（编辑页回填人物用）。

### 3. Step3Map 预览模式（`lib/views/create_route_wizard/steps/step3_map.dart`）

- 新增 `enum Step3Mode { edit, preview }`，**默认 edit，向导行为完全不变**（既有测试不回归）。
- 新增构造参数：
  - `mode`：preview 下隐藏添加/清空按钮、删除/排序/交通切换入口，列表改普通只读 ListView，footer「保存行程」换成「开始导航」（回调 `onStartNavigation`）；
  - `onTransportTypesChanged`：交通方式变更回传（key 为 `Step3Map.segmentKey(from, to)` 格式 `fromId:fromName->toId:toName`），供持久化；
  - `initialSegmentTransports`：按地点顺序恢复每段交通方式。
- 子组件 `_SelectedPlaceChip`/`_ItineraryTimelineTile`/`_SegmentTransportRow` 回调改可空 + 新增 `interactive` 标志，预览态只读渲染。

### 4. 两个新页面（`lib/views/route_preview/`，新目录）

- `route_preview_page.dart`：`RoutePreviewPage({routeId})`。进入时按 id 加载（加载中/失败重试/不存在三态）；半透明顶部栏（返回 + 标题 + 编辑）；主体 `Step3Map(preview)`；编辑返回 `true` 则重新加载刷新。
- `route_edit_page.dart`：`RouteEditPage({route})`。`Step3Map(edit)` 全功能；`figureId` 非空时异步回填 `CelebrityProfile`（失败降级 null，仅影响"添加地点"推荐）；「保存行程」→ `updateWaypoints` → `pop(true)`；保存中有遮罩。
- **实现注意**：两个页面的根 Stack 必须包 `SizedBox.expand`——Stack 在松散约束下会收缩到非 positioned 子项（顶部栏）的高度，导致地图只有 ~44px（开发中实际踩过，已修并验证）。

### 5. 保存链路接线

- `create_route_wizard.dart`：`_handleSave` 由假保存改为真实 `createRoute`（保留 900ms 归档动画再 `pop(SavedRoute)`）；新增 `_segmentTransportTypes` 状态经 `onTransportTypesChanged` 同步。
- `main.dart`：`_newRouteDrafts` 换成 `_savedRoutes`（`ValueNotifier<List<SavedRoute>>`）；`initState` 拉取用户路线；向导返回后插入列表（首页 AnimatedList 插入动画保留）。
- `home_page.dart`：列表类型 `NewRouteDraft` → `SavedRoute`；新建票据补 `onTap` 跳预览页（`slideFromRightRoute`）。
- `lib/models/new_route_draft.dart`：**已删除**（引用全部清理，docs/ui_overview_v20260622.md 中的旧描述可后续更新）。

## 三、数据流

```
创建：向导 step3 → onLocationsChanged/onTransportTypesChanged → _handleSave
      → createRoute（user_routes + user_route_waypoints）→ pop(SavedRoute)
      → main.dart 插入 _savedRoutes → 首页票据

查看：首页票据 onTap → RoutePreviewPage(routeId)
      → fetchRouteById → waypoints.toRoutePlace() → Step3Map(preview)

编辑：预览页编辑按钮 → RouteEditPage(route)
      → Step3Map(edit) → _handleSave → updateWaypoints（delete+重插）
      → pop(true) → 预览页 _load() 刷新
```

## 四、验证情况

- `flutter analyze`：无 error（剩余 58 条 info 绝大多数为 register_page 等历史代码遗留）。
- `flutter test`：**298 个全部通过**（~2 skip 为既有）。新增 13 个：
  - `test/models/saved_route_test.dart`：模型映射、map 往返、copyWith；
  - `test/data/user_route_repository_test.dart`：注入 fake 表仓库验证排序组装、insert/delete 行数据、未登录抛错；
  - `test/views/route_preview_page_test.dart`：MethodChannel mock（沿用 step3 测试模式）验证只读渲染、marker 顺序、无编辑入口、footer 为「开始导航」、编辑页进出。
- **待真机验收**（需先执行 migration）：创建→首页票据→预览→编辑保存→刷新→杀进程重进确认持久化。

## 五、已知限制 / 后续建议

1. **migration 未执行前**，向导保存会失败（报错 SnackBar，不崩溃）。
2. 预设的两张票据仍是死数据（无坐标），后续如开放需补坐标来源。
3. 「开始导航」占位；项目里有现成的孤儿页面 `GuidePage`（高德导览）可对接。
4. 途经点全量替换（delete+insert）适合当前简单场景；路线编辑粒度变复杂后可改 upsert。
5. 路线汇总数据（总里程/总时长）未持久化，每次进入预览页由 `RoutePreviewCoordinator` 实时计算（240ms 防抖，逐段走原生高德 SDK）。
6. 收藏页（`saved_routes_page.dart`）仍用 `MockRoute`，可后续切到 `UserRouteRepository`。
7. `docs/ui_overview_v20260622.md` 中 NewRouteDraft 的旧流程描述已过时，建议下次更新文档时一并修订。
