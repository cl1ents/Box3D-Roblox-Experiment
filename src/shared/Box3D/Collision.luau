--!strict

local Core = require(script.Parent.Core)
local Scratch = require(script.Parent.Internal.Scratch)

local Collision = {}

local function readMass(ptr: number): { mass: number, center: Vector3 }
	local memory = Core.memory()[1]
	return {
		mass = buffer.readf32(memory, ptr),
		center = Vector3.new(buffer.readf32(memory, ptr + 4), buffer.readf32(memory, ptr + 8), buffer.readf32(memory, ptr + 12)),
	}
end

function Collision.computeSphereMass(center: Vector3, radius: number, density: number): { mass: number, center: Vector3 }
	Core.requireExport("b3d_compute_sphere_mass", "Collision.computeSphereMass")
	Core.Adapter.b3d_compute_sphere_mass(center.X, center.Y, center.Z, radius, density, Scratch.MASS_PTR)
	return readMass(Scratch.MASS_PTR)
end

function Collision.computeCapsuleMass(pointA: Vector3, pointB: Vector3, radius: number, density: number): { mass: number, center: Vector3 }
	Core.requireExport("b3d_compute_capsule_mass", "Collision.computeCapsuleMass")
	Core.Adapter.b3d_compute_capsule_mass(pointA.X, pointA.Y, pointA.Z, pointB.X, pointB.Y, pointB.Z, radius, density, Scratch.MASS_PTR)
	return readMass(Scratch.MASS_PTR)
end

function Collision.isValidRay(origin: Vector3, translation: Vector3, maxFraction: number): boolean
	Core.requireExport("b3d_is_valid_ray", "Collision.isValidRay")
	return Core.Adapter.b3d_is_valid_ray(origin.X, origin.Y, origin.Z, translation.X, translation.Y, translation.Z, maxFraction) ~= 0
end

return Collision
