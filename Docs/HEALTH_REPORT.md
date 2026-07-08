# LinenFlow Repository Health Report

**Date:** 2026-07-08
**Scope:** `brennin0820/LinenFlow.xcodeproj` (main branch, HEAD `945b5a9`)

## Executive summary

| Area | Status | Notes |
|---|---|---|
| iOS build (main) | 🔴 **Broken** | Compile error in `DefaultData.swift` fails every build |
| iOS CI | 🔴 Red | Hasn't gone green on `main` since at least 2026-06-08 |
| CodeQL (Swift) | 🔴 Red | Fails as a downstream effect of the same compile error |
| CodeQL (Java/Kotlin) | 🟡 Config error | Extractor doesn't support the pinned Kotlin version, not a code defect |
| Android CI | 🟢 Green | Last real run (2026-06-12) passed; path-filtered so it hasn't re-run since |
| Swift Format lint | 🟡 Gap | Doesn't cover `Modules/LinenFlowKit`, where ~90% of the app's Swift now lives |
| Test suite | ⚪ Unknown | Can't execute — blocked by the build failure above |
| Open PRs | 5 | One (`#12`) is the fix for the build break and is sitting unmerged |
| Dependencies | 🟡 Behind | 2 open Dependabot PRs (Android deps, `actions/checkout`) |

**Bottom line:** the app does not currently compile. This is a single well-understood syntax error with a fix already proposed in an open PR. Everything else in the repo is in reasonably good shape once that's merged.

## 1. Critical: `main` doesn't build

`Modules/LinenFlowKit/Sources/LinenFlowCore/SeedData/DefaultData.swift` has `public` written before 21 `.init(...)` array-literal elements:

```swift
public static let towers: [TowerDefault] = [
    public .init(name: "Lagoon", ...),   // ← invalid: `public` is a declaration
    ...                                   //   modifier, meaningless on an expression
]
```

`public` is a declaration modifier and has no meaning inside an array literal — Swift can't parse it, so the whole `LinenFlowCore` target fails to compile with a cascade of ~15 syntax errors per malformed line. This breaks:

- `xcodebuild build` for the `HimmerFlow` scheme (iOS CI)
- CodeQL's Swift analysis (it builds the project to analyze it)
- Any local development that pulls `main`

**A fix already exists:** PR **[#12 — "Fix invalid `public` modifier on array literal elements in DefaultData.swift"](https://github.com/brennin0820/LinenFlow.xcodeproj/pull/12)**, opened 2026-06-26 by the Copilot coding agent, currently a draft with no reviews or merge activity. It removes `public` from all 21 array elements — the correct, minimal fix (the array is already declared `public static let`, so element visibility is inherited).

**Recommendation:** review and merge #12 (or mark it ready for review) — it's the single highest-leverage action available right now. Until it merges, every subsequent commit on `main` will also fail CI.

Likely root cause: this looks like an artifact of the recent "slice app into 4 modules" refactor (`d7137bf`, merged via PR into `main` on 2026-06-26) — probably a find/replace that added `public` broadly and didn't account for array-literal position.

## 2. CI/CD status detail

- **iOS CI** (`.github/workflows/ios-ci.yml`): last 9+ runs on `main` going back to 2026-06-08 are all `failure` or `cancelled` — it has not gone green in a month. The most recent `main` push (2026-06-26, the module-slice merge) never got a completed iOS CI run at all (cancelled).
- **CodeQL**: two matrix jobs, `swift` and `java-kotlin`.
  - `swift` fails at "Build for CodeQL (Swift)" — same root cause as above.
  - `java-kotlin` fails with `CodeQL job status was configuration error` / "Kotlin version too new" — CodeQL's Java/Kotlin extractor doesn't yet support the Kotlin/AGP version the Android module is pinned to. This is a tooling limitation, not a defect in the code; it should be tracked separately (pin CodeQL to a supported Kotlin version, or wait for extractor support) rather than treated as a build regression.
- **Android CI** (`.github/workflows/android-ci.yml`): path-filtered to `android/**`, so it only runs when Android files change. Its last real execution (2026-06-12, commit `cfd2140`) passed cleanly (`assembleDebug` + unit tests). No evidence of Android-side breakage.
- **Swift Format** (`.github/workflows/swift-format.yml`): passing, but its `paths:` trigger and lint target list (`LinenFlow`, `LinenFlowTests`, `LinenFlow Widget`, `LinenFlowWidgets`) predate the module split and were never updated. `Modules/LinenFlowKit/**` — now the bulk of the Swift source (203 of the repo's Swift files, ~31k LOC) — is neither linted nor gated by this workflow. It would not have caught the `DefaultData.swift` issue (that's a compiler error, not a style issue), but it means format drift in the largest part of the codebase currently goes unchecked.
- **`swift.yml`**: intentionally disabled (`if: false`) with a comment pointing at `ios-ci.yml` as the real workflow. No action needed, just noting it's dead weight that could be deleted.

## 3. Open pull requests

| # | Title | Author | State | Notes |
|---|---|---|---|---|
| [12](https://github.com/brennin0820/LinenFlow.xcodeproj/pull/12) | Fix invalid `public` modifier in `DefaultData.swift` | Copilot | draft | **Fixes the build break above — highest priority** |
| [9](https://github.com/brennin0820/LinenFlow.xcodeproj/pull/9) | Load God's Eye memory chain at session start | brennin0820 (Claude) | draft | Adds a `SessionStart` hook; unrelated to build health |
| [8](https://github.com/brennin0820/LinenFlow.xcodeproj/pull/8) | Bump Android deps (compose-bom, lifecycle, gradle-wrapper) | dependabot | open, not draft | Routine; its own CI run failed, but only because CodeQL/Kotlin config error (see §2), not the dependency bump itself |
| [7](https://github.com/brennin0820/LinenFlow.xcodeproj/pull/7) | Bump `actions/checkout` 6 → 7 | dependabot | open, not draft | Routine, low risk |
| [6](https://github.com/brennin0820/LinenFlow.xcodeproj/pull/6) | Fix UI behavior defects (stale edit focus, VoiceOver label, Reduce Motion) | brennin0820 (Claude) | draft | Small, well-scoped SwiftUI fixes; been open since 2026-06-14 |

Five open PRs, none merged in the last two weeks despite CI having been red that whole time — worth a merge pass, starting with #12.

## 4. Code structure & size

The app was recently sliced into a clean one-way dependency graph (commit `d7137bf`):

```text
App (HimmerFlow target) → LinenFlowUI → LinenFlowEngine → LinenFlowCore
```

- 203 Swift files / ~30,900 lines under `LinenFlow/` + `Modules/LinenFlowKit/`
- Android companion app: 717 lines of Kotlin — small, likely a secondary/companion surface rather than full feature parity
- Largest files are all in `LinenFlowUI` and skew toward view code:
  - `SettingsView.swift` — 1,767 lines
  - `FlowViewModel.swift` — 1,715 lines
  - `ShiftTabView+LegacyDeliveryContent.swift` — 1,657 lines
  - `FloorDistributionView.swift` (Legacy, excluded from build) — 1,477 lines
  - `HomeView.swift` — 1,282 lines

  Several of the largest files (`FloorDistributionView`, `ResultsView`, `ReceivingView`, `RebalanceShortFloorsView`, `FlowStep`, `ReviewReceivedView` — all under `Views/Flow/Legacy/`) are explicitly excluded from both the SPM package and the app target's build. That's ~4,700 lines of dead/superseded code still living in the tree. Worth a decision: delete it, or document why it's kept around (reference implementation? partial migration?).
- Only one `TODO` in the entire codebase (`ShiftOrchestrator.swift:11`), no `FIXME`/`XXX` — low debt-marker noise, though that alone doesn't say much about actual debt.

## 5. Tests

- `LinenFlowTests/`: 25 test files + 4 protocol mocks (clock, location, notification, live activity) — good breadth, covering reconciliation, scheduling, arithmetic parsing, geofencing, widgets, and view models.
- `LinenFlowUITests/`: exactly one file (`LinenTabUITests.swift`) — UI test coverage is thin relative to the unit suite.
- **None of this can currently run in CI** — the build failure in §1 blocks the `Test` step entirely (it shows as `skipped` in the last completed iOS CI run). Test health is unknown until the build is fixed.

## 6. Dependencies

- Android: Gradle wrapper `9.5.1`, with Dependabot already proposing `9.6.1` + Compose BOM / lifecycle bumps (PR #8) — dependency hygiene here looks actively maintained via Dependabot.
- GitHub Actions: Dependabot proposing `actions/checkout` v6 → v7 (PR #7) — routine.
- Swift: no `Package.resolved` / external SPM dependencies found for `LinenFlowKit` — it has zero third-party dependencies, which is good for supply-chain risk but also means Dependabot has nothing to manage on the Swift side (there's no ecosystem entry for Swift in `.github/dependabot.yml` to verify, worth confirming it's intentional rather than an oversight — the "swift in /." check that appears in the Actions history is actually a **Dependabot** run failing at its "Run Dependabot" step, separate from the CI failures in §1-2).

## Prioritized recommendations

1. **Merge PR #12** (or an equivalent fix) to restore a compiling `main` — everything else is secondary until this lands.
2. Re-run iOS CI and CodeQL (Swift) on `main` after the fix merges to confirm green, and actually execute the test suite for the first time in a month.
3. Update `.github/workflows/swift-format.yml`'s path filters and lint target to include `Modules/LinenFlowKit/**` so the largest part of the codebase is covered.
4. Decide on the ~4,700 lines of excluded `Views/Flow/Legacy/*` — delete or document intent.
5. Clear the small PR backlog (#6, #7, #8, #9) now that CI will actually be able to validate them.
6. Track the CodeQL Java/Kotlin "configuration error" separately from real build health — it's a Kotlin-version/extractor mismatch, not a code regression.
