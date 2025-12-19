set(KMPKG_POLICY_CMAKE_HELPER_PORT enabled)

file(COPY
    "${CURRENT_PORT_DIR}/kmpkg-port-config.cmake"
    "${CURRENT_PORT_DIR}/x_kmpkg_pkgconfig_get_modules.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

kmpkg_install_copyright(FILE_LIST "${KMPKG_ROOT_DIR}/LICENSE.txt")
