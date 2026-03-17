# 通用数据与模型分层教程

本文面向正在阅读本项目数据层逻辑的协作者，主要说明 `models` 与 `data` 目录的分工，并详细列出每个仓储提供的方法，方便快速上手各张表的常见业务查询。

## 1. 为什么要分两层？

- `models/*.dart`：只管“什么字段有、类型是什么”。它定义了一张表对应的 Dart 对象，方便后续 UI/逻辑直接操作 `CelebrityProfile`、`LocationRecord` 这样的类，而不是频繁写 `row['name']`。
- `data/*.dart`：只管“怎么拿到数据”。它直接与 Supabase 交互，包含：
  1. 统一重试/超时（复用 `DatabaseService.runQueryWithRetry`）
  2. 统一过滤方式（通过 `SupabaseTableRepository.fetchAll` 的 `equals`）
  3. 根据模型 `fromMap` 把 Map 变成对象

如果把两者混在一起，每次要写查询都得重复 `SupabaseTableRepository` 里那些逻辑，代码就很难维护，测试也麻烦。

## 2. 数据流程示意

1. 页面/业务层调用 `TopicRepository.fetchTopics()`。
2. 仓储通过 `SupabaseTableRepository.fetchAll<TopicRecord>` 向 `topic` 表发请求。
3. `SupabaseTableRepository` 交给 `DatabaseService.runQueryWithRetry`，统一处理重试。
4. 拿到 `List<Map>` 后，逐条 `TopicRecord.fromMap`转换为对象。
5. 页面直接拿 `TopicRecord` 里的字段，不再关心原始 Map。

## 3. 仓储方法概览

每个仓储都基于 `SupabaseTableRepository`，暴露语义化方法；调用方可根据业务直接使用如下方法。

- `CelebrityRepository`
  - `fetchCelebrities()`：获取 `Celebrity` 表的所有人物并返回 `CelebrityProfile`。
  - 支持传入测试用 `fetcher`，方便单元测试。
- `TopicRepository`
  - `fetchTopics({int? limit})`：拉全部 `Topic` 记录，可限制数量。
  - `fetchTopicsByCelebrity(String celebrityName)`：按人物名等值过滤 `Topic`。
- `LocationRepository`
  - `fetchLocations({int? limit})`：分页/全表读取 `Location`，返回 `LocationRecord`。
  - `fetchLocationsByTopic(String topicName)`：按 `Topic` 字段过滤。
  - `fetchArEnabledLocations()`：只拿 `is_ar_enabled = true` 的地点。
- `DynastyRepository`
  - `fetchDynasties({int? limit})`：拉全部朝代记录。
- `PoiCelebrityRelationRepository`
  - `fetchRelations({int? limit})`：读取所有人物-地点关系。
  - `fetchRelationsByCelebrity(String celebrityName)`：按人物名过滤。
  - `fetchRelationsByLocation(String locationName)`：按地点名过滤。

这些方法都自动处理查询、重试、等值过滤，返回强类型模型，业务仅需关注字段含义。

## 4. 具体示例续

```dart
const topicRepo = TopicRepository();
final topics = await topicRepo.fetchTopicsByCelebrity('苏东坡');
final firstTopicName = topics.first.name;
```

调用方只需关心业务参数（人物名），仓储封装了“查询哪个表”“过滤哪个字段”“转换为模型”的全部细节。

## 4. 新增表的步骤（复用通用逻辑）

1. 在 `lib/models/` 新增一个类（字段 + `fromMap` + `toMap`）。
2. 在 `lib/data/` 新增一个仓储类，内部持有 `const SupabaseTableRepository(tableName: '表名')`。
3. 提供业务友好的方法（如 `fetchByXxx`），必要时传入 `equals` 让查询支持过滤。
4. 页面/业务层直接依赖模型类，保持整洁。

## 5. 为什么仓储不多余？

离开仓储意味着：
- 每个页面都得直接写 Supabase 查询语句，改动同样字段要同步更新很多地方。
- 没有统一的重试/过滤策略，容易漏写 `runQueryWithRetry`。
- Unit test 难 mock Supabase 查询，必须启动真实 client。

仓储层把这些重复逻辑抽成一个地方，即便表很多也只要写一次，业务层可集中在“需要哪些数据”上。

## 6. 常见术语

- **模型（Model）**：字段定义 + 数据转换，位于 `lib/models/`。
- **仓储（Repository）**：调用 Supabase、处理重试、返回模型，位于 `lib/data/`。
- **通用表仓储**：`SupabaseTableRepository`，不同表共享查询/过滤能力。
- **界面层**：只需 `TopicRepository` 返回的对象，避免接触原始 JSON。
