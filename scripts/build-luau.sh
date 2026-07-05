#!/usr/bin/env bash
set -euo pipefail

mkdir -p build-wasm
spider-cli compile -O -t luau build-wasm/box3d_wasm.wasm > build-wasm/box3d.luau
perl -0pi -e 's/local buffer_write_f32 = buffer\.writef32\n\nlocal function rt_store_f32\(destination: Memory, offset: number, source: number\)\n\tbuffer_write_u32\(destination\[1\], offset, source\)\nend\n\nlocal buffer_write_u32 = buffer\.writeu32/local buffer_write_f32 = buffer.writef32\nlocal buffer_write_u32 = buffer.writeu32\n\nlocal function rt_store_f32(destination: Memory, offset: number, source: number)\n\tbuffer_write_u32(destination[1], offset, source)\nend/' build-wasm/box3d.luau
cat >> build-wasm/box3d.luau <<'LUA'

return {
	module = module,
	rt_import_map = rt_import_map,
	rt_export_map = rt_export_map,
	into_bits_f32 = into_bits_f32,
}
LUA
