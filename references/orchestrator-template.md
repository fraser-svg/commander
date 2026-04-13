# Orchestrator Template

Every orchestrator commander generates follows this shape. The orchestrator is itself a skill at `<project>/.claude/skills/<harness-name>/orchestrator/SKILL.md`. Its `description:` field is the sole trigger mechanism — `CLAUDE.md` is context-loading only.

## Strategic ordering inside generated orchestrators

- **First 15% of body:** mission statement, team roster one-liners, intake protocol, abort conditions
- **Middle 15–85%:** reference load conditions, phase model, delegation logic, handoff format, error handling
- **Last 15% of body:** output format and success criteria, anti-pattern validation reminder, follow-up trigger acknowledgment

The restatement at the end compensates for middle-context attention loss on long sessions. One line each, not a full repetition.

## DAG YAML shape (embedded in every orchestrator SKILL.md)

```yaml
dag:
  nodes:
    - id: ingest
      agent: data-ingest-agent
      inputs: [domain_brief.md]
      outputs: [raw_corpus/]
      model: haiku
      repo_writes: false
      cache_blocks: [system_prompt, agent_definition, rubric]
      exit:
        success: "corpus_manifest.json exists AND line_count > 0"
        failure: "timeout 10m OR corpus_manifest.json missing"
      on_failure: abort

    - id: analyze
      agent: schema-analyst-agent
      depends_on: [ingest]
      model: sonnet
      repo_writes: false
      cache_blocks: [system_prompt, agent_definition]
      exit:
        success: "schema_draft.json valid JSON"
        failure: "timeout 15m"
      on_failure: retry_once then abort

    - id: emit
      agent: emitter-agent
      depends_on: [analyze]
      model: haiku
      repo_writes: true
      worktree: .worktrees/emitter-agent
      exit:
        success: "final_output/ contains >= 1 file"
        failure: "timeout 10m"
      on_failure: abort

  exit_conditions:
    global_timeout: 45m
    abort_on: any_node_failure
```

**Rules:**
- `exit.success` is a shell-evaluable boolean expression
- `exit.failure` is a timeout or filesystem assertion
- `cache_blocks` lists prompt sections the orchestrator marks with `cache_control: {"type": "ephemeral"}`
- `repo_writes: true` triggers git worktree spawn via `.worktrees/<agent-name>/`
- `depends_on` encodes edges; orchestrator runs topological order

## Phase 0 inside the generated orchestrator (context verification)

Before running the DAG, the generated orchestrator must:
1. Check for `_workspace/HANDOFF.md`. If present and status=PARTIAL, read the resume_from field and jump to that phase.
2. Check for existing `_workspace/<run-id>/` — if present + new input → move existing to `_workspace_prev/` and start fresh run. If present + user requested partial update → re-run only the affected node(s).
3. If neither handoff nor prior run → Phase 1 full execution.

## Data passing rules

- File-based via `_workspace/<run-id>/<phase>/<agent>/<artifact>.<ext>`
- Naming convention: `{phase}_{agent}_{artifact}.{ext}` inside the run directory
- Final outputs to user-specified paths; intermediate files preserved in `_workspace/` (audit trail)
- For team mode: also use `SendMessage` for real-time coordination, `TaskCreate` for shared task list
- For sub-agent mode: use return values plus file outputs

## Error handling policy

- 1 retry per node maximum. Retry must include a structured error analysis block (what failed, hypothesis, what's different).
- If second attempt fails: skip the node, record the gap in HANDOFF.md, continue with downstream nodes that can proceed.
- Conflicting data between agents: preserve both sources with attribution, never silently delete.
- Budget exhaustion: halt new launches, drain in-flight, emit partial completion HANDOFF.

## Description writing for generated orchestrators

The orchestrator's `description:` must be pushy, under 150 words, with:
- WHAT: what the team does in one sentence
- WHEN to trigger: 3–5 phrases the user would actually type, including casual phrasings
- Follow-up keywords: "update", "re-run", "add another", "fix the", "rebuild"
- WHEN NOT: 2–3 explicit exclusions
- Produces: concrete output list

Example:
```yaml
description: |
  Runs the newsletter production pipeline: research → draft → review → publish.
  Use when: "send this week's newsletter", "draft the weekly digest",
  "publish Tuesday edition", "re-run the newsletter pipeline", "add a new
  section to the newsletter", "review the newsletter before send".
  Do NOT use for: one-off blog posts, social posts, marketing emails.
  Produces: draft.md, review_notes.md, published-edition-<date>.md.
```

## Post-run contract

Every orchestrator run ends with:
1. Write `HANDOFF.md` using `assets/handoff-template.md`
2. Call `scripts/workspace-rotate.sh` to compress old runs
3. Log actual cost to `_workspace/run.log` via post-run hook
4. If any node was skipped or retried, flag in `HANDOFF.md` under Incomplete
5. If orchestrator exited due to budget gate, emit the exact cost-over message

## CLAUDE.md for harness-enabled projects

Write only context-loading to CLAUDE.md. No trigger language.

```markdown
## Harnesses
This project uses the <harness-name> harness built by commander.
Registry: .claude/harnesses.json
Workspace: _workspace/
Worktrees: .worktrees/
Do not edit files under .claude/agents/<harness-name>/ manually.
Do not delete _workspace/HANDOFF.md.
```

No "use this skill when..." language. The orchestrator's own description handles triggering.
