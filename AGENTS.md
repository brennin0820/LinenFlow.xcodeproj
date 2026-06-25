# AGENTS.md — project entry for coding agents

**Memory auto-loads at session start** via the Claude Code `SessionStart` hook
(`.claude/hooks/session-start.sh`), which injects `Docs/14_SESSION_HANDOFF.md`
and the memory tails into context. (Cursor users get the same via `.cursor/hooks.json`.)

**God's Eye chain (read in parallel when substantive work starts):**

1. `Docs/37_GODS_EYE.md` §0 — portable law (or `$GODS_EYE_ROOT/docs/37_GODS_EYE.md`)
2. `Docs/GODS_EYE_REPO_OVERLAY.md` — local vocabulary (if present)
3. `Docs/GODS_EYE_GRAND_SPEC.md` — router (if present)
4. This file → `Docs/14_SESSION_HANDOFF.md`

> Paths are **case-sensitive** on Linux (Claude Code on the web). The directory is
> `Docs/` (capital D); lowercase `docs/` resolves only on macOS/Windows.

**Laws:** `+#` only on memory docs · this repo only · Tier C default · **plan until code it** (Bible §2.8) · memory + wire before code unless the user names UI/copy/implementation.

**After meaningful work:** append handoff **Recent sessions**; Tier 2+ also changelog + learning log.

## NightRaven Core (orchestration)

- **Skill:** `.claude/skills/nightraven/SKILL.md` — adaptive Builder/Auditor orchestration
- **Ledgers:** `docs/ledgers/BUILD_LEDGER.md` · `docs/ledgers/AUDIT_LEDGER.md` (append-only)
- **Full build plan:** `Docs/BUILD_PLAN_FULL.md` — human-readable phased instructions (all tracks)
- **Runner:** `Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml` — machine phase index for `/nightraven`
- **When:** Multi-phase or full-project builds — Phase 0 Task Assessment before mutating files
- **Law:** God's Eye memory chain still authoritative; NightRaven Core does not replace handoff or Bible §2.8 ship signal
