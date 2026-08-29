# SageRoute 人物页 UX Flows

> Source brief: `product-brief.json` v0.1.0  
> Platform: iOS + Android  
> Date: 2026-08-26  
> Confidence: medium

## Architecture Summary

人物页是发现和保存浏览上下文的持久入口。搜索是独立覆盖层，不改变目录筛选；文章页和人物详情页是层级详情。主题筛选只刷新按主题组织的推送文章列表，人物筛选固定为朝代且只刷新人物目录。

## Requirement Ledger

| ID | Priority | Requirement |
| --- | --- | --- |
| R1 | Must | 从人物页打开相关推送文章或人物页。 |
| R2 | Must | 人物名、文章标题、主题名分别以 `ILIKE '%query%'` 子串匹配，合并后说明结果类型与目标。 |
| R3 | Must | 主题文章筛选和人物朝代筛选独立。 |
| R4 | Must | 两个目录默认七项，可展开/收起。 |
| R5 | Must | 加载、空结果与失败可区分且可恢复。 |
| R6 | Must | 文章左进右返，并恢复人物页上下文。 |
| R7 | Must | 状态可被辅助技术识别。 |
| R8 | Must | 两端遵循各自系统返回行为。 |

## Actors And Objects

- `A1 内容阅读用户`：浏览、搜索、筛选、展开与进入详情，不能修改内容数据。
- `A2 内容服务`：提供文章、人物、主题匹配及失败信息。
- `O1 Search session`：idle → querying → results / empty / failed → dismissed。
- `O2 Topic article directory`：loading → ready-collapsed → ready-expanded；或 empty / failed。
- `O3 Figure directory`：loading → ready-collapsed → ready-expanded；或 empty / failed。
- `O4 Browse context`：active → preserved → restored；缓存失效时进入 stale 并重新加载。

## Critical Flows

### F1 打开文章并返回

人物页加载完成后，用户从精选文章或主题推送文章列表点入文章。系统先保存人物页的滚动位置、搜索词、两个独立筛选与目录展开状态，再左向进入文章页。文章加载失败时可重试或返回；返回使用右向运动并恢复原上下文。

### F2 全局搜索

用户打开搜索覆盖层并输入查询。系统对人物名、文章标题和主题名分别执行 `ILIKE '%query%'`，合并后展示带对象类型和跳转目标的结果。无结果时可以改词、清除或关闭；失败时可以重试或关闭。关闭始终回到未被改动的人物页目录上下文。首版不支持错别字、拼音、别名、繁简转换或复杂排序。

### F3 独立目录筛选与展开

选择主题只刷新主题推送文章列表；选择朝代只刷新人物目录。每个目录独立显示加载、结果、空结果或失败，并各自支持清除与重试。八项及以上默认只展示七项，展开/收起只影响该目录。

### F4 失效推送恢复

系统验证推送深链接的文章或人物目标。有效则直达详情；无效、删除或加载失败则解释原因，并提供重试或进入人物页默认浏览的恢复路径。

## Platform Behavior

- iOS：文章页使用导航栈和系统边缘返回，不以自定义全屏右滑抢占系统手势。
- Android：系统返回/预测返回恢复人物页保存的上下文；左向进入不替代系统返回。
- 两端：加载、空结果、失败和搜索结果类型均需有可访问文本与正确焦点顺序。

## Open Questions

- 推送频率、授权时机和深链接落地目标。
- 三类搜索字段的实际列名和结果合并展示顺序。
- 人物详情页的内容结构。
