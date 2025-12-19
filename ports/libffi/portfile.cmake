kmpkg_download_distfile(ARCHIVE
    URLS "https://github.com/libffi/libffi/releases/download/v${VERSION}/libffi-${VERSION}.tar.gz"
    FILENAME "libffi-${VERSION}.tar.gz"
    SHA512 76974a84e3aee6bbd646a6da2e641825ae0b791ca6efdc479b2d4cbcd3ad607df59cffcf5031ad5bd30822961a8c6de164ac8ae379d1804acd388b1975cdbf4d
)
kmpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        dll-bindir.diff
)

kmpkg_list(SET options)
if(KMPKG_TARGET_IS_WINDOWS)
    set(linkage_flag "-DFFI_STATIC_BUILD")
    if(KMPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        set(linkage_flag "-DFFI_BUILDING_DLL")
    endif()
    kmpkg_list(APPEND options "CFLAGS=\${CFLAGS} ${linkage_flag}")
endif()

kmpkg_cmake_get_vars(cmake_vars_file ADDITIONAL_LANGUAGES ASM)
include("${cmake_vars_file}")
if(KMPKG_DETECTED_CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    kmpkg_add_to_path("${SOURCE_PATH}")
    kmpkg_list(APPEND options "CCAS=msvcc.sh")
    set(ccas_options "")
    if(KMPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        string(APPEND ccas_options " -m32")
    elseif(KMPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        string(APPEND ccas_options " -m64")
    elseif(KMPKG_TARGET_ARCHITECTURE STREQUAL "arm")
        string(APPEND ccas_options " -marm")
    elseif(KMPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        string(APPEND ccas_options " -marm64")
    endif()
    if(ccas_options)
        kmpkg_list(APPEND options "CCASFLAGS=\${CCASFLAGS}${ccas_options}")
    endif()
endif()

kmpkg_make_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    LANGUAGES C CXX ASM
    OPTIONS
        --enable-portable-binary
        --disable-docs
        --disable-multi-os-directory
        ${options}
)

kmpkg_make_install()
kmpkg_copy_pdbs()
kmpkg_fixup_pkgconfig()

if (KMPKG_LIBRARY_LINKAGE STREQUAL "static")
    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/ffi.h" "defined(FFI_STATIC_BUILD)" "1")
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/unofficial-libffi-config.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/unofficial-libffi")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/libffiConfig.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/share/man3"
)

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
