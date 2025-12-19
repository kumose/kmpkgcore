if(NOT _KMPKG_WINDOWS_TOOLCHAIN)
    set(_KMPKG_WINDOWS_TOOLCHAIN 1)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>$<$<STREQUAL:${KMPKG_CRT_LINKAGE},dynamic>:DLL>" CACHE STRING "")
    set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "")

    if(POLICY CMP0056)
        cmake_policy(SET CMP0056 NEW)
    endif()
    if(POLICY CMP0066)
        cmake_policy(SET CMP0066 NEW)
    endif()
    if(POLICY CMP0067)
        cmake_policy(SET CMP0067 NEW)
    endif()
    if(POLICY CMP0137)
        cmake_policy(SET CMP0137 NEW)
    endif()
    list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
        KMPKG_CRT_LINKAGE KMPKG_TARGET_ARCHITECTURE KMPKG_SET_CHARSET_FLAG
        KMPKG_C_FLAGS KMPKG_CXX_FLAGS
        KMPKG_C_FLAGS_DEBUG KMPKG_CXX_FLAGS_DEBUG
        KMPKG_C_FLAGS_RELEASE KMPKG_CXX_FLAGS_RELEASE
        KMPKG_LINKER_FLAGS KMPKG_LINKER_FLAGS_RELEASE KMPKG_LINKER_FLAGS_DEBUG
        KMPKG_PLATFORM_TOOLSET
    )

    set(CMAKE_SYSTEM_NAME WindowsStore CACHE STRING "")

    if(KMPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        set(CMAKE_SYSTEM_PROCESSOR x86 CACHE STRING "")
    elseif(KMPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(CMAKE_SYSTEM_PROCESSOR AMD64 CACHE STRING "")
    elseif(KMPKG_TARGET_ARCHITECTURE STREQUAL "arm")
        set(CMAKE_SYSTEM_PROCESSOR ARM CACHE STRING "")
    elseif(KMPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set(CMAKE_SYSTEM_PROCESSOR ARM64 CACHE STRING "")
    endif()

    if(DEFINED KMPKG_CMAKE_SYSTEM_VERSION)
        set(CMAKE_SYSTEM_VERSION "${KMPKG_CMAKE_SYSTEM_VERSION}" CACHE STRING "" FORCE)
    endif()

    set(CMAKE_CROSSCOMPILING ON CACHE STRING "")

    if(NOT DEFINED CMAKE_SYSTEM_VERSION)
        set(CMAKE_SYSTEM_VERSION "${CMAKE_HOST_SYSTEM_VERSION}" CACHE STRING "")
    endif()

    if(NOT (DEFINED KMPKG_MSVC_CXX_WINRT_EXTENSIONS))
        set(KMPKG_MSVC_CXX_WINRT_EXTENSIONS ON)
    endif()

    if(KMPKG_CRT_LINKAGE STREQUAL "dynamic")
        set(KMPKG_CRT_LINK_FLAG_PREFIX "/MD")
    elseif(KMPKG_CRT_LINKAGE STREQUAL "static")
        set(KMPKG_CRT_LINK_FLAG_PREFIX "/MT")
    else()
        message(FATAL_ERROR "Invalid setting for KMPKG_CRT_LINKAGE: \"${KMPKG_CRT_LINKAGE}\". It must be \"static\" or \"dynamic\"")
    endif()

    set(CHARSET_FLAG "/utf-8")
    if (NOT KMPKG_SET_CHARSET_FLAG OR KMPKG_PLATFORM_TOOLSET MATCHES "v120")
        # VS 2013 does not support /utf-8
        set(CHARSET_FLAG "")
    endif()

    set(MP_BUILD_FLAG "")
    if(NOT (CMAKE_CXX_COMPILER MATCHES "clang-cl.exe"))
        set(MP_BUILD_FLAG "/MP ")
    endif()

    set(_kmpkg_cpp_flags "/DWIN32 /D_WINDOWS /D_UNICODE /DUNICODE /DWINAPI_FAMILY=WINAPI_FAMILY_APP /D__WRL_NO_DEFAULT_LIB__" ) # VS adds /D "_WINDLL" for DLLs;
    set(_kmpkg_common_flags "/nologo /Z7 ${MP_BUILD_FLAG}/GS /Gd /Gm- /W3 /WX- /Zc:wchar_t /Zc:inline /Zc:forScope /fp:precise /Oy- /EHsc")
    #/ZW:nostdlib -> ZW is added by CMake # VS also normally adds /sdl but not cmake MSBUILD
    set(_kmpkg_winmd_flag "")
    if(KMPKG_MSVC_CXX_WINRT_EXTENSIONS)
        file(TO_CMAKE_PATH "$ENV{VCToolsInstallDir}" _kmpkg_vctools)
        set(ENV{_CL_} "/FU\"${_kmpkg_vctools}/lib/x86/store/references/platform.winmd\" $ENV{_CL_}")
        # CMake has problems to correctly pass this in the compiler test so probably need special care in get_cmake_vars
        #set(_kmpkg_winmd_flag "/FU\\\\\"${_kmpkg_vctools}/lib/x86/store/references/platform.winmd\\\\\"") # VS normally passes /ZW for Apps
    endif()

    set(CMAKE_CXX_FLAGS "${_kmpkg_cpp_flags} ${_kmpkg_common_flags} ${_kmpkg_winmd_flag} ${CHARSET_FLAG} ${KMPKG_CXX_FLAGS}" CACHE STRING "")
    set(CMAKE_C_FLAGS "${_kmpkg_cpp_flags} ${_kmpkg_common_flags} ${_kmpkg_winmd_flag} ${CHARSET_FLAG} ${KMPKG_C_FLAGS}" CACHE STRING "")
    set(CMAKE_RC_FLAGS "-c65001 ${_kmpkg_cpp_flags}" CACHE STRING "")

    unset(CHARSET_FLAG)
    unset(MP_BUILD_FLAG)
    unset(_kmpkg_cpp_flags)
    unset(_kmpkg_common_flags)
    unset(_kmpkg_winmd_flag)

    set(CMAKE_CXX_FLAGS_DEBUG "${KMPKG_CRT_LINK_FLAG_PREFIX}d /Od /RTC1 ${KMPKG_CXX_FLAGS_DEBUG}" CACHE STRING "")
    set(CMAKE_C_FLAGS_DEBUG "${KMPKG_CRT_LINK_FLAG_PREFIX}d /Od /RTC1 ${KMPKG_C_FLAGS_DEBUG}" CACHE STRING "")

    set(CMAKE_CXX_FLAGS_RELEASE "${KMPKG_CRT_LINK_FLAG_PREFIX} /O2 /Oi /Gy /DNDEBUG ${KMPKG_CXX_FLAGS_RELEASE}" CACHE STRING "") # VS adds /GL
    set(CMAKE_C_FLAGS_RELEASE "${KMPKG_CRT_LINK_FLAG_PREFIX} /O2 /Oi /Gy /DNDEBUG ${KMPKG_C_FLAGS_RELEASE}" CACHE STRING "")

    string(APPEND CMAKE_STATIC_LINKER_FLAGS_RELEASE_INIT " /nologo ") # VS adds /LTCG

    if(KMPKG_MSVC_CXX_WINRT_EXTENSIONS)
        set(additional_dll_flags "/WINMD:NO ")
        if(CMAKE_GENERATOR MATCHES "Ninja")
            set(additional_exe_flags "/WINMD ") # VS Generator chokes on this in the compiler detection
        endif()
    endif()
    string(APPEND CMAKE_MODULE_LINKER_FLAGS " /MANIFEST:NO /NXCOMPAT /DYNAMICBASE /DEBUG ${additional_dll_flags}/APPCONTAINER /SUBSYSTEM:CONSOLE /MANIFESTUAC:NO ${KMPKG_LINKER_FLAGS}")
    string(APPEND CMAKE_SHARED_LINKER_FLAGS " /MANIFEST:NO /NXCOMPAT /DYNAMICBASE /DEBUG ${additional_dll_flags}/APPCONTAINER /SUBSYSTEM:CONSOLE /MANIFESTUAC:NO ${KMPKG_LINKER_FLAGS}")
    # VS adds /DEBUG:FULL /TLBID:1.    WindowsApp.lib is in CMAKE_C|CXX_STANDARD_LIBRARIES
    string(APPEND CMAKE_EXE_LINKER_FLAGS " /MANIFEST:NO /NXCOMPAT /DYNAMICBASE /DEBUG ${additional_exe_flags}/APPCONTAINER /MANIFESTUAC:NO ${KMPKG_LINKER_FLAGS}")

    set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "/DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${KMPKG_LINKER_FLAGS_RELEASE}" CACHE STRING "") # VS uses /LTCG:incremental
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "/DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${KMPKG_LINKER_FLAGS_RELEASE}" CACHE STRING "") # VS uses /LTCG:incremental
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "/DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${KMPKG_LINKER_FLAGS_RELEASE}" CACHE STRING "")
    string(APPEND CMAKE_STATIC_LINKER_FLAGS_DEBUG_INIT " /nologo ")
    string(APPEND CMAKE_MODULE_LINKER_FLAGS_DEBUG_INIT " /nologo ")
    string(APPEND CMAKE_SHARED_LINKER_FLAGS_DEBUG_INIT " /nologo ")
    string(APPEND CMAKE_EXE_LINKER_FLAGS_DEBUG_INIT " /nologo ${KMPKG_LINKER_FLAGS} ${KMPKG_LINKER_FLAGS_DEBUG} ")
endif()
