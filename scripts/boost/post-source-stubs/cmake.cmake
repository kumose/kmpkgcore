# Beta builds contains a text in the version string
string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.([0-9]+)" SEMVER_VERSION "${VERSION}")
configure_file("${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt.in" "${SOURCE_PATH}/CMakeLists.txt" @ONLY)

kmpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
kmpkg_cmake_install()

file(INSTALL "${SOURCE_PATH}/include/" DESTINATION "${CURRENT_PACKAGES_DIR}/share/boost/cmake-build")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

kmpkg_download_distfile(BOOST_LICENSE
    URLS "https://raw.githubusercontent.com/boostorg/boost/refs/tags/boost-${VERSION}/LICENSE_1_0.txt"
    FILENAME "boost-${VERSION}-LICENSE_1_0.txt"
    SHA512 d6078467835dba8932314c1c1e945569a64b065474d7aced27c9a7acc391d52e9f234138ed9f1aa9cd576f25f12f557e0b733c14891d42c16ecdc4a7bd4d60b8
)
kmpkg_install_copyright(FILE_LIST "${BOOST_LICENSE}")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
