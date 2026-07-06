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

Default build exports only the functions used by the Rojo demo so Emscripten LTO and wasm GC can strip unused bridge paths. The exported API surface is generated from `wasm/box3d_api.json` before CMake runs.

The wasm build also writes API coverage reports from upstream Box3D headers:

- `build-wasm/box3d_api_coverage.json`: machine-readable status for every `B3_API` symbol.
- `build-wasm/box3d_api_coverage.md`: readable topic summary and unmapped API list.

Run `python3 scripts/generate-api-coverage.py --check` when intentionally enforcing that every upstream API has an implemented, omitted, unsupported, callback, or file-IO decision.

API profile controls:

- `BOX3D_WASM_API_PROFILE=demo scripts/build-wasm.sh`: demo exports only.
- `BOX3D_WASM_API_PROFILE=full scripts/build-wasm.sh`: all manifest exports.
- `BOX3D_WASM_FULL_API=ON scripts/build-wasm.sh`: legacy alias for the full profile.
- `BOX3D_WASM_OMIT_FUNCTIONS=b3d_destroy_world;b3d_create_capsule scripts/build-wasm.sh`: omit individual bridge exports.

Omitted functions stay visible in the Roblox wrapper where useful, but throw `{name} is not included!` when called.

## Compile To Luau

```sh
scripts/build-luau.sh
```

Output:

```sh
build-wasm/box3d.luau
```

`scripts/build-luau.sh` keeps generated Spider code raw except for Spider-output corrections and a small runtime export table. Roblox-facing adapters live in normal source files.

## Rojo Example

`default.project.json` maps generated Spider output to `ReplicatedStorage.Box3DWasm` and the typed Roblox wrapper to `ReplicatedStorage.Shared.Box3D`.

Wrapper modules:

- `src/shared/Box3D/Internal/Adapter.luau`: low-level Spider closure/import adapter.
- `src/shared/Box3D/Internal/Omitted.luau`: generated omitted-function metadata.
- `src/shared/Box3D/init.luau`: typed Roblox API entrypoint returning handle objects, `Vector3`, and `CFrame`.
- `src/shared/Box3D/{World,Body,Shape,Joint,Query,Events,Collision,Math,Types}.luau`: focused API modules loaded by the entrypoint.

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

Default exported functions:

- `b3d_create_world(gravity_x, gravity_y, gravity_z) -> world_handle`
- `b3d_step(world_handle, time_step, sub_step_count)`
- `b3d_create_body(world_handle, body_type, x, y, z, qx, qy, qz, qw) -> body_handle`
- `b3d_create_sphere(body_handle, radius, density, friction, restitution) -> shape_handle`
- `b3d_create_box(body_handle, hx, hy, hz, density, friction, restitution) -> shape_handle`
- `b3d_get_body_transform(body_handle, out_ptr)` writes 7 floats: `x, y, z, qx, qy, qz, qw`

Extra groups with `BOX3D_WASM_FULL_API=ON`:

- World settings, bounds, counters/profile, awake body count, explosion helper.
- Body validity/type, angular velocity, forces, impulses, damping, gravity scale, sleep/awake, enable/disable, bullet flag, mass data, shape/joint counts, AABB.
- Shape extended sphere options, capsule/box, validity/type/body/sensor, density/friction/restitution/filter, sensor/contact/hit event flags, AABB, mass data, closest point, ray cast.
- Joint handles, distance/filter/weld creation, destroy/valid/type/body lookup, constraint force/torque/separation, distance joint spring/limit/motor setters.
- Query helpers for raycast closest, raycast all, and AABB overlap using C-side result buffers.
- Event helpers for body move, sensor begin/end, contact begin/end/hit, and joint events.
- Collision helpers for primitive mass/AABB and ray casts.
- `malloc(size) -> ptr` and `free(ptr)` for adapter scratch use.

Still intentionally omitted: raw `userData` pointers, arbitrary callback APIs, debug draw callbacks, low-level dynamic tree internals, host filesystem APIs, and mesh/heightfield/compound asset ownership until a Roblox-safe registry is added.

Invalid handles return `0` or write identity/default values.

## Smoke Test

Build was verified by instantiating `build-wasm/box3d_wasm.wasm` in Node, creating a static ground box and dynamic sphere, stepping 60 frames, and reading the final body transform.

## Notes

- `BOX3D_DISABLE_SIMD=ON` for the wasm wrapper today. This keeps the output conservative for Spider.
- Build output stays in `build-wasm/` and is gitignored.
- Add more bridge exports in `wasm/box3d_bridge.c` as Roblox needs grow.
