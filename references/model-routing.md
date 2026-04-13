# Model Routing — 70/20/10 Haiku/Sonnet/Opus

Defaults per agent role. Non-negotiable. Never put a reviewer on Opus. Never put an architect on Haiku.

## Pricing (April 2026)

| Model | Input ($/M tokens) | Output ($/M tokens) | Context |
|---|---|---|---|
| Haiku 4.5 | $1.00 | $5.00 | 200k |
| Sonnet 4.6 | $3.00 | $15.00 | 200k |
| Opus 4.6 (≤200k) | $5.00 | $25.00 | 200k |
| Opus 4.6 (>200k) | $10.00 | $37.50 | cliff at 200k |

Cache writes: 1.25× input rate. Cache reads: 0.1× input rate (90% discount on cache hits). Batch API: 50% discount on both input and output (async within 24h).

## Per-role routing table

| Role | Tier | Model | Rationale |
|---|---|---|---|
| planner | Opus | Opus 4.6 | DAG decomposition, cross-agent dep resolution |
| architect | Opus | Opus 4.6 | System design, irreversible structural choices |
| high-stakes-decision | Opus | Opus 4.6 | Eval gates, go/no-go on deployment |
| main-coder | Sonnet | Sonnet 4.6 | Core impl, multi-file, best coding model |
| integrator | Sonnet | Sonnet 4.6 | Cross-service wiring, API plumbing |
| researcher | Sonnet | Sonnet 4.6 | Synthesis tasks needing broad reasoning |
| writer | Sonnet | Sonnet 4.6 | Long-form content generation |
| builder | Sonnet | Sonnet 4.6 | Feature impl, iterative build loops |
| debugger | Sonnet | Sonnet 4.6 | Root cause analysis requires context |
| reviewer | Haiku | Haiku 4.5 | Pattern match against rubric |
| QA-validator | Haiku | Haiku 4.5 | Pass/fail assertion, structured output |
| classifier | Haiku | Haiku 4.5 | Label routing, minimal reasoning |
| triager | Haiku | Haiku 4.5 | Priority scoring, rule-based |
| formatter | Haiku | Haiku 4.5 | Schema enforcement, deterministic |
| extractor | Haiku | Haiku 4.5 | Structured field pull from text |
| summarizer | Haiku | Haiku 4.5 | Compression task, no synthesis |
| publisher | Haiku | Haiku 4.5 | Emit artifact, no generation |
| linter | Haiku | Haiku 4.5 | Rule application, static checks |

## ReWOO pattern

"Big model plans, small models execute." Planner (Opus) emits a full reasoning trace + step plan in one call. Each step is dispatched to Sonnet/Haiku workers that receive `{step_instruction, context_slice, expected_output_schema}` and execute without re-reasoning. Workers don't see the full plan — only their slice.

On a 5-step plan: 1 Opus call + 5 Haiku/Sonnet calls vs 6 Opus calls = roughly 6× cheaper on output alone.

## Override rules

Commander's verify-agent-def.sh enforces:
- If role is `reviewer | QA | classifier | triager | formatter | extractor | summarizer | publisher | linter`, model must be `haiku` — upgrade only with a `# WHY:` comment justifying it
- If role is `planner | architect | high-stakes-decision`, model is `opus`
- Everything else defaults to `sonnet`
- Any agent marked `opus` where the estimated input context > 150k is warned; > 180k forces downgrade to sonnet unless role is in the planner tier; > 200k is refused

## Cost budget gate

Every orchestrator run calls `estimate-cost.sh` before launching agents. If estimate > `$COST_GATE_THRESHOLD` (default $2.00), the orchestrator asks for user confirmation. Post-run actual cost is logged to `_workspace/run.log` for calibration.
