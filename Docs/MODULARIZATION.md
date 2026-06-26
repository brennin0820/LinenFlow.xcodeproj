# Modularization — LinenFlow (HimmerFlow)

This document describes the modular architecture that LinenFlow is being
refactored into: a single SwiftUI + SwiftData iOS app target split into a
thin app shell plus a local Swift package, `LinenFlowKit`, containing three
library targets.

- Platform: SwiftUI + SwiftData, iOS 26.0 deployment target
- Swift language mode 5
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (app target and package targets)
- ~200 Swift source files
- Local package location: `Modules/LinenFlowKit/`

> Status: this refactor was prepared in an environment **without Xcode**, so it
> has **not been build-verified** yet. See
> [`MODULARIZATION_FINISHING.md`](./MODULARIZATION_FINISHING.md) for the
> Mac + Xcode steps required to finish and verify it.

## Overview — the 4 slices

The codebase is divided into four slices with a strict one-way dependency
direction. Each higher slice may depend on the slices below it; nothing depends
upward.

1. **App** — the existing `HimmerFlow` Xcode app target. The thin shell:
   `@main` entry point, app delegate, assets, configuration, entitlements.
2. **LinenFlowUI** — library target. SwiftUI views and view models.
3. **LinenFlowEngine** — library target. Services and orchestration logic.
4. **LinenFlowCore** — library target. Models, utilities, seed data, protocols,
   Live Activity attributes. The foundation; depends on nothing else in the app.

## Dependency diagram

```
            ┌─────────────────────────────┐
            │           App               │   HimmerFlow (Xcode app target)
            │  @main, AppDelegate, Assets │
            └──────────────┬──────────────┘
                           │ depends on
                           ▼
            ┌─────────────────────────────┐
            │        LinenFlowUI          │   Views/, ViewModels/
            └──────────────┬──────────────┘
                           │ depends on
                           ▼
            ┌─────────────────────────────┐
            │       LinenFlowEngine       │   Services/, Orchestration/
            └──────────────┬──────────────┘
                           │ depends on
                           ▼
            ┌─────────────────────────────┐
            │        LinenFlowCore        │   Models/, Utilities/, SeedData/,
            │                             │   LiveActivity/, Protocols/
            └─────────────────────────────┘
                 (no dependency on the other slices)
```

Dependencies are transitive: the App target links `LinenFlowUI` directly and
gets `LinenFlowEngine` and `LinenFlowCore` transitively. `LinenFlowUI` links
`LinenFlowEngine` and `LinenFlowCore`; `LinenFlowEngine` links `LinenFlowCore`.

The graph is **acyclic** by construction — this is enforced by the compiler at
the module boundary (a cycle would fail to build).

## Slice contents

### App — `HimmerFlow` Xcode app target
- `LinenFlow/App/HimmerFlowApp.swift` — `@main` entry point
- `LinenFlow/App/AppDelegate.swift`
- `Assets.xcassets`
- `Info.plist`, entitlements
- Gains Swift package product dependencies on the three library products.

### LinenFlowUI — `Modules/LinenFlowKit/Sources/LinenFlowUI/`
- `Views/`
- `ViewModels/`
- Depends on: `LinenFlowEngine`, `LinenFlowCore`

### LinenFlowEngine — `Modules/LinenFlowKit/Sources/LinenFlowEngine/`
- `Services/`
- `Orchestration/` — `ReconciliationEngine`, `ShiftOrchestrator`,
  `TimelineComputation`
- Depends on: `LinenFlowCore`

### LinenFlowCore — `Modules/LinenFlowKit/Sources/LinenFlowCore/`
- `Models/`
- `Utilities/`
- `SeedData/`
- `LiveActivity/` — `ActivityAttributes` types
- `Protocols/`
- Depends on: nothing in the app.
- May import: SwiftUI, Foundation, SwiftData, CoreLocation, OSLog, ActivityKit.

## Old folder → new module/location

| Old location (in app target)      | New module        | New location                                         |
| --------------------------------- | ----------------- | ---------------------------------------------------- |
| `LinenFlow/App/`                  | App (HimmerFlow)  | `LinenFlow/App/` (unchanged, stays in app target)    |
| `Assets.xcassets`, `Info.plist`   | App (HimmerFlow)  | unchanged, stays in app target                       |
| `Views/`                          | LinenFlowUI       | `Modules/LinenFlowKit/Sources/LinenFlowUI/Views/`    |
| `ViewModels/`                     | LinenFlowUI       | `Modules/LinenFlowKit/Sources/LinenFlowUI/ViewModels/` |
| `Services/`                       | LinenFlowEngine   | `Modules/LinenFlowKit/Sources/LinenFlowEngine/Services/` |
| `Orchestration/`                  | LinenFlowEngine   | `Modules/LinenFlowKit/Sources/LinenFlowEngine/Orchestration/` |
| `Models/`                         | LinenFlowCore     | `Modules/LinenFlowKit/Sources/LinenFlowCore/Models/` |
| `Utilities/`                      | LinenFlowCore     | `Modules/LinenFlowKit/Sources/LinenFlowCore/Utilities/` |
| `SeedData/`                       | LinenFlowCore     | `Modules/LinenFlowKit/Sources/LinenFlowCore/SeedData/` |
| `LiveActivity/` (ActivityAttributes) | LinenFlowCore  | `Modules/LinenFlowKit/Sources/LinenFlowCore/LiveActivity/` |
| `Protocols/`                      | LinenFlowCore     | `Modules/LinenFlowKit/Sources/LinenFlowCore/Protocols/` |

## Rationale — "easier to manage"

- **Isolated compilation units.** Each slice compiles as its own module.
  Changing a view no longer forces a recompile of model or service code.
- **Enforced boundaries.** The one-way dependency direction is enforced by the
  compiler. UI cannot reach "sideways," and lower layers cannot depend on
  higher ones — an attempt to introduce a cycle simply fails to build.
- **Faster incremental builds.** Because modules are separate compilation units,
  edits localized to one slice rebuild only that slice (and its dependents),
  not the whole ~200-file target.
- **Clearer ownership.** Each file's responsibility is implied by the module it
  lives in: foundational types in Core, business logic in Engine, presentation
  in UI, wiring and lifecycle in App.
- **Explicit public surface.** Crossing a module boundary requires marking a
  symbol `public`, which makes each module's intended API visible and
  deliberate rather than accidental.

## Adding code going forward

Decide which slice the new code belongs to by its responsibility, then place the
file in that slice's directory and add the right imports.

- **A new model, utility, seed type, protocol, or Live Activity attribute** →
  `LinenFlowCore`. No app imports needed beyond system frameworks.
- **A new service or orchestration component** → `LinenFlowEngine`.
  `import LinenFlowCore` to reference models/utilities/protocols.
- **A new view or view model** → `LinenFlowUI`.
  `import LinenFlowEngine` and/or `import LinenFlowCore` as needed.
- **App lifecycle / wiring / configuration** → the App target (`HimmerFlow`).
  `import LinenFlowUI` (and the lower modules as needed).

Rules of thumb:

- Never import "upward." Core must not import Engine or UI; Engine must not
  import UI. If you find yourself wanting to, the type probably belongs in a
  lower slice.
- Any type or member referenced from a different module must be declared
  `public` (and constructed types need an explicit `public init`). See the
  finishing guide for details.
- Keep the App target thin: prefer pushing logic down into Engine/Core rather
  than accumulating it in the shell.

## Widgets are separate and unchanged

The two widget extensions — **"LinenFlow Widget"** and **"LinenFlowWidgets"** —
are **not** part of `LinenFlowKit`. They keep their **own copies** of shared
files and are intentionally left untouched by this refactor. Do not route the
widget targets through the package; they remain independent.
