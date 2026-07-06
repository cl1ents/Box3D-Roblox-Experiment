--!strict

local Types = require(script.Types)

export type WorldModule = typeof(require(script.World))
export type BodyModule = typeof(require(script.Body))
export type ShapeModule = typeof(require(script.Shape))
export type MathModule = typeof(require(script.Math))
export type TypesModule = typeof(require(script.Types))

export type World = { handle: number }
export type Body = { handle: number }
export type Shape = { handle: number }
export type BodyType = "Static" | "Kinematic" | "Dynamic"
export type Quaternion = { x: number, y: number, z: number, w: number }
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

export type Box3D = {
	World: WorldModule,
	Body: BodyModule,
	Shape: ShapeModule,
	Math: MathModule,
	Types: TypesModule,
	BodyType: typeof(Types.BodyType),
	createWorld: typeof(require(script.World).create),
	destroyWorld: typeof(require(script.World).destroy),
	step: typeof(require(script.World).step),
	createBody: typeof(require(script.Body).create),
	destroyBody: typeof(require(script.Body).destroy),
	createSphere: typeof(require(script.Shape).createSphere),
	createCapsule: typeof(require(script.Shape).createCapsule),
	createBox: typeof(require(script.Shape).createBox),
	destroyShape: typeof(require(script.Shape).destroy),
	getBodyCFrame: typeof(require(script.Body).getCFrame),
	setBodyCFrame: typeof(require(script.Body).setCFrame),
	getBodyLinearVelocity: typeof(require(script.Body).getLinearVelocity),
	setBodyLinearVelocity: typeof(require(script.Body).setLinearVelocity),
}

local modules = {
	World = script.World,
	Body = script.Body,
	Shape = script.Shape,
	Math = script.Math,
	Types = script.Types,
}

local Box3D = {
	BodyType = Types.BodyType,
}

function Box3D.createWorld(gravity: Vector3?): World
	return require(script.World).create(gravity)
end

function Box3D.destroyWorld(world: World)
	require(script.World).destroy(world)
end

function Box3D.step(world: World, timeStep: number, subStepCount: number?)
	require(script.World).step(world, timeStep, subStepCount)
end

function Box3D.createBody(world: World, options: BodyOptions?): Body
	return require(script.Body).create(world, options)
end

function Box3D.destroyBody(body: Body)
	require(script.Body).destroy(body)
end

function Box3D.createSphere(body: Body, radius: number, options: ShapeOptions?): Shape
	return require(script.Shape).createSphere(body, radius, options)
end

function Box3D.createCapsule(body: Body, pointA: Vector3, pointB: Vector3, radius: number, options: ShapeOptions?): Shape
	return require(script.Shape).createCapsule(body, pointA, pointB, radius, options)
end

function Box3D.createBox(body: Body, size: Vector3, options: ShapeOptions?): Shape
	return require(script.Shape).createBox(body, size, options)
end

function Box3D.destroyShape(shape: Shape)
	require(script.Shape).destroy(shape)
end

function Box3D.getBodyCFrame(body: Body): CFrame
	return require(script.Body).getCFrame(body)
end

function Box3D.setBodyCFrame(body: Body, cframe: CFrame)
	require(script.Body).setCFrame(body, cframe)
end

function Box3D.getBodyLinearVelocity(body: Body): Vector3
	return require(script.Body).getLinearVelocity(body)
end

function Box3D.setBodyLinearVelocity(body: Body, velocity: Vector3)
	require(script.Body).setLinearVelocity(body, velocity)
end

return setmetatable(Box3D :: any, {
	__index = function(self, key: string)
		local module = modules[key]
		if module == nil then
			return nil
		end

		local value = require(module)
		rawset(self, key, value)
		return value
	end,
}) :: Box3D
