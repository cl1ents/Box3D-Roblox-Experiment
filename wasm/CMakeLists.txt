cmake_minimum_required(VERSION 3.22)

project(box3d_wasm LANGUAGES C CXX)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BOX3D_SAMPLES OFF CACHE BOOL "" FORCE)
set(BOX3D_UNIT_TESTS OFF CACHE BOOL "" FORCE)
set(BOX3D_BENCHMARKS OFF CACHE BOOL "" FORCE)
set(BOX3D_VALIDATE OFF CACHE BOOL "" FORCE)
set(BOX3D_DISABLE_SIMD ON CACHE BOOL "" FORCE)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../box3d ${CMAKE_CURRENT_BINARY_DIR}/box3d)

add_executable(box3d_wasm box3d_bridge.c)
target_link_libraries(box3d_wasm PRIVATE box3d::box3d)
target_compile_features(box3d_wasm PRIVATE c_std_17)

if(EMSCRIPTEN)
  set(BOX3D_WASM_EXPORTS_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../build-wasm/box3d_exports.cmake")
  if(EXISTS "${BOX3D_WASM_EXPORTS_FILE}")
    include("${BOX3D_WASM_EXPORTS_FILE}")
  else()
    set(BOX3D_WASM_EXPORTED_FUNCTIONS "['_b3d_create_world','_b3d_step','_b3d_create_body','_b3d_create_sphere','_b3d_create_box','_b3d_get_body_transform']")
  endif()

  target_compile_options(box3d PRIVATE -Oz -flto -ffunction-sections -fdata-sections)
  target_compile_options(box3d_wasm PRIVATE -Oz -flto -ffunction-sections -fdata-sections)

  set_target_properties(box3d_wasm PROPERTIES SUFFIX ".wasm")
  target_link_options(box3d_wasm PRIVATE
    "-Oz"
    "-flto"
    "-Wl,--gc-sections"
    "--no-entry"
    "-sSTANDALONE_WASM=1"
    "-sALLOW_MEMORY_GROWTH=1"
    "-sASSERTIONS=0"
    "-sFILESYSTEM=0"
    "-sMALLOC=emmalloc"
    "-sEXPORTED_FUNCTIONS=${BOX3D_WASM_EXPORTED_FUNCTIONS}"
  )
endif()
