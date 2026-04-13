# HANDOFF.md Protocol

Every orchestrator run ends with a `HANDOFF.md` written to `_workspace/HANDOFF.md`. This is the single source of truth for "what's done and what's next." A new session reads only this file to understand prior state — no transcript review needed.

`HANDOFF.md` is:
- **Always at `_workspace/HANDOFF.md`** (never in a run subdirectory)
- **Overwritten at end of every phase**, not just at end of run
- **Never auto-deleted** — even `workspace-rotate.sh` preserves it
- **Written by Claude directly** from `assets/handoff-template.md`, no separate script

## Required fields

```markdown
# HANDOFF — <harness-name>
Run ID: <YYYYMMDD-HHMMSS-slug>
Session ended: <ISO timestamp>
Status: COMPLETE | PARTIAL | FAILED

## Built
- [x] <artifact 1>
- [x] <artifact 2>
- [x] <agent file N of M>

## Incomplete
- [ ] <artifact not reached>
- [ ] <agent definition blocked on skill-god>

## Resume From
Phase: <N>
Checkpoint: _workspace/checkpoints/p<N>_<name>.json
Command: invoke `<orchestrator-name>` — it will auto-detect checkpoint

## Incomplete Worktrees
- <path to worktree> (branch: <branch-name>) — merge manually or re-run

## Env State
- Relevant env vars: <list>
- External deps installed: <list>

## Cost Summary
- Phase 0–N total: ~$<amount>
- Projected remaining: ~$<amount>

## Next Session Notes
<Any human decisions pending. Any blockers to describe. Short.>
```

## Status values

- **COMPLETE**: all phases finished, all artifacts produced, no blockers
- **PARTIAL**: some phases finished but the run didn't reach Phase 7. Resumable.
- **FAILED**: a phase hit a hard error the retry policy couldn't resolve. Not resumable without human intervention.

## Resume protocol

A new session that finds `HANDOFF.md` with status=PARTIAL reads the `Resume From` field and:
1. Jumps to that phase
2. Reads the referenced checkpoint file
3. Re-runs only the incomplete nodes
4. Does not re-execute phases listed in `Built`

If `Next Session Notes` contains a question for the user, the session surfaces it before touching any file.

## HANDOFF.md is a stateless contract

It is valid to lose all session history as long as `HANDOFF.md` + `_workspace/checkpoints/` survive. The harness must resume from these two artifacts alone. If you cannot resume without reading the prior conversation transcript, the handoff is malformed.

## Tiered memory model

Commander distinguishes four tiers of memory, each with a different persistence and location:

| Tier | Contents | Location | Persistence |
|---|---|---|---|
| Session | In-conversation messages, tool results | Context window | Ephemeral |
| Episodic | Past run summaries, phase artifacts | `_workspace/<run-id>/` | Preserved until rotation |
| Semantic | User facts, project conventions | `CLAUDE.md`, `harnesses.json` | Cross-session |
| Procedural | Workflow instructions | `.claude/skills/<harness-name>/orchestrator/SKILL.md` | Version-controlled |

`HANDOFF.md` is the bridge from Episodic back into Session on resume.

## What goes in CLAUDE.md (Procedural-only)

```markdown
## Harnesses
This project uses the <harness-name> harness built by commander.
Registry: .claude/harnesses.json
Workspace: _workspace/
Worktrees: .worktrees/
Do not edit files under .claude/agents/<harness-name>/ manually.
Do not delete _workspace/HANDOFF.md.
```

No trigger language. No agent lists. No skill lists. No workflow rules. The orchestrator's own description handles triggering; `.claude/agents/` and `.claude/skills/` hold the structure.
