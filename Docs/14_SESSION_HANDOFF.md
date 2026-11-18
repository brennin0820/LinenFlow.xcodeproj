# Session handoff

**Scope:** App memory for **this repository only**. Portable law: `docs/37_GODS_EYE.md` (or `$GODS_EYE_ROOT/docs/37_GODS_EYE.md`).

---

## Current state / focus

+# **LinenFlow / HimmerFlow** — iOS core **built** (283 tests); God's Eye + NightRaven wired 2026-06-11. **Full executable plan:** `Docs/BUILD_PLAN_FULL.md` + `Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml`. **Resume at:** Phase 17 (accessibility polish) — first `pending`/`partial` in runner YAML.

---

## Already done

+# Phases 0–16 — Xcode project through floor-sensing services, 5-tab shell, widgets, Linen one-screen cards (see `Docs/FinalReport.md`)
+# God's Eye + NightRaven Core install — rules, skill, ledgers, overlay (`2026-06-11`)
+# `Docs/BUILD_PLAN_FULL.md` — end-to-end phased build instructions for agents

---

## Recent sessions

+# **2026-11-18** — Calculator safety patch on `chatgpt/linen-calculator-safety-20261118`: centralized overflow-safe nonnegative multiplication, replaced floating-point ceiling division and unsafe `abs(Int.min)` logic, hardened bundle par capacity, and added 4 XCTest regression cases. Standalone Swift 6.2.1 quantity-math smoke checks passed (10/10). Full iOS `xcodebuild`/XCTest not run: Xcode unavailable in this environment. Preserve tower operational defaults and existing one-screen workflow; review CI before merging.
- **2026-06-11** — God's Eye + NightRaven install; authored `Docs/BUILD_PLAN_FULL.md` + `Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml` for **build entire thing** execution (`+#` only).

---

## Guardrails / locks

- **`+#` only** on memory docs — never `-#` or collapse **Recent sessions** / **Already done**
- **This repo only** — no cross-repo handoff bleed
