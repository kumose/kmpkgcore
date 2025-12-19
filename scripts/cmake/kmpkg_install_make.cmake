function(kmpkg_install_make)
    kmpkg_build_make(
        ${ARGN}
        ENABLE_INSTALL
    )
endfunction()
