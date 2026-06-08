# Linen Tab — Manual QA (One-Screen Smoke Checklist)

> **Purpose:** Pre-release smoke test for the one-screen Linen tab (`HomeView`). Replaces the wizard-era checklist in `Docs/BuildLog.md`.
>
> **Source:** `docs/superpowers/plans/2026-06-08-linen-tab-master-plan.draft-qa-risks.md` § Manual QA — smoke path.
>
> **Duration:** ~15 minutes.
>
> **Devices:** Run on **iOS Simulator** and at least one **physical iPhone** (haptics + keyboard behavior differ).

---

## Prerequisites

- Fresh install **or** Settings → confirm seed towers are present.
- Prefer **Lagoon** tower (21 floors) for parity with `DemoDayFlowTests`.
- Optional: filter Console for boot logs — `subsystem:com.himmerflow category:boot`.

---

## Smoke checklist (15 steps)

### 1. Setup

- [ ] Confirm app data state: fresh install **or** seeded towers visible in Settings → Towers.
- [ ] Note device type (Simulator model **or** physical iPhone model + iOS version).

**Pass criteria:** Lagoon (or target tower) available for selection; no prior crash on last launch.

---

### 2. Launch

- [ ] Cold-launch the app (force quit first if re-testing).
- [ ] Confirm default tab is **Linen** (tab 0, `shippingbox.fill` icon).
- [ ] Confirm no crash on cold start.

**Pass criteria:** Linen tab visible; no crash. Optional: `AppLogger.boot` line in Console.

---

### 3. Tower picker

- [ ] On `HomeView`, expand the inline tower picker.
- [ ] Select **Lagoon** (21 floors).
- [ ] Confirm picker collapses and header shows tower name + accent color.

**Pass criteria:** Header reads “Lagoon”; floor count reflects 21.

---

### 4. Item selection

- [ ] Open item configuration for the tower.
- [ ] Enable: **Bath Towel**, **Bath Mat**, **Hand Towel**, **Washcloth**, **Pillow Case** → Save.
- [ ] Confirm deselected items are hidden from the card grid.

**Pass criteria:** Exactly the enabled items appear as linen cards.

---

### 5. Empty-state intelligence

- [ ] With **zero** receiving entries, observe intelligence cards.
- [ ] If prior logs exist: **Restore Last Log** card is visible.
- [ ] If predictions exist: **Smart Fill** card is visible.

**Pass criteria:** Cards match data state (either, both, or neither — not stale/wrong tower).

---

### 6. Smart Fill or manual entry

- [ ] Apply **Smart Fill** **or** enter `490` on the Bath Towel card via the expression input.
- [ ] Confirm card summary shows bundles/pieces.
- [ ] Expand distribution: **21 floors** listed (Demo Day: first 7 at 24 pcs, remainder 23 — matches `DemoDayFlowTests`).

**Pass criteria:** Totals recalculate; distribution row count = tower floor count.

---

### 7. Arithmetic expression

- [ ] On **Bath Mat**, enter `30+30`.
- [ ] Confirm parsed total **60** without crash or stuck spinner.

**Pass criteria:** Expression evaluates to 60; covered by `ArithmeticTests` in CI.

---

### 8. Validation warnings

- [ ] Enter a partial bundle on **Hand Towel** (e.g. 3 pieces when bundle size > 3).
- [ ] Confirm warning badge or validation message appears.

**Pass criteria:** User-visible validation; aligns with `FlowViewModelTests.test_validation_*`.

---

### 9. Summary strip

- [ ] With multiple entries populated, locate the inline summary strip.
- [ ] Confirm totals for items / pieces / bundles / loose are visible.

**Pass criteria:** Strip updates when entries change.

---

### 10. Save Log

- [ ] Tap **Save Log**.
- [ ] Confirm success haptic (physical device) and confirmation UI.
- [ ] Switch to **Logs** tab → new **Lagoon** entry at top.

**Pass criteria:** Log persisted; visible in Logs tab immediately.

---

### 11. Snapshot immunity

- [ ] Settings → change **Bath Mat** par (or bundle-related setting).
- [ ] Logs tab → reopen the saved Lagoon log from step 10.
- [ ] Confirm saved counts are **unchanged**.

**Pass criteria:** Snapshot isolation — `DailyLogSaveTests.test_savedLog_snapshotIsImmuneToLaterSettingsChanges`.

---

### 12. Clear Entries

- [ ] Return to Linen tab → **Clear Entries**.
- [ ] Confirm dialog → proceed.
- [ ] Confirm entries cleared and delivery session reset.

**Pass criteria:** Empty card grid; `FlowViewModelTests.test_clearEntries_resetsDeliverySessionAndDeliveryItem`.

---

### 13. Open Delivery

- [ ] Re-enter minimal data if needed (or Restore Last Log).
- [ ] Tap bottom chrome **Open Delivery** (or equivalent).
- [ ] Confirm navigation to `ShiftCommandCenterView` with pace/checklist UI.

**Pass criteria:** Delivery command center loads without crash.

---

### 14. Widget pin

- [ ] On a linen card, toggle **widget pin** for an item.
- [ ] Add HimmerFlow home-screen widget if not present.
- [ ] Confirm widget reflects pinned item (App Group `group.com.himmerflow.shared`).

**Pass criteria:** Widget label/counts match pinned item within one refresh cycle.

---

### 15. Deep link

- [ ] From Safari or terminal:
  - Simulator: `xcrun simctl openurl booted 'himmerflow://widget/delivery?tower=Lagoon'`
  - Device: open the same URL in Notes/Safari.
- [ ] Confirm app opens to **Linen** tab and pushes delivery / command center.

**Pass criteria:** Route handled by `WidgetDeepLinkCoordinator`; legacy `linenflow://` schemes still work if tested separately.

---

## Sign-off

| Field | Value |
|-------|-------|
| Tester | |
| Date | |
| Simulator pass (Y/N) | |
| Device pass (Y/N) | |
| Build / branch | |
| Failures (step #) | |

---

## When to re-run

Minimum re-run after any merge touching:

| Area | Automated minimum | Manual minimum |
|------|-------------------|----------------|
| `HomeView.swift` layout | Build | Steps 1–6 |
| `FlowViewModel.swift` | `FlowViewModelTests` | Steps 6, 10, 12 |
| `OneScreenLinenItemCard.swift` | Build | Steps 6–9 |
| Widget sync | `test_syncWidgetState_*` | Step 14 |
| Deep links | `WidgetDeepLinkRouterTests` (when added) | Step 15 |

---

## Related checklists

- **Accessibility pass (Phase 11):** VoiceOver + Dynamic Type XXXL — see master plan § Linen tab — accessibility pass.
- **Settings dependency:** Towers & Areas + Linen Items sections (custom towers in picker; inactive items hidden).
- **Unit test gate:** `xcodebuild test -scheme HimmerFlow` — 283+ tests before TestFlight.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-07 | Initial 15-step smoke checklist (`89f7ca28`) from QA draft |
