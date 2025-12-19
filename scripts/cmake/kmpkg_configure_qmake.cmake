function(kmpkg_configure_qmake)
    # parse parameters such that semicolons in options arguments to COMMAND don't get erased
    cmake_parse_arguments(PARSE_ARGV 0 arg
        ""
        "SOURCE_PATH"
        "OPTIONS;OPTIONS_RELEASE;OPTIONS_DEBUG;BUILD_OPTIONS;BUILD_OPTIONS_RELEASE;BUILD_OPTIONS_DEBUG"
    )

    # Find qmake executable
    find_program(qmake_executable NAMES qmake PATHS "${CURRENT_HOST_INSTALLED_DIR}/tools/qt5/bin" NO_DEFAULT_PATH)

    if(NOT qmake_executable)
        message(FATAL_ERROR "kmpkg_configure_qmake: unable to find qmake.")
    endif()

    z_kmpkg_get_cmake_vars(cmake_vars_file)
    include("${cmake_vars_file}")

    function(qmake_append_program var qmake_var value)
        get_filename_component(prog "${value}" NAME)
        # QMake assumes everything is on PATH?
        kmpkg_list(APPEND ${var} "${qmake_var}=${prog}")
        find_program(${qmake_var} NAMES "${prog}")
        cmake_path(COMPARE "${${qmake_var}}" EQUAL "${value}" correct_prog_on_path)
        if(NOT correct_prog_on_path AND NOT "${value}" MATCHES "|:")
            message(FATAL_ERROR "Detect path mismatch for '${qmake_var}'. '${value}' is not the same as '${${qmake_var}}'. Please correct your PATH!")
        endif()
        unset(${qmake_var})
        unset(${qmake_var} CACHE)
        set(${var} "${${var}}" PARENT_SCOPE)
    endfunction()
    # Setup Build tools
    set(qmake_build_tools "")
    qmake_append_program(qmake_build_tools "QMAKE_CC" "${KMPKG_DETECTED_CMAKE_C_COMPILER}")
    qmake_append_program(qmake_build_tools "QMAKE_CXX" "${KMPKG_DETECTED_CMAKE_CXX_COMPILER}")
    qmake_append_program(qmake_build_tools "QMAKE_AR" "${KMPKG_DETECTED_CMAKE_AR}")
    qmake_append_program(qmake_build_tools "QMAKE_RANLIB" "${KMPKG_DETECTED_CMAKE_RANLIB}")
    qmake_append_program(qmake_build_tools "QMAKE_STRIP" "${KMPKG_DETECTED_CMAKE_STRIP}")
    qmake_append_program(qmake_build_tools "QMAKE_NM" "${KMPKG_DETECTED_CMAKE_NM}")
    qmake_append_program(qmake_build_tools "QMAKE_RC" "${KMPKG_DETECTED_CMAKE_RC_COMPILER}")
    qmake_append_program(qmake_build_tools "QMAKE_MT" "${KMPKG_DETECTED_CMAKE_MT}")
    if(NOT KMPKG_TARGET_IS_WINDOWS OR KMPKG_DETECTED_CMAKE_AR MATCHES "ar$")
        kmpkg_list(APPEND qmake_build_tools "QMAKE_AR+=qc")
    endif()
    if(KMPKG_TARGET_IS_WINDOWS AND NOT KMPKG_TARGET_IS_MINGW)
        qmake_append_program(qmake_build_tools "QMAKE_LIB" "${KMPKG_DETECTED_CMAKE_AR}")
        qmake_append_program(qmake_build_tools "QMAKE_LINK" "${KMPKG_DETECTED_CMAKE_LINKER}")
    else()
        qmake_append_program(qmake_build_tools "QMAKE_LINK" "${KMPKG_DETECTED_CMAKE_CXX_COMPILER}")
        qmake_append_program(qmake_build_tools "QMAKE_LINK_SHLIB" "${KMPKG_DETECTED_CMAKE_CXX_COMPILER}")
        qmake_append_program(qmake_build_tools "QMAKE_LINK_C" "${KMPKG_DETECTED_CMAKE_C_COMPILER}")
        qmake_append_program(qmake_build_tools "QMAKE_LINK_C_SHLIB" "${KMPKG_DETECTED_CMAKE_C_COMPILER}")
    endif()
    set(qmake_comp_flags "")
    macro(qmake_add_flags qmake_var operation flags)
        string(STRIP "${flags}" striped_flags)
        if(striped_flags)
            kmpkg_list(APPEND qmake_comp_flags "${qmake_var}${operation}${striped_flags}")
        endif()
    endmacro()

    if(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
        kmpkg_list(APPEND arg_OPTIONS "CONFIG-=shared" "CONFIG*=static")
    else()
        kmpkg_list(APPEND arg_OPTIONS "CONFIG-=static" "CONFIG*=shared")
    endif()
    kmpkg_list(APPEND arg_OPTIONS "CONFIG*=force_debug_info")

    if(KMPKG_TARGET_IS_WINDOWS AND KMPKG_CRT_LINKAGE STREQUAL "static")
        kmpkg_list(APPEND arg_OPTIONS "CONFIG*=static_runtime")
    endif()

    if(DEFINED KMPKG_OSX_DEPLOYMENT_TARGET)
        set(ENV{QMAKE_MACOSX_DEPLOYMENT_TARGET} "${KMPKG_OSX_DEPLOYMENT_TARGET}")
    endif()

    if(NOT DEFINED KMPKG_BUILD_TYPE OR KMPKG_BUILD_TYPE STREQUAL "release")
        z_kmpkg_setup_pkgconfig_path(CONFIG RELEASE)

        set(current_binary_dir "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")

        # Cleanup build directories
        file(REMOVE_RECURSE "${current_binary_dir}")

        configure_file("${CURRENT_INSTALLED_DIR}/tools/qt5/qt_release.conf" "${current_binary_dir}/qt.conf")
    
        message(STATUS "Configuring ${TARGET_TRIPLET}-rel")
        file(MAKE_DIRECTORY "${current_binary_dir}")

        qmake_add_flags("QMAKE_LIBS" "+=" "${KMPKG_DETECTED_CMAKE_C_STANDARD_LIBRARIES} ${KMPKG_DETECTED_CMAKE_CXX_STANDARD_LIBRARIES}")
        qmake_add_flags("QMAKE_RC" "+=" "${KMPKG_DETECTED_CMAKE_RC_FLAGS_RELEASE}")
        qmake_add_flags("QMAKE_CFLAGS_RELEASE" "+=" "${KMPKG_DETECTED_CMAKE_C_FLAGS_RELEASE}")
        qmake_add_flags("QMAKE_CXXFLAGS_RELEASE" "+=" "${KMPKG_DETECTED_CMAKE_CXX_FLAGS_RELEASE}")
        qmake_add_flags("QMAKE_LFLAGS" "+=" "${KMPKG_DETECTED_CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
        qmake_add_flags("QMAKE_LFLAGS_SHLIB" "+=" "${KMPKG_DETECTED_CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
        qmake_add_flags("QMAKE_LFLAGS_PLUGIN" "+=" "${KMPKG_DETECTED_CMAKE_MODULE_LINKER_FLAGS_RELEASE}")
        qmake_add_flags("QMAKE_LIBFLAGS_RELEASE" "+=" "${KMPKG_DETECTED_CMAKE_STATIC_LINKER_FLAGS_RELEASE}")

        kmpkg_list(SET build_opt_param)
        if(DEFINED arg_BUILD_OPTIONS OR DEFINED arg_BUILD_OPTIONS_RELEASE)
            kmpkg_list(SET build_opt_param -- ${arg_BUILD_OPTIONS} ${arg_BUILD_OPTIONS_RELEASE})
        endif()

        kmpkg_execute_required_process(
            COMMAND "${qmake_executable}" CONFIG-=debug CONFIG+=release ${qmake_build_tools} ${qmake_comp_flags}
                    ${arg_OPTIONS} ${arg_OPTIONS_RELEASE} ${arg_SOURCE_PATH}
                    -qtconf "${current_binary_dir}/qt.conf"
                    ${build_opt_param}
            WORKING_DIRECTORY "${current_binary_dir}"
            LOGNAME "config-${TARGET_TRIPLET}-rel"
            SAVE_LOG_FILES config.log
        )
        message(STATUS "Configuring ${TARGET_TRIPLET}-rel done")
        if(EXISTS "${current_binary_dir}/config.log")
            file(REMOVE "${CURRENT_BUILDTREES_DIR}/internal-config-${TARGET_TRIPLET}-rel.log")
            file(RENAME "${current_binary_dir}/config.log" "${CURRENT_BUILDTREES_DIR}/internal-config-${TARGET_TRIPLET}-rel.log")
        endif()

        z_kmpkg_restore_pkgconfig_path()
    endif()

    if(NOT DEFINED KMPKG_BUILD_TYPE OR KMPKG_BUILD_TYPE STREQUAL "debug")
        z_kmpkg_setup_pkgconfig_path(CONFIG DEBUG)

        set(current_binary_dir "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg")

        # Cleanup build directories
        file(REMOVE_RECURSE "${current_binary_dir}")

        configure_file("${CURRENT_INSTALLED_DIR}/tools/qt5/qt_debug.conf" "${current_binary_dir}/qt.conf")

        message(STATUS "Configuring ${TARGET_TRIPLET}-dbg")
        file(MAKE_DIRECTORY "${current_binary_dir}")

        set(qmake_comp_flags "")
        qmake_add_flags("QMAKE_LIBS" "+=" "${KMPKG_DETECTED_CMAKE_C_STANDARD_LIBRARIES} ${KMPKG_DETECTED_CMAKE_CXX_STANDARD_LIBRARIES}")
        qmake_add_flags("QMAKE_RC" "+=" "${KMPKG_DETECTED_CMAKE_RC_FLAGS_DEBUG}")
        qmake_add_flags("QMAKE_CFLAGS_DEBUG" "+=" "${KMPKG_DETECTED_CMAKE_C_FLAGS_DEBUG}")
        qmake_add_flags("QMAKE_CXXFLAGS_DEBUG" "+=" "${KMPKG_DETECTED_CMAKE_CXX_FLAGS_DEBUG}")
        qmake_add_flags("QMAKE_LFLAGS" "+=" "${KMPKG_DETECTED_CMAKE_SHARED_LINKER_FLAGS_DEBUG}")
        qmake_add_flags("QMAKE_LFLAGS_SHLIB" "+=" "${KMPKG_DETECTED_CMAKE_SHARED_LINKER_FLAGS_DEBUG}")
        qmake_add_flags("QMAKE_LFLAGS_PLUGIN" "+=" "${KMPKG_DETECTED_CMAKE_MODULE_LINKER_FLAGS_DEBUG}")
        qmake_add_flags("QMAKE_LIBFLAGS_DEBUG" "+=" "${KMPKG_DETECTED_CMAKE_STATIC_LINKER_FLAGS_DEBUG}")

        kmpkg_list(SET build_opt_param)
        if(DEFINED arg_BUILD_OPTIONS OR DEFINED arg_BUILD_OPTIONS_DEBUG)
            kmpkg_list(SET build_opt_param -- ${arg_BUILD_OPTIONS} ${arg_BUILD_OPTIONS_DEBUG})
        endif()
        kmpkg_execute_required_process(
            COMMAND "${qmake_executable}" CONFIG-=release CONFIG+=debug ${qmake_build_tools} ${qmake_comp_flags}
                    ${arg_OPTIONS} ${arg_OPTIONS_DEBUG} ${arg_SOURCE_PATH}
                    -qtconf "${current_binary_dir}/qt.conf"
                    ${build_opt_param}
            WORKING_DIRECTORY "${current_binary_dir}"
            LOGNAME "config-${TARGET_TRIPLET}-dbg"
            SAVE_LOG_FILES config.log
        )
        message(STATUS "Configuring ${TARGET_TRIPLET}-dbg done")
        if(EXISTS "${current_binary_dir}/config.log")
            file(REMOVE "${CURRENT_BUILDTREES_DIR}/internal-config-${TARGET_TRIPLET}-dbg.log")
            file(RENAME "${current_binary_dir}/config.log" "${CURRENT_BUILDTREES_DIR}/internal-config-${TARGET_TRIPLET}-dbg.log")
        endif()
        
        z_kmpkg_restore_pkgconfig_path()
    endif()

endfunction()
