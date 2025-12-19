file(INSTALL
    "${CMAKE_CURRENT_LIST_DIR}/usage.in"
    "${CMAKE_CURRENT_LIST_DIR}/boost-install.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

kmpkg_install_copyright(FILE_LIST "${KMPKG_ROOT_DIR}/LICENSE.txt")
set(KMPKG_POLICY_CMAKE_HELPER_PORT enabled)
