kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO nmslib/hnswlib
    REF "v${VERSION}"
    SHA512 2bac86547374ef762083f33b5209c7c02c89b3270442dda2bc80fbc7b6a33766cb81248841deddc2ca1f7c49e3e19889955f45c91d0b601d1c883a5e1c930794
    HEAD_REF master
)

set(KMPKG_BUILD_TYPE "release") # header-only port

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DHNSWLIB_EXAMPLES=OFF
)

kmpkg_cmake_install()
kmpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/hnswlib)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
