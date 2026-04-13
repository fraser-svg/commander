# Why — philosophy and feedback mapping

This file contains the design rationale that didn't fit in `SKILL.md` and the feedback-mapping table used in Phase 7 evolution.

## Why commander exists

The upstream `revfactory/harness` (Korean meta-skill, v1.2.0) has good bones and several critical bugs:

- Its own description is in Korean — fails its own "pushy" pushy-description rule for any English-speaking user. Trigger surface dark.
- Every agent is mandated to `model: opus`. Combined with double-run evals and no prompt caching, the modal run cost is 10–15× current best practice.
- Team-mode-default inverts the cost gradient. Anthropic's own March 2026 position: 95% of tasks don't need multi-agent. Teams should be the escalation, not the default.
- Phase 7 "evolution" is theater — no memory, no diffing, hand-maintained changelog. Claims auto-trigger on repeated feedback but has no persistent state.
- Incremental QA contradicts team-mode parallel execution. The upstream never resolves it.
- Orchestrator-triggering-via-CLAUDE.md-pointer is superstition. CLAUDE.md preloads context; it doesn't force skill invocation.
- Bootstrap paradox with skill-god: Phase 4 mandates skill-god delegation but has no story for a new environment without skill-god installed.
- No security model. No tool allow-lists. No hooks. No CaMeL layers. Every generated agent is effectively "all tools allowed."
- Single-harness-per-project assumption. Two harnesses in one project = silent agent-name collision.

Commander fixes these while keeping the good parts: agents-vs-skills split, `_workspace/` convention, file-based handoff, progressive disclosure, skill-god delegation, and the QA boundary-mismatch methodology (which is the best idea in the upstream).

## Why these defaults

**Why Haiku for reviewers/QA/classifiers?** Pattern matching against a rubric and emitting structured output is Haiku's sweet spot. Opus for this is 5× more expensive with no quality delta.

**Why Sonnet for builders/writers?** Sonnet 4.6 is Anthropic's strongest coding model and handles multi-file synthesis cleanly. Cheaper than Opus, more capable than Haiku. It's the modal default for 20% of work that isn't trivially classifiable or strictly architectural.

**Why Opus only for planners/architects?** Irreversible decisions and cross-agent dependency resolution benefit from maximum reasoning depth. That's <10% of work in a typical run.

**Why "pushy" descriptions?** Anthropic's own term (March 2026 skill docs). Claude undertriggers skills by default. Pushy descriptions with concrete WHEN + WHEN NOT + casual phrasings overcome the bias.

**Why 150-word description cap?** Sits in context on every turn. ~53 tokens at 100 words, ~80 tokens at 150. Over 150 and you're taxing every single turn with low-value text.

**Why ≤500-line SKILL.md body?** Context rot past 80% utilization. SKILL.md + references loads on trigger; keeping the body lean leaves headroom for actual task context.

**Why 3-agent minimum for team mode?** Measured: 2-agent team has team overhead (3–4× token cost) for zero coordination benefit over 2 parallel sub-agents. The breakeven is at 3 agents where real coordination starts to matter.

**Why 5-agent maximum for team mode?** Coordination cost grows faster than output quality past 5. Beyond 5, split into hierarchical sub-teams.

**Why grounding gate?** "If the model would do this right without the rule, the rule is token tax." Commander rejects any rule that teaches pre-trained knowledge (what JSON is, how to be concise).

**Why ban Likert scales?** Models drift on numeric ranges across runs. Binary pass/fail is reproducible. If you need granularity, add more binary checks.

**Why prompt caching mandatory?** 90% discount on cache hits, ~80% of input bytes are cacheable on a modal run, ignoring this is setting 75% of your input spend on fire.

## Feedback mapping (Phase 7)

When the user gives feedback on a harness run, map it to the right artifact and edit only that:

| Feedback | Edit |
|---|---|
| "The writer's output is too shallow" | `agents/<writer>.md` skill body — add depth criteria |
| "We need a security reviewer" | Add new agent to `agents/<harness>/` + update orchestrator roster |
| "Run QA before the writer finishes, not after" | Orchestrator DAG node order |
| "These two agents are redundant" | Merge into one; update orchestrator |
| "The skill didn't trigger when I said X" | Orchestrator or skill description — add trigger keywords |
| "The output shape changed and broke downstream" | Agent output contract + downstream consumer type; run QA boundary-mismatch check |
| "It's burning too many tokens" | Model routing table; check caching markers; check for 200k cliff |

## Final rule (reproducing SKILL.md's)

If a rule in commander's own files would cause commander to violate one of its own anti-patterns when re-read by a future generation, the rule is broken and must be reframed. Commander is a skill about skills — it must pass its own grounding gate and its own pushy-description test.
