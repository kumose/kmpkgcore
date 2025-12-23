kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO duckdb/duckdb
    REF "v${VERSION}"
    SHA512 058218e4551867dc231cae682e835fb76b2d02b655f889753fde6745b9895b81a7161c7eb3104c9f9e8a7a33fed460fc0028d0b94a1e36834100aa597b97a877
    HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_UNITTESTS=OFF
        -DENABLE_SANITIZER=OFF
        -DENABLE_UBSAN=OFF
)

kmpkg_cmake_install()

kmpkg_copy_pdbs()
kmpkg_cmake_config_fixup(PACKAGE_NAME duckdb CONFIG_PATH lib/cmake/DuckDB)
kmpkg_fixup_pkgconfig()

kmpkg_copy_tools(TOOL_NAMES duckdb AUTO_CLEAN)


file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
