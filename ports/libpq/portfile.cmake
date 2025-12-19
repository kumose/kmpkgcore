kmpkg_download_distfile(ARCHIVE
    URLS "https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.bz2"
         "https://www.mirrorservice.org/sites/ftp.postgresql.org/source/v${VERSION}/postgresql-${VERSION}.tar.bz2"
    FILENAME "postgresql-${VERSION}.tar.bz2"
    SHA512 23a3d983c5be49c3daabbbde35db2920bd2e2ba8d9baba805e7908da1f43153ff438c76c253ea8ee8ac6f8a9313fbf0348a1e9b45ef530c5e156fee0daceb814
)

kmpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    PATCHES
        unix/installdirs.patch
        unix/fix-configure.patch
        unix/single-linkage.patch
        unix/no-server-tools.patch
        unix/mingw-install.patch
        unix/python.patch
        windows/macro-def.patch
        windows/win_bison_flex.patch
        windows/msbuild.patch
        windows/spin_delay.patch
        windows/tcl-9.0-alpha.patch
        android/unversioned_so.patch
)

file(GLOB _py3_include_path "${CURRENT_HOST_INSTALLED_DIR}/include/python3*")
string(REGEX MATCH "python3\\.([0-9]+)" _python_version_tmp "${_py3_include_path}")
set(PYTHON_VERSION_MINOR "${CMAKE_MATCH_1}")

if("client" IN_LIST FEATURES)
    set(HAS_TOOLS TRUE)
else()
    set(HAS_TOOLS FALSE)
endif()

kmpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

set(required_programs BISON FLEX)
if(KMPKG_DETECTED_MSVC OR NOT KMPKG_HOST_IS_WINDOWS)
    list(APPEND required_programs PERL)
endif()
foreach(program_name IN LISTS required_programs)
    kmpkg_find_acquire_program(${program_name})
    get_filename_component(program_dir ${${program_name}} DIRECTORY)
    kmpkg_add_to_path(PREPEND "${program_dir}")
endforeach()

if(KMPKG_DETECTED_MSVC)
    if("xml" IN_LIST FEATURES)
        x_kmpkg_pkgconfig_get_modules(
            PREFIX PC_LIBXML2
            MODULES --msvc-syntax libxml-2.0
            LIBS
        )
        separate_arguments(LIBXML2_LIBS_DEBUG NATIVE_COMMAND "${PC_LIBXML2_LIBS_DEBUG}")
        separate_arguments(LIBXML2_LIBS_RELEASE NATIVE_COMMAND "${PC_LIBXML2_LIBS_RELEASE}")
    endif()
    if("xslt" IN_LIST FEATURES)
        x_kmpkg_pkgconfig_get_modules(
            PREFIX PC_LIBXSLT
            MODULES --msvc-syntax libxslt
            LIBS
        )
        separate_arguments(LIBXSLT_LIBS_DEBUG NATIVE_COMMAND "${PC_LIBXSLT_LIBS_DEBUG}")
        separate_arguments(LIBXSLT_LIBS_RELEASE NATIVE_COMMAND "${PC_LIBXSLT_LIBS_RELEASE}")
    endif()

    include("${CMAKE_CURRENT_LIST_DIR}/build-msvc.cmake")
    if(NOT KMPKG_BUILD_TYPE)
        build_msvc(DEBUG "${SOURCE_PATH}")
    endif()
    build_msvc(RELEASE "${SOURCE_PATH}")

    if(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
    endif()

    if(HAS_TOOLS)
        kmpkg_copy_tool_dependencies("${CURRENT_PACKAGES_DIR}/tools/${PORT}")
    else()
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/tools")
    endif()
else()
    file(COPY "${CMAKE_CURRENT_LIST_DIR}/Makefile" DESTINATION "${SOURCE_PATH}")

    kmpkg_list(SET BUILD_OPTS)
    foreach(option IN ITEMS icu lz4 nls openssl readline xml xslt zlib zstd)
        if(option IN_LIST FEATURES)
            list(APPEND BUILD_OPTS --with-${option})
        else()
            list(APPEND BUILD_OPTS --without-${option})
        endif()
    endforeach()
    if("nls" IN_LIST FEATURES)
        set(ENV{MSGFMT} "${CURRENT_HOST_INSTALLED_DIR}/tools/gettext/bin/msgfmt${KMPKG_HOST_EXECUTABLE_SUFFIX}")
    endif()
    if("python" IN_LIST FEATURES)
        list(APPEND BUILD_OPTS --with-python=3.${PYTHON_VERSION_MINOR})
        kmpkg_find_acquire_program(PYTHON3)
        list(APPEND BUILD_OPTS "PYTHON=${PYTHON3}")
    endif()
    if(KMPKG_TARGET_IS_ANDROID AND (NOT KMPKG_CMAKE_SYSTEM_VERSION OR KMPKG_CMAKE_SYSTEM_VERSION LESS "26"))
        list(APPEND BUILD_OPTS ac_cv_header_langinfo_h=no)
    endif()
    if(KMPKG_DETECTED_CMAKE_OSX_SYSROOT)
        list(APPEND BUILD_OPTS "PG_SYSROOT=${KMPKG_DETECTED_CMAKE_OSX_SYSROOT}")
    endif()
    kmpkg_configure_make(
        SOURCE_PATH "${SOURCE_PATH}"
        COPY_SOURCE
        AUTOCONFIG
        ADDITIONAL_MSYS_PACKAGES autoconf-archive
            DIRECT_PACKAGES
                "https://mirror.msys2.org/msys/x86_64/tzcode-2025b-1-x86_64.pkg.tar.zst"
                824779e3ac4857bb21cbdc92fa881fa24bf89dfa8bc2f9ca816e9a9837a6d963805e8e0991499c43337a134552215fdee50010e643ddc8bd699170433a4c83de
        OPTIONS
            ${BUILD_OPTS}
        OPTIONS_DEBUG
            --enable-debug
    )

    if(KMPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        set(ENV{LIBPQ_LIBRARY_TYPE} shared)
    else()
        set(ENV{LIBPQ_LIBRARY_TYPE} static)
    endif()
    if(KMPKG_TARGET_IS_MINGW)
        set(ENV{LIBPQ_USING_MINGW} yes)
    endif()
    if(HAS_TOOLS)
        set(ENV{LIBPQ_ENABLE_TOOLS} yes)
    endif()
    kmpkg_install_make()

    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/postgresql/server/pg_config.h" "#define CONFIGURE_ARGS" "// #define CONFIGURE_ARGS")
    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/pg_config.h" "#define CONFIGURE_ARGS" "// #define CONFIGURE_ARGS")
endif()

kmpkg_fixup_pkgconfig()
configure_file("${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake" "${CURRENT_PACKAGES_DIR}/share/postgresql/kmpkg-cmake-wrapper.cmake" @ONLY)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/doc"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/debug/symbols"
    "${CURRENT_PACKAGES_DIR}/debug/tools"
    "${CURRENT_PACKAGES_DIR}/symbols"
    "${CURRENT_PACKAGES_DIR}/tools/${PORT}/debug"
)

file(INSTALL "${CURRENT_PORT_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYRIGHT")
