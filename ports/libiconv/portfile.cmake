if(NOT DEFINED X_KMPKG_BUILD_GNU_LIBICONV)
    set(X_KMPKG_BUILD_GNU_LIBICONV 0)
    if(KMPKG_TARGET_IS_WINDOWS OR KMPKG_TARGET_IS_IOS OR KMPKG_TARGET_IS_BSD)
        set(X_KMPKG_BUILD_GNU_LIBICONV 1)
    elseif(KMPKG_TARGET_IS_ANDROID)
        kmpkg_cmake_get_vars(cmake_vars_file)
        include("${cmake_vars_file}")
        if(KMPKG_DETECTED_CMAKE_SYSTEM_VERSION VERSION_LESS "28")
            set(X_KMPKG_BUILD_GNU_LIBICONV 1)
        endif()
    endif()
endif()

if(NOT X_KMPKG_BUILD_GNU_LIBICONV)
    message(STATUS "Not building GNU libiconv.")
    set(KMPKG_POLICY_EMPTY_PACKAGE enabled)
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/iconv")
    file(COPY "${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/iconv")
    return()
endif()

kmpkg_download_distfile(ARCHIVE
    URLS "https://ftpmirror.gnu.org/gnu/libiconv/libiconv-${VERSION}.tar.gz"
         "https://ftp.gnu.org/gnu/libiconv/libiconv-${VERSION}.tar.gz"
         "https://www.mirrorservice.org/sites/ftp.gnu.org/gnu/libiconv/libiconv-${VERSION}.tar.gz"
    FILENAME "libiconv-${VERSION}.tar.gz"
    SHA512 a55eb3b7b785a78ab8918db8af541c9e11deb5ff4f89d54483287711ed797d87848ce0eafffa7ce26d9a7adb4b5a9891cb484f94bd4f51d3ce97a6a47b4c719a
)
kmpkg_extract_source_archive(SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    SOURCE_BASE "v${VERSION}"
    PATCHES
        0002-Config-for-MSVC.patch
        0003-Add-export.patch
        0004-ModuleFileName.patch
)

kmpkg_list(SET OPTIONS)
if (NOT KMPKG_TARGET_IS_ANDROID)
    kmpkg_list(APPEND OPTIONS --enable-relocatable)
endif()

kmpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    DETERMINE_BUILD_TRIPLET
    USE_WRAPPERS
    OPTIONS
        --enable-extra-encodings
        --without-libiconv-prefix
        --without-libintl-prefix
        ${OPTIONS}
)
kmpkg_install_make()

kmpkg_copy_pdbs()
kmpkg_copy_tool_dependencies("${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin")
kmpkg_copy_tool_dependencies("${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug/bin")

file(COPY "${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/iconv")

set(KMPKG_POLICY_ALLOW_RESTRICTED_HEADERS enabled)
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/${PORT}") # share contains unneeded doc files

# Please keep, the default usage is broken
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Handle copyright
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING.LIB" "${SOURCE_PATH}/COPYING" COMMENT "
The libiconv and libcharset libraries and their header files are under LGPL,
see COPYING.LIB below.

The iconv program and the documentation are under GPL, see COPYING below.")
