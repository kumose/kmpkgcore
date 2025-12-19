# Common Ambient Variables:
#   CURRENT_BUILDTREES_DIR    = ${KMPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR      = ${KMPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#   CURRENT_PORT_DIR          = ${KMPKG_ROOT_DIR}\ports\${PORT}
#   CURRENT_INSTALLED_DIR     = ${KMPKG_ROOT_DIR}\installed\${TRIPLET}
#   DOWNLOADS                 = ${KMPKG_ROOT_DIR}\downloads
#   PORT                      = current port name (zlib, etc)
#   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
#   KMPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
#   KMPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
#   KMPKG_ROOT_DIR            = <C:\path\to\current\kmpkg>
#   KMPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
#   KMPKG_TOOLCHAIN           = ON OFF
#   TRIPLET_SYSTEM_ARCH       = arm x86 x64
#   BUILD_ARCH                = "Win32" "x64" "ARM"
#   DEBUG_CONFIG              = "Debug Static" "Debug Dll"
#   RELEASE_CONFIG            = "Release Static"" "Release DLL"
#   KMPKG_TARGET_IS_WINDOWS
#   KMPKG_TARGET_IS_UWP
#   KMPKG_TARGET_IS_LINUX
#   KMPKG_TARGET_IS_OSX
#   KMPKG_TARGET_IS_FREEBSD
#   KMPKG_TARGET_IS_ANDROID
#   KMPKG_TARGET_IS_MINGW
#   KMPKG_TARGET_EXECUTABLE_SUFFIX
#   KMPKG_TARGET_STATIC_LIBRARY_SUFFIX
#   KMPKG_TARGET_SHARED_LIBRARY_SUFFIX
#
# 	See additional helpful variables in /docs/maintainers/kmpkg_common_definitions.md

# Also consider kmpkg_from_* functions if you can; the generated code here is for any web accessable
# source archive.
#  kmpkg_from_github
#  kmpkg_from_gitlab
#  kmpkg_from_bitbucket
#  kmpkg_from_sourceforge
kmpkg_download_distfile(ARCHIVE
    URLS "@URL@"
    FILENAME "@FILENAME@"
    SHA512 @SHA512@
)

kmpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    # (Optional) A friendly name to use instead of the filename of the archive (e.g.: a version number or tag).
    # REF 1.0.0
    # (Optional) Read the docs for how to generate patches at:
    # https://github.com/microsoft/kmpkg-docs/blob/main/kmpkg/examples/patching.md
    # PATCHES
    #   001_port_fixes.patch
    #   002_more_port_fixes.patch
)

# # Check if one or more features are a part of a package installation.
# # See /docs/maintainers/kmpkg_check_features.md for more details
# kmpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
#   FEATURES
#     tbb   WITH_TBB
#   INVERTED_FEATURES
#     tbb   ROCKSDB_IGNORE_PACKAGE_TBB
# )

kmpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    # OPTIONS -DUSE_THIS_IN_ALL_BUILDS=1 -DUSE_THIS_TOO=2
    # OPTIONS_RELEASE -DOPTIMIZE=1
    # OPTIONS_DEBUG -DDEBUGGABLE=1
)

kmpkg_cmake_install()

# # Moves all .cmake files from /debug/share/@PORT@/ to /share/@PORT@/
# # See /docs/maintainers/ports/kmpkg-cmake-config/kmpkg_cmake_config_fixup.md for more details
# When you uncomment "kmpkg_cmake_config_fixup()", you need to add the following to "dependencies" kmpkg.json:
#{
#    "name": "kmpkg-cmake-config",
#    "host": true
#}
# kmpkg_cmake_config_fixup()

# Uncomment the line below if necessary to install the license file for the port
# as a file named `copyright` to the directory `${CURRENT_PACKAGES_DIR}/share/${PORT}`
# kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
