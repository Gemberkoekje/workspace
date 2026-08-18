---
name: coding-standards
description: Comment/review conventions for this codebase — comments describe the code's own behavior, never its consumers; keep comments on-topic; write for the project as it evolves, not for one state. Use when writing or reviewing any code here.
---

# Coding Standards

## Comments describe the CODE, not its consumers

- Comments must explain what the code does and WHY — never who uses it or which state/scene depends on it.
- Wrong: "used by LimitTheoryRedux" / "needed by Benchmark" / "consumed by SolarSystemPlayable".
- Right: "a focused single-planet scene: one star, one rocky planet with ring + belt forced on".
- Consumers change and multiply; a comment naming one goes stale and misleads the next reader.
- Same rule for names: pick names that describe the thing itself (e.g. `SinglePlanetWithBelt`), not a specific caller.

## Keep comments on-topic

- A comment in file X should only explain X. Don't reference other states, other systems, or
  "the benchmark did this" style archaeology unless it is directly relevant to why THIS line exists.
- If a behavior was decided elsewhere (a rule, a discussion), state the RULE, not the meeting:
  "engine unit IS the game unit (UniverseScaleConfig)" — not "the user said on 2026-08-09".

## Write for the project as it evolves

- No singular branch names, commit hashes, one-off states, or transient findings in comments.
- Describe invariants and conventions that hold for any future call site.
- "That should be a rule" → encode it in the governing instruction file (skill/AGENTS/README),
  not just in memory or a one-off comment.

## Comments for technically complicated code — AI-agent rule

When writing or modifying technically complicated code, add comments where ownership, lifecycle, synchronization, backend, FFI, or other safety-sensitive rationale is not obvious from the implementation. Explain **why** the structure exists, the invariant or constraint it preserves, and the failure mode it prevents. Do not add comments that merely restate self-evident code; straightforward code does not need extra commentary.

## Review checklist

- Every comment names only the code it sits in.
- No consumer/state/scene names in comments or docstrings.
- No dates, commit refs, or "we changed X" narratives.
- New reusable config/rulesets are registered in their `__init__`/index and named self-descriptively.
