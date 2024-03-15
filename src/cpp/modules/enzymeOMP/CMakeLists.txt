project("ADBench_EnzymeOMP" C CXX)

set(CMAKE_C_COMPILER "/utils/clang/llvm-project-12.0.1.src/build/bin/clang")
set(CMAKE_CXX_COMPILER "/utils/clang/llvm-project-12.0.1.src/build/bin/clang++")
set(clang_enzyme_path "/adb/src/parallel-ad-minibench/enzyme/Enzyme/enzyme/build/Enzyme/ClangEnzyme-12.so")
set(clang_omp_runtime "/utils/clang/llvm-project-12.0.1.src/build/projects/openmp/runtime/src/")


add_library("EnzymeOMP" MODULE)

set(CMAKE_C_FLAGS "-DOMP=1 -Xclang -load -Xclang ${clang_enzyme_path} -O2 -std=c++20 -Wall -I ${clang_omp_runtime} -fopenmp")
set(CMAKE_CXX_FLAGS "-DOMP=1 -Xclang -load -Xclang ${clang_enzyme_path} -O2 -std=c++20 -Wall -I ${clang_omp_runtime} -fopenmp")


target_sources("EnzymeOMP" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")

target_sources("EnzymeOMP" PRIVATE "../enzyme/ba/ba.cpp")
target_sources("EnzymeOMP" PUBLIC "../enzyme/EnzymeBA.cpp")

target_sources("EnzymeOMP" PRIVATE "../enzyme/gmm/gmm.cpp")
target_sources("EnzymeOMP" PUBLIC "../enzyme/EnzymeGMM.cpp")
