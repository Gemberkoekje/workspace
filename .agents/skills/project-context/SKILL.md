---
name: project-context
description: Use when changing a project whose agent instructions and skills are managed outside the main repository.
---

# External project context

Use this skill when a project deliberately keeps agent guidance outside its
source repository.

## Procedure

1. Confirm the target checkout and the external workspace root before editing.
2. Treat the canonical `AGENT.md` and `skills/` tree as the source of truth.
3. Leave provider projections (`AGENTS.md`, `CLAUDE.md`, `.agents/skills`,
   `.claude/skills`) outside the target checkout.
4. Do not overwrite unrelated local changes in the target repository.

## Scope

This skill describes workspace hygiene only. It does not prescribe a task
tracker, model provider, language toolchain, or deployment platform.
