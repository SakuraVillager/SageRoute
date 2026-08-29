# SageRoute 人物页 Visual Baseline

> Source: `.superpowers/brainstorm/399-1787655594/content/figures-featured-hero-directions-v6.html`  
> Selected direction: `02 博物馆展签`  
> Purpose: Flutter 实现与截图验收的测量基准，不是从截图推测的设计建议。

## Color Roles

| Role | Exact value | HTML source role |
| --- | --- | --- |
| Primary brand | `#96615A` | 选中筛选、重点标签、分页激活态 |
| Brand dark | `#784E48` | 操作图标、强调文字 |
| Ink | `#3C2724` | 页面标题与主要文字 |
| Near black | `#2D1D1B` | 图片遮罩、设备边框 |
| Warm paper | `#EADFDE` | 暖纸表面、边缘强调 |
| Page wash | `#F5EFEF` | 柔和背景 |
| Surface | `#FFFFFF` | 内容面与筛选未选态 |
| Border | `#D8D8DC` | 控件边界与底部导航边界 |
| Muted text | `#6F6D72` | 次级描述 |
| Divider / recommended-topic field | `#D3D3D3` | 分割线与推荐主题整块背景 |

## Spatial And Type Baseline

Values below use the preview's logical phone coordinate system (`350px` device width, `730px` device height, `8px` device edge).

| Element | Contract |
| --- | --- |
| Screen content inset | `15px` for page title, section header, filters and directories |
| Top search control | `35 × 35px`, circular, outline border |
| Featured article card | horizontal carousel; card width `screen width - 8px`; height `380px` |
| Featured overlay | `11–13px` horizontal inset; cover `48 × 70px` in selected direction; title `18px` display type |
| Featured pager | `23px` high; inactive dot `5px`; active marker `25 × 5px` |
| Directory row | topic row minimum `33px`; figure row minimum `40px` |
| Directory icon | topic `22 × 22px`; figure `29 × 29px` |
| Filter control | height `23px`; horizontal scrolling; selected state uses primary brand |
| Recommended-topic field | full screen width; no preceding/following divider; vertical padding `11px 0 13px` |
| Recommended-topic carousel | no horizontal track padding; `8px` inter-card gap; default scroll centers a card and leaves neighbouring card edges visible |
| Recommended card | width `track width - 50px`; `6px` inner image/copy inset; `3px` corner radius; horizontal image `105px` high |
| Bottom navigation | fixed; height `50px`; accommodates system bottom inset |

## Behavior Baseline

- Article entry moves left; return to figures moves right. Reduce Motion substitutes a brief opacity transition while preserving navigation semantics.
- Search is an independent overlay. Closing it restores, rather than resets, topic filter, dynasty filter, list expansion and scroll position.
- Topic filter updates only the push-article list. Dynasty filter updates only the figure directory.
- Each directory initially shows seven entries at most; the eighth entry requires explicit expansion.
- Initial loading uses a centered circular indicator. A local filter load uses feedback only in its owning directory region.
- Empty and failed states never reuse the same copy or control: empty offers clearing/modifying a condition; failure offers retry and safe return.

## Flutter Screenshot Acceptance

1. Render Android and iOS at the same logical width used by the design target.
2. Compare default, selected-topic, selected-dynasty, search results, search empty, local failure, article entry and return states.
3. Treat the values above as tolerances to match, not decorative suggestions; record intentional platform deviations.
4. Verify Dynamic Type/scalable text, TalkBack/VoiceOver order, system back and reduced motion separately. Static HTML cannot prove these behaviors.
