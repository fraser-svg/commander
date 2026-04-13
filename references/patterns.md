# Architectural Patterns

Six DAG-shaped patterns. Pick one in Phase 2 after choosing the escalation tier. Each pattern has required roles, exit conditions per node, and failure recovery.

## Pattern 1 — Pipeline

Use when stages have strict sequential dependency. Each stage consumes prior output.

```
[Input] → [Stage A] → [Stage B] → [Stage C] → [Output]
```

- Roles: stage agents, each specialized
- Exit per node: output artifact passes schema validation before forwarding
- Failure recovery: retry node max 2, then abort. If node 2 fails after retry, re-run from node 1 with revised prompt.

## Pattern 2 — Fan-out / Fan-in

Use when ≥2 independent tasks merge into a single artifact. Classic map-reduce.

```
            ┌→ [Worker A] ─┐
[Splitter] → [Worker B] ─→ [Merger] → [Output]
            └→ [Worker C] ─┘
```

- Roles: splitter (orchestrator), N workers (parallel sub-agents via `run_in_background`), merger
- Exit per node: workers complete independently; merger waits for all
- Failure recovery: failed worker retried once in isolation; if retry fails, merger proceeds with partial outputs and flags the gap in HANDOFF.md

## Pattern 3 — Expert Pool

Use when tasks require routing to specialized agents based on task type. Input set is heterogeneous.

```
[Queue] → [Router] → {Expert A | Expert B | Expert C} → [Collector]
```

- Roles: router (classifies and dispatches), experts (domain-specific), collector (aggregates)
- Exit per node: router assigns task to exactly one expert; expert returns structured output; collector signals done when queue empty
- Failure recovery: router re-classifies failed task and routes to fallback expert. Max 2 reroutes.

## Pattern 4 — Generator-Evaluator

Use for high-value outputs that need external validation. Never let an agent grade its own work.

```
[Generator] → [Draft] → [Evaluator] → (Accept | Revise)
                    ↑___________________________|
```

- Roles: generator produces output, evaluator is a different agent with a different prompt
- Exit per node: evaluator emits `ACCEPT` with score or `REVISE` with structured critique
- Loop bounded at N=3 rounds. Round 4+ takes best-scoring draft + `[FLAGGED: did not reach ACCEPT in 3 rounds]` and escalates to human.
- Accept criteria defined by orchestrator before loop starts, not by generator.

**Evaluator prompt skeleton:**
```
You are an independent evaluator. You did NOT produce the output below.
<output>{{generator_output}}</output>
<criteria>{{accept_criteria}}</criteria>
Respond with: VERDICT (ACCEPT|REVISE), SCORE 1-10, CRITIQUE bullets, REQUIRED_CHANGES.
Do not rewrite. Only evaluate.
```

## Pattern 5 — Supervisor

Use when one coordinator must maintain global state and assign sub-tasks dynamically based on emerging results.

```
           ┌→ [Worker A] ─┐
[Supervisor] → [Worker B] ─→ [Supervisor] (re-routes based on results)
           └→ [Worker C] ─┘
```

- Roles: supervisor maintains task queue and global state; workers are stateless
- Exit per node: supervisor polls worker completion, updates state, assigns next task; terminates when queue empty and all outputs validated
- Failure recovery: supervisor detects stuck worker via timeout; re-assigns task to different worker; logs failure

## Pattern 6 — Hierarchical

Use for complex domain decomposition where sub-domains have internal parallelism but must coordinate at the top level.

```
[Orchestrator]
  ├→ [Sub-Orch A] → [Worker A1, A2]
  ├→ [Sub-Orch B] → [Worker B1, B2]
  └→ [Merger]
```

- Roles: top orchestrator owns the plan; sub-orchestrators manage domain-specific fan-outs; merger reconciles across domains
- Exit per node: sub-orchestrators emit completion signals; top orchestrator merges only after all sub-orchestrators complete
- Failure recovery: failed sub-orchestrator retried once with simplified scope; if retry fails, top orchestrator marks domain partial and flags for human review

## Decision tree

```
Is the task a single coherent unit?
├─ YES → use skills alone, no orchestration
└─ NO → are tasks structurally independent (no shared intermediate state)?
   ├─ NO → sequential dependency?
   │  ├─ YES → Pipeline
   │  └─ NO → real-time peer feedback?
   │     ├─ YES → Supervisor (if global state) or Hierarchical (if domain decomposition)
   │     └─ NO → Generator-Evaluator (if output is high-value)
   └─ YES → how many independent tasks?
      ├─ 2 → parallel sub-agents, not a team
      ├─ ≥3 homogeneous → Fan-out/Fan-in
      ├─ ≥3 heterogeneous → Expert Pool
      └─ ≥3 with high-value merged output → Fan-out/Fan-in + Generator-Evaluator on merger output
```

## Team size rules

- **Minimum team = 3.** Two agents = parallel sub-agents via `run_in_background`, not `TeamCreate`.
- **Maximum team = 5.** Beyond 5, split into hierarchical sub-teams.
- If output is high-value: include at least 1 evaluator role (read-only relative to generator).
- Never symmetric roles (two agents doing the same thing) — that's fan-out, not a team.

## CoVe (Chain of Verification) — integrated into Generator-Evaluator

For critical outputs, run CoVe inside each Gen-Eval round:

1. **Generate** — generator produces the artifact
2. **Question** — orchestrator (not generator) derives ≤10 verification questions targeting factual claims, logic dependencies, edge cases
3. **Answer independently** — critic agent answers each question **without reading the artifact** (prevents anchoring)
4. **Revise** — orchestrator diffs critic answers against generator claims; discrepancies become a revision brief; generator revises only flagged sections

Bounded: CoVe runs once per Gen-Eval round, max 3 rounds total, ≤10 questions per round.

## Stuck-state detection and recovery

- **Bounded retries:** max 2 per node. Retry 1 = same prompt with error context. Retry 2 = simplified prompt with reduced scope. No retry 3.
- **Structured retry block** (orchestrator writes before retry): what failed, hypothesis for why, what's different this time. Retrying without this block is prohibited.
- **Budget exhaustion:** track token estimate per agent. If remaining budget < (tasks remaining × avg task cost), halt new launches, complete in-flight agents, report partial completion.
- **Stuck-state:** agent not emitting output in >2× expected duration = send probe. No response in 1 probe cycle = cancel and replace with fresh agent instance. Max 1 replacement per agent slot.
