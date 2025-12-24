kmpkg_check_linkage(ONLY_STATIC_LIBRARY)

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO kumose/ftxui
    REF "v${VERSION}"
    SHA512 466c174ce2b626aea540ae1021690c6cc4ae289438b0569b108b8300c9f1be9f31a7f5a0d955df1fe1bf8361b62f14fca1b9b69053480eeb757d36d0ab08382f
    HEAD_REF main
)

kmpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DFTXUI_BUILD_EXAMPLES=OFF
        -DFTXUI_ENABLE_INSTALL=ON
        -DFTXUI_BUILD_TESTS=OFF
        -DFTXUI_BUILD_DOCS=OFF
)

kmpkg_cmake_install()

kmpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/${PORT})

kmpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" "${CURRENT_PACKAGES_DIR}/debug/share")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
