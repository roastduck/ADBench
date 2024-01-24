project("ADBench_Enzyme" C CXX)

set(CMAKE_C_COMPILER "/utils/clang/llvm-project-12.0.1.src/build/bin/clang")
set(CMAKE_CXX_COMPILER "/utils/clang/llvm-project-12.0.1.src/build/bin/clang++")
set(clang_enzyme_path "/adb/src/parallel-ad-minibench/enzyme/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so")
set(clang_omp_runtime "/utils/clang/llvm-project-12.0.1.src/build/projects/openmp/runtime/src/")


add_library("Enzyme" MODULE)

set(CMAKE_C_FLAGS "-Xclang -load -Xclang ${clang_enzyme_path} -O2 -std=c++20 -Wall")
set(CMAKE_CXX_FLAGS "-Xclang -load -Xclang ${clang_enzyme_path} -O2 -std=c++20 -Wall")


target_sources("Enzyme" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")

target_sources("Enzyme" PRIVATE "ba/ba.cpp")
target_sources("Enzyme" PUBLIC "EnzymeBA.cpp")
