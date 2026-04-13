# Caching and Cost Engineering

Prompt caching is mandatory for every orchestrator commander generates. Upstream `revfactory/harness` ignored caching entirely and ran every agent on Opus — a 10–15× cost inflation vs current best practice on a modal run. Commander cuts that to ~7× cheaper via caching + routing.

## What to cache

Place `cache_control: {"type": "ephemeral"}` markers on:

- **System prompt body** — stable across turns within a run, cached across runs
- **Agent definition block** — the `.md` file content, identical every invocation
- **Reference files** injected at agent load time (style guides, API specs, rule files)
- **Shared context** — repo map, project README, global constraints

Do **not** cache:

- Per-task user instruction (the actual job) — always fresh, always at the end of context
- Tool call results — dynamic, unique per run
- Conversation turns after task starts
- Timestamps, run IDs, dynamic env vars

## Cache pricing

- **Cache write:** 1.25× base input rate (1-time cost when writing to cache)
- **Cache read:** 0.1× base input rate (90% discount on cache hits)
- Cache TTL: ephemeral (default ~5 min), extends on each hit

## Expected cache hit ratios

On a 3-agent team with ~11k–15k input tokens per agent where ~13k of that is stable prompt:
- Writer: 89.9% cached
- Reviewer: 83.6% cached
- Publisher: 78.8% cached

Effective input cost on repeat runs: ~75% cheaper than no caching.

## Batch API

For non-user-facing work, use the Batch API for an additional 50% discount. Stacked with caching, savings reach ~95% on eval sweeps and regression tests.

**Use batch if:**
- Task is not user-facing (no interactive output expected)
- Result latency ≤24h acceptable
- Task type in {eval_run, trigger_validation, regression_test, rubric_score, classification_sweep}
- User has not passed `--live` flag

**Use live if:**
- Orchestrator is user-facing (terminal session, chat response)
- Task requires result within current session
- Task type in {main_build, integration, planning, publishing}
- Downstream agent depends on this result synchronously

Commander emits a `_batch_queue/` directory of JSONL request files when batch mode activates; `flush-batch.sh` submits on demand or schedule.

## 200k context cliff

Opus past 200k costs 2× input / 1.5× output. Check on every agent invocation:

```
estimated_context = sum(
  system_prompt_tokens,
  skill_body_tokens,
  injected_reference_tokens,
  task_instruction_tokens,
  projected_tool_result_tokens,
  conversation_history_tokens
)

if estimated ≤ 150k:      proceed normally
if 150k < estimated ≤ 180k:  WARN, log to run.log
if 180k < estimated ≤ 200k:  FORCE DOWNGRADE Opus→Sonnet unless role is planner/architect/high-stakes
if estimated > 200k on Opus: REFUSE, halt orchestrator
```

150k ceiling leaves 50k headroom for tool results and conversation growth mid-run.

## Modal 3-agent cost comparison

Task: "build me a content harness with writer, reviewer, publisher." Assumptions: writer 12k-in/3k-out, reviewer 10k-in/1k-out, publisher 8k-in/500-out.

| Scenario | Writer | Reviewer | Publisher | Total |
|---|---|---|---|---|
| Upstream (all Opus, no cache) | $0.135+$0.075 | $0.050+$0.025 | $0.040+$0.0125 | **$0.338** |
| Upstream + double-eval | ×2 | | | **$0.478** |
| Commander (70/20/10 + caching) | Sonnet 85% cache: $0.019+$0.045 | Haiku 83% cache: $0.002+$0.005 | Haiku 79% cache: $0.002+$0.003 | **$0.076** |
| Commander + batch eval | unchanged | $0.001+$0.0025 | $0.001+$0.0015 | **$0.067** |

Upstream vs commander with double-eval: **7.1× cheaper**.

## Trap list — enforced by orchestrator

| Trap | Detection | Auto-fix |
|---|---|---|
| Reviewer on Opus | role ∈ {reviewer, QA, classifier, formatter, extractor} AND model=opus | Force Haiku, warn |
| Missing cache_control on stable block >1000 tokens | No marker in stable block | Inject at first stable boundary |
| Team for 2-agent task | `TeamCreate` with agent_count ≤2 | Rewrite as sequential/parallel sub-agents |
| Silent 200k cliff | Context estimate crosses 200k without pre-flight check | Pre-flight mandatory; refuse without it |
| Batch mode on user-facing call | batch=true AND session=interactive | Force live, error |
| Double-eval | Same task + same input hash dispatched twice | Deduplicate, suppress second |
| Plan-mode on Haiku worker | Haiku-tier role + thinking_mode=enabled | Strip thinking block |
| Runaway parallel fan-out | >5 `run_in_background` in single turn | Cap at 5, queue remainder, warn |
| Re-injected references without cache | Same ref file on consecutive calls without marker | Hash + cache on first injection |
| Missing post-run cost log | Run exits without writing to run.log | Mandatory post-hook blocks exit until flush confirmed |
