if(KMPKG_TARGET_IS_WINDOWS)
    message("libbacktrace cannot be built using MSVC on Windows due to relying on the C++ unwind API https://itanium-cxx-abi.github.io/cxx-abi/abi-eh.html")
endif()

kmpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ianlancetaylor/libbacktrace
    REF 1db85642e3fca189cf4e076f840a45d6934b2456
    SHA512 a7f7a1233f551326e4ae1ba91db0fb905cf2737c20284c9aaf26cfe448b2a54efeaaa678e3abccbe0856c2a19019412208da7c1a82d319a58fe4d66d0a952aa0
)

kmpkg_configure_make(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTOCONFIG
)
kmpkg_install_make()
kmpkg_fixup_pkgconfig()

kmpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
