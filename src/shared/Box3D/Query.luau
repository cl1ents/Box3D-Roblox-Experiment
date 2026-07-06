--!strict

local Core = require(script.Parent.Core)
local Scratch = require(script.Parent.Internal.Scratch)

export type World = { handle: number }
export type Shape = { handle: number }
export type RayHit = {
	hit: boolean,
	shape: Shape?,
	point: Vector3,
	normal: Vector3,
	fraction: number,
}

local Query = {}

local function readRayHit(shapeHandle: number): RayHit
	local memory = Core.memory()[1]
	local hit = buffer.readf32(memory, Scratch.FLOATS_PTR) ~= 0
	return {
		hit = hit,
		shape = if hit and shapeHandle ~= 0 then { handle = shapeHandle } else nil,
		point = Vector3.new(buffer.readf32(memory, Scratch.FLOATS_PTR + 4), buffer.readf32(memory, Scratch.FLOATS_PTR + 8), buffer.readf32(memory, Scratch.FLOATS_PTR + 12)),
		normal = Vector3.new(buffer.readf32(memory, Scratch.FLOATS_PTR + 16), buffer.readf32(memory, Scratch.FLOATS_PTR + 20), buffer.readf32(memory, Scratch.FLOATS_PTR + 24)),
		fraction = buffer.readf32(memory, Scratch.FLOATS_PTR + 28),
	}
end

function Query.castRayClosest(world: World, origin: Vector3, translation: Vector3, categoryBits: number?, maskBits: number?): RayHit
	Core.requireExport("b3d_world_cast_ray_closest", "Query.castRayClosest")
	Core.Adapter.b3d_world_cast_ray_closest(world.handle, origin.X, origin.Y, origin.Z, translation.X, translation.Y, translation.Z, categoryBits or 1, maskBits or -1, Scratch.FLOATS_PTR, Scratch.INTS_PTR)
	local shapeHandle = buffer.readi32(Core.memory()[1], Scratch.INTS_PTR)
	return readRayHit(shapeHandle)
end

function Query.overlapAABB(world: World, lowerBound: Vector3, upperBound: Vector3, categoryBits: number?, maskBits: number?): { Shape }
	Core.requireExport("b3d_world_overlap_aabb", "Query.overlapAABB")
	local count = Core.Adapter.b3d_world_overlap_aabb(world.handle, lowerBound.X, lowerBound.Y, lowerBound.Z, upperBound.X, upperBound.Y, upperBound.Z, categoryBits or 1, maskBits or -1)
	local shapes = table.create(count)
	for index = 0, count - 1 do
		shapes[index + 1] = { handle = Core.Adapter.b3d_query_get_shape(index) }
	end
	return shapes
end

function Query.castRayAll(world: World, origin: Vector3, translation: Vector3, categoryBits: number?, maskBits: number?): { RayHit }
	Core.requireExport("b3d_world_cast_ray_all", "Query.castRayAll")
	local count = Core.Adapter.b3d_world_cast_ray_all(world.handle, origin.X, origin.Y, origin.Z, translation.X, translation.Y, translation.Z, categoryBits or 1, maskBits or -1)
	local hits = table.create(count)
	for index = 0, count - 1 do
		Core.Adapter.b3d_query_get_hit(index, Scratch.FLOATS_PTR)
		local memory = Core.memory()[1]
		hits[index + 1] = {
			hit = true,
			shape = { handle = Core.Adapter.b3d_query_get_shape(index) },
			point = Vector3.new(buffer.readf32(memory, Scratch.FLOATS_PTR), buffer.readf32(memory, Scratch.FLOATS_PTR + 4), buffer.readf32(memory, Scratch.FLOATS_PTR + 8)),
			normal = Vector3.new(buffer.readf32(memory, Scratch.FLOATS_PTR + 12), buffer.readf32(memory, Scratch.FLOATS_PTR + 16), buffer.readf32(memory, Scratch.FLOATS_PTR + 20)),
			fraction = buffer.readf32(memory, Scratch.FLOATS_PTR + 24),
		}
	end
	return hits
end

return Query
