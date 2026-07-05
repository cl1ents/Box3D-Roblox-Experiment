#!/usr/bin/env bash
set -euo pipefail

emcmake cmake -S wasm -B build-wasm -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-wasm
