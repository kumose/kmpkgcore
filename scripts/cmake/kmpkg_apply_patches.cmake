function(kmpkg_apply_patches)
    z_kmpkg_deprecation_message("kmpkg_apply_patches has been deprecated in favor of the `PATCHES` argument to `kmpkg_from_*`.")

    cmake_parse_arguments(PARSE_ARGV 0 "arg" "QUIET" "SOURCE_PATH" "PATCHES")

    if(arg_QUIET)
        set(quiet "QUIET")
    else()
        set(quiet)
    endif()

    z_kmpkg_apply_patches(
        SOURCE_PATH "${arg_SOURCE_PATH}"
        ${quiet}
        PATCHES ${arg_PATCHES}
    )
endfunction()
