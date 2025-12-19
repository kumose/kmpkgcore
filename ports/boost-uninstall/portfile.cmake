set(KMPKG_POLICY_EMPTY_PACKAGE enabled)

message(STATUS "\nPlease use the following command when you need to remove all boost ports/components:\n\
    \"./kmpkg remove boost-uninstall:${TARGET_TRIPLET} --recurse\"\n")

configure_file("${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake" "${CURRENT_PACKAGES_DIR}/share/boost/kmpkg-cmake-wrapper.cmake" @ONLY)