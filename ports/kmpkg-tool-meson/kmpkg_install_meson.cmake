function(kmpkg_install_meson)
    cmake_parse_arguments(PARSE_ARGV 0 arg "ADD_BIN_TO_PATH" "" "")

    kmpkg_find_acquire_program(NINJA)
    unset(ENV{DESTDIR}) # installation directory was already specified with '--prefix' option

    if(KMPKG_TARGET_IS_OSX)
        kmpkg_backup_env_variables(VARS SDKROOT MACOSX_DEPLOYMENT_TARGET)
        set(ENV{SDKROOT} "${KMPKG_DETECTED_CMAKE_OSX_SYSROOT}")
        set(ENV{MACOSX_DEPLOYMENT_TARGET} "${KMPKG_DETECTED_CMAKE_OSX_DEPLOYMENT_TARGET}")
    endif()

    foreach(buildtype IN ITEMS "debug" "release")
        if(DEFINED KMPKG_BUILD_TYPE AND NOT KMPKG_BUILD_TYPE STREQUAL buildtype)
            continue()
        endif()

        if(buildtype STREQUAL "debug")
            set(short_buildtype "dbg")
        else()
            set(short_buildtype "rel")
        endif()

        message(STATUS "Package ${TARGET_TRIPLET}-${short_buildtype}")
        if(arg_ADD_BIN_TO_PATH)
            kmpkg_backup_env_variables(VARS PATH)
            if(buildtype STREQUAL "debug")
                kmpkg_add_to_path(PREPEND "${CURRENT_INSTALLED_DIR}/debug/bin")
            else()
                kmpkg_add_to_path(PREPEND "${CURRENT_INSTALLED_DIR}/bin")
            endif()
        endif()
        kmpkg_execute_required_process(
            COMMAND "${NINJA}" install -v
            WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${short_buildtype}"
            LOGNAME package-${TARGET_TRIPLET}-${short_buildtype}
        )
        if(arg_ADD_BIN_TO_PATH)
            kmpkg_restore_env_variables(VARS PATH)
        endif()
    endforeach()

    kmpkg_list(SET renamed_libs)
    if(KMPKG_TARGET_IS_WINDOWS AND KMPKG_LIBRARY_LINKAGE STREQUAL static AND NOT KMPKG_TARGET_IS_MINGW)
        # Meson names all static libraries lib<name>.a which basically breaks the world
        file(GLOB_RECURSE gen_libraries "${CURRENT_PACKAGES_DIR}*/**/lib*.a")
        foreach(gen_library IN LISTS gen_libraries)
            get_filename_component(libdir "${gen_library}" DIRECTORY)
            get_filename_component(libname "${gen_library}" NAME)
            string(REGEX REPLACE ".a$" ".lib" fixed_librawname "${libname}")
            string(REGEX REPLACE "^lib" "" fixed_librawname "${fixed_librawname}")
            file(RENAME "${gen_library}" "${libdir}/${fixed_librawname}")
            # For cmake fixes.
            string(REGEX REPLACE ".a$" "" origin_librawname "${libname}")
            string(REGEX REPLACE ".lib$" "" fixed_librawname "${fixed_librawname}")
            kmpkg_list(APPEND renamed_libs ${fixed_librawname})
            set(${librawname}_old ${origin_librawname})
            set(${librawname}_new ${fixed_librawname})
        endforeach()
        file(GLOB_RECURSE cmake_files "${CURRENT_PACKAGES_DIR}*/*.cmake")
        foreach(cmake_file IN LISTS cmake_files)
            foreach(current_lib IN LISTS renamed_libs)
                kmpkg_replace_string("${cmake_file}" "${${current_lib}_old}" "${${current_lib}_new}" IGNORE_UNCHANGED)
            endforeach()
        endforeach()
    endif()

    if(KMPKG_TARGET_IS_OSX)
        kmpkg_restore_env_variables(VARS SDKROOT MACOSX_DEPLOYMENT_TARGET)
    endif()
endfunction()
