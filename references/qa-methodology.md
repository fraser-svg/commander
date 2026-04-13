# QA Methodology

Ported and generalized from `revfactory/harness/references/qa-agent-guide.md`. The core insight is load-bearing: most real-world bugs in agent-built systems are **boundary mismatches** — API response shape vs consumer type, field-name case drift (camelCase vs snake_case), file path vs router reference, state transition map vs actual update code. Catching them requires reading both sides simultaneously, not checking each side in isolation.

## Core principle: read both sides

QA's job is not "does X exist?" — it's "does X on one side match its consumer on the other side?"

Examples of cross-boundary checks:
- API route's `NextResponse.json()` shape vs the hook's generic type on the consumer
- Database schema field names vs ORM model properties
- Router `href`/`router.push` strings vs actual file paths
- State machine transition map vs every call site that updates state
- Event emitter payload shape vs every subscriber's handler signature
- Config schema vs every key access site

The QA agent reads both sides **in one pass** and diffs them. A single-sided check (does the API return JSON? yes) misses contract drift (does the API return the shape the consumer expects? no).

## QA as parallel sub-agent, not team member

QA does not join the team. QA is a parallel sub-agent the orchestrator invokes on module-completion checkpoints.

Protocol:
1. Orchestrator defines QA checkpoint conditions in the plan ("after each module write, before next module starts")
2. On module completion, orchestrator launches QA as a parallel sub-agent with the module artifact as input via `run_in_background`
3. QA runs independently — no team membership, no `SendMessage` access
4. QA emits structured report: `PASS | WARN | BLOCK`
5. Orchestrator polls QA completion before assigning next module
6. `BLOCK` halts downstream chain. `WARN` logs + continues. `PASS` clears checkpoint
7. QA has read access to team's output surface (files) but no write access

This resolves the upstream contradiction where "team mode default" collided with "QA runs incrementally per module." Team agents work in parallel; QA validates incrementally without joining the team's communication channel.

## Incremental QA, not end-stage QA

Anti-pattern: QA runs once at the end of the orchestrator's final phase.

Failure mode: bugs accumulate. Each module built on top of a broken upstream module inherits the break. Fixing at the end means untangling coupled failures across the whole chain — expensive.

Correct: QA runs after every module's final write. The orchestrator pauses the downstream chain until QA returns.

## QA agent type

QA agents must be `general-purpose` subagent type, never `Explore`. Rationale:
- `Explore` is read-only; QA needs to run verification scripts (grep, cross-file diff, shell-based assertions)
- QA often needs to write a structured report to `_workspace/`
- `general-purpose` supports Bash, which is required for deterministic checks

Model: **Haiku 4.5**. QA is pattern matching against a rubric and emitting structured output — Haiku is sufficient and ~5× cheaper than Opus.

## Six boundary-mismatch categories to check

1. **API response shape ↔ consumer type.** Read the API handler and every hook/fetch site. Diff the shapes.
2. **Field name case drift.** Database/schema uses `snake_case`; frontend uses `camelCase`. Check every transformation layer.
3. **File path ↔ router reference.** Every `href=` and `router.push()` must point to a file that actually exists.
4. **State transition map ↔ update code.** If the state machine says `template_draft → template_approved`, there must be code that actually sets `template_approved`.
5. **Event payload ↔ subscriber signature.** Emitter's payload shape must match every `.on(event)` handler's expected type.
6. **Config schema ↔ access sites.** Every `config.get('key')` must reference a key that exists in the schema.

## QA output format

Every QA run emits a structured JSON report to `_workspace/<run-id>/qa/<module-name>.json`:

```json
{
  "module": "newsletter-writer",
  "verdict": "PASS | WARN | BLOCK",
  "checks_run": 6,
  "issues": [
    {
      "severity": "block | warn | info",
      "category": "api_shape_mismatch",
      "evidence_a": { "file": "api/route.ts", "line": 42, "snippet": "NextResponse.json({ id, title })" },
      "evidence_b": { "file": "hooks/useNewsletter.ts", "line": 18, "snippet": "useSWR<{id, title, author}>" },
      "diff": "consumer expects 'author' field; API never returns it"
    }
  ],
  "next_action": "fix api/route.ts line 42 OR remove author from consumer type"
}
```

## Trigger eval protocol (applies to every generated skill)

Separate from QA, but uses the same binary-rubric discipline.

**Procedure:**
1. Collect 10 should-trigger queries and 10 near-miss queries
2. Present each query to the skill selector in isolation
3. Record: triggered / did not trigger. Binary only
4. If using LLM-as-judge: run each query twice with position-swapped candidate ordering. Flag any reversal as failure regardless of individual answers
5. Pass threshold: 9/10 should-trigger, 9/10 near-miss rejections
6. Report: `PASS [n/10 trigger, n/10 near-miss]` or `FAIL — see failures list`

**What makes a good near-miss:** shares keywords or domain words with the skill but resolves to a different tool. "Review this code for bugs" and "create a new skill for web search" are good near-misses for commander — they share words but belong to code-reviewer and skill-god respectively. "Write a prime number function" is a bad near-miss — it shares no surface with commander at all.

## Do not use Likert scales

Binary rubrics only. 1–10 scales drift across evaluators and across runs. Use PASS/FAIL with specific evidence. If you need granularity, add more binary checks — don't widen the scale.
