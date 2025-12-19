include_guard(GLOBAL)

macro(z_kmpkg_cmake_configure_both_set_or_unset var1 var2)
    if(DEFINED ${var1} AND NOT DEFINED ${var2})
        message(FATAL_ERROR "If ${var1} is set, then ${var2} must be set.")
    elseif(NOT DEFINED ${var1} AND DEFINED ${var2})
        message(FATAL_ERROR "If ${var2} is set, then ${var1} must be set.")
    endif()
endmacro()

function(kmpkg_cmake_configure)
    cmake_parse_arguments(PARSE_ARGV 0 "arg"
        "PREFER_NINJA;DISABLE_PARALLEL_CONFIGURE;WINDOWS_USE_MSBUILD;NO_CHARSET_FLAG;Z_CMAKE_GET_VARS_USAGE"
        "SOURCE_PATH;GENERATOR;LOGFILE_BASE"
        "OPTIONS;OPTIONS_DEBUG;OPTIONS_RELEASE;MAYBE_UNUSED_VARIABLES"
    )

    if(NOT arg_Z_CMAKE_GET_VARS_USAGE AND DEFINED CACHE{Z_KMPKG_CMAKE_GENERATOR})
        message(WARNING "${CMAKE_CURRENT_FUNCTION} already called; this function should only be called once.")
    endif()
    if(arg_PREFER_NINJA)
        message(WARNING "PREFER_NINJA has been deprecated in ${CMAKE_CURRENT_FUNCTION}. Please remove it from the portfile!")
    endif()

    if(DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} was passed extra arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT DEFINED arg_SOURCE_PATH)
        message(FATAL_ERROR "SOURCE_PATH must be set")
    endif()
    if(NOT DEFINED arg_LOGFILE_BASE)
        set(arg_LOGFILE_BASE "config-${TARGET_TRIPLET}")
    endif()

    set(invalid_maybe_unused_vars "${arg_MAYBE_UNUSED_VARIABLES}")
    list(FILTER invalid_maybe_unused_vars INCLUDE REGEX "^-D")
    if(NOT invalid_maybe_unused_vars STREQUAL "")
        list(JOIN invalid_maybe_unused_vars " " bad_items)
        message(${Z_KMPKG_BACKCOMPAT_MESSAGE_LEVEL}
            "Option MAYBE_UNUSED_VARIABLES must be used with variables names. "
            "The following items are invalid: ${bad_items}")
    endif()

    set(manually_specified_variables "")

    if(arg_Z_CMAKE_GET_VARS_USAGE)
        set(configuring_message "Getting CMake variables for ${TARGET_TRIPLET}")
    else()
        set(configuring_message "Configuring ${TARGET_TRIPLET}")

        foreach(option IN LISTS arg_OPTIONS arg_OPTIONS_RELEASE arg_OPTIONS_DEBUG)
            if("${option}" MATCHES "^-D([^:=]*)[:=]")
                kmpkg_list(APPEND manually_specified_variables "${CMAKE_MATCH_1}")
            endif()
        endforeach()
        kmpkg_list(REMOVE_DUPLICATES manually_specified_variables)
        foreach(maybe_unused_var IN LISTS arg_MAYBE_UNUSED_VARIABLES)
            kmpkg_list(REMOVE_ITEM manually_specified_variables "${maybe_unused_var}")
        endforeach()
        debug_message("manually specified variables: ${manually_specified_variables}")
    endif()

    if(CMAKE_HOST_WIN32)
        if(DEFINED ENV{PROCESSOR_ARCHITEW6432})
            set(host_architecture "$ENV{PROCESSOR_ARCHITEW6432}")
        else()
            set(host_architecture "$ENV{PROCESSOR_ARCHITECTURE}")
        endif()
    endif()

    set(ninja_host ON) # Ninja availability
    if(host_architecture STREQUAL "x86" OR DEFINED ENV{KMPKG_FORCE_SYSTEM_BINARIES})
        # Prebuilt ninja binaries are only provided for x64 hosts
        find_program(NINJA NAMES ninja ninja-build)
        if(NOT NINJA)
            set(ninja_host OFF)
            set(arg_DISABLE_PARALLEL_CONFIGURE ON)
            set(arg_WINDOWS_USE_MSBUILD ON)
        endif()
    endif()

    set(generator "")
    set(architecture_options "")
    if(arg_WINDOWS_USE_MSBUILD AND KMPKG_HOST_IS_WINDOWS AND KMPKG_TARGET_IS_WINDOWS AND NOT KMPKG_TARGET_IS_MINGW)
        z_kmpkg_get_visual_studio_generator(OUT_GENERATOR generator OUT_ARCH arch)
        kmpkg_list(APPEND architecture_options "-A${arch}")
        if(DEFINED KMPKG_PLATFORM_TOOLSET)
            kmpkg_list(APPEND arg_OPTIONS "-T${KMPKG_PLATFORM_TOOLSET}")
        endif()
        if(NOT generator)
            message(FATAL_ERROR "Unable to determine appropriate Visual Studio generator for triplet ${TARGET_TRIPLET}:
    ENV{VisualStudioVersion} : $ENV{VisualStudioVersion}
    KMPKG_TARGET_ARCHITECTURE: ${KMPKG_TARGET_ARCHITECTURE}")
        endif()
    elseif(DEFINED arg_GENERATOR)
        set(generator "${arg_GENERATOR}")
    elseif(ninja_host)
        set(generator "Ninja")
    elseif(NOT KMPKG_HOST_IS_WINDOWS)
        set(generator "Unix Makefiles")
    endif()

    if(NOT generator)
        if(NOT KMPKG_CMAKE_SYSTEM_NAME)
            set(KMPKG_CMAKE_SYSTEM_NAME "Windows")
        endif()
        message(FATAL_ERROR "Unable to determine appropriate generator for: "
            "${KMPKG_CMAKE_SYSTEM_NAME}-${KMPKG_TARGET_ARCHITECTURE}-${KMPKG_PLATFORM_TOOLSET}")
    endif()

    set(parallel_log_args "")
    set(log_args "")

    if(generator STREQUAL "Ninja")
        kmpkg_find_acquire_program(NINJA)
        kmpkg_list(APPEND arg_OPTIONS "-DCMAKE_MAKE_PROGRAM=${NINJA}")
        # If we use Ninja, it must be on PATH for CMake's ExternalProject,
        # cf. https://gitlab.kitware.com/cmake/cmake/-/issues/23355.
        get_filename_component(ninja_path "${NINJA}" DIRECTORY)
        kmpkg_add_to_path("${ninja_path}")
        set(parallel_log_args
            "../build.ninja" ALIAS "rel-ninja.log"
            "../../${TARGET_TRIPLET}-dbg/build.ninja" ALIAS "dbg-ninja.log"
        )
        set(log_args "build.ninja")
    endif()

    set(build_dir_release "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
    set(build_dir_debug "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg")
    file(REMOVE_RECURSE
        "${build_dir_release}"
        "${build_dir_debug}")
    file(MAKE_DIRECTORY "${build_dir_release}")
    if(NOT DEFINED KMPKG_BUILD_TYPE OR KMPKG_BUILD_TYPE STREQUAL "debug")
        file(MAKE_DIRECTORY "${build_dir_debug}")
    endif()

    if(DEFINED KMPKG_CMAKE_SYSTEM_NAME)
        kmpkg_list(APPEND arg_OPTIONS "-DCMAKE_SYSTEM_NAME=${KMPKG_CMAKE_SYSTEM_NAME}")
        if(KMPKG_TARGET_IS_UWP AND NOT DEFINED KMPKG_CMAKE_SYSTEM_VERSION)
            set(KMPKG_CMAKE_SYSTEM_VERSION 10.0)
        elseif(KMPKG_TARGET_IS_ANDROID AND NOT DEFINED KMPKG_CMAKE_SYSTEM_VERSION)
            set(KMPKG_CMAKE_SYSTEM_VERSION 21)
        endif()
    endif()

    if(DEFINED KMPKG_CMAKE_SYSTEM_VERSION)
        kmpkg_list(APPEND arg_OPTIONS "-DCMAKE_SYSTEM_VERSION=${KMPKG_CMAKE_SYSTEM_VERSION}")
    endif()

    if(DEFINED KMPKG_XBOX_CONSOLE_TARGET)
        kmpkg_list(APPEND arg_OPTIONS "-DXBOX_CONSOLE_TARGET=${KMPKG_XBOX_CONSOLE_TARGET}")
    endif()

    if(KMPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        kmpkg_list(APPEND arg_OPTIONS "-DBUILD_SHARED_LIBS=ON")
    elseif(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
        kmpkg_list(APPEND arg_OPTIONS "-DBUILD_SHARED_LIBS=OFF")
    else()
        message(FATAL_ERROR
            "Invalid setting for KMPKG_LIBRARY_LINKAGE: \"${KMPKG_LIBRARY_LINKAGE}\". "
            "It must be \"static\" or \"dynamic\"")
    endif()

    z_kmpkg_cmake_configure_both_set_or_unset(KMPKG_CXX_FLAGS_DEBUG KMPKG_C_FLAGS_DEBUG)
    z_kmpkg_cmake_configure_both_set_or_unset(KMPKG_CXX_FLAGS_RELEASE KMPKG_C_FLAGS_RELEASE)
    z_kmpkg_cmake_configure_both_set_or_unset(KMPKG_CXX_FLAGS KMPKG_C_FLAGS)

    set(KMPKG_SET_CHARSET_FLAG ON)
    if(arg_NO_CHARSET_FLAG)
        set(KMPKG_SET_CHARSET_FLAG OFF)
    endif()

    if(NOT DEFINED KMPKG_CHAINLOAD_TOOLCHAIN_FILE)
        z_kmpkg_select_default_kmpkg_chainload_toolchain()
    endif()

    list(JOIN KMPKG_TARGET_ARCHITECTURE "\;" target_architecture_string)
    kmpkg_list(APPEND arg_OPTIONS
        "-DKMPKG_CHAINLOAD_TOOLCHAIN_FILE=${KMPKG_CHAINLOAD_TOOLCHAIN_FILE}"
        "-DKMPKG_TARGET_TRIPLET=${TARGET_TRIPLET}"
        "-DKMPKG_SET_CHARSET_FLAG=${KMPKG_SET_CHARSET_FLAG}"
        "-DKMPKG_PLATFORM_TOOLSET=${KMPKG_PLATFORM_TOOLSET}"
        "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON"
        "-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON"
        "-DCMAKE_FIND_PACKAGE_NO_SYSTEM_PACKAGE_REGISTRY=ON"
        "-DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=TRUE"
        "-DCMAKE_VERBOSE_MAKEFILE=ON"
        "-DKMPKG_APPLOCAL_DEPS=OFF"
        "-DCMAKE_TOOLCHAIN_FILE=${SCRIPTS}/buildsystems/kmpkg.cmake"
        "-DCMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION=ON"
        "-DKMPKG_CXX_FLAGS=${KMPKG_CXX_FLAGS}"
        "-DKMPKG_CXX_FLAGS_RELEASE=${KMPKG_CXX_FLAGS_RELEASE}"
        "-DKMPKG_CXX_FLAGS_DEBUG=${KMPKG_CXX_FLAGS_DEBUG}"
        "-DKMPKG_C_FLAGS=${KMPKG_C_FLAGS}"
        "-DKMPKG_C_FLAGS_RELEASE=${KMPKG_C_FLAGS_RELEASE}"
        "-DKMPKG_C_FLAGS_DEBUG=${KMPKG_C_FLAGS_DEBUG}"
        "-DKMPKG_CRT_LINKAGE=${KMPKG_CRT_LINKAGE}"
        "-DKMPKG_LINKER_FLAGS=${KMPKG_LINKER_FLAGS}"
        "-DKMPKG_LINKER_FLAGS_RELEASE=${KMPKG_LINKER_FLAGS_RELEASE}"
        "-DKMPKG_LINKER_FLAGS_DEBUG=${KMPKG_LINKER_FLAGS_DEBUG}"
        "-DKMPKG_TARGET_ARCHITECTURE=${target_architecture_string}"
        "-DCMAKE_INSTALL_LIBDIR:STRING=lib"
        "-DCMAKE_INSTALL_BINDIR:STRING=bin"
        "-D_KMPKG_ROOT_DIR=${KMPKG_ROOT_DIR}"
        "-D_KMPKG_INSTALLED_DIR=${_KMPKG_INSTALLED_DIR}"
        "-DKMPKG_MANIFEST_INSTALL=OFF"
    )

    # Sets configuration variables for macOS builds
    foreach(config_var IN ITEMS INSTALL_NAME_DIR OSX_DEPLOYMENT_TARGET OSX_SYSROOT OSX_ARCHITECTURES)
        if(DEFINED KMPKG_${config_var})
            kmpkg_list(APPEND arg_OPTIONS "-DCMAKE_${config_var}=${KMPKG_${config_var}}")
        endif()
    endforeach()

    kmpkg_list(PREPEND arg_OPTIONS "-DFETCHCONTENT_FULLY_DISCONNECTED=ON")

    # Allow overrides / additional configuration variables from triplets
    if(DEFINED KMPKG_CMAKE_CONFIGURE_OPTIONS)
        kmpkg_list(APPEND arg_OPTIONS ${KMPKG_CMAKE_CONFIGURE_OPTIONS})
    endif()
    if(DEFINED KMPKG_CMAKE_CONFIGURE_OPTIONS_RELEASE)
        kmpkg_list(APPEND arg_OPTIONS_RELEASE ${KMPKG_CMAKE_CONFIGURE_OPTIONS_RELEASE})
    endif()
    if(DEFINED KMPKG_CMAKE_CONFIGURE_OPTIONS_DEBUG)
        kmpkg_list(APPEND arg_OPTIONS_DEBUG ${KMPKG_CMAKE_CONFIGURE_OPTIONS_DEBUG})
    endif()

    kmpkg_list(SET rel_command
        "${CMAKE_COMMAND}" "${arg_SOURCE_PATH}" 
        -G "${generator}"
        ${architecture_options}
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_INSTALL_PREFIX=${CURRENT_PACKAGES_DIR}"
        ${arg_OPTIONS} ${arg_OPTIONS_RELEASE})
    kmpkg_list(SET dbg_command
        "${CMAKE_COMMAND}" "${arg_SOURCE_PATH}" 
        -G "${generator}"
        ${architecture_options}
        "-DCMAKE_BUILD_TYPE=Debug"
        "-DCMAKE_INSTALL_PREFIX=${CURRENT_PACKAGES_DIR}/debug"
        ${arg_OPTIONS} ${arg_OPTIONS_DEBUG})

    if(NOT arg_DISABLE_PARALLEL_CONFIGURE)
        kmpkg_list(APPEND arg_OPTIONS "-DCMAKE_DISABLE_SOURCE_CHANGES=ON")

        kmpkg_find_acquire_program(NINJA)

        #parallelize the configure step
        set(ninja_configure_contents
            "rule CreateProcess\n  command = \$process\n\n"
        )

        if(NOT DEFINED KMPKG_BUILD_TYPE OR "${KMPKG_BUILD_TYPE}" STREQUAL "release")
            z_kmpkg_configure_cmake_build_cmakecache(ninja_configure_contents ".." "rel")
        endif()
        if(NOT DEFINED KMPKG_BUILD_TYPE OR "${KMPKG_BUILD_TYPE}" STREQUAL "debug")
            z_kmpkg_configure_cmake_build_cmakecache(ninja_configure_contents "../../${TARGET_TRIPLET}-dbg" "dbg")
        endif()

        file(MAKE_DIRECTORY "${build_dir_release}/kmpkg-parallel-configure")
        file(WRITE
            "${build_dir_release}/kmpkg-parallel-configure/build.ninja"
            "${ninja_configure_contents}")

        message(STATUS "${configuring_message}")
        kmpkg_execute_required_process(
            COMMAND "${NINJA}" -v
            WORKING_DIRECTORY "${build_dir_release}/kmpkg-parallel-configure"
            LOGNAME "${arg_LOGFILE_BASE}"
            SAVE_LOG_FILES
                "../../${TARGET_TRIPLET}-dbg/CMakeCache.txt" ALIAS "dbg-CMakeCache.txt.log"
                "../CMakeCache.txt" ALIAS "rel-CMakeCache.txt.log"
                "../../${TARGET_TRIPLET}-dbg/CMakeFiles/CMakeConfigureLog.yaml" ALIAS "dbg-CMakeConfigureLog.yaml.log"
                "../CMakeFiles/CMakeConfigureLog.yaml" ALIAS "rel-CMakeConfigureLog.yaml.log"
                ${parallel_log_args}
        )
        
        kmpkg_list(APPEND config_logs
            "${CURRENT_BUILDTREES_DIR}/${arg_LOGFILE_BASE}-out.log"
            "${CURRENT_BUILDTREES_DIR}/${arg_LOGFILE_BASE}-err.log")
    else()
        if(NOT DEFINED KMPKG_BUILD_TYPE OR "${KMPKG_BUILD_TYPE}" STREQUAL "debug")
            message(STATUS "${configuring_message}-dbg")
            kmpkg_execute_required_process(
                COMMAND ${dbg_command}
                WORKING_DIRECTORY "${build_dir_debug}"
                LOGNAME "${arg_LOGFILE_BASE}-dbg"
                SAVE_LOG_FILES
                  "CMakeCache.txt"
                  "CMakeFiles/CMakeConfigureLog.yaml"
                  ${log_args}
            )
            kmpkg_list(APPEND config_logs
                "${CURRENT_BUILDTREES_DIR}/${arg_LOGFILE_BASE}-dbg-out.log"
                "${CURRENT_BUILDTREES_DIR}/${arg_LOGFILE_BASE}-dbg-err.log")
        endif()

        if(NOT DEFINED KMPKG_BUILD_TYPE OR "${KMPKG_BUILD_TYPE}" STREQUAL "release")
            message(STATUS "${configuring_message}-rel")
            kmpkg_execute_required_process(
                COMMAND ${rel_command}
                WORKING_DIRECTORY "${build_dir_release}"
                LOGNAME "${arg_LOGFILE_BASE}-rel"
                SAVE_LOG_FILES
                  "CMakeCache.txt"
                  "CMakeFiles/CMakeConfigureLog.yaml"
                  ${log_args}
            )
            kmpkg_list(APPEND config_logs
                "${CURRENT_BUILDTREES_DIR}/${arg_LOGFILE_BASE}-rel-out.log"
                "${CURRENT_BUILDTREES_DIR}/${arg_LOGFILE_BASE}-rel-err.log")
        endif()
    endif()
    
    set(all_unused_variables)
    foreach(config_log IN LISTS config_logs)
        if(NOT EXISTS "${config_log}")
            continue()
        endif()
        file(READ "${config_log}" log_contents)
        debug_message("Reading configure log ${config_log}...")
        if(NOT log_contents MATCHES "Manually-specified variables were not used by the project:\n\n((    [^\n]*\n)*)")
            continue()
        endif()
        string(STRIP "${CMAKE_MATCH_1}" unused_variables) # remove leading `    ` and trailing `\n`
        string(REPLACE "\n    " ";" unused_variables "${unused_variables}")
        debug_message("unused variables: ${unused_variables}")
        foreach(unused_variable IN LISTS unused_variables)
            if(unused_variable IN_LIST manually_specified_variables)
                debug_message("manually specified unused variable: ${unused_variable}")
                kmpkg_list(APPEND all_unused_variables "${unused_variable}")
            else()
                debug_message("unused variable (not manually specified): ${unused_variable}")
            endif()
        endforeach()
    endforeach()

    if(DEFINED all_unused_variables)
        kmpkg_list(REMOVE_DUPLICATES all_unused_variables)
        kmpkg_list(JOIN all_unused_variables "\n    " all_unused_variables)
        message(WARNING "The following variables are not used in CMakeLists.txt:
    ${all_unused_variables}
Please recheck them and remove the unnecessary options from the `kmpkg_cmake_configure` call.
If these options should still be passed for whatever reason, please use the `MAYBE_UNUSED_VARIABLES` argument.")
    endif()

    if(NOT arg_Z_CMAKE_GET_VARS_USAGE)
        set(Z_KMPKG_CMAKE_GENERATOR "${generator}" CACHE INTERNAL "The generator which was used to configure CMake.")
    endif()
endfunction()
