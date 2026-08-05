---
name: ltheory-project
description: Use when changing the Limit Theory Redux Rust and Lua project through its external workspace.
---

# Limit Theory Redux project context

Use this skill for work in the sibling `ltheory` checkout while keeping agent
configuration in the separate workspace repository.

## Procedure

1. Confirm the target checkout is the sibling `ltheory` directory.
2. Inspect the relevant Rust crate and Lua module boundaries before editing.
3. Check the working tree and preserve unrelated tracked or untracked work.
4. Run the smallest real build, format, or test command covering the change.
5. Keep instructions and provider projections in this workspace, not in the
   target checkout.

## Branches and worktrees

Switching branches in the same checkout does not change the workspace target.
When several worktrees are active, give each worktree its own profile if its
instructions or skills differ; share one profile only when that is deliberate.

## Scope

This skill provides project context and workspace hygiene. It does not impose
a task tracker, model provider, deployment platform, or credential workflow.
