--!strict

local Core = require(script.Parent.Core)

export type World = { handle: number }

local World = {}

local function readVec3(ptr: number): Vector3
	local memory = Core.memory()[1]
	return Vector3.new(buffer.readf32(memory, ptr), buffer.readf32(memory, ptr + 4), buffer.readf32(memory, ptr + 8))
end

local function readAABB(ptr: number): { lowerBound: Vector3, upperBound: Vector3 }
	local memory = Core.memory()[1]
	return {
		lowerBound = Vector3.new(buffer.readf32(memory, ptr), buffer.readf32(memory, ptr + 4), buffer.readf32(memory, ptr + 8)),
		upperBound = Vector3.new(buffer.readf32(memory, ptr + 12), buffer.readf32(memory, ptr + 16), buffer.readf32(memory, ptr + 20)),
	}
end

function World.create(gravity: Vector3?): World
	local g = gravity or Vector3.new(0, -9.8, 0)
	local handle = Core.Adapter.b3d_create_world(g.X, g.Y, g.Z)
	Core.assertHandle("world", handle)
	return { handle = handle }
end

function World.destroy(world: World)
	Core.requireExport("b3d_destroy_world", "World.destroy")
	Core.Adapter.b3d_destroy_world(world.handle)
end

function World.step(world: World, timeStep: number, subStepCount: number?)
	Core.Adapter.b3d_step(world.handle, timeStep, subStepCount or 4)
end

function World.isValid(world: World): boolean
	Core.requireExport("b3d_world_is_valid", "World.isValid")
	return Core.Adapter.b3d_world_is_valid(world.handle) ~= 0
end

function World.getCount(): number
	Core.requireExport("b3d_get_world_count", "World.getCount")
	return Core.Adapter.b3d_get_world_count()
end

function World.getBounds(world: World): { lowerBound: Vector3, upperBound: Vector3 }
	Core.requireExport("b3d_world_get_bounds", "World.getBounds")
	local Scratch = require(script.Parent.Internal.Scratch)
	Core.Adapter.b3d_world_get_bounds(world.handle, Scratch.AABB_PTR)
	return readAABB(Scratch.AABB_PTR)
end

function World.setGravity(world: World, gravity: Vector3)
	Core.requireExport("b3d_world_set_gravity", "World.setGravity")
	Core.Adapter.b3d_world_set_gravity(world.handle, gravity.X, gravity.Y, gravity.Z)
end

function World.getGravity(world: World): Vector3
	Core.requireExport("b3d_world_get_gravity", "World.getGravity")
	local Scratch = require(script.Parent.Internal.Scratch)
	Core.Adapter.b3d_world_get_gravity(world.handle, Scratch.VEC3_PTR)
	return readVec3(Scratch.VEC3_PTR)
end

function World.enableSleeping(world: World, enabled: boolean)
	Core.requireExport("b3d_world_enable_sleeping", "World.enableSleeping")
	Core.Adapter.b3d_world_enable_sleeping(world.handle, if enabled then 1 else 0)
end

function World.isSleepingEnabled(world: World): boolean
	Core.requireExport("b3d_world_is_sleeping_enabled", "World.isSleepingEnabled")
	return Core.Adapter.b3d_world_is_sleeping_enabled(world.handle) ~= 0
end

function World.enableContinuous(world: World, enabled: boolean)
	Core.requireExport("b3d_world_enable_continuous", "World.enableContinuous")
	Core.Adapter.b3d_world_enable_continuous(world.handle, if enabled then 1 else 0)
end

function World.isContinuousEnabled(world: World): boolean
	Core.requireExport("b3d_world_is_continuous_enabled", "World.isContinuousEnabled")
	return Core.Adapter.b3d_world_is_continuous_enabled(world.handle) ~= 0
end

function World.setRestitutionThreshold(world: World, value: number)
	Core.requireExport("b3d_world_set_restitution_threshold", "World.setRestitutionThreshold")
	Core.Adapter.b3d_world_set_restitution_threshold(world.handle, value)
end

function World.getRestitutionThreshold(world: World): number
	Core.requireExport("b3d_world_get_restitution_threshold", "World.getRestitutionThreshold")
	return Core.Adapter.b3d_world_get_restitution_threshold(world.handle)
end

function World.setHitEventThreshold(world: World, value: number)
	Core.requireExport("b3d_world_set_hit_event_threshold", "World.setHitEventThreshold")
	Core.Adapter.b3d_world_set_hit_event_threshold(world.handle, value)
end

function World.getHitEventThreshold(world: World): number
	Core.requireExport("b3d_world_get_hit_event_threshold", "World.getHitEventThreshold")
	return Core.Adapter.b3d_world_get_hit_event_threshold(world.handle)
end

function World.setContactTuning(world: World, hertz: number, dampingRatio: number, contactSpeed: number)
	Core.requireExport("b3d_world_set_contact_tuning", "World.setContactTuning")
	Core.Adapter.b3d_world_set_contact_tuning(world.handle, hertz, dampingRatio, contactSpeed)
end

function World.setMaximumLinearSpeed(world: World, speed: number)
	Core.requireExport("b3d_world_set_maximum_linear_speed", "World.setMaximumLinearSpeed")
	Core.Adapter.b3d_world_set_maximum_linear_speed(world.handle, speed)
end

function World.getMaximumLinearSpeed(world: World): number
	Core.requireExport("b3d_world_get_maximum_linear_speed", "World.getMaximumLinearSpeed")
	return Core.Adapter.b3d_world_get_maximum_linear_speed(world.handle)
end

function World.getAwakeBodyCount(world: World): number
	Core.requireExport("b3d_world_get_awake_body_count", "World.getAwakeBodyCount")
	return Core.Adapter.b3d_world_get_awake_body_count(world.handle)
end

function World.explode(world: World, position: Vector3, radius: number, falloff: number, impulsePerArea: number, maskBits: number?)
	Core.requireExport("b3d_world_explode", "World.explode")
	Core.Adapter.b3d_world_explode(world.handle, position.X, position.Y, position.Z, radius, falloff, impulsePerArea, maskBits or -1)
end

return World
