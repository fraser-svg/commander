---
name: <agent-name>
description: |
  <One sentence: what this agent does, starting with an action verb.>
  Use when: <3-5 specific trigger phrases including casual phrasings>.
  Retriggers on: <2-3 follow-up keywords: "update X", "add another Y", "the Z is broken">.
  Do NOT use for: <2-3 explicit exclusions>.
  Produces: <concrete output list — files, formats, artifacts>.
model: <opus|sonnet|haiku>     # per references/model-routing.md
subagent_type: general-purpose  # or Explore for read-only roles
brevity: "Reply in under 200 words unless task requires exhaustive output."
security:
  allowedTools: [Read, Grep, Glob]   # explicit list, never "all", never empty
  mcpServers: []                      # explicit empty list if none
  outputsSanitized: false             # consumer treats output as untrusted
  dataScope: internal                 # public | internal | sensitive | pii
  bashPolicy:
    allow: []                         # command allowlist if Bash in allowedTools
    denyPaths: [/etc, /usr, ~/.ssh]
  costBudgetUSD: 0.10                 # hard ceiling; orchestrator enforces
  canPush: false
  canMutateFiles: false
---

## Core Role

<One paragraph. Who this agent is, what it owns, why it exists. Keep it to the single responsibility that justifies a dedicated agent.>

## Operating Principles

- <Principle 1 with reasoning — explain WHY, not just what>
- <Principle 2 with reasoning>
- <Principle 3 with reasoning>

## Input

The orchestrator passes this agent:
- `<field>`: <type and description>
- `<field>`: <type and description>

Required artifacts on disk before this agent runs:
- `_workspace/<run-id>/<prior-phase>/<artifact>.md`

## Output

This agent writes:
- `_workspace/<run-id>/<this-phase>/<this-agent>/<artifact>.md` — <description>

Output shape (JSON schema or markdown structure):
```
<schema here>
```

## Error Handling

- If <expected input missing>: log to `_workspace/errors/<agent>.log`, emit `status: blocked`, exit
- If <validation fails>: retry once with simplified scope
- If <upstream dependency unresolved>: emit `status: blocked` with reason, do not loop
- Hard rule: no retry without a structured error-analysis block written to `_workspace/<run-id>/retries/<agent>-<timestamp>.md`

## Team Communication Protocol

<Only include this section in team mode. Delete if this agent runs as a parallel sub-agent.>

- Receives messages from: `<other agent names>`
- Sends messages to: `<other agent names>`
- Task requests: the orchestrator creates tasks via `TaskCreate`; this agent claims via `TaskUpdate` with `owner`
- Handoff format: structured envelope via `scripts/wrap-output.sh`

## Resume Behavior

If `_workspace/<run-id>/<this-phase>/<this-agent>/` already exists from a prior run:
- Read the existing artifacts
- Diff against the current input
- Reflect only incremental changes, not full regeneration
- Update `HANDOFF.md` with what changed

## Peer skills used

- `<skill-name>` — <when this agent invokes it>
