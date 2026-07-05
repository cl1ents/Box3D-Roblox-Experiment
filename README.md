# Box3D Roblox

Box3D compiled to WebAssembly, then translated with [Spider](https://github.com/SovereignSatellite/Spider) for Luau/LuaJIT experiments.

Initial Nix, wasm bridge, Spider build scripts, and Rojo example were generated with OpenAI GPT-5.5 via OpenCode.

## Setup

This repo uses Nix flakes and direnv.

```sh
direnv allow
```

Or enter the shell manually:

```sh
nix develop
```

The dev shell includes:

- CMake
- Ninja
- Emscripten
- Node.js
- WABT
- Rust/Cargo
- `spider-cli`

`spider-cli` installs itself on first use from Spider `trunk` into `.direnv/spider`.

## Build Wasm

```sh
scripts/build-wasm.sh
```

Output:

```sh
build-wasm/box3d_wasm.wasm
```

The wasm build uses `wasm/CMakeLists.txt` as a wrapper around the upstream `box3d` submodule. This avoids Box3D's top-level Emscripten pthread setup and produces a single-thread standalone wasm module.

## Compile To Luau

```sh
scripts/build-luau.sh
```

Output:

```sh
build-wasm/box3d.luau
```

`scripts/build-luau.sh` appends `return rt_export_map` so Rojo can mount the generated Luau as a `ModuleScript`.

## Rojo Example

`default.project.json` maps `build-wasm/box3d.luau` directly into `ReplicatedStorage.Box3D`.

```sh
scripts/build-wasm.sh
scripts/build-luau.sh
rojo serve
```

Open Roblox Studio with the Rojo plugin, connect to the server, and press Play. The server script creates a Box3D world, steps a falling sphere, and mirrors the transform onto an anchored Roblox ball.

## Wasm ABI

The bridge lives in `wasm/box3d_bridge.c`. It exports a small handle-based API so Luau/Spider callers do not need to pass Box3D structs directly.

Body types:

- `0`: static
- `1`: kinematic
- `2`: dynamic

Exported functions:

- `b3d_create_world(gravity_x, gravity_y, gravity_z) -> world_handle`
- `b3d_destroy_world(world_handle)`
- `b3d_step(world_handle, time_step, sub_step_count)`
- `b3d_create_body(world_handle, body_type, x, y, z, qx, qy, qz, qw) -> body_handle`
- `b3d_destroy_body(body_handle)`
- `b3d_create_sphere(body_handle, radius, density, friction, restitution) -> shape_handle`
- `b3d_create_capsule(body_handle, ax, ay, az, bx, by, bz, radius, density, friction, restitution) -> shape_handle`
- `b3d_create_box(body_handle, hx, hy, hz, density, friction, restitution) -> shape_handle`
- `b3d_destroy_shape(shape_handle)`
- `b3d_get_body_transform(body_handle, out_ptr)` writes 7 floats: `x, y, z, qx, qy, qz, qw`
- `b3d_set_body_transform(body_handle, x, y, z, qx, qy, qz, qw)`
- `b3d_get_body_linear_velocity(body_handle, out_ptr)` writes 3 floats: `x, y, z`
- `b3d_set_body_linear_velocity(body_handle, x, y, z)`
- `malloc(size) -> ptr`
- `free(ptr)`

Invalid handles return `0` or write identity/default values.

## Smoke Test

Build was verified by instantiating `build-wasm/box3d_wasm.wasm` in Node, creating a static ground box and dynamic sphere, stepping 60 frames, and reading the final body transform.

## Notes

- `BOX3D_DISABLE_SIMD=ON` for the wasm wrapper today. This keeps the output conservative for Spider.
- Build output stays in `build-wasm/` and is gitignored.
- Add more bridge exports in `wasm/box3d_bridge.c` as Roblox needs grow.
