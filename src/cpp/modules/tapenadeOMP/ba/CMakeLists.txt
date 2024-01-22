
set(ENV{PATH} "${CMAKE_CURRENT_SOURCE_DIR}/../tapenade/bin/:$ENV{PATH}")
execute_process(COMMAND tapenade -b -o ba -head "compute_reproj_error(err)/(w cam X)" -head "compute_zach_weight_error(err)/(w)" ba.c
		WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        COMMAND_ERROR_IS_FATAL ANY)

execute_process(COMMAND patch -p0 ba_b.c ba_b.patch
		WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        COMMAND_ERROR_IS_FATAL ANY)

