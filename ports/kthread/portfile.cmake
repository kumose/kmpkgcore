
kmpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO kumose/kthread
        REF "v${VERSION}"
        SHA512 5b899cdadf7d29ff5f86f996d07f404f14b3a715f92bcf4c015576f915e5562e84f02405ec2dc41ca8d2feb416b84d086ec0e0efc7eb8f691f7d847e1f548475
        HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DKMCMAKE_BUILD_TEST=OFF
)

kmpkg_cmake_install()
kmpkg_cmake_config_fixup(PACKAGE_NAME kthread CONFIG_PATH lib/cmake/kthread)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
kmpkg_copy_pdbs()

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

kmpkg_fixup_pkgconfig()
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
