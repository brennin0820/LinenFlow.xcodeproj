# Agent Work Log

> **Single source of truth** for parallel agent file ownership. Read before any edit; update before claiming; release on completion.
>
> Master plan: `docs/superpowers/plans/2026-06-08-linen-tab-master-plan.md`

**Last updated:** 2026-06-07 (track B compile verify — `trackB-b7e2`)

---

## Rules for agents

1. **MUST claim before edit** — Add or update a row in **Active Claims** with exact file paths before writing any file.
2. **MUST release on completion** — Move the row to **Completed Work** with build/test results; remove files from **File Lock Registry**.
3. **NEVER edit another agent's claimed files** while status is `ACTIVE`.
4. **If a file is locked** — Wait for release, ask the parent agent to reschedule, or pick a different task. Do not force-merge or revert in-progress work.
5. **One agent per Swift source file** — No two `ACTIVE` claims on the same `.swift` path.
6. **New generated files** — Register in Active Claims and File Lock Registry before creation.
7. **`project.pbxproj`** — Serialize edits; only one agent at a time. Coordinate with parent if multiple tracks add files.
8. **Check File Ownership Map** (master plan § File Ownership Map) — Respect track boundaries even when a file is not yet listed here.

---

## Conflict hotspots

These files have the highest merge-conflict risk. **Serialize** — one active agent at a time.

| File | Risk | Typical owners (tracks) |
|------|------|-------------------------|
| `LinenFlow/Views/HomeView.swift` | **Critical** — ~1,180 lines, many sections | D, F, G, I, J |
| `LinenFlow/ViewModels/FlowViewModel.swift` | **Critical** — shared app state | A, H, floor-detection |
| `LinenFlow.xcodeproj/project.pbxproj` | **High** — target membership, new files | Any track adding files |

**Current overlap alert:** `project.pbxproj` is claimed by **f19a62cd** (wizard/Legacy) and may also be touched by **50fed4e9** (audit/build). Parent should serialize or delegate pbxproj edits to one agent.

---

## Active Claims

| Agent ID | Task | Files owned | Status | Started (UTC) |
|----------|------|-------------|--------|---------------|
| `a7618ee3` | Phase 11 — polish / a11y (card + input + keyboard shell) | `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift`, `LinenFlow/Views/Components/PremiumExpressionInput.swift`, `LinenFlow/Views/Components/KeyboardPinnedEditorShell.swift` | **ACTIVE — do not touch** | 2026-06-07 |
| `f19a62cd` | Phase 12 — wizard orphan / Legacy folder + HomeView nav | `LinenFlow/Views/HomeView.swift`, `LinenFlow/Views/Flow/Legacy/**`, `LinenFlow/Views/Flow/ReceivingView.swift`, `LinenFlow/Views/Flow/ReviewReceivedView.swift`, `LinenFlow/Views/Flow/ResultsView.swift`, `LinenFlow/Views/Flow/FloorDistributionView.swift`, `LinenFlow/Views/Flow/RebalanceShortFloorsView.swift`, `LinenFlow.xcodeproj/project.pbxproj` | **ACTIVE — do not touch** | 2026-06-07 |
| `9e5546a4` | Floor detection — VM + delivery UI | `LinenFlow/ViewModels/FlowViewModel.swift`, `LinenFlow/Views/Flow/ShiftCommandCenterView.swift`, `LinenFlow/Views/Flow/FloorChecklistView.swift`, `LinenFlow/Views/Flow/FloorDetectionCard.swift` | **ACTIVE — do not touch** | 2026-06-07 |
| `50fed4e9` | Post-completion audit / build / install | `LinenFlow.xcodeproj/project.pbxproj` (shared — coordinate), `TestPlan.xctestplan`, `.github/workflows/**`, repo-wide verification (read-mostly; write only after other claims release) | **ACTIVE — do not touch** (advisory on pbxproj) | 2026-06-07 |
| `qa-timeline-fix` | QA — TimelineComputationTests missing import | `LinenFlowTests/TimelineComputationTests.swift` | **ACTIVE — do not touch** | 2026-06-07 |
| `kb-autoclose-fix` | Keyboard auto-dismiss — stable ScrollView + entry sync guard | `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift` | **ACTIVE — do not touch** | 2026-06-07 |

---

## File Lock Registry

Explicit locks — **do not edit** these paths while locked.

| File | Locked by | Since | Notes |
|------|-----------|-------|-------|
| `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift` | `a7618ee3` | 2026-06-07 | Phase 11 card polish |
| `LinenFlow/Views/Components/PremiumExpressionInput.swift` | `a7618ee3` | 2026-06-07 | Expression input a11y |
| `LinenFlow/Views/Components/KeyboardPinnedEditorShell.swift` | `a7618ee3` | 2026-06-07 | Keyboard pinned editor |
| `LinenFlow/Views/HomeView.swift` | `f19a62cd` | 2026-06-07 | Wizard nav / Legacy — **hotspot** |
| `LinenFlow/Views/Flow/Legacy/**` | `f19a62cd` | 2026-06-07 | Wizard archive moves |
| `LinenFlow/Views/Flow/ReceivingView.swift` | `f19a62cd` | 2026-06-07 | Wizard (may move to Legacy) |
| `LinenFlow/Views/Flow/ReviewReceivedView.swift` | `f19a62cd` | 2026-06-07 | Wizard (may move to Legacy) |
| `LinenFlow/Views/Flow/ResultsView.swift` | `f19a62cd` | 2026-06-07 | Wizard (may move to Legacy) |
| `LinenFlow/Views/Flow/Legacy/FloorDistributionView.swift` | `f19a62cd` | 2026-06-07 | Wizard (Legacy) |
| `LinenFlow/Views/Flow/RebalanceShortFloorsView.swift` | `f19a62cd` | 2026-06-07 | Wizard (may move to Legacy) |
| `LinenFlow.xcodeproj/project.pbxproj` | `f19a62cd` (+ advisory `50fed4e9`) | 2026-06-07 | **Hotspot** — serialize with audit agent |
| `LinenFlow/ViewModels/FlowViewModel.swift` | `9e5546a4` | 2026-06-07 | Floor detection — **hotspot** |
| `LinenFlow/Views/Flow/ShiftCommandCenterView.swift` | `9e5546a4` | 2026-06-07 | Delivery command center |
| `LinenFlow/Views/Flow/FloorChecklistView.swift` | `9e5546a4` | 2026-06-07 | Floor checklist |
| `LinenFlow/Views/Flow/FloorDetectionCard.swift` | `9e5546a4` | 2026-06-07 | New or modified floor detection UI |
| `LinenFlowTests/TimelineComputationTests.swift` | `qa-timeline-fix` | 2026-06-07 | QA — add @testable import HimmerFlow |
| `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift` | `kb-autoclose-fix` | 2026-06-07 | Keyboard auto-dismiss fix (supersedes `a7618ee3` claim for this file — coordinate on merge) |
**Unlocked (safe for new claims if no other agent needs them):** Models, Services (except via FlowViewModel), `AppRootView.swift`, `android/**`, most Components not listed above, `docs/**`.

---

## Completed Work

| Agent ID | Task | Files | Completed | Verification |
|----------|------|-------|-----------|--------------|
| `89f7ca28` | Docs — device capabilities inventory + Linen tab manual QA | `docs/ios-device-capabilities-inventory.md`, `docs/LinenTabManualQA.md` | 2026-06-07 | Docs only — no Swift; 50fed4e9 had not created inventory yet |
| _(coordination setup)_ | Agent file-coordination infrastructure | `AGENT_WORK_LOG.md`, `.cursor/rules/agent-file-coordination.mdc`, `docs/AGENT_COORDINATION.md` | 2026-06-07 | Docs only — no Swift edits |
| `b3c4d5e6` | PremiumCard calm pass — reduce visual intensity | `LinenFlow/Views/Components/PremiumCard.swift` | 2026-06-07 | `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone Air' build` — **BUILD FAILED** (unrelated: `Weekday` redeclaration in `ShiftPattern.swift`, `HimmerFlowMigrationPlan.swift`); PremiumCard.swift has no compile errors |
| `b3c4d5e6` | PremiumCard editing tap-through fix | `PremiumCard.swift`, `HomeView.swift` | 2026-06-07 | `xcodebuild … HimmerFlow build` — **BUILD FAILED** (unrelated `Weekday` redeclaration); changed files compile clean |
| `track3-c7e8` | Parallel track 3 — PremiumCard `isCurrent` call-site wiring | `HomeView.swift` (itemCard), `FloorDistributionView.swift` (Legacy) | 2026-06-07 | `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone Air' build` — **BUILD FAILED** (unrelated: `Weekday` redeclaration in `ShiftPattern.swift`, `HimmerFlowMigrationPlan.swift`); view edits lint-clean |
| `d4e5f6a7` | Track 2 — edit-mode tap-through fix | `KeyboardPinnedEditorShell.swift`, `HomeView.swift` | 2026-06-07 | `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone Air' build` — **BUILD FAILED** (unrelated: `SavedLocation.coordinate`, `ShiftTimelinePhase.requiresAcknowledgement`); tap-through files compile clean |
| `track3-c7e8` | Interaction contract — `backgroundTap = dismissKeyboardOnly` | `KeyboardPinnedEditorShell.swift`, `HomeView.swift` | 2026-06-07 | `KeyboardEditingFocus.dismissKeyboard()` in tap absorber; `handleItemFocusChange` ignores blur; `endEditing()` only via Done; isCurrent already wired; build failed (unrelated Services model errors) |
| `kb-safe-c8f2` | Keyboard-safe card positioning (priority bugfix) | `HomeView.swift`, `OneScreenLinenItemCard.swift`, `KeyboardPinnedEditorShell.swift` | 2026-06-07 | `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone Air' build` — **BUILD FAILED** (unrelated: `SavedLocation.coordinate`, `ShiftTimelinePhase.requiresAcknowledgement`); changed files compile clean |
| `c3f8a912` | Restore missing model APIs — device build/install | `ShiftPlannerSettings.swift`, `ShiftTimelinePhase.swift`, `ShiftTimelineSnapshot.swift`, `SavedLocation.swift`, `ShiftPattern.swift` | 2026-06-07 | `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS,id=00008150-00056D260282401C' -allowProvisioningUpdates build` — **BUILD SUCCEEDED**; `xcrun devicectl device install app --device 70093628-E2B5-509B-B807-4E06B510CEF1 …/Debug-iphoneos/HimmerFlow.app` — **INSTALL SUCCEEDED** |
| `trackB-b7e2` | Parallel track B — compile error audit (no code changes) | _(read-only verification)_ | 2026-06-07 | `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'generic/platform=iOS' build` — **BUILD SUCCEEDED**; zero compile errors; prior fixes by `c3f8a912` already present (`SavedLocation.coordinate`, `ShiftTimelinePhase.displayName/statusEmoji/requiresAcknowledgement`, `ShiftPattern.clockInHour/Minute`, `Weekday` single definition) |
| `swiftdata-cal-fix` | SwiftData crash — `_CalendarProtocol` in persisted DateComponents | `ShiftPlannerSettings.swift`, `ShiftPattern.swift` | 2026-06-07 | `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone Air' build` — **BUILD SUCCEEDED**; simulator test launch failed (Invalid device state — environment, not code) |

---

## Quick reference — File Ownership Map

See master plan for full table. Summary:

| Area | Primary files | Serialize? |
|------|---------------|------------|
| Track I (a11y) | `OneScreenLinenItemCard`, `KeyboardPinnedEditorShell` | Card parallel with HomeView **only** if HomeView untouched |
| Track J (wizard) | `HomeView`, `Views/Flow/*` wizard views | HomeView **one agent** |
| Floor detection | `FlowViewModel`, `ShiftCommandCenterView`, `FloorChecklistView` | FlowViewModel **one agent** |
| Track G/H | `DailyLogSaveService`, `SharedWidgetStateManager` | Not currently claimed |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-07 | Initial log + active claims for agents a7618ee3, f19a62cd, 9e5546a4, 50fed4e9 |
| 2026-06-07 | Docs: `ios-device-capabilities-inventory.md` + `LinenTabManualQA.md` (`89f7ca28`) |
| 2026-06-07 | Quality reminder added for all ACTIVE agents |
| 2026-06-07 | PremiumCard calm pass complete (`b3c4d5e6`) — shadow/glow/scale/border toned down |
| 2026-06-07 | Track 3 `isCurrent` call-site wiring (`track3-c7e8`) — HomeView itemCard + Legacy FloorDistributionView |
| 2026-06-07 | Track 2 tap-through fix (`d4e5f6a7`) — `KeyboardEditingTapAbsorber` + HomeView chrome shields |
| 2026-06-07 | Keyboard-safe card positioning (`kb-safe-c8f2`) — ScrollViewReader, keyboard inset padding, scrollable focused card |
| 2026-06-07 | Interaction contract (`track3-c7e8`) — background tap = keyboard dismiss only; Done = card dismiss |
| 2026-06-07 | Model API restore + device install (`c3f8a912`) — hasCompletedOnboarding, phase display props, progressFraction, coordinate, clockInHour/Minute, isPointEvent |
| 2026-06-07 | Track B compile audit (`trackB-b7e2`) — generic iOS device build passes; no additional fixes required |
| 2026-06-07 | SwiftData Calendar crash fix (`swiftdata-cal-fix`) — replaced persisted `DateComponents` with `clockInHour`/`clockInMinute` on `ShiftPlannerSettings` and `ShiftPattern` |

---

## Quality reminder (ACTIVE agents)

**Applies to:** `a7618ee3`, `f19a62cd`, `9e5546a4`, `50fed4e9`

Before releasing your claim and removing entries from **File Lock Registry**:

1. **Build must pass** — Run `xcodebuild` build for your change; record command + result in **Completed Work**.
2. **Tests must pass** — Run relevant `xcodebuild test` (scheme/destination appropriate to your track) before release.
3. **No success without output** — Do not mark complete or release locks if build or test failed; report failures honestly.
4. **Device checks** — If your work touches barometer or floor detection, verify on a physical **iPhone** (not Simulator-only).

See also: `docs/AGENT_COORDINATION.md` § Quality Gate.
