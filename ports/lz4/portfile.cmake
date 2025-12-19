kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lz4/lz4
    REF v${VERSION}
    SHA512 8c4ceb217e6dc8e7e0beba99adc736aca8963867bcf9f970d621978ba11ce92855912f8b66138037a1d2ae171e8e17beb7be99281fea840106aa60373c455b28
    HEAD_REF dev
    PATCHES
        target-lz4-lz4.diff
)

kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tools LZ4_BUILD_CLI
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/build/cmake"
    OPTIONS
        ${FEATURE_OPTIONS}
    OPTIONS_DEBUG
        -DCMAKE_DEBUG_POSTFIX=d
)

kmpkg_cmake_install()
kmpkg_copy_pdbs()

if("tools" IN_LIST FEATURES)
    kmpkg_copy_tools(
        TOOL_NAMES lz4
        AUTO_CLEAN
    )
endif()

if(KMPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    set(DLL_IMPORT "1 && defined(_MSC_VER)")
else()
    set(DLL_IMPORT "0")
endif()
foreach(FILE lz4.h lz4frame.h)
    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/${FILE}"
        "defined(LZ4_DLL_IMPORT) && (LZ4_DLL_IMPORT==1)"
        "${DLL_IMPORT}"
    )
endforeach()

kmpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/lz4")

kmpkg_fixup_pkgconfig()
if(NOT DEFINED KMPKG_BUILD_TYPE OR KMPKG_BUILD_TYPE STREQUAL "debug")
    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/liblz4.pc" " -llz4" " -llz4d")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

set(LICENSE_FILES "${SOURCE_PATH}/lib/LICENSE")
if("tools" IN_LIST FEATURES)
    list(APPEND LICENSE_FILES "${SOURCE_PATH}/programs/COPYING")
endif()
kmpkg_install_copyright(FILE_LIST ${LICENSE_FILES})
