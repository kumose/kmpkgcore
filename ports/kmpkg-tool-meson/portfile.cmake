# This port represents a dependency on the Meson build system.
# In the future, it is expected that this port acquires and installs Meson.
# Currently is used in ports that call kmpkg_find_acquire_program(MESON) in order to force rebuilds.

set(KMPKG_POLICY_CMAKE_HELPER_PORT enabled)

set(patches
  meson-intl.patch
  adjust-python-dep.patch
  adjust-args.patch
  remove-pkgconfig-specialization.patch
  meson-56879d5.diff  # Remove with 1.9.1
)
set(scripts
  kmpkg-port-config.cmake
  kmpkg_configure_meson.cmake
  kmpkg_install_meson.cmake
  meson.template.in
)
set(to_hash 
  "${CMAKE_CURRENT_LIST_DIR}/kmpkg.json"
  "${CMAKE_CURRENT_LIST_DIR}/portfile.cmake"
)
foreach(file IN LISTS patches scripts)
  set(filepath  "${CMAKE_CURRENT_LIST_DIR}/${file}")
  list(APPEND to_hash "${filepath}")
  file(COPY "${filepath}" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
endforeach()

set(meson_path_hash "")
foreach(filepath IN LISTS to_hash)
  file(SHA1 "${filepath}" to_append)
  string(APPEND meson_path_hash "${to_append}")
endforeach()
string(SHA512 meson_path_hash "${meson_path_hash}")

string(SUBSTRING "${meson_path_hash}" 0 6 MESON_SHORT_HASH)
list(TRANSFORM patches REPLACE [[^(..*)$]] [["${CMAKE_CURRENT_LIST_DIR}/\0"]])
list(JOIN patches "\n            " PATCHES)
configure_file("${CMAKE_CURRENT_LIST_DIR}/kmpkg-port-config.cmake" "${CURRENT_PACKAGES_DIR}/share/${PORT}/kmpkg-port-config.cmake" @ONLY)

kmpkg_install_copyright(FILE_LIST "${KMPKG_ROOT_DIR}/LICENSE.txt")

include("${CURRENT_PACKAGES_DIR}/share/${PORT}/kmpkg-port-config.cmake")
