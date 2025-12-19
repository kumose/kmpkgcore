function(kmpkg_clean_msbuild)
    if(NOT ARGC EQUAL 0)
        message(WARNING "kmpkg_clean_msbuild was passed extra arguments: ${ARGV}")
    endif()
    file(REMOVE_RECURSE
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg"
        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel"
    )
endfunction()
