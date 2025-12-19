if(NOT KMPKG_TARGET_IS_WINDOWS)
    kmpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

kmpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO kumose/turbo
        REF v${VERSION}
        SHA512 2b850cd5d4cb7b35359002ea0e6bbead7f2cb79a797b0f7f22306bdbe19fa8967d532625611c79d2523feb3e055505d049689ef980c2293626dab4545b4f5d60
        HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DCARBIN_BUILD_TEST=OFF
)



kmpkg_cmake_install()
kmpkg_cmake_config_fixup(PACKAGE_NAME turbo CONFIG_PATH lib/cmake/turbo)
kmpkg_fixup_pkgconfig()

kmpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
