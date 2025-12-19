set(KMPKG_POLICY_CMAKE_HELPER_PORT enabled)

configure_file("${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake" "${CURRENT_PACKAGES_DIR}/share/${PORT}/kmpkg-port-config.cmake" @ONLY)
file(INSTALL "${KMPKG_ROOT_DIR}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
