# Peer Skill Composition

Commander is a Tier-1 team architect. It defers to peer meta-skills for their specialties rather than re-implementing them. When Phase 1 detects one of the conditions below, commander invokes or recommends the peer.

## skill-god — every Phase 4

Commander never writes `SKILL.md` for a generated agent's skill. It delegates to skill-god. See `SKILL.md` Phase 4 for the full protocol.

Bootstrap check: if `~/.claude/skills/skill-god/` does not exist, error with install instructions and refuse to proceed.

## agent-harness-construction — Phase 3 reference

For single-agent internals (tool design, observation formatting, error recovery contracts), link to this peer in the generated agent definition rather than re-teaching. Don't duplicate its patterns inside commander.

## ralphinho-rfc-pipeline — Phase 1 when scope > 50 work units

Trigger: Phase 1 domain analysis reveals more than ~50 distinct work units.

Action: recommend the user run `ralphinho-rfc-pipeline` first to decompose the work formally. Pause commander and wait for the user's decision.

Rationale: commander is ad-hoc team formation. RFC pipeline is prescriptive DAG decomposition with merge queues, dependency graphs, and rollback plans. For large formal projects, the RFC pipeline produces a better backbone and commander can then assign agents to each work unit.

## continuous-agent-loop — after Phase 6 for iterative long-running work

Trigger: user asks to run the orchestrator repeatedly or in a loop (e.g. "run this every hour", "keep iterating until X").

Action: recommend `continuous-agent-loop` as the wrapper. Commander builds the one-shot team; continuous-agent-loop runs it in a supervised loop with health monitoring, churn detection, and budget drift detection.

Commander itself is session-scoped and does not own loop health.

## enterprise-agent-ops — production deployment

Trigger: user asks to deploy the generated harness as a long-running service, or mentions uptime, metrics, incident response, or scoped credentials management.

Action: hand off to `enterprise-agent-ops`. Commander produces the harness artifacts; enterprise-agent-ops handles lifecycle (start/pause/stop/restart), observability, change management, and incident response.

Commander does not own production deployment.

## cost-aware-llm-pipeline — Phase 3 cost routing

Trigger: user asks about batch processing, high-volume workloads, or explicitly wants to override the default 70/20/10 routing.

Action: read `cost-aware-llm-pipeline` and apply its guidance. Commander's default routing (see `model-routing.md`) is a sane starting point but this peer has more sophisticated routing strategies for heterogeneous workloads.

## superpowers:brainstorming — Phase 1 when request is vague

Trigger: user's request is missing ≥2 of (domain, team shape, output).

Action: invoke `superpowers:brainstorming` before proceeding to Phase 1 analysis. Concrete requests skip the brainstorm gate.

## superpowers:dispatching-parallel-agents — referenced in Phase 2

When commander selects Tier 2 (parallel sub-agents), link to this peer in the generated orchestrator's SKILL.md rather than re-teaching the parallel-agent dispatch pattern.

## Principle

Commander defers decisively. If a peer owns a domain, commander links to it. Duplicating peer patterns inside commander creates drift — the peer evolves, commander's copy rots. Always link, never clone.
