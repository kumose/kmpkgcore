kmpkg_download_distfile(ARCHIVE
    URLS "https://sourceware.org/pub/bzip2/bzip2-${VERSION}.tar.gz"
         "https://www.mirrorservice.org/sites/sourceware.org/pub/bzip2/bzip2-${VERSION}.tar.gz"
    FILENAME "bzip2-${VERSION}.tar.gz"
    SHA512 083f5e675d73f3233c7930ebe20425a533feedeaaa9d8cc86831312a6581cefbe6ed0d08d2fa89be81082f2a5abdabca8b3c080bf97218a1bd59dc118a30b9f3
)

kmpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES fix-import-export-macros.patch
)

kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    INVERTED_FEATURES
        tool BZIP2_SKIP_TOOLS
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" DESTINATION "${SOURCE_PATH}")

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        "-DBZ2_VERSION=${VERSION}"
    OPTIONS_DEBUG
        -DBZIP2_SKIP_HEADERS=ON
        -DBZIP2_SKIP_TOOLS=ON
)

kmpkg_cmake_install()
kmpkg_copy_pdbs()

file(READ "${CURRENT_PACKAGES_DIR}/include/bzlib.h" BZLIB_H)
if(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
    string(REPLACE "defined(BZ_IMPORT)" "0" BZLIB_H "${BZLIB_H}")
else()
    string(REPLACE "defined(BZ_IMPORT)" "1" BZLIB_H "${BZLIB_H}")
endif()
file(WRITE "${CURRENT_PACKAGES_DIR}/include/bzlib.h" "${BZLIB_H}")

if (NOT KMPKG_BUILD_TYPE OR KMPKG_BUILD_TYPE STREQUAL "release")
    set(BZIP2_PREFIX "${CURRENT_INSTALLED_DIR}")
    set(bzname bz2)
    configure_file("${CMAKE_CURRENT_LIST_DIR}/bzip2.pc.in" "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/bzip2.pc" @ONLY)
endif()

if (NOT KMPKG_BUILD_TYPE OR KMPKG_BUILD_TYPE STREQUAL "debug")
    set(BZIP2_PREFIX "${CURRENT_INSTALLED_DIR}/debug")
    set(bzname bz2d)
    configure_file("${CMAKE_CURRENT_LIST_DIR}/bzip2.pc.in" "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/bzip2.pc" @ONLY)
endif()

kmpkg_fixup_pkgconfig()

file(COPY "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
