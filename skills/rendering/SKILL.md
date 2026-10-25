---
name: rendering
description: Render architecture — the wgpu renderer behind Renderer/RenderCommand, the dedicated render thread, the Lua render API (passes, pipelines, materials, scene list, Imm), shaders and the validation harness. Use when touching engine/lib/phx/src/render, window/wgpu_render.rs, res/shader or Lua draw code.
---

# Rendering

The renderer runs on wgpu (Vulkan, Metal or DX12: the platform's native API;
`WGPU_BACKEND=vulkan|metal|dx12` overrides it for diagnostics). There is no
OpenGL backend and no backend switch. All rendering code lives in
`engine/lib/phx/src/render/`; the docs are in `doc/engine/` (start with
`render-thread.md` and `shader-system.md`; `render-api-v2.md` and
`wgpu-migration-gaps.md` are migration history).

## Layers

```
Lua (script/Render, script/Modules/Rendering, materials)
  -> FFI types: Renderer, RenderPass, Pipeline, Material, SceneList, Imm, Tex*, Mesh, Shader
  -> main-thread Renderer (render/thread/renderer_threaded.rs): records passes,
     owns the uniform/vertex rings and resource ids
  -> bounded RenderCommand channel
  -> render thread (render_thread.rs) -> WgpuCommandExecutor
     (render/thread/command_executor_wgpu.rs + command_executor_wgpu/)
  -> wgpu device, queue, surface
```

- `render/gpu/` holds the backend-independent front end: pipelines, samplers,
  texture views, bind groups, materials, the scene list, the immediate batcher
  (`imm.rs`), the uniform/vertex staging rings, readback and procedural
  generation.
- The executor owns every GPU object and the surface; nothing on the main
  thread calls wgpu.
- Startup: `Engine::new` creates the window with winit, builds the surface
  bundle (`window/wgpu_render.rs`) and calls `Renderer::start`. Dropping
  `Renderer` joins the render thread; `Engine` declares `winit_window` after
  `renderer` so the surface (made from the window's raw handles) goes first.
- `Renderer::new_headless()` (tests only) has no device; it answers fences and
  reply channels and returns ring memory.

## Shaders

GLSL 330 sources in `res/shader/` are preprocessed (`#include`, `#group N`)
and adapted for naga (`command_executor_wgpu/shader.rs`). Every uniform a
shader reads must sit in a `#group` uniform block or be a sampler declared
under a `#group`; there is no per-name uniform setter. Shared blocks
(`ViewBlock`, `DrawBlock`) have Rust mirrors in `render/gpu/` with layout
checks (`render/thread/layout_parity.rs`). Hot reload keeps the last working
program on failure.

## Guidelines

- Every `RenderCommand` must stay `Send` and self-contained.
- Resource writes (texture uploads, buffer writes) are not allowed inside an
  open pass: wgpu orders `queue.write_*` before the whole submission.
- Changes to FFI-exposed render types regenerate files in `ffi_gen`/`meta` —
  commit those (see `luajit-ffi-bindings` skill).
- `LTHEORY_WGPU_FATAL=1` turns the first wgpu validation error into a panic;
  `LTHEORY_WGPU_DIAG` / `LTHEORY_WGPU_DUMP` are opt-in diagnostics
  (`command_executor_wgpu/diag.rs`).

## Validation

`tools/render_validation/` (see its README): 13 pixel-probe supervisors, deterministic
scene captures (`capture.py`, `compare.py`), `auto_exposure_test.py` and
`hot_reload_probe.py`, all run as `<script> wgpu`. Captures differ per driver
and platform: for a change that must not alter pixels, build the earlier
commit in a separate worktree, capture there with its own
`LTHEORY_VALIDATION_ARTIFACT_DIR`, and run
`compare.py wgpu --reference <ref-artifacts>/captures/wgpu`. Run GPU suites
serially, never two at once.

GPU unit tests are `#[ignore]`d:
`cargo test -p phx --lib command_executor_wgpu -- --ignored --test-threads=1`.
