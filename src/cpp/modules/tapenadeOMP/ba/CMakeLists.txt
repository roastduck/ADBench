
set(ENV{PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../tapenade/bin/:$ENV{PATH}")
execute_process(COMMAND tapenade -b -o ba -head "compute_reproj_error(err)/(w cam X)" -head "compute_zach_weight_error(err)/(w)" ba.c
		WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
		RESULT_VARIABLE result_var
                OUTPUT_VARIABLE output_var
                ERROR_VARIABLE error_var)

if(result_var AND NOT result_var EQUAL 0)
	message(STATUS "Working directory: ${CMAKE_CURRENT_SOURCE_DIR}")
	message(STATUS "Running command: tapenade -b -o ba -head \"compute_reproj_error(err)/(w cam X)\" -head \"compute_zach_weight_error(err)/(w)\" ba.c")
	message(STATUS "result_var: ${result_var}")
	message(STATUS "output_var: ${output_var}") 
	message(STATUS "error_var: ${error_var}")
endif()

execute_process(COMMAND patch -p0 ba_b.c ba_b.patch
		WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
		RESULT_VARIABLE result_var
                OUTPUT_VARIABLE output_var
                ERROR_VARIABLE error_var)

if(result_var AND NOT result_var EQUAL 0)
	message(STATUS "Working directory: ${CMAKE_CURRENT_SOURCE_DIR}")
	message(STATUS "Running command: patch -p0 ba_b.c ba_b.patch")
	message(STATUS "result_var: ${result_var}")
	message(STATUS "output_var: ${output_var}") 
	message(STATUS "error_var: ${error_var}")
endif()

