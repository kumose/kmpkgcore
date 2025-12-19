if(EXISTS "${CURRENT_INSTALLED_DIR}/share/mozjpeg/copyright")
    message(FATAL_ERROR "Can't build ${PORT} if mozjpeg is installed. Please remove mozjpeg:${TARGET_TRIPLET}, and try to install ${PORT}:${TARGET_TRIPLET} again.")
endif()
if(EXISTS "${CURRENT_INSTALLED_DIR}/share/ijg-libjpeg/copyright")
    message(FATAL_ERROR "Can't build ${PORT} if ijg-libjpeg is installed. Please remove ijg-libjpeg:${TARGET_TRIPLET}, and try to install ${PORT}:${TARGET_TRIPLET} again.")
endif()
kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libjpeg-turbo/libjpeg-turbo
    REF "${VERSION}"
    SHA512 d95bf0689fb2862ad5ea9e902b73724098d911d9c312aa69157bec9de77f32e4d5ac7dfa105d844110cc66dbdb0336056ba7f96781fcbc848b72fd0661604d50
    HEAD_REF master
    PATCHES
        add-options-for-docs-headers.patch
        # workaround for kmpkg bug see #5697 on github for more information
        workaround_cmake_system_processor.patch
)

if(KMPKG_TARGET_ARCHITECTURE STREQUAL "wasm32")
    set(LIBJPEGTURBO_SIMD -DWITH_SIMD=OFF)
elseif(KMPKG_TARGET_ARCHITECTURE STREQUAL "arm" OR KMPKG_TARGET_ARCHITECTURE STREQUAL "arm64" OR (KMPKG_CMAKE_SYSTEM_NAME AND NOT KMPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore"))
    set(LIBJPEGTURBO_SIMD -DWITH_SIMD=ON -DNEON_INTRINSICS=ON)
else()
    set(LIBJPEGTURBO_SIMD -DWITH_SIMD=ON)
    kmpkg_find_acquire_program(NASM)
    get_filename_component(NASM_EXE_PATH ${NASM} DIRECTORY)
    set(ENV{PATH} "$ENV{PATH};${NASM_EXE_PATH}")
endif()

if(KMPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
    set(ENV{_CL_} "-DNO_GETENV -DNO_PUTENV")
endif()

string(COMPARE EQUAL "${KMPKG_LIBRARY_LINKAGE}" "dynamic" ENABLE_SHARED)
string(COMPARE EQUAL "${KMPKG_LIBRARY_LINKAGE}" "static" ENABLE_STATIC)
string(COMPARE EQUAL "${KMPKG_CRT_LINKAGE}" "dynamic" WITH_CRT_DLL)

kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        jpeg7 WITH_JPEG7
        jpeg8 WITH_JPEG8
        tools WITH_TOOLS
)

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DENABLE_STATIC=${ENABLE_STATIC}
        -DENABLE_SHARED=${ENABLE_SHARED}
        -DWITH_CRT_DLL=${WITH_CRT_DLL}
        ${FEATURE_OPTIONS}
        ${LIBJPEGTURBO_SIMD}
    MAYBE_UNUSED_VARIABLES
        WITH_CRT_DLL
)

kmpkg_cmake_install()
kmpkg_copy_pdbs()

if(WITH_TOOLS)
    kmpkg_copy_tools(
        TOOL_NAMES cjpeg djpeg jpegtran rdjpgcom wrjpgcom
        AUTO_CLEAN
    )
    kmpkg_clean_executables_in_bin(
        FILE_NAMES tjbench
    )
endif()

kmpkg_fixup_pkgconfig()
kmpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/libjpeg-turbo)

# Rename libraries for static builds
if(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
    if(EXISTS "${CURRENT_PACKAGES_DIR}/lib/jpeg-static.lib")
        file(RENAME "${CURRENT_PACKAGES_DIR}/lib/jpeg-static.lib" "${CURRENT_PACKAGES_DIR}/lib/jpeg.lib")
        file(RENAME "${CURRENT_PACKAGES_DIR}/lib/turbojpeg-static.lib" "${CURRENT_PACKAGES_DIR}/lib/turbojpeg.lib")
    endif()
    if(EXISTS "${CURRENT_PACKAGES_DIR}/debug/lib/jpeg-static.lib")
        file(RENAME "${CURRENT_PACKAGES_DIR}/debug/lib/jpeg-static.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/jpeg.lib")
        file(RENAME "${CURRENT_PACKAGES_DIR}/debug/lib/turbojpeg-static.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/turbojpeg.lib")
    endif()

    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")

    if (EXISTS "${CURRENT_PACKAGES_DIR}/share/${PORT}/libjpeg-turboTargets-debug.cmake")
        kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/libjpeg-turboTargets-debug.cmake"
            "jpeg-static${KMPKG_TARGET_STATIC_LIBRARY_SUFFIX}" "jpeg${KMPKG_TARGET_STATIC_LIBRARY_SUFFIX}" IGNORE_UNCHANGED)
        kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/libjpeg-turboTargets-debug.cmake"
            "turbojpeg-static${KMPKG_TARGET_STATIC_LIBRARY_SUFFIX}" "turbojpeg${KMPKG_TARGET_STATIC_LIBRARY_SUFFIX}" IGNORE_UNCHANGED)
    endif()
    if (EXISTS "${CURRENT_PACKAGES_DIR}/share/${PORT}/libjpeg-turboTargets-release.cmake")
        kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/libjpeg-turboTargets-release.cmake"
            "jpeg-static${KMPKG_TARGET_STATIC_LIBRARY_SUFFIX}" "jpeg${KMPKG_TARGET_STATIC_LIBRARY_SUFFIX}" IGNORE_UNCHANGED)
        kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${PORT}/libjpeg-turboTargets-release.cmake"
            "turbojpeg-static${KMPKG_TARGET_STATIC_LIBRARY_SUFFIX}" "turbojpeg${KMPKG_TARGET_STATIC_LIBRARY_SUFFIX}" IGNORE_UNCHANGED)
    endif()
endif()

file(REMOVE_RECURSE
     "${CURRENT_PACKAGES_DIR}/debug/share"
     "${CURRENT_PACKAGES_DIR}/debug/include"
     "${CURRENT_PACKAGES_DIR}/share/man")

file(COPY "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/kmpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/jpeg")

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
