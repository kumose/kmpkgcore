function(kmpkg_buildpath_length_warning warning_length)
    string(LENGTH "${CURRENT_BUILDTREES_DIR}" buildtrees_path_length)
    if(buildtrees_path_length GREATER warning_length AND CMAKE_HOST_WIN32)
            message(WARNING "${PORT}'s buildsystem uses very long paths and may fail on your system.\n"
                "We recommend moving kmpkg to a short path such as 'C:\\src\\kmpkg' or using the subst command."
            )
    endif()
endfunction()
