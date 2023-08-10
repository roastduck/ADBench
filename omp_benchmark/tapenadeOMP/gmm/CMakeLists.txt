project(TBA)

if(DEFINED OMP)
add_definitions(-DOMP)
add_definitions(-DOBONLY)
add_definitions(-DFORTRAN)

message("use omp")
set(COMMON_FLAGS "${COMMON_FLAGS}   -lpthread  -fopenmp -O2 -g ")
else()
set(COMMON_FLAGS "${COMMON_FLAGS}  -O2 -g")
endif()


set(CMAKE_C_FLAGS "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS "${COMMON_FLAGS}")
set(CMAKE_Fortran_COMPILER  gfortran)
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
enable_language(Fortran)

include_directories(../shared)
if(DEFINED OMP)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS}  -O2  -fopenmp -g  ")
    add_library(libname STATIC "gmm/f_tapenade_omp_b.f90")
    set_target_properties(libname PROPERTIES LINKER_LANGUAGE Fortran)
    add_executable(omp TapenadeGMM.cpp ../../runner/main.cpp ../../runner/Filepaths.cpp 
    ../../runner/GMMBenchmark.cpp ../../runner/ModuleLoader.cpp ../../runner/OutputSave.cpp 
    ../../shared/utils.cpp ../ADFirstAidKit/adStack.c ../ADFirstAidKit/adOMP.c)
    target_link_libraries(omp libname)
else()
    #set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -O2 -g")
    #add_library(libname STATIC "gmm/f_tapenade_serial_b.f90")
    #set_target_properties(libname PROPERTIES LINKER_LANGUAGE Fortran)
    add_executable(serial TapenadeGMM.cpp ../../runner/main.cpp ../../runner/Filepaths.cpp 
    ../../runner/GMMBenchmark.cpp ../../runner/ModuleLoader.cpp ../../runner/OutputSave.cpp 
    ../../shared/utils.cpp ../ADFirstAidKit/adStack.c gmm/gmm_b.c gmm/gmm.c)
    #target_link_libraries(serial libname)
endif()





