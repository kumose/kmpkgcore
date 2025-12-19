kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO gabime/spdlog
    REF "v${VERSION}"
    SHA512 3c330162201fb405a08040327e08bc3f90336f431b8865d250e1cf171e48eb8a07a0245a8f60118022869de1ee38209b14da76bf6bcc2ec3da60f1853adaf958
    HEAD_REF v1.x
)

kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        benchmark SPDLOG_BUILD_BENCH
        fmt       SPDLOG_FMT_EXTERNAL
        wchar     SPDLOG_WCHAR_SUPPORT
    INVERTED_FEATURES
        fmt       SPDLOG_USE_STD_FORMAT
)

# SPDLOG_WCHAR_FILENAMES can only be configured in triplet file since it is an alternative (not additive)
if(NOT DEFINED SPDLOG_WCHAR_FILENAMES)
    set(SPDLOG_WCHAR_FILENAMES OFF)
endif()
if(NOT KMPKG_TARGET_IS_WINDOWS AND SPDLOG_WCHAR_FILENAMES)
    message(FATAL_ERROR "Build option 'SPDLOG_WCHAR_FILENAMES' is for Windows.")
endif()

string(COMPARE EQUAL "${KMPKG_LIBRARY_LINKAGE}" "dynamic" SPDLOG_BUILD_SHARED)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DSPDLOG_INSTALL=ON
        -DSPDLOG_BUILD_SHARED=${SPDLOG_BUILD_SHARED}
        -DSPDLOG_WCHAR_FILENAMES=${SPDLOG_WCHAR_FILENAMES}
        -DSPDLOG_BUILD_EXAMPLE=OFF
)

kmpkg_cmake_install()
kmpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/spdlog)
kmpkg_fixup_pkgconfig()
kmpkg_copy_pdbs()

if(NOT KMPKG_BUILD_TYPE)
    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/spdlog.pc" " -lspdlog" " -lspdlogd")
endif()

# add support for integration other than cmake
if(SPDLOG_FMT_EXTERNAL)
    kmpkg_replace_string(${CURRENT_PACKAGES_DIR}/include/spdlog/tweakme.h
        "// #define SPDLOG_FMT_EXTERNAL"
        "#ifndef SPDLOG_FMT_EXTERNAL\n#define SPDLOG_FMT_EXTERNAL\n#endif"
    )
endif()
if(SPDLOG_USE_STD_FORMAT)
    kmpkg_replace_string(${CURRENT_PACKAGES_DIR}/include/spdlog/tweakme.h
        "// #define SPDLOG_USE_STD_FORMAT"
	"#ifndef SPDLOG_USE_STD_FORMAT\n#define SPDLOG_USE_STD_FORMAT\n#endif"
    )
endif()
if(SPDLOG_WCHAR_SUPPORT)
    kmpkg_replace_string(${CURRENT_PACKAGES_DIR}/include/spdlog/tweakme.h
        "// #define SPDLOG_WCHAR_TO_UTF8_SUPPORT"
        "#ifndef SPDLOG_WCHAR_TO_UTF8_SUPPORT\n#define SPDLOG_WCHAR_TO_UTF8_SUPPORT\n#endif"
    )
endif()
if(SPDLOG_WCHAR_FILENAMES)
    kmpkg_replace_string(${CURRENT_PACKAGES_DIR}/include/spdlog/tweakme.h
        "// #define SPDLOG_WCHAR_FILENAMES"
        "#ifndef SPDLOG_WCHAR_FILENAMES\n#define SPDLOG_WCHAR_FILENAMES\n#endif"
    )
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/include/spdlog/fmt/bundled"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
