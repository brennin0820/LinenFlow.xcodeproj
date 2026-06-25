#!/bin/bash
# SessionStart hook — loads the God's Eye memory chain into context so every new
# Claude Code (web) chat "pulls previous memories". The original chain only had
# Cursor hooks (.cursor/hooks.json), which never run under Claude Code, so new
# web sessions started cold. This injects the session handoff + memory tails as
# additionalContext at session start.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$ROOT"

emit() { [ -f "$1" ] && { printf '\n===== %s =====\n' "$1"; cat "$1"; }; }
tail_doc() { [ -f "$1" ] && { printf '\n===== %s (tail) =====\n' "$1"; tail -n "${2:-25}" "$1"; }; }

CONTEXT="$(
  printf 'GOD'\''S EYE MEMORY — auto-loaded at session start (this repo only).\n'
  printf 'Read order: AGENTS.md laws -> Docs/37_GODS_EYE.md -> Docs/GODS_EYE_REPO_OVERLAY.md -> session handoff below.\n'
  emit "Docs/14_SESSION_HANDOFF.md"
  tail_doc "Docs/02_ENGINEERING_CHANGELOG.md" 20
  tail_doc "Docs/04_LEARNING_LOG.md" 20
  tail_doc "Docs/ledgers/BUILD_LEDGER.md" 15
  tail_doc "Docs/ledgers/AUDIT_LEDGER.md" 15
)"

jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
