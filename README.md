<p align="center">
  <img src="https://em-content.zobj.net/source/apple/391/military-medal_1f396-fe0f.png" width="120" />
</p>

<h1 align="center">commander</h1>

<p align="center">
  <strong>describe the job. get the team.</strong>
</p>

<p align="center">
  <a href="https://github.com/fraser-svg/commander/stargazers"><img src="https://img.shields.io/github/stars/fraser-svg/commander?style=flat&color=yellow" alt="Stars"></a>
  <a href="https://github.com/fraser-svg/commander/commits/master"><img src="https://img.shields.io/github/last-commit/fraser-svg/commander?style=flat" alt="Last Commit"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/fraser-svg/commander?style=flat" alt="License"></a>
  <a href="https://claude.com/claude-code"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-8b5cf6" alt="Claude Code"></a>
</p>

<p align="center">
  <a href="#before--after">Before/After</a> •
  <a href="#install">Install</a> •
  <a href="#what-you-get">What You Get</a> •
  <a href="#examples">Examples</a> •
  <a href="#philosophy">Philosophy</a> •
  <a href="#faq">FAQ</a>
</p>

---

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) meta-skill that turns one sentence into a complete agent team — agents, skills, orchestrator, security rails, cost routing, resumable checkpoints. Stop hand-rolling harnesses.

Based on the painful observation that everyone building on Claude Code ships the same twelve-file mess — broken DAG, keyword collisions, one agent quietly burning Opus on a task Haiku handles fine. So we made it a one-line install.

## Before / After

<table>
<tr>
<td width="50%">

### 🛠️ Hand-rolled harness

> "Okay so I need a research agent, then a drafter, then an editor. Let me write three agent files. What model? I'll put them all on Sonnet to be safe. Now the orchestrator... do I use Task or Agent? Cache control, right. Security? I'll add a note. Wait, the drafter is overwriting the researcher's output. Let me rewrite the DAG."

</td>
<td width="50%">

### 🎖️ Commander

> "build me a team to turn a YouTube URL into a blog post"

**3 agents, 4 skills, orchestrator, DAG, cost estimate, HANDOFF.md — shipped.**

</td>
</tr>
<tr>
<td>

### 🛠️ Hand-rolled review agent

> "Let me write a code reviewer. Opus, for quality. 400-line prompt telling it to be careful. Oh no, the prompt has `MUST NEVER ALWAYS` in all caps nine times. Why is my review loop still letting bad diffs through?"

</td>
<td>

### 🎖️ Commander

> "add a PR review agent to my harness"

**Haiku 4.5, 80-line definition, trigger eval 10/10, `allowedTools` allow-list, shipped.**

</td>
</tr>
</table>

**Same team. One sentence. Grounding gate filters the bloat.**

```
┌─────────────────────────────────────────┐
│  TIME TO FIRST RUN    ████████  60s     │
│  MODEL COST SAVINGS   ████████  ~70%    │
│  SECURITY             ████████  as code │
│  RESUMABLE            ████████  always  │
│  OPINIONS             ████████  strong  │
└─────────────────────────────────────────┘
```

- **Cheap-correct by default** — Haiku 4.5 for reviewers/QA/classifiers, Sonnet 4.6 for builders, Opus 4.6 for planners. Never inverted.
- **Prompt caching wired** — `cache_control` markers auto-placed on stable blocks. Stop paying for the same system prompt 40x per run.
- **Security as code** — `allowedTools` allow-lists and `PreToolUse` hooks. Not a prose instruction that says *"please don't rm -rf prod."*
- **Resumable across sessions** — every phase writes a checkpoint, every run ends with `HANDOFF.md`. Crash, pick up exactly where you stopped.
- **Trigger evals before ship** — 10 should-trigger + 10 near-miss queries, 9/10 pass threshold. Doesn't activate reliably → doesn't ship.

## Install

```bash
git clone https://github.com/fraser-svg/commander.git ~/.claude/skills/commander
git clone https://github.com/fraser-svg/skill-god.git  ~/.claude/skills/skill-god
```

Open any project in Claude Code and say *"build me a team to..."*. That it.

> [!NOTE]
> Commander delegates all skill-writing to [`skill-god`](https://github.com/fraser-svg/skill-god). It will refuse to run without it. No silent fallback to hand-rolled slop.

## What You Get

| Feature | Commander |
|---------|:---------:|
| Graduated escalation ladder (single → parallel → team) | Y |
| 70/20/10 Haiku/Sonnet/Opus routing | Y |
| Prompt caching with `cache_control` markers | Y |
| `allowedTools` allow-lists + `PreToolUse` hooks | Y |
| Git worktrees for code-touching agents | Y |
| `HANDOFF.md` + per-phase checkpoints | Y |
| Trigger evals (10 + 10, binary pass/fail) | Y |
| Grounding gate on every generated rule | Y |
| Multi-harness per project (namespaced) | Y |
| Delegates skill-writing to `skill-god` | Y |

## Examples

One sentence in, full harness out.

```
"build me a team to scrape competitor pricing daily"
"set up agents for my cold email pipeline — research, draft, personalize"
"make a harness that audits a codebase and writes a migration plan"
"add a QA agent to my existing content-engine harness"
"audit my .claude/ directory and reconcile drift"
```

## The 8 phases

```
Audit → Domain → Architecture → Agents → Skills → Orchestration → Validation → Evolution
```

Every phase writes a checkpoint JSON. Crash at phase 5, resume at phase 5. Read the full protocol in [`SKILL.md`](./SKILL.md) — 300 lines of load-bearing opinions and they're all there for a reason.

## Philosophy

Commander has opinions and enforces them in code, not prompts.

**Security is only security if it's code.** Instructions that say *"don't delete prod"* are theatre. `allowedTools` is security.

**Every rule earns its place.** If Claude already does it right most of the time, writing the rule wastes tokens and buries the rules that matter. The grounding gate is non-negotiable.

**Composition over god-objects.** Commander doesn't write skills — [`skill-god`](https://github.com/fraser-svg/skill-god) does. Commander doesn't spawn a team for a task a single session handles. Taste in what *not* to build is the whole job.

**Cheap-correct by default.** Opus is a luxury you spend on planning, not grep.

## FAQ

**Do I need skill-god?** Yes. Commander refuses to run without it.

**Will this work on `claude-3-5-sonnet`?** No. Commander targets the Claude 4.5/4.6 family (Haiku 4.5 / Sonnet 4.6 / Opus 4.6). Older models don't have the price-performance split it optimizes for.

**Does it work outside Claude Code?** Claude Code only. It relies on `Skill`, `Agent`, `TeamCreate`, and `Task*` tools that other agents don't have.

**Can I override the model routing?** Yes, but you'll have to remove a rule from `SKILL.md` and Commander will tell you which one. The default is non-negotiable for a reason.

**Is Phase 7 "evolution" magic?** No. It's an honest changelog you maintain. No persistent cross-session state, no fake auto-learning.

## Contributing

Read [`SKILL.md`](./SKILL.md) first. Opinions are load-bearing — PRs that soften them get pushback, PRs that sharpen them get merged fast.

## License

MIT. See [LICENSE](./LICENSE).

---

<p align="center">
  <sub>Built with <a href="https://claude.com/claude-code">Claude Code</a>. Ship something wild with Commander? Open an issue — I want to see it.</sub>
</p>
