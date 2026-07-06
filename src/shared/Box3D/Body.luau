--!strict

local Core = require(script.Parent.Core)
local Scratch = require(script.Parent.Internal.Scratch)
local Math = require(script.Parent.Math)
local Types = require(script.Parent.Types)

export type World = { handle: number }
export type Body = { handle: number }
export type BodyType = "Static" | "Kinematic" | "Dynamic"
export type Quaternion = { x: number, y: number, z: number, w: number }
export type BodyOptions = {
	bodyType: BodyType?,
	position: Vector3?,
	cframe: CFrame?,
	quaternion: Quaternion?,
}

local Body = {}

function Body.create(world: World, options: BodyOptions?): Body
	local bodyType: BodyType = "Static"
	local position = Vector3.zero
	local quaternion: Quaternion = { x = 0, y = 0, z = 0, w = 1 }

	if options then
		bodyType = options.bodyType or bodyType
		if options.cframe then
			position = options.cframe.Position
			quaternion = Math.quaternionFromCFrame(options.cframe)
		else
			position = options.position or position
			quaternion = options.quaternion or quaternion
		end
	end

	local handle = Core.Adapter.b3d_create_body(world.handle, Types.BodyTypeIds[bodyType], position.X, position.Y, position.Z, quaternion.x, quaternion.y, quaternion.z, quaternion.w)
	Core.assertHandle("body", handle)
	return { handle = handle }
end

function Body.destroy(body: Body)
	Core.requireExport("b3d_destroy_body", "Body.destroy")
	Core.Adapter.b3d_destroy_body(body.handle)
end

function Body.getCFrame(body: Body): CFrame
	Core.Adapter.b3d_get_body_transform(body.handle, Scratch.TRANSFORM_PTR)

	local memory = Core.memory()[1]
	local position = Vector3.new(
		buffer.readf32(memory, Scratch.TRANSFORM_PTR),
		buffer.readf32(memory, Scratch.TRANSFORM_PTR + 4),
		buffer.readf32(memory, Scratch.TRANSFORM_PTR + 8)
	)

	return Math.cframeFromQuaternion(position, {
		x = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 12),
		y = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 16),
		z = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 20),
		w = buffer.readf32(memory, Scratch.TRANSFORM_PTR + 24),
	})
end

function Body.setCFrame(body: Body, cframe: CFrame)
	Core.requireExport("b3d_set_body_transform", "Body.setCFrame")

	local q = Math.quaternionFromCFrame(cframe)
	local p = cframe.Position
	Core.Adapter.b3d_set_body_transform(body.handle, p.X, p.Y, p.Z, q.x, q.y, q.z, q.w)
end

function Body.getLinearVelocity(body: Body): Vector3
	Core.requireExport("b3d_get_body_linear_velocity", "Body.getLinearVelocity")

	Core.Adapter.b3d_get_body_linear_velocity(body.handle, Scratch.VELOCITY_PTR)
	local memory = Core.memory()[1]
	return Vector3.new(
		buffer.readf32(memory, Scratch.VELOCITY_PTR),
		buffer.readf32(memory, Scratch.VELOCITY_PTR + 4),
		buffer.readf32(memory, Scratch.VELOCITY_PTR + 8)
	)
end

function Body.setLinearVelocity(body: Body, velocity: Vector3)
	Core.requireExport("b3d_set_body_linear_velocity", "Body.setLinearVelocity")
	Core.Adapter.b3d_set_body_linear_velocity(body.handle, velocity.X, velocity.Y, velocity.Z)
end

return Body
