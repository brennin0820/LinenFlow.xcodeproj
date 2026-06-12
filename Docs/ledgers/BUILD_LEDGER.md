# NightRaven Build Ledger

## [2026-06-11] GravNightraven-Orchestrator — LinenFlow parallel dispatch
- Event: BuildStarted
- Actions performed: Installed God's Eye + NightRaven Core; created BUILD_PLAN_FULL.md, linenflow-parallel.yaml, PARALLEL_RUN_STATUS.md; registered project in gods-eye-projects.conf; dispatched parallel streams S1–S5
- Files created: Docs/BUILD_PLAN_FULL.md, Docs/PARALLEL_RUN_STATUS.md, .gods-eye/nightraven/linenflow-parallel.yaml
- Files modified: /Users/brentlenninorlanda/Developer/gods-eye/scripts/gods-eye-projects.conf
- Dependencies added: none
- Reasoning: User requested Grav Nightraven parallel build for entire LinenFlow project
- Confidence: 85/100

## [2026-06-11] ios-uitest — Phase 14 XCUITest happy path
- Event: FeatureBuilt
- Actions performed: Implemented `LinenFlowUITests/LinenTabUITests.swift` with launch→Linen tab, tower selection, piece entry, summary assertion, save log, Logs tab verification; attempted xcodebuild UI test run
- Files created: (none — scaffold pre-existed)
- Files modified: `LinenFlowUITests/LinenTabUITests.swift`, `AGENT_WORK_LOG.md`, `docs/ledgers/BUILD_LEDGER.md`
- Dependencies added: none
- Reasoning: Phase 14 Track L; `project.pbxproj` locked by `f19a62cd`/`50fed4e9` — UI test target not added; test source ready for pbxproj integration
- Blockers: `LinenFlowUITests` target missing from Xcode project (pbxproj ACTIVE lock); xcodebuild `-only-testing:LinenFlowUITests` cannot run until target added and scheme updated
- Confidence: 82/100

## [2026-06-11] ci-gates — CI workflow verification (Stream S4)
- Event: FeatureBuilt
- Actions performed: Reviewed `.github/workflows/ios-ci.yml`, `android-ci.yml`, `swift.yml` against `Docs/BUILD_PLAN_FULL.md` Gate 4; fixed AGP 9 built-in Kotlin incompatibility (removed deprecated `org.jetbrains.kotlin.android` plugin); bumped `compileSdk` 35→36 for `androidx.activity:1.13.0`; added `iPhone 17 Pro Max` to iOS CI simulator preference list; ran local verification
- Files created: none
- Files modified: `.github/workflows/ios-ci.yml`, `android/build.gradle.kts`, `android/app/build.gradle.kts`, `docs/ledgers/BUILD_LEDGER.md`
- Dependencies added: none
- Workflow assessment:
  - **ios-ci.yml** — OK: `LinenFlow.xcodeproj` + `HimmerFlow` scheme, macos-15, resolvePackageDependencies, dynamic simulator selection, build+test with code-sign disabled, artifact upload. Minor fix: prefer `iPhone 17 Pro Max` (matches build plan).
  - **android-ci.yml** — OK after Gradle fixes: `android/` working dir, JDK 21, `assembleDebug` + `test`, APK artifact path `android/app/build/outputs/apk/debug/*.apk` verified locally.
  - **swift.yml** — Intentionally disabled (`if: false`); comment directs to `ios-ci.yml`. No action needed.
  - **swift-format.yml** — Not in scope; paths and `.vscode/.swift-format` config look correct.
  - **codeql.yml** — Uses same project/scheme; Android leg depends on same Gradle fixes.
- Commands run:
  - `xcodebuild -project LinenFlow.xcodeproj -scheme HimmerFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build` → **PASS** (BUILD SUCCEEDED)
  - `cd android && ./gradlew assembleDebug` (JAVA_HOME=Android Studio JBR, ANDROID_HOME=~/Library/Android/sdk) → **PASS** after fixes (BUILD SUCCESSFUL, `app-debug.apk` produced)
  - `cd android && ./gradlew test` → **PASS** (no unit tests yet; task succeeds)
- Reasoning: Android CI would fail on AGP 9.2.1 with legacy `kotlin.android` plugin and compileSdk 35 vs activity 1.13.0 requirement; iOS workflow was already correct
- Confidence: 90/100

Append-only. Every Builder Agent logs here — actions, files, dependencies, reasoning, confidence. Builders report to this ledger, not to auditors and not to the user. Auditors consume these entries.

Entry format:

```
## [YYYY-MM-DD] <BuilderAgent> — <task>
- Event: BuildStarted | FeatureBuilt | DatabaseChanged | ...
- Actions performed: ...
- Files created: ...
- Files modified: ...
- Dependencies added: ...
- Reasoning: ...
- Confidence: <n>/100
```

---
