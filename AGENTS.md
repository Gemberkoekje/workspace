# AGENTS.md — workspace

This repository is a small, provider-neutral external workspace module. It
must remain independent of any particular project, service, language, or model
provider.

The module writes only to paths explicitly named by a manifest, and refuses
instruction or skill destinations inside the configured target repository.
Keep synchronization non-destructive: unrelated provider skills and local
project changes must survive a bootstrap.

Use `bash tests/test.sh` for the local fixture check. Do not add project
credentials, generated provider projections, or a target repository checkout
to this repository.

## Git commits

Use Conventional Commits for every commit made in a repository managed by
this workspace: `type(scope): summary`, with the scope optional. Use a
lowercase, imperative summary and one of the standard types such as `feat`,
`fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore`, or `revert`.
Record breaking changes with `!` or a `BREAKING CHANGE:` footer. Keep commits
focused, inspect the staged diff before committing, and never include secrets,
generated projections, or target-repository files by accident.
