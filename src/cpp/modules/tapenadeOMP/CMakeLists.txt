project("ADBench_TapenadeOMP" C CXX Fortran)

add_library("TapenadeOMP" MODULE)

add_subdirectory("ba")

set(COMMON_FLAGS "${COMMON_FLAGS} -lpthread -fopenmp -O2")

set(CMAKE_C_FLAGS "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS "${COMMON_FLAGS}")
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -O2 -fopenmp")


target_sources("TapenadeOMP" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("TapenadeOMP" PRIVATE "tapenade/ADFirstAidKit/adStack.c")
target_sources("TapenadeOMP" PRIVATE "tapenade/ADFirstAidKit/adOMP.c")

target_sources("TapenadeOMP" PRIVATE "gmm/f_tapenade_b_omp.f90")
target_sources("TapenadeOMP" PUBLIC "TapenadeGMM.cpp")

target_sources("TapenadeOMP" PRIVATE "ba/ba.c")
target_sources("TapenadeOMP" PRIVATE "ba/ba_b.c")
target_sources("TapenadeOMP" PUBLIC "TapenadeBA.cpp")





