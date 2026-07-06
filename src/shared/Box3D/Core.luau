--!strict

local Adapter = require(script.Parent.Internal.Adapter)

local Core = {}

Core.Adapter = Adapter

function Core.memory(): { buffer }
	Adapter._initialize()
	return Adapter.memory
end

function Core.hasExport(name: string): boolean
	return Adapter.hasExport(name)
end

function Core.requireExport(name: string, publicName: string?)
	if not Adapter.hasExport(name) then
		error(`Box3D.{publicName or name} requires wasm built with BOX3D_WASM_FULL_API=ON`, 3)
	end
end

function Core.assertHandle(kind: string, handle: number)
	if handle == 0 then
		error(`Box3D failed to create {kind}`, 3)
	end
end

return Core
