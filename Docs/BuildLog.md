# HimmerFlow Build Log

> **Historical note:** Task entries below record the May 2026 build sequence. Early tasks reference `TowerSelectionView`, which was later removed — tower selection is now inline on `HomeView`. See **Architecture update — 2026-06-07** at the end of this file for the current flow.

## Task 1 — Fix Xcode project for iOS
Date: 2026-05-16
Files changed:
- `LinenFlow.xcodeproj/project.pbxproj`

Build command:
```
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

Simulator used: iPhone 17 Pro Max (iPhone 16 Pro not available on this machine; Xcode 26.5 ships iPhone 17 family by default).

Build result: ** BUILD SUCCEEDED **
Test command: (none — no test target yet; added in Task 5)
Test result: n/a

Errors found: None. Project already had `SDKROOT = iphoneos`, `productType = application`, and `TARGETED_DEVICE_FAMILY = "1,2"`. The macOS-only settings listed in the prompt were not present.

Fixes applied:
- Changed `IPHONEOS_DEPLOYMENT_TARGET = 26.5` → `17.0` in both project Debug and Release configs.
- Added `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` to both project Debug and Release configs.
- Added `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`, and `SUPPORTS_MACCATALYST = NO` to both target Debug and Release configs.
- Stashed pre-existing WIP in `LinenFlow/ContentView.swift` (`git stash@{0}`) so the rebuild starts from the initial template.

Improvements made: Target now compiles against `arm64-apple-ios17.0-simulator` confirmed in linker invocation.

Known issues:
- One harmless warning during `-showdestinations`: "Supported platforms for the buildables in the current scheme is empty." This is a known xcodebuild quirk during destination enumeration and does not affect builds.
- No unit-test target exists yet; will be added in Task 5.

Next task: Task 2 — App foundation and navigation shell.

## Task 2 — App foundation and navigation shell
Date: 2026-05-16
Files changed:
- `LinenFlow/App/HimmerFlowApp.swift` (moved from `LinenFlow/`, now launches `HomeView`)
- `LinenFlow/Views/HomeView.swift` (created)
- `LinenFlow/Views/Flow/{TowerSelectionView,ReceivingView,ReviewReceivedView,ResultsView,FloorDistributionView}.swift` (created)
- `LinenFlow/Views/Logs/LogsView.swift` (created)
- `LinenFlow/Views/Settings/SettingsView.swift` (created)
- `LinenFlow/Views/Components/PlaceholderScreen.swift` (created)
- Removed: `LinenFlow/ContentView.swift`
- Created empty folders: `Models/`, `Services/`, `ViewModels/`, `SeedData/`, `Utilities/`

Build command: same as Task 1
Build result: ** BUILD SUCCEEDED **
Test command: n/a
Test result: n/a

Errors found: First `Write` to the moved `HimmerFlowApp.swift` was rejected because the new path had not been read; resolved by reading then writing.

Fixes applied: Read the file at its new path before writing the new contents.

Improvements made:
- Single source of truth for navigation: `HomeRoute` enum + `navigationDestination(for:)`. Adding a new top-level screen is a one-line change.
- Dark mode forced at the app root (`.preferredColorScheme(.dark)`) so previews and runtime match the premium-dark design direction.
- Placeholder screens share a common `PlaceholderScreen` component so polish later only touches that file.

Known issues:
- HomeView and PlaceholderScreen use bespoke styling for now; Task 8 will replace them with reusable `PremiumCard` / `PrimaryActionButton` components.
- Empty folders (`Models/`, `Services/`, etc.) won't be tracked by git until they have files (added in upcoming tasks).

Next task: Task 3 — Add core models.

## Task 3 — Add core models
Date: 2026-05-16
Files changed:
- `LinenFlow/Models/Tower.swift` (created — @Model)
- `LinenFlow/Models/LinenItem.swift` (created — @Model)
- `LinenFlow/Models/CountMethod.swift` (created — enum)
- `LinenFlow/Models/CalculationStatus.swift` (created — enum)
- `LinenFlow/Models/ReceivingEntry.swift` (created — Codable struct)
- `LinenFlow/Models/CalculationSummary.swift` (created — Codable struct)
- `LinenFlow/Models/FloorDistributionRow.swift` (created — Codable struct)
- `LinenFlow/Models/DailyLog.swift` (created — @Model with snapshot Data fields)

Build command: same as Task 1
Build result: ** BUILD SUCCEEDED **
Test command: n/a (no test target yet)
Test result: n/a

Errors found: None.

Fixes applied: n/a.

Improvements made:
- `LinenItem.allowedTowerNames` stored as JSON `Data` with a computed `[String]` accessor — avoids iOS 17.0 quirks with stored primitive arrays in SwiftData while keeping the call-site API natural.
- `LinenItem.countMethod` stored as raw `String` with a computed enum accessor — same SwiftData-safety motivation; lets seed/migration logic work with strings.
- `DailyLog` stores `entriesSnapshot`, `summarySnapshot`, `distributionSnapshot` as encoded `Data` so logs are immutable against later settings changes (the locked rule from the build prompt). Snapshots are exposed as computed `[…]` arrays.
- `ReceivingEntry`/`CalculationSummary`/`FloorDistributionRow` are Codable structs so they round-trip cleanly through the snapshot Data fields and can also live in transient flow state without ModelContext.

Known issues:
- `ModelContainer` is not wired into the app yet — that lands in Task 4 (seed data).
- No snapshot round-trip tests yet — test target lands in Task 5; will add a DailyLog snapshot test then.

Next task: Task 4 — Add seed data.

## Task 4 — Add seed data
Date: 2026-05-16
Files changed:
- `LinenFlow/SeedData/DefaultData.swift` (created)
- `LinenFlow/SeedData/SeedService.swift` (created)
- `LinenFlow/App/HimmerFlowApp.swift` (wires `ModelContainer` for Tower/LinenItem/DailyLog and runs `SeedService.seedIfNeeded`)

Build command: same as Task 1
Build result: ** BUILD SUCCEEDED **
Test command: n/a (test target not yet added)
Test result: n/a

Errors found: None.

Fixes applied: n/a.

Improvements made:
- Idempotent seeding: each tower/item is only inserted if no row with the same `name` exists. Safe to re-run on every launch.
- `allowedTowerNames` reflects the locked tower rules from the prompt (Alii/Diamond for King + Double; Tapa/Rainbow for King + Queen). Items with empty `allowedTowerNames` are available to every tower.
- Identity colours pre-seeded from the brand palette (`#00AFC7` Lagoon aqua, `#D99A2B` GI gold, `#3F4E8C` GW indigo, `#6F7C85` Diamond slate, `#0E8F6D` Alii emerald) so accent-strip UI in Task 9 can pull straight from the model.

Known issues:
- Persistence + idempotency are not yet covered by automated tests — added together with the test target in Task 5.
- `LinenItem.piecesPerBin` is only meaningful for `fixedBin` items today (just Bath Towel). Validation lives in FlowViewModel (Task 7).

Next task: Task 5 — Safe arithmetic engine + tests.

## Cleanup audit — logging and widget polish
Date: 2026-05-25
Files changed:
- `LinenFlow/SeedData/SeedService.swift`
- `LinenFlow/Views/Logs/LogsView.swift`
- `LinenFlow/Views/Logs/LogDetailView.swift`
- `LinenFlow Widget/HimmerFlow_Widget.swift`
- `Docs/CriteriaChecklist.md`
- `Docs/FinalReport.md`

Build command:
```
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```
Build result: Failed before compilation in the sandbox because CoreSimulator and SwiftPM cache writes were not permitted.

Fallback validation: Xcode project build completed successfully through the local Xcode build tool.

Test command:
```
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```
Test result: Failed before test execution for the same sandbox/CoreSimulator/SwiftPM cache permissions.

Cleanup applied:
- Replaced production `print` calls in seed/log save failure paths with `AppLogger`.
- Kept WidgetKit snapshot/status logic unchanged while correcting widget presentation for sub-minute countdowns to show `<1m`.
- Updated stale protected-invariant checklist wording.

## Task 5 — Safe arithmetic engine + tests
Date: 2026-05-16
Files changed:
- `LinenFlow/Utilities/ArithmeticParser.swift` (created)
- `LinenFlow/Services/ArithmeticExpressionService.swift` (created)
- `LinenFlowTests/ArithmeticTests.swift` (created)
- `LinenFlow.xcodeproj/project.pbxproj` (added `HimmerFlowTests` unit-test target, target dependency, container item proxy, build configurations)

Build command:
```
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```
Build result: ** BUILD SUCCEEDED **

Test command:
```
xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
```
Test result: ** TEST SUCCEEDED ** (23 / 23 passed)

Errors found: None during build/test. The pbxproj edits required matching identifier patterns (24-char hex) for new objects (`AABBCCDDEEFF1122334400xx`) and consistent comment labels (`/* HimmerFlowTests */`, `/* PBXTargetDependency */`, etc.) to avoid Xcode rejecting the file.

Fixes applied: n/a.

Improvements made:
- Recursive-descent parser instead of `NSExpression`/`eval` — no language injection surface, easy to add operators later, and predictable error reporting via the `ArithmeticError` enum.
- Two-layer API: `evaluate(_:)` returns the raw `Double`; `evaluatePieces(_:)` adds non-negative + whole-number checks for the "received pieces" context. Lets non-pieces fields (e.g. par-count math) skip the stricter checks.
- Distinct error cases (`negativeNotAllowed`, `fractionalNotAllowed`, `divisionByZero`, `partial`, `mismatchedParens`, `invalidCharacter`, `empty`) — UI can pick a tailored message later (Task 10) instead of "invalid expression".
- 23 tests cover every required case (multiply aliases × 3, divide aliases × 2, +, -, mixed-precedence, parens, whitespace, letters, mixed letters, double-operator, /0, eval(), sqrt(), import, "245 bags", negative pieces, fractional pieces, empty, partial).

Known issues:
- One harmless build-time warning per build cycle: `appintentsmetadataprocessor … Metadata extraction skipped. No AppIntents.framework dependency found.` — emitted by Xcode 26 for any app that doesn't link AppIntents; can be silenced later if it becomes noisy.
- The test target uses XCTest. Could migrate to Swift Testing (`import Testing`) for terser assertions if desired.

Next task: Task 6 — Bundle library + calculator service + tests.

## Task 6 — Bundle library + calculator service + tests
Date: 2026-05-16
Files changed:
- `LinenFlow/Services/BundleLibrary.swift` (created)
- `LinenFlow/Services/LinenCalculatorService.swift` (created)
- `LinenFlowTests/CalculatorTests.swift` (created)

Build command: same as Task 5
Build result: ** BUILD SUCCEEDED **

Test command: same as Task 5
Test result: ** TEST SUCCEEDED ** (38 / 38 — all 23 arithmetic + 15 calculator tests)

Errors found: Initial `xcodebuild` invocation failed with "LinenFlow.xcodeproj does not exist" because the shell's working directory had been reset between commands. Resolved by passing the absolute project path on the next invocation.

Fixes applied: Use `-project <absolute path>` to keep xcodebuild calls cwd-independent.

Improvements made:
- `LinenCalculatorService` is a pure enum of `static` functions — no instance state, no SwiftUI imports, no view types referenced. Forces calculation logic to live here (the prompt's locked rule).
- Each function tolerates degenerate input by clamping with `max(0, …)` or guarding `floorCount > 0` — zero-floor and zero-received calls return safe defaults instead of trapping.
- `calculateSummary` is the one-stop function the view layer will call per item; the smaller functions stay exposed so tests pin every formula individually.
- `BundleLibrary.canonicalName(_:)` is case-insensitive and resolves both direct names and aliases, so the cart/label parser (Task 18) can feed user-typed names straight in.
- `BundleLibrary` is the source of truth for bundle constants. `LinenItem.bundleSize` mirrors it via the seed data; Settings (Task 16) will surface but disallow editing of the bundle size to preserve the lock.

Tests added (CalculatorTests):
- `test_bundleLibrary_protectedConstants` — pins every bundle size
- `test_bundleLibrary_aliasResolution` — pins Duvet/Pillowcase/Wash Cloth mappings
- `test_bathTowelTwoBinsInLagoon` — full pipeline from bins → pieces → summary
- `test_manualShortage`, `test_exactMatch`, `test_overage`
- `test_remainderDistribution` — verifies first-N-floors-get-base+1 rule
- `test_bundleConversion_everyLockedItem` — including Diamond/D-Head's 116→23+1, 89→17+4
- `test_giDistribution_32Floors`, `test_gwDistribution_31Floors`, `test_diamondDistribution_15Floors`, `test_aliiDistribution_14Floors`
- `test_zeroFloorCount_doesNotCrash`, `test_zeroReceivedPieces_doesNotCrash`
- `test_dailyLog_snapshotRoundTrip` — completes the Task 3 model coverage

Known issues: None.

Next task: Task 7 — FlowViewModel + tests.

## Task 7 — FlowViewModel + tests
Date: 2026-05-16
Files changed:
- `LinenFlow/ViewModels/FlowViewModel.swift` (created)
- `LinenFlowTests/FlowViewModelTests.swift` (created)

Build command: same as Task 5
Build result: ** BUILD SUCCEEDED **
Test command: same as Task 5
Test result: ** TEST SUCCEEDED ** (52 / 52 total — 23 arithmetic + 15 calculator + 14 flow)

Errors found: None.

Fixes applied: n/a.

Improvements made:
- `@Observable` + `@MainActor` on the ViewModel. View bindings update automatically; all calculation calls hop through the calculator service so views never see arithmetic code.
- `recalculate` groups receiving entries by canonical item name and sums pieces before converting to bundles. This is what makes the cart/label path (Task 18) "just work" — multiple rows for "Double Sheet" accumulate to a single canonical summary.
- `loadDiamondDHeadExample` already maps aliases (`Double Duvet` → `Double Cover`, `King Duvet / King Cover` → `King Cover`) via `BundleLibrary.canonicalName`, and the resulting summary matches the locked fixture exactly: 305 pcs, 60 bundles, 5 loose. Task 18 will add the raw-row preservation in the log.
- Validation surfaces specific guidance per entry (missing bin count, missing pieces, Double-in-non-Diamond-tower, loose pieces). Each warning is a discrete string so the UI can render them as a list.
- In-memory `ModelContainer` (`ModelConfiguration(isStoredInMemoryOnly: true)`) makes the tests fast and isolated from device state.

Known issues:
- Cart/label raw-row preservation in the saved log is deferred to Task 18 — currently the per-cart `ReceivingEntry` rows ARE preserved in `receivingEntries`, but the summary collapses them. Will revisit at Task 18.

Next task: Task 8 — Premium reusable UI components.

## Task 8 — Premium reusable UI components
Date: 2026-05-16
Files changed (all created):
- `Views/Components/AppBackground.swift`
- `Views/Components/PremiumCard.swift`
- `Views/Components/PrimaryActionButton.swift`
- `Views/Components/SecondaryActionButton.swift`
- `Views/Components/StatusBadge.swift`
- `Views/Components/MetricTile.swift`
- `Views/Components/PremiumNumberInput.swift`
- `Views/Components/PremiumExpressionInput.swift`
- `Views/Components/SectionHeader.swift`
- `Views/Components/EmptyStateView.swift`
- `Views/Components/FlowProgressHeader.swift`
- `Views/Components/TowerAccentStrip.swift`
- `Views/Components/WarningCard.swift`
- `Views/Components/StickyBottomActionBar.swift`

Build command: same as Task 5
Build result: ** BUILD SUCCEEDED **
Test command: same as Task 5
Test result: ** TEST SUCCEEDED ** (52 / 52 — no regressions)

Errors found: None.

Fixes applied: n/a.

Improvements made:
- `PremiumExpressionInput` is the integration point between `ArithmeticExpressionService` and the UI. The raw expression stays editable; evaluated pieces sync to a separate `@Binding<Int>` so view models always see the validated number. Each `ArithmeticError` case maps to a one-sentence user-facing message.
- `MetricTile` uses `.contentTransition(.numericText())` + `.snappy` so changing values animate fluidly, satisfying the "subtle numericText transitions" requirement listed in Task 19.
- `TowerAccentStrip` decodes the per-tower `identityColorHex` seeded in Task 4 via a `Color(hex:)` extension — accent colours flow from the model rather than being hard-coded per screen.
- `FlowProgressHeader` exposes its own `Step` enum so each flow screen specifies its position once, and the header keeps complete/current/upcoming styles consistent across screens.
- `StickyBottomActionBar` uses `.ultraThinMaterial` for the iOS-native sticky-action look without competing with the dark gradient background.

Known issues:
- Some components have no `#Preview` (build prompt says "Preview examples added if practical") — I prioritised getting Tasks 9–13 unblocked. Previews can be added during the Task 19 polish pass.
- The legacy `PlaceholderScreen.swift` from Task 2 still exists and is used by the unimplemented screens; it will be removed as each screen gets its real implementation (Tasks 9–16).

Next task: Task 9 — Home + Tower Selection screens.

## Task 9 — Home + Tower Selection screens
Date: 2026-05-17
Files changed:
- `LinenFlow/App/HimmerFlowApp.swift` (now creates `FlowViewModel` and injects via `.environment`)
- `LinenFlow/Views/HomeView.swift` (rewritten — premium dashboard, `NavigationPath`, `HomeRoute`/`FlowStep` destinations)
- `LinenFlow/Views/Flow/TowerSelectionView.swift` (rewritten — real tower cards, accent strips, FlowProgressHeader)
- `LinenFlow/Views/Flow/{ReceivingView, ReviewReceivedView, ResultsView, FloorDistributionView}.swift` (transitional placeholders with `path: Binding<NavigationPath>` so they navigate forward — full implementations in Tasks 10–13)

Build command: same as Task 5
Build result: ** BUILD SUCCEEDED **
Test command: same as Task 5
Test result: ** TEST SUCCEEDED ** (52 / 52)

Errors found: None.

Fixes applied: n/a.

Improvements made:
- `FlowViewModel` is created once at app launch in `HimmerFlowApp.init()` and shared via `.environment(viewModel)` — every flow screen reads it with `@Environment(FlowViewModel.self)`. No prop drilling.
- `NavigationPath` (heterogeneous) drives the stack so a single `NavigationStack` handles both `HomeRoute` and `FlowStep` destinations; pushing the next step is a one-liner.
- `DemoBootstrapView` is a transitional view that calls `viewModel.loadDemoDay()` then replaces itself in the stack with `ResultsView` — gives the user an immediate spinner instead of a frozen tap and a logically clean stack ("back" returns to Home, not to a loader).
- `TowerCard` pulls the tower's `identityColorHex` straight from the model — the brand-colour requirement from the build prompt is satisfied without per-screen lookup tables.

Known issues:
- Receiving, Review, Results, Floor Plan screens are still placeholders that just navigate forward; their real implementations are Tasks 10–13.
- The legacy `PlaceholderScreen.swift` (Task 2) is still used by no one and could be deleted in Task 19 polish.

Next task: Task 10 — Receiving screen.

## Task 10 — Receiving screen
Date: 2026-05-17
Files changed:
- `LinenFlow/Views/Flow/ReceivingView.swift` (rewritten)

Build command: same as Task 5
Build result: ** BUILD SUCCEEDED **
Test command: same as Task 5
Test result: ** TEST SUCCEEDED ** (52 / 52)

Errors found: None.

Improvements made:
- Items are filtered by the selected tower's `allowedTowerNames`, so e.g. King/Double sheets don't appear in Lagoon — fewer wrong-tower entries.
- Each item card has its own state. Bath Towel (`fixedBin`) gets `PremiumNumberInput`; everything else gets `PremiumExpressionInput` so users can type `60+60` or `245*2`.
- Live bundle conversion strip below every input (Pieces / Bundles / Loose / per-bundle) updates as the value changes.
- Tower header surfaces a running entries+pieces total so the user always sees the totals while typing.
- Sticky bottom "Review Received Pieces" disables until at least one entry exists.

Known issues:
- The expression input's "live evaluated" appears immediately, but only after a user types — pre-existing entries (when navigating back) re-populate the text but the green "= X pcs" hint won't render until the next keystroke. Minor; will polish in Task 19.
- No per-item notes UI yet (the data model and API support it). Will add in Task 19 if Receiving feels cramped without it.

Next task: Task 11 — Review received screen.

## Task 11 — Review received screen
Date: 2026-05-17
Files changed: `LinenFlow/Views/Flow/ReviewReceivedView.swift` (rewritten).
Build: ** BUILD SUCCEEDED ** · Tests: ** TEST SUCCEEDED ** (52/52)

Improvements made:
- Read-only summary so the user audits before locking in calculations. Edit button pops back to Receiving (`path.removeLast()`); Calculate Results pushes forward.
- Per-entry card surfaces the input shape (bins+per-bin, or manual pieces) plus the derived pieces / bundles / loose. The emphasised "Pieces" tile makes the converted total impossible to miss.
- Summary card at top totals item types, pieces, and bundles so the user sees the day at a glance.
- Validation warnings re-displayed here in case the user proceeded past them on Receiving.

Next task: Task 12 — Results screen.

## Task 12 — Results screen
Date: 2026-05-17
Files changed: `LinenFlow/Views/Flow/ResultsView.swift` (rewritten).
Build: ** BUILD SUCCEEDED ** · Tests: ** TEST SUCCEEDED ** (52/52)

Improvements made:
- Each item gets a card with `StatusBadge`, 6 `MetricTile`s in a 3×2 grid (Received / Bundles / Required / Difference / Per Floor / Practical), and a plain-English summary line ("23 per floor. First 7 floors get 24.")
- Accent strip + Difference tile tint by status: red for shortage, green for overage, blue for exact.
- Demo Day pill in the header when `viewModel.isDemoDay`.
- Save Daily Log inserts the `DailyLog` snapshot via `modelContext` and shows a checkmark banner with timestamp; haptic feedback fires on iOS via `UINotificationFeedbackGenerator`.
- Edit Received pops two stack entries (Results → Review → Receiving) so users can refine inputs without losing place.

Known issues:
- LogsView still placeholder — saved logs land in SwiftData but won't be visible until Task 15.
- Save errors render as text in the banner; a proper modal alert can land in Task 19 polish.

Next task: Task 13 — Floor distribution screen.

## Task 13 — Floor distribution screen
Date: 2026-05-17
Files changed: `LinenFlow/Views/Flow/FloorDistributionView.swift` (rewritten — adds `FloorRangeBuilder` + `FloorRange` types).
Build: ** BUILD SUCCEEDED ** · Tests: ** TEST SUCCEEDED ** (52/52)

Improvements made:
- `FloorRangeBuilder` collapses consecutive floors with identical suggested pieces into a single range row ("Floors 1–7: 24 pcs / Floors 8–21: 23 pcs"). The Lagoon Bath Towel demo example collapses to two ranges instead of 21 rows.
- The higher-value group (the one receiving the remainder bonus) gets a subtle blue `+1` capsule badge — easy to scan while walking the floors.
- Save Daily Log is available here as well as on Results, matching the prompt's "save at any time" intent.

Known issues:
- Test coverage for `FloorRangeBuilder` will land in Task 20.

Next task: Task 14 — Daily log saving (SwiftData) — already partially complete (insert + save wired in Results & Floor Plan). Task 14 will formalise it.

## Task 14 — Daily log saving (SwiftData)
Date: 2026-05-17
Files changed:
- `LinenFlow/Services/DailyLogSaveService.swift` (created)
- `LinenFlow/Views/Flow/ResultsView.swift` (refactored save flow to call the service)
- `LinenFlow/Views/Flow/FloorDistributionView.swift` (same)
- `LinenFlowTests/DailyLogSaveTests.swift` (created)

Build: ** BUILD SUCCEEDED **
Tests: ** TEST SUCCEEDED ** (57 / 57)

Improvements made:
- `DailyLogSaveService` centralises the three failure modes (`noTower`, `noEntries`, `invalidCalculations`) plus `persistFailure(message)`. Each returns a localized message via `errorDescription`, so the UI just prints what the service says.
- New `test_savedLog_snapshotIsImmuneToLaterSettingsChanges` flips `Bath Mat.parCount` to 999 after saving and asserts the saved log still shows `requiredPieces = 63`. This pins the build prompt's "snapshots, not references" rule.
- 4 other save tests cover the failure paths and fetch round-trip.

Known issues:
- LogsView (Task 15) still placeholder — saved logs exist in SwiftData but aren't visible yet.

Next task: Task 15 — Daily logs history screen.

## Task 15 — Daily logs history
Date: 2026-05-17
Files changed:
- `LinenFlow/Views/Logs/LogsView.swift` (rewritten)
- `LinenFlow/Views/Logs/LogDetailView.swift` (created)

Build: ** BUILD SUCCEEDED ** · Tests: ** TEST SUCCEEDED ** (57/57)

Improvements made:
- `@Query(sort: \DailyLog.createdAt, order: .reverse)` auto-streams logs into the list — no manual fetch in the view.
- Horizontal filter bar: All, Lagoon, GI, GW, Diamond, Alii, Shortages. Filters are an enum so adding more is trivial.
- Each log card pulls its tower brand colour from `DefaultData.towers` so the strip matches the rest of the app.
- Status pill summary on each card (count of Short/Enough/Exact) gives a one-glance health check.
- LogDetailView is receipt-style: header card, entries, summaries with `StatusBadge`, distribution ranges (re-uses `FloorRangeBuilder`), notes.
- Long-press a card for context-menu delete; LogDetailView toolbar has Delete in a `Menu`.

Next task: Task 16 — Settings screen.

## Task 16 — Settings
Date: 2026-05-17
Files changed: `LinenFlow/Views/Settings/SettingsView.swift` (rewritten).
Build: ** BUILD SUCCEEDED ** · Tests: ** TEST SUCCEEDED ** (57/57)

Improvements made:
- Tower cards: `Stepper` for floor count (1–80) and a `Toggle` for active state. Brand colour accent. `@Bindable` writes directly to the SwiftData model; save fires on change.
- Linen item cards: par editable via `Stepper`, count method shown as pill, bundle size displayed with a "(locked)" label, pieces/bin shown only for fixed-bin items.
- Special-rules card surfaces the Double Sheet/Cover constraint and the bundle-size lock in plain text.
- Data card explicitly tells the user that settings changes do not affect saved logs — reinforces the snapshot invariant.

Known issues:
- Bundle size is currently shown but cannot be edited because there's no editing UI; the displayed value is technically still writable via SwiftData if I added a binding. The "(locked)" affordance and missing editor make this safe in practice; an explicit guard could land in Task 19.
- No reset-all-defaults / delete-all-logs buttons — the prompt cautioned against dangerous data buttons without confirmation, so deferred.

Next task: Task 17 — Demo Day flow.

## Task 17 — Full Demo Day flow
Date: 2026-05-17
Files changed: `LinenFlowTests/DemoDayFlowTests.swift` (created).
Build: ** BUILD SUCCEEDED ** · Tests: ** TEST SUCCEEDED ** (68 / 68)

Notes:
- Functional Demo Day was already in place from Tasks 7 (viewModel.loadDemoDay), 9 (DemoBootstrapView routing), 12 (Demo Day badge in ResultsView), 14 (save path supports demo as a real log). Task 17 was about pinning every required assertion in tests.
- Added 11 tests covering per-item base/remainder for all 5 demo items, the full 21-floor distribution sequence for Bath Towel and Bath Mat, the `isDemoDay` flag lifecycle, and a "demo does not mutate LinenItem" test pinning the prompt's settings-independence rule.
- The `test_bathTowelRanges_collapseToTwoRanges` also covers `FloorRangeBuilder` end-to-end through the Demo Day pipeline.

Next task: Task 18 — Diamond / D-Head ALSCO example flow.

## Task 18 — Diamond / D-Head ALSCO example
Date: 2026-05-17
Files changed:
- `LinenFlow/ViewModels/FlowViewModel.swift` (adds `bundleFloorDistributions`, `prefersBundleDelivery`, log uses bundle distribution for Diamond/Alii)
- `LinenFlow/Views/Flow/FloorDistributionView.swift` (renders bundles when `prefersBundleDelivery`, helper text adapts; `FloorRange.suggestedValue` replaces `suggestedPieces`, `FloorRangeBuilder.build(_, unitIsBundles:)` parameter added)
- `LinenFlow/Views/Logs/LogDetailView.swift` (auto-detects bundle snapshots in saved logs)
- `LinenFlow/Views/HomeView.swift` (adds "Diamond Cart Example" button + `DiamondBootstrapView`)
- `LinenFlowTests/DemoDayFlowTests.swift` (updated to new `suggestedValue` field)
- `LinenFlowTests/DiamondExampleTests.swift` (created — 12 tests)

Build: ** BUILD SUCCEEDED **
Tests: ** TEST SUCCEEDED ** (80 / 80)

Errors found: Renaming `FloorRange.suggestedPieces` to `suggestedValue` broke `DemoDayFlowTests`. Caught immediately by the test suite; fixed by updating the two references.

Fixes applied: Updated DemoDayFlowTests to read `suggestedValue`.

Improvements made:
- Bundle-first display is now a first-class concept: `FlowViewModel.bundleFloorDistributions` is always populated, `prefersBundleDelivery` flips the UI for Diamond and Alii towers.
- `FloorRange.suggestedValue` + `FloorRangeGroup.unitIsBundles` lets one builder and one card render both modes; the card chooses "1 bundle" / "N bundles" or "N pcs" automatically.
- `LogDetailView` infers whether a saved snapshot is bundle-mode (any row has `suggestedBundles > 0` and `suggestedPieces == 0`) and renders accordingly — old pieces-mode logs keep working.
- New `Diamond Cart Example` button on home, with `DiamondBootstrapView` mirroring `DemoBootstrapView`'s pattern.
- 12 Diamond tests pin: raw cart preservation (6 entries, Cart 1801/7045/1406 in notes), combined canonical totals (305/60/5), per-item bundle conversion, bundle-first floor distribution (King Sheet: floors 1–10 get 1, 11–15 get 0; Double Cover: 1–8 get 2, 9–15 get 1), saved-log uses bundle snapshot.

Known issues:
- Loose pieces are tracked in summaries but the Floor Plan card doesn't surface them. Loose pcs DO appear on Results (the `+N loose` secondary on the Bundles tile). Could add a footnote line on Floor Plan in Task 19.

Next task: Task 19 — Polish UI + animations.

## Task 19 — Polish UI + animations
Date: 2026-05-17
Files changed:
- Deleted: `LinenFlow/Views/Components/PlaceholderScreen.swift` (legacy Task-2 stub, no longer referenced)
- `LinenFlow/Views/Flow/FloorDistributionView.swift` (loose-pieces footer for bundle mode, range card transition)
- `LinenFlow/Views/HomeView.swift` (subtle entrance animation on actions stack)
- `LinenFlow/Views/Flow/ResultsView.swift` (snappy card transitions on result cards)

Build: ** BUILD SUCCEEDED ** · Tests: ** TEST SUCCEEDED ** (80/80 — no regressions)

Improvements made:
- Loose-pieces footer card on Floor Plan when in bundle mode — surfaces the Diamond example's 5 loose pieces (Double Cover 1 + Double Sheet 4) below the floor ranges, with an orange accent so it's distinguishable from delivery rows.
- `.transition(.opacity.combined(with: .move/.scale))` + `.animation(.snappy, value:)` on result and floor-plan cards — they slide in subtly when calculations populate rather than appearing instantly.
- Removed unused `PlaceholderScreen` component.

Deliberately deferred:
- A "pull to refresh" action — overkill for an inputs-driven flow.
- Per-item notes UI on Receiving — the model and API support it; data flow tests pass; UI surface area is moot since the only consumer (Daily Log notes) is editable elsewhere.

Next task: Task 20 — Final tests + manual validation.

## Task 20 — Final tests + validation
Date: 2026-05-17
Build: ** BUILD SUCCEEDED **
Tests: ** TEST SUCCEEDED ** (80 / 80)

### Required test coverage audit

| # | Required test | Covered by |
|---|---------------|------------|
| 1 | Bath Towel fixed-bin (2 bins × 245 = 490) | `CalculatorTests.test_bathTowelTwoBinsInLagoon` |
| 2 | Lagoon Bath Towel full calc (req 294, diff +196, base 23, remainder 7, floors 1–7 get 24, 8–21 get 23) | `CalculatorTests.test_bathTowelTwoBinsInLagoon` + `DemoDayFlowTests.test_bathTowel_distribution_first7Floors24_rest23` |
| 3 | Bath Mat shortage (60 received, par 3, 21 floors → shortage 3) | `CalculatorTests.test_manualShortage` + `DemoDayFlowTests.test_bathMat_base2_remainder18` |
| 4 | Exact match | `CalculatorTests.test_exactMatch` |
| 5 | GI 32 floors (received 245, base 7, remainder 21) | `CalculatorTests.test_giDistribution_32Floors` |
| 6 | GW 31 floors (received 245, base 7, remainder 28) | `CalculatorTests.test_gwDistribution_31Floors` |
| 7 | Diamond 15 floors / 60 bundles (4 per floor) | `CalculatorTests.test_diamondDistribution_15Floors` + `DiamondExampleTests.test_kingSheet_bundleDistribution_*` |
| 8 | Zero received does not crash | `CalculatorTests.test_zeroReceivedPieces_doesNotCrash` |
| 9 | Zero floor count does not crash | `CalculatorTests.test_zeroFloorCount_doesNotCrash` |
| 10 | Demo Day (Lagoon, 21 floors, 5 entries, expected diffs) | `FlowViewModelTests.test_loadDemoDay_*` + `DemoDayFlowTests.*` |
| 11 | Diamond D-Head example (305 / 60 / 5; per-item bundle conversions) | `DiamondExampleTests.*` |
| 12 | Arithmetic (all 23 cases) | `ArithmeticTests.test_01_*` … `test_23_*` |

All required tests pass.

### Manual app-flow checklist
This is the smoke path to walk through in Simulator (or on device) before shipping. Each step is verifiable by hand because there is no UI test target yet.

- [ ] Launch app — home renders with date hero card and 5 buttons (Go Linen Flow, Daily Logs, Settings, Demo Day · Lagoon, Diamond Cart Example).
- [ ] Tap **Go Linen Flow** → Tower Selection shows Alii, Diamond, GI, GW, Lagoon with brand-coloured accent strips and `N floors · Own supply only`.
- [ ] Select **Lagoon** → Receiving lists Bath Towel (Fixed Bin badge, "× 245 pcs each") plus Bath Mat, Hand Towel, Washcloth, Pillow Case, King/Queen Sheet/Cover where allowed.
- [ ] Enter Bath Towel `2` bins → live strip shows `490 pcs / 98 bundles / 0 loose`.
- [ ] Enter Bath Mat `60` (or `30+30`) → live strip shows `60 / 6 / 0`.
- [ ] Tap **Review Received Pieces** → both entries listed with `Pieces` emphasised; bottom shows Edit + Calculate Results.
- [ ] Tap **Calculate Results** → Results shows two cards. Bath Towel = `Enough +196`, Bath Mat = `Shortage`. Plain-English line under Bath Towel reads "23 per floor. First 7 floors get 24."
- [ ] Tap **Save Daily Log** → green check banner, haptic on device.
- [ ] Tap **View Floor Plan** → Lagoon collapses to "Floors 1–7: 24 pcs" + "Floors 8–21: 23 pcs" for Bath Towel; `+1` capsule on the higher row.
- [ ] Pop back to home and tap **Daily Logs** → the saved Lagoon log appears at the top with two status pills.
- [ ] Tap the log → LogDetailView shows entries, summaries with status badges, distribution ranges, and "saved at HH:MM".
- [ ] Open **Settings** → 5 towers and 11 linen items. Edit Lagoon's floor count via Stepper; toggle a tower's Active state. Edit Bath Mat's par via Stepper.
- [ ] Back to **Daily Logs** → open the previously saved Lagoon log. Its required pieces and distribution are unchanged (snapshot immunity).
- [ ] Home → **Demo Day · Lagoon** → spinner briefly, then Results with `Demo Day` pill and 5 result cards.
- [ ] Home → **Diamond Cart Example** → Results shows 4 cards (Double Cover/Sheet, King Cover/Sheet) and Diamond tower header. Floor Plan reads "1 bundle" / "0 bundles" with a Loose pieces footer card listing 1 Double Cover + 4 Double Sheet.
- [ ] In Daily Logs, long-press a log → Delete; the row disappears.

### Final verification

- Build: `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build` → ** BUILD SUCCEEDED **
- Test: same command with `test` → ** TEST SUCCEEDED **, 80 of 80 cases passing.

Next task: Task 21 — already running in parallel; each task has been committed as it landed.

---

## Architecture update — 2026-06-07

Post-build simplification aligned docs and navigation with the current HimmerFlow app:

### Removed views (no longer in codebase)

- **`TowerSelectionView`** — tower picking moved into an inline expandable picker on `HomeView` (Linen tab). No dedicated tower-selection navigation destination.
- **`FloorTrackerView`** — floor tracking consolidated into `ShiftCommandCenterView` and related shift UI.
- **`SmartShiftAlarmPlannerView`** — alarm/commute planning UI lives in `WorkSchedule/` cards driven by `SmartShiftAlarmPlannerViewModel` on the Shift tab.

### Current Linen-tab flow

1. **`HomeView`** — single screen with inline tower picker, item selection, and `OneScreenLinenItemCard` grid.
2. **Wizard screens** — `ReceivingView`, `ReviewReceivedView`, `ResultsView`, `FloorDistributionView`, and `RebalanceShortFloorsView` remain reachable via `FlowStep` `navigationDestination` on `HomeView`'s `NavigationStack`.
3. **`FlowProgressHeader`** — four steps only: `receive`, `review`, `results`, `floorPlan` (no `.tower` step).

### Doc refresh scope

- `plan.md`, `SettingsManagerManualQA.md`, `Docs/FinalReport.md`, and this file updated to remove stale view references and reflect the one-screen `HomeView` architecture.















