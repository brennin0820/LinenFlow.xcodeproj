# HimmerFlow — iOS Device Capabilities Inventory

> **Purpose:** Single reference for sensors, system integrations, and iPhone hardware features used (or available) in HimmerFlow / LinenFlow.
>
> **Audience:** iOS engineers, QA, and parallel agents wiring delivery / shift features.
>
> **Snapshot date:** 2026-06-07 — compiled from canonical codebase paths documented in the master plan, HimmerFlow WS6 integration notes, and active floor-detection work. Re-verify `Info.plist` keys on a full checkout before release.
>
> **Related:** `docs/superpowers/plans/2026-06-08-linen-tab-master-plan.md`, `AGENT_WORK_LOG.md`

---

## App surfaces (where capabilities appear)

| Surface | Tab / extension | Primary files | Device hooks |
|---------|-----------------|---------------|----------------|
| **Linen** | Tab 0 (`HomeView`) | `LinenFlow/Views/HomeView.swift`, `OneScreenLinenItemCard.swift` | Haptics, keyboard, widget pin, deep links |
| **Shift** | Shift planner tab | `ShiftTabView`, `ShiftOrchestrator.swift`, `Core/TimelineComputation.swift` | GPS, geofences, notifications, Live Activity, MapKit |
| **Logs** | Logs tab | `DailyLog` models, Logs views | SwiftData only |
| **Settings** | Settings | Tower/item editors, `LocationPickerView.swift` | MapKit, SwiftData |
| **Insights** | Reports | `DailyReportService.swift` | SwiftData read |
| **Delivery** | Bottom chrome / command center | `ShiftCommandCenterView.swift`, `FloorChecklistView.swift`, `FloorDetectionCard.swift` | Barometer floor sensing (active delivery) |
| **Home screen widget** | Widget extension | `LinenFlow Widget/HimmerFlow_Widget.swift`, `LinenFlow_WidgetBundle.swift` | WidgetKit, App Group |
| **Live Activity** | Lock screen / Dynamic Island | `LiveActivity/ShiftActivityWidget.swift`, `LinenFlow Widget/` copies | ActivityKit |
| **URL / widget deep links** | Cold / warm launch | `Utilities/WidgetDeepLinkRouter.swift`, `AppRootView.swift` | Custom URL schemes |

---

## Already integrated

### Barometer / relative altitude (floor detection)

| Field | Detail |
|-------|--------|
| **API** | `CoreMotion` — `CMAltimeter`, relative altitude |
| **Status** | **Integrated** — service layer complete; UI wiring in progress (`9e5546a4`) |
| **Files** | `LinenFlow/Services/FloorSensingService.swift`, `FloorSensingEstimator.swift`, `Models/FloorSensingState.swift`, `Services/TowerCalibrationService.swift`, `Models/Tower.swift` (`estimatedFloorHeightMeters`, `floorDetectionToleranceMeters`), `Views/Flow/FloorDetectionCard.swift`, `Views/Flow/ShiftCommandCenterView.swift`, `Views/Flow/FloorChecklistView.swift`, `ViewModels/FlowViewModel.swift` |
| **Permission keys** | **None** — `CMAltimeter` does not prompt for motion permission |
| **Battery** | **Low–medium** while delivery session active (continuous relative altitude updates). Stop on session end. |
| **Simulator** | **Unavailable** — no barometer hardware; service should show graceful “unavailable” state |
| **HimmerFlow use case** | Auto-highlight current floor during linen delivery on high-rise towers; attendant confirms with **Correct floor** control; pairs with `DeliveryFloorSequenceService.swift` ordering |

### GPS / Core Location (when-in-use + geofences)

| Field | Detail |
|-------|--------|
| **API** | `CoreLocation` — `CLLocationManager`, circular regions, significant-change monitoring |
| **Status** | **Integrated** (Shift tab / orchestrator) |
| **Files** | `LinenFlow/Services/LocationService.swift`, `Models/SavedLocation.swift`, `Models/ShiftLocationState.swift`, `Views/Location/LocationPickerView.swift`, `Core/ShiftOrchestrator.swift`, `Core/ReconciliationEngine.swift`, `LinenFlowTests/GeofenceHandlingTests.swift` |
| **Permission keys** | `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` (in `LinenFlow/Info.plist`) |
| **Background modes** | `location` in `UIBackgroundModes` — cold launch via `AppDelegate` / `HimmerFlowAppIntegration.register()` |
| **Battery** | **Medium–high** with always/background geofencing; **low** for one-shot “current location” in picker |
| **HimmerFlow use case** | Detect leave-home / arrive-work for shift timeline phases; reconcile orchestrator state with `ShiftLocationState`; optional tower geo calibration fields on `Tower.swift` |

### Background location & geofence reactions

| Field | Detail |
|-------|--------|
| **API** | Region monitoring + significant location changes |
| **Status** | **Integrated** — wired through `ShiftOrchestrator` → `LocationService` |
| **Files** | `ShiftOrchestrator.swift`, `LocationService.swift`, `ShiftTimelinePhase.swift` (geofence reactions), `LinenFlowTests/ReconciliationTests.swift`, `ShiftOrchestratorReconciliationTests.swift` |
| **Permission keys** | Same as GPS + **Always** authorization for reliable background entry |
| **Battery** | **Medium** — region monitoring is efficient vs continuous GPS fixes |
| **HimmerFlow use case** | Advance shift phases (e.g. `.leave`, `.commute`, `.arrival`) without user opening the app at 5 AM |

### Local notifications

| Field | Detail |
|-------|--------|
| **API** | `UserNotifications` — `UNUserNotificationCenter`, calendar triggers |
| **Status** | **Integrated** |
| **Files** | `LinenFlow/Services/NotificationService.swift`, `LinenFlowTests/NotificationSchedulingTests.swift`, orchestrator scheduling hooks |
| **Permission keys** | System prompt only (no Info.plist usage string required) |
| **Battery** | **Negligible** |
| **HimmerFlow use case** | Phase reminders: sleep, wake, leave-by, commute, shift countdown; snooze actions |

### Live Activities (ActivityKit)

| Field | Detail |
|-------|--------|
| **API** | `ActivityKit` — shift timeline on Lock Screen / Dynamic Island |
| **Status** | **Integrated** |
| **Files** | `LinenFlow/Services/LiveActivityService.swift`, `LiveActivity/ShiftActivityWidget.swift`, `LinenFlow Widget/` (extension copy), `Models/SharedWidgetState.swift`, `Utilities/AppLogger.swift` (`liveactivity` category) |
| **Permission keys** | `NSSupportsLiveActivities` = YES in Info.plist; Live Activity entitlement on target |
| **Battery** | **Low** — system-managed updates |
| **HimmerFlow use case** | Glanceable “leave in 12 min” / current phase for tired night-shift workers; aligned with linen delivery widget state via `SharedWidgetState` |

### Home screen widgets (WidgetKit)

| Field | Detail |
|-------|--------|
| **API** | `WidgetKit`, `TimelineProvider`, App Group JSON |
| **Status** | **Integrated** |
| **Files** | `LinenFlow Widget/HimmerFlow_Widget.swift`, `LinenFlow_WidgetBundle.swift`, `Services/SharedWidgetStateManager.swift`, `Models/SharedWidgetState.swift`, `FlowViewModel.syncWidgetState()` |
| **Permission keys** | App Group entitlement: `group.com.himmerflow.shared` (legacy: `group.com.linenflow.shared`) |
| **Battery** | **Negligible** — OS schedules widget reloads |
| **HimmerFlow use case** | Pin up to 3 linen items; show delivery progress; tap opens app via deep link |

### App Groups & deep links

| Field | Detail |
|-------|--------|
| **API** | `UserDefaults(suiteName:)`, custom URL schemes |
| **Status** | **Integrated** |
| **Files** | `SharedWidgetStateManager.swift`, `Utilities/WidgetDeepLinkRouter.swift`, `AppRootView.swift`, `FlowViewModel.migrateLegacyUserDefaultsKeys()` |
| **Schemes** | `himmerflow://`, `linenflow://` (legacy) — e.g. `himmerflow://widget/delivery?tower=Lagoon` |
| **Battery** | **Negligible** |
| **HimmerFlow use case** | Widget ↔ app state continuity; bookmarkable delivery entry points |

### MapKit (maps & routing UI)

| Field | Detail |
|-------|--------|
| **API** | `MapKit`, `MKMapItem`, directions (Shift tab) |
| **Status** | **Integrated** (Shift / location picker) |
| **Files** | `Views/Location/LocationPickerView.swift`, Shift tab commute cards, `LocationService.fetchCurrentLocation()` |
| **Permission keys** | Uses location keys when showing user position |
| **Battery** | **Low–medium** during active route preview |
| **HimmerFlow use case** | Pick home/work geofence centers; commute ETA card |

### Haptic feedback

| Field | Detail |
|-------|--------|
| **API** | `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`, SwiftUI `.sensoryFeedback` |
| **Status** | **Integrated** (Linen tab) |
| **Files** | `HomeView.swift`, `OneScreenLinenItemCard.swift`, `PremiumExpressionInput.swift`, Smart Fill / Save Log flows |
| **Permission keys** | None |
| **Battery** | **Negligible** |
| **HimmerFlow use case** | Confirm valid expression commit, Save Log success, Smart Fill apply — tactile confidence on noisy laundry floors |

### SwiftData + local persistence

| Field | Detail |
|-------|--------|
| **API** | SwiftData `@Model`, lightweight migration |
| **Status** | **Integrated** |
| **Files** | `HimmerFlowApp.swift`, `HimmerFlowMigrationPlan.swift`, `Tower`, `LinenItem`, `DailyLog`, shift models in `LinenFlow/Models/` |
| **Permission keys** | None |
| **Battery** | **Negligible** |
| **HimmerFlow use case** | Towers, par settings, immutable daily log snapshots, shift patterns |

### Accessibility (VoiceOver, Dynamic Type)

| Field | Detail |
|-------|--------|
| **API** | SwiftUI accessibility modifiers, `AccessibilityNotification` |
| **Status** | **Partial** (Phase 11 in flight) |
| **Files** | `HomeView.linenCardAccessibilityLabel`, `OneScreenLinenItemCard.swift`, `PremiumCard.swift` |
| **Permission keys** | None |
| **Battery** | **Negligible** |
| **HimmerFlow use case** | Attendants with VoiceOver; XXXL Dynamic Type on card grid |

### Logging (OSLog)

| Field | Detail |
|-------|--------|
| **API** | `OSLog` / `Logger` |
| **Status** | **Integrated** |
| **Files** | `Utilities/AppLogger.swift`, `Utilities/Logging.swift` (`HimmerFlowLog`) — categories: `boot`, `session`, `widget`, `save`, `location`, `liveActivity`, `orchestrator` |
| **Battery** | **Negligible** |
| **HimmerFlow use case** | Debug Linen save pipeline, widget sync failures, shift reconciliation |

---

## Partially built (services exist; UI or wiring incomplete)

| Capability | Files | Gap | HimmerFlow opportunity |
|------------|-------|-----|------------------------|
| **Movement sensing coordinator** | `Services/MovementSensingCoordinator.swift` | Not primary path for floor UI | Fuse barometer + motion for elevator vs stairs detection |
| **Phone movement provider** | Mock / protocol in movement stack | Production provider may be stubbed | Detect “walking between floors” vs idle cart |
| **Floor tracking session VM** | `ViewModels/FloorTrackingSessionViewModel.swift` | Uses mocks; not mounted in views | Dedicated debug / calibration session |
| **Tower calibration UI** | `TowerCalibrationView`, `TowerPickerEnvironmentView` (if present) | May be settings-only or hidden | On-site floor height calibration wizard |
| **VoiceOver on distribution rows** | `OneScreenLinenItemCard.swift` | SC-13 partial per master plan | Full card grid a11y |
| **Dynamic Type XXXL** | Card header grids | SC-14 gap | Prevent clipping on small phones |
| **Analytics / signposts** | Observability section in master plan | OSLog only today | Smart Fill adoption metrics |

---

## Available on iPhone but unused (or not planned)

| Capability | API / framework | Permission keys | Battery impact | HimmerFlow use case (if adopted) |
|------------|-----------------|-----------------|----------------|----------------------------------|
| **Pedometer** | `CMPedometer` | `NSMotionUsageDescription` | Medium during active monitoring | Verify “walk-in” phase completion; floor-change corroboration |
| **Motion activity** | `CMMotionActivityManager` | `NSMotionUsageDescription` | Medium | Distinguish driving vs walking vs stationary for commute phase |
| **Accelerometer / gyro** | `CMMotionManager` device motion | `NSMotionUsageDescription` (if motion classified) | Medium–high if continuous | Shake-to-correct floor; detect elevator start/stop |
| **Magnetometer** | `CLLocationManager` heading | Usually bundled with location | Low | Indoor heading for long hotel corridors (weak indoors) |
| **NFC** | `CoreNFC` | `NFCReaderUsageDescription` | Low per scan | Tap floor or linen closet NFC tags to confirm location |
| **Camera / barcode** | `AVFoundation`, `Vision` | `NSCameraUsageDescription` | Low per scan | Scan cart labels (`CountMethod.cartLabelPieces`) instead of manual entry |
| **HealthKit sleep** | `HealthKit` | Health share/read usage strings | Low (read) | Import sleep duration instead of manual sleep phase |
| **Bluetooth beacons** | `CoreBluetooth` + iBeacon | `NSBluetoothAlwaysUsageDescription` (if background) | Medium | Fixed floor beacons in service elevators |
| **UWB ranging** | Nearby Interaction | Varies | Medium | Precise distance to dock stations (future) |
| **Siri / App Intents** | App Intents framework | None | Negligible | “Start Lagoon delivery” hands-free |
| **Focus filters** | Focus API | None | Negligible | Auto-silence non-shift notifications during sleep phase |
| **Apple Watch** | `WatchConnectivity` | Watch companion target | Depends on watch app | Wrist countdown for leave-by time |
| **Significant location only** | `startMonitoringSignificantLocationChanges` | Location Always | Low–medium | Cheaper fallback if geofence radii are large |
| **CarPlay** | `CPInterfaceController` | CarPlay entitlement | N/A | Unlikely for linen attendants |
| **ARKit** | ARKit | Camera permission | High | Overkill for floor counting |

---

## Permission & entitlement checklist

Verify on full tree before TestFlight:

| Key / entitlement | Required for | Typical location |
|-------------------|--------------|------------------|
| `NSLocationWhenInUseUsageDescription` | Map picker, foreground location | `LinenFlow/Info.plist` |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Background geofences, shift orchestrator | `LinenFlow/Info.plist` |
| `UIBackgroundModes` → `location` | Geofence wake, AppDelegate relaunch | `LinenFlow/Info.plist` |
| `NSSupportsLiveActivities` | Shift Live Activity | `LinenFlow/Info.plist` |
| App Groups `group.com.himmerflow.shared` | Widget + shared state | App + widget entitlements |
| URL types `himmerflow`, `linenflow` | Widget deep links | Info.plist / target settings |
| `NSMotionUsageDescription` | **Not required today** (barometer only) | Add if adopting pedometer / motion activity |
| `NSCameraUsageDescription` | **Not required today** | Add if barcode scanning ships |
| `NFCReaderUsageDescription` | **Not required today** | Add if NFC floor tags ship |

---

## Battery impact summary (operations view)

| Tier | Features | Guidance |
|------|----------|----------|
| **Negligible** | WidgetKit, notifications (scheduled), haptics, SwiftData, deep links | Safe to leave enabled |
| **Low** | Live Activities, MapKit snapshot, one-shot GPS | Default for shift tab |
| **Medium** | Barometer during delivery, geofence monitoring, pedometer | Start/stop with delivery session; document in QA |
| **High** | Continuous GPS fixes, continuous motion streaming, AR | Avoid unless explicitly product-required |

---

## Verification notes

| Feature | Simulator | Physical iPhone |
|---------|-----------|-----------------|
| Barometer / floor detection | ❌ Unavailable | ✅ Required (`AGENT_WORK_LOG.md` quality gate) |
| Widget pin + App Group | ⚠️ Partial | ✅ Preferred |
| Haptics | ❌ | ✅ |
| Geofence background | ⚠️ Limited | ✅ |
| Live Activity | ✅ | ✅ |

**Console filters:**

```
subsystem:com.himmerflow.app category:widget
subsystem:com.himmerflow.app category:location
subsystem:com.himmerflow.app category:liveactivity
```

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-07 | Initial inventory (`89f7ca28`) — docs-only; 50fed4e9 audit doc not yet present |
