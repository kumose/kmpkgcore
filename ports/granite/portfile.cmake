
kmpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO kumose/granite
        REF "v${VERSION}"
        SHA512 ad17ca8af4126e1f426d613a209e1287b7f8069c4338455ca9eb7286bf5760a83963adecdb41cdcd81714866817a13ed865042a297d66ae40949d4f65016d962
        HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DKMCMAKE_BUILD_TEST=OFF
)

kmpkg_cmake_install()
kmpkg_cmake_config_fixup(PACKAGE_NAME granite CONFIG_PATH lib/cmake/granite)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
kmpkg_copy_pdbs()

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

kmpkg_fixup_pkgconfig()
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
