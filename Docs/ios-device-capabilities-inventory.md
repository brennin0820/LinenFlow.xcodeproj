# HimmerFlow / LinenFlow — iOS Device Capabilities Inventory

> Generated: 2026-06-07  
> Codebase: `LinenFlow/` (HimmerFlow scheme, iOS 26+)

This document maps **what the app already uses**, **what is partially built**, and **what iPhone hardware/APIs remain available** for future linen-delivery and shift-planning features.

---

## App tabs & surfaces (current)

| Tab | Entry | Primary features |
|-----|-------|------------------|
| **Linen** | `Views/HomeView.swift` | Tower picker, one-screen linen item cards, inline calculations, floor distribution, save daily logs, delivery command center (`ShiftCommandCenterView`), property map preview |
| **Shift** | `Views/Tabs/ShiftTabView.swift` → `DashboardView` | Shift timeline dashboard, patterns, durations, planner settings, Live Activity–driven shift phases, location onboarding |
| **Insights** | `Views/Insights/InsightsView.swift` | Charts from saved logs, tower filter, supply recommendations via `ShiftIntelligenceService` |
| **Logs** | `Views/Tabs/LogsTabView.swift` → `LogsView` | Historical daily logs, export |
| **Settings** | `Views/Tabs/SettingsTabView.swift` → `SettingsView` | Theme, property map, QR scanner, monitoring tier, alarms, tower calibration |
| **Widget extension** | `LinenFlow Widget/` | Home Screen + Lock Screen widgets, delivery command board, App Intents (`CompleteCurrentFloorIntent`) |
| **Live Activities** | `LiveActivityService`, widget extension | Shift timeline on Lock Screen / Dynamic Island |

---

## Already integrated

### Barometer / relative altitude (`CMAltimeter`)
- **Files:** `Services/FloorSensingService.swift`, `Services/FloorSensingEstimator.swift`, `Models/FloorSensingState.swift`, `Views/Components/FloorDetectionCard.swift`, `ViewModels/FlowViewModel.swift`, `Views/Flow/ShiftCommandCenterView.swift`, `Views/Flow/FloorChecklistView.swift`
- **Use:** Estimates current hotel floor during active delivery; user can correct floor; highlights checklist row.
- **Permissions:** No dedicated Info.plist key (barometer is not gated by user prompt on iPhone).
- **Battery:** Low–moderate while delivery session active; stopped when leaving command center.
- **Simulator:** Gracefully reports unavailable.

### GPS / Core Location (`CLLocationManager`)
- **Files:** `Services/LocationService.swift`, `Views/Location/LocationPickerView.swift`, `Core/ShiftOrchestrator.swift`, `App/HimmerFlowApp.swift`, `App/AppDelegate.swift`
- **Use:** One-shot location for home/work pins; geofence enter/exit; significant location changes for shift reconciliation.
- **Permissions:** `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` (`LinenFlow/Info.plist`, `project.pbxproj`)
- **Background:** `UIBackgroundModes`: `location`, `fetch`
- **Battery:** Always + geofencing = **moderate–high**; significant-change monitoring = **low–moderate**

### Geofencing (`CLCircularRegion`)
- **Files:** `LocationService.swift`, `ReconciliationEngine.swift`, `ShiftOrchestrator.swift`, `Views/Settings/MonitoringTierPickerView.swift`
- **Use:** Detect leaving home / arriving at work → reschedule notifications & Live Activity phases.
- **Requires:** Precise location + When In Use (foreground) or Always (background delivery).

### Significant location changes
- **Files:** `LocationService.startMonitoringSignificantLocationChanges()`, wired in `HimmerFlowApp`
- **Use:** Commute / coarse movement reconciliation without continuous GPS.
- **Battery:** **Low** (cell-tower/Wi‑Fi assisted, not continuous GPS).

### Local notifications (`UserNotifications`)
- **Files:** `Services/NotificationService.swift`, `ShiftNotificationService.swift`, `ShiftAlarmNotificationService.swift`, `LeavingChecklistNotificationService.swift`, `NotificationManager.swift`
- **Use:** Shift alarms, leaving checklist, ack/snooze actions, reconciliation scheduling.
- **Permissions:** Runtime prompt on first schedule; categories registered in `NotificationService.registerCategories()`.
- **Battery:** **Negligible** (system-managed).

### Live Activities (`ActivityKit`)
- **Files:** `Services/LiveActivityService.swift`, `LiveActivity/ShiftActivityAttributes.swift`, `LinenFlow Widget/ShiftActivityWidget.swift`
- **Use:** Shift phase timeline on Lock Screen / Dynamic Island.
- **Plist:** `INFOPLIST_KEY_NSSupportsLiveActivities = YES`
- **Battery:** **Low** (OS-managed updates).

### WidgetKit + App Intents
- **Files:** `LinenFlow Widget/LinenFlow_Widget.swift`, `LinenFlow Widget/AppIntent.swift`, `LinenFlowWidgets/*`, `Services/SharedWidgetStateManager.swift`
- **Use:** Delivery progress widgets, floor-complete intent, deep links (`himmerflow://`).
- **App Group:** `group.com.himmerflow.shared` (`LinenFlow.entitlements`, widget entitlements)
- **Battery:** **Negligible** (timeline refresh every 2–15 min).

### MapKit
- **Files:** `Views/Location/LocationPickerView.swift`, `Views/Components/PropertySceneMapView.swift`, `Utilities/HiltonPropertyMap.swift`
- **Use:** Pick home/work, property tower map preview.
- **Permissions:** None beyond location when centering on user.

### Wi‑Fi path monitoring (`Network` / `NWPathMonitor`)
- **Files:** `Services/WiFiLeaveDetectionService.swift`
- **Use:** Foreground-only hint when Wi‑Fi drops (possible leave-home); **not** reliable background detection.
- **Battery:** **Low** while monitoring in foreground.

### Haptics (`UIImpactFeedbackGenerator`)
- **Files:** `KeyboardPinnedEditorShell.swift`, `TodayShiftPlanCard.swift`, legacy delivery content
- **Use:** Light/medium feedback on commit and shift actions.
- **Battery:** Negligible.

### Camera / AVFoundation (QR)
- **Files:** `Views/Settings/QRScannerView.swift`
- **Use:** Scan property share codes.
- **Permissions:** **Missing from Info.plist** — add `NSCameraUsageDescription` before App Store or first camera use will crash.
- **Battery:** Low (only while scanner open).

### SwiftData + App Group UserDefaults
- **Files:** `App/HimmerFlowApp.swift`, `SharedWidgetStateManager.swift`, models under `Models/`
- **Use:** Local persistence; widget/Live Activity shared state.

### URL scheme / deep links
- **Files:** `LinenFlow/Info.plist`, `LinenFlowURLTypes.plist`, `WidgetDeepLinkRouter`
- **Scheme:** `himmerflow://`

---

## Partially built (service exists, UI incomplete or stub)

### Phone movement sensing (`PhoneMovementProvider`)
- **Files:** `Services/PhoneMovementProvider.swift`, `MovementSensingCoordinator`
- **Status:** Stub — returns stationary/low confidence; comments document future `CMPedometer`, `CMMotionActivityManager`, barometer fusion.
- **Could enable:** Auto-detect walking between floors, dwell time on floor, “worked floor” vs “landed floor”.
- **Permissions (future):** `NSMotionUsageDescription` if using Core Motion activity API.
- **Battery:** Moderate if always-on during delivery.

### Apple Watch movement (`WatchMovementProvider`)
- **Files:** `Services/WatchMovementProvider.swift`
- **Status:** Stub — no watchOS target, no `WatchConnectivity`.
- **Could enable:** Wrist step count, workout session during delivery, cross-check with barometer.
- **Battery:** Watch moderate; phone low (BT sync).

### Floor tracking session (mocks)
- **Files:** `ViewModels/FloorTrackingSessionViewModel.swift`, mock managers
- **Status:** Instantiated in `HimmerFlowApp` but **not wired to any view**; uses `MockFloorTrackingManager` / `MockFootstepTrackingManager`.
- **Could enable:** Analytics overlay, debug floor timeline, future fusion with real sensors.

### Floor height calibration
- **Files:** `Services/FloorHeightCalibrationService.swift`, `TowerCalibrationService.swift`
- **Status:** Models/services exist; tied to tower settings; real-device calibration flow partial.

### Delivery Live Activity (linen route)
- **Files:** `LinenFlowWidgets/DeliveryLiveActivity.swift`, `Models/DeliveryLiveActivityAttributes.swift`, `LiveActivityManager.swift`
- **Status:** Code present; primary Live Activity path is **shift timeline** (`ShiftActivityAttributes`). Delivery-specific LA may be secondary/legacy.

---

## Available on iPhone but unused (opportunity list)

| Capability | API | HimmerFlow use case | Permission key | Battery impact |
|------------|-----|---------------------|----------------|----------------|
| **Accelerometer / gyro** | `CMMotionManager` device motion | Detect elevator vs stairs, shake-to-correct floor | `NSMotionUsageDescription` | Moderate during session |
| **Magnetometer** | `CMMotionManager` | Heading / map orientation in property map | Usually none | Low |
| **Pedometer** | `CMPedometer` | Steps per floor, confirm “worked floor” | `NSMotionUsageDescription` | Moderate |
| **Motion activity** | `CMMotionActivityManager` | Walking vs stationary vs automotive (commute) | `NSMotionUsageDescription` | Low–moderate |
| **Bluetooth LE** | `CoreBluetooth` | Beacon-based floor or laundry-room proximity | `NSBluetoothAlwaysUsageDescription` | Moderate if scanning |
| **NFC** | `CoreNFC` | Tap tower/floor tags for instant floor confirm | NFCReaderUsageDescription | Low (on tap) |
| **HealthKit steps** | `HKHealthStore` | Cross-check steps (user opt-in) | Health share in Health app | Low |
| **Siri / Shortcuts** | App Intents (partial) | “Start delivery”, “Log received count” | None extra | Negligible |
| **Focus filters** | `FocusStatus` | Suppress non-shift notifications during delivery | None | Negligible |
| **Background fetch** | `UIBackgroundModes: fetch` | Declared but minimal custom BG fetch logic | — | Low |
| **Push (remote)** | APNs | Server-driven shift updates (not implemented) | Push capability | Low |
| **UWB / Nearby Interaction** | `NearbyInteraction` | Precise indoor (future, niche) | — | High |

---

## Top 10 recommended next integrations (impact × feasibility)

1. **Barometer floor detection (done)** — already in Shift Command Center; tune on physical device.
2. **CMPedometer + motion activity** — fuse with barometer in `PhoneMovementProvider` for walked-floor confirmation.
3. **Geofence + significant location (done)** — ensure Always permission UX in onboarding.
4. **Live Activities for shift (done)** — extend to delivery countdown if desired.
5. **Widget floor-complete intent (done)** — expand App Shortcuts phrases.
6. **NFC floor tags** — tap to snap `correctFloor` when barometer drifts.
7. **Camera permission plist** — required fix for QR scanner production use.
8. **Apple Watch companion** — steps + haptic “floor complete” on wrist.
9. **Bluetooth beacons** — elevator lobby / linen room proximity (hotel IT dependent).
10. **Focus mode integration** — quiet non-essential alerts during active delivery session.

---

## Permission checklist (Info.plist / entitlements)

| Key / entitlement | Present? | Notes |
|-------------------|----------|-------|
| `NSLocationWhenInUseUsageDescription` | ✅ | |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | ✅ | |
| `UIBackgroundModes: location, fetch` | ✅ | |
| `NSSupportsLiveActivities` | ✅ | build setting |
| `com.apple.security.application-groups` | ✅ | `group.com.himmerflow.shared` |
| `NSCameraUsageDescription` | ❌ | Needed for `QRScannerView` |
| `NSMotionUsageDescription` | ❌ | Needed for pedometer/activity APIs |
| `NSBluetoothAlwaysUsageDescription` | ❌ | If BLE added |
| Push Notifications entitlement | ❌ | Not used |

---

## Testing notes

- **Simulator:** Barometer unavailable; location can be simulated; Live Activities supported on recent simulators.
- **Physical iPhone:** Required for barometer calibration, geofence background behavior, haptics, and App Store–realistic permission flows.
- **Unit tests:** `LinenFlowTests/FloorSensingEstimatorTests.swift`, `GeofenceHandlingTests.swift`, `NotificationSchedulingTests.swift`, `ReconciliationTests.swift` cover core logic without hardware.

---

## Related architecture files

- Shift location pipeline: `Core/ShiftOrchestrator.swift`, `Core/ReconciliationEngine.swift`, `Core/TimelineComputation.swift`
- Delivery flow: `ViewModels/FlowViewModel.swift`, `Views/Flow/ShiftCommandCenterView.swift`
- Widget state: `Services/SharedWidgetStateManager.swift`
