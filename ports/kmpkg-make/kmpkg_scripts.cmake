include_guard(GLOBAL)
function(kmpkg_insert_into_path)
    cmake_parse_arguments(PARSE_ARGV 0 arg
        "" 
        "PATH_OUT;APPENDED_OUT"
        "BEFORE;INSERT"
    )
    z_kmpkg_unparsed_args(FATAL_ERROR)
    cmake_path(CONVERT "$ENV{PATH}" TO_CMAKE_PATH_LIST path_list NORMALIZE)

    string(TOUPPER "${arg_BEFORE}" before_upper)

    set(index 0)
    set(appending TRUE)
    foreach(item IN LISTS path_list)
        string(TOUPPER "${item}" item_upper)
        if(item IN_LIST arg_BEFORE OR item_upper IN_LIST before_upper)
            set(appending FALSE)
            break()
        endif()
        math(EXPR index "${index} + 1")
    endforeach()

    kmpkg_list(INSERT path_list "${index}" ${arg_INSERT})

    cmake_path(CONVERT "${path_list}" TO_NATIVE_PATH_LIST native_path_list)
    set(ENV{PATH} "${native_path_list}")
    if(DEFINED arg_PATH_OUT)
        set("${arg_PATH_OUT}" "${path_list}" PARENT_SCOPE)
    endif()
    if(appending)
        set("${arg_APPENDED_OUT}" "TRUE" PARENT_SCOPE)
    else()
        set("${arg_APPENDED_OUT}" "FALSE" PARENT_SCOPE)
    endif()
endfunction()

function(kmpkg_insert_program_into_path prog)
    set(filepath "${prog}")
    cmake_path(GET filepath FILENAME ${prog})
    find_program(z_vcm_prog_found NAMES "${${prog}}" PATHS ENV PATH NO_DEFAULT_PATH NO_CACHE)
    if(NOT z_vcm_prog_found STREQUAL filepath)
        cmake_path(GET z_vcm_prog_found PARENT_PATH before_dir)
        cmake_path(GET filepath PARENT_PATH dir)
        kmpkg_insert_into_path(
            INSERT "${dir}"
            BEFORE "${before_dir}"
        )
    endif()
endfunction()

function(kmpkg_insert_msys_into_path msys_out)
    cmake_parse_arguments(PARSE_ARGV 1 arg
        "" 
        "PATH_OUT"
        "PACKAGES"
    )
    z_kmpkg_unparsed_args(FATAL_ERROR)
    kmpkg_acquire_msys(MSYS_ROOT PACKAGES ${arg_PACKAGES})
    cmake_path(CONVERT "$ENV{SystemRoot}" TO_CMAKE_PATH_LIST system_root NORMALIZE)
    cmake_path(CONVERT "$ENV{LOCALAPPDATA}" TO_CMAKE_PATH_LIST local_app_data NORMALIZE)
    file(REAL_PATH "${system_root}" system_root)

    kmpkg_list(SET find_system_dirs 
        "${system_root}/system32"
        "${system_root}/System32"
        "${system_root}/system32/"
        "${system_root}/System32/"
        "${local_app_data}/Microsoft/WindowsApps"
        "${local_app_data}/Microsoft/WindowsApps/"
    )

    kmpkg_insert_into_path(
        INSERT "${MSYS_ROOT}/usr/bin"
        BEFORE ${find_system_dirs}
        PATH_OUT path_out
        APPENDED_OUT appending
    )

    if(appending)
        message(WARNING "Unable to find system dir in the PATH variable! Appending required msys paths!")
    endif()

    if(DEFINED arg_PATH_OUT)
        set("${arg_PATH_OUT}" "${path_out}" PARENT_SCOPE)
    endif()

    set("${msys_out}" "${MSYS_ROOT}" PARENT_SCOPE)
endfunction()

### Helper macros for argument checking
macro(z_kmpkg_unparsed_args warning_level)
    if(DEFINED arg_UNPARSED_ARGUMENTS)
        message("${warning_level}" "${CMAKE_CURRENT_FUNCTION} was passed extra arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()
endmacro()

macro(z_kmpkg_conflicting_args)
    set(conflicting_args_set "")
    foreach(z_kmpkg_conflicting_args_index RANGE 0 "${ARGC}")
        if(${ARGV${z_kmpkg_conflicting_args_index}})
            list(APPEND conflicting_args_set "${ARGV${z_kmpkg_conflicting_args_index}}")
        endif()
    endforeach()
    list(LENGTH conflicting_args_set conflicting_args_set_length)
    if(conflicting_args_set_length GREATER 1)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} was passed conflicting arguments:'${conflicting_args_set}'. Only one of those arguments can be passed")
    endif()
    unset(conflicting_args_set_length)
    unset(conflicting_args_set)
    unset(z_kmpkg_conflicting_args_index)
endmacro()

macro(z_kmpkg_required_args arg)
    foreach(arg IN ITEMS ${ARGN})
        if(NOT DEFINED arg_${arg})
            message("FATAL_ERROR" "${CMAKE_CURRENT_FUNCTION} requires argument: ${arg}")
        endif()
    endforeach()
endmacro()

function(z_kmpkg_set_global_property property value)
    if(NOT ARGN STREQUAL "" AND NOT ARGN MATCHES "^APPEND(_STRING)?$")
        message(FATAL_ERROR "'${CMAKE_CURRENT_FUNCTION}' called with invalid arguments '${ARGN}'")
    endif()
    set_property(GLOBAL ${ARGN} PROPERTY "z_kmpkg_global_property_${property}" "${value}")
endfunction()

function(z_kmpkg_get_global_property outvar property)
    if(NOT ARGN STREQUAL "" AND NOT ARGN STREQUAL "SET")
        message(FATAL_ERROR "'${CMAKE_CURRENT_FUNCTION}' called with invalid arguments '${ARGN}'")
    endif()
    get_property(outprop GLOBAL PROPERTY "z_kmpkg_global_property_${property}" ${ARGN})
    set(${outvar} "${outprop}" PARENT_SCOPE)
endfunction()

function(kmpkg_prepare_pkgconfig config)
    set(subdir "")
    if(config MATCHES "(DEBUG|debug)")
        set(subdir "/debug")
    endif()

    z_kmpkg_get_global_property(has_backup "make-pkg-config-backup-${envvar}" SET)
    if(has_backup)
        message(FATAL_ERROR "'${CMAKE_CURRENT_FUNCTION}' does not (yet) support recursive backups. Need to restore previous state first!")
    endif()

    foreach(envvar IN ITEMS PKG_CONFIG PKG_CONFIG_PATH)
        if(DEFINED ENV{${envvar}})
            z_kmpkg_set_global_property("make-pkg-config-backup-${envvar}" "$ENV{${envvar}}")
        else()
            z_kmpkg_set_global_property("make-pkg-config-backup-${envvar}" "")
        endif()
    endforeach()

    kmpkg_find_acquire_program(PKGCONFIG)
    set(ENV{PKG_CONFIG} "${PKGCONFIG}")

    kmpkg_host_path_list(PREPEND ENV{PKG_CONFIG_PATH} 
                            # After installation, (merged) 'lib' is always searched before 'share'.
                            "${CURRENT_PACKAGES_DIR}${subdir}/lib/pkgconfig"
                            "${CURRENT_INSTALLED_DIR}${subdir}/lib/pkgconfig"
                            "${CURRENT_PACKAGES_DIR}/share/pkgconfig"
                            "${CURRENT_INSTALLED_DIR}/share/pkgconfig"
                        )
endfunction()

function(kmpkg_restore_pkgconfig)
    foreach(envvar IN ITEMS PKG_CONFIG PKG_CONFIG_PATH)
        z_kmpkg_get_global_property(has_backup "make-pkg-config-backup-${envvar}" SET)
        if(has_backup)
            z_kmpkg_get_global_property(backup "make-pkg-config-backup-${envvar}")
            set("ENV{${envvar}}" "${backup}")
            z_kmpkg_set_global_property("make-pkg-config-backup-${envvar}" "")
        else()
            unset("ENV{${envvar}}")
        endif()
    endforeach()
endfunction()

function(z_kmpkg_escape_spaces_in_path outvar invar)
    string(REPLACE " " "\\ " current_installed_dir_escaped "${invar}")
    set("${outvar}" "${current_installed_dir_escaped}" PARENT_SCOPE)
endfunction()

function(z_kmpkg_warn_path_with_spaces)
    kmpkg_list(SET z_vcm_paths_with_spaces)
    if(CURRENT_BUILDTREES_DIR MATCHES " ")
        kmpkg_list(APPEND z_vcm_paths_with_spaces "${CURRENT_BUILDTREES_DIR}")
    endif()
    if(CURRENT_PACKAGES_DIR MATCHES " ")
        kmpkg_list(APPEND z_vcm_paths_with_spaces "${CURRENT_PACKAGES_DIR}")
    endif()
    if(CURRENT_INSTALLED_DIR MATCHES " ")
        kmpkg_list(APPEND z_vcm_paths_with_spaces "${CURRENT_INSTALLED_DIR}")
    endif()
    if(z_vcm_paths_with_spaces)
        # Don't bother with whitespace. The tools will probably fail and I tried very hard trying to make it work (no success so far)!
        kmpkg_list(APPEND z_vcm_paths_with_spaces "Please move the path to one without whitespaces!")
        list(JOIN z_vcm_paths_with_spaces "\n   " z_vcm_paths_with_spaces)
        message(STATUS "Warning: Paths with embedded space may be handled incorrectly by configure:\n   ${z_vcm_paths_with_spaces}")
    endif()
endfunction()
