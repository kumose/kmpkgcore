if(EXISTS "${CURRENT_INSTALLED_DIR}/share/libressl/copyright"
    OR EXISTS "${CURRENT_INSTALLED_DIR}/share/boringssl/copyright")
    message(FATAL_ERROR "Can't build openssl if libressl/boringssl is installed. Please remove libressl/boringssl, and try install openssl again if you need it.")
endif()

if(KMPKG_TARGET_IS_EMSCRIPTEN)
    kmpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO openssl/openssl
    REF "openssl-${VERSION}"
    SHA512 3e1796708155454c118550ba0964b42c0c1055b651fec00cfb55038e8a8abbf5f85df02449e62b50b99d2a4a2f7b47862067f8a965e9c8a72f71dee0153672d9
    PATCHES
        cmake-config.patch
        command-line-length.patch
        script-prefix.patch
        aes_cfb128_vaes_encdec_wrapper.diff # https://github.com/openssl/openssl/issues/28745
        windows/install-layout.patch
        windows/install-pdbs.patch
        windows/install-programs.diff # https://github.com/openssl/openssl/issues/28744
        unix/android-cc.patch
        unix/move-openssldir.patch
        unix/no-empty-dirs.patch
        unix/no-static-libs-for-shared.patch
)

kmpkg_list(SET CONFIGURE_OPTIONS
    enable-static-engine
    enable-capieng
    no-tests
    no-docs
)

# https://github.com/openssl/openssl/blob/master/INSTALL.md#enable-ec_nistp_64_gcc_128
kmpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")
if(KMPKG_DETECTED_CMAKE_C_COMPILER_ID MATCHES "^(GNU|Clang|AppleClang)$"
   AND KMPKG_TARGET_ARCHITECTURE MATCHES "^(x64|arm64|riscv64|ppc64le)$")
    kmpkg_list(APPEND CONFIGURE_OPTIONS enable-ec_nistp_64_gcc_128)
endif()

set(INSTALL_FIPS "")
if("fips" IN_LIST FEATURES)
    kmpkg_list(APPEND INSTALL_FIPS install_fips)
    kmpkg_list(APPEND CONFIGURE_OPTIONS enable-fips)
endif()

if(KMPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    kmpkg_list(APPEND CONFIGURE_OPTIONS shared)
else()
    kmpkg_list(APPEND CONFIGURE_OPTIONS no-shared no-module)
endif()

if(NOT "tools" IN_LIST FEATURES)
    kmpkg_list(APPEND CONFIGURE_OPTIONS no-apps)
endif()

if("weak-ssl-ciphers" IN_LIST FEATURES)
    kmpkg_list(APPEND CONFIGURE_OPTIONS enable-weak-ssl-ciphers)
endif()

if("ssl3" IN_LIST FEATURES)
    kmpkg_list(APPEND CONFIGURE_OPTIONS enable-ssl3)
    kmpkg_list(APPEND CONFIGURE_OPTIONS enable-ssl3-method)
endif()

if(DEFINED OPENSSL_USE_NOPINSHARED)
    kmpkg_list(APPEND CONFIGURE_OPTIONS no-pinshared)
endif()

if(OPENSSL_NO_AUTOLOAD_CONFIG)
    kmpkg_list(APPEND CONFIGURE_OPTIONS no-autoload-config)
endif()

if(KMPKG_TARGET_IS_WINDOWS AND NOT KMPKG_TARGET_IS_MINGW)
    include("${CMAKE_CURRENT_LIST_DIR}/windows/portfile.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/install-pc-files.cmake")
else()
    include("${CMAKE_CURRENT_LIST_DIR}/unix/portfile.cmake")
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

if (NOT "${VERSION}" MATCHES [[^([0-9]+)\.([0-9]+)\.([0-9]+)$]])
    message(FATAL_ERROR "Version regex did not match.")
endif()
set(OPENSSL_VERSION_MAJOR "${CMAKE_MATCH_1}")
set(OPENSSL_VERSION_MINOR "${CMAKE_MATCH_2}")
set(OPENSSL_VERSION_FIX "${CMAKE_MATCH_3}")
configure_file("${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake.in" "${CURRENT_PACKAGES_DIR}/share/${PORT}/kmpkg-cmake-wrapper.cmake" @ONLY)

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
