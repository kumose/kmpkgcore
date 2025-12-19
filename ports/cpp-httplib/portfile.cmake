kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO yhirose/cpp-httplib
    REF "v${VERSION}"
    SHA512 e7a8877d489c97669a8ee536e1498575be921e558ed947253013fe6b67a49d4569eedd01f543caa70183b92d8ac0e8687d662a70d880954412e387317008a239
    HEAD_REF master
    PATCHES
        fix-find-brotli.patch
)

kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        brotli  HTTPLIB_REQUIRE_BROTLI
        openssl HTTPLIB_REQUIRE_OPENSSL
        zlib    HTTPLIB_REQUIRE_ZLIB
        zstd    HTTPLIB_REQUIRE_ZSTD
)

set(KMPKG_BUILD_TYPE release) # header-only port

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
    ${FEATURE_OPTIONS}
    -DHTTPLIB_USE_OPENSSL_IF_AVAILABLE=OFF
    -DHTTPLIB_USE_ZLIB_IF_AVAILABLE=OFF
    -DHTTPLIB_USE_BROTLI_IF_AVAILABLE=OFF
    -DHTTPLIB_USE_ZSTD_IF_AVAILABLE=OFF
)

kmpkg_cmake_install()
kmpkg_cmake_config_fixup(PACKAGE_NAME httplib CONFIG_PATH lib/cmake/httplib)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
