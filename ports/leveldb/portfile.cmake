kmpkg_check_linkage(ONLY_STATIC_LIBRARY)

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/leveldb
    REF "${VERSION}"
    SHA512 ac15eac29387b9f702a901b6567d47a9f8c17cf5c7d8700a77ec771da25158c83b04959c33f3d4de7a3f033ef08f545d14ba823a8d527e21889c4b78065b0f84
    HEAD_REF master
    PATCHES
        fix-dependencies.patch
        fix-util-install.patch
)

file(COPY "${CURRENT_PORT_DIR}/leveldbConfig.cmake.in" DESTINATION "${SOURCE_PATH}/cmake")

kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        crc32c WITH_CRC32C
        snappy WITH_SNAPPY
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DLEVELDB_BUILD_TESTS=OFF
        -DLEVELDB_BUILD_BENCHMARKS=OFF
    OPTIONS_DEBUG
        -DINSTALL_HEADERS=OFF
)

kmpkg_cmake_install()

kmpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")


file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
