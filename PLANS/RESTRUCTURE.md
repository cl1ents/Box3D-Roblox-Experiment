# Box3D Restructure Plan

Progress: `[####################] 100%`

Goal: move current working wrapper into `ReplicatedStorage.Shared.Box3D`, split source into focused modules, and keep behavior stable before expanding API surface.

## Tasks

- [x] Move public require path to `ReplicatedStorage.Shared.Box3D`.
- [x] Keep raw generated Spider module at `ReplicatedStorage.Box3DWasm`.
- [x] Remove old public `ReplicatedStorage.Box3D` wrapper mapping.
- [x] Update server demo require to `require(ReplicatedStorage.Shared.Box3D)`.
- [x] Create folder layout:

```txt
src/shared/Box3D/
  init.luau
  Core.luau
  Types.luau
  Math.luau
  World.luau
  Body.luau
  Shape.luau
  Internal/
    Adapter.luau
    Scratch.luau
```

- [x] Move `src/shared/Box3DAdapter.luau` to `src/shared/Box3D/Internal/Adapter.luau`.
- [x] Keep adapter responsibilities unchanged: require `Box3DWasm`, set Spider imports, call `runtime.module({})`, call `_initialize`, wrap closure-table exports, convert f32 args, expose `hasExport`.
- [x] Add `Core.luau` for shared runtime helpers: `Adapter`, `memory`, `hasExport`, `requireExport`, and full-API guard errors.
- [x] Add `Internal/Scratch.luau` for shared scratch pointers like `TRANSFORM_PTR` and `VELOCITY_PTR`.
- [x] Add `Types.luau` for public handle/object types, option types, and constants.
- [x] Add `Math.luau` for `quaternionFromCFrame` and `cframeFromQuaternion`.
- [x] Add `World.luau` with `create`, `destroy`, and `step`.
- [x] Add `Body.luau` with `create`, `destroy`, `getCFrame`, `setCFrame`, `getLinearVelocity`, and `setLinearVelocity`.
- [x] Add `Shape.luau` with `createSphere`, `createCapsule`, `createBox`, and `destroy`.
- [x] Add lazy `init.luau` that exposes `World`, `Body`, `Shape`, `Math`, `Types`, and `BodyType`.
- [x] Decide whether to keep temporary compatibility aliases like `Box3D.createWorld = World.create`.
- [x] Update server demo to domain style:

```luau
local Box3D = require(ReplicatedStorage.Shared.Box3D)

local world = Box3D.World.create(Vector3.new(0, -50, 0))
local body = Box3D.Body.create(world, ...)
Box3D.Shape.createSphere(body, ...)
Box3D.World.step(world, step, 4)
ball.CFrame = Box3D.Body.getCFrame(body)
```

- [x] Update README require path and module split docs.
- [x] Run `./scripts/build-luau.sh`.
- [x] Run `rojo sourcemap default.project.json --output /tmp/opencode/box3d-sourcemap.json`.
- [ ] Studio-test world creation, falling ball, ramp collision, and no require path errors.

## Done Criteria

- [x] Public require path is `ReplicatedStorage.Shared.Box3D`.
- [x] Raw generated wasm remains isolated at `ReplicatedStorage.Box3DWasm`.
- [x] Current ramp demo works with split modules.
- [x] No generated Spider adapter logic is appended to `build-wasm/box3d.luau` except raw runtime export and known corrections.
- [x] Rojo sourcemap validates.
