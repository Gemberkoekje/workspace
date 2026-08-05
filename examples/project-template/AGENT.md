# Example project — external agent context

This instruction file is maintained outside the target repository.

Keep project-specific guidance, provider adapters, and skills in the external
agent workspace. Do not add generated agent files to the product repository
unless the project owner explicitly chooses that trade-off.

When working on the project:

- inspect existing boundaries before changing APIs;
- preserve unrelated local work and untracked provider settings;
- run the smallest real project check that covers the changed surface;
- record assumptions in the external workspace rather than in generated
  provider projections.

## Version control

Use Conventional Commits for every project commit: `type(scope): summary`,
with an optional scope. Keep the summary lowercase, imperative, and focused;
use standard types such as `feat`, `fix`, `docs`, `refactor`, `test`, `build`,
`ci`, `chore`, or `revert`. Mark breaking changes with `!` or a
`BREAKING CHANGE:` footer, and inspect the staged diff before committing.
