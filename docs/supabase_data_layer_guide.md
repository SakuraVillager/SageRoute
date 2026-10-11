# Supabase 通用数据层使用说明

本文档说明本项目如何复用 **查询、重试、过滤** 逻辑，避免每个表重复写一套 Supabase 访问代码。

## 1. 整体结构

- `lib/services/database_service.dart`
  - 负责 Supabase 初始化（读取 `assets/env.env`）
  - 提供 `runQueryWithRetry`，统一重试与异常处理
- `lib/data/supabase_table_repository.dart`
  - 通用表访问层：按 `tableName` 查询，支持等值过滤
  - 可直接返回原始行，也可映射为模型对象
- `lib/models/*.dart`
  - 每张表一个模型，提供 `fromMap` / `toMap`
- `lib/data/*_repository.dart`
  - 每张表一个仓储，对业务层暴露强类型查询方法

---

## 2. 启动前初始化

在 `main.dart` 中已完成初始化：

```dart
await DatabaseService.initialize();
```

这一步会读取 `assets/env.env` 里的：

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

---

## 3. 通用查询（可复用）

### 3.1 查询原始行

```dart
const tableRepo = SupabaseTableRepository(tableName: 'Topic');
final rows = await tableRepo.fetchAllRaw();
```

### 3.2 查询并映射为模型

```dart
const tableRepo = SupabaseTableRepository(tableName: 'Topic');
final topics = await tableRepo.fetchAll<TopicRecord>(
  mapper: TopicRecord.fromMap,
);
```

---

## 4. 重试逻辑（可复用）

所有通过 `SupabaseTableRepository` 发起的请求，底层都会走：

```dart
DatabaseService.runQueryWithRetry(...)
```

当前策略：

- 默认重试次数：2 次（总尝试 3 次）
- 重试场景：超时、网络异常（如 `SocketException`）
- 退避间隔：逐次递增（毫秒级）

如果你要在其他地方直接写 Supabase 查询，也建议包一层：

```dart
final response = await DatabaseService.runQueryWithRetry(
  () => DatabaseService.client.from('Dynasty').select(),
  operationName: 'manual.fetchDynasty',
);
```

---

## 5. 过滤逻辑（可复用）

通用仓储支持等值过滤：

```dart
final rows = await tableRepo.fetchAllRaw(
  equals: {'celebrity': '苏东坡'},
);
```

或在业务仓储中封装为语义方法：

```dart
Future<List<TopicRecord>> fetchTopicsByCelebrity(String name) {
  return _tableRepository.fetchAll<TopicRecord>(
    mapper: TopicRecord.fromMap,
    equals: {'celebrity': name},
  );
}
```

当前内置过滤是“字段 = 值”。
如需范围查询、模糊查询、排序等复杂条件，建议在对应 `*_repository.dart` 中新增专用方法。

---

## 6. 新增一张表的推荐步骤

1. 在 `lib/models/` 新建模型（`fromMap/toMap`）。
2. 在 `lib/data/` 新建该表 repository，内部持有：

   ```dart
   const SupabaseTableRepository(tableName: '你的表名')
   ```

3. 暴露业务方法（如 `fetchAll`、`fetchByXxx`）。
4. 页面/业务层只依赖强类型模型，不直接处理裸 `Map`。

---

## 7. 已落地的表

- `Celebrity`
- `Topic`
- `Location`
- `Dynasty`
- `poi_celebrity_relatian`
