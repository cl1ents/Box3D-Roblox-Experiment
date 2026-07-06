# Box3D API Expansion Plan

Progress: `[--------------------] 0%`

Goal: implement broad Box3D API through flattened C bridge wrappers, grouped Luau adapter modules, Roblox-friendly typed public modules, and configurable wasm export omission for file size control.

## Scope Policy

- [ ] Include simulation/runtime APIs: world, body, shape, joints, query/casts, events, filters/materials, profile/counters, mass data.
- [ ] Include file IO APIs through Roblox `StringValue` objects in `ReplicatedStorage` instead of host filesystem access.
- [ ] Defer poor Roblox-fit APIs unless needed: custom allocators, assert/log callbacks, low-level dynamic tree internals, arbitrary C callbacks.

## Manifest And Generation

- [ ] Add API manifest, likely `wasm/box3d_api.json` or `scripts/box3d-api.lua`.
- [ ] Manifest fields: C bridge name, wasm export name, args, return type, feature group, build mode, Luau adapter target, Roblox wrapper target.
- [ ] Manifest supports per-function omission flags so individual functions can be excluded from wasm compilation/export even when their group is enabled.
- [ ] Manifest supports named omit profiles, such as `demo`, `no-file-io`, `query-only`, `no-joints`, and `full`.
- [ ] Manifest records omission reason text for docs and diagnostics.
- [ ] Add binding generator script under `scripts/`.
- [ ] Generate low-level adapter files by group:

```txt
src/shared/Box3D/Internal/Adapter/
  init.luau
  Runtime.luau
  World.luau
  Body.luau
  Shape.luau
  Joint.luau
  Query.luau
  Events.luau
  Collision.luau
```

- [ ] Keep root adapter runtime shared and lazy.
- [ ] Generate CMake `EXPORTED_FUNCTIONS` from manifest.
- [ ] Generate omitted-function metadata for Luau so adapters know which functions were intentionally excluded.
- [ ] Prevent drift between C bridge, CMake exports, Luau adapter, and docs.

## Missing Export Handling

- [ ] Add a shared adapter handler for omitted or unavailable wasm exports.
- [ ] Handler must error exactly:

```txt
{name} is not included!
```

- [ ] Use wasm export name or public wrapper name consistently for `{name}`; decide and document the convention before generation.
- [ ] Generated adapter wrappers must call this handler when an omitted function is invoked.
- [ ] Public wrapper methods must not silently no-op when backing wasm function is omitted.
- [ ] Add tests or Studio smoke cases proving omitted functions throw the expected message.
- [ ] Update docs showing how omitted APIs save wasm/Luau size and how runtime errors appear.

## C Bridge Expansion

- [ ] Expand handle registries in `wasm/box3d_bridge.c`.
- [ ] Keep current registries for worlds, bodies, shapes.
- [ ] Add registries for joints, hulls, meshes, heightfields, compounds, and possibly recordings/players later.
- [ ] Use flattened bridge calls instead of exposing raw C structs directly.
- [ ] Use C-side result buffers for callback-style APIs.

## World API

- [ ] `destroy`
- [ ] `step`
- [ ] `setGravity`
- [ ] `getGravity -> Vector3`
- [ ] `enableSleeping`
- [ ] `isSleepingEnabled`
- [ ] `enableContinuous`
- [ ] `isContinuousEnabled`
- [ ] `setRestitutionThreshold`
- [ ] `getRestitutionThreshold`
- [ ] `setHitEventThreshold`
- [ ] `getHitEventThreshold`
- [ ] `getCounters`
- [ ] `getProfile`
- [ ] `explode`

## Body API

- [ ] create/destroy
- [ ] get/set `CFrame`
- [ ] get/set linear velocity
- [ ] get/set angular velocity
- [ ] apply force
- [ ] apply torque
- [ ] apply linear impulse
- [ ] apply angular impulse
- [ ] get/set type
- [ ] enable/disable
- [ ] sleep/wake
- [ ] enable gravity
- [ ] get/set damping
- [ ] get/set mass data
- [ ] local/world point and vector helpers where useful

## Shape API

- [ ] sphere
- [ ] capsule
- [ ] box
- [ ] hull
- [ ] mesh
- [ ] heightfield
- [ ] compound if feasible
- [ ] destroy
- [ ] get/set material
- [ ] get/set friction
- [ ] get/set restitution
- [ ] get/set density
- [ ] get/set filter
- [ ] set sensor
- [ ] get AABB
- [ ] get body
- [ ] test point / ray cast if upstream supports direct shape query

## Joint API

- [ ] Add `Joint.luau` root module.
- [ ] Add `Joints/Distance.luau`.
- [ ] Add `Joints/Motor.luau`.
- [ ] Add `Joints/Prismatic.luau`.
- [ ] Add `Joints/Revolute.luau`.
- [ ] Add `Joints/Spherical.luau`.
- [ ] Add `Joints/Weld.luau`.
- [ ] Add `Joints/Wheel.luau`.
- [ ] Implement create/destroy.
- [ ] Implement get type.
- [ ] Implement get bodies.
- [ ] Implement enable/disable collision.
- [ ] Implement per-joint params, motors, limits, and springs where present.

## Query API

- [ ] Implement C-side query result buffers.
- [ ] Implement overlap AABB.
- [ ] Implement raycast closest.
- [ ] Implement raycast all.
- [ ] Implement shape cast.
- [ ] Implement body/shape cast if practical.
- [ ] Return Roblox-friendly hit tables:

```luau
type RayHit = {
  shape: Shape,
  body: Body?,
  position: Vector3,
  normal: Vector3,
  fraction: number,
}
```

## Event API

- [ ] Expose transient event arrays after `World.step`.
- [ ] Copy event data into Luau tables immediately.
- [ ] Body move events.
- [ ] Sensor begin/end touch events.
- [ ] Contact begin/end/hit events.
- [ ] Joint events.
- [ ] Return handles and `Vector3` fields instead of raw pointers.

## Collision And Math API

- [ ] Expose useful stable helpers only.
- [ ] AABB validation.
- [ ] Ray/shape cast helpers.
- [ ] Mass computation.
- [ ] Distance/TOI APIs if useful.
- [ ] Hull creation/conversion if needed by shape APIs.
- [ ] Defer huge low-level dynamic tree API until concrete use case exists.

## Build Feature Groups

- [ ] Keep minimal demo build.
- [ ] Keep full API build.
- [ ] Add explicit per-function omit support for wasm compilation/export.
- [ ] Add build input for omitted functions, e.g. `BOX3D_WASM_OMIT_FUNCTIONS=b3d_world_explode;b3d_shape_create_mesh`.
- [ ] Add build input for omit profiles, e.g. `BOX3D_WASM_API_PROFILE=demo|full|custom`.
- [ ] Make omitted functions absent from `EXPORTED_FUNCTIONS` so Emscripten LTO/GC can strip unreachable code.
- [ ] Emit Luau omitted-function metadata during binding generation.
- [ ] Keep wrappers present where useful, but route calls to `{name} is not included!` handler when omitted.
- [ ] Add optional feature groups later:

```cmake
BOX3D_WASM_API_WORLD=ON
BOX3D_WASM_API_BODY=ON
BOX3D_WASM_API_SHAPE=ON
BOX3D_WASM_API_JOINT=ON
BOX3D_WASM_API_QUERY=ON
BOX3D_WASM_API_EVENTS=ON
BOX3D_WASM_API_FILE_IO=OFF
BOX3D_WASM_OMIT_FUNCTIONS=""
BOX3D_WASM_FULL_API=OFF
```

## Roblox File IO API

- [ ] Map Box3D file-write APIs to `StringValue` instances under `ReplicatedStorage`.
- [ ] Create a root container, likely `ReplicatedStorage.Box3DFileIO`.
- [ ] For each file write, create or update a `StringValue` where `Name` is the sanitized file path or logical filename.
- [ ] Store file bytes/text in `StringValue.Value` when data is valid UTF-8/text.
- [ ] Define binary policy for non-text data: base64 encode, hex encode, or reject with clear error.
- [ ] Add metadata attributes on each `StringValue`, such as `OriginalName`, `Encoding`, `ByteLength`, and `UpdatedAt`.
- [ ] Map Box3D file-read APIs to read from `ReplicatedStorage.Box3DFileIO` by logical filename.
- [ ] Validate names to prevent unexpected hierarchy/path traversal behavior.
- [ ] Add helper API:

```luau
Box3D.FileIO.getFolder(): Folder
Box3D.FileIO.read(name: string): string?
Box3D.FileIO.write(name: string, contents: string, encoding: string?)
Box3D.FileIO.clear(name: string?)
```

- [ ] Add build flag `BOX3D_WASM_API_FILE_IO=ON` for including these APIs.
- [ ] Default file IO to omitted/off to save size unless explicitly enabled.
- [ ] Ensure omitted file IO methods use `{name} is not included!` handler.

## Examples And Tests

- [ ] Keep default ramp demo working.
- [ ] Add optional examples under `src/server/examples/`:

```txt
Ramp.server.luau
Joints.server.luau
Raycast.server.luau
Events.server.luau
```

- [ ] Validate each group with wasm build, Luau build, and Rojo sourcemap.
- [ ] Studio-test world/body/shape smoke.
- [ ] Studio-test joint smoke.
- [ ] Studio-test raycast smoke.
- [ ] Studio-test events smoke.
- [ ] Track performance and file size after each group.

## Execution Order

- [ ] Finish restructure pass.
- [ ] Fix any Studio runtime regressions.
- [ ] Add manifest and generator scaffolding.
- [ ] Migrate current bridge functions into manifest/generated adapter.
- [ ] Add `World` group.
- [ ] Add `Body` group.
- [ ] Add `Shape` group.
- [ ] Add `Joint` group.
- [ ] Add `Query` group.
- [ ] Add `Events` group.
- [ ] Add file IO group.
- [ ] Add collision/helpers last.

## Main Risk

Spider still emits one huge `build-wasm/box3d.luau`. Wrapper and adapter files can be split and lazy-required, but compiled wasm output cannot be split safely without risky Spider-output surgery. Near-term win is lazy wrapper modules plus feature-group and per-function wasm export omission.

## Done Criteria

- [ ] Manifest owns exported API surface.
- [ ] CMake exports are generated or synchronized from manifest.
- [ ] Adapter modules are split by domain.
- [ ] Public modules return Roblox-friendly types.
- [ ] Default build remains small.
- [ ] Full API build exposes broad Box3D API.
- [ ] Omitted wasm functions are stripped from exports and throw `{name} is not included!` when called.
- [ ] File IO APIs use `ReplicatedStorage` `StringValue` objects instead of host filesystem access.
- [ ] Demos validate major API groups in Studio.
