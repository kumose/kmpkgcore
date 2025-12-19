set(KMPKG_POLICY_CMAKE_HELPER_PORT enabled)

set(automake_version 1.17)
kmpkg_download_distfile(ARCHIVE
    URLS "https://ftpmirror.gnu.org/gnu/automake/automake-${automake_version}.tar.gz"
         "https://ftp.gnu.org/gnu/automake/automake-${automake_version}.tar.gz"
         "https://www.mirrorservice.org/sites/ftp.gnu.org/gnu/automake/automake-${automake_version}.tar.gz"
    FILENAME "automake-${automake_version}.tar.gz"
    SHA512 11357dfab8cbf4b5d94d9d06e475732ca01df82bef1284888a34bd558afc37b1a239bed1b5eb18a9dbcc326344fb7b1b301f77bb8385131eb8e1e118b677883a
)

kmpkg_extract_source_archive(
    automake_source
    ARCHIVE "${ARCHIVE}"
)

file(COPY
        "${CMAKE_CURRENT_LIST_DIR}/configure.ac"
        "${CMAKE_CURRENT_LIST_DIR}/kmpkg_make_common.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/kmpkg_make_configure.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/kmpkg_make_install.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/kmpkg_make.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/kmpkg_scripts.cmake"
        "${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake"
    DESTINATION
        "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)

file(COPY
        "${automake_source}/lib/ar-lib"
        "${automake_source}/lib/compile"
        "${CMAKE_CURRENT_LIST_DIR}/wrappers/"
    DESTINATION
        "${CURRENT_PACKAGES_DIR}/share/${PORT}/wrappers"
)

kmpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")
include("${CURRENT_PORT_DIR}/kmpkg_scripts.cmake")
include("${CURRENT_PORT_DIR}/kmpkg_make.cmake")
cmake_path(GET KMPKG_DETECTED_CMAKE_C_COMPILER FILENAME compiler_name)
z_kmpkg_make_determine_target_triplet(build_opt_triplet COMPILER_NAME "${compiler_name}")
set(build_opt_source "kmpkg")
if(NOT build_opt_triplet)
    set(ENV{CC_FOR_BUILD} "${KMPKG_DETECTED_CMAKE_C_COMPILER}")
    kmpkg_execute_required_process(
        COMMAND "sh" -c "${automake_source}/lib/config.guess"
        OUTPUT_VARIABLE build_opt_triplet
        OUTPUT_STRIP_TRAILING_WHITESPACE
        WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}"
        LOGNAME "config-guess-${TARGET_TRIPLET}"
    )
    if(NOT build_opt_triplet)
        message("${Z_KMPKG_BACKCOMPAT_MESSAGE_LEVEL}"
            "Unknown autotools triplet for kmpkg ${TARGET_TRIPLET} triplet. "
            "You may need to define KMPKG_MAKE_BUILD_TRIPLET in the triplet file."
        )
    endif()
    set(build_opt_source "config.guess")
endif()
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/build_opt_triplet.txt" "${build_opt_triplet}\n")
message(STATUS "${TARGET_TRIPLET} autotools triplet: ${build_opt_triplet} (from ${build_opt_source})")

kmpkg_install_copyright(
    COMMENT [[
The cmake scripts are under kmpkg's MIT license terms, see LICENSE.txt below.
The port also installs shell scripts from GNU Automake.
These scripts are under GPL-2.0-or-later, see COPYING below.
]]
    FILE_LIST
        "${KMPKG_ROOT_DIR}/LICENSE.txt"
        "${automake_source}/COPYING"
)
