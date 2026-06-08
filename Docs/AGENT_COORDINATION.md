# Agent Coordination Protocol

Short reference for humans and coding agents working in parallel on LinenFlow.

**Authoritative lock file:** [`AGENT_WORK_LOG.md`](../AGENT_WORK_LOG.md) (repo root)

**Master plan:** [`docs/superpowers/plans/2026-06-08-linen-tab-master-plan.md`](superpowers/plans/2026-06-08-linen-tab-master-plan.md)

**Cursor rule:** `.cursor/rules/agent-file-coordination.mdc` (always applied)

---

## Why

Parallel agents editing the same Swift file causes merge conflicts and lost work. The Linen tab concentrates risk in a few large files (`HomeView.swift`, `FlowViewModel.swift`, `project.pbxproj`).

---

## Protocol: claim → edit → verify → release

### 1. Claim

Before creating or modifying any file:

1. Open `AGENT_WORK_LOG.md`.
2. Scan **File Lock Registry** and **Active Claims**.
3. If your file is locked by another agent → **stop**; wait or ask the parent.
4. Add a row to **Active Claims**: agent ID, task summary, **exact paths**, status `ACTIVE`, start time.
5. Add each path to **File Lock Registry**.

New files must be listed **before** they exist on disk.

### 2. Edit

- Touch **only** files you claimed.
- One agent per `.swift` source file.
- Follow the **File Ownership Map** in the master plan for track boundaries.
- Do not revert another agent's in-progress changes.

### 3. Verify

Before releasing:

- Run build and/or tests appropriate to your change (see master plan Verification Gates).
- Record command output summary in **Completed Work**.

### 4. Release

1. Move your **Active Claims** row to **Completed Work** (include verification).
2. Remove your entries from **File Lock Registry**.
3. Set status to completed with date.

---

## Conflict hotspots

| File | Rule |
|------|------|
| `LinenFlow/Views/HomeView.swift` | One active agent only |
| `LinenFlow/ViewModels/FlowViewModel.swift` | One active agent only |
| `LinenFlow.xcodeproj/project.pbxproj` | One active agent only; coordinate audit vs feature agents |

---

## Currently active agents (2026-06-07)

| Agent ID | Owns (summary) |
|----------|----------------|
| `a7618ee3` | `OneScreenLinenItemCard`, `PremiumExpressionInput`, `KeyboardPinnedEditorShell` |
| `f19a62cd` | `HomeView`, wizard/Legacy views, `project.pbxproj` |
| `9e5546a4` | `FlowViewModel`, `ShiftCommandCenterView`, `FloorChecklistView`, `FloorDetectionCard` |
| `50fed4e9` | Audit/build/install (advisory on `project.pbxproj`; prefer after feature agents finish) |

Always re-read `AGENT_WORK_LOG.md` — this table may be stale after releases.

---

## Parent agent instructions

When dispatching a subagent:

1. Paste: *"Read `AGENT_WORK_LOG.md` and `docs/AGENT_COORDINATION.md`. Claim your files before editing. Do not touch ACTIVE locks."*
2. Assign non-overlapping files using the master plan **File Ownership Map**.
3. Never schedule two agents on `HomeView.swift` or `FlowViewModel.swift` simultaneously.
4. Serialize `project.pbxproj` edits (wizard agent vs audit agent).
5. After subagents complete, confirm locks are released before starting overlapping work.

---

## Example claim (markdown)

```markdown
| `my-agent-id` | Phase 11 VoiceOver on card | `LinenFlow/Views/Flow/OneScreenLinenItemCard.swift` | **ACTIVE — do not touch** | 2026-06-07 |
```

Remove from Active Claims and File Lock Registry when done.

---

## Quality Gate

Before marking work complete or releasing locks:

1. **Read before edit; minimal diff** — Open each file you will change; touch only what the task requires.
2. **Build after Swift changes** — Run an Xcode build (`xcodebuild` or equivalent) and confirm it succeeds before moving your claim to **Completed Work**.
3. **Test before release** — Run relevant tests (`xcodebuild test` with the appropriate scheme/destination) before releasing locks on Swift or project changes.
4. **No commits unless asked** — Do not `git commit` unless the user explicitly requested it.
5. **Respect Active Claims** — Do not edit paths listed in `AGENT_WORK_LOG.md` **Active Claims** or **File Lock Registry** owned by another agent.
6. **Real device when required** — Some features cannot be verified on Simulator (e.g. barometer / floor detection needs a physical **iPhone**). Note device vs simulator in verification.
7. **Honest reporting** — Report failures as-is; do not claim build or test success without actual command output in **Completed Work**.
