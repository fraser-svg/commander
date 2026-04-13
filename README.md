# Commander

**You describe the job. Commander builds the team.**

One sentence in, a full agent team out: agents, skills, orchestrator, security rails, cost routing, the works. Drop it into any Claude Code project and stop hand-rolling harnesses.

```
you:        "build me a team that turns a YouTube URL into a blog post"
commander:  ✓ 3 agents wired (fetch → draft → edit)
            ✓ 4 skills written by skill-god
            ✓ orchestrator with DAG + HANDOFF.md
            ✓ Haiku for edit, Sonnet for draft, Opus skipped
            ✓ cost estimate: $0.14/run
            ready.
```

## Why this exists

Everyone building on Claude Code hits the same wall. You want three agents talking to each other. You end up with twelve files, a broken orchestrator, two skills that trigger on the same keyword, and one agent quietly running on Opus burning $40/hour on a task Haiku handles fine.

Commander is the senior engineer who's done this fifty times. It picks the cheapest execution mode that works, routes each role to the right model, writes the security rails as code instead of vibes, and refuses to generate a skill that duplicates one you already have installed.

It's also the only meta-skill that delegates skill writing to another skill (`skill-god`) instead of pretending it can do everything itself. Composition over god-objects.

## What you get

- **Graduated escalation ladder.** Single-session → parallel sub-agents → full agent team. Commander defaults to the cheapest tier and only escalates with written justification. No more "oh I'll just use a team for this two-step task."
- **70/20/10 model routing.** Reviewers, QA, classifiers, formatters → Haiku 4.5. Builders and writers → Sonnet 4.6. Planners and architects → Opus 4.6. Never the other way around.
- **Prompt caching on by default.** Stable blocks get `cache_control` markers automatically. You stop paying for the same system prompt 40 times.
- **Security as code, not vibes.** `allowedTools` allow-lists, `PreToolUse` hooks, git worktrees for any code-touching agent. Not a prose instruction that says "please don't delete prod."
- **Resumable across sessions.** Every phase writes a checkpoint. Every run ends with a `HANDOFF.md`. Crash mid-run, pick up exactly where you left off.
- **Trigger evals before ship.** 10 should-trigger queries + 10 near-misses, binary pass/fail. If your skill doesn't activate reliably, it doesn't ship.
- **The grounding gate.** Every rule Commander writes gets asked: *"would Claude fail at this >30% of the time without this rule?"* If no, delete. Kills the bloat that makes most agent prompts unmaintainable.

## Install

```bash
git clone https://github.com/fraser-svg/commander.git ~/.claude/skills/commander
```

Per project:

```bash
git clone https://github.com/fraser-svg/commander.git .claude/skills/commander
```

Commander delegates skill generation to [`skill-god`](https://github.com/fraser-svg/skill-god). Install that too or Commander will refuse to run (intentional — no silent fallback to hand-rolled slop).

## Use

In Claude Code, say any of:

- "build me a team to scrape competitor pricing daily"
- "set up agents for PR review"
- "make a harness for my cold email pipeline"
- "architect a multi-agent system for research"
- "add a QA agent to my existing harness"
- "audit my .claude/ directory"

Commander intakes the request in plain English, confirms scope, picks the right tier, and ships.

## What it actually does (the 8 phases)

| # | Phase | Output |
|---|---|---|
| 0 | **Audit** — read existing harnesses, detect drift, resume if `HANDOFF.md` exists | `audit_report.md` |
| 1 | **Domain analysis** — identify task types, check skill index for reuse | `domain_brief.md`, `entity_map.md` |
| 2 | **Architecture** — pick tier (single/parallel/team) with written justification | `arch_spec.md`, `escalation_decision.md` |
| 3 | **Agent generation** — write definitions, verify each via `verify-agent-def.sh` | `.claude/agents/<harness>/*.md` |
| 4 | **Skill generation** — delegate to `skill-god` with JSON specs | `.claude/skills/<harness>/*/` |
| 5 | **Orchestration** — DAG, cache markers, worktrees, cost gates | `orchestrator/SKILL.md` |
| 6 | **Validation** — trigger eval (9/10 + 9/10 threshold), DAG dry-run | `validation_report.md` |
| 7 | **Evolution** — honest changelog, no fake auto-learning | `harnesses.json` update |

## vs. the alternatives

| | Commander | `revfactory/harness` | hand-rolling |
|---|---|---|---|
| Picks execution tier | ✓ ladder w/ justification | fixed | you guess |
| Per-role model routing | ✓ 70/20/10 | no | Opus everywhere |
| Prompt caching wired | ✓ default | no | you forget |
| Security as code | ✓ allow-lists + hooks | prose | prose |
| Resumable | ✓ HANDOFF.md | no | lol |
| Grounding gate | ✓ 30% rule | no | bloat city |
| Trigger evals | ✓ pre-ship | no | prod surprise |
| Multi-harness per project | ✓ namespaced | collision | collision |

## Philosophy

Commander has opinions and enforces them in code, not in prompts.

- **Security is only security if it's code.** An instruction that says "don't call `rm -rf`" is theatre. An `allowedTools` list is security.
- **Every rule earns its place.** If the model already does it right most of the time, writing it down wastes tokens and buries the rules that actually matter.
- **Composition over god-objects.** Commander doesn't write skills. `skill-god` does. Commander doesn't write agents for tasks a single session handles. Taste in what *not* to build is the whole job.
- **Cheap-correct by default.** Opus is a luxury you spend on planning, not on grep.

## Status

Used in production across [redacted] projects. MIT licensed. PRs welcome, but read `SKILL.md` first — it has strong opinions and they're load-bearing.

## License

MIT. See [LICENSE](./LICENSE).

---

Built with [Claude Code](https://claude.com/claude-code). If you ship something wild with Commander, I want to see it.
