# SageRoute 人物页 Prototype Test Plan

## Core task tests

| ID | Flow | Preconditions | Actions | Expected result | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| TC1 | F2 global search | People page has a non-default topic, dynasty, expansion state, and saved scroll offset | Open search, query a substring held in a figure name, article title, or topic name, then close | Three `ILIKE '%query%'` result sets are merged with object types; closing restores the exact People page context | not-tested | |
| TC2 | F2 search to article | Search returns an article result | Open the article and use the platform Back action | Article enters leftward, return is rightward, and original People page context returns | not-tested | |
| TC3 | F2 search to figure | Search returns a figure result | Open the figure and use the platform Back action | Figure detail opens and return restores the original People page context | not-tested | |
| TC4 | F3 independent filtering | Both directories contain over seven entries | Select topic, expand topic directory, select dynasty, expand figure directory | Each filter and expansion affects only its own directory; each can collapse separately | not-tested | |
| TC5 | F3 local recovery | Deterministic topic and dynasty errors are available | Inject each empty/error case; retry and clear its filter | Local status gives a recovery action; unaffected directory remains stable | not-tested | |
| TC6 | F1 detail recovery | Deterministic detail failure is available | Open article/figure, inject failure, retry then return | Object identity remains visible; return restores saved People page context | not-tested | |
| TC7 | F4 invalid deep link | Invalid notification target can be opened | Follow link and choose recovery | Failure is explained and the People page remains browsable | not-tested | |

## Runtime pressure

- Large text/scalable text: test iOS Dynamic Type and Android font scale at a large accessibility setting; search input, result type, retry, filters, and seven-item controls must reflow and remain visible.
- VoiceOver/TalkBack: verify logical reading order, result object type and target, selected filter state, loading/empty/error announcements, and restored focus after search closes.
- Reduce Motion: verify article/detail transition becomes a short fade without suppressing loading or route-change semantics.
- Keyboard and focus: confirm the search input remains visible above the keyboard, close/system Back first dismisses search, and focus returns to the invoking search control.
- Background/termination restore: background while search or a detail route is active, then resume/recreate; no incorrect context is claimed and saved context is restored when persisted.
- Offline/reconnect and duplicate submission: use injected search and detail failures; retry is idempotent and previous query/object identity remains intact.
- Permission denial and Settings return: notifications are optional; denial keeps the People page as the primary entry and a Settings return does not block browsing.
- Destructive recovery and privacy surfaces: no destructive action is in scope; invalid or unauthorized deep links show minimal error information and return to People page.
