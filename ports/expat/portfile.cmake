string(REPLACE "." "_" REF "R_${VERSION}")

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libexpat/libexpat
    REF "${REF}"
    SHA512 34400f7dff0151a38c5ff7d73b65b57c7fdf648cf407ed94beddf2d11511b650c4ea16e417a15ebe1707456e7279210e929cc97a0caf7a1ff45bf1d07275e815
    HEAD_REF master
)

string(COMPARE EQUAL "${KMPKG_LIBRARY_LINKAGE}" "dynamic" EXPAT_LINKAGE)
string(COMPARE EQUAL "${KMPKG_CRT_LINKAGE}" "static" EXPAT_CRT_LINKAGE)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/expat"
    OPTIONS
        -DEXPAT_BUILD_EXAMPLES=OFF
        -DEXPAT_BUILD_TESTS=OFF
        -DEXPAT_BUILD_TOOLS=OFF
        -DEXPAT_BUILD_DOCS=OFF
        -DEXPAT_SHARED_LIBS=${EXPAT_LINKAGE}
        -DEXPAT_MSVC_STATIC_CRT=${EXPAT_CRT_LINKAGE}
        -DEXPAT_BUILD_PKGCONFIG=ON
    MAYBE_UNUSED_VARIABLES
        EXPAT_MSVC_STATIC_CRT
)

kmpkg_cmake_install()
kmpkg_copy_pdbs()
kmpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/expat-${VERSION}")
kmpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/doc")

kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/expat_external.h" "defined(_MSC_EXTENSIONS)" "defined(_WIN32)")
if(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/expat_external.h" "! defined(XML_STATIC)" "0")
endif()

file(COPY "${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/expat/COPYING")
