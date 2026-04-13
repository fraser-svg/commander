# Commander

Agent team & skill architect for Claude Code. Given a domain request, Commander produces a complete, cost-aware, secure agent team — agent definitions, their skills, and one orchestrator skill that wires them together via DAG.

Commander is a meta-skill. Skill creation is delegated to `skill-god` — Commander never writes `SKILL.md` directly.

## Features

- Defaults to the cheapest-correct execution mode (single-session → parallel sub-agents → team)
- Routes per-role across Haiku 4.5 / Sonnet 4.6 / Opus 4.6 via the 70/20/10 rule
- Caches stable prompt blocks with `cache_control` markers
- Enforces security deterministically via scripts and tool allow-lists, not instructions
- Emits a `HANDOFF.md` at the end of every run so sessions resume cleanly

## Install

```bash
git clone https://github.com/fraser-svg/commander.git ~/.claude/skills/commander
```

Or as a submodule inside a project:

```bash
git clone https://github.com/fraser-svg/commander.git .claude/skills/commander
```

## Use

In Claude Code, trigger with phrases like:

- "build me a team to…"
- "set up agents for…"
- "make a harness"
- "architect an agent workflow"
- "design a multi-agent system"

## Layout

```
SKILL.md        # Skill entry point and instructions
references/     # Design docs, patterns, checklists
scripts/        # Deterministic automation commander delegates to
assets/         # Templates and static resources
```

## License

MIT
