set(COMMON_FLAGS "${COMMON_FLAGS}   -lpthread   -fopenmp -O2 -g")

set(CMAKE_C_FLAGS "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS "${COMMON_FLAGS}")
set(CMAKE_Fortran_COMPILER  gfortran)
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
enable_language(Fortran)


set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -march=native  -g")
add_library(libname STATIC "gmm/f_tapenade_omp_b.f90")
set_target_properties(libname PROPERTIES LINKER_LANGUAGE Fortran)

add_executable(omp TapenadeGMM.cpp ../../runner/main.cpp ../../runner/Filepaths.cpp ../../runner/GMMBenchmark.cpp ../../runner/ModuleLoader.cpp ../../runner/OutputSave.cpp ../../shared/utils.cpp ADFirstAidKit/adStack.c ADFirstAidKit/adOMP.c)
target_link_libraries(omp libname)



