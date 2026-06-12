# Linen Tab — Grand Master Plan (Parallel Execution)

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement tracks task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Coordination file:** Claim work in `AGENT_WORK_LOG.md` before touching files. Never edit the same file from two parallel agents.

> **Scope (2026-06-11):** **Android / Track K / Phase 13 is OUT OF SCOPE.** Do not dispatch parallel agents on `android/**`. iOS tracks (A–J, L) and God's Eye coordination continue unchanged.


**Goal:** Build and maintain the **Linen tab** — the primary operational surface where hotel linen attendants select a tower, enter received inventory, see inline calculations and per-floor distribution, save daily logs, and open live delivery guidance.

**Architecture:** The Linen tab is **not** a separate `LinenTabView`. It is tab index 0 in `AppRootView`, labeled "Linen", deep-link key `.home`, root view **`HomeView`**. State lives in app-scoped **`FlowViewModel`**; calculations live in **`LinenCalculatorService`** (never in views). The primary UX is a **one-screen card grid** (`OneScreenLinenItemCard`) that supersedes the older multi-step wizard (`ReceivingView` → `ReviewReceivedView` → `ResultsView` → `FloorDistributionView`).

**Tech Stack:** SwiftUI, SwiftData (`@Model` + `@Query`), `@Observable` ViewModels, WidgetKit App Group sync, iOS 26.0, Xcode 26.x.

**Current status (2026-06-08):** Core Linen tab workflow is **production-complete**. This plan covers (a) canonical build-from-zero sequence, (b) parallel polish tracks, and (c) open architectural decisions.

---

## Table of Contents

1. [Definition of Done](#1-definition-of-done)
2. [System Map](#2-system-map)
3. [Parallel Execution Matrix](#3-parallel-execution-matrix)
4. [Phase 0 — Agent Coordination Setup](#phase-0--agent-coordination-setup)
5. [Phase 1 — Data Foundation (Track A)](#phase-1--data-foundation-track-a)
6. [Phase 2 — Calculation Engine (Track A continued)](#phase-2--calculation-engine-track-a-continued)
7. [Phase 3 — FlowViewModel (Track A gate)](#phase-3--flowviewmodel-track-a-gate)
8. [Phase 4 — Shared UI Components (Track B)](#phase-4--shared-ui-components-track-b)
9. [Phase 5 — Tab Shell & Deep Links (Track C)](#phase-5--tab-shell--deep-links-track-c)
10. [Phase 6 — HomeView Scaffold (Track D)](#phase-6--homeview-scaffold-track-d)
11. [Phase 7 — One-Screen Linen Cards (Track E)](#phase-7--one-screen-linen-cards-track-e)
12. [Phase 8 — Intelligence & Restore (Track F)](#phase-8--intelligence--restore-track-f)
13. [Phase 9 — Save, Clear, Delivery (Track G)](#phase-9--save-clear-delivery-track-g)
14. [Phase 10 — Widget Sync (Track H)](#phase-10--widget-sync-track-h)
15. [Phase 11 — Polish & Accessibility (Track I)](#phase-11--polish--accessibility-track-i)
16. [Phase 12 — Wizard Flow Decision (Track J)](#phase-12--wizard-flow-decision-track-j)
17. [Phase 13 — Android Parity (Track K) — SKIPPED](#phase-13--android-parity-track-k--out-of-scope--skipped)
18. [Phase 14 — UI Tests (Track L)](#phase-14--ui-tests-track-l)
19. [Verification Gates](#verification-gates)
20. [File Ownership Map](#file-ownership-map)

---

## 1. Definition of Done

The Linen tab is **done** when all of the following hold:

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | Tab appears first in `AppRootView` with label "Linen" and `shippingbox.fill` icon | Visual + `AppRootView.swift` |
| 2 | User can select a tower inline (no separate tower screen) | Manual: pick Lagoon/GI/GW/Diamond/Alii |
| 3 | User can configure which linen items apply to the tower | Item selection card saves to SwiftData |
| 4 | User can enter received pieces per item with arithmetic expressions | `PremiumExpressionInput` → `FlowViewModel.addOrUpdateReceivedPieces` |
| 5 | Calculations and floor distribution update inline on each entry | `recalculate()` → card summary + distribution rows |
| 6 | Smart Fill and Restore Last Log work when no entries exist | `SmartFillCard`, `useLastLogCard` |
| 7 | Save Log persists immutable snapshot to SwiftData | `DailyLogSaveService` + Logs tab shows entry |
| 8 | Clear Entries resets flow state with confirmation | Confirmation dialog + `clearEntries()` |
| 9 | Open Delivery navigates to `ShiftCommandCenterView` | Bottom chrome `NavigationLink` |
| 10 | Widget deep links land on Linen tab and can open delivery | `linenflow://widget/...` URLs |
| 11 | `xcodebuild test` passes all 283+ unit tests | CI green |
| 12 | VoiceOver reads focused card, distribution, and actions | Accessibility audit |
| 13 | `PremiumCard.isCurrent` wired for focused linen card (no duplicate stroke) | Visual + code review |

---

## 2. System Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│ AppRootView (TabView)                                                   │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ Tab 0: Linen → HomeView                                          │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐  │   │
│  │  │ TowerPicker │  │ SmartFill /  │  │ OneScreenLinenItemCard  │  │   │
│  │  │ + Map       │  │ Restore Log  │  │ grid (per item)         │  │   │
│  │  └──────┬──────┘  └──────┬───────┘  └───────────┬─────────────┘  │   │
│  │         │                │                      │                │   │
│  │         └────────────────┴──────────────────────┘                │   │
│  │                          │                                       │   │
│  │                   FlowViewModel (@Environment)                   │   │
│  │                          │                                       │   │
│  │         ┌────────────────┼────────────────┐                      │   │
│  │         ▼                ▼                ▼                      │   │
│  │  LinenCalculator   ShiftIntelligence   DailyLogSaveService        │   │
│  │  Service           Service                                    │   │
│  │         │                │                │                      │   │
│  │         ▼                ▼                ▼                      │   │
│  │  BundleLibrary     @Query DailyLog    SwiftData DailyLog         │   │
│  │  FloorRangeBuilder                                                 │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│  Bottom chrome: Open Delivery → ShiftCommandCenterView                  │
│  WidgetDeepLinkCoordinator → .home tab + delivery push                  │
└─────────────────────────────────────────────────────────────────────────┘
```

### User flow (happy path)

```
Open app → Linen tab
  → Expand tower picker → Select "Lagoon" (21 floors)
  → Configure items (Bath Towel, Hand Towel, …) → Save
  → Tap Smart Fill OR enter pieces on first card
  → Cards show summary (bundles, loose, status) + floor distribution
  → Save Log
  → Open Delivery → ShiftCommandCenterView (pace, trips, checklist)
```

---

## 3. Parallel Execution Matrix

Tracks can run **in parallel** once their dependencies are met. Use `AGENT_WORK_LOG.md` to claim a track.

```
Phase 0 ─────────────────────────────────────────────────────────────►
         │
Phase 1-3 (Track A: Models + Services + FlowViewModel) ─── GATE ────►
         │                                                    │
         ├──────────────┬──────────────┬──────────────┬────────┴────────┐
         ▼              ▼              ▼              ▼               ▼
    Track B         Track C         Track D        Track E         Track F
    Components      Tab Shell       HomeView       LinenCard       Intelligence
    (parallel)      + DeepLinks     Scaffold       (parallel)      + Restore
         │              │              │              │               │
         └──────────────┴──────────────┴──────────────┴───────────────┘
                                    │
                              INTEGRATION GATE
                                    │
         ┌──────────────┬───────────┴───────────┬──────────────┐
         ▼              ▼                       ▼              ▼
    Track G         Track H                  Track I        Track J
    Save/Clear/     Widget Sync              Polish/a11y    Wizard decision
    Delivery        (parallel w/ G)          (after E)      (optional)
         │              │                       │              │
         └──────────────┴───────────────────────┴──────────────┘
                                    │
                              FINAL QA GATE
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
            (Track K SKIPPED)                  Track L
            Android — OUT OF SCOPE             XCUITest (optional)
```

| Track | Agent focus | Depends on | Can parallel with |
|-------|-------------|------------|-------------------|
| **A** | Models, Services, FlowViewModel | — | Nothing (start here) |
| **B** | PremiumCard, PremiumExpressionInput, AppBackground | A (models only) | A (late stage) |
| **C** | AppRootView, WidgetDeepLinkRouter | A | B |
| **D** | HomeView tower picker, header, empty state | A, B (partial) | B, E (not same files) |
| **E** | OneScreenLinenItemCard | A, B | D (different files) |
| **F** | SmartFillCard, useLastLogCard wiring | A, D (HomeView sections) | E |
| **G** | Save/Clear/Delivery bottom chrome | A, D | H |
| **H** | SharedWidgetStateManager wiring | A, G | G |
| **I** | isCurrent, VoiceOver, Dynamic Type | E, D | — (touches HomeView + card) |
| **J** | Wizard orphan decision | D | K, L |
| ~~**K**~~ | ~~Android LinenScreen~~ | — | **OUT OF SCOPE (2026-06-11)** |
| **L** | XCUITest target | All iOS | I, J (optional) |

---

## Phase 0 — Agent Coordination Setup

**Files:**
- Create/Update: `AGENT_WORK_LOG.md`

- [ ] **Step 1:** Create `AGENT_WORK_LOG.md` with Active Claims table (Agent ID, Task, Files, Status, Started).

- [ ] **Step 2:** Before any edit, add a row to Active Claims with exact file list.

- [ ] **Step 3:** On completion, move row to Completed Work with build/test results.

- [ ] **Step 4:** Commit coordination file separately from feature work when possible.

**Conflict rules:**
- `HomeView.swift` — **one agent at a time** (1,180 lines, many sections).
- `FlowViewModel.swift` — **one agent at a time**.
- `OneScreenLinenItemCard.swift` — separate from HomeView; can parallel if HomeView agent only wires `EquatableLinenListCard`.

---

## Phase 1 — Data Foundation (Track A)

**Files:**
- Create: `LinenFlow/Models/Tower.swift`
- Create: `LinenFlow/Models/LinenItem.swift`
- Create: `LinenFlow/Models/ReceivingEntry.swift`
- Create: `LinenFlow/Models/CalculationSummary.swift`
- Create: `LinenFlow/Models/FloorDistributionRow.swift`
- Create: `LinenFlow/Models/DailyLog.swift`
- Create: `LinenFlow/Models/CountMethod.swift`
- Create: `LinenFlow/Models/CalculationStatus.swift`
- Create: `LinenFlow/SeedData/DefaultData.swift`
- Create: `LinenFlow/SeedData/SeedService.swift`
- Modify: `LinenFlow/App/HimmerFlowApp.swift`

### Task 1.1: SwiftData models

- [ ] **Step 1:** Create `@Model Tower` with `name`, `floorCount`, `identityColorHex`, `sortOrder`, operational flags.

- [ ] **Step 2:** Create `@Model LinenItem` with `name`, `bundleSize`, `countMethod`, `allowedTowerNames` (stored as JSON `Data` with computed `[String]` accessor), `sortOrder`, `displayGroup`.

- [ ] **Step 3:** Create Codable structs `ReceivingEntry`, `CalculationSummary`, `FloorDistributionRow` for transient + snapshot use.

- [ ] **Step 4:** Create `@Model DailyLog` with encoded snapshot `Data` fields (`entriesSnapshot`, `summarySnapshot`, `distributionSnapshot`) — **immutable logs, never live references**.

- [ ] **Step 5:** Create enums `CountMethod`, `CalculationStatus`.

### Task 1.2: Seed data

- [ ] **Step 1:** In `DefaultData.swift`, define 5 towers: Lagoon (21), GI (32), GW (31), Diamond (15), Alii (14).

- [ ] **Step 2:** Define 11 linen items with locked bundle sizes (Bath Towel 5, Bath Mat 10, Hand Towel 20, Washcloth 50, Pillow Case 50, sheets/covers 5).

- [ ] **Step 3:** In `SeedService.swift`, implement idempotent `seedIfNeeded(context:)` — skip if towers exist.

- [ ] **Step 4:** Wire `ModelContainer` in `HimmerFlowApp.swift` for `Tower`, `LinenItem`, `DailyLog`; call seed on launch.

**Verify:**
```bash
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone Air' build
```
Expected: **BUILD SUCCEEDED**

---

## Phase 2 — Calculation Engine (Track A continued)

**Files:**
- Create: `LinenFlow/Utilities/ArithmeticParser.swift`
- Create: `LinenFlow/Services/ArithmeticExpressionService.swift`
- Create: `LinenFlow/Services/BundleLibrary.swift`
- Create: `LinenFlow/Services/LinenCalculatorService.swift`
- Create: `LinenFlow/Services/FloorRangeBuilder.swift`
- Create: `LinenFlowTests/ArithmeticTests.swift`
- Create: `LinenFlowTests/CalculatorTests.swift`

### Task 2.1: Safe arithmetic

- [ ] **Step 1:** Implement `ArithmeticParser` — tokenize `+`, `-`, `*`, `/`, integers; no eval injection.

- [ ] **Step 2:** Write 26 tests in `ArithmeticTests.swift` covering valid expressions, empty, divide-by-zero, overflow guards.

### Task 2.2: Calculator service (pure functions only)

- [ ] **Step 1:** `BundleLibrary` — canonical names, aliases, protected constants.

- [ ] **Step 2:** `LinenCalculatorService.calculateSummary(item:receivedPieces:floorCount:)` → `CalculationSummary`.

- [ ] **Step 3:** `LinenCalculatorService.distributeAcrossFloors(...)` → `[FloorDistributionRow]`.

- [ ] **Step 4:** `FloorRangeBuilder` — format floor ranges for card display ("12–15", "3, 5, 7").

- [ ] **Step 5:** Write 19+ calculator tests pinning every formula.

**Invariant:** No SwiftUI imports in Services. Views never compute bundles — they call ViewModel → Service.

**Verify:**
```bash
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone Air' test \
  -only-testing:HimmerFlowTests/ArithmeticTests \
  -only-testing:HimmerFlowTests/CalculatorTests
```

---

## Phase 3 — FlowViewModel (Track A gate)

**Files:**
- Create: `LinenFlow/ViewModels/FlowViewModel.swift`
- Create: `LinenFlowTests/FlowViewModelTests.swift`
- Modify: `LinenFlow/App/HimmerFlowApp.swift`

### Task 3.1: Core state

- [ ] **Step 1:** `@Observable class FlowViewModel` with:
  - `selectedTower`, `availableTowers`, `availableItems`
  - `receivingEntries`, `calculationSummaries`, `floorDistributions`, `deliveryFloorDistributions`
  - `validationWarnings`, `deliveryUnitIsBundles`
  - `deliverySessionState` (for Shift Command Center)

- [ ] **Step 2:** `selectTower(_:)` — reset entries on tower change; warn if delivery active.

- [ ] **Step 3:** `addOrUpdateReceivedPieces(item:pieces:)` → `recalculate()`.

- [ ] **Step 4:** `recalculate()` — guard `selectedTower`; call `LinenCalculatorService` per entry; populate summaries + distributions.

- [ ] **Step 5:** `saveSelectedItems(_:for:)`, `selectedItemIDs(for:)`, `itemDisplayGroups`.

- [ ] **Step 6:** `clearEntries()`, `loadFromLog(_:)`, `applySmartFill()`, `updateShiftIntelligence(from:)`.

- [ ] **Step 7:** `syncWidgetState(...)` stub (filled in Phase 10).

- [ ] **Step 8:** Inject via `.environment(flowViewModel)` in `HimmerFlowApp.swift`.

### Task 3.2: Tests (58 cases)

- [ ] Cover tower selection, piece entry, recalculate, smart fill, log restore, widget item pinning, delivery session.

**Verify:** All `FlowViewModelTests` pass. This unblocks Tracks B–H.

---

## Phase 4 — Shared UI Components (Track B)

**Parallel with:** Late Track A, early Track C

**Files:**
- Create: `LinenFlow/Views/Components/PremiumCard.swift`
- Create: `LinenFlow/Views/Components/PremiumCardLayout.swift`
- Create: `LinenFlow/Views/Components/PremiumExpressionInput.swift`
- Create: `LinenFlow/Views/Components/AppBackground.swift`
- Create: `LinenFlow/Views/Components/EmptyStateView.swift`
- Create: `LinenFlow/Views/Components/WarningCard.swift`
- Create: `LinenFlow/Views/Components/LinenItemIcon.swift`
- Create: `LinenFlow/Views/Components/TowerPickerEnvironmentView.swift`
- Create: `LinenFlow/Views/Components/KeyboardPinnedEditorShell.swift`
- Create: `LinenFlow/Views/Components/IntelligenceCards.swift`

### Task 4.1: PremiumCard

- [ ] Implement `PremiumCardStyle` variants: `.standard`, `.fullAccent`, `.solid(Color)`.
- [ ] Add `isCurrent: Bool = false` — accent glow, scale 1.008, `.isSelected` trait, Reduce Motion respect.
- [ ] `PremiumCardActionRow` — leading content + trailing CTA without layout shift.

### Task 4.2: PremiumExpressionInput

- [ ] Arithmetic text field; evaluates via `ArithmeticExpressionService` on commit.
- [ ] Haptic on valid commit; red border on parse error.
- [ ] Focus callbacks for parent card focus management.

### Task 4.3: Supporting components

- [ ] `AppBackground` — gradient + accent color from selected tower.
- [ ] `EmptyStateView` — icon, title, message (used when no tower selected).
- [ ] `SmartFillCard` in `IntelligenceCards.swift` — confidence badge, apply CTA.
- [ ] `KeyboardEditingToolbar` — Done, next item, dismiss.

**Verify:** Build succeeds. Components previewable in Xcode canvas.

---

## Phase 5 — Tab Shell & Deep Links (Track C)

**Files:**
- Create: `LinenFlow/Views/AppRootView.swift`
- Create: `LinenFlow/Utilities/WidgetDeepLinkRouter.swift`
- Modify: `LinenFlow/App/HimmerFlowApp.swift`

### Task 5.1: Register Linen tab

```swift
TabView(selection: $deepLinkCoordinator.selectedTab) {
    HomeView()
        .tabItem { Label("Linen", systemImage: "shippingbox.fill") }
        .tag(WidgetDeepLinkCoordinator.Tab.home)
    // Shift, Insights, Logs, Settings...
}
.environment(deepLinkCoordinator)
.onOpenURL { deepLinkCoordinator.handle($0, flowViewModel: flowViewModel) }
```

### Task 5.2: Deep link coordinator

- [ ] `enum Tab: Hashable { case home, shift, insights, logs, settings }`
- [ ] Parse `linenflow://widget/start` → `selectedTab = .home`
- [ ] Parse `linenflow://widget/delivery?tower=...` → `.home` + `openDeliveryCommandCenter = true`
- [ ] `consumeDeliveryCommandCenterRequest()` after HomeView handles push

**Verify:** Simulator URL open switches to Linen tab.

---

## Phase 6 — HomeView Scaffold (Track D)

**Files:**
- Create: `LinenFlow/Views/HomeView.swift` (or rewrite)
- Modify: `LinenFlow.xcodeproj/project.pbxproj` (if new files)

### Task 6.1: Navigation shell

- [ ] `NavigationStack(path: $flowPath)` inside `HomeView`.
- [ ] `@Environment(FlowViewModel.self)`, `@Environment(WidgetDeepLinkCoordinator.self)`.
- [ ] `@Query` logs for shift intelligence.
- [ ] `AppBackground(accentColor: selectedTowerColor) { ScrollView { flowContent } }`.
- [ ] `.navigationTitle(viewModel.selectedTower?.name ?? "Linen Delivery")`.
- [ ] `.safeAreaInset(edge: .bottom) { bottomChrome }` — placeholder until Phase 9.
- [ ] Register `navigationDestination(for: FlowStep.self)` (wizard — Phase 12).
- [ ] `navigationDestination(isPresented: $showDeliveryCommandCenter) { ShiftCommandCenterView() }`.
- [ ] `.toolbar(placement: .keyboard) { itemEditingKeyboardBar }`.

### Task 6.2: Header

- [ ] Shipping-box icon with tower accent color.
- [ ] Tower name + "Today's linen run" subtitle.
- [ ] Date + live delivery indicator when session active.

### Task 6.3: Inline tower picker

- [ ] Collapsed row: selected tower name, floor count, chevron.
- [ ] Expanded: tower list cards with accent strips.
- [ ] `TowerPickerEnvironmentView` property map when `@AppStorage("isCustomProperty")`.
- [ ] `activeFloorCount` stepper respecting `TowerOperationalPolicy` locks.
- [ ] On select: `viewModel.selectTower(tower)`, collapse picker, `refreshShiftIntelligence()`.

### Task 6.4: Empty state

- [ ] When `selectedTower == nil`: `EmptyStateView("Choose a tower")`.
- [ ] When tower selected: show item selection + card area.

### Task 6.5: Item selection card

- [ ] Draft `draftSelectedItemIDs: Set<UUID>` local state.
- [ ] Expandable checklist grouped by `LinenItemDisplayGroup` (bath, bedding, specialty).
- [ ] Save → `viewModel.saveSelectedItems(draftSelectedItemIDs, for: tower)`.

**Verify:** Can select tower, configure items, see empty card list. No crashes on tower switch.

---

## Phase 7 — One-Screen Linen Cards (Track E)

**Files:**
- Create: `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift`
- Modify: `LinenFlow/Views/HomeView.swift` (wire `itemList` only)

### Task 7.1: Card structure

`OneScreenLinenItemCard` receives:
- `item: LinenItem`
- `entry: ReceivingEntry?`
- `summary: CalculationSummary?`
- `distributionRows: [FloorDistributionRow]`
- `unitIsBundles: Bool`
- `onPiecesChange: (Int) -> Void`
- Focus props: `focusRequest`, `focusReleaseRequest`, `onFocusChange`, `onEditRequested`

### Task 7.2: Card sections (top to bottom)

1. **Header** — `LinenItemIcon`, name, bundle size, background style picker (`LinenCardBackground` persisted per item via `@AppStorage`).
2. **Expression input** — `PremiumExpressionInput`; on commit → `onPiecesChange(calculatedPieces)`.
3. **Summary strip** — received pieces, full bundles, loose, status badge (`CalculationStatus`).
4. **Distribution** — collapsible section; floor rows with `FloorRangeBuilder` labels; ascending/descending toggle.
5. **Trip/Widget pills** — `viewModel.toggleCurrentTripItem`, `selectCurrentDeliveryItem` for widget sync.

### Task 7.3: Performance — Equatable wrapper

- [ ] `EquatableLinenListCard` in `HomeView.swift` — custom `==` ignoring distribution row internals when unchanged.
- [ ] `LazyVStack` in `itemList` grouped by `viewModel.itemDisplayGroups`.

### Task 7.4: Focus management

- [ ] `focusedItemID`, `focusRequest`, `focusReleaseRequest` in HomeView.
- [ ] Tap card → set focus; keyboard toolbar navigates next/previous item.
- [ ] **Do not** add duplicate stroke overlay — reserve for Phase 11 `isCurrent` wiring.

### Task 7.5: Wire itemList in HomeView

```swift
ForEach(group.items) { item in
    EquatableLinenListCard(
        item: item,
        entry: viewModel.receivingEntries.first { $0.itemName == item.name },
        summary: viewModel.calculationSummaries.first { $0.itemName == item.name },
        distributionRows: viewModel.deliveryFloorDistributions
            .first { $0.itemName == item.name }?.rows ?? [],
        unitIsBundles: viewModel.deliveryUnitIsBundles,
        hasSupplyAnomaly: viewModel.hasSupplyAnomaly(for: item),
        isFocused: focusedItemID == item.id,
        focusRequest: focusRequest,
        focusReleaseRequest: focusReleaseRequest,
        onEditRequested: { focusItem(item.id) },
        onFocusChange: { focused in handleFocusChange(item.id, focused) }
    )
}
```

**Verify:** Enter "100+50" on Bath Towel → summary shows 150 pieces, 30 bundles, distribution across 21 floors.

---

## Phase 8 — Intelligence & Restore (Track F)

**Files:**
- Modify: `LinenFlow/Views/HomeView.swift` (sections: `smartFillCard`, `useLastLogCard`)
- Uses: `LinenFlow/Services/ShiftIntelligenceService.swift`

### Task 8.1: Restore Last Log card

- [ ] Show when `viewModel.receivingEntries.isEmpty` and `latestLogForSelectedTower != nil`.
- [ ] Display tower name, date, item count from most recent `DailyLog` for selected tower.
- [ ] Restore button → `viewModel.loadFromLog(log)` + confirmation banner.

### Task 8.2: Smart Fill card

- [ ] Show when `viewModel.smartFillItemCount > 0` and entries empty.
- [ ] `SmartFillCard` with confidence from `viewModel.supplyPredictions`.
- [ ] Apply → `viewModel.applySmartFill()` + haptic + confirmation.

### Task 8.3: Shift intelligence refresh

- [ ] `refreshShiftIntelligence()` on appear, tower change, logs change.
- [ ] `viewModel.updateShiftIntelligence(from: logs)`.

**Verify:** With existing logs in simulator, Smart Fill and Restore appear before first entry.

---

## Phase 9 — Save, Clear, Delivery (Track G)

**Files:**
- Create: `LinenFlow/Services/DailyLogSaveService.swift`
- Modify: `LinenFlow/Views/HomeView.swift` (`inlineActions`, `bottomChrome`, `notesField`)
- Create: `LinenFlowTests/DailyLogSaveTests.swift`

### Task 9.1: Inline actions row

- [ ] **Save Log** → `DailyLogSaveService.save(viewModel:context:)` — success haptic + green confirmation card.
- [ ] **Clear** → `showClearConfirmation` dialog → `viewModel.clearEntries()`.
- [ ] Disable Save when no entries or validation warnings block.

### Task 9.2: Notes field

- [ ] Optional `TextField` bound to `viewModel.shiftNotes` when entries exist.

### Task 9.3: Summary strip

- [ ] When `!calculationSummaries.isEmpty`: total items, pieces, bundles, loose across all entries.

### Task 9.4: Bottom chrome — Open Delivery

- [ ] Pinned `NavigationLink` to `ShiftCommandCenterView`.
- [ ] Gradient button with tower accent; disabled when no tower.
- [ ] Deep link handler sets `showDeliveryCommandCenter = true`.

### Task 9.5: DailyLogSaveService

- [ ] Encode snapshots from current `viewModel` state.
- [ ] Insert `DailyLog` into SwiftData context.
- [ ] 11 tests in `DailyLogSaveTests`.

**Verify:** Save → check Logs tab → log appears with correct tower and counts.

---

## Phase 10 — Widget Sync (Track H)

**Files:**
- Modify: `LinenFlow/ViewModels/FlowViewModel.swift` (`syncWidgetState`)
- Uses: `LinenFlow/Services/SharedWidgetStateManager.swift`
- Uses: `LinenFlow Widget/HimmerFlow_Widget.swift`

### Task 10.1: Widget state on flow changes

- [ ] After `recalculate()`, `selectTower`, trip item toggle — call `syncWidgetState()`.
- [ ] Write to App Group `group.com.himmerflow.shared`.
- [ ] Include: tower name, pinned items, floor progress, delivery mode.

### Task 10.2: Card trip/widget pills

- [ ] In `OneScreenLinenItemCard`, show pinned state from `viewModel`.
- [ ] Toggle updates widget snapshot immediately.

**Verify:** Pin item on card → home screen widget reflects item. Deep link from widget opens Linen tab.

---

## Phase 11 — Polish & Accessibility (Track I)

**Status:** Partially done. **Highest priority remaining work.**

**Files:**
- Modify: `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift`
- Modify: `LinenFlow/Views/HomeView.swift`
- Modify: `LinenFlow/Views/Components/KeyboardPinnedEditorShell.swift`

### Task 11.1: Wire PremiumCard.isCurrent (P0)

- [ ] Pass `isCurrent: isFocused` into `PremiumCard` inside `OneScreenLinenItemCard`.
- [ ] Remove duplicate focused stroke overlay from `HomeView.itemCard` (if present).
- [ ] Pass `isCurrent: true` on `KeyboardEditingPlaceholder` pinned editor card.

### Task 11.2: VoiceOver pass (P1)

- [ ] Distribution expand/collapse — `accessibilityLabel` + hint.
- [ ] Expression input — announce parsed result on commit.
- [ ] Floor rows — "{pieces} pieces to floors {range}".
- [ ] Trip/Widget pills — toggle state announced.

### Task 11.3: Dynamic Type (P2)

- [ ] Test `XXXL` content size on card grid and summary strip.
- [ ] `minimumScaleFactor` on dense labels; allow stacked layout fallback.

### Task 11.4: Reduce Motion

- [ ] Respect `@Environment(\.accessibilityReduceMotion)` on card scale and picker animations.

**Verify:** VoiceOver walkthrough of full happy path without silent controls.

---

## Phase 12 — Wizard Flow Decision (Track J)

**Context:** `HomeView` registers `FlowStep` destinations but **nothing pushes** `flowPath` in normal use. One-screen flow supersedes wizard.

**Choose one:**

### Option A — Remove orphan wizard (recommended)

- [ ] Delete `navigationDestination(for: FlowStep.self)` from `HomeView`.
- [ ] Keep wizard views for potential Settings debug or remove from target.
- [ ] Update `Docs/FinalReport.md` navigation table.

### Option B — Add "Step-by-step mode" entry

- [ ] Add toolbar button "Wizard mode" → `flowPath.append(FlowStep.receiving)`.
- [ ] Wizard screens pre-populate from `FlowViewModel` state.
- [ ] On wizard completion, pop to root one-screen view.

### Option C — Archive only

- [ ] Move wizard views to `Views/Flow/Legacy/` folder.
- [ ] Exclude from build target.

**Parallel safe:** This track touches only `HomeView` navigation + Flow folder. Coordinate via AGENT_WORK_LOG.

---

## Phase 13 — Android Parity (Track K) — OUT OF SCOPE / SKIPPED

**User decision:** No Android parallel work. The `android/` tree is frozen for this plan; do not claim Track K in `AGENT_WORK_LOG.md`. Re-enable only with explicit user approval.

**Files (reference only — do not implement):**
- `android/app/src/main/java/com/himmerflow/android/ui/HimmerFlowApp.kt`
- `android/app/src/main/java/com/himmerflow/android/ui/HimmerFlowViewModel.kt`
- `android/app/src/main/java/com/himmerflow/android/data/LinenCalculator.kt`

### Task 13.1: LinenScreen basics (done)

- [ ] Tower picker, item list, piece entry, calculate.

### Task 13.2: Parity gaps

- [ ] Smart Fill / Restore last log.
- [ ] Per-item floor distribution inline cards.
- [ ] Widget sync (if Android widget planned).
- [ ] Open Delivery → delivery command screen.

**Parallel safe:** Entirely separate codebase from iOS tracks.

---

## Phase 14 — UI Tests (Track L)

**Files:**
- Create: `LinenFlowUITests/LinenTabUITests.swift`
- Modify: `LinenFlow.xcodeproj/project.pbxproj`

### Task 14.1: XCUITest target

- [ ] Add UI test target to Xcode project.
- [ ] Launch app → assert Linen tab selected by default.
- [ ] Select tower → enter piece count → assert summary visible.
- [ ] Save log → navigate to Logs tab → assert new entry.

**Note:** FinalReport lists this as known gap. Lower priority than Phase 11.

---

## Verification Gates

Run at each gate before merging parallel tracks.

### Gate 1 — After Track A (Phase 3)

```bash
xcodebuild -project /workspace/LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone Air' test
```
Expected: **TEST SUCCEEDED** (FlowViewModel + Calculator + Arithmetic)

### Gate 2 — After Tracks D+E (Phases 6–7)

Manual on simulator:
1. Select Lagoon → select Bath Towel + Hand Towel → Save items
2. Enter 100 on Bath Towel → see 20 bundles, floor distribution
3. No layout crashes on keyboard show/hide

### Gate 3 — After Tracks F+G (Phases 8–9)

1. Save log → verify in Logs tab
2. Clear entries → confirm dialog works
3. Open Delivery → ShiftCommandCenterView loads

### Gate 4 — Final

```bash
xcodebuild -project /workspace/LinenFlow.xcodeproj -scheme HimmerFlow \
  -destination 'platform=iOS Simulator,name=iPhone Air' test
```
Expected: **283+ tests passed**, build succeeded, manual VoiceOver pass.

---

## File Ownership Map

Use this to assign parallel agents without conflicts.

| File / Directory | Owner track | Notes |
|------------------|-------------|-------|
| `LinenFlow/Models/*` | A | Stable after Phase 1 |
| `LinenFlow/Services/LinenCalculatorService.swift` | A | Do not edit from UI tracks |
| `LinenFlow/Services/BundleLibrary.swift` | A | Locked constants |
| `LinenFlow/ViewModels/FlowViewModel.swift` | A, H | Serialize edits |
| `LinenFlow/Views/Components/PremiumCard.swift` | B, I | isCurrent API done; wiring in I |
| `LinenFlow/Views/Components/PremiumExpressionInput.swift` | B | |
| `LinenFlow/Views/Components/IntelligenceCards.swift` | B, F | |
| `LinenFlow/Views/AppRootView.swift` | C | |
| `LinenFlow/Utilities/WidgetDeepLinkRouter.swift` | C | |
| `LinenFlow/Views/HomeView.swift` | D, F, G, I, J | **Serialize** — highest conflict risk |
| `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift` | E, I | Can parallel with HomeView if only Equatable wrapper touched |
| `LinenFlow/Views/Flow/ShiftCommandCenterView.swift` | G | Delivery tab overlap — coordinate |
| `LinenFlow/Services/DailyLogSaveService.swift` | G | |
| `LinenFlow/Services/SharedWidgetStateManager.swift` | H | |
| `LinenFlow/Views/Flow/{Receiving,Review,Results,Floor}*.swift` | J | Wizard decision |
| `android/**` | — | **OUT OF SCOPE** — no agent claims |
| `LinenFlowUITests/**` | L | Independent |

---

## Recommended Parallel Dispatch (3 iOS agents — Android excluded)

For **remaining work** on the already-built Linen tab:

| Agent | Track | Tasks | Est. scope |
|-------|-------|-------|------------|
| **Agent 1** | I | Phase 11 — isCurrent wiring + remove duplicate stroke | Small, P0 |
| **Agent 2** | I | Phase 11 — VoiceOver on OneScreenLinenItemCard | Medium, P1 |
| **Agent 3** | J | Phase 12 — wizard orphan decision | Small, architecture |
| ~~**Agent 4**~~ | ~~K~~ | ~~Phase 13 — Android~~ | **Removed — Android OUT OF SCOPE** |

Agents 1 and 2 must **not** both edit `HomeView.swift` simultaneously. Agent 1 takes `HomeView` focus overlay removal; Agent 2 takes `OneScreenLinenItemCard.swift` only.

---

## Commit Strategy

- One commit per task (2–5 min granularity).
- Format: `feat(linen): wire isCurrent on focused linen card` / `a11y(linen): VoiceOver labels for distribution rows`.
- Run build before every commit.
- Update `AGENT_WORK_LOG.md` on track completion.

---

*Plan generated 2026-06-08. Codebase at detached HEAD — 283 tests, Linen tab core workflow complete, Phase 11–14 are active work.*
