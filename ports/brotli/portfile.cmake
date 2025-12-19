kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/brotli
    REF v${VERSION} # v1.1.0 
    SHA512 f94542afd2ecd96cc41fd21a805a3da314281ae558c10650f3e6d9ca732b8425bba8fde312823f0a564c7de3993bdaab5b43378edab65ebb798cefb6fd702256
    HEAD_REF master
    PATCHES
        install.patch
        pkgconfig.patch
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBROTLI_DISABLE_TESTS=ON
)
kmpkg_cmake_install()
kmpkg_copy_pdbs()
kmpkg_fixup_pkgconfig()
kmpkg_cmake_config_fixup(CONFIG_PATH share/unofficial-brotli PACKAGE_NAME unofficial-brotli)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/tools")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/man")

# Under emscripten the brotli executable tool is produced with .js extension but kmpkg_copy_tools
# has no special behaviour in this case and searches for the tool name with no extension
if(KMPKG_TARGET_IS_EMSCRIPTEN)
	set(TOOL_SUFFIX ".js" )
endif()

kmpkg_copy_tools(TOOL_NAMES "brotli${TOOL_SUFFIX}" SEARCH_DIR "${CURRENT_PACKAGES_DIR}/tools/brotli")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
