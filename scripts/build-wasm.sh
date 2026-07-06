#!/usr/bin/env bash
set -euo pipefail

profile="${BOX3D_WASM_API_PROFILE:-demo}"
if [ "${BOX3D_WASM_FULL_API:-OFF}" = "ON" ]; then
  profile="full"
fi

python3 scripts/generate-api-bindings.py --profile "$profile" --omit "${BOX3D_WASM_OMIT_FUNCTIONS:-}"
python3 scripts/generate-api-coverage.py
emcmake cmake -S wasm -B build-wasm -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-wasm
