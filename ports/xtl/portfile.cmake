# header-only library

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO xtensor-stack/xtl
    REF "${VERSION}"
    SHA512 cb032d27b2f7dff135c442fd92e3924eb108355769354c9eee9ec2d3ec7ebd867ee89ee2e10f41352447e08f185637f338fdc40e37d60d85cf2fffdcaac1ce6c
    HEAD_REF master
    PATCHES
        fix-fixup-cmake.patch
)

set(KMPKG_BUILD_TYPE release)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTS=OFF
        -DDOWNLOAD_GTEST=OFF
)

kmpkg_cmake_install()

kmpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/xtl)
kmpkg_fixup_pkgconfig()

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
