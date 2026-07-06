--!strict

local Core = require(script.Parent.Core)

export type Body = { handle: number }
export type Shape = { handle: number }
export type ShapeOptions = {
	density: number?,
	friction: number?,
	restitution: number?,
	isSensor: boolean?,
	categoryBits: number?,
	maskBits: number?,
	groupIndex: number?,
}

local Shape = {}

local function shapeOptions(options: ShapeOptions?): (number, number, number)
	if options == nil then
		return 1, 0.5, 0
	end

	return options.density or 1, options.friction or 0.5, options.restitution or 0
end

function Shape.createSphere(body: Body, radius: number, options: ShapeOptions?): Shape
	local density, friction, restitution = shapeOptions(options)
	local handle
	if options and (options.isSensor ~= nil or options.categoryBits ~= nil or options.maskBits ~= nil or options.groupIndex ~= nil) then
		Core.requireExport("b3d_create_sphere_ex", "Shape.createSphere")
		handle = Core.Adapter.b3d_create_sphere_ex(body.handle, 0, 0, 0, radius, density, friction, restitution, if options.isSensor then 1 else 0, options.categoryBits or 1, options.maskBits or -1, options.groupIndex or 0)
	else
		handle = Core.Adapter.b3d_create_sphere(body.handle, radius, density, friction, restitution)
	end
	Core.assertHandle("sphere", handle)
	return { handle = handle }
end

function Shape.createCapsule(body: Body, pointA: Vector3, pointB: Vector3, radius: number, options: ShapeOptions?): Shape
	Core.requireExport("b3d_create_capsule", "Shape.createCapsule")

	local density, friction, restitution = shapeOptions(options)
	local handle = Core.Adapter.b3d_create_capsule(body.handle, pointA.X, pointA.Y, pointA.Z, pointB.X, pointB.Y, pointB.Z, radius, density, friction, restitution)
	Core.assertHandle("capsule", handle)
	return { handle = handle }
end

function Shape.createBox(body: Body, size: Vector3, options: ShapeOptions?): Shape
	local density, friction, restitution = shapeOptions(options)
	local handle = Core.Adapter.b3d_create_box(body.handle, size.X / 2, size.Y / 2, size.Z / 2, density, friction, restitution)
	Core.assertHandle("box", handle)
	return { handle = handle }
end

function Shape.destroy(shape: Shape)
	Core.requireExport("b3d_destroy_shape", "Shape.destroy")
	Core.Adapter.b3d_destroy_shape(shape.handle)
end

function Shape.isValid(shape: Shape): boolean
	Core.requireExport("b3d_shape_is_valid", "Shape.isValid")
	return Core.Adapter.b3d_shape_is_valid(shape.handle) ~= 0
end

function Shape.getType(shape: Shape): number
	Core.requireExport("b3d_shape_get_type", "Shape.getType")
	return Core.Adapter.b3d_shape_get_type(shape.handle)
end

function Shape.isSensor(shape: Shape): boolean
	Core.requireExport("b3d_shape_is_sensor", "Shape.isSensor")
	return Core.Adapter.b3d_shape_is_sensor(shape.handle) ~= 0
end

function Shape.setDensity(shape: Shape, density: number, updateMass: boolean?)
	Core.requireExport("b3d_shape_set_density", "Shape.setDensity")
	Core.Adapter.b3d_shape_set_density(shape.handle, density, if updateMass == false then 0 else 1)
end

function Shape.getDensity(shape: Shape): number
	Core.requireExport("b3d_shape_get_density", "Shape.getDensity")
	return Core.Adapter.b3d_shape_get_density(shape.handle)
end

function Shape.setFriction(shape: Shape, friction: number)
	Core.requireExport("b3d_shape_set_friction", "Shape.setFriction")
	Core.Adapter.b3d_shape_set_friction(shape.handle, friction)
end

function Shape.getFriction(shape: Shape): number
	Core.requireExport("b3d_shape_get_friction", "Shape.getFriction")
	return Core.Adapter.b3d_shape_get_friction(shape.handle)
end

function Shape.setRestitution(shape: Shape, restitution: number)
	Core.requireExport("b3d_shape_set_restitution", "Shape.setRestitution")
	Core.Adapter.b3d_shape_set_restitution(shape.handle, restitution)
end

function Shape.getRestitution(shape: Shape): number
	Core.requireExport("b3d_shape_get_restitution", "Shape.getRestitution")
	return Core.Adapter.b3d_shape_get_restitution(shape.handle)
end

function Shape.setFilter(shape: Shape, categoryBits: number, maskBits: number, groupIndex: number?, invokeContacts: boolean?)
	Core.requireExport("b3d_shape_set_filter", "Shape.setFilter")
	Core.Adapter.b3d_shape_set_filter(shape.handle, categoryBits, maskBits, groupIndex or 0, if invokeContacts == false then 0 else 1)
end

function Shape.enableSensorEvents(shape: Shape, enabled: boolean)
	Core.requireExport("b3d_shape_enable_sensor_events", "Shape.enableSensorEvents")
	Core.Adapter.b3d_shape_enable_sensor_events(shape.handle, if enabled then 1 else 0)
end

function Shape.enableContactEvents(shape: Shape, enabled: boolean)
	Core.requireExport("b3d_shape_enable_contact_events", "Shape.enableContactEvents")
	Core.Adapter.b3d_shape_enable_contact_events(shape.handle, if enabled then 1 else 0)
end

function Shape.enableHitEvents(shape: Shape, enabled: boolean)
	Core.requireExport("b3d_shape_enable_hit_events", "Shape.enableHitEvents")
	Core.Adapter.b3d_shape_enable_hit_events(shape.handle, if enabled then 1 else 0)
end

function Shape.getAABB(shape: Shape): { lowerBound: Vector3, upperBound: Vector3 }
	Core.requireExport("b3d_shape_get_aabb", "Shape.getAABB")
	local Scratch = require(script.Parent.Internal.Scratch)
	Core.Adapter.b3d_shape_get_aabb(shape.handle, Scratch.AABB_PTR)
	local memory = Core.memory()[1]
	return {
		lowerBound = Vector3.new(buffer.readf32(memory, Scratch.AABB_PTR), buffer.readf32(memory, Scratch.AABB_PTR + 4), buffer.readf32(memory, Scratch.AABB_PTR + 8)),
		upperBound = Vector3.new(buffer.readf32(memory, Scratch.AABB_PTR + 12), buffer.readf32(memory, Scratch.AABB_PTR + 16), buffer.readf32(memory, Scratch.AABB_PTR + 20)),
	}
end

function Shape.getClosestPoint(shape: Shape, target: Vector3): Vector3
	Core.requireExport("b3d_shape_get_closest_point", "Shape.getClosestPoint")
	local Scratch = require(script.Parent.Internal.Scratch)
	Core.Adapter.b3d_shape_get_closest_point(shape.handle, target.X, target.Y, target.Z, Scratch.VEC3_PTR)
	local memory = Core.memory()[1]
	return Vector3.new(buffer.readf32(memory, Scratch.VEC3_PTR), buffer.readf32(memory, Scratch.VEC3_PTR + 4), buffer.readf32(memory, Scratch.VEC3_PTR + 8))
end

return Shape
