include_guard(GLOBAL)
include("${CMAKE_CURRENT_LIST_DIR}/kmpkg_make.cmake")

function(kmpkg_make_install)
    cmake_parse_arguments(PARSE_ARGV 0 arg
        "DISABLE_PARALLEL"
        "LOGFILE_ROOT;MAKEFILE"
        "OPTIONS;OPTIONS_DEBUG;OPTIONS_RELEASE;TARGETS"
    )
    z_kmpkg_unparsed_args(FATAL_ERROR)

    if(NOT DEFINED arg_LOGFILE_ROOT)
        set(arg_LOGFILE_ROOT "make")
    endif()

    if(NOT DEFINED arg_TARGETS)
        set(arg_TARGETS "all;install")
    endif()

    if (NOT DEFINED arg_MAKEFILE)
        set(arg_MAKEFILE Makefile)
    endif()

    # Can be set in the triplet to append options for configure
    if(DEFINED KMPKG_MAKE_OPTIONS)
        kmpkg_list(APPEND arg_OPTIONS ${KMPKG_MAKE_OPTIONS})
    endif()
    if(DEFINED KMPKG_MAKE_OPTIONS_RELEASE)
        kmpkg_list(APPEND arg_OPTIONS_RELEASE ${KMPKG_MAKE_OPTIONS_RELEASE})
    endif()
    if(DEFINED KMPKG_MAKE_OPTIONS_DEBUG)
        kmpkg_list(APPEND arg_OPTIONS_DEBUG ${KMPKG_MAKE_OPTIONS_DEBUG})
    endif()

    if(CMAKE_HOST_WIN32)
        set(Z_KMPKG_INSTALLED "${CURRENT_INSTALLED_DIR}")
    else()
        string(REPLACE " " "\ " Z_KMPKG_INSTALLED "${CURRENT_INSTALLED_DIR}")
    endif()

    kmpkg_make_get_shell(shell_var)
    set(shell_cmd "${shell_var}")

    if(KMPKG_HOST_IS_BSD)
        find_program(Z_KMPKG_MAKE gmake REQUIRED)
    else()
        find_program(Z_KMPKG_MAKE NAMES make gmake NAMES_PER_DIR REQUIRED)
    endif()
    set(make_command "${Z_KMPKG_MAKE}")

    set(destdir "${CURRENT_PACKAGES_DIR}")
    if (CMAKE_HOST_WIN32)
        set(path_backup "$ENV{PATH}")
        kmpkg_add_to_path(PREPEND "${CURRENT_HOST_INSTALLED_DIR}/share/kmpkg-make/wrappers")
        string(REPLACE " " [[\ ]] kmpkg_package_prefix "${CURRENT_PACKAGES_DIR}")
        string(REGEX REPLACE [[([a-zA-Z]):/]] [[/\1/]] destdir "${kmpkg_package_prefix}")
    endif()

    kmpkg_backup_env_variables(VARS LIB LIBPATH LIBRARY_PATH LD_LIBRARY_PATH CPPFLAGS CFLAGS CXXFLAGS RCFLAGS PATH)

    z_kmpkg_make_set_common_vars()
    z_kmpkg_get_global_property(prepare_flags_opts "make_prepare_flags_opts")
    
    z_kmpkg_make_prepare_flags(${prepare_flags_opts})

    set(prepare_env_opts "")

    set(trace_opts "")
    if(DEFINED KMPKG_MAKE_TRACE_OPTIONS)
        set(trace_opts "${KMPKG_MAKE_TRACE_OPTIONS}")
    else()
        # --trace is a GNU make option
        execute_process(
            COMMAND "${Z_KMPKG_MAKE}" --help
            OUTPUT_VARIABLE make_help_output
            ERROR_VARIABLE make_help_output
        )
        if(make_help_output MATCHES "--trace")
            set(trace_opts "--trace")
        endif()
    endif()

    foreach(buildtype IN LISTS buildtypes)
        string(TOUPPER "${buildtype}" cmake_buildtype)
        set(short_buildtype "${suffix_${cmake_buildtype}}")
        set(path_suffix "${path_suffix_${cmake_buildtype}}")

        set(working_directory "${workdir_${cmake_buildtype}}")
        message(STATUS "Building/Installing ${TARGET_TRIPLET}-${short_buildtype}")

        # Setup environment
        z_kmpkg_make_prepare_env("${cmake_buildtype}" ${prepare_env_opts})
        z_kmpkg_make_prepare_programs(configure_env ${prepare_flags_opts} CONFIG "${cmake_buildtype}")

        set(destdir_opt "DESTDIR=${destdir}")

        foreach(target IN LISTS arg_TARGETS)
            string(REPLACE "/" "_" target_no_slash "${target}")
            kmpkg_list(SET make_cmd_line ${make_command} ${arg_OPTIONS} ${arg_OPTIONS_${cmake_buildtype}} V=1 -j ${KMPKG_CONCURRENCY} ${trace_opts} -f ${arg_MAKEFILE} ${target} ${destdir_opt})
            kmpkg_list(SET no_parallel_make_cmd_line ${make_command} ${arg_OPTIONS} ${arg_OPTIONS_${cmake_buildtype}} V=1 -j 1 ${trace_opts} -f ${arg_MAKEFILE} ${target} ${destdir_opt})
            message(STATUS "Making target '${target}' for ${TARGET_TRIPLET}-${short_buildtype}")
            if (arg_DISABLE_PARALLEL)
                kmpkg_run_shell_as_build(
                    WORKING_DIRECTORY "${working_directory}"
                    LOGNAME "${arg_LOGFILE_ROOT}-${target_no_slash}-${TARGET_TRIPLET}-${short_buildtype}"
                    SHELL ${shell_cmd}
                    COMMAND ${configure_env} ${no_parallel_make_cmd_line}
                )
            else()
                kmpkg_run_shell_as_build(
                    WORKING_DIRECTORY "${working_directory}"
                    LOGNAME "${arg_LOGFILE_ROOT}-${target_no_slash}-${TARGET_TRIPLET}-${short_buildtype}"
                    SHELL ${shell_cmd}
                    COMMAND ${configure_env} ${make_cmd_line}
                    NO_PARALLEL_COMMAND ${configure_env} ${no_parallel_make_cmd_line}
                )
            endif()
            file(READ "${CURRENT_BUILDTREES_DIR}/${arg_LOGFILE_ROOT}-${target_no_slash}-${TARGET_TRIPLET}-${short_buildtype}-out.log" logdata) 
            if(logdata MATCHES "Warning: linker path does not have real file for library")
                message(FATAL_ERROR "libtool could not find a file being linked against!")
            endif()
        endforeach()

        z_kmpkg_make_restore_env()

        kmpkg_restore_env_variables(VARS LIB LIBPATH LIBRARY_PATH)
    endforeach()

    ## TODO: Fix DESTDIR handling
    string(REGEX REPLACE "([a-zA-Z]):/" "/\\1/" destdir_suffix "${CURRENT_INSTALLED_DIR}")
    if (EXISTS "${CURRENT_PACKAGES_DIR}${destdir_suffix}") # <- Means DESTDIR was correctly used; need to move files.
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}_tmp")
        file(RENAME "${CURRENT_PACKAGES_DIR}" "${CURRENT_PACKAGES_DIR}_tmp")
        file(RENAME "${CURRENT_PACKAGES_DIR}_tmp${destdir_suffix}" "${CURRENT_PACKAGES_DIR}")
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}_tmp")
    endif()

    # Remove libtool files since they contain absolute paths and are not necessary. 
    file(GLOB_RECURSE libtool_files "${CURRENT_PACKAGES_DIR}/**/*.la")
    if(libtool_files)
        file(REMOVE ${libtool_files})
    endif()

    if (CMAKE_HOST_WIN32)
        set(ENV{PATH} "${path_backup}")
    endif()

    kmpkg_restore_env_variables(VARS LIB LIBPATH LIBRARY_PATH LD_LIBRARY_PATH CPPFLAGS CFLAGS CXXFLAGS RCFLAGS)
endfunction()
