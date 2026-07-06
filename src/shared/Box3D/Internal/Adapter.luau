--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Omitted = require(script.Parent.Omitted)

type Runtime = {
	module: ({ any }) -> (),
	rt_import_map: { [string]: { [string]: any } },
	rt_export_map: { [string]: any },
	into_bits_f32: (number) -> number,
}

type Adapter = {
	memory: { buffer },
	hasExport: (name: string) -> boolean,
	_initialize: () -> (),
	requireExport: (name: string, publicName: string?) -> (),
	malloc: (size: number) -> number,
	free: (ptr: number) -> (),
	b3d_create_world: (gravityX: number, gravityY: number, gravityZ: number) -> number,
	b3d_destroy_world: (worldHandle: number) -> (),
	b3d_step: (worldHandle: number, timeStep: number, subStepCount: number) -> (),
	b3d_create_body: (worldHandle: number, bodyType: number, x: number, y: number, z: number, qx: number, qy: number, qz: number, qw: number) -> number,
	b3d_destroy_body: (bodyHandle: number) -> (),
	b3d_create_sphere: (bodyHandle: number, radius: number, density: number, friction: number, restitution: number) -> number,
	b3d_create_capsule: (bodyHandle: number, ax: number, ay: number, az: number, bx: number, by: number, bz: number, radius: number, density: number, friction: number, restitution: number) -> number,
	b3d_create_box: (bodyHandle: number, hx: number, hy: number, hz: number, density: number, friction: number, restitution: number) -> number,
	b3d_destroy_shape: (shapeHandle: number) -> (),
	b3d_get_body_transform: (bodyHandle: number, outPtr: number?) -> (),
	b3d_set_body_transform: (bodyHandle: number, x: number, y: number, z: number, qx: number, qy: number, qz: number, qw: number) -> (),
	b3d_get_body_linear_velocity: (bodyHandle: number, outPtr: number?) -> (),
	b3d_set_body_linear_velocity: (bodyHandle: number, x: number, y: number, z: number) -> (),
}

local runtime = require(ReplicatedStorage:WaitForChild("Box3DWasm")) :: Runtime
local rawExports = runtime.rt_export_map
local initialized = false
local adapter = {} :: Adapter

runtime.rt_import_map.env = {
	emscripten_notify_memory_growth = { function() end },
}

runtime.rt_import_map.wasi_snapshot_preview1 = {
	clock_time_get = { function(_, _, _, outPtr: number)
		buffer.writeu32(rawExports.memory[1], outPtr, 0)
		buffer.writeu32(rawExports.memory[1], outPtr + 4, 0)
		return 0
	end },

	fd_write = { function()
		return 0
	end },
}

local done = {
	function(_, ...)
		return ...
	end,
}

local function ensureInitialized()
	if not initialized then
		runtime.module({})
		initialized = true
		adapter.memory = rawExports.memory

		if rawExports._initialize then
			rawExports._initialize[1](rawExports._initialize, done)
		end
	end
end

local function getExport(name: string): any?
	ensureInitialized()
	return rawExports[name]
end

local function missingExport(name: string, publicName: string?)
	local omitted = Omitted[name]
	if omitted then
		error(`{publicName or omitted.publicName or name} is not included!`, 3)
	end

	error(`Box3D wasm export {name} is unavailable.`, 3)
end

local function call(name: string, ...): any
	local export = getExport(name)
	if not export then
		missingExport(name, nil)
	end
	local callable = export :: any

	local args = table.pack(...)
	args.n += 1
	args[args.n] = done

	return callable[1](callable, table.unpack(args, 1, args.n))
end

local FLOAT_ARGS: { [string]: { number } } = {
	b3d_create_world = { 1, 2, 3 },
	b3d_step = { 2 },
	b3d_world_set_gravity = { 2, 3, 4 },
	b3d_world_set_restitution_threshold = { 2 },
	b3d_world_set_hit_event_threshold = { 2 },
	b3d_world_set_contact_tuning = { 2, 3, 4 },
	b3d_world_set_maximum_linear_speed = { 2 },
	b3d_world_explode = { 2, 3, 4, 5, 6, 7 },
	b3d_create_body = { 3, 4, 5, 6, 7, 8, 9 },
	b3d_set_body_transform = { 2, 3, 4, 5, 6, 7, 8 },
	b3d_set_body_linear_velocity = { 2, 3, 4 },
	b3d_body_set_angular_velocity = { 2, 3, 4 },
	b3d_body_apply_force = { 2, 3, 4, 5, 6, 7 },
	b3d_body_apply_force_to_center = { 2, 3, 4 },
	b3d_body_apply_torque = { 2, 3, 4 },
	b3d_body_apply_linear_impulse = { 2, 3, 4, 5, 6, 7 },
	b3d_body_apply_linear_impulse_to_center = { 2, 3, 4 },
	b3d_body_apply_angular_impulse = { 2, 3, 4 },
	b3d_body_set_mass_data = { 2, 3, 4, 5, 6, 7, 8 },
	b3d_body_set_linear_damping = { 2 },
	b3d_body_set_angular_damping = { 2 },
	b3d_body_set_gravity_scale = { 2 },
	b3d_create_sphere = { 2, 3, 4, 5 },
	b3d_create_sphere_ex = { 2, 3, 4, 5, 6, 7, 8 },
	b3d_create_capsule = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
	b3d_create_box = { 2, 3, 4, 5, 6, 7 },
	b3d_shape_set_density = { 2 },
	b3d_shape_set_friction = { 2 },
	b3d_shape_set_restitution = { 2 },
	b3d_shape_get_closest_point = { 2, 3, 4 },
	b3d_shape_ray_cast = { 2, 3, 4, 5, 6, 7 },
	b3d_create_distance_joint = { 4, 5, 6, 7, 8, 9, 10 },
	b3d_create_weld_joint = { 4, 5, 6, 7, 8, 9 },
	b3d_distance_joint_set_length = { 2 },
	b3d_distance_joint_set_spring_hertz = { 2 },
	b3d_distance_joint_set_spring_damping_ratio = { 2 },
	b3d_distance_joint_set_length_range = { 2, 3 },
	b3d_distance_joint_set_motor_speed = { 2 },
	b3d_distance_joint_set_max_motor_force = { 2 },
	b3d_world_cast_ray_closest = { 2, 3, 4, 5, 6, 7 },
	b3d_world_overlap_aabb = { 2, 3, 4, 5, 6, 7 },
	b3d_world_cast_ray_all = { 2, 3, 4, 5, 6, 7 },
	b3d_compute_sphere_mass = { 1, 2, 3, 4, 5 },
	b3d_compute_capsule_mass = { 1, 2, 3, 4, 5, 6, 7, 8 },
	b3d_compute_sphere_aabb = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
	b3d_is_valid_ray = { 1, 2, 3, 4, 5, 6, 7 },
	b3d_ray_cast_sphere = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
	b3d_ray_cast_capsule = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
}

local function makeBridgeCall(name: string)
	local floatArgs = FLOAT_ARGS[name]
	return function(...)
		local args = table.pack(...)
		if floatArgs then
			for _, index in floatArgs do
				args[index] = runtime.into_bits_f32(args[index])
			end
		end

		return call(name, table.unpack(args, 1, args.n))
	end
end

adapter.memory = {} :: { buffer }

function adapter.hasExport(name: string): boolean
	ensureInitialized()
	return rawExports[name] ~= nil
end

function adapter.requireExport(name: string, publicName: string?)
	if not adapter.hasExport(name) then
		missingExport(name, publicName)
	end
end

function adapter._initialize()
	ensureInitialized()
end

function adapter.b3d_create_world(gravityX: number, gravityY: number, gravityZ: number): number
	return call("b3d_create_world", runtime.into_bits_f32(gravityX), runtime.into_bits_f32(gravityY), runtime.into_bits_f32(gravityZ))
end

function adapter.b3d_step(worldHandle: number, timeStep: number, subStepCount: number)
	call("b3d_step", worldHandle, runtime.into_bits_f32(timeStep), subStepCount)
end

function adapter.b3d_create_body(worldHandle: number, bodyType: number, x: number, y: number, z: number, qx: number, qy: number, qz: number, qw: number): number
	return call("b3d_create_body", worldHandle, bodyType, runtime.into_bits_f32(x), runtime.into_bits_f32(y), runtime.into_bits_f32(z), runtime.into_bits_f32(qx), runtime.into_bits_f32(qy), runtime.into_bits_f32(qz), runtime.into_bits_f32(qw))
end

function adapter.b3d_create_sphere(bodyHandle: number, radius: number, density: number, friction: number, restitution: number): number
	return call("b3d_create_sphere", bodyHandle, runtime.into_bits_f32(radius), runtime.into_bits_f32(density), runtime.into_bits_f32(friction), runtime.into_bits_f32(restitution))
end

function adapter.b3d_create_box(bodyHandle: number, hx: number, hy: number, hz: number, density: number, friction: number, restitution: number): number
	return call("b3d_create_box", bodyHandle, runtime.into_bits_f32(hx), runtime.into_bits_f32(hy), runtime.into_bits_f32(hz), runtime.into_bits_f32(density), runtime.into_bits_f32(friction), runtime.into_bits_f32(restitution))
end

function adapter.b3d_get_body_transform(bodyHandle: number, outPtr: number?)
	call("b3d_get_body_transform", bodyHandle, outPtr or 1048576)
end

adapter.malloc = function(size: number): number
	return call("malloc", size)
end

adapter.free = function(ptr: number)
	call("free", ptr)
end

adapter.b3d_destroy_world = function(worldHandle: number)
	call("b3d_destroy_world", worldHandle)
end

adapter.b3d_destroy_body = function(bodyHandle: number)
	call("b3d_destroy_body", bodyHandle)
end

adapter.b3d_create_capsule = function(bodyHandle: number, ax: number, ay: number, az: number, bx: number, by: number, bz: number, radius: number, density: number, friction: number, restitution: number): number
	return call("b3d_create_capsule", bodyHandle, runtime.into_bits_f32(ax), runtime.into_bits_f32(ay), runtime.into_bits_f32(az), runtime.into_bits_f32(bx), runtime.into_bits_f32(by), runtime.into_bits_f32(bz), runtime.into_bits_f32(radius), runtime.into_bits_f32(density), runtime.into_bits_f32(friction), runtime.into_bits_f32(restitution))
end

adapter.b3d_destroy_shape = function(shapeHandle: number)
	call("b3d_destroy_shape", shapeHandle)
end

adapter.b3d_set_body_transform = function(bodyHandle: number, x: number, y: number, z: number, qx: number, qy: number, qz: number, qw: number)
	call("b3d_set_body_transform", bodyHandle, runtime.into_bits_f32(x), runtime.into_bits_f32(y), runtime.into_bits_f32(z), runtime.into_bits_f32(qx), runtime.into_bits_f32(qy), runtime.into_bits_f32(qz), runtime.into_bits_f32(qw))
end

adapter.b3d_get_body_linear_velocity = function(bodyHandle: number, outPtr: number?)
	call("b3d_get_body_linear_velocity", bodyHandle, outPtr or 1048608)
end

adapter.b3d_set_body_linear_velocity = function(bodyHandle: number, x: number, y: number, z: number)
	call("b3d_set_body_linear_velocity", bodyHandle, runtime.into_bits_f32(x), runtime.into_bits_f32(y), runtime.into_bits_f32(z))
end

return setmetatable(adapter :: any, {
	__index = function(self, key: string)
		if string.sub(key, 1, 4) ~= "b3d_" then
			return nil
		end

		local fn = makeBridgeCall(key) :: any
		rawset(self, key, fn)
		return fn
	end,
}) :: Adapter
