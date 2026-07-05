#!/usr/bin/env bash
set -euo pipefail

mkdir -p build-wasm
spider-cli compile -t luau build-wasm/box3d_wasm.wasm > build-wasm/box3d.luau
perl -0pi -e 's/local buffer_write_f32 = buffer\.writef32\n\nlocal function rt_store_f32\(destination: Memory, offset: number, source: number\)\n\tbuffer_write_u32\(destination\[1\], offset, source\)\nend\n\nlocal buffer_write_u32 = buffer\.writeu32/local buffer_write_f32 = buffer.writef32\nlocal buffer_write_u32 = buffer.writeu32\n\nlocal function rt_store_f32(destination: Memory, offset: number, source: number)\n\tbuffer_write_u32(destination[1], offset, source)\nend/' build-wasm/box3d.luau
cat >> build-wasm/box3d.luau <<'LUA'

rt_import_map.env = {
	emscripten_notify_memory_growth = { function() end },
}

rt_import_map.wasi_snapshot_preview1 = {
	clock_time_get = { function(_, _, _, outPtr)
		buffer.writeu32(rt_export_map.memory[1], outPtr, 0)
		buffer.writeu32(rt_export_map.memory[1], outPtr + 4, 0)
		return 0
	end },

	fd_write = { function()
		return 0
	end },
}

module({})

local done = {
	function(_, ...)
		return ...
	end,
}

local function call(export, ...)
	return export[1](export, ..., done)
end

local raw_exports = rt_export_map

rt_export_map = {
	memory = raw_exports.memory,

	_initialize = function()
		return call(raw_exports._initialize)
	end,

	malloc = function(size)
		return call(raw_exports.malloc, size)
	end,

	free = function(ptr)
		return call(raw_exports.free, ptr)
	end,

	b3d_create_world = function(gravityX, gravityY, gravityZ)
		return raw_exports.b3d_create_world[1](raw_exports.b3d_create_world, into_bits_f32(gravityX), into_bits_f32(gravityY), into_bits_f32(gravityZ), done)
	end,

	b3d_destroy_world = function(worldHandle)
		return call(raw_exports.b3d_destroy_world, worldHandle)
	end,

	b3d_step = function(worldHandle, timeStep, subStepCount)
		return raw_exports.b3d_step[1](raw_exports.b3d_step, worldHandle, into_bits_f32(timeStep), subStepCount, done)
	end,

	b3d_create_body = function(worldHandle, bodyType, x, y, z, qx, qy, qz, qw)
		return raw_exports.b3d_create_body[1](raw_exports.b3d_create_body, worldHandle, bodyType, into_bits_f32(x), into_bits_f32(y), into_bits_f32(z), into_bits_f32(qx), into_bits_f32(qy), into_bits_f32(qz), into_bits_f32(qw), done)
	end,

	b3d_destroy_body = function(bodyHandle)
		return call(raw_exports.b3d_destroy_body, bodyHandle)
	end,

	b3d_create_sphere = function(bodyHandle, radius, density, friction, restitution)
		return raw_exports.b3d_create_sphere[1](raw_exports.b3d_create_sphere, bodyHandle, into_bits_f32(radius), into_bits_f32(density), into_bits_f32(friction), into_bits_f32(restitution), done)
	end,

	b3d_create_capsule = function(bodyHandle, ax, ay, az, bx, by, bz, radius, density, friction, restitution)
		return raw_exports.b3d_create_capsule[1](raw_exports.b3d_create_capsule, bodyHandle, into_bits_f32(ax), into_bits_f32(ay), into_bits_f32(az), into_bits_f32(bx), into_bits_f32(by), into_bits_f32(bz), into_bits_f32(radius), into_bits_f32(density), into_bits_f32(friction), into_bits_f32(restitution), done)
	end,

	b3d_create_box = function(bodyHandle, hx, hy, hz, density, friction, restitution)
		return raw_exports.b3d_create_box[1](raw_exports.b3d_create_box, bodyHandle, into_bits_f32(hx), into_bits_f32(hy), into_bits_f32(hz), into_bits_f32(density), into_bits_f32(friction), into_bits_f32(restitution), done)
	end,

	b3d_destroy_shape = function(shapeHandle)
		return call(raw_exports.b3d_destroy_shape, shapeHandle)
	end,

	b3d_get_body_transform = function(bodyHandle, outPtr)
		return raw_exports.b3d_get_body_transform[1](raw_exports.b3d_get_body_transform, bodyHandle, outPtr or 1048576, done)
	end,

	b3d_set_body_transform = function(bodyHandle, x, y, z, qx, qy, qz, qw)
		return raw_exports.b3d_set_body_transform[1](raw_exports.b3d_set_body_transform, bodyHandle, into_bits_f32(x), into_bits_f32(y), into_bits_f32(z), into_bits_f32(qx), into_bits_f32(qy), into_bits_f32(qz), into_bits_f32(qw), done)
	end,

	b3d_get_body_linear_velocity = function(bodyHandle, outPtr)
		return raw_exports.b3d_get_body_linear_velocity[1](raw_exports.b3d_get_body_linear_velocity, bodyHandle, outPtr or 1048608, done)
	end,

	b3d_set_body_linear_velocity = function(bodyHandle, x, y, z)
		return raw_exports.b3d_set_body_linear_velocity[1](raw_exports.b3d_set_body_linear_velocity, bodyHandle, into_bits_f32(x), into_bits_f32(y), into_bits_f32(z), done)
	end,
}

return rt_export_map
LUA
