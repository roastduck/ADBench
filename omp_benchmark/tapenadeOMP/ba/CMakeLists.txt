if(DEFINED OMP)
message("use omp")
add_definitions(-DOMP)
set(COMMON_FLAGS "${COMMON_FLAGS}   -lpthread   -fopenmp -O2 -g")
else()
set(COMMON_FLAGS "${COMMON_FLAGS}  -O2 -g")
endif()

if(DEFINED OBJONLY)
message("OBJONLY ")
add_definitions(-DOBJONLY)
endif()

set(CMAKE_C_FLAGS "${COMMON_FLAGS}")
set(CMAKE_CXX_FLAGS "${COMMON_FLAGS}")
set(CMAKE_Fortran_COMPILER  gfortran)
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
enable_language(Fortran)
#SET(F_OBJ f_tapenade_b.f90  )


include_directories(../runner)
include_directories(../shared)
include_directories(../utils)
#ADD_LIBRARY (name STATIC ${F_OBJ}   )
#SET_TARGET_PROPERTIES(name PROPERTIES LINKER_LANGUAGE Fortran)


if(DEFINED OMP)
    add_executable(omp main_ba.cpp  ../runner/Filepaths.cpp  ../runner/BABenchmark.cpp ../runner/OutputSave.cpp 
                    ../runner/ModuleLoader.cpp ../shared/utils.cpp
                    TapenadeBA.cpp ba/ba_b.c ba/ba.c ../ADFirstAidKit/adStack.c )
else()
    add_executable(serial main_ba.cpp  ../runner/Filepaths.cpp  ../runner/BABenchmark.cpp ../runner/OutputSave.cpp 
                    ../runner/ModuleLoader.cpp ../shared/utils.cpp
                    TapenadeBA.cpp ba/ba_b.c ba/ba.c ../ADFirstAidKit/adStack.c )
endif()






 

