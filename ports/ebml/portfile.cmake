kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Matroska-Org/libebml
    REF "release-${VERSION}"
    SHA512 284da9b7a1415585bbcfffc87101c63f1dd242bb09d88a731597127732a2f8064fd35e0a718fdcde464714b71e3f7dcc8285f291889629aba6997c38e0575dfb
    HEAD_REF master
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

kmpkg_cmake_install()

kmpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/EBML)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

# Handle copyright
file(INSTALL "${SOURCE_PATH}/LICENSE.LGPL" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

kmpkg_copy_pdbs()
kmpkg_fixup_pkgconfig()
