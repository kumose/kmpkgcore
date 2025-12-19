# We currently insist on static only because:
# - Thrift doesn't yet support building as a DLL on Windows,
# - x64-linux only builds static anyway.
# From https://github.com/apache/thrift/blob/master/CHANGES.md
if(KMPKG_TARGET_IS_WINDOWS)
    kmpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

kmpkg_find_acquire_program(FLEX)
kmpkg_find_acquire_program(BISON)

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO apache/thrift
    REF "v${VERSION}"
    SHA512 6dedcf48a8900e3a1dabfa73a4577a4d2482527b45ad8b77fec3fa7fdd8ea21b9249b3602c1e3e54bcee98143a9bb325b59e345423dc6dd8c9365889095615e2
    HEAD_REF master
    PATCHES
      "pc-suffix.patch"
      "fix_missing_quotes_in_config_and_bin_path.patch"
)

if (KMPKG_TARGET_IS_OSX)
    message(WARNING "${PORT} requires bison version greater than 2.5,\n\
please use command \`brew install bison\` to install bison")
endif()

string(COMPARE EQUAL "${KMPKG_LIBRARY_LINKAGE}" "dynamic" shared_lib)
string(COMPARE EQUAL "${KMPKG_LIBRARY_LINKAGE}" "static" static_lib)

# note we specify values for WITH_STATIC_LIB and WITH_SHARED_LIB because even though
# they're marked as deprecated, Thrift incorrectly hard-codes a value for BUILD_SHARED_LIBS.
kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    NO_CHARSET_FLAG
    OPTIONS
        --trace-expand
        -DLIB_INSTALL_DIR:PATH=lib
        -DWITH_SHARED_LIB=${shared_lib}
        -DWITH_STATIC_LIB=${static_lib}
        -DBUILD_TESTING=OFF
        -DBUILD_JAVA=OFF
        -DWITH_C_GLIB=OFF
        -DBUILD_C_GLIB=OFF
        -DCMAKE_DISABLE_FIND_PACKAGE_GLIB=TRUE
        -DBUILD_PYTHON=OFF
        -DBUILD_CPP=ON
        -DWITH_CPP=ON
        -DWITH_ZLIB=ON
        -DCMAKE_REQUIRE_FIND_PACKAGE_ZLIB=TRUE
        -DWITH_LIBEVENT=ON
        -DCMAKE_REQUIRE_FIND_PACKAGE_Libevent=TRUE
        -DWITH_OPENSSL=ON
        -DCMAKE_REQUIRE_FIND_PACKAGE_OpenSSL=TRUE
        -DBUILD_TUTORIALS=OFF
        -DFLEX_EXECUTABLE=${FLEX}
        -DWITH_QT5=OFF
        -DCMAKE_DISABLE_FIND_PACKAGE_Qt5=TRUE
        -DCMAKE_DISABLE_FIND_PACKAGE_Gradle=TRUE
        -DCMAKE_DISABLE_FIND_PACKAGE_Java=TRUE
        -DBUILD_JAVASCRIPT=OFF
        -DBUILD_NODEJS=OFF
        -DBISON_EXECUTABLE=${BISON}
    MAYBE_UNUSED_VARIABLES
        CMAKE_DISABLE_FIND_PACKAGE_GLIB
        CMAKE_DISABLE_FIND_PACKAGE_Gradle
        CMAKE_REQUIRE_FIND_PACKAGE_Libevent
        CMAKE_REQUIRE_FIND_PACKAGE_OpenSSL
        CMAKE_REQUIRE_FIND_PACKAGE_ZLIB
    
)

kmpkg_cmake_install()

kmpkg_copy_pdbs()

# Move CMake config files to the right place
kmpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/${PORT}")
kmpkg_fixup_pkgconfig()

file(GLOB COMPILER "${CURRENT_PACKAGES_DIR}/bin/thrift" "${CURRENT_PACKAGES_DIR}/bin/thrift.exe")
if(COMPILER)
    kmpkg_copy_tools(TOOL_NAMES thrift AUTO_CLEAN)
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" "${CURRENT_PACKAGES_DIR}/debug/share")

if ("${KMPKG_LIBRARY_LINKAGE}" STREQUAL "static")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin")
endif()

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
