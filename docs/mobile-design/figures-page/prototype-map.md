# SageRoute 人物页 Prototype Map

## UI -> prototype traceability

- UI source: `ui-design.json`
- Screen/state coverage: S1/ST1-ST6, S2/ST7-ST9, S3/ST10, S4/ST10
- Interaction coverage: all 8 explicit UI interactions are mapped to transition contracts.
- Alignment validation: pass on 2026-08-26

## 1. Scope and evidence status

- Target: behavior prototype and implementation handoff
- Platform/device: iOS and Android phones; device execution has not started.
- Evidence status: built; browser runner exercised search-query, empty, failure, and close-to-context contract states. Device/runtime evidence remains not-tested.
- Critical task: open global search, find an `ILIKE '%query%'` match across the three supported fields, open its destination, and return without losing the original People page context.
- High-risk recovery: injected search/index failure or empty result; retry, change query, or close must remain available and closing must restore the saved People page context.

## 2. Node map

| ID | Screen/state | Entry | Primary action | Feedback | Exit |
| --- | --- | --- | --- | --- | --- |
| P1 | S1/ST1 page loading | Enter People page | Wait for initial content | Centered progress with text announcement | Loaded content or P2 |
| P2 | S1/ST2 page failure | Initial load fails | Retry | Readable error and retry | P1 or retained People page |
| P3 | S1/ST3 topic directory loading | Select/change topic | Clear topic or wait | Only topic article area announces update | Topic result/empty/failure |
| P4 | S1/ST4 figure directory loading | Select/change dynasty | Clear dynasty or wait | Only figure directory announces update | Figure result/empty/failure |
| P5 | S1/ST5 topic local recovery | Topic result empty/fails | Retry or clear topic | Inline result-specific message | P3 or unfiltered topic list |
| P6 | S1/ST6 figure local recovery | Dynasty result empty/fails | Retry or clear dynasty | Inline result-specific message | P4 or unfiltered figure list |
| P7 | S2/ST7 search querying | Open search and submit/change text | Cancel or keep editing | Three `ILIKE '%query%'` queries are in progress; focus remains in input | Typed results, P8, P9, or close |
| P8 | S2/ST8 search empty | Query has no fuzzy matches | Change/clear query or close | "No matching results" plus action | P7 or saved People page |
| P9 | S2/ST9 search failure | Search times out/fails | Retry or close | Error is announced with retry | P7 or saved People page |
| P10 | S3/ST10 article unavailable | Article open fails | Retry or return | Article identity remains visible; failure announced | Retry or saved People page |
| P11 | S4/ST10 figure unavailable | Figure open fails | Retry or return | Figure identity remains visible; failure announced | Retry or saved People page |

## 3. Transition contracts

| ID | From | Trigger | System response | Motion/feedback | To | Interrupt/recovery |
| --- | --- | --- | --- | --- | --- | --- |
| TR1 | P1 | Initial request succeeds | Render People page content and preserve default directory scope | Centered spinner ends; content becomes available | P3 | If topic data is still loading, keep figure directory unchanged |
| TR2 | P1 | Initial request fails | Keep People page reachable with page-level retry | Error text is announced | P2 | Retry restarts P1; no false success state |
| TR3 | P3 | Select topic | Update only topic article query and retain dynasty, directory expansion, and scroll context | Local progress; no full-page reset | P3 | Empty/failure moves to P5; clear returns unfiltered topic articles |
| TR4 | P4 | Select dynasty | Update only figure query and retain topic, directory expansion, and scroll context | Local progress; no full-page reset | P4 | Empty/failure moves to P6; clear returns unfiltered figures |
| TR5 | P5 | Retry or clear topic | Retry same query or remove only topic constraint | Inline recovery status | P3 | Dynasty selection must not change |
| TR6 | P6 | Retry or clear dynasty | Retry same query or remove only dynasty constraint | Inline recovery status | P4 | Topic selection must not change |
| TR7 | P3 | Tap article | Save People page context and push article route | Article enters from right/leftward hierarchy; Reduce Motion uses fade | P10 | iOS edge back and Android system/predictive Back restore saved context |
| TR8 | P4 | Tap figure | Save People page context and push figure route | Standard hierarchical transition; Reduce Motion uses fade | P11 | Return restores saved People page context |
| TR9 | P3 | Tap search | Open global search overlay above current context and focus input | Keyboard appears without obscuring input | P7 | Back/close dismisses overlay and returns to saved People page context |
| TR10 | P7 | Search service returns no matches | Keep entered query and show typed empty state | Polite empty-result announcement | P8 | Clear/edit returns to P7; close restores context |
| TR11 | P7 | Search service fails/times out | Preserve query and show retry | Assertive error announcement | P9 | Retry reuses same query; close restores context |
| TR12 | P7 | Tap article result | Save origin context and push article route | Leftward entry; result type/target is announced before activation | P10 | Route back restores original People page context |
| TR13 | P7 | Tap figure result | Save origin context and push figure route | Standard hierarchical transition | P11 | Route back restores original People page context |
| TR14 | P7 | Close search or system Back | Dismiss overlay; restore focus to search entry and all People page state | Keyboard dismisses, then focus returns | P3 | No filters, expansions, or scroll offsets reset |
| TR15 | P10 | Retry article | Retry identified article without losing object identity | Loading text or reduced-motion fade | P10 | Return always remains available |
| TR16 | P11 | Retry figure | Retry identified figure without losing object identity | Loading text or reduced-motion fade | P11 | Return always remains available |

## 4. Failure hooks and test matrix

| Hook/test | Setup | Expected truth | Evidence | Status |
| --- | --- | --- | --- | --- |
| FH1 / initial load | Force initial People request failure for ST1/ST2 | Retry is available and the page does not present stale success as current data |  | not-tested |
| FH2 / independent filters | Force topic ST3/ST5 and dynasty ST4/ST6 empty/failure responses separately | Only the owning directory changes; clear/retry does not alter the other directory |  | not-tested |
| FH3 / search index | Force ST7 timeout, ST8 empty, and ST9 failure using deterministic query responses | Query is retained; retry, edit, clear, and close recover correctly |  | not-tested |
| FH4 / detail load | Force ST10 article and figure detail failure after preserving object identity | Retry and return are both reachable; saved People page context returns intact |  | not-tested |
| FH5 / deep link | Open an invalid notification target | Explain unavailability and recover to a browsable People page |  | not-tested |
