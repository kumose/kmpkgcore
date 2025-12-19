kmpkg_check_linkage(ONLY_STATIC_LIBRARY)

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO kgabis/parson
    REF ba29f4eda9ea7703a9f6a9cf2b0532a2605723c3 # accessed on 2023-10-31
    SHA512 fdb8c66e9b8966488a22db2e6437d0bfa521c73abc043c7bd18227247fd52de9dd1856dec0d5ebd88f1dacce2493b2c68707b5e16ca4e3032ff6342933f16030
    HEAD_REF master
    PATCHES
        fix-cmake-files-path.patch
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

kmpkg_cmake_install()

kmpkg_cmake_config_fixup()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

kmpkg_copy_pdbs()
