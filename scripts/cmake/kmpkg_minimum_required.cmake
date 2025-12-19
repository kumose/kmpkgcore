function(kmpkg_minimum_required)
    cmake_parse_arguments(PARSE_ARGV 0 arg "" "VERSION" "")
    if(NOT DEFINED KMPKG_BASE_VERSION)
        message(FATAL_ERROR "Your kmpkg executable is outdated and is not compatible with the current CMake scripts.
    Please re-acquire kmpkg by running bootstrap-kmpkg."
        )
    endif()
    if(NOT DEFINED arg_VERSION)
        message(FATAL_ERROR "VERSION must be specified")
    endif()

    set(kmpkg_date_regex "^[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]$")
    if(NOT "${KMPKG_BASE_VERSION}" MATCHES "${kmpkg_date_regex}")
        message(FATAL_ERROR
            "kmpkg internal failure; KMPKG_BASE_VERSION (${KMPKG_BASE_VERSION}) was not a valid date."
        )
    endif()

    if(NOT "${arg_VERSION}" MATCHES "${kmpkg_date_regex}")
        message(FATAL_ERROR
            "VERSION (${arg_VERSION}) was not a valid date - expected something of the form 'YYYY-MM-DD'"
        )
    endif()

    string(REPLACE "-" "." KMPKG_BASE_VERSION_as_dotted "${KMPKG_BASE_VERSION}")
    string(REPLACE "-" "." arg_VERSION_as_dotted "${arg_VERSION}")

    if("${KMPKG_BASE_VERSION_as_dotted}" VERSION_LESS "${arg_VERSION_as_dotted}")
        message(FATAL_ERROR
            "Your kmpkg executable is from ${KMPKG_BASE_VERSION} which is older than required by the caller "
            "of kmpkg_minimum_required(VERSION ${arg_VERSION}). "
            "Please re-acquire kmpkg by running bootstrap-kmpkg."
        )
    endif()
endfunction()
