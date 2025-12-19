set(KMPKG_POLICY_EMPTY_PACKAGE enabled)

if(NOT TARGET_TRIPLET STREQUAL _HOST_TRIPLET)
    message(FATAL_ERROR "kmpkg-gn is a host-only port; please mark it as a host port in your dependencies.")
endif()

file(INSTALL
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg_gn_configure.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg_gn_install.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
