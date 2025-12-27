if(NOT KMPKG_TARGET_IS_WINDOWS)
    kmpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

kmpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO kumose/merak
        REF v${VERSION}
        SHA512 16f258991c97daa4b4217609325d64010836f389315e835a4620adc8db865f23825bdb8a38be0d546b034508cf3be2b29085f3dc700094f3e2b21572dc188467
        HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DKMCMAKE_BUILD_TEST=OFF
)



kmpkg_cmake_install()
kmpkg_cmake_config_fixup(PACKAGE_NAME merak CONFIG_PATH lib/cmake/merak)

kmpkg_fixup_pkgconfig()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
kmpkg_copy_pdbs()

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
file(COPY "${CURRENT_PORT_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
