# SageRoute 人物页 Platform Review

## 1. Scope

- Platforms/OS versions: cross-platform Flutter target; exact minimum and target OS versions remain implementation-owned and unverified.
- Devices/form factors: compact iPhone and Android handset first; tablet, foldable, landscape, multi-window, and external keyboard are planned compatibility checks.
- Runtime evidence: the browser runner structurally exercised search-query, empty, failure, and close-to-context contract states on 2026-08-26. No device evidence exists, so every device/runtime-dependent check is `not-tested`.
- Sources checked/date: bundled iOS and Android first-party-reference summaries plus mobile IA and screen-spec rules, 2026-08-26. No version-specific implementation claim is made.

## 2. Outcome parity

| User outcome | iOS expression | Android expression | Intentionally different? | Reason |
| --- | --- | --- | --- | --- |
| Find content without disturbing browsing | Full-screen search overlay closes through visible close or system Back; keyboard focus is restored | Same product outcome; system Back/predictive Back closes search before leaving People page | Yes | System back models differ while saved context must match |
| Return from article or figure detail | Navigation stack and edge-back return to saved People page context | System/ predictive Back returns to saved People page context | Yes | Platform owns return gesture semantics |
| Read an accessible, scalable directory | Dynamic Type reflows text and VoiceOver announces state | Font scale reflows text and TalkBack announces state | Yes | Platform accessibility APIs and settings differ |
| Recover from unavailable content | Inline retry/return; invalid deep link falls back to People page | Same fallback outcome | No | Content recovery is product behavior |
| Continue without notifications | Notification authorization is optional; People page remains a primary entry | Notification permission is optional; People page remains a primary entry | No | Push is a secondary entry, not core value |

## 3. Rule/check matrix

| ID | Platform | Area | Rule | Status | Evidence | Owner/fix |
| --- | --- | --- | --- | --- | --- | --- |
| PG1 | iOS | navigation | Detail uses navigation-stack behavior; edge Back restores saved People page context | not-tested |  | Flutter implementation: use one route stack and preserve page state |
| PG2 | Android | navigation | System and predictive Back close search or return from detail without exiting unexpectedly | not-tested |  | Flutter implementation: integrate route/back dispatcher with predictive-back preview |
| PG3 | iOS | layout | Controls/text respect safe areas and keyboard; default targets reach 44 pt | not-tested |  | Flutter implementation: SafeArea, keyboard insets, and target-size audit |
| PG4 | Android | insets | Edge-to-edge background may extend under bars while interactive content avoids gesture/cutout insets | not-tested |  | Flutter implementation: WindowInsets/edge-to-edge verification |
| PG5 | iOS | accessibility | Dynamic Type, VoiceOver order/labels, focus restore, and Reduce Motion preserve the task | not-tested |  | Flutter implementation: semantic labels, focus management, text reflow, fade fallback |
| PG6 | Android | accessibility | Scalable text, TalkBack order/labels, and 48 dp target checks preserve the task | not-tested |  | Flutter implementation: semantics, text reflow, and hit-target audit |
| PG7 | cross-platform | state | Search, independent filters, expansion, and scroll context survive overlay dismissal and detail return | not-tested |  | Flutter implementation: explicit People-page state model and widget tests |
| PG8 | Android | lifecycle | Process recreation avoids false current state and restores persisted context when available | not-tested |  | Flutter implementation: restoration/persistence decision and emulator test |
| PG9 | cross-platform | deep-link | Notification is optional; invalid/expired/unauthorized targets explain recovery and lead to People page | not-tested |  | Flutter implementation: validate route target and define fallback state |
| PG10 | cross-platform | adaptive layout | Compact behavior reflows before truncation on tablet, foldable, landscape, multi-window, and keyboard pressure | not-tested |  | Flutter implementation: layout breakpoints and device test matrix |

## 4. Device test plan

- Navigation/back: iOS edge Back from article, figure, and search; Android system and predictive Back from the same states. Verify saved filters, expansion, scroll, and focus.
- Insets/keyboard/text scaling: verify safe areas, gesture/cutout insets, keyboard avoidance, Dynamic Type, and Android font scale at large accessibility settings.
- Permissions/system surfaces: deny notifications, return from Settings, open valid and invalid notification deep links. Browsing must stay available.
- Lifecycle/adaptive form factors: background/resume iOS; Android recreation; compact/large, landscape, foldable, and multi-window where the app supports them.
- Assistive technology/reduced motion: VoiceOver and TalkBack labels/order/announcements; iOS Reduce Motion and Android reduced animations.

## 5. Decision and confidence

The planned design is conditionally suitable for both platforms. It remains conditional until the implementation supplies route/back integration, inset handling, scalable text, semantics/focus behavior, and device evidence.
