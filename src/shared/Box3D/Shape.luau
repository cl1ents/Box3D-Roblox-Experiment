--!strict

local Core = require(script.Parent.Core)

export type Body = { handle: number }
export type Shape = { handle: number }
export type ShapeOptions = {
	density: number?,
	friction: number?,
	restitution: number?,
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
	local handle = Core.Adapter.b3d_create_sphere(body.handle, radius, density, friction, restitution)
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

return Shape
