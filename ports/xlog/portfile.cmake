if(NOT KMPKG_TARGET_IS_WINDOWS)
    kmpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

kmpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO kumose/xlog
        REF v${VERSION}
        SHA512 997605d3671bfa4323631c5c9dcc519599d9c016da5194bb6c1ac8db1c666f13b37b20839bb02b900175c5be48888db7baf98706f9ad443ffaabfb1f44bc5921
        HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DKMCMAKE_BUILD_TEST=OFF
)



kmpkg_cmake_install()
kmpkg_cmake_config_fixup(PACKAGE_NAME xlog CONFIG_PATH lib/cmake/xlog)
kmpkg_fixup_pkgconfig()

kmpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
