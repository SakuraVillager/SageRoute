# SageRoute 人物页 Design Review

> Review mode: package  
> Date: 2026-08-26  
> Result: conditional pass  
> Score: 87/100  
> Blockers: 0

## 1. Decision

This package is ready to begin Flutter implementation conditionally. The user resolved search scope: the first release uses three Supabase/Postgres `ILIKE '%query%'` substring queries, for figure names, article titles, and topic names, without typo tolerance, pinyin, aliases, simplified/traditional conversion, or complex sorting. Implementation must preserve the defined minimum semantic target sizes and navigation/state-continuity behavior. No device or production runtime behavior is claimed as proven.

Next stage: `flutter-implementation` followed by `flutter-accessibility` and `flutter-visual-qa`.

Conditions:

1. Implement three Supabase `ILIKE '%query%'` queries over the confirmed fields, merge typed results, and cover empty/error/retry behavior.
2. Implement visual controls with 44 pt iOS and 48 dp Android semantic hit areas, even where the locked visual frame is smaller.
3. Keep People-page context explicit across overlay dismissal and detail Back; verify it on iOS and Android after implementation.

## 2. Sources and validation

| ID | Source | Version/date | Limitation |
| --- | --- | --- | --- |
| SR1 | `product-brief.json` | 2026-08-26 | Does not establish live data/search availability. |
| SR2 | `ux-architecture.json`, `wireframe.json` | 2026-08-26 | Defines planned flows, not runtime interaction. |
| SR3 | `ui-design.json`, `ui-spec.md`, `visual-baseline.md`, `design-system.json` | 2026-08-26 | Static baseline cannot prove hit testing, reflow, or semantics. |
| SR4 | `prototype.json`, browser runner, test plan | 2026-08-26 | Browser runner proves contract reachability, not Flutter/device behavior. |
| SR5 | `platform-guidelines.json`, `platform-review.md` | 2026-08-26 | All device checks remain not-tested. |

All structured artifacts validated: product brief, UX architecture, wireframe, UI design, design system, prototype, UI/prototype alignment, prototype runner, platform guidelines, and workflow manifest.

## 3. Score

| Dimension | Awarded | Maximum | Deductions |
| --- | ---: | ---: | --- |
| Product and task match | 20 | 20 | None |
| Information architecture and UX | 18 | 20 | I3 |
| Visual hierarchy and consistency | 18 | 20 | I2 |
| Platform-native behavior | 10 | 15 | I2, I4 |
| State completeness | 9 | 10 | I3 |
| Accessibility, privacy, and ethics | 7 | 10 | I2, I4 |
| Brand differentiation | 5 | 5 | None |

## 4. Findings

### I1 - Resolved - Search scope is explicitly bounded

- Location/evidence: user decision on 2026-08-26; `product-brief.md`, `ux-flow.md`, and `prototype.json` now define the implementation boundary.
- Affected user/task: users searching a figure name, article title, or topic name.
- Impact: scope is now implementable without an unbounded search-quality promise.
- Fix: use `ILIKE '%query%'` against the three named fields, merge typed results, and exclude typo, pinyin, alias, simplified/traditional, and complex-sort behavior.
- Verify: focused tests cover the three field queries, substring matches, zero results, failure, retry, and result typing.

### I2 - P2 - Locked visual dimensions need explicit semantic hit-area wrappers

- Location/evidence: `visual-baseline.md` specifies a 35 x 35 px search control, 23 px filters, and 33-40 px rows; `ui-spec.md` and platform rules require 44 pt iOS and 48 dp Android targets.
- Affected user/task: users with motor impairments or one-handed use selecting search, filters, list rows, and the expansion action.
- Impact: directly implementing the visible measurements as hit targets would miss platform target guidance and make repeated browsing error-prone.
- Fix: preserve the visual measurements but place each interactive component in a transparent, non-overlapping 44 pt/48 dp minimum semantic hit area; document the resulting layout behavior when adjacent controls compete.
- Verify: Flutter widget tests inspect minimum tap bounds; iOS/Android manual tests confirm adjacent actions stay independently operable at large text.

### I3 - P2 - Detail defaults and restoration storage boundary need implementation definition

- Location/evidence: `ui-spec.md` says article body remains existing and figure detail structure is deferred; `prototype.json` requires restoration of topic/dynasty filters, expansion, scroll, and focus but leaves cold-start persistence open.
- Affected user/task: readers returning from article/figure detail after backgrounding, process recreation, or an unavailable target.
- Impact: navigation may restore only partially, or a route can display an incomplete/ambiguous detail state.
- Fix: before coding, identify the existing article and figure routes, specify default/loading/error content ownership for each, and decide which People-page fields are in-memory route context versus persisted restoration state.
- Verify: widget/integration tests cover opening existing article/figure routes, route return, search close, background/resume, and Android process recreation against the chosen persistence boundary.

### I4 - P2 - Platform and notification policy require post-implementation device evidence

- Location/evidence: all checks in `platform-guidelines.json` are `not-tested`; supported iOS/Android versions and push authorization timing remain unresolved.
- Affected user/task: iOS and Android users using system Back, assistive technology, large text, keyboard, or an optional notification deep link.
- Impact: platform contracts could regress silently even if the static page matches the visual baseline.
- Fix: record supported OS/API ranges, make notification authorization explicitly optional, and execute the listed iOS/Android device matrix after implementation.
- Verify: attach device evidence for edge/system/predictive Back, keyboard/insets, Dynamic Type/font scale, VoiceOver/TalkBack, reduced motion, process recreation, and invalid deep-link recovery.

## 5. Strengths

- The selected `VD2` museum-exhibit direction is user-locked and implemented as a semantic design system rather than an untraceable screenshot treatment.
- The UX distinguishes topic-article filtering from dynasty-figure filtering and explicitly models each directory's empty, error, retry, and seven-item expansion behavior.
- Search closes without resetting browsing state, and article/figure routes preserve a defined recovery path.
- Notification permission is correctly treated as optional, with an invalid-link fallback to the People page.
- The browser runner structurally exercised search querying, empty, failure, and close-to-context contract states while keeping device evidence accurately `not-tested`.

## 6. Not tested

- Flutter implementation of the approved three-field `ILIKE '%query%'` search and typed-result merge.
- Flutter hit testing, semantics, keyboard avoidance, state restoration, animations, and error handling.
- iOS edge Back, Dynamic Type, VoiceOver, Reduce Motion, safe areas, and keyboard behavior.
- Android system/predictive Back, edge-to-edge insets, scalable text, TalkBack, process recreation, and adaptive layouts.

## 7. Prioritized next actions

1. SageRoute Flutter owner: implement and test I1's bounded `ILIKE` search contract for the three named fields.
2. Flutter implementation owner: implement the People page with I2's semantic target wrappers and I3's explicit restoration model.
3. QA/accessibility owner: run the platform device matrix for I4 after a runnable build exists.
4. Design/engineering: conduct visual QA against `visual-baseline.md` on Android and iOS screenshots.
