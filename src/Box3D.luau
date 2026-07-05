--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Adapter = require(ReplicatedStorage.Shared.Box3DAdapter)

export type World = { handle: number }
export type Body = { handle: number }
export type Shape = { handle: number }
export type BodyType = "Static" | "Kinematic" | "Dynamic"

export type Quaternion = {
	x: number,
	y: number,
	z: number,
	w: number,
}

export type BodyOptions = {
	bodyType: BodyType?,
	position: Vector3?,
	cframe: CFrame?,
	quaternion: Quaternion?,
}

export type ShapeOptions = {
	density: number?,
	friction: number?,
	restitution: number?,
}

type Box3D = {
	BodyType: { Static: BodyType, Kinematic: BodyType, Dynamic: BodyType },
	createWorld: (gravity: Vector3?) -> World,
	destroyWorld: (world: World) -> (),
	step: (world: World, timeStep: number, subStepCount: number?) -> (),
	createBody: (world: World, options: BodyOptions?) -> Body,
	destroyBody: (body: Body) -> (),
	createSphere: (body: Body, radius: number, options: ShapeOptions?) -> Shape,
	createCapsule: (body: Body, pointA: Vector3, pointB: Vector3, radius: number, options: ShapeOptions?) -> Shape,
	createBox: (body: Body, size: Vector3, options: ShapeOptions?) -> Shape,
	destroyShape: (shape: Shape) -> (),
	getBodyCFrame: (body: Body) -> CFrame,
	setBodyCFrame: (body: Body, cframe: CFrame) -> (),
	getBodyLinearVelocity: (body: Body) -> Vector3,
	setBodyLinearVelocity: (body: Body, velocity: Vector3) -> (),
}

local TRANSFORM_PTR = 1024 * 1024
local VELOCITY_PTR = TRANSFORM_PTR + 32

local bodyTypes: { [BodyType]: number } = {
	Static = 0,
	Kinematic = 1,
	Dynamic = 2,
}

local function assertHandle(kind: string, handle: number)
	if handle == 0 then
		error(`Box3D failed to create {kind}`, 3)
	end
end

local function requireFullApi(name: string): never
	error(`Box3D.{name} requires wasm built with BOX3D_WASM_FULL_API=ON`, 3)
end

local function shapeOptions(options: ShapeOptions?): (number, number, number)
	if options == nil then
		return 1, 0.5, 0
	end

	return options.density or 1, options.friction or 0.5, options.restitution or 0
end

local function quaternionFromCFrame(cframe: CFrame): Quaternion
	local _, _, _, m00, m01, m02, m10, m11, m12, m20, m21, m22 = cframe:GetComponents()
	local trace = m00 + m11 + m22

	if trace > 0 then
		local s = math.sqrt(trace + 1) * 2
		return {
			x = (m21 - m12) / s,
			y = (m02 - m20) / s,
			z = (m10 - m01) / s,
			w = 0.25 * s,
		}
	elseif m00 > m11 and m00 > m22 then
		local s = math.sqrt(1 + m00 - m11 - m22) * 2
		return {
			x = 0.25 * s,
			y = (m01 + m10) / s,
			z = (m02 + m20) / s,
			w = (m21 - m12) / s,
		}
	elseif m11 > m22 then
		local s = math.sqrt(1 + m11 - m00 - m22) * 2
		return {
			x = (m01 + m10) / s,
			y = 0.25 * s,
			z = (m12 + m21) / s,
			w = (m02 - m20) / s,
		}
	else
		local s = math.sqrt(1 + m22 - m00 - m11) * 2
		return {
			x = (m02 + m20) / s,
			y = (m12 + m21) / s,
			z = 0.25 * s,
			w = (m10 - m01) / s,
		}
	end
end

local function cframeFromQuaternion(position: Vector3, q: Quaternion): CFrame
	local xx = q.x * q.x
	local yy = q.y * q.y
	local zz = q.z * q.z
	local xy = q.x * q.y
	local xz = q.x * q.z
	local yz = q.y * q.z
	local wx = q.w * q.x
	local wy = q.w * q.y
	local wz = q.w * q.z

	return CFrame.new(
		position.X,
		position.Y,
		position.Z,
		1 - 2 * (yy + zz),
		2 * (xy - wz),
		2 * (xz + wy),
		2 * (xy + wz),
		1 - 2 * (xx + zz),
		2 * (yz - wx),
		2 * (xz - wy),
		2 * (yz + wx),
		1 - 2 * (xx + yy)
	)
end

local Box3D = {} :: Box3D

Box3D.BodyType = {
	Static = "Static",
	Kinematic = "Kinematic",
	Dynamic = "Dynamic",
}

function Box3D.createWorld(gravity: Vector3?): World
	local g = gravity or Vector3.new(0, -9.8, 0)
	local handle = Adapter.b3d_create_world(g.X, g.Y, g.Z)
	assertHandle("world", handle)
	return { handle = handle }
end

function Box3D.destroyWorld(world: World)
	if not Adapter.hasExport("b3d_destroy_world") then
		requireFullApi("destroyWorld")
	end
	Adapter.b3d_destroy_world(world.handle)
end

function Box3D.step(world: World, timeStep: number, subStepCount: number?)
	Adapter.b3d_step(world.handle, timeStep, subStepCount or 4)
end

function Box3D.createBody(world: World, options: BodyOptions?): Body
	local bodyType: BodyType = "Static"
	local position = Vector3.zero
	local quaternion: Quaternion = { x = 0, y = 0, z = 0, w = 1 }

	if options then
		bodyType = options.bodyType or bodyType
		if options.cframe then
			position = options.cframe.Position
			quaternion = quaternionFromCFrame(options.cframe)
		else
			position = options.position or position
			quaternion = options.quaternion or quaternion
		end
	end

	local handle = Adapter.b3d_create_body(world.handle, bodyTypes[bodyType], position.X, position.Y, position.Z, quaternion.x, quaternion.y, quaternion.z, quaternion.w)
	assertHandle("body", handle)
	return { handle = handle }
end

function Box3D.destroyBody(body: Body)
	if not Adapter.hasExport("b3d_destroy_body") then
		requireFullApi("destroyBody")
	end
	Adapter.b3d_destroy_body(body.handle)
end

function Box3D.createSphere(body: Body, radius: number, options: ShapeOptions?): Shape
	local density, friction, restitution = shapeOptions(options)
	local handle = Adapter.b3d_create_sphere(body.handle, radius, density, friction, restitution)
	assertHandle("sphere", handle)
	return { handle = handle }
end

function Box3D.createCapsule(body: Body, pointA: Vector3, pointB: Vector3, radius: number, options: ShapeOptions?): Shape
	if not Adapter.hasExport("b3d_create_capsule") then
		requireFullApi("createCapsule")
	end

	local density, friction, restitution = shapeOptions(options)
	local handle = Adapter.b3d_create_capsule(body.handle, pointA.X, pointA.Y, pointA.Z, pointB.X, pointB.Y, pointB.Z, radius, density, friction, restitution)
	assertHandle("capsule", handle)
	return { handle = handle }
end

function Box3D.createBox(body: Body, size: Vector3, options: ShapeOptions?): Shape
	local density, friction, restitution = shapeOptions(options)
	local handle = Adapter.b3d_create_box(body.handle, size.X / 2, size.Y / 2, size.Z / 2, density, friction, restitution)
	assertHandle("box", handle)
	return { handle = handle }
end

function Box3D.destroyShape(shape: Shape)
	if not Adapter.hasExport("b3d_destroy_shape") then
		requireFullApi("destroyShape")
	end
	Adapter.b3d_destroy_shape(shape.handle)
end

function Box3D.getBodyCFrame(body: Body): CFrame
	Adapter.b3d_get_body_transform(body.handle, TRANSFORM_PTR)

	local memory = Adapter.memory[1]
	local position = Vector3.new(
		buffer.readf32(memory, TRANSFORM_PTR),
		buffer.readf32(memory, TRANSFORM_PTR + 4),
		buffer.readf32(memory, TRANSFORM_PTR + 8)
	)

	return cframeFromQuaternion(position, {
		x = buffer.readf32(memory, TRANSFORM_PTR + 12),
		y = buffer.readf32(memory, TRANSFORM_PTR + 16),
		z = buffer.readf32(memory, TRANSFORM_PTR + 20),
		w = buffer.readf32(memory, TRANSFORM_PTR + 24),
	})
end

function Box3D.setBodyCFrame(body: Body, cframe: CFrame)
	if not Adapter.hasExport("b3d_set_body_transform") then
		requireFullApi("setBodyCFrame")
	end

	local q = quaternionFromCFrame(cframe)
	local p = cframe.Position
	Adapter.b3d_set_body_transform(body.handle, p.X, p.Y, p.Z, q.x, q.y, q.z, q.w)
end

function Box3D.getBodyLinearVelocity(body: Body): Vector3
	if not Adapter.hasExport("b3d_get_body_linear_velocity") then
		requireFullApi("getBodyLinearVelocity")
	end

	Adapter.b3d_get_body_linear_velocity(body.handle, VELOCITY_PTR)
	local memory = Adapter.memory[1]
	return Vector3.new(
		buffer.readf32(memory, VELOCITY_PTR),
		buffer.readf32(memory, VELOCITY_PTR + 4),
		buffer.readf32(memory, VELOCITY_PTR + 8)
	)
end

function Box3D.setBodyLinearVelocity(body: Body, velocity: Vector3)
	if not Adapter.hasExport("b3d_set_body_linear_velocity") then
		requireFullApi("setBodyLinearVelocity")
	end

	Adapter.b3d_set_body_linear_velocity(body.handle, velocity.X, velocity.Y, velocity.Z)
end

return Box3D
