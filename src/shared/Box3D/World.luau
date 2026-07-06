--!strict

local Core = require(script.Parent.Core)

export type World = { handle: number }

local World = {}

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

return World
