if(NOT KMPKG_TARGET_IS_WINDOWS)
    kmpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

kmpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO kumose/vamos
        REF v${VERSION}
        SHA512 08774a02304a2ea57da23c6b73ec4f741704cef516e888ef7e401933c4c7556b65f19bca9315b1f70d44b97dc2e9d429a517106b6a9fa2a911dfcec15cebba32
        HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DCARBIN_BUILD_TEST=OFF
)



kmpkg_cmake_install()
kmpkg_cmake_config_fixup(PACKAGE_NAME vamos CONFIG_PATH lib/cmake/vamos)
kmpkg_fixup_pkgconfig()

kmpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
