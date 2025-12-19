if(NOT KMPKG_TARGET_IS_WINDOWS)
    kmpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

kmpkg_from_gitee(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO kumose/collie
        REF v${VERSION}
        SHA512 66403e950acc84474e76049b2d337d36b2fbe6f75cb3f813c928658d6f5a1ef89185f473881e3708c58b35422702fc29614c6b419ae4a6031e68f005aa0e5638
        HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DKMCMAKE_BUILD_TEST=OFF
)



kmpkg_cmake_install()
kmpkg_cmake_config_fixup(PACKAGE_NAME collie CONFIG_PATH lib/cmake/collie)
kmpkg_fixup_pkgconfig()

kmpkg_copy_pdbs()

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
