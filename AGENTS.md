# Limit Theory Redux — external workspace instructions

These instructions live in the separate `workspace` checkout and are
projected into the provider files at its root. The target source checkout is
the sibling directory `../ltheory`.

Keep the target repository free of generated agent instructions and provider
skill projections. Preserve existing local changes in the target checkout;
this workspace must never overwrite or reset them.

When working on the project:

- inspect the Rust and Lua boundaries before changing APIs or generated
  bindings;
- keep changes scoped to the requested surface and preserve unrelated local
  work;
- use the target repository's own build, format, and test commands;
- verify behavior through the real project path, not only static inspection;
- keep reusable guidance and provider configuration in this workspace.
