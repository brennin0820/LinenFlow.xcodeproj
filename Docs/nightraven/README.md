# NightRaven runner — LinenFlow

**Grav Nightraven** = God's Eye (memory) + NightRaven Core (orchestration).

| File | Role |
|------|------|
| [`LINENFLOW_BUILD_RUNNER.yaml`](LINENFLOW_BUILD_RUNNER.yaml) | Machine phase index — `status`, `depends_on`, NightRaven prompts |
| [`../BUILD_PLAN_FULL.md`](../BUILD_PLAN_FULL.md) | Human step-by-step instructions for every phase |

## Build entire thing (copy-paste)

```text
Read AGENTS.md, docs/14_SESSION_HANDOFF.md, Docs/BUILD_PLAN_FULL.md, and Docs/nightraven/LINENFLOW_BUILD_RUNNER.yaml.

/nightraven Execute LinenFlow full build — build the entire thing.

Execute every phase where status is pending or partial, in order, starting at current_phase in the YAML. CRITICAL complexity. Claim AGENT_WORK_LOG.md before edits. Append to docs/ledgers/BUILD_LEDGER.md.
```

## Refresh install

```bash
bash ~/Developer/gods-eye/scripts/install-gods-eye-nightraven.sh --no-mcp /Users/brentlenninorlanda/Developer/crazyboy
```
