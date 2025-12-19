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
       KMPKG_CRT_LINKAGE KMPKG_TARGET_ARCHITECTURE
       KMPKG_C_FLAGS KMPKG_CXX_FLAGS
       KMPKG_C_FLAGS_DEBUG KMPKG_CXX_FLAGS_DEBUG
       KMPKG_C_FLAGS_RELEASE KMPKG_CXX_FLAGS_RELEASE
       KMPKG_LINKER_FLAGS KMPKG_LINKER_FLAGS_RELEASE KMPKG_LINKER_FLAGS_DEBUG
       KMPKG_PLATFORM_TOOLSET XBOX_CONSOLE_TARGET
    )

    set(CMAKE_SYSTEM_NAME Windows CACHE STRING "")

    if(KMPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set(CMAKE_SYSTEM_PROCESSOR AMD64 CACHE STRING "")
    else()
        message(FATAL_ERROR "Xbox requires x64 native target.")
    endif()

    if(DEFINED KMPKG_CMAKE_SYSTEM_VERSION)
        set(CMAKE_SYSTEM_VERSION "${KMPKG_CMAKE_SYSTEM_VERSION}" CACHE STRING "" FORCE)
    else()
        set(CMAKE_SYSTEM_VERSION "10.0" CACHE STRING "" FORCE)
    endif()

    set(CMAKE_CROSSCOMPILING ON CACHE STRING "")

    # Add the Microsoft GDK if present
    if (DEFINED ENV{GameDKCoreLatest})
        # October 2025 or later
        # No windows paths should be used for console targets.
    elseif (DEFINED ENV{GRDKLatest})
        # April 2025 or earlier
        cmake_path(SET _kmpkg_grdk "$ENV{GRDKLatest}")

        list(APPEND CMAKE_REQUIRED_INCLUDES "${_kmpkg_grdk}/gameKit/Include")
        include_directories(BEFORE SYSTEM "${_kmpkg_grdk}/gameKit/Include")
        cmake_path(CONVERT "${_kmpkg_grdk}/gameKit/Include" TO_NATIVE_PATH_LIST _kmpkg_inc NORMALIZE)

        link_directories(BEFORE "${_kmpkg_grdk}/gameKit/Lib/amd64")
        cmake_path(CONVERT "${_kmpkg_grdk}/gameKit/Lib/amd64" TO_NATIVE_PATH_LIST _kmpkg_lib NORMALIZE)
    endif()

    # Add the Microsoft GDK Xbox Extensions if present
    if (DEFINED ENV{GameDKXboxLatest})
        # October 2025 or later
        cmake_path(SET _kmpkg_gxdk "$ENV{GameDKXboxLatest}")

        if(XBOX_CONSOLE_TARGET STREQUAL "scarlett")
            list(APPEND CMAKE_REQUIRED_INCLUDES "${_kmpkg_gxdk}/xbox/include/gen9" "${_kmpkg_gxdk}/xbox/include")
            include_directories(BEFORE SYSTEM "${_kmpkg_gxdk}/xbox/include/gen9" "${_kmpkg_gxdk}/xbox/include")
            cmake_path(CONVERT "${_kmpkg_gxdk}/xbox/include/gen9;${_kmpkg_gxdk}/xbox/include" TO_NATIVE_PATH_LIST _kmpkg_inc NORMALIZE)

            link_directories(BEFORE "${_kmpkg_gxdk}/xbox/lib/gen9" "${_kmpkg_gxdk}/xbox/lib/x64")
            cmake_path(CONVERT "${_kmpkg_gxdk}/xbox/lib/gen9;${_kmpkg_gxdk}/xbox/lib/x64" TO_NATIVE_PATH_LIST _kmpkg_lib NORMALIZE)
        elseif(XBOX_CONSOLE_TARGET STREQUAL "xboxone")
            list(APPEND CMAKE_REQUIRED_INCLUDES "${_kmpkg_gxdk}/xbox/include/gen8" "${_kmpkg_gxdk}/xbox/include")
            include_directories(BEFORE SYSTEM "${_kmpkg_gxdk}/xbox/include/gen8" "${_kmpkg_gxdk}/xbox/include")
            cmake_path(CONVERT "${_kmpkg_gxdk}/xbox/include/gen8;${_kmpkg_gxdk}/xbox/include" TO_NATIVE_PATH_LIST _kmpkg_inc NORMALIZE)

            link_directories(BEFORE "${_kmpkg_gxdk}/xbox/lib/gen8" "${_kmpkg_gxdk}/xbox/lib/x64")
            cmake_path(CONVERT "${_kmpkg_gxdk}/xbox/lib/gen8;${_kmpkg_gxdk}/xbox/lib/x64" TO_NATIVE_PATH_LIST _kmpkg_lib NORMALIZE)
        endif()
    elseif (DEFINED ENV{GXDKLatest})
        # April 2025 or earlier
        cmake_path(SET _kmpkg_gxdk "$ENV{GXDKLatest}")

        if(XBOX_CONSOLE_TARGET STREQUAL "scarlett")
            list(APPEND CMAKE_REQUIRED_INCLUDES "${_kmpkg_gxdk}/gameKit/Include" "${_kmpkg_gxdk}/gameKit/Include/Scarlett")
            include_directories(BEFORE SYSTEM "${_kmpkg_gxdk}/gameKit/Include" "${_kmpkg_gxdk}/gameKit/Include/Scarlett")
            cmake_path(CONVERT "${_kmpkg_gxdk}/gameKit/Include;${_kmpkg_gxdk}/gameKit/Include/Scarlett" TO_NATIVE_PATH_LIST _kmpkg_inc NORMALIZE)

            link_directories(BEFORE "${_kmpkg_gxdk}/gameKit/Lib/amd64" "${_kmpkg_gxdk}/gameKit/Lib/amd64/Scarlett")
            cmake_path(CONVERT "${_kmpkg_gxdk}/gameKit/Lib/amd64;${_kmpkg_gxdk}/gameKit/Lib/amd64/Scarlett" TO_NATIVE_PATH_LIST _kmpkg_lib NORMALIZE)
        elseif(XBOX_CONSOLE_TARGET STREQUAL "xboxone")
            list(APPEND CMAKE_REQUIRED_INCLUDES "${_kmpkg_gxdk}/gameKit/Include" "${_kmpkg_gxdk}/gameKit/Include/XboxOne")
            include_directories(BEFORE SYSTEM "${_kmpkg_gxdk}/gameKit/Include" "${_kmpkg_gxdk}/gameKit/Include/XboxOne")
            cmake_path(CONVERT "${_kmpkg_gxdk}/gameKit/Include;${_kmpkg_gxdk}/gameKit/Include/XboxOne" TO_NATIVE_PATH_LIST _kmpkg_inc NORMALIZE)

            link_directories(BEFORE "${_kmpkg_gxdk}/gameKit/Lib/amd64" "${_kmpkg_gxdk}/gameKit/Lib/amd64/XboxOne")
            cmake_path(CONVERT "${_kmpkg_gxdk}/gameKit/Lib/amd64;${_kmpkg_gxdk}/gameKit/Lib/amd64/XboxOne" TO_NATIVE_PATH_LIST _kmpkg_lib NORMALIZE)
        endif()
    endif()

    if(DEFINED _kmpkg_inc)
        set(ENV{INCLUDE} "${_kmpkg_inc};$ENV{INCLUDE}")
        set(ENV{LIB} "${_kmpkg_lib};$ENV{LIB}")
    endif()

    unset(_kmpkg_inc)
    unset(_kmpkg_lib)

    set(_kmpkg_core_libs onecore_apiset.lib)
    set(_kmpkg_default_lib onecore_apiset.lib)

    set(MP_BUILD_FLAG "")
    if(NOT (CMAKE_CXX_COMPILER MATCHES "clang-cl.exe"))
        set(MP_BUILD_FLAG "/MP")
    endif()

    set(_kmpkg_cpp_flags "/nologo /DWIN32 /D_WINDOWS /D_UNICODE /DUNICODE /DWINAPI_FAMILY=WINAPI_FAMILY_GAMES /D_WIN32_WINNT=0x0A00 /D_ATL_NO_DEFAULT_LIBS /D__WRL_NO_DEFAULT_LIB__ /D__WRL_CLASSIC_COM_STRICT__ /D_UITHREADCTXT_SUPPORT=0 /D_CRT_USE_WINAPI_PARTITION_APP")
    set(_kmpkg_common_flags "/nologo /Z7 ${MP_BUILD_FLAG} /GS /Gd /W3 /WX- /Zc:wchar_t /Zc:inline /Zc:forScope /fp:precise /Oy- /EHsc /utf-8")

    # Add the Microsoft GDK if present
    if (DEFINED _kmpkg_grdk)
        string(APPEND _kmpkg_core_libs " xgameruntime.lib")
    endif()

    # Add the Microsoft GDK Xbox Extensions if present
    if (DEFINED _kmpkg_gxdk)
        if(XBOX_CONSOLE_TARGET STREQUAL "scarlett")
            string(APPEND _kmpkg_cpp_flags " /D_GAMING_XBOX /D_GAMING_XBOX_SCARLETT")

            set(_kmpkg_core_libs "xgameplatform.lib xgameruntime.lib")
            set(_kmpkg_default_lib xgameplatform.lib)
        elseif(XBOX_CONSOLE_TARGET STREQUAL "xboxone")
            string(APPEND _kmpkg_cpp_flags " /D_GAMING_XBOX /D_GAMING_XBOX_XBOXONE")

            set(_kmpkg_core_libs "xgameplatform.lib xgameruntime.lib")
            set(_kmpkg_default_lib xgameplatform.lib)
        endif()
    endif()

    set(CMAKE_C_STANDARD_LIBRARIES_INIT "${_kmpkg_core_libs}" CACHE INTERNAL "")
    set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "${_kmpkg_core_libs}" CACHE INTERNAL "")

    set(CMAKE_C_STANDARD_LIBRARIES ${CMAKE_C_STANDARD_LIBRARIES_INIT} CACHE STRING "" FORCE)
    set(CMAKE_CXX_STANDARD_LIBRARIES ${CMAKE_CXX_STANDARD_LIBRARIES_INIT} CACHE STRING "" FORCE)

    unset(_kmpkg_core_libs)

    if(KMPKG_CRT_LINKAGE STREQUAL "dynamic")
        set(KMPKG_CRT_LINK_FLAG_PREFIX "/MD")
    elseif(KMPKG_CRT_LINKAGE STREQUAL "static")
        set(KMPKG_CRT_LINK_FLAG_PREFIX "/MT")
    else()
        message(FATAL_ERROR "Invalid setting for KMPKG_CRT_LINKAGE: \"${KMPKG_CRT_LINKAGE}\". It must be \"static\" or \"dynamic\"")
    endif()

    if(XBOX_CONSOLE_TARGET STREQUAL "scarlett")
        string(APPEND _kmpkg_common_flags " /favor:AMD64 /arch:AVX2")
    elseif(XBOX_CONSOLE_TARGET STREQUAL "xboxone")
        string(APPEND _kmpkg_common_flags " /favor:AMD64 /arch:AVX")
    endif()

    set(CMAKE_CXX_FLAGS "${_kmpkg_cpp_flags} ${_kmpkg_common_flags} ${KMPKG_CXX_FLAGS}" CACHE STRING "")
    set(CMAKE_C_FLAGS "${_kmpkg_cpp_flags} ${_kmpkg_common_flags} ${KMPKG_C_FLAGS}" CACHE STRING "")
    set(CMAKE_RC_FLAGS "-c65001 ${_kmpkg_cpp_flags}" CACHE STRING "")

    unset(_kmpkg_cpp_flags)
    unset(_kmpkg_common_flags)

    set(CMAKE_CXX_FLAGS_DEBUG "${KMPKG_CRT_LINK_FLAG_PREFIX}d /Od /RTC1 ${KMPKG_CXX_FLAGS_DEBUG}" CACHE STRING "")
    set(CMAKE_C_FLAGS_DEBUG "${KMPKG_CRT_LINK_FLAG_PREFIX}d /Od /RTC1 ${KMPKG_C_FLAGS_DEBUG}" CACHE STRING "")

    set(CMAKE_CXX_FLAGS_RELEASE "${KMPKG_CRT_LINK_FLAG_PREFIX} /O2 /Oi /Gy /DNDEBUG ${KMPKG_CXX_FLAGS_RELEASE}" CACHE STRING "")
    set(CMAKE_C_FLAGS_RELEASE "${KMPKG_CRT_LINK_FLAG_PREFIX} /O2 /Oi /Gy /DNDEBUG ${KMPKG_C_FLAGS_RELEASE}" CACHE STRING "")

    # oldnames.lib is not in this list as many open source libraries still rely on the older non-compliant POSIX function names.
    set(_kmpkg_unsupported advapi32.lib comctl32.lib comsupp.lib dbghelp.lib gdi32.lib gdiplus.lib guardcfw.lib mmc.lib msimg32.lib msvcole.lib msvcoled.lib mswsock.lib ntstrsafe.lib ole2.lib ole2autd.lib ole2auto.lib ole2d.lib ole2ui.lib ole2uid.lib ole32.lib oleacc.lib oleaut32.lib oledlg.lib oledlgd.lib runtimeobject.lib shell32.lib shlwapi.lib strsafe.lib urlmon.lib user32.lib userenv.lib wlmole.lib wlmoled.lib onecore.lib)
    set (_kmpkg_nodefaultlib "/NODEFAULTLIB:kernel32.lib")
    foreach(arg ${_kmpkg_unsupported})
    string(APPEND _kmpkg_nodefaultlib " /NODEFAULTLIB:${arg}")
    endforeach()

    # Some upstream projects don't respect STANDARD_LIBRARIES_INIT and rely on default libs instead.
    set(_kmpkg_common_lflags "/MANIFEST:NO /NXCOMPAT /DYNAMICBASE /DEBUG /MANIFESTUAC:NO /SUBSYSTEM:WINDOWS,10.0 /DEFAULTLIB:${_kmpkg_default_lib}")

    string(APPEND CMAKE_MODULE_LINKER_FLAGS " ${_kmpkg_common_lflags} ${KMPKG_LINKER_FLAGS} ${_kmpkg_nodefaultlib}")
    string(APPEND CMAKE_SHARED_LINKER_FLAGS " ${_kmpkg_common_lflags} ${KMPKG_LINKER_FLAGS} ${_kmpkg_nodefaultlib}")
    string(APPEND CMAKE_EXE_LINKER_FLAGS " ${_kmpkg_common_lflags} ${KMPKG_LINKER_FLAGS} ${_kmpkg_nodefaultlib}")

    string(APPEND CMAKE_STATIC_LINKER_FLAGS_RELEASE_INIT " /nologo ")
    set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "/nologo /DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${_kmpkg_common_lflags} ${KMPKG_LINKER_FLAGS} ${KMPKG_LINKER_FLAGS_RELEASE} ${_kmpkg_nodefaultlib}" CACHE STRING "")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "/nologo /DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${_kmpkg_common_lflags} ${KMPKG_LINKER_FLAGS} ${KMPKG_LINKER_FLAGS_RELEASE} ${_kmpkg_nodefaultlib}" CACHE STRING "")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "/nologo /DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${_kmpkg_common_lflags} ${KMPKG_LINKER_FLAGS} ${KMPKG_LINKER_FLAGS_RELEASE} ${_kmpkg_nodefaultlib}" CACHE STRING "")

    string(APPEND CMAKE_STATIC_LINKER_FLAGS_DEBUG_INIT " /nologo ")
    string(APPEND CMAKE_MODULE_LINKER_FLAGS_DEBUG_INIT " /nologo ${KMPKG_LINKER_FLAGS} ${KMPKG_LINKER_FLAGS_DEBUG} ")
    string(APPEND CMAKE_SHARED_LINKER_FLAGS_DEBUG_INIT " /nologo ${KMPKG_LINKER_FLAGS} ${KMPKG_LINKER_FLAGS_DEBUG} ")
    string(APPEND CMAKE_EXE_LINKER_FLAGS_DEBUG_INIT " /nologo ${KMPKG_LINKER_FLAGS} ${KMPKG_LINKER_FLAGS_DEBUG} ")

    unset(_kmpkg_unsupported)
    unset(_kmpkg_nodefaultlib)
    unset(_kmpkg_default_lib)
    unset(_kmpkg_common_lflags)
    unset(_kmpkg_grdk)
    unset(_kmpkg_gxdk)
    unset(MP_BUILD_FLAG)
    unset(KMPKG_CRT_LINK_FLAG_PREFIX)
endif()
