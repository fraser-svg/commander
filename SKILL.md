---
name: commander
description: |
  Designs and builds complete agent teams with their skills for any domain.
  Use when: someone says "build me a team to...", "set up agents for...",
  "make a harness", "architect an agent workflow", "I need agents that can...",
  "design a multi-agent system", "create specialists for...", or asks to
  "update my harness", "add an agent", "audit the harness", "refactor my skill".
  Retriggers on: "tweak the orchestrator", "the agent is broken", "new skill for X".
  Do NOT use for: single-skill creation (use skill-god), one-off scripts,
  tasks a single agent handles cleanly, or when the user just wants a prompt
  template without any agent infrastructure.
  Produces: frontmatter + SKILL.md + references/ + scripts/ for every agent,
  plus an orchestrator that wires them together.
---

# Commander — Agent Team & Skill Architect

Commander is a meta-skill. Given a domain request, it produces a complete, cost-aware, secure agent team: agent definitions in `.claude/agents/<harness-name>/`, their skills in `.claude/skills/<harness-name>/`, and one orchestrator skill that wires them together via DAG. Skill creation is delegated to `skill-god` — commander never writes `SKILL.md` directly.

Tier-1 tool. Single-session subagents (`Agent` tool with `run_in_background`) or Agent Teams (`TeamCreate` + `SendMessage` + `TaskCreate`). Not a cloud agent runner. Not a multi-terminal coordinator.

## Mission

Replace the upstream `revfactory/harness` with a skill that:
- Defaults to the cheapest-correct execution mode (single-session → parallel sub-agents → team)
- Routes per-role across Haiku 4.5 / Sonnet 4.6 / Opus 4.6 via the 70/20/10 rule
- Caches stable prompt blocks with `cache_control` markers
- Enforces security deterministically via scripts and tool allow-lists, not instructions
- Emits a `HANDOFF.md` at the end of every run so sessions resume cleanly
- Supports multiple harnesses per project without namespace collisions

## Intake protocol

Before generating anything, confirm these with the user in plain language:
1. **Domain** — what task, in one sentence.
2. **Team size target** — 1 agent? 2–3? 3–5? (Maps to single-session / parallel / team.)
3. **Persistence** — one-shot run, or ongoing resumable work?
4. **Human-in-the-loop requirements** — which phases need user review?
5. **Output surface** — files, PR, published artifact, database write?

If ≥2 of (domain, team shape, output) are vague, invoke `superpowers:brainstorming` before proceeding. Concrete requests skip the brainstorm gate.

## 8-phase workflow

Each phase reads from and writes to `_workspace/<run-id>/<phase>/`. Every phase writes a checkpoint JSON file to `_workspace/<run-id>/checkpoints/p<N>_<name>.json` so a crashed session can resume.

### Phase 0 — Audit

Read existing harnesses in the target project. Write `audit_report.md`.

- Read `<project>/.claude/harnesses.json` (if it exists)
- Read `<project>/.claude/agents/` recursively
- Read `<project>/.claude/skills/` recursively
- Read `<project>/CLAUDE.md`
- Check for `<project>/_workspace/HANDOFF.md` — if present, prefer resuming over re-running earlier phases
- Detect drift: agents/skills on disk that aren't in `harnesses.json`, or vice versa
- Report summary to user, confirm plan before Phase 1

Branching:
- New build (no `harnesses.json`, no existing harness) → continue Phase 1
- Extension (existing harness, request to add) → jump to the relevant phase per the selection matrix
- Maintenance (audit/sync request) → stop after audit report, ask user what to reconcile

### Phase 1 — Domain analysis

Outputs: `domain_brief.md`, `entity_map.md`.

- Identify core task types (generate / validate / edit / analyze / publish)
- Read `~/.claude/skill-index.json` (built by `scripts/scan-skills.sh`) and flag reusable skills — do not generate a skill that duplicates an existing one
- If the task mentions >50 distinct work units, recommend running `ralphinho-rfc-pipeline` first and pause for user decision
- Detect user skill level from the conversation context; adjust downstream communication tone

### Phase 2 — Architecture design

Output: `arch_spec.md`, `escalation_decision.md`.

Graduated escalation ladder. Default is Tier 1; escalating requires written justification.

**Tier 1 — Single session with skills.** No agents spawned. Commander writes skills only and the user runs them inline. No justification needed.

**Tier 2 — Parallel sub-agents via `run_in_background`.** Required gates (all true):
- ≥2 structurally independent tasks
- No real-time peer feedback needed
- Estimated wall-clock saving >30%

**Tier 3 — Agent team (`TeamCreate` + `SendMessage` + `TaskCreate`).** Required gates (all true):
- ≥3 tasks requiring real-time peer review
- Outputs reference each other's intermediate state
- File-passing between sub-agents is genuinely insufficient

Write the choice + justification to `escalation_decision.md`. Omitting this file and jumping to Tier 3 is a spec violation.

Then pick one of six patterns from `references/patterns.md`: Pipeline, Fan-out/Fan-in, Expert Pool, Generator-Evaluator, Supervisor, Hierarchical.

### Phase 3 — Agent definition generation

Output: `<project>/.claude/agents/<harness-name>/<agent>.md` × N and `agent_roster.md`.

For every agent, use `assets/agent-template.md`. Required frontmatter:
- `name`
- `description` (pushy, under 150 words, with negative triggers)
- `model` (per `references/model-routing.md` — reviewer/QA/classifier → Haiku; builder/writer → Sonnet; planner/architect → Opus)
- `security:` block: `allowedTools`, `mcpServers`, `outputsSanitized`, `dataScope`, `bashPolicy`, `costBudgetUSD`, `canPush`, `canMutateFiles`
- `brevity:` constraint on non-length-sensitive outputs

Run `scripts/verify-agent-def.sh <file>` after writing each agent file. If it exits non-zero, halt and fix.

Agent definition files live at `.claude/agents/<harness-name>/<agent>.md` to prevent multi-harness namespace collision.

### Phase 4 — Skill generation via skill-god

Commander never writes `SKILL.md` for agent skills. It delegates to `skill-god`.

Procedure:
1. For each skill the team needs, write a skill spec JSON to `_workspace/<run-id>/skill-god/inbox/<skill-name>.json` using `assets/skill-spec-template.json`
2. Invoke skill-god via the Skill tool, passing the inbox path
3. Skill-god runs its grounding gate → draft → 5-criterion rubric → eval → ship and writes to `.claude/skills/<harness-name>/<skill-name>/`
4. Wait for the `p4_skills.json` checkpoint file before proceeding

**Bootstrap check:** if `~/.claude/skills/skill-god/` does not exist, error with exact install instructions and refuse to proceed. Do not fall back to writing skills directly. Skill-god is the single source of quality.

### Phase 5 — Orchestration

Output: `<project>/.claude/skills/<harness-name>/orchestrator/SKILL.md` with an embedded DAG.

The orchestrator's own `description` is the sole trigger mechanism. `CLAUDE.md` is context-loading only and must contain no "use this when..." language. See `references/orchestrator-template.md` for the DAG YAML shape.

The orchestrator must:
- Define every node with explicit `exit.success` and `exit.failure` conditions
- Set `cache_control` markers on stable prompt sections (system, agent definitions, reference files)
- Spawn git worktrees for any agent with `repo_writes: true` via `.worktrees/<agent-name>/`
- Check estimated context per agent against the 200k cliff before invocation
- Write `HANDOFF.md` at end of run using `assets/handoff-template.md`
- Call `scripts/workspace-rotate.sh` to compress old runs (keep last 3)
- Include Generator-Evaluator or CoVe for high-value outputs (see `references/patterns.md`)
- Launch QA as a parallel sub-agent on module checkpoints, never as a team member

Run `scripts/estimate-cost.sh` before starting any agent. If estimate > `$COST_GATE_THRESHOLD` (default $2.00), ask for confirmation.

### Phase 6 — Validation

Output: `validation_report.md`, `test_run.log`.

Mandatory checks before shipping:
- Every agent file passes `scripts/verify-agent-def.sh`
- Every skill has a pushy description under 150 words with negative triggers
- Every DAG node has `exit.success` and `exit.failure`
- `cache_control` markers present on all stable prompt blocks
- No agent is `model: opus` unless its role is planner/architect/high-stakes-decision
- `allowedTools:` is a concrete list, never empty, never "all"
- Trigger eval: 10 should-trigger + 10 near-miss queries. Binary pass/fail. Pass threshold 9/10 + 9/10. Position-swap if LLM-as-judge. See `references/qa-methodology.md` for protocol.
- Dry-run the DAG — every node's inputs map to a prior node's outputs; no dead links.

### Phase 7 — Evolution (honest version)

Phase 7 is a changelog the user maintains, not an auto-evolving system. After each run:
- Ask the user if anything should change. Don't force an answer.
- If the user provides feedback, map it to the right artifact using the table in `references/why.md` and edit only that artifact.
- Append the change to the project's `harnesses.json` `changelog` array with date + target + reason.
- Never claim "auto-trigger on 2× feedback" — that would require persistent state across sessions, which this skill does not have.

## Reference loading rules

Load these files only when the condition is met:

- `references/patterns.md` — always during Phase 2 or Phase 5
- `references/orchestrator-template.md` — during Phase 5
- `references/qa-methodology.md` — during Phase 6, or on audit requests
- `references/model-routing.md` — during Phase 3 when assigning models, or when team size >3
- `references/caching-and-cost.md` — during Phase 5 when wiring the orchestrator, or when the user asks about cost
- `references/security.md` — during Phase 3 when the team touches external APIs, user data, or filesystem writes
- `references/handoff-protocol.md` — during Phase 5 or whenever >1 agent is persistent across sessions
- `references/peer-skill-composition.md` — during Phase 1 when the team needs to call other installed skills
- `references/why.md` — during Phase 7 feedback mapping, or when justifying a rule that might violate the grounding gate

## Grounding gate (applies to every rule commander generates)

Before writing any rule into a generated skill or agent, ask:

> "If I deleted this rule and gave a blank prompt to Claude Sonnet 4.6 with only the task description, would the model fail to do this correctly more than 30% of the time?"

If no, drop the rule. If yes, keep it and add a `# WHY: <reason>` comment. The gate rejects rules that teach pre-trained behavior (what JSON is, what markdown headers do, how to be concise).

## Execution rules

- Model routing is non-negotiable. Never put a reviewer, QA, classifier, formatter, or extractor on Opus. Never put a planner/architect on Haiku. See `references/model-routing.md`.
- Every agent call must include `cache_control` markers on stable prompt blocks.
- Every generated agent definition must pass `scripts/verify-agent-def.sh` before the agent runs.
- Every code-touching agent must run inside its own git worktree.
- The orchestrator's description is the trigger. `CLAUDE.md` is context-loading only.
- Security is only security if it's code. Never rely on LLM instructions to enforce tool restrictions — use `allowedTools:` and `PreToolUse` hooks.

## Anti-patterns commander rejects

Before writing any file, scan for these and fix before output:
- ALL-CAPS enforcement (`MUST`, `NEVER`, `ALWAYS`) without a `# WHY:` comment
- Description under 80 words, or missing negative triggers
- Rule that teaches the model pre-trained knowledge (fails grounding gate)
- Critical rule buried in the middle 60% of a long body (put at start or end)
- Security rule written as a prose instruction instead of a hook or allow-list
- Likert 1–10 rubrics (use binary pass/fail)
- Open-ended loop with no exit condition
- Agent definition over 300 lines
- Peer-skill call without a matching load condition in the body
- Missing brevity constraint on non-length-sensitive outputs
- Team mode for a 2-agent task
- Reviewer / QA / classifier on Opus
- Missing `cache_control` markers on stable blocks >1000 tokens

## Input/output contract with skill-god

When delegating to skill-god, commander writes a JSON spec to `_workspace/<run-id>/skill-god/inbox/<skill-name>.json`:

```json
{
  "name": "example-skill",
  "domain": "content",
  "trigger_keywords": ["phrase one", "phrase two"],
  "negative_triggers": ["do not use for X"],
  "responsibilities": ["what the skill does"],
  "expected_outputs": ["file1.md"],
  "model_recommendation": "sonnet",
  "max_lines": 200
}
```

Skill-god reads this, runs its full pipeline, writes the resulting skill under `<project>/.claude/skills/<harness-name>/<skill-name>/`, and drops a handoff at `_workspace/<run-id>/skill-god/HANDOFF_<skill-name>.md`.

## Checkpoint + resume

Every phase writes `_workspace/<run-id>/checkpoints/p<N>_<name>.json` on completion. A crashed session finds the latest checkpoint and jumps to the next phase. The `_workspace/checkpoints/` symlink at the workspace root always points to the current run's checkpoint directory.

If `HANDOFF.md` exists at session start, read it first — it tells you what's built, what's incomplete, and what to resume.

## Final rule

If any rule in this file would cause commander to violate one of its own anti-patterns when re-read by a future generation, the rule is broken and must be reframed. Commander is a skill about skills — it must pass its own grounding gate and its own pushy-description test. Its own description is in English and scores 117 words on the pushy test. Don't regress.
