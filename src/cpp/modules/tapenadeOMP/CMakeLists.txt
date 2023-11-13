project("ADBench_TapenadeOMP" C CXX Fortran)

add_library("TapenadeOMP" MODULE)

add_subdirectory("ba")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -lpthread -fopenmp")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -lpthread -fopenmp")
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fopenmp")
set(CMAKE_C_FLAGS_RELEASE "-O2")
set(CMAKE_CXX_FLAGS_RELEASE "-O2")
set(CMAKE_Fortran_FLAGS_RELEASE "-O2")

target_sources("TapenadeOMP" PRIVATE "${CMAKE_SOURCE_DIR}/src/cpp/shared/utils.cpp")
target_sources("TapenadeOMP" PRIVATE "tapenade/ADFirstAidKit/adStack.c")
target_sources("TapenadeOMP" PRIVATE "tapenade/ADFirstAidKit/adOMP.c")

target_sources("TapenadeOMP" PRIVATE "gmm/f_tapenade_b_omp.f90")
target_sources("TapenadeOMP" PUBLIC "TapenadeGMM.cpp")

target_sources("TapenadeOMP" PRIVATE "ba/ba.c")
target_sources("TapenadeOMP" PRIVATE "ba/ba_b.c")
target_sources("TapenadeOMP" PUBLIC "TapenadeBA.cpp")
