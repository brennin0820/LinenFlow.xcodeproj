# LinenFlow / HimmerFlow — Full Project Build Plan

> **Executable by:** God's Eye + **NightRaven Core** ("Grav Nightraven")  
> **Machine runner:** [`Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml`](nightraven/LINENFLOW_BUILD_RUNNER.yaml)  
> **Coordination:** [`AGENT_WORK_LOG.md`](../AGENT_WORK_LOG.md) — claim files before edit  
> **Linen-tab deep dive:** [`Docs/superpowers/plans/2026-06-08-linen-tab-master-plan.md`](superpowers/plans/2026-06-08-linen-tab-master-plan.md)

**Goal:** Build the entire LinenFlow hotel linen attendant app — iOS (primary), widgets, Android companion, tests, CI, and remaining features — from zero through release gate.

**Workspace:** `/Users/brentlenninorlanda/Developer/crazyboy`  
**Xcode scheme:** `HimmerFlow` · **Project:** `LinenFlow.xcodeproj`  
**Tech stack:** SwiftUI, SwiftData, WidgetKit, ActivityKit, Jetpack Compose (Android), iOS 26.0, Xcode 26.x

**Snapshot (2026-06-11):** Phases **0–16 done** · Phases **17–19 partial** · Phases **20–25 pending** · **283** active unit tests

---

## How to run this plan (Grav Nightraven)

### What is Grav Nightraven?

| Layer | What it is | Where |
|-------|------------|-------|
| **God's Eye** | Repo-native agent **memory** — handoff, changelog, +# chain, intent ladder | `docs/37_GODS_EYE.md`, `AGENTS.md` |
| **NightRaven Core** | Adaptive **orchestration** — Phase 0 assessment, Builder/Auditor divisions, ledgers | `.claude/skills/nightraven/SKILL.md` |
| **Grav Nightraven** | **Both together** — memory before edit; orchestration for multi-phase builds | Installed via `gods-eye/scripts/install-gods-eye-nightraven.sh` |

NightRaven is **not** a separate CLI binary. It is a **skill** invoked in Cursor/Claude with `/nightraven <task>`. It reads markdown/YAML plans, runs Phase 0 Task Assessment, appends to `docs/ledgers/BUILD_LEDGER.md`, and coordinates Builder/Auditor subagents per complexity.

> **Note:** "Antigravity" in gods-eye docs is a **HimFLer-specific** Planning + Architecture Auditor role — not required for LinenFlow unless you adopt that external coder workflow.

### One-shot: build entire thing

Paste into a **new Cursor Agent chat** (workspace = crazyboy):

```text
Read AGENTS.md, docs/14_SESSION_HANDOFF.md, Docs/BUILD_PLAN_FULL.md, and Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml.

/nightraven Execute LinenFlow full build — build the entire thing.

Rules:
- Complexity: CRITICAL — activate Planning + Builder + Architecture + Security + Performance + General Auditor per NightRaven matrix.
- Execute every phase where status is pending or partial, in numeric order, starting at current_phase in the YAML.
- Claim files in AGENT_WORK_LOG.md before edits; one writer per Swift file.
- Append BuildStarted/FeatureBuilt events to docs/ledgers/BUILD_LEDGER.md before mutating files.
- Run verification commands after each phase; do not advance on failure.
- User approval for full build is granted: "build the entire thing".
```

### Resume a single phase

```text
/nightraven Execute LinenFlow BUILD_PLAN_FULL Phase 17 only — accessibility polish. Read phase steps and acceptance in Docs/BUILD_PLAN_FULL.md.
```

### Install / refresh God's Eye + NightRaven (once per machine)

```bash
git clone https://github.com/brennin0820/gods-eye.git ~/Developer/gods-eye   # if missing
bash ~/Developer/gods-eye/scripts/install-gods-eye-nightraven.sh --no-mcp /Users/brentlenninorlanda/Developer/crazyboy
```

Optional MCP (memory-chain tools): see `docs/MCP_SETUP.md` — requires `cd gods-eye/mcp-server && npm install && npm run build`.

---

## Phase index

| Phase | Name | Status | Track |
|-------|------|--------|-------|
| 0 | Environment & NightRaven wiring | ✅ done | meta |
| 1 | Xcode project for iOS | ✅ done | A |
| 2 | App foundation | ✅ done | A |
| 3 | SwiftData models | ✅ done | A |
| 4 | Seed data | ✅ done | A |
| 5 | Arithmetic engine | ✅ done | A |
| 6 | Calculator services | ✅ done | A |
| 7 | FlowViewModel | ✅ done | A |
| 8 | Premium UI components | ✅ done | B |
| 9 | 5-tab shell & deep links | ✅ done | C |
| 10 | HomeView & one-screen cards | ✅ done | D–E |
| 11 | Intelligence & restore | ✅ done | F |
| 12 | Save, clear, delivery | ✅ done | G |
| 13 | Widget sync & Live Activities | ✅ done | H |
| 14 | Shift tab & work schedule | ✅ done | shift |
| 15 | Insights & Logs tabs | ✅ done | tabs |
| 16 | Settings, onboarding, site plan | ✅ done | settings |
| 17 | Accessibility polish | 🟡 partial | I |
| 18 | Wizard orphan cleanup | 🟡 partial | J |
| 19 | Floor detection polish | 🟡 partial | floor |
| 20 | LogFilterBuilder | ⬜ pending | logs |
| 21 | TowerConfigService | ⬜ pending | settings |
| 22 | Android parity | ⏭ skipped (out of scope — no Android) | K |
| 23 | XCUITest target | ⬜ pending | L |
| 24 | CI & release hardening | 🟡 partial | ci |
| 25 | Final QA & release gate | ⬜ pending | qa |

---

## Global verification commands

```bash
# iOS build
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# iOS test (283+ cases)
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test

# Android debug APK
cd android && ./gradlew assembleDebug

# List simulators
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -showdestinations
```

**Manual QA:** [`Docs/LinenTabManualQA.md`](LinenTabManualQA.md)  
**Device capabilities:** [`Docs/ios-device-capabilities-inventory.md`](ios-device-capabilities-inventory.md)

---

## Phase 0 — Environment & NightRaven wiring

**Status:** ✅ done (2026-06-11)  
**Prerequisites:** Xcode 26.x, repo cloned  
**NightRaven:** `/nightraven Phase 0 — verify install only`

### Steps

1. Clone workspace: `git clone` → `/Users/brentlenninorlanda/Developer/crazyboy`
2. Run God's Eye + NightRaven install (see command above)
3. Verify files exist:
   - `.cursor/rules/gods-eye-context-intent.mdc`
   - `.claude/skills/nightraven/SKILL.md`
   - `docs/ledgers/BUILD_LEDGER.md`, `docs/ledgers/AUDIT_LEDGER.md`
   - `AGENTS.md`, `docs/GODS_EYE_REPO_OVERLAY.md`
4. Ensure `AGENT_WORK_LOG.md` exists with claim protocol
5. Read `docs/14_SESSION_HANDOFF.md` before any code session

### Acceptance

- [x] NightRaven skill present
- [x] This plan + runner YAML committed under `Docs/`

---

## Phase 1 — Xcode project for iOS

**Status:** ✅ done  
**Files:** `LinenFlow.xcodeproj/project.pbxproj`

### Steps (canonical — already applied)

1. Set `SDKROOT = iphoneos`, `TARGETED_DEVICE_FAMILY = 1,2`
2. Set `IPHONEOS_DEPLOYMENT_TARGET = 26.0` (current) — was 17.0 during initial build
3. Add `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`
4. Confirm scheme **HimmerFlow** builds app target **HimmerFlow**

### Verification

```bash
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

**Expected:** `BUILD SUCCEEDED`

---

## Phase 2 — App foundation

**Status:** ✅ done  
**Files:** `LinenFlow/App/HimmerFlowApp.swift`, `LinenFlow/Views/HomeView.swift`

### Steps

1. `@main struct HimmerFlowApp` — launch `AppRootView` (later) or `HomeView` (initial)
2. Force dark mode at root if design requires: `.preferredColorScheme(.dark)`
3. Create folder scaffold: `Models/`, `Services/`, `ViewModels/`, `SeedData/`, `Utilities/`, `Views/`

### Verification

Build succeeds; app launches to placeholder or home.

---

## Phase 3 — SwiftData models

**Status:** ✅ done  
**Files:** `LinenFlow/Models/*`

### Steps

1. `@Model Tower` — name, floorCount, identityColorHex, sortOrder, operational flags, calibration fields
2. `@Model LinenItem` — name, bundleSize, countMethod, allowedTowerNames (JSON Data), sortOrder, displayGroup
3. Codable structs: `ReceivingEntry`, `CalculationSummary`, `FloorDistributionRow`
4. `@Model DailyLog` — immutable snapshot `Data` fields (entries, summary, distribution)
5. Enums: `CountMethod`, `CalculationStatus`, delivery/shift models as needed

### Verification

Build succeeds; no SwiftUI in Models.

---

## Phase 4 — Seed data

**Status:** ✅ done  
**Files:** `LinenFlow/SeedData/DefaultData.swift`, `SeedService.swift`, `HimmerFlowApp.swift`

### Steps

1. Define towers: Lagoon (21), GI (32), GW (31), Diamond (15), Alii (14), Tapa, Rainbow
2. Define 11 linen items with locked bundle sizes
3. `SeedService.seedIfNeeded(context:)` — idempotent
4. Wire `ModelContainer` for Tower, LinenItem, DailyLog; call seed on launch

### Verification

Build + launch; towers appear in Settings / Home picker.

---

## Phase 5 — Arithmetic engine

**Status:** ✅ done  
**Files:** `LinenFlow/Utilities/ArithmeticParser.swift`, `LinenFlow/Services/ArithmeticExpressionService.swift`, `LinenFlowTests/ArithmeticTests.swift`

### Steps

1. Tokenize `+`, `-`, `*`, `/`, integers — no eval injection
2. Write **26 tests**: valid expressions, empty, divide-by-zero, overflow guards

### Verification

```bash
xcodebuild … test -only-testing:HimmerFlowTests/ArithmeticTests
```

**Expected:** 26/26 pass

---

## Phase 6 — Calculator services

**Status:** ✅ done  
**Files:** `BundleLibrary.swift`, `LinenCalculatorService.swift`, `FloorRangeBuilder.swift`, tests

### Steps

1. `BundleLibrary` — canonical names, aliases, protected constants
2. `calculateSummary(item:receivedPieces:floorCount:)` → `CalculationSummary`
3. `distributeAcrossFloors(...)` → `[FloorDistributionRow]`
4. `FloorRangeBuilder` — display labels ("12–15", "3, 5, 7")
5. **19+ calculator tests** pinning every formula

**Invariant:** No SwiftUI imports in Services.

### Verification

```bash
xcodebuild … test -only-testing:HimmerFlowTests/CalculatorTests
```

---

## Phase 7 — FlowViewModel

**Status:** ✅ done  
**Files:** `LinenFlow/ViewModels/FlowViewModel.swift`, `FlowViewModelTests.swift`

### Steps

1. `@Observable class FlowViewModel` with tower, entries, summaries, distributions, delivery session, widget sync hooks
2. `selectTower`, `addOrUpdateReceivedPieces`, `recalculate`, `saveSelectedItems`, `clearEntries`, `loadFromLog`, `applySmartFill`
3. Inject via `.environment(flowViewModel)` in app entry
4. **58 FlowViewModel tests**

### Verification

All `FlowViewModelTests` pass — **unblocks UI tracks**.

---

## Phase 8 — Premium UI components

**Status:** ✅ done  
**Files:** `LinenFlow/Views/Components/*`

### Steps

1. `PremiumCard` — variants, `isCurrent: Bool`, Reduce Motion
2. `PremiumExpressionInput` — arithmetic commit, haptics, error border
3. `AppBackground`, `EmptyStateView`, `WarningCard`, `LinenItemIcon`, `IntelligenceCards`, `KeyboardPinnedEditorShell`

### Verification

Build + SwiftUI previews compile.

---

## Phase 9 — 5-tab shell & deep links

**Status:** ✅ done  
**Files:** `AppRootView.swift`, `WidgetDeepLinkRouter.swift`

### Steps

1. `TabView`: Linen (`HomeView`), Shift, Insights, Logs, Settings
2. `WidgetDeepLinkCoordinator` — parse `himmerflow://` / `linenflow://` widget URLs
3. `.onOpenURL` → switch tab + optional delivery push

### Verification

- `WidgetDeepLinkRouterTests` pass
- Simulator: `xcrun simctl openurl booted "himmerflow://widget/delivery?tower=Lagoon"`

---

## Phase 10 — HomeView & one-screen linen cards

**Status:** ✅ done  
**Files:** `HomeView.swift`, `OneScreenLinenItemCard.swift`

### Steps

1. Inline tower picker (collapsed/expanded), item selection card
2. `OneScreenLinenItemCard` — expression input, summary, distribution, trip/widget pills
3. `EquatableLinenListCard` + `LazyVStack` for performance
4. Focus management + keyboard toolbar

### Verification (Gate 2)

1. Select Lagoon → Bath Towel + Hand Towel → Save items
2. Enter 100 on Bath Towel → 20 bundles, floor distribution visible
3. No keyboard layout crashes

---

## Phase 11 — Intelligence & restore

**Status:** ✅ done  
**Files:** `ShiftIntelligenceService.swift`, `HomeView` smart fill sections

### Steps

1. Restore Last Log when entries empty and log exists
2. Smart Fill card when `smartFillItemCount > 0`
3. `refreshShiftIntelligence()` on appear / tower change

### Verification

With seeded logs, Smart Fill and Restore appear before first entry.

---

## Phase 12 — Save, clear, delivery

**Status:** ✅ done  
**Files:** `DailyLogSaveService.swift`, `HomeView` chrome, `ShiftCommandCenterView.swift`

### Steps

1. Inline Save Log / Clear with confirmation
2. `DailyLogSaveService` — encode snapshots, insert `DailyLog`
3. Bottom chrome `NavigationLink` → `ShiftCommandCenterView`
4. **11 DailyLogSaveTests**

### Verification (Gate 3)

Save → Logs tab shows entry; Clear works; Open Delivery loads command center.

---

## Phase 13 — Widget sync & Live Activities

**Status:** ✅ done  
**Files:** `SharedWidgetStateManager.swift`, `LinenFlow Widget/`, `LiveActivityManager.swift`

### Steps

1. App Group `group.com.himmerflow.shared` (+ legacy migration)
2. `FlowViewModel.syncWidgetState()` on recalculate / tower change / trip toggle
3. Widget extension reads shared JSON; Live Activity for delivery/shift

### Verification

Pin item on card → widget reflects; deep link opens Linen tab.

---

## Phase 14 — Shift tab & work schedule

**Status:** ✅ done  
**Files:** `ShiftTabView.swift`, `Views/WorkSchedule/*`, `ShiftOrchestrator.swift`, location/notifications

### Steps

1. Shift timing, pace, today plan, commute, alarms, leaving checklist
2. `LocationService` + geofences for leave/arrive phases
3. `NotificationService` for shift reminders
4. Tests: `ShiftPlannerTests`, `GeofenceHandlingTests`, `NotificationSchedulingTests`

### Verification

Shift tab loads; planner tests pass.

---

## Phase 15 — Insights & Logs tabs

**Status:** ✅ done  
**Files:** `InsightsView.swift`, `LogsView.swift`, `LogDetailView.swift`, `DailyReportService.swift`

### Steps

1. Logs tab — SwiftData `@Query` on `DailyLog`, detail view with snapshots
2. Insights — analytics via `DailyReportService`
3. CSV export if present in Settings

### Verification

`DailyReportServiceTests` pass; log detail shows frozen snapshot counts.

---

## Phase 16 — Settings, onboarding, property map

**Status:** ✅ done  
**Files:** `SettingsView.swift`, `OnboardingFlow.swift`, `PropertyMapView.swift`, `Docs/site-plan/`

### Steps

1. Tower/item editors (bundle size locked in UI)
2. Tower calibration, QR property sharing, monitoring tier
3. Onboarding flow for first launch
4. Site plan SVG + `Docs/site-plan/index.html` synced with `DefaultData.swift`

### Verification

```bash
open Docs/site-plan/index.html
```

Settings builds; map pins match seed towers.

---

## Phase 17 — Accessibility polish 🟡

**Status:** partial — **START HERE for remaining work**  
**Prerequisites:** Phase 10  
**Parallel with:** Phase 19 (different files)  
**NightRaven:** `/nightraven Phase 17 — Linen accessibility`

**Serialize:** `HomeView.swift` — one agent at a time with Phase 18.

### Files

- `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift`
- `LinenFlow/Views/HomeView.swift`
- `LinenFlow/Views/Components/KeyboardPinnedEditorShell.swift`
- `LinenFlow/Views/Components/PremiumCard.swift`

### Steps

1. **P0 — Wire `PremiumCard.isCurrent`**
   - Pass `isCurrent: isFocused` inside `OneScreenLinenItemCard`
   - Remove duplicate focused stroke overlay from `HomeView` if present
   - Pass `isCurrent: true` on `KeyboardEditingPlaceholder` pinned editor card

2. **P1 — VoiceOver**
   - Distribution expand/collapse — label + hint
   - Expression input — announce parsed result on commit
   - Floor rows — "{pieces} pieces to floors {range}"
   - Trip/Widget pills — toggle state announced

3. **P2 — Dynamic Type**
   - Test `XXXL` on card grid and summary strip
   - `minimumScaleFactor` on dense labels; stacked layout fallback

4. **P3 — Reduce Motion**
   - Respect `@Environment(\.accessibilityReduceMotion)` on card scale and picker animations

### Verification

```bash
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```

Manual: VoiceOver walkthrough per [`Docs/LinenTabManualQA.md`](LinenTabManualQA.md) § Accessibility.

**Expected:** Full happy path readable; no silent controls.

---

## Phase 18 — Wizard orphan cleanup 🟡

**Status:** partial  
**Prerequisites:** Phase 10  
**NightRaven:** `/nightraven Phase 18 — wizard Legacy cleanup`

### Recommended: Option A (archive — largely done)

1. Confirm wizard views live in `LinenFlow/Views/Flow/Legacy/`
2. Remove `navigationDestination(for: FlowStep.self)` from `HomeView` if still present
3. Verify Legacy files **excluded** from HimmerFlow target in `project.pbxproj`
4. Update `Docs/FinalReport.md` navigation table if needed

### Verification

- Grep `FlowStep` in `HomeView.swift` — no production navigation push
- Build succeeds without Legacy in compile sources

---

## Phase 19 — Floor detection delivery polish 🟡

**Status:** partial (services exist; UI wiring in progress)  
**Prerequisites:** Phase 12  
**NightRaven:** `/nightraven Phase 19 — floor detection UI`

### Files

- `LinenFlow/Services/FloorSensingService.swift`, `FloorSensingEstimator.swift`
- `LinenFlow/ViewModels/FlowViewModel.swift` — session lifecycle hooks
- `LinenFlow/Views/Components/FloorDetectionCard.swift`
- `LinenFlow/Views/Flow/ShiftCommandCenterView.swift`, `FloorChecklistView.swift`

### Steps

1. Start/stop `FloorSensingService` with delivery session active
2. Bind `FloorSensingState` to `FloorDetectionCard` in command center
3. Highlight current floor in `FloorChecklistView` when confidence ≥ medium
4. **Correct floor** control updates estimator baseline
5. Simulator: show graceful `unavailable` — no crash (no barometer hardware)
6. Device: verify barometer updates with real altitude changes

### Verification

```bash
xcodebuild … test -only-testing:HimmerFlowTests/FloorSensingEstimatorTests
```

Manual on **physical iPhone** with barometer during mock delivery session.

---

## Phase 20 — LogFilterBuilder ⬜

**Status:** pending  
**Prerequisites:** Phase 15  
**NightRaven:** `/nightraven Phase 20 — LogFilterBuilder`

### Files

- Create: `LinenFlow/Services/LogFilterBuilder.swift`
- Modify: `LinenFlow/Views/Logs/LogsView.swift`
- Enable: `LinenFlowTests/LogFilterBuilderTests.swift` (currently commented stub)

### Steps

1. Read git history / stub comments in `LogFilterBuilderTests.swift` for expected API
2. Implement pure filter builder: by tower, date range, item name, search text
3. Wire filter UI on Logs tab (chips or sheet — match app chrome)
4. Uncomment and fix all tests in `LogFilterBuilderTests.swift`
5. Ensure filtered results use snapshot fields only (not live LinenItem)

### Verification

```bash
xcodebuild … test -only-testing:HimmerFlowTests/LogFilterBuilderTests
```

Manual: filter Lagoon logs → only Lagoon entries shown.

---

## Phase 21 — TowerConfigService ⬜

**Status:** pending  
**Prerequisites:** Phase 16  
**NightRaven:** `/nightraven Phase 21 — TowerConfigService`

### Files

- Create: `LinenFlow/Services/TowerConfigService.swift`
- Modify: Settings tower editors as needed
- Enable: `LinenFlowTests/TowerConfigServiceTests.swift`

### Steps

1. Read stub tests for expected behaviors (import/export, validation, operational policy)
2. Service loads/saves tower config blobs (JSON or SwiftData) — active floor count, locks, calibration refs
3. Integrate with `TowerOperationalPolicy` and `TowerCalibrationService` without duplicating logic
4. Settings UI calls service — no business logic in views
5. Uncomment `TowerConfigServiceTests`

### Verification

```bash
xcodebuild … test -only-testing:HimmerFlowTests/TowerConfigServiceTests
```

---

## Phase 22 — Android parity ⏭

**Status:** skipped — **OUT OF SCOPE** (user: no Android). Do not dispatch; historical reference only.  
**Prerequisites:** Phases 10–12 concepts  
**Parallel:** entire `android/` tree independent of iOS  
**NightRaven:** `/nightraven Phase 22 — Android parity`

### Files

- `android/app/src/main/java/com/himmerflow/android/ui/HimmerFlowApp.kt`
- `android/.../HimmerFlowViewModel.kt`
- `android/.../data/LinenCalculator.kt`
- `android/.../widget/HimmerFlowWidgetProvider.kt`

### Steps

1. **Done:** tower picker, item list, piece entry, calculate
2. **Todo:** Smart Fill / Restore last log (port `ShiftIntelligence` concepts)
3. **Todo:** Per-item inline floor distribution cards (match iOS one-screen model)
4. **Todo:** Open Delivery → delivery command screen
5. **Todo:** Widget sync parity with App Group equivalent (`WidgetStateStore.kt`)
6. Align package name / branding with HimmerFlow

### Verification

```bash
cd android && ./gradlew assembleDebug test
```

Manual parity checklist:

| Feature | iOS | Android |
|---------|-----|---------|
| Tower select | ✅ | ✅ |
| Item configure | ✅ | verify |
| Arithmetic entry | ✅ | verify |
| Inline distribution | ✅ | ⬜ |
| Smart fill | ✅ | ⬜ |
| Save log | ✅ | ⬜ |
| Delivery screen | ✅ | ⬜ |
| Home widget | ✅ | partial |

---

## Phase 23 — XCUITest target ⬜

**Status:** pending  
**Prerequisites:** Phases 17–18  
**NightRaven:** `/nightraven Phase 23 — XCUITest`

### Files

- Create: `LinenFlowUITests/LinenTabUITests.swift`
- Modify: `LinenFlow.xcodeproj/project.pbxproj`, `TestPlan.xctestplan`

### Steps

1. Add UI Testing Bundle target **LinenFlowUITests** in Xcode
2. Add accessibility identifiers to critical controls (tower picker, item card, Save Log) — minimal churn
3. Test: launch → Linen tab default
4. Test: select tower → enter pieces → summary visible
5. Test: Save log → Logs tab → new entry visible
6. Wire into `TestPlan.xctestplan` and CI if separate scheme needed

### Verification

```bash
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```

**Expected:** UI tests green alongside 283+ unit tests.

---

## Phase 24 — CI & release hardening 🟡

**Status:** partial  
**Prerequisites:** Phase 23  
**Files:** `.github/workflows/ios-ci.yml`, `android-ci.yml`, `swift-format.yml`, `codeql.yml`

### Steps

1. Confirm `ios-ci` runs build + test on `macos-15` with simulator discovery
2. Confirm `android-ci` runs `./gradlew assembleDebug`
3. Add UI test step to CI when Phase 23 complete (may need longer timeout)
4. Verify Dependabot + CodeQL workflows active
5. Document signing: CI uses `CODE_SIGNING_ALLOWED=NO` for simulator builds

### Verification

Push branch → GitHub Actions all green (or `workflow_dispatch` manual run).

---

## Phase 25 — Final QA & release gate ⬜

**Status:** pending  
**Prerequisites:** All phases 17–24  
**NightRaven:** `/nightraven Phase 25 — Final QA — God's Eye Final Report`

### Steps

1. Run full `ios_test` — **≥283** unit tests + UI tests
2. Run `android` build + tests
3. Complete [`Docs/LinenTabManualQA.md`](LinenTabManualQA.md) end-to-end
4. Update [`Docs/CriteriaChecklist.md`](CriteriaChecklist.md) — all rows ✅
5. Update [`Docs/FinalReport.md`](FinalReport.md) with final counts
6. Append handoff Recent sessions + changelog `+#`
7. Present **God's Eye Final Report** per NightRaven skill template (Verdict PASS)

### Verification

| Gate | Command / check | Expected |
|------|-----------------|----------|
| Unit tests | `xcodebuild … test` | TEST SUCCEEDED, 283+ |
| UI tests | same | Linen smoke green |
| Android | `./gradlew assembleDebug` | BUILD SUCCESSFUL |
| Manual QA | LinenTabManualQA.md | All checkboxes |
| Ledgers | `docs/ledgers/BUILD_LEDGER.md` | Every mutation logged |

---

## Parallel execution matrix (remaining work)

```
Phase 17 (a11y) ──┬── Phase 19 (floor)     [different files — can parallel]
Phase 18 (wizard) ┘   [serialize HomeView + pbxproj with 17]

Phase 20 (LogFilter) ── parallel with 21 (TowerConfig) — no file overlap

Phase 22 (Android) ── fully parallel with all iOS tracks

Phase 23 (XCUITest) ── after 17+18

Phase 24 (CI) ── after 23

Phase 25 (QA) ── after all
```

| Agent | Phase | Files | Est. |
|-------|-------|-------|------|
| 1 | 17 P0 | `OneScreenLinenItemCard`, `HomeView` (stroke removal) | 2–4 h |
| 2 | 17 P1 | `OneScreenLinenItemCard` only | 4–6 h |
| 3 | 18 | `HomeView`, Legacy/, `pbxproj` | 2–3 h |
| 4 | 19 | `FlowViewModel`, delivery views, `FloorDetectionCard` | 6–10 h |
| 5 | 20–21 | Services + Logs/Settings | 8–12 h |
| 6 | 22 | `android/**` | 16–24 h |
| 7 | 23–24 | UITests + CI | 8–12 h |

---

## Protected invariants (never break)

1. Bundle constants locked in `BundleLibrary`
2. Calculations only in services — never in views
3. Daily logs = immutable snapshots
4. Widget state via App Group only from extension
5. Private repo — no public GitHub publish without Brent approval

---

## File ownership (hotspots)

| File | Risk | Owner phases |
|------|------|--------------|
| `HomeView.swift` | Critical | 10, 11, 12, 17, 18 |
| `FlowViewModel.swift` | Critical | 7, 13, 19 |
| `project.pbxproj` | High | 18, 23 |
| `OneScreenLinenItemCard.swift` | Medium | 10, 17 |
| `android/**` | Isolated | 22 |

---

## Commit strategy

- Conventional commits: `feat(linen):`, `a11y(linen):`, `fix(android):`, `test(ui):`
- One commit per completed phase task group
- Run build/tests before each commit
- Update `AGENT_WORK_LOG.md` on track completion
- NightRaven: append `BuildStarted` / `FeatureBuilt` to `docs/ledgers/BUILD_LEDGER.md`

---

## Related documents

| Doc | Purpose |
|-----|---------|
| `Docs/FinalReport.md` | Completion snapshot |
| `Docs/CriteriaChecklist.md` | 21-task + extension status |
| `Docs/BuildLog.md` | Historical May 2026 build sequence |
| `Docs/AGENT_COORDINATION.md` | Parallel agent rules |
| `docs/37_GODS_EYE.md` | Portable agent law |
| `.claude/skills/nightraven/SKILL.md` | Orchestration protocol |

---

*Plan authored 2026-06-11 for Grav Nightraven execution. Resume at Phase 17.*
