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

local function readVec3(ptr: number): Vector3
	local memory = Core.memory()[1]
	return Vector3.new(buffer.readf32(memory, ptr), buffer.readf32(memory, ptr + 4), buffer.readf32(memory, ptr + 8))
end

local function readMassData(ptr: number): { mass: number, center: Vector3 }
	local memory = Core.memory()[1]
	return {
		mass = buffer.readf32(memory, ptr),
		center = Vector3.new(buffer.readf32(memory, ptr + 4), buffer.readf32(memory, ptr + 8), buffer.readf32(memory, ptr + 12)),
	}
end

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

function Body.isValid(body: Body): boolean
	Core.requireExport("b3d_body_is_valid", "Body.isValid")
	return Core.Adapter.b3d_body_is_valid(body.handle) ~= 0
end

function Body.getType(body: Body): number
	Core.requireExport("b3d_body_get_type", "Body.getType")
	return Core.Adapter.b3d_body_get_type(body.handle)
end

function Body.setType(body: Body, bodyType: BodyType)
	Core.requireExport("b3d_body_set_type", "Body.setType")
	Core.Adapter.b3d_body_set_type(body.handle, Types.BodyTypeIds[bodyType])
end

function Body.getPosition(body: Body): Vector3
	Core.requireExport("b3d_body_get_position", "Body.getPosition")
	Core.Adapter.b3d_body_get_position(body.handle, Scratch.VEC3_PTR)
	return readVec3(Scratch.VEC3_PTR)
end

function Body.getAngularVelocity(body: Body): Vector3
	Core.requireExport("b3d_body_get_angular_velocity", "Body.getAngularVelocity")
	Core.Adapter.b3d_body_get_angular_velocity(body.handle, Scratch.VEC3_PTR)
	return readVec3(Scratch.VEC3_PTR)
end

function Body.setAngularVelocity(body: Body, velocity: Vector3)
	Core.requireExport("b3d_body_set_angular_velocity", "Body.setAngularVelocity")
	Core.Adapter.b3d_body_set_angular_velocity(body.handle, velocity.X, velocity.Y, velocity.Z)
end

function Body.applyForce(body: Body, force: Vector3, point: Vector3, wake: boolean?)
	Core.requireExport("b3d_body_apply_force", "Body.applyForce")
	Core.Adapter.b3d_body_apply_force(body.handle, force.X, force.Y, force.Z, point.X, point.Y, point.Z, if wake == false then 0 else 1)
end

function Body.applyForceToCenter(body: Body, force: Vector3, wake: boolean?)
	Core.requireExport("b3d_body_apply_force_to_center", "Body.applyForceToCenter")
	Core.Adapter.b3d_body_apply_force_to_center(body.handle, force.X, force.Y, force.Z, if wake == false then 0 else 1)
end

function Body.applyTorque(body: Body, torque: Vector3, wake: boolean?)
	Core.requireExport("b3d_body_apply_torque", "Body.applyTorque")
	Core.Adapter.b3d_body_apply_torque(body.handle, torque.X, torque.Y, torque.Z, if wake == false then 0 else 1)
end

function Body.applyLinearImpulse(body: Body, impulse: Vector3, point: Vector3, wake: boolean?)
	Core.requireExport("b3d_body_apply_linear_impulse", "Body.applyLinearImpulse")
	Core.Adapter.b3d_body_apply_linear_impulse(body.handle, impulse.X, impulse.Y, impulse.Z, point.X, point.Y, point.Z, if wake == false then 0 else 1)
end

function Body.applyLinearImpulseToCenter(body: Body, impulse: Vector3, wake: boolean?)
	Core.requireExport("b3d_body_apply_linear_impulse_to_center", "Body.applyLinearImpulseToCenter")
	Core.Adapter.b3d_body_apply_linear_impulse_to_center(body.handle, impulse.X, impulse.Y, impulse.Z, if wake == false then 0 else 1)
end

function Body.applyAngularImpulse(body: Body, impulse: Vector3, wake: boolean?)
	Core.requireExport("b3d_body_apply_angular_impulse", "Body.applyAngularImpulse")
	Core.Adapter.b3d_body_apply_angular_impulse(body.handle, impulse.X, impulse.Y, impulse.Z, if wake == false then 0 else 1)
end

function Body.getMass(body: Body): number
	Core.requireExport("b3d_body_get_mass", "Body.getMass")
	return Core.Adapter.b3d_body_get_mass(body.handle)
end

function Body.getInverseMass(body: Body): number
	Core.requireExport("b3d_body_get_inverse_mass", "Body.getInverseMass")
	return Core.Adapter.b3d_body_get_inverse_mass(body.handle)
end

function Body.getMassData(body: Body): { mass: number, center: Vector3 }
	Core.requireExport("b3d_body_get_mass_data", "Body.getMassData")
	Core.Adapter.b3d_body_get_mass_data(body.handle, Scratch.MASS_PTR)
	return readMassData(Scratch.MASS_PTR)
end

function Body.applyMassFromShapes(body: Body)
	Core.requireExport("b3d_body_apply_mass_from_shapes", "Body.applyMassFromShapes")
	Core.Adapter.b3d_body_apply_mass_from_shapes(body.handle)
end

function Body.setLinearDamping(body: Body, damping: number)
	Core.requireExport("b3d_body_set_linear_damping", "Body.setLinearDamping")
	Core.Adapter.b3d_body_set_linear_damping(body.handle, damping)
end

function Body.getLinearDamping(body: Body): number
	Core.requireExport("b3d_body_get_linear_damping", "Body.getLinearDamping")
	return Core.Adapter.b3d_body_get_linear_damping(body.handle)
end

function Body.setAngularDamping(body: Body, damping: number)
	Core.requireExport("b3d_body_set_angular_damping", "Body.setAngularDamping")
	Core.Adapter.b3d_body_set_angular_damping(body.handle, damping)
end

function Body.getAngularDamping(body: Body): number
	Core.requireExport("b3d_body_get_angular_damping", "Body.getAngularDamping")
	return Core.Adapter.b3d_body_get_angular_damping(body.handle)
end

function Body.setGravityScale(body: Body, scale: number)
	Core.requireExport("b3d_body_set_gravity_scale", "Body.setGravityScale")
	Core.Adapter.b3d_body_set_gravity_scale(body.handle, scale)
end

function Body.getGravityScale(body: Body): number
	Core.requireExport("b3d_body_get_gravity_scale", "Body.getGravityScale")
	return Core.Adapter.b3d_body_get_gravity_scale(body.handle)
end

function Body.isAwake(body: Body): boolean
	Core.requireExport("b3d_body_is_awake", "Body.isAwake")
	return Core.Adapter.b3d_body_is_awake(body.handle) ~= 0
end

function Body.setAwake(body: Body, awake: boolean)
	Core.requireExport("b3d_body_set_awake", "Body.setAwake")
	Core.Adapter.b3d_body_set_awake(body.handle, if awake then 1 else 0)
end

function Body.enableSleep(body: Body, enabled: boolean)
	Core.requireExport("b3d_body_enable_sleep", "Body.enableSleep")
	Core.Adapter.b3d_body_enable_sleep(body.handle, if enabled then 1 else 0)
end

function Body.isSleepEnabled(body: Body): boolean
	Core.requireExport("b3d_body_is_sleep_enabled", "Body.isSleepEnabled")
	return Core.Adapter.b3d_body_is_sleep_enabled(body.handle) ~= 0
end

function Body.enable(body: Body)
	Core.requireExport("b3d_body_enable", "Body.enable")
	Core.Adapter.b3d_body_enable(body.handle)
end

function Body.disable(body: Body)
	Core.requireExport("b3d_body_disable", "Body.disable")
	Core.Adapter.b3d_body_disable(body.handle)
end

function Body.isEnabled(body: Body): boolean
	Core.requireExport("b3d_body_is_enabled", "Body.isEnabled")
	return Core.Adapter.b3d_body_is_enabled(body.handle) ~= 0
end

function Body.setBullet(body: Body, bullet: boolean)
	Core.requireExport("b3d_body_set_bullet", "Body.setBullet")
	Core.Adapter.b3d_body_set_bullet(body.handle, if bullet then 1 else 0)
end

function Body.isBullet(body: Body): boolean
	Core.requireExport("b3d_body_is_bullet", "Body.isBullet")
	return Core.Adapter.b3d_body_is_bullet(body.handle) ~= 0
end

function Body.getShapeCount(body: Body): number
	Core.requireExport("b3d_body_get_shape_count", "Body.getShapeCount")
	return Core.Adapter.b3d_body_get_shape_count(body.handle)
end

function Body.getJointCount(body: Body): number
	Core.requireExport("b3d_body_get_joint_count", "Body.getJointCount")
	return Core.Adapter.b3d_body_get_joint_count(body.handle)
end

return Body
