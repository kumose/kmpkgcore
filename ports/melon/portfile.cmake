kmpkg_check_linkage(ONLY_STATIC_LIBRARY)

# Required to run build/generate_escape_tables.py et al.
kmpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
kmpkg_add_to_path("${PYTHON3_DIR}")

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO kumose/melon
    REF "v${VERSION}"
    SHA512 2c11befb0e0eb9e78744cfa85f6bb4ee1e44f45b07e6045c9f0434faf1a2632f7247d33d7f542db6e40497f304e915078c38c9935d314ae4a3f3b81a3d382ca6
    HEAD_REF master
)

file(REMOVE "${SOURCE_PATH}/CMake/FindFmt.cmake")
file(REMOVE "${SOURCE_PATH}/CMake/FindLibsodium.cmake")
file(REMOVE "${SOURCE_PATH}/CMake/FindZstd.cmake")
file(REMOVE "${SOURCE_PATH}/CMake/FindSnappy.cmake")
file(REMOVE "${SOURCE_PATH}/CMake/FindLZ4.cmake")


if(KMPKG_CRT_LINKAGE STREQUAL static)
    set(MSVC_USE_STATIC_RUNTIME ON)
else()
    set(MSVC_USE_STATIC_RUNTIME OFF)
endif()

kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        "zlib"       CMAKE_REQUIRE_FIND_PACKAGE_ZLIB
        "liburing"   WITH_liburing
        "libaio"     WITH_libaio
        "int128"     MELON_HAVE_INT128_T
    INVERTED_FEATURES
        "bzip2"      CMAKE_DISABLE_FIND_PACKAGE_BZip2
        "lzma"       CMAKE_DISABLE_FIND_PACKAGE_LibLZMA
        "lz4"        CMAKE_DISABLE_FIND_PACKAGE_LZ4
        "zstd"       CMAKE_DISABLE_FIND_PACKAGE_Zstd
        "snappy"     CMAKE_DISABLE_FIND_PACKAGE_Snappy
        "libsodium"  CMAKE_DISABLE_FIND_PACKAGE_unofficial-sodium
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    DISABLE_PARALLEL_CONFIGURE
    OPTIONS
        -DMSVC_USE_STATIC_RUNTIME=${MSVC_USE_STATIC_RUNTIME}
        -DCMAKE_DISABLE_FIND_PACKAGE_LibDwarf=ON
        -DCMAKE_DISABLE_FIND_PACKAGE_Libiberty=ON
        -DCMAKE_INSTALL_DIR=share/melon
        -DBUILD_TESTS=OFF
        ${FEATURE_OPTIONS}
    MAYBE_UNUSED_VARIABLES
        MSVC_USE_STATIC_RUNTIME
)

kmpkg_cmake_install(ADD_BIN_TO_PATH)

kmpkg_copy_pdbs()

configure_file("${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake" "${CURRENT_PACKAGES_DIR}/share/${PORT}/kmpkg-cmake-wrapper.cmake" @ONLY)

kmpkg_cmake_config_fixup()

# Release melon-targets.cmake does not link to the right libraries in debug mode.
# We substitute with generator expressions so that the right libraries are linked for debug and release.
set(MELON_TARGETS_CMAKE "${CURRENT_PACKAGES_DIR}/share/melon/melon-targets.cmake")
FILE(READ ${MELON_TARGETS_CMAKE} _contents)
string(REPLACE "\${KMPKG_IMPORT_PREFIX}/lib/zlib.lib" "ZLIB::ZLIB" _contents "${_contents}")
STRING(REPLACE "\${KMPKG_IMPORT_PREFIX}/lib/" "\${KMPKG_IMPORT_PREFIX}/\$<\$<CONFIG:DEBUG>:debug/>lib/" _contents "${_contents}")
STRING(REPLACE "\${KMPKG_IMPORT_PREFIX}/debug/lib/" "\${KMPKG_IMPORT_PREFIX}/\$<\$<CONFIG:DEBUG>:debug/>lib/" _contents "${_contents}")
string(REPLACE "-vc140-mt.lib" "-vc140-mt\$<\$<CONFIG:DEBUG>:-gd>.lib" _contents "${_contents}")
FILE(WRITE ${MELON_TARGETS_CMAKE} "${_contents}")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

# Handle copyright
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

kmpkg_fixup_pkgconfig()
