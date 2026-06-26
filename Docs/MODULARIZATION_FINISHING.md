# Finishing & Verifying the Modularization (Mac + Xcode)

The split into `LinenFlowKit` (targets `LinenFlowCore`, `LinenFlowEngine`,
`LinenFlowUI`) plus the thin `HimmerFlow` app target was prepared **without
Xcode** and is therefore **not build-verified**. This is the checklist to
finish and verify it on a Mac.

See [`MODULARIZATION.md`](./MODULARIZATION.md) for the architecture overview.

## What the automated first pass already did

- Moved each old folder into its target under `Modules/LinenFlowKit/Sources/...`
  (see the mapping table in `MODULARIZATION.md`).
- Promoted top-level type and member declarations from the default `internal`
  access level to `public`, so they can be referenced across module boundaries.
- Added the necessary `import LinenFlowCore` / `import LinenFlowEngine` lines.
- Wired a local Swift package reference into `LinenFlow.xcodeproj` and added the
  three library products as package product dependencies of the app target.
- Set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on the package targets (via a
  Swift setting) to match the app target.

What it could **not** do is anything that only the Swift compiler can surface.
The rest of this document is that work. The general loop is: **build, read the
first error, fix it, repeat.** The compiler pinpoints each remaining item.

## Step 1 — Open and resolve the package

1. Open `LinenFlow.xcodeproj` in Xcode.
2. Let Xcode resolve the local package. If it does not start automatically:
   **File ▸ Packages ▸ Resolve Package Versions**.
3. Confirm `LinenFlowKit` appears in the project navigator with three library
   products: `LinenFlowCore`, `LinenFlowEngine`, `LinenFlowUI`.
4. Select the `HimmerFlow` app target ▸ **General ▸ Frameworks, Libraries, and
   Embedded Content** and confirm it depends on the library products it needs
   (at minimum `LinenFlowUI`; Engine and Core come transitively).

If resolution fails, check the package manifest at
`Modules/LinenFlowKit/Package.swift` and the package reference path in the
project file.

## Step 2 — Build bottom-up

Build the modules in dependency order so errors surface at their source rather
than cascading:

1. Build the `LinenFlowCore` scheme/target first.
2. Then `LinenFlowEngine`.
3. Then `LinenFlowUI`.
4. Finally the `HimmerFlow` app target.

(Building the app builds everything, but bottom-up makes the **first** real
error easier to find.)

## Step 3 — Iterative access-control & isolation fixups

Expect a series of access-control errors at module boundaries. Fix the first
one reported, rebuild, repeat. The five recurring categories:

### 3.1 Public initializers (most common)

Swift does **not** synthesize *public* memberwise inits for structs, nor a
public init for a class. A `struct` or `class` defined in one module and
**constructed from another module** needs an explicit `public init(...)`.

Expected error:

```
'X' initializer is inaccessible due to 'internal' protection level
```

Fix — add an explicit public init mirroring the stored properties:

```swift
public struct ShiftSummary {
    public let id: UUID
    public let title: String

    public init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }
}
```

For a class, add a `public init` with the same parameters its callers use.

### 3.2 SwiftData `@Model` classes

For each `@Model` type that is **constructed** from another module (e.g. a
model defined in `LinenFlowCore` but instantiated in `LinenFlowUI` or
`LinenFlowEngine`):

- Mark the class `public`.
- Add a `public init(...)` (the macro-generated init is not public).
- Confirm the **properties** accessed across modules are `public` too.

Expected errors look like the §3.1 init error, plus
"'someProperty' is inaccessible due to 'internal' protection level" for stored
properties read or written across modules.

### 3.3 MainActor isolation

The app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; the package
targets are configured with the same default. Verify no actor-isolation errors
remain after the move.

Typical symptom:

```
call to main actor-isolated <member> in a synchronous nonisolated context
```

Fixes, depending on intent:

- Annotate the type/member explicitly with `@MainActor` where main-actor
  isolation is intended, or
- Mark genuinely isolation-free code `nonisolated`, or
- Await across the boundary if calling from a non-isolated async context.

Confirm the `SWIFT_DEFAULT_ACTOR_ISOLATION` (or equivalent `swiftSettings`
`defaultIsolation(MainActor.self)`) is actually present on **every** package
target, not just the app, since a mismatch is a common source of these errors.

### 3.4 Remaining "inaccessible due to internal protection level"

For any other symbol the compiler reports as inaccessible across a module
boundary — a method, property, enum case, typealias, nested type — promote that
**specific** symbol to `public`:

```
'computeTimeline' is inaccessible due to 'internal' protection level
```

→ mark `computeTimeline` (and its parameter/return types, if they are also
cross-module) `public`. Promote only what is actually used across the boundary;
keep internal anything that is module-private.

### 3.5 Unused-import warnings (cosmetic)

The automated pass may have added imports that a given file does not use.
These produce warnings, not errors. Remove them if desired; they do not block
the build.

## Step 4 — Verify the dependency graph is acyclic

The build itself enforces acyclicity — a module cycle fails to compile. To
inspect the graph explicitly:

- In `Modules/LinenFlowKit/`, run:

  ```sh
  swift package show-dependencies
  ```

  Expect a tree, never a cycle. The intended shape is
  `LinenFlowUI → LinenFlowEngine → LinenFlowCore`, with the app target on top.

- Sanity-check the `dependencies:` arrays in `Package.swift`:
  - `LinenFlowCore` depends on nothing.
  - `LinenFlowEngine` depends only on `LinenFlowCore`.
  - `LinenFlowUI` depends on `LinenFlowEngine` and `LinenFlowCore`.

- Confirm no source file imports "upward" (e.g. a file in `LinenFlowCore` must
  never `import LinenFlowEngine` or `import LinenFlowUI`).

## Step 5 — Run the tests

1. Build for the destination first to make sure everything links.
2. Run the existing app test targets (`LinenFlowTests`, `LinenFlowUITests`) via
   **Product ▸ Test** or:

   ```sh
   xcodebuild test \
     -project LinenFlow.xcodeproj \
     -scheme HimmerFlow \
     -destination 'platform=iOS Simulator,name=iPhone 16'
   ```

   (Use a simulator that supports the iOS 26.0 deployment target.)

3. If you add package-level unit tests under
   `Modules/LinenFlowKit/Tests/`, run them with:

   ```sh
   swift test --package-path Modules/LinenFlowKit
   ```

   Note: package targets that import iOS-only frameworks (SwiftUI, SwiftData,
   ActivityKit, etc.) generally need to be exercised through an Xcode/simulator
   destination rather than plain `swift test` on macOS.

## Done criteria

- All four targets build clean (Core → Engine → UI → app).
- No "inaccessible due to internal protection level" errors remain.
- No actor-isolation errors remain.
- `swift package show-dependencies` shows an acyclic tree matching the intended
  shape.
- Existing test targets pass.

## Out of scope — widgets

The two widget extensions ("LinenFlow Widget" and "LinenFlowWidgets") are **not**
part of `LinenFlowKit`. They keep their own copies of shared files and are not
touched by this work. Do not route them through the package while finishing the
build.
