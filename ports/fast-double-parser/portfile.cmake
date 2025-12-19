set(KMPKG_BUILD_TYPE release) # header-only

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lemire/fast_double_parser
    REF "v${VERSION}"
    SHA512 143f5d920159c5fc6d516417d14f297f7ba79764bab794ed6337dff73add7adcf99f27c078cd0e83a2907c5ec1143a247d85fc229eedcaf74d7710bab0adbd76
    HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
)

kmpkg_cmake_install()

kmpkg_cmake_config_fixup(PACKAGE_NAME fast_double_parser)

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
