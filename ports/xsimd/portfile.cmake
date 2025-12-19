kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO xtensor-stack/xsimd
    REF "${VERSION}"
    SHA512 f1d9bc50482a52a7b1891637c4e054eeafed0503b938ef07050fea8354e215b9483bafb17485b22fca8d715ddd7c79f03af352116487558d610d4e03d7dbcf4e
    HEAD_REF master
)

kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        xcomplex ENABLE_XTL_COMPLEX
)

set(KMPKG_BUILD_TYPE release) # header-only port

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTS=OFF
        ${FEATURE_OPTIONS}
)

kmpkg_cmake_install()

kmpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/${PORT})
kmpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
