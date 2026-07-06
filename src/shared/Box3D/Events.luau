--!strict

local Core = require(script.Parent.Core)
local Scratch = require(script.Parent.Internal.Scratch)

export type World = { handle: number }

local Events = {}

function Events.getBodyMoves(world: World): { { body: { handle: number }, cframe: CFrame, fellAsleep: boolean } }
	Core.requireExport("b3d_events_get_body_move_count", "Events.getBodyMoves")
	local Math = require(script.Parent.Math)
	local count = Core.Adapter.b3d_events_get_body_move_count(world.handle)
	local moves = table.create(count)
	for index = 0, count - 1 do
		Core.Adapter.b3d_events_get_body_move(world.handle, index, Scratch.TRANSFORM_PTR, Scratch.INTS_PTR)
		local memory = Core.memory()[1]
		moves[index + 1] = {
			body = { handle = buffer.readi32(memory, Scratch.INTS_PTR) },
			cframe = Math.cframeFromQuaternion(Vector3.new(buffer.readf32(memory, Scratch.TRANSFORM_PTR), buffer.readf32(memory, Scratch.TRANSFORM_PTR + 4), buffer.readf32(memory, Scratch.TRANSFORM_PTR + 8)), {
				x = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 12),
				y = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 16),
				z = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 20),
				w = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 24),
			}),
			fellAsleep = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 28) ~= 0,
		}
	end
	return moves
end

function Events.getSensorBegin(world: World): { { sensorShape: { handle: number }, visitorShape: { handle: number } } }
	Core.requireExport("b3d_events_get_sensor_begin_count", "Events.getSensorBegin")
	local count = Core.Adapter.b3d_events_get_sensor_begin_count(world.handle)
	local events = table.create(count)
	for index = 0, count - 1 do
		Core.Adapter.b3d_events_get_sensor_begin(world.handle, index, Scratch.INTS_PTR)
		local memory = Core.memory()[1]
		events[index + 1] = { sensorShape = { handle = buffer.readi32(memory, Scratch.INTS_PTR) }, visitorShape = { handle = buffer.readi32(memory, Scratch.INTS_PTR + 4) } }
	end
	return events
end

function Events.getContactHits(world: World): { { shapeA: { handle: number }, shapeB: { handle: number }, point: Vector3, normal: Vector3, approachSpeed: number } }
	Core.requireExport("b3d_events_get_contact_hit_count", "Events.getContactHits")
	local count = Core.Adapter.b3d_events_get_contact_hit_count(world.handle)
	local events = table.create(count)
	for index = 0, count - 1 do
		Core.Adapter.b3d_events_get_contact_hit(world.handle, index, Scratch.FLOATS_PTR, Scratch.INTS_PTR)
		local memory = Core.memory()[1]
		events[index + 1] = {
			shapeA = { handle = buffer.readi32(memory, Scratch.INTS_PTR) },
			shapeB = { handle = buffer.readi32(memory, Scratch.INTS_PTR + 4) },
			point = Vector3.new(buffer.readf32(memory, Scratch.FLOATS_PTR), buffer.readf32(memory, Scratch.FLOATS_PTR + 4), buffer.readf32(memory, Scratch.FLOATS_PTR + 8)),
			normal = Vector3.new(buffer.readf32(memory, Scratch.FLOATS_PTR + 12), buffer.readf32(memory, Scratch.FLOATS_PTR + 16), buffer.readf32(memory, Scratch.FLOATS_PTR + 20)),
			approachSpeed = buffer.readf32(memory, Scratch.FLOATS_PTR + 24),
		}
	end
	return events
end

return Events
