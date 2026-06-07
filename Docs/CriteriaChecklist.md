# HimmerFlow Criteria Checklist

Legend: ✅ done · 🟡 in progress · ⬜ not started · 🧪 tests pass · 🛠 build passes · 👁 manually verified

| # | Task | Status | Build | Tests | Manual |
|---|------|--------|-------|-------|--------|
| 1 | Fix Xcode project for iOS | ✅ | 🛠 | n/a | 👁 (xcodebuild) |
| 2 | App foundation and navigation shell | ✅ | 🛠 | n/a | 👁 (build) |
| 3 | Core models | ✅ | 🛠 | n/a | 👁 (build) |
| 4 | Seed data | ✅ | 🛠 | n/a | 👁 (build) |
| 5 | Safe arithmetic engine + tests | ✅ | 🛠 | 🧪 26/26 | 👁 |
| 6 | Bundle library + calculator service + tests | ✅ | 🛠 | 🧪 45/45 | 👁 |
| 7 | FlowViewModel + tests | ✅ | 🛠 | 🧪 103/103 | 👁 |
| 8 | Premium reusable UI components | ✅ | 🛠 | 🧪 103/103 | 👁 |
| 9 | Home + Tower Selection screens | ✅ | 🛠 | 🧪 103/103 | 👁 |
| 10 | Receiving screen | ✅ | 🛠 | 🧪 103/103 | 👁 |
| 11 | Review received screen | ✅ | 🛠 | 🧪 103/103 | 👁 |
| 12 | Results screen | ✅ | 🛠 | 🧪 103/103 | 👁 |
| 13 | Floor distribution screen | ✅ | 🛠 | 🧪 103/103 | 👁 |
| 14 | Daily log saving (SwiftData) | ✅ | 🛠 | 🧪 114/114 | 👁 |
| 15 | Daily logs history | ✅ | 🛠 | 🧪 114/114 | 👁 |
| 16 | Settings | ✅ | 🛠 | 🧪 114/114 | 👁 |
| 17 | Demo Day flow | ✅ | 🛠 | 🧪 125/125 | 👁 |
| 18 | Diamond/D-Head ALSCO example | ✅ | 🛠 | 🧪 137/137 | 👁 |
| 19 | Polish UI + animations | ✅ | 🛠 | 🧪 137/137 | 👁 |
| 20 | Final tests + validation | ✅ | 🛠 | 🧪 283/283 | 📋 manual checklist in BuildLog |
| 21 | Commit after each passing task | ✅ | n/a | n/a | 👁 (git log) |

> **Note (2026-06-07):** Test counts in the table above reflect cumulative growth through the initial 21-task build, then the current **283 active cases** at project end-state. Counts verified by `grep -c "func test" LinenFlowTests/*.swift`.

## Post-build extensions (current state)

| Feature | Status | Notes |
|---------|--------|-------|
| 5-tab app shell (Linen / Shift / Insights / Logs / Settings) | ✅ | `AppRootView.swift` |
| One-screen interactive linen cards | ✅ | `OneScreenLinenItemCard` on Linen tab |
| Shift tab + work schedule | ✅ | `ShiftTabView`, `Views/WorkSchedule/*`, `WorkdayPlannerService` |
| Widget extension + Live Activities | ✅ | `LinenFlow Widget/`, App Group sync via `SharedWidgetStateManager` |
| Insights tab | ✅ | `InsightsView` + `DailyReportService` |
| Floor sensing / tracking (mock + real providers) | ✅ | `FloorTrackingSessionViewModel`, movement services |
| CSV export + property sharing (QR) | ✅ | `CSVExportService`, `PropertySharingService`, `QRScannerView` |
| Android Compose app | ✅ (separate repo folder) | `android/` — independent from iOS target |
| LogFilterBuilder | ⬜ | Test stub only (`LogFilterBuilderTests.swift`) |
| TowerConfigService | ⬜ | Test stub only (`TowerConfigServiceTests.swift`) |

## Current test coverage

| Suite | Cases |
|-------|-------|
| FlowViewModelTests | 58 |
| AlgorithmTests | 39 |
| ArithmeticTests | 26 |
| ShiftPlannerTests | 25 |
| CalculatorTests | 19 |
| TowerOperationalPolicyTests | 18 |
| TowerFloorRangeTests | 12 |
| OperationalPlanningTests | 12 |
| DiamondExampleTests | 12 |
| DailyLogSaveTests | 11 |
| DemoDayFlowTests | 11 |
| OperationalShiftStateEngineTests | 11 |
| DeliverySessionTests | 8 |
| FloorRangeBuilderTests | 8 |
| FloorRebalanceServiceTests | 7 |
| ShiftSettingsTests | 4 |
| DailyReportServiceTests | 2 |
| **Total (17 active files)** | **283** |

Deployment target: **iOS 26.0** · App Swift files: **151** · Test Swift files: **19** (17 active + 2 stubs)

## Protected invariants

- Bundle constants (Bath Towel 5, Bath Mat 10, Hand Towel 20, Washcloth 50, Pillow Case 50, all sheets/covers 5) — implemented and protected by service/tests.
- Tower defaults (Lagoon 21, GI 32, GW 31, Diamond 15, Alii 14) — implemented in seed data.
- Calculation logic must live in services, not views — enforced by service/view-model boundaries and `Services/Algorithms/`.
- Daily logs must store snapshots, not references — implemented with encoded snapshot fields.
- Widget/Live Activity state must sync through App Group, not direct SwiftData access from the extension.
