kmpkg_check_linkage(ONLY_STATIC_LIBRARY)

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/flatbuffers
    REF "v${VERSION}"
    SHA512 259ae6c0b024c19c882d87c93d6ba156c15f14a61b11846170ac1b9e9c051cd3e80ae93cfe20ccb1aa30f2085cdbd4127ffa229b42cabbfed6b035ca4851c127
    HEAD_REF master
    PATCHES
        fix-uwp-build.patch
        fix-runtime-flags-msvc.patch
)

set(options "")
if(KMPKG_CROSSCOMPILING)
    list(APPEND options -DFLATBUFFERS_BUILD_FLATC=OFF -DFLATBUFFERS_BUILD_FLATHASH=OFF)
    if(KMPKG_TARGET_IS_OSX OR KMPKG_TARGET_IS_IOS)
        # The option may cause "#error Unsupported architecture"
        list(APPEND options -DFLATBUFFERS_OSX_BUILD_UNIVERSAL=OFF)
    endif()
endif()

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DFLATBUFFERS_BUILD_TESTS=OFF
        -DFLATBUFFERS_BUILD_GRPCTEST=OFF
        ${options}
    OPTIONS_DEBUG
        -DFLATBUFFERS_BUILD_FLATC=OFF
)

kmpkg_cmake_install()
kmpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/flatbuffers)
kmpkg_fixup_pkgconfig()

file(GLOB flatc_path ${CURRENT_PACKAGES_DIR}/bin/flatc*)
if(flatc_path)
    kmpkg_copy_tools(TOOL_NAMES flatc AUTO_CLEAN)
else()
    file(APPEND "${CURRENT_PACKAGES_DIR}/share/flatbuffers/flatbuffers-config.cmake"
"\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/../../../${HOST_TRIPLET}/share/flatbuffers/FlatcTargets.cmake\")\n")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/flatbuffers/pch")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
