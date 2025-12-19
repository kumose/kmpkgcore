kmpkg_download_distfile(
    ARCHIVE
    URLS "https://github.com/unicode-org/icu/releases/download/release-${VERSION}/icu4c-${VERSION}-sources.tgz"
    FILENAME "icu4c-${VERSION}-sources.tgz"
    SHA512 c366398fdb50afc6355a8c45ed1d68a18eaa5f07a5d1c4555becbcfb9d4073e65ebe1e9caf24b93779b11b36cd813c98dd59e4b19f008851f25c7262811c112d
)

kmpkg_extract_source_archive(SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        disable-static-prefix.patch # https://gitlab.kitware.com/cmake/cmake/-/issues/16617; also mingw.
        fix_parallel_build_on_windows.patch
        mh-darwin.patch
        mh-mingw.patch
        mh-msys-msvc.patch
        subdirs.patch
        kmpkg-cross-data.patch
)

kmpkg_find_acquire_program(PYTHON3)
set(ENV{PYTHON} "${PYTHON3}")

kmpkg_list(SET CONFIGURE_OPTIONS)
kmpkg_list(SET BUILD_OPTIONS)

if(KMPKG_TARGET_IS_EMSCRIPTEN)
    kmpkg_list(APPEND CONFIGURE_OPTIONS --disable-extras icu_cv_host_frag=mh-linux)
    kmpkg_list(APPEND BUILD_OPTIONS "\"PKGDATA_OPTS=--without-assembly -O ../data/icupkg.inc\"")
elseif(KMPKG_TARGET_IS_UWP)
    kmpkg_list(APPEND CONFIGURE_OPTIONS --disable-extras ac_cv_func_tzset=no ac_cv_func__tzset=no)
    string(APPEND KMPKG_C_FLAGS " -DU_PLATFORM_HAS_WINUWP_API=1")
    string(APPEND KMPKG_CXX_FLAGS " -DU_PLATFORM_HAS_WINUWP_API=1")
    kmpkg_list(APPEND BUILD_OPTIONS "\"PKGDATA_OPTS=--windows-uwp-build -O ../data/icupkg.inc\"")
elseif(KMPKG_TARGET_IS_OSX AND KMPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    kmpkg_list(APPEND CONFIGURE_OPTIONS --enable-rpath)
    if(DEFINED CMAKE_INSTALL_NAME_DIR)
        kmpkg_list(APPEND BUILD_OPTIONS "ID_PREFIX=${CMAKE_INSTALL_NAME_DIR}")
    endif()
endif()

if(KMPKG_TARGET_IS_WINDOWS AND NOT KMPKG_TARGET_IS_MINGW)
    list(APPEND CONFIGURE_OPTIONS ac_cv_lib_m_floor=no)
endif()

if("tools" IN_LIST FEATURES)
  list(APPEND CONFIGURE_OPTIONS --enable-tools)
else()
  list(APPEND CONFIGURE_OPTIONS --disable-tools)
endif()
if(CMAKE_HOST_WIN32 AND KMPKG_TARGET_IS_MINGW AND NOT HOST_TRIPLET MATCHES "mingw")
    # Assuming no cross compiling because the host (windows) pkgdata tool doesn't
    # use the '/' path separator when creating compiler commands for mingw bash.
elseif(KMPKG_CROSSCOMPILING)
    set(TOOL_PATH "${CURRENT_HOST_INSTALLED_DIR}/tools/${PORT}")
    # convert to unix path
    string(REGEX REPLACE "^([a-zA-Z]):/" "/\\1/" _KMPKG_TOOL_PATH "${TOOL_PATH}")
    list(APPEND CONFIGURE_OPTIONS "--with-cross-build=${_KMPKG_TOOL_PATH}")
endif()

kmpkg_make_configure(
    SOURCE_PATH "${SOURCE_PATH}/source"
    # AUTORECONF # needs Autoconf version 2.72
    OPTIONS
        ${CONFIGURE_OPTIONS}
        --disable-samples
        --disable-tests
        --disable-layoutex
    OPTIONS_RELEASE
        --disable-debug
        --enable-release
    OPTIONS_DEBUG
        --enable-debug
        --disable-release
)
kmpkg_make_install(OPTIONS ${BUILD_OPTIONS})

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/share"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/lib/icu"
    "${CURRENT_PACKAGES_DIR}/debug/lib/icu"
    "${CURRENT_PACKAGES_DIR}/debug/lib/icud")

file(GLOB TEST_LIBS
    "${CURRENT_PACKAGES_DIR}/lib/*test*"
    "${CURRENT_PACKAGES_DIR}/debug/lib/*test*")
if(TEST_LIBS)
    file(REMOVE ${TEST_LIBS})
endif()

if(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
    # force U_STATIC_IMPLEMENTATION macro
    foreach(HEADER utypes.h utf_old.h platform.h)
        kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/unicode/${HEADER}" "defined(U_STATIC_IMPLEMENTATION)" "1")
    endforeach()
endif()

# Install executables from /tools/icu/sbin to /tools/icu/bin on unix (/bin because icu require this for cross compiling)
if(KMPKG_TARGET_IS_LINUX OR KMPKG_TARGET_IS_OSX AND "tools" IN_LIST FEATURES)
    kmpkg_copy_tools(
        TOOL_NAMES icupkg gennorm2 gencmn genccode gensprep
        SEARCH_DIR "${CURRENT_PACKAGES_DIR}/tools/icu/sbin"
        DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin"
    )
endif()

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/tools/icu/sbin"
    "${CURRENT_PACKAGES_DIR}/tools/icu/debug")

# To cross compile, we need some files at specific positions. So lets copy them
file(GLOB CROSS_COMPILE_DEFS "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/config/icucross.*")
file(INSTALL ${CROSS_COMPILE_DEFS} DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}/config")

if(KMPKG_TARGET_IS_WINDOWS)
    string(REGEX MATCH "^[0-9]*" ICU_VERSION_MAJOR "${VERSION}")
    file(GLOB RELEASE_DLLS "${CURRENT_PACKAGES_DIR}/lib/*icu*${ICU_VERSION_MAJOR}.dll")
    file(COPY ${RELEASE_DLLS} DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin")

    # copy dlls
    file(GLOB RELEASE_DLLS "${CURRENT_PACKAGES_DIR}/lib/*icu*${ICU_VERSION_MAJOR}.dll")
    file(COPY ${RELEASE_DLLS} DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
    if(NOT KMPKG_BUILD_TYPE)
        file(GLOB DEBUG_DLLS "${CURRENT_PACKAGES_DIR}/debug/lib/*icu*${ICU_VERSION_MAJOR}.dll")
        file(COPY ${DEBUG_DLLS} DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
    endif()

    # remove any remaining dlls in /lib
    file(GLOB DUMMY_DLLS "${CURRENT_PACKAGES_DIR}/lib/*.dll" "${CURRENT_PACKAGES_DIR}/debug/lib/*.dll")
    if(DUMMY_DLLS)
        file(REMOVE ${DUMMY_DLLS})
    endif()

    kmpkg_copy_pdbs()
endif()

kmpkg_fixup_pkgconfig()
set(cxx_link_libraries "")
if(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
    block(PROPAGATE cxx_link_libraries)
        kmpkg_cmake_get_vars(cmake_vars_file)
        include("${cmake_vars_file}")
        list(REMOVE_ITEM KMPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES ${KMPKG_DETECTED_CMAKE_C_IMPLICIT_LINK_LIBRARIES})
        list(TRANSFORM KMPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES REPLACE "^([^/]+)\$" "-l\\1")
        string(JOIN " " cxx_link_libraries ${KMPKG_DETECTED_CMAKE_CXX_IMPLICIT_LINK_LIBRARIES})
    endblock()
    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/icu-uc.pc" "baselibs = " "baselibs = ${cxx_link_libraries} ")
    if(NOT KMPKG_BUILD_TYPE)
        kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/icu-uc.pc" "baselibs = " "baselibs = ${cxx_link_libraries} ")
    endif()
endif()

kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/tools/icu/bin/icu-config" "${CURRENT_INSTALLED_DIR}" "`dirname $0`/../../../" IGNORE_UNCHANGED)
kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/tools/icu/bin/icu-config" "${CURRENT_HOST_INSTALLED_DIR}" "`dirname $0`/../../../../${_HOST_TRIPLET}/" IGNORE_UNCHANGED)

configure_file("${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake" "${CURRENT_PACKAGES_DIR}/share/${PORT}/kmpkg-cmake-wrapper.cmake" @ONLY)
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
