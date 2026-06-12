# God's Eye MCP setup (Phase 2)

Optional **Model Context Protocol** tools expose the git-backed memory chain to Cursor agents without replacing handoff, changelog, or overlay as source of truth.

**Git wins:** MCP reads and appends (+# only) to L3 docs. Any external index (Mem0/Zep) remains optional L4 — see [`GODS_EYE_UNIFIED_STACK.md`](GODS_EYE_UNIFIED_STACK.md) §6.

---

## Tools

| Tool | Purpose |
|------|---------|
| `gods_eye_list_memory_slots` | List handoff, changelog, overlay, Bible, etc. with paths |
| `gods_eye_get_read_order` | Return Touch 1 parallel read batch |
| `gods_eye_read_memory` | Read one memory doc by slot id |
| `gods_eye_search_memory` | Substring search across memory docs (dedup) |
| `gods_eye_append_recent_session` | Append one **Recent sessions** line (+# only) |

---

## One-time build

From the God's Eye install root (this repo or `$GODS_EYE_INSTALL_ROOT`):

```bash
cd mcp-server
npm install
npm run build
```

Verify:

```bash
node mcp-server/dist/index.js
# Ctrl+C — stdio server waits for MCP client
```

---

## Project install (Cursor)

When you run `./install.sh` on a bootstrapped project, it copies:

- `.cursor/mcp.json` — MCP server registration
- `.cursor/mcp/run-gods-eye-mcp.js` — cross-platform launcher (runs natively on Windows, macOS, Linux)
- `.cursor/mcp/run-gods-eye-mcp.sh` — bash fallback launcher

**Enable in Cursor:**

1. **Cursor Settings → MCP** — confirm `gods-eye` appears (green).
2. Open a new Agent chat in the bootstrapped project.
3. Ask the agent to call `gods_eye_list_memory_slots` or `gods_eye_read_memory` with `slot: handoff`.

If the server fails to start, build `mcp-server/` as above. The launcher prints the exact path it expects.

---

## Manual `.cursor/mcp.json`

```json
{
  "mcpServers": {
    "gods-eye": {
      "command": "node",
      "args": [".cursor/mcp/run-gods-eye-mcp.js"]
    }
  }
}
```

Set `GODS_EYE_INSTALL_ROOT` in the MCP env block if the portable Bible lives outside the project:

```json
{
  "mcpServers": {
    "gods-eye": {
      "command": "node",
      "args": [".cursor/mcp/run-gods-eye-mcp.js"],
      "env": {
        "GODS_EYE_INSTALL_ROOT": "/path/to/gods-eye",
        "GODS_EYE_PROJECT_ROOT": "/path/to/your-app"
      }
    }
  }
}
```

---

## Path resolution

The server resolves paths in this order:

| Variable | Role |
|----------|------|
| `GODS_EYE_PROJECT_ROOT` | App repo (handoff, overlay, changelog) |
| `CURSOR_PROJECT_DIR` | Cursor workspace fallback |
| `GODS_EYE_ROOT` / `GODS_EYE_INSTALL_ROOT` | Portable Bible when not vendored in project |

Portable L2 docs (`bible`, `router`, `session_tree`) fall back to `$GODS_EYE_ROOT` when missing in the project tree.

---

## Operating rules

- **`+#` only** — `gods_eye_append_recent_session` inserts under **Recent sessions**; it refuses shrink/delete.
- **This repo only** — no cross-repo handoff bleed; one MCP instance per workspace.
- **Tier 0–1** — optional; parallel doc reads remain sufficient for small tasks.
- **Mem0/Zep** — separate optional L4; ingest from git, never shadow writes.
- **Mode-agnostic** — MCP tools work identically in local (LM Studio) and cloud mode. Execution mode governs agent parallelism and context discipline, not the MCP API itself — see [`GODS_EYE_LOCAL_VS_CLOUD.md`](GODS_EYE_LOCAL_VS_CLOUD.md) §4.

---

## Related

- [`HOOKS_SETUP.md`](HOOKS_SETUP.md) — Phase 2 soft hooks
- [`CURSOR_INSTALL.md`](CURSOR_INSTALL.md) — full install flow
- [`GODS_EYE_UNIFIED_STACK.md`](GODS_EYE_UNIFIED_STACK.md) — Phase 2 hooks + MCP roadmap
- [`GODS_EYE_LOCAL_VS_CLOUD.md`](GODS_EYE_LOCAL_VS_CLOUD.md) — local vs cloud agent discipline (§4 governs parallelism, not MCP API)
