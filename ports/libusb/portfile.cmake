if("udev" IN_LIST FEATURES)
    message("${PORT} currently requires the following tools and libraries from the system package manager:\n    libudev\n\nThese can be installed on Ubuntu systems via apt-get install libudev-dev")
endif()

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO libusb/libusb
    REF "v${VERSION}"
    SHA512 98c5f7940ff06b25c9aa65aa98e23de4c79a4c1067595f4c73cc145af23a1c286639e1ba11185cd91bab702081f307b973f08a4c9746576dc8d01b3620a3aeb5
    HEAD_REF master
)

if(KMPKG_TARGET_IS_WINDOWS AND NOT KMPKG_TARGET_IS_MINGW)

  if(KMPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
      set(LIBUSB_PROJECT_TYPE dll)
  else()
      set(LIBUSB_PROJECT_TYPE static)
  endif()

  # The README.md file in the archive is a symlink to README
  # which causes issues with the windows MSBUILD process
  file(REMOVE "${SOURCE_PATH}/README.md")

  kmpkg_msbuild_install(
      SOURCE_PATH "${SOURCE_PATH}"
      PROJECT_SUBPATH msvc/libusb_${LIBUSB_PROJECT_TYPE}.vcxproj
  )

  file(INSTALL "${SOURCE_PATH}/libusb/libusb.h"  DESTINATION "${CURRENT_PACKAGES_DIR}/include/libusb-1.0")
  set(prefix "")
  set(exec_prefix [[${prefix}]])
  set(libdir [[${prefix}/lib]])
  set(includedir [[${prefix}/include]])  
  configure_file("${SOURCE_PATH}/libusb-1.0.pc.in" "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libusb-1.0.pc" @ONLY)
  kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libusb-1.0.pc" " -lusb-1.0" " -llibusb-1.0")
  if(NOT KMPKG_BUILD_TYPE)
      set(includedir [[${prefix}/../include]])  
      configure_file("${SOURCE_PATH}/libusb-1.0.pc.in" "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libusb-1.0.pc" @ONLY)
      kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libusb-1.0.pc" " -lusb-1.0" " -llibusb-1.0")
  endif()
else()
    kmpkg_list(SET MAKE_OPTIONS)
    kmpkg_list(SET LIBUSB_LINK_LIBRARIES)
    if("udev" IN_LIST FEATURES)
        kmpkg_list(APPEND MAKE_OPTIONS "--enable-udev")
        kmpkg_list(APPEND LIBUSB_LINK_LIBRARIES udev)
    else()
        kmpkg_list(APPEND MAKE_OPTIONS "--disable-udev")
    endif()
    kmpkg_make_configure(
        SOURCE_PATH "${SOURCE_PATH}"
        AUTORECONF
        OPTIONS 
            ${MAKE_OPTIONS}
            "--enable-examples-build=no"
            "--enable-tests-build=no"
    )
    kmpkg_make_install()
endif()

kmpkg_fixup_pkgconfig()

# -Wl,-framework,... is poorly handled in CMake
kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/lib/pkgconfig/libusb-1.0.pc" " -Wl,-framework," " -framework " IGNORE_UNCHANGED)
if(NOT KMPKG_BUILD_TYPE)
    kmpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/libusb-1.0.pc" " -Wl,-framework," " -framework " IGNORE_UNCHANGED)
endif()

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
