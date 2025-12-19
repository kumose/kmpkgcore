function(kmpkg_install_cmake)
    if(Z_KMPKG_CMAKE_INSTALL_GUARD)
        message(FATAL_ERROR "The ${PORT} port already depends on kmpkg-cmake; using both kmpkg-cmake and kmpkg_install_cmake in the same port is unsupported.")
    endif()

    cmake_parse_arguments(PARSE_ARGV 0 "arg" "DISABLE_PARALLEL;ADD_BIN_TO_PATH" "" "")
    if(DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "kmpkg_cmake_install was passed extra arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()

    kmpkg_list(SET params)
    foreach(arg IN ITEMS DISABLE_PARALLEL ADD_BIN_TO_PATH)
        if(arg_${arg})
            kmpkg_list(APPEND params "${arg}")
        endif()
    endforeach()

    kmpkg_build_cmake(Z_KMPKG_DISABLE_DEPRECATION MESSAGE
        ${params}
        LOGFILE_ROOT install
        TARGET install
    )
endfunction()
