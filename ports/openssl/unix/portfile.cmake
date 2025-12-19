if (KMPKG_TARGET_IS_LINUX)
    message(NOTICE [[
openssl requires Linux kernel headers from the system package manager.
   They can be installed on Alpine systems via `apk add linux-headers`.
   They can be installed on Ubuntu systems via `apt install linux-libc-dev`.
]])
endif()

if(KMPKG_HOST_IS_WINDOWS)
    kmpkg_acquire_msys(MSYS_ROOT PACKAGES make perl)
    set(MAKE "${MSYS_ROOT}/usr/bin/make.exe")
    set(PERL "${MSYS_ROOT}/usr/bin/perl.exe")
else()
    find_program(MAKE make)
    if(NOT MAKE)
        message(FATAL_ERROR "Could not find make. Please install it through your package manager.")
    endif()
    kmpkg_find_acquire_program(PERL)
endif()
set(INTERPRETER "${PERL}")

execute_process(
    COMMAND "${PERL}" -e "use IPC::Cmd;"
    RESULT_VARIABLE perl_ipc_cmd_result
)
if(NOT perl_ipc_cmd_result STREQUAL "0")
    message(FATAL_ERROR "\nPerl cannot find IPC::Cmd. Please install it through your system package manager.\n")
endif()

# Ideally, OpenSSL should use `CC` from kmpkg as is (absolute path).
# But in reality, OpenSSL expects to locate the compiler via `PATH`,
# and it makes its own choices e.g. for Android.
kmpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")
cmake_path(GET KMPKG_DETECTED_CMAKE_C_COMPILER PARENT_PATH compiler_path)
cmake_path(GET KMPKG_DETECTED_CMAKE_C_COMPILER FILENAME compiler_name)
find_program(compiler_in_path NAMES "${compiler_name}" PATHS ENV PATH NO_DEFAULT_PATH)
if(NOT compiler_in_path)
    kmpkg_host_path_list(APPEND ENV{PATH} "${compiler_path}")
elseif(NOT compiler_in_path STREQUAL KMPKG_DETECTED_CMAKE_C_COMPILER)
    kmpkg_host_path_list(PREPEND ENV{PATH} "${compiler_path}")
endif()

kmpkg_list(SET MAKEFILE_OPTIONS)
if(KMPKG_TARGET_IS_ANDROID)
    set(ENV{ANDROID_NDK_ROOT} "${KMPKG_DETECTED_CMAKE_ANDROID_NDK}")
    set(OPENSSL_ARCH "android-${KMPKG_DETECTED_CMAKE_ANDROID_ARCH}")
    if(KMPKG_DETECTED_CMAKE_ANDROID_ARCH STREQUAL "arm" AND NOT KMPKG_DETECTED_CMAKE_ANDROID_ARM_NEON)
        kmpkg_list(APPEND CONFIGURE_OPTIONS no-asm)
    endif()
elseif(KMPKG_TARGET_IS_LINUX)
    if(KMPKG_TARGET_ARCHITECTURE MATCHES "arm64")
        set(OPENSSL_ARCH linux-aarch64)
    elseif(KMPKG_TARGET_ARCHITECTURE MATCHES "arm")
        set(OPENSSL_ARCH linux-armv4)
    elseif(KMPKG_TARGET_ARCHITECTURE MATCHES "x64")
        set(OPENSSL_ARCH linux-x86_64)
    elseif(KMPKG_TARGET_ARCHITECTURE MATCHES "x86")
        set(OPENSSL_ARCH linux-x86)
    else()
        set(OPENSSL_ARCH linux-generic32)
    endif()
elseif(KMPKG_TARGET_IS_IOS)
    if(KMPKG_TARGET_ARCHITECTURE MATCHES "arm64")
        set(OPENSSL_ARCH ios64-xcrun)
    elseif(KMPKG_TARGET_ARCHITECTURE MATCHES "arm")
        set(OPENSSL_ARCH ios-xcrun)
    elseif(KMPKG_TARGET_ARCHITECTURE MATCHES "x86" OR KMPKG_TARGET_ARCHITECTURE MATCHES "x64")
        set(OPENSSL_ARCH iossimulator-xcrun)
    else()
        message(FATAL_ERROR "Unknown iOS target architecture: ${KMPKG_TARGET_ARCHITECTURE}")
    endif()
    # disable that makes linkage error (e.g. require stderr usage)
    list(APPEND CONFIGURE_OPTIONS no-ui no-asm)
elseif(KMPKG_TARGET_IS_TVOS OR KMPKG_TARGET_IS_WATCHOS)
    set(OPENSSL_ARCH iphoneos-cross)
    # disable that makes linkage error (e.g. require stderr usage)
    list(APPEND CONFIGURE_OPTIONS no-ui no-asm)
elseif(KMPKG_TARGET_IS_OSX)
    if(KMPKG_TARGET_ARCHITECTURE MATCHES "arm64")
        set(OPENSSL_ARCH darwin64-arm64)
    else()
        set(OPENSSL_ARCH darwin64-x86_64)
    endif()
elseif(KMPKG_TARGET_IS_BSD)
    set(OPENSSL_ARCH BSD-nodef-generic64)
elseif(KMPKG_TARGET_IS_SOLARIS)
    if(KMPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(OPENSSL_ARCH solaris64-x86_64-gcc)
    else()
        set(OPENSSL_ARCH solaris-x86-gcc)
    endif()
elseif(KMPKG_TARGET_IS_MINGW)
    if(KMPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(OPENSSL_ARCH mingw64)
    elseif(KMPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(OPENSSL_ARCH mingwarm64)
    else()
        set(OPENSSL_ARCH mingw)
    endif()
elseif(KMPKG_TARGET_IS_EMSCRIPTEN)
    set(OPENSSL_ARCH linux-x32)
    kmpkg_list(APPEND CONFIGURE_OPTIONS
        no-engine
        no-asm
        no-sse2
        no-srtp
        --cross-compile-prefix=
    )
    # Cf. https://emscripten.org/docs/porting/pthreads.html:
    # For Pthreads support, not just openssl but everything
    # must be compiled and linked with `-pthread`.
    # This makes it a triplet/toolchain-wide setting.
    if(NOT " ${KMPKG_DETECTED_CMAKE_C_FLAGS} " MATCHES " -pthread ")
        kmpkg_list(APPEND CONFIGURE_OPTIONS no-threads)
    endif()
else()
    message(FATAL_ERROR "Unknown platform")
endif()

file(MAKE_DIRECTORY "${SOURCE_PATH}/kmpkg")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/configure" DESTINATION "${SOURCE_PATH}/kmpkg")
kmpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    PROJECT_SUBPATH "kmpkg"
    NO_ADDITIONAL_PATHS
    OPTIONS
        "${INTERPRETER}"
        "${SOURCE_PATH}/Configure"
        ${OPENSSL_ARCH}
        ${CONFIGURE_OPTIONS}
        "--openssldir=/etc/ssl"
        "--libdir=lib"
    OPTIONS_DEBUG
        --debug
)
kmpkg_install_make(
    ${MAKEFILE_OPTIONS}
    BUILD_TARGET build_inst_sw
)
kmpkg_fixup_pkgconfig()

if("tools" IN_LIST FEATURES)
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
    file(RENAME "${CURRENT_PACKAGES_DIR}/bin/c_rehash" "${CURRENT_PACKAGES_DIR}/tools/${PORT}/c_rehash")
    file(REMOVE "${CURRENT_PACKAGES_DIR}/debug/bin/c_rehash")
    kmpkg_copy_tools(TOOL_NAMES openssl AUTO_CLEAN)
elseif(KMPKG_LIBRARY_LINKAGE STREQUAL "static" OR NOT KMPKG_TARGET_IS_WINDOWS)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/etc/ssl/misc")
endif()

file(TOUCH "${CURRENT_PACKAGES_DIR}/etc/ssl/certs/.keep")
file(TOUCH "${CURRENT_PACKAGES_DIR}/etc/ssl/private/.keep")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/etc"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

# For consistency of mingw build with nmake build
file(GLOB engines "${CURRENT_PACKAGES_DIR}/lib/ossl-modules/*.dll")
if(NOT engines STREQUAL "")
    file(COPY ${engines} DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib/ossl-modules")
endif()
file(GLOB engines "${CURRENT_PACKAGES_DIR}/debug/lib/ossl-modules/*.dll")
if(NOT engines STREQUAL "")
    file(COPY ${engines} DESTINATION "${CURRENT_PACKAGES_DIR}/debug/bin")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/lib/ossl-modules")
endif()
