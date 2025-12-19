kmpkg_download_distfile(
    ARCHIVE_PATH
    URLS
        "https://invisible-mirror.net/archives/ncurses/ncurses-${VERSION}.tar.gz"
        "ftp://ftp.invisible-island.net/ncurses/ncurses-${VERSION}.tar.gz"
        "https://ftp.gnu.org/gnu/ncurses/ncurses-${VERSION}.tar.gz"
    FILENAME "ncurses-${VERSION}.tgz"
    SHA512 fc5a13409d2a530a1325776dcce3a99127ddc2c03999cfeb0065d0eee2d68456274fb1c7b3cc99c1937bc657d0e7fca97016e147f93c7821b5a4a6837db821e8
)

kmpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE_PATH}"
)

kmpkg_list(SET OPTIONS)

if(KMPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    list(APPEND OPTIONS
        --with-cxx-shared
        --with-shared    # "lib model"
        --without-normal # "lib model"
    )
endif()

if(NOT KMPKG_TARGET_IS_MINGW)
    list(APPEND OPTIONS
        --enable-mixed-case
    )
endif()

if(KMPKG_TARGET_IS_MINGW)
    list(APPEND OPTIONS
        --disable-home-terminfo
        --enable-term-driver
        --disable-termcap
    )
endif()

if("check-size" IN_LIST FEATURES)
    list(APPEND OPTIONS
        --enable-check-size
    )
endif()

kmpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

# There are compilation errors on gcc 15. adding `-std=c17` to CFLAGS for workaround.
# ref: https://gitlab.archlinux.org/archlinux/packaging/packages/ncurses/-/issues/3
if(KMPKG_DETECTED_CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND KMPKG_DETECTED_CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 15)
    set(ENV{CFLAGS} "$ENV{CFLAGS} -std=c17")
endif()

kmpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    CONFIGURE_ENVIRONMENT_VARIABLES CFLAGS
    DETERMINE_BUILD_TRIPLET
    NO_ADDITIONAL_PATHS
    OPTIONS
        ${OPTIONS}
        --disable-db-install
        --disable-pkg-ldflags
        --disable-rpath-hack
        --enable-pc-files
        --without-ada
        --without-debug # "lib model"
        --without-manpages
        --without-progs
        --without-tack
        --without-tests
        --with-pkg-config-libdir=libdir
)
kmpkg_install_make()
kmpkg_fixup_pkgconfig()

# Prefer local files over search path
file(GLOB headers "${CURRENT_PACKAGES_DIR}/include/ncursesw/*.h")
foreach(file IN LISTS headers)
    kmpkg_replace_string("${file}" [[#include <ncursesw/([^>]*)>]] [[#include "\1"]] REGEX IGNORE_UNCHANGED)
endforeach()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
