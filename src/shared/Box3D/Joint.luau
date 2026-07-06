--!strict

local Core = require(script.Parent.Core)
local Scratch = require(script.Parent.Internal.Scratch)

export type World = { handle: number }
export type Body = { handle: number }
export type Joint = { handle: number }

local Joint = {}

function Joint.createDistance(world: World, bodyA: Body, bodyB: Body, localAnchorA: Vector3, localAnchorB: Vector3, length: number): Joint
	Core.requireExport("b3d_create_distance_joint", "Joint.createDistance")
	local handle = Core.Adapter.b3d_create_distance_joint(world.handle, bodyA.handle, bodyB.handle, localAnchorA.X, localAnchorA.Y, localAnchorA.Z, localAnchorB.X, localAnchorB.Y, localAnchorB.Z, length)
	Core.assertHandle("distance joint", handle)
	return { handle = handle }
end

function Joint.createFilter(world: World, bodyA: Body, bodyB: Body): Joint
	Core.requireExport("b3d_create_filter_joint", "Joint.createFilter")
	local handle = Core.Adapter.b3d_create_filter_joint(world.handle, bodyA.handle, bodyB.handle)
	Core.assertHandle("filter joint", handle)
	return { handle = handle }
end

function Joint.createWeld(world: World, bodyA: Body, bodyB: Body, localAnchorA: Vector3, localAnchorB: Vector3): Joint
	Core.requireExport("b3d_create_weld_joint", "Joint.createWeld")
	local handle = Core.Adapter.b3d_create_weld_joint(world.handle, bodyA.handle, bodyB.handle, localAnchorA.X, localAnchorA.Y, localAnchorA.Z, localAnchorB.X, localAnchorB.Y, localAnchorB.Z)
	Core.assertHandle("weld joint", handle)
	return { handle = handle }
end

function Joint.destroy(joint: Joint, wakeAttached: boolean?)
	Core.requireExport("b3d_destroy_joint", "Joint.destroy")
	Core.Adapter.b3d_destroy_joint(joint.handle, if wakeAttached == false then 0 else 1)
end

function Joint.isValid(joint: Joint): boolean
	Core.requireExport("b3d_joint_is_valid", "Joint.isValid")
	return Core.Adapter.b3d_joint_is_valid(joint.handle) ~= 0
end

function Joint.getType(joint: Joint): number
	Core.requireExport("b3d_joint_get_type", "Joint.getType")
	return Core.Adapter.b3d_joint_get_type(joint.handle)
end

function Joint.getConstraintForce(joint: Joint): Vector3
	Core.requireExport("b3d_joint_get_constraint_force", "Joint.getConstraintForce")
	Core.Adapter.b3d_joint_get_constraint_force(joint.handle, Scratch.VEC3_PTR)
	local memory = Core.memory()[1]
	return Vector3.new(buffer.readf32(memory, Scratch.VEC3_PTR), buffer.readf32(memory, Scratch.VEC3_PTR + 4), buffer.readf32(memory, Scratch.VEC3_PTR + 8))
end

function Joint.setDistanceLength(joint: Joint, length: number)
	Core.requireExport("b3d_distance_joint_set_length", "Joint.setDistanceLength")
	Core.Adapter.b3d_distance_joint_set_length(joint.handle, length)
end

function Joint.getDistanceLength(joint: Joint): number
	Core.requireExport("b3d_distance_joint_get_length", "Joint.getDistanceLength")
	return Core.Adapter.b3d_distance_joint_get_length(joint.handle)
end

return Joint
