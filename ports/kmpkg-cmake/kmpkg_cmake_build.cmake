include_guard(GLOBAL)

function(kmpkg_cmake_build)
    cmake_parse_arguments(PARSE_ARGV 0 "arg" "DISABLE_PARALLEL;ADD_BIN_TO_PATH" "TARGET;LOGFILE_BASE" "")

    if(DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "kmpkg_cmake_build was passed extra arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()
    if(NOT DEFINED arg_LOGFILE_BASE)
        set(arg_LOGFILE_BASE "build")
    endif()
    kmpkg_list(SET build_param)
    kmpkg_list(SET parallel_param)
    kmpkg_list(SET no_parallel_param)

    if("${Z_KMPKG_CMAKE_GENERATOR}" STREQUAL "Ninja")
        kmpkg_list(SET build_param "-v") # verbose output
        kmpkg_list(SET parallel_param "-j${KMPKG_CONCURRENCY}")
        kmpkg_list(SET no_parallel_param "-j1")
    elseif("${Z_KMPKG_CMAKE_GENERATOR}" MATCHES "^Visual Studio")
        kmpkg_list(SET build_param
            "/p:KMPkgLocalAppDataDisabled=true"
            "/p:UseIntelMKL=No"
        )
        kmpkg_list(SET parallel_param "/m")
    elseif("${Z_KMPKG_CMAKE_GENERATOR}" STREQUAL "NMake Makefiles")
        # No options are currently added for nmake builds
    elseif(Z_KMPKG_CMAKE_GENERATOR STREQUAL "Unix Makefiles")
        kmpkg_list(SET build_param "VERBOSE=1")
        kmpkg_list(SET parallel_param "-j${KMPKG_CONCURRENCY}")
        kmpkg_list(SET no_parallel_param "")
    elseif(Z_KMPKG_CMAKE_GENERATOR STREQUAL "Xcode")
        kmpkg_list(SET parallel_param -jobs "${KMPKG_CONCURRENCY}")
        kmpkg_list(SET no_parallel_param -jobs 1)
    else()
        message(WARNING "Unrecognized GENERATOR setting from kmpkg_cmake_configure().")
    endif()

    kmpkg_list(SET target_param)
    if(arg_TARGET)
        kmpkg_list(SET target_param "--target" "${arg_TARGET}")
    endif()

    foreach(build_type IN ITEMS debug release)
        if(NOT DEFINED KMPKG_BUILD_TYPE OR "${KMPKG_BUILD_TYPE}" STREQUAL "${build_type}")
            if("${build_type}" STREQUAL "debug")
                set(short_build_type "dbg")
                set(config "Debug")
            else()
                set(short_build_type "rel")
                set(config "Release")
            endif()

            message(STATUS "Building ${TARGET_TRIPLET}-${short_build_type}")

            if(arg_ADD_BIN_TO_PATH)
                kmpkg_backup_env_variables(VARS PATH)
                if("${build_type}" STREQUAL "debug")
                    kmpkg_add_to_path(PREPEND "${CURRENT_INSTALLED_DIR}/debug/bin")
                else()
                    kmpkg_add_to_path(PREPEND "${CURRENT_INSTALLED_DIR}/bin")
                endif()
            endif()

            if(arg_DISABLE_PARALLEL)
                kmpkg_execute_build_process(
                    COMMAND
                        "${CMAKE_COMMAND}" --build . --config "${config}" ${target_param}
                        -- ${build_param} ${no_parallel_param}
                    WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${short_build_type}"
                    LOGNAME "${arg_LOGFILE_BASE}-${TARGET_TRIPLET}-${short_build_type}"
                )
            else()
                kmpkg_execute_build_process(
                    COMMAND
                        "${CMAKE_COMMAND}" --build . --config "${config}" ${target_param}
                        -- ${build_param} ${parallel_param}
                    NO_PARALLEL_COMMAND
                        "${CMAKE_COMMAND}" --build . --config "${config}" ${target_param}
                        -- ${build_param} ${no_parallel_param}
                    WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${short_build_type}"
                    LOGNAME "${arg_LOGFILE_BASE}-${TARGET_TRIPLET}-${short_build_type}"
                )
            endif()

            if(arg_ADD_BIN_TO_PATH)
                kmpkg_restore_env_variables(VARS PATH)
            endif()
        endif()
    endforeach()
endfunction()
