file(INSTALL
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg_msbuild.props.in"
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg_msbuild.targets.in"
    "${CMAKE_CURRENT_LIST_DIR}/z_kmpkg_msbuild_create_props.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg_msbuild_install.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(INSTALL "${KMPKG_ROOT_DIR}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
set(KMPKG_POLICY_CMAKE_HELPER_PORT enabled)
