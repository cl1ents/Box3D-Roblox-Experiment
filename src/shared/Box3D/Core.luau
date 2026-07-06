--!strict

local Adapter = require(script.Parent.Internal.Adapter)

local Core = {}

Core.Adapter = Adapter :: any

function Core.memory(): { buffer }
	Adapter._initialize()
	return Adapter.memory
end

function Core.hasExport(name: string): boolean
	return Adapter.hasExport(name)
end

function Core.requireExport(name: string, publicName: string?)
	Adapter.requireExport(name, publicName)
end

function Core.assertHandle(kind: string, handle: number)
	if handle == 0 then
		error(`Box3D failed to create {kind}`, 3)
	end
end

return Core
