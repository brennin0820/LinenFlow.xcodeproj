# God's Eye repo overlay — local layer

**Local layer only.** Portable laws live in **`docs/37_GODS_EYE.md`** (vendored or at `$GODS_EYE_ROOT`).

This file holds **this project's** vocabulary, boundaries, and disambiguation. Do not duplicate portable content — cross-link the Bible.

**Router:** `docs/GODS_EYE_GRAND_SPEC.md` (if present)

**Default posture:** **Tier C — Creator-Innovator** (Bible §10). Product/QA win on product boundaries.

---

## 1. Vocabulary (this repo)

| Term | Meaning |
|------|---------|
| **Always Sync** | `git pull` before work; `git push` after every commit — no local-only state (Bible §2.9) |
| **Governed Bypass** | Any rule may be bypassed only with explicit user approval first; log the bypass (Bible §2.9) |
| **Local mode** | LM Studio execution — serial only, no subagents, strict context pruning (Bible §2.9) |
| **Cloud mode** | Cloud frontier model — parallel reads, subagents allowed, fresh thread at 80% (Bible §2.9) |

---

## 2. Product boundary

| Rule | Detail |
|------|--------|
| **Bundle constants** | Bath Towel 5, Bath Mat 10, Hand Towel 20, Washcloth 50, Pillow Case 50, sheets/covers 5 — locked in `BundleLibrary` |
| **Tower defaults** | Lagoon 21, GI 32, GW 31, Diamond 15, Alii 14 (+ Tapa, Rainbow in seed) |
| **Calculations** | Services only — never in SwiftUI views |
| **Daily logs** | Immutable encoded snapshots — never live `@Model` refs |
| **App Group** | `group.com.himmerflow.shared` (legacy `group.com.linenflow.shared` migration) |
| **URL schemes** | `himmerflow://` + `linenflow://` (legacy widgets) |
| **Linen tab** | Tab 0 = `HomeView` — one-screen `OneScreenLinenItemCard` grid (not wizard) |
| **Private repo** | Do not publish to public GitHub without explicit Brent approval |
| **Android parallel build** | **OUT OF SCOPE** — no Track K / `android/**` agents; see `Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml` |

---

## NightRaven stack (God's Eye + Core)

| Term | Meaning |
|------|---------|
| **God's Eye** | Portable agent memory — Bible, handoff, hooks, +# chain |
| **NightRaven Core** | Adaptive orchestration — `.claude/skills/nightraven/SKILL.md`; invoke with `/nightraven <task>` |
| **Grav Nightraven** | Shorthand for **God's Eye + NightRaven Core** together (memory + orchestration) |
| **Full build** | [`Docs/BUILD_PLAN_FULL.md`](../Docs/BUILD_PLAN_FULL.md) + [`Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml`](../Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml) |
| **Coordination** | [`AGENT_WORK_LOG.md`](../AGENT_WORK_LOG.md) (uppercase Docs = product docs; lowercase docs/ = God's Eye chain) |
| **Stack rule** | God's Eye remembers; NightRaven Core coordinates execution. Do not collapse memory chains. |

**LinenFlow product names:** HimmerFlow (Xcode scheme/target), LinenFlow (repo folder), Linen tab (attendant workflow).

---

## 3. Connected chain (this repo)

| Layer | Path |
|-------|------|
| Rule | `.cursor/rules/gods-eye-context-intent.mdc` |
| Bible | `docs/37_GODS_EYE.md` or `$GODS_EYE_ROOT` |
| Overlay | this file |
| Handoff | `docs/14_SESSION_HANDOFF.md` |
| Entry | `AGENTS.md` |
