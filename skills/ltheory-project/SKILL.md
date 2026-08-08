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

## Development loop

The repository's own workflow (see `ltheory/CONTRIBUTING.md`) is the source of
truth. Practical commands:

- Iterate on engine or script changes: `cargo run -p ltr` from the `ltheory`
  checkout. This builds and launches the default app in one step. Do not use
  `cargo build` alone for a run; the project's sanctioned dev loop is
  `cargo run`.
- Run a specific app script: `cargo run -p ltr -- <script name without
  extension>` (top-level scripts live in `script/States/App`).
- Format engine code: `./format.sh` (runs `cargo +nightly fmt`). CI fails on
  unformatted engine code.
- Build a packaged binary: `./build.sh` (copies artifacts into `bin/`).
- The default entry point is `./script/Main.lua`. If the script path is not
  found in the working directory, the engine re-bases to the parent of the
  executable path, so launching `target/debug/ltr.exe` from anywhere still
  finds repo assets.

Rendering is threaded by default on `feat/multithreaded_rendering` (the
`--render-thread` CLI flag was removed; threaded rendering became the default).
A healthy threaded run shows log lines "Render thread spawned" /
"Render thread started successfully" / "GL context made current on render
thread" and clean shutdown stats (commands_processed / draw_calls /
frame_count) on exit.

## Branch switches

- Fetch before switching: the local remote-tracking ref may be stale. The
  `feat/multithreaded_rendering` branch has been found 60+ commits behind
  origin after a long period without fetches.
- Stash uncommitted work first (`git stash push -u`) when local edits touch
  files that differ between branches; `git checkout` refuses to switch with
  conflicting local modifications. The stash is recoverable afterwards.
- The Z: share can leave a stale `.git/index.lock` after a crashed git
  process; remove it before retrying git commands.

## Branches and worktrees

Switching branches in the same checkout does not change the workspace target.
When several worktrees are active, give each worktree its own profile if its
instructions or skills differ; share one profile only when that is deliberate.

## Scope

This skill provides project context and workspace hygiene. It does not impose
a task tracker, model provider, deployment platform, or credential workflow.
