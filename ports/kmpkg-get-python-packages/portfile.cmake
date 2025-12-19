file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/copyright"
    "${CMAKE_CURRENT_LIST_DIR}/x_kmpkg_get_python_packages.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

include("${CMAKE_CURRENT_LIST_DIR}/x_kmpkg_get_python_packages.cmake")

set(KMPKG_POLICY_EMPTY_PACKAGE enabled)
