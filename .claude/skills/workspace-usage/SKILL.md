---
name: workspace-usage
description: Use when setting up, operating, or repairing an external workspace for agent instructions and skills.
---

# Workspace usage

Use this skill to keep agent guidance outside the target repository while
making it available to the tools that work from the external workspace root.

## Setup

1. Copy the project template profile and edit `workspace.toml`.
2. Set `workspace_root` to the external directory used to launch the agent.
3. Set `target_path` to the existing project checkout.
4. Keep `instruction_source` and `skills_source` in the external profile.
5. List only the provider projection directories you actually use.
6. Run `module/bootstrap.sh --config <profile>/workspace.toml`.

## Daily use

- Launch the agent or editor from `workspace_root` so external instructions
  are discoverable while the target checkout remains unchanged.
- Edit the canonical `AGENT.md` and source `skills/` tree, not generated
  `AGENTS.md`, `CLAUDE.md`, or provider projection copies.
- Run `module/doctor.sh --config <profile>/workspace.toml` after changing
  paths, instructions, or skills.
- Treat any drift report as a synchronization problem, not a reason to edit
  generated files by hand.
- Keep workspace guidance generic: no singular branch names, commit hashes,
  one-off states, or transient findings; write for the project as it evolves.

## Branches and worktrees

Switching branches in the same checkout does not change the workspace target.
When several worktrees are active, give each worktree its own profile if its
instructions or skills differ; share one profile only when that is deliberate.

## Version control

- Use Conventional Commits: `type(scope): summary`, with an optional scope.
- Keep summaries lowercase, imperative, and focused; use standard types such
  as `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, or
  `revert`.
- Mark breaking changes with `!` or a `BREAKING CHANGE:` footer.
- Inspect the staged diff before committing and keep secrets, generated
  projections, and target-repository files out of the commit.

## Safety

The module refuses configured destinations that resolve inside `target_path`.
It merges skill files without pruning unrelated provider content. Keep local
project changes in the target checkout and workspace guidance in the external
profile.
