function(kmpkg_build_msbuild)
    cmake_parse_arguments(
        PARSE_ARGV 0
        arg
        "USE_KMPKG_INTEGRATION"
        "PROJECT_PATH;RELEASE_CONFIGURATION;DEBUG_CONFIGURATION;PLATFORM;PLATFORM_TOOLSET;TARGET_PLATFORM_VERSION;TARGET"
        "OPTIONS;OPTIONS_RELEASE;OPTIONS_DEBUG"
    )

    if(DEFINED arg_UNPARSED_ARGUMENTS)
        message(WARNING "kmpkg_build_msbuild was passed extra arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT DEFINED arg_RELEASE_CONFIGURATION)
        set(arg_RELEASE_CONFIGURATION Release)
    endif()
    if(NOT DEFINED arg_DEBUG_CONFIGURATION)
        set(arg_DEBUG_CONFIGURATION Debug)
    endif()
    if(NOT DEFINED arg_PLATFORM)
        set(arg_PLATFORM "${TRIPLET_SYSTEM_ARCH}")
    endif()
    if(NOT DEFINED arg_PLATFORM_TOOLSET)
        set(arg_PLATFORM_TOOLSET "${KMPKG_PLATFORM_TOOLSET}")
    endif()
    if(NOT DEFINED arg_TARGET_PLATFORM_VERSION)
        kmpkg_get_windows_sdk(arg_TARGET_PLATFORM_VERSION)
    endif()
    if(NOT DEFINED arg_TARGET)
        set(arg_TARGET Rebuild)
    endif()

    list(APPEND arg_OPTIONS
        "/t:${arg_TARGET}"
        "/p:Platform=${arg_PLATFORM}"
        "/p:PlatformToolset=${arg_PLATFORM_TOOLSET}"
        "/p:KMPkgLocalAppDataDisabled=true"
        "/p:UseIntelMKL=No"
        "/p:WindowsTargetPlatformVersion=${arg_TARGET_PLATFORM_VERSION}"
        "/p:KmpkgManifestInstall=false"
        "/p:KmpkgManifestEnabled=false"
        "/m"
    )

    if(KMPKG_LIBRARY_LINKAGE STREQUAL "static")
        # Disable LTCG for static libraries because this setting introduces ABI incompatibility between minor compiler versions
        # TODO: Add a way for the user to override this if they want to opt-in to incompatibility
        list(APPEND arg_OPTIONS "/p:WholeProgramOptimization=false")
    endif()

    if(arg_USE_KMPKG_INTEGRATION)
        list(
            APPEND arg_OPTIONS
            "/p:ForceImportBeforeCppTargets=${SCRIPTS}/buildsystems/msbuild/kmpkg.targets"
            "/p:KmpkgTriplet=${TARGET_TRIPLET}"
            "/p:KmpkgInstalledDir=${_KMPKG_INSTALLED_DIR}"
        )
    else()
        list(APPEND arg_OPTIONS "/p:KmpkgEnabled=false")
    endif()

    if(NOT DEFINED KMPKG_BUILD_TYPE OR KMPKG_BUILD_TYPE STREQUAL "release")
        message(STATUS "Building ${arg_PROJECT_PATH} for Release")
        file(MAKE_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel")
        kmpkg_execute_required_process(
            COMMAND msbuild "${arg_PROJECT_PATH}"
                "/p:Configuration=${arg_RELEASE_CONFIGURATION}"
                ${arg_OPTIONS}
                ${arg_OPTIONS_RELEASE}
            WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel"
            LOGNAME "build-${TARGET_TRIPLET}-rel"
        )
    endif()

    if(NOT DEFINED KMPKG_BUILD_TYPE OR KMPKG_BUILD_TYPE STREQUAL "debug")
        message(STATUS "Building ${arg_PROJECT_PATH} for Debug")
        file(MAKE_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg")
        kmpkg_execute_required_process(
            COMMAND msbuild "${arg_PROJECT_PATH}"
                "/p:Configuration=${arg_DEBUG_CONFIGURATION}"
                ${arg_OPTIONS}
                ${arg_OPTIONS_DEBUG}
            WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg"
            LOGNAME "build-${TARGET_TRIPLET}-dbg"
        )
    endif()
endfunction()
