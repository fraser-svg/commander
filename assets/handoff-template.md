# HANDOFF — <harness-name>

Run ID: <YYYYMMDD-HHMMSS-slug>
Session ended: <ISO-8601 UTC timestamp>
Status: <COMPLETE | PARTIAL | FAILED>

## Built

- [ ] <artifact 1 — file path or description>
- [ ] <artifact 2>
- [ ] <agent file N of M>

## Incomplete

- [ ] <artifact not reached>
- [ ] <agent definition blocked on skill-god>
- [ ] <QA check not run>

## Resume From

Phase: <N>
Checkpoint: `_workspace/checkpoints/p<N>_<name>.json`
Command: invoke `<orchestrator-name>` — it will auto-detect the checkpoint.

## Incomplete Worktrees

- `<path/to/worktree>` (branch: `<branch-name>`) — merge manually or re-run

## Env State

- Relevant env vars: `<list>`
- External deps installed: `<list>`
- Git branch: `<branch-name>`

## Cost Summary

- Phases 0–<N> total: ~$<amount>
- Projected remaining: ~$<amount>
- Actual by model: Opus $<x>, Sonnet $<x>, Haiku $<x>
- Cache hit ratio: <%>

## Next Session Notes

<Any human decisions pending. Any blockers to describe. Keep short — if this section grows, decisions were deferred too long.>
