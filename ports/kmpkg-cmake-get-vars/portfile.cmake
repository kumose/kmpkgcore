if(KMPKG_CROSSCOMPILING)
    # make FATAL_ERROR in CI when issue #16773 fixed
    message(WARNING "kmpkg-cmake-get-vars is a host-only port; please mark it as a host port in your dependencies.")
endif()

file(INSTALL
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg_cmake_get_vars.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/cmake_get_vars"
    "${CMAKE_CURRENT_LIST_DIR}/cmake-get-vars.cmake.in"
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(INSTALL "${KMPKG_ROOT_DIR}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
set(KMPKG_POLICY_CMAKE_HELPER_PORT enabled)

