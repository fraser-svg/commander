# Commander

> **Describe the job. Get the team.**

A meta-skill for [Claude Code](https://claude.com/claude-code) that turns one sentence into a full agent team — agents, skills, orchestrator, security rails, cost routing, resumable checkpoints. Stop hand-rolling harnesses.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-8b5cf6)](https://claude.com/claude-code)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./CONTRIBUTING.md)

## Install

```bash
git clone https://github.com/fraser-svg/commander.git ~/.claude/skills/commander
git clone https://github.com/fraser-svg/skill-god.git  ~/.claude/skills/skill-god
```

That's it. Open any project in Claude Code and say *"build me a team to..."*.

## Demo

```
you:        build me a team that turns a YouTube URL into a blog post

commander:  ▸ intake confirmed — 3 agents, 4 skills, Tier-2 parallel
            ▸ picked Fan-out/Fan-in pattern
            ▸ routed: fetcher→Haiku, drafter→Sonnet, editor→Haiku
            ▸ delegated 4 skills to skill-god
            ▸ wired orchestrator with cache_control + worktrees
            ▸ cost estimate: $0.14/run · trigger eval: 10/10 + 10/10
            ▸ HANDOFF.md written

            ready. trigger with "turn this video into a post".
```

Commander wrote 11 files. You wrote one sentence.

## Why people hand-build harnesses and why it goes wrong

You want three agents to talk to each other. You end up with twelve files, a broken DAG, two skills that trigger on the same keyword, and one agent quietly running on Opus burning $40/hour on a task Haiku handles fine. Prompt caching? Forgot. Security? A prose instruction that says *"please don't rm -rf prod."* Resume after a crash? Start over.

Commander is the senior engineer who's done this fifty times. It picks the cheapest execution tier that actually works, routes each role to the right model, writes security as code, and refuses to ship a skill that duplicates one you already have installed.

## What's inside

- **Graduated escalation ladder.** Single-session → parallel sub-agents → full team. Defaults to cheap. Escalating requires a written justification file or it refuses to ship.
- **70/20/10 model routing.** Reviewers, QA, classifiers, formatters → Haiku 4.5. Builders and writers → Sonnet 4.6. Planners and architects → Opus 4.6. Never inverted.
- **Prompt caching on by default.** `cache_control` markers auto-placed on stable blocks. You stop paying for the same system prompt 40 times per run.
- **Security as code.** `allowedTools` allow-lists, `PreToolUse` hooks, git worktrees for code-touching agents. Not vibes.
- **Resumable.** Every phase writes a checkpoint. Every run ends with `HANDOFF.md`. Crash mid-run, pick up where you stopped.
- **Trigger evals before ship.** 10 should-trigger + 10 near-miss queries, binary pass/fail, 9/10 threshold. If it doesn't activate reliably, it doesn't ship.
- **The grounding gate.** Every rule is asked *"would Claude fail at this >30% of the time without this rule?"* If no, delete. The reason your generated skills won't bloat into 800-line monsters.

## Examples of what you can build in one sentence

```
"build a PR review team that runs lint, tests, and security in parallel"
"set up agents for my cold email pipeline — research, draft, personalize"
"make a harness that audits a codebase and writes a migration plan"
"add a QA agent to my existing content-engine harness"
"audit my .claude/ directory and reconcile drift"
```

Each of those ships a full harness. Commander picks the tier, picks the pattern, delegates skill-writing to [`skill-god`](https://github.com/fraser-svg/skill-god), wires the DAG, and hands you a working system with a cost estimate before the first agent runs.

## Philosophy

Commander has opinions and enforces them in code, not prompts.

**Security is only security if it's code.** An instruction that says *"don't delete prod"* is theatre. An `allowedTools` list is security.

**Every rule earns its place.** If the model already does it right most of the time, writing the rule down wastes tokens and buries the rules that matter. The grounding gate is non-negotiable.

**Composition over god-objects.** Commander doesn't write skills — [`skill-god`](https://github.com/fraser-svg/skill-god) does. Commander doesn't spawn a team for a task a single session handles. Taste in what *not* to build is the whole job.

**Cheap-correct by default.** Opus is a luxury you spend on planning, not grep.

## How it works (the 8 phases)

`Audit → Domain → Architecture → Agents → Skills → Orchestration → Validation → Evolution`

Each phase writes a checkpoint. Read the full protocol in [`SKILL.md`](./SKILL.md) — it's 300 lines of load-bearing opinions and they're all there for a reason.

## FAQ

**Do I need skill-god?** Yes. Commander refuses to run without it. No silent fallback to hand-rolled slop.

**Will this work on `claude-3-5-sonnet`?** No. Commander targets Claude 4.5/4.6 routing (Haiku 4.5 / Sonnet 4.6 / Opus 4.6). Older models don't have the price-performance split it optimizes for.

**Does it work outside Claude Code?** Claude Code only. It relies on `Skill`, `Agent`, `TeamCreate`, and `Task*` tools that other harnesses don't have.

**Can I override the model routing?** Yes, but you'll have to remove a rule from `SKILL.md` and Commander will tell you which one. The default is non-negotiable for a reason.

## Contributing

Read [`SKILL.md`](./SKILL.md) first. Opinions are load-bearing — PRs that soften them get pushback. PRs that sharpen them get merged fast.

## License

MIT. See [LICENSE](./LICENSE).

---

<sub>Built with [Claude Code](https://claude.com/claude-code). If you ship something wild with Commander, open an issue — I want to see it.</sub>
