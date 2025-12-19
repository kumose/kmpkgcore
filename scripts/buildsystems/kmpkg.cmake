# Mark variables as used so cmake doesn't complain about them
mark_as_advanced(CMAKE_TOOLCHAIN_FILE)

# NOTE: to figure out what cmake versions are required for different things,
# grep for `CMake 3`. All version requirement comments should follow that format.

# Attention: Changes to this file do not affect ABI hashing.

#[===[.md:
# z_kmpkg_add_fatal_error
Add a fatal error.

```cmake
z_kmpkg_add_fatal_error(<message>...)
```

We use this system, instead of `message(FATAL_ERROR)`,
since cmake prints a lot of nonsense if the toolchain errors out before it's found the build tools.

This `Z_KMPKG_HAS_FATAL_ERROR` must be checked before any filesystem operations are done,
since otherwise you might be doing something with bad variables set up.
#]===]
# this is defined above everything else so that it can be used.
set(Z_KMPKG_FATAL_ERROR)
set(Z_KMPKG_HAS_FATAL_ERROR OFF)
function(z_kmpkg_add_fatal_error ERROR)
    if(NOT Z_KMPKG_HAS_FATAL_ERROR)
        set(Z_KMPKG_HAS_FATAL_ERROR ON PARENT_SCOPE)
        set(Z_KMPKG_FATAL_ERROR "${ERROR}" PARENT_SCOPE)
    else()
        string(APPEND Z_KMPKG_FATAL_ERROR "\n${ERROR}")
    endif()
endfunction()

set(Z_KMPKG_CMAKE_REQUIRED_MINIMUM_VERSION "3.7.2")
if(CMAKE_VERSION VERSION_LESS Z_KMPKG_CMAKE_REQUIRED_MINIMUM_VERSION)
    message(FATAL_ERROR "kmpkg.cmake requires at least CMake ${Z_KMPKG_CMAKE_REQUIRED_MINIMUM_VERSION}.")
endif()
cmake_policy(PUSH)
cmake_policy(VERSION 3.16)

include(CMakeDependentOption)

# KMPKG toolchain options.
option(KMPKG_VERBOSE "Enables messages from the KMPKG toolchain for debugging purposes." OFF)
mark_as_advanced(KMPKG_VERBOSE)

option(KMPKG_APPLOCAL_DEPS "Automatically copy dependencies into the output directory for executables." ON)
option(X_KMPKG_APPLOCAL_DEPS_SERIALIZED "(experimental) Add USES_TERMINAL to KMPKG_APPLOCAL_DEPS to force serialization." OFF)

# requires CMake 3.14
option(X_KMPKG_APPLOCAL_DEPS_INSTALL "(experimental) Automatically copy dependencies into the install target directory for executables. Requires CMake 3.14." OFF)
option(KMPKG_PREFER_SYSTEM_LIBS "Appends the kmpkg paths to CMAKE_PREFIX_PATH, CMAKE_LIBRARY_PATH and CMAKE_FIND_ROOT_PATH so that kmpkg libraries/packages are found after toolchain/system libraries/packages." OFF)
if(KMPKG_PREFER_SYSTEM_LIBS)
    message(WARNING "KMPKG_PREFER_SYSTEM_LIBS has been deprecated. Use empty overlay ports instead.")
endif()

# Manifest options and settings
set(Z_KMPKG_MANIFEST_DIR_INITIAL_VALUE "${KMPKG_MANIFEST_DIR}")
if(NOT DEFINED KMPKG_MANIFEST_DIR)
    if(EXISTS "${CMAKE_SOURCE_DIR}/kmpkg.json")
        set(Z_KMPKG_MANIFEST_DIR_INITIAL_VALUE "${CMAKE_SOURCE_DIR}")
    endif()
endif()
set(KMPKG_MANIFEST_DIR "${Z_KMPKG_MANIFEST_DIR_INITIAL_VALUE}"
    CACHE PATH "The path to the kmpkg manifest directory." FORCE)

if(DEFINED KMPKG_MANIFEST_DIR AND NOT KMPKG_MANIFEST_DIR STREQUAL "")
    set(Z_KMPKG_HAS_MANIFEST_DIR ON)
else()
    set(Z_KMPKG_HAS_MANIFEST_DIR OFF)
endif()

option(KMPKG_MANIFEST_MODE "Use manifest mode, as opposed to classic mode." "${Z_KMPKG_HAS_MANIFEST_DIR}")

if(KMPKG_MANIFEST_MODE AND NOT Z_KMPKG_HAS_MANIFEST_DIR)
    z_kmpkg_add_fatal_error(
"kmpkg manifest mode was enabled, but we couldn't find a manifest file (kmpkg.json)
in the current source directory (${CMAKE_CURRENT_SOURCE_DIR}).
Please add a manifest, or disable manifests by turning off KMPKG_MANIFEST_MODE."
    )
endif()

if(NOT DEFINED CACHE{Z_KMPKG_CHECK_MANIFEST_MODE})
    set(Z_KMPKG_CHECK_MANIFEST_MODE "${KMPKG_MANIFEST_MODE}"
        CACHE INTERNAL "Making sure KMPKG_MANIFEST_MODE doesn't change")
endif()

if(NOT KMPKG_MANIFEST_MODE AND Z_KMPKG_CHECK_MANIFEST_MODE)
    z_kmpkg_add_fatal_error([[
kmpkg manifest mode was disabled for a build directory where it was initially enabled.
This is not supported. Please delete the build directory and reconfigure.
]])
elseif(KMPKG_MANIFEST_MODE AND NOT Z_KMPKG_CHECK_MANIFEST_MODE)
    z_kmpkg_add_fatal_error([[
kmpkg manifest mode was enabled for a build directory where it was initially disabled.
This is not supported. Please delete the build directory and reconfigure.
]])
endif()

CMAKE_DEPENDENT_OPTION(KMPKG_MANIFEST_INSTALL [[
Install the dependencies listed in your manifest:
    If this is off, you will have to manually install your dependencies.
    See https://github.com/microsoft/kmpkg/tree/master/docs/specifications/manifests.md for more info.
]]
    ON
    "KMPKG_MANIFEST_MODE"
    OFF)

if(KMPKG_MANIFEST_INSTALL)
    set(KMPKG_BOOTSTRAP_OPTIONS "${KMPKG_BOOTSTRAP_OPTIONS}" CACHE STRING "Additional options to bootstrap kmpkg" FORCE)
    set(KMPKG_OVERLAY_PORTS "${KMPKG_OVERLAY_PORTS}" CACHE STRING "Overlay ports to use for kmpkg install in manifest mode" FORCE)
    set(KMPKG_OVERLAY_TRIPLETS "${KMPKG_OVERLAY_TRIPLETS}" CACHE STRING "Overlay triplets to use for kmpkg install in manifest mode" FORCE)
    set(KMPKG_INSTALL_OPTIONS "${KMPKG_INSTALL_OPTIONS}" CACHE STRING "Additional install options to pass to kmpkg" FORCE)
    set(Z_KMPKG_UNUSED KMPKG_BOOTSTRAP_OPTIONS)
    set(Z_KMPKG_UNUSED KMPKG_OVERLAY_PORTS)
    set(Z_KMPKG_UNUSED KMPKG_OVERLAY_TRIPLETS)
    set(Z_KMPKG_UNUSED KMPKG_INSTALL_OPTIONS)
endif()

# CMake helper utilities

#[===[.md:
# z_kmpkg_function_arguments

Get a list of the arguments which were passed in.
Unlike `ARGV`, which is simply the arguments joined with `;`,
so that `(A B)` is not distinguishable from `("A;B")`,
this macro gives `"A;B"` for the first argument list,
and `"A\;B"` for the second.

```cmake
z_kmpkg_function_arguments(<out-var> [<N>])
```

`z_kmpkg_function_arguments` gets the arguments between `ARGV<N>` and the last argument.
`<N>` defaults to `0`, so that all arguments are taken.

## Example:
```cmake
function(foo_replacement)
    z_kmpkg_function_arguments(ARGS)
    foo(${ARGS})
    ...
endfunction()
```
#]===]

# NOTE: this function definition is copied directly from scripts/cmake/z_kmpkg_function_arguments.cmake
# do not make changes here without making the same change there.
macro(z_kmpkg_function_arguments OUT_VAR)
    if("${ARGC}" EQUAL "1")
        set(z_kmpkg_function_arguments_FIRST_ARG "0")
    elseif("${ARGC}" EQUAL "2")
        set(z_kmpkg_function_arguments_FIRST_ARG "${ARGV1}")
    else()
        # kmpkg bug
        message(FATAL_ERROR "z_kmpkg_function_arguments: invalid arguments (${ARGV})")
    endif()

    set("${OUT_VAR}" "")

    # this allows us to get the value of the enclosing function's ARGC
    set(z_kmpkg_function_arguments_ARGC_NAME "ARGC")
    set(z_kmpkg_function_arguments_ARGC "${${z_kmpkg_function_arguments_ARGC_NAME}}")

    math(EXPR z_kmpkg_function_arguments_LAST_ARG "${z_kmpkg_function_arguments_ARGC} - 1")
    if(z_kmpkg_function_arguments_LAST_ARG GREATER_EQUAL z_kmpkg_function_arguments_FIRST_ARG)
        foreach(z_kmpkg_function_arguments_N RANGE "${z_kmpkg_function_arguments_FIRST_ARG}" "${z_kmpkg_function_arguments_LAST_ARG}")
            string(REPLACE ";" "\\;" z_kmpkg_function_arguments_ESCAPED_ARG "${ARGV${z_kmpkg_function_arguments_N}}")
            # adds an extra `;` on the first time through
            set("${OUT_VAR}" "${${OUT_VAR}};${z_kmpkg_function_arguments_ESCAPED_ARG}")
        endforeach()
        # remove leading `;`
        string(SUBSTRING "${${OUT_VAR}}" "1" "-1" "${OUT_VAR}")
    endif()
endmacro()

#[===[.md:
# z_kmpkg_set_powershell_path

Gets either the path to powershell or powershell core,
and places it in the variable Z_KMPKG_POWERSHELL_PATH.
#]===]
function(z_kmpkg_set_powershell_path)
    # Attempt to use pwsh if it is present; otherwise use powershell
    if(NOT DEFINED Z_KMPKG_POWERSHELL_PATH)
        find_program(Z_KMPKG_PWSH_PATH pwsh)
        if(Z_KMPKG_PWSH_PATH)
            set(Z_KMPKG_POWERSHELL_PATH "${Z_KMPKG_PWSH_PATH}" CACHE INTERNAL "The path to the PowerShell implementation to use.")
        else()
            message(DEBUG "kmpkg: Could not find PowerShell Core; falling back to PowerShell")
            find_program(Z_KMPKG_BUILTIN_POWERSHELL_PATH powershell)
            if(Z_KMPKG_BUILTIN_POWERSHELL_PATH)
                set(Z_KMPKG_POWERSHELL_PATH "${Z_KMPKG_BUILTIN_POWERSHELL_PATH}" CACHE INTERNAL "The path to the PowerShell implementation to use.")
            else()
                message(WARNING "kmpkg: Could not find PowerShell; using static string 'powershell.exe'")
                set(Z_KMPKG_POWERSHELL_PATH "powershell.exe" CACHE INTERNAL "The path to the PowerShell implementation to use.")
            endif()
        endif()
    endif() # Z_KMPKG_POWERSHELL_PATH
endfunction()


# Determine whether the toolchain is loaded during a try-compile configuration
get_property(Z_KMPKG_CMAKE_IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE)

if(KMPKG_CHAINLOAD_TOOLCHAIN_FILE)
    include("${KMPKG_CHAINLOAD_TOOLCHAIN_FILE}")
endif()

if(KMPKG_TOOLCHAIN)
    cmake_policy(POP)
    return()
endif()

#If CMake does not have a mapping for MinSizeRel and RelWithDebInfo in imported targets
#it will map those configuration to the first valid configuration in CMAKE_CONFIGURATION_TYPES or the targets IMPORTED_CONFIGURATIONS.
#In most cases this is the debug configuration which is wrong.
if(NOT DEFINED CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL)
    set(CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL "MinSizeRel;Release;None;")
    if(KMPKG_VERBOSE)
        message(STATUS "KMPKG-Info: CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL set to MinSizeRel;Release;None;")
    endif()
endif()
if(NOT DEFINED CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO)
    set(CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO "RelWithDebInfo;Release;None;")
    if(KMPKG_VERBOSE)
        message(STATUS "KMPKG-Info: CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO set to RelWithDebInfo;Release;None;")
    endif()
endif()

if(KMPKG_TARGET_TRIPLET)
    # This is required since a user might do: 'set(KMPKG_TARGET_TRIPLET somevalue)' [no CACHE] before the first project() call
    # Latter within the toolchain file we do: 'set(KMPKG_TARGET_TRIPLET somevalue CACHE STRING "")' which
    # will otherwise override the user setting of KMPKG_TARGET_TRIPLET in the current scope of the toolchain since the CACHE value
    # did not exist previously. Since the value is newly created CMake will use the CACHE value within this scope since it is the more
    # recently created value in directory scope. This 'strange' behaviour only happens on the very first configure call since subsequent
    # configure call will see the user value as the more recent value. The same logic must be applied to all cache values within this file!
    # The FORCE keyword is required to ALWAYS lift the user provided/previously set value into a CACHE value.
    set(KMPKG_TARGET_TRIPLET "${KMPKG_TARGET_TRIPLET}" CACHE STRING "Kmpkg target triplet (ex. x86-windows)" FORCE)
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Ww][Ii][Nn]32$")
    set(Z_KMPKG_TARGET_TRIPLET_ARCH x86)
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Xx]64$")
    set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Aa][Rr][Mm]$")
    set(Z_KMPKG_TARGET_TRIPLET_ARCH arm)
elseif(CMAKE_GENERATOR_PLATFORM MATCHES "^[Aa][Rr][Mm]64$")
    set(Z_KMPKG_TARGET_TRIPLET_ARCH arm64)
else()
    if(CMAKE_GENERATOR STREQUAL "Visual Studio 14 2015 Win64")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 14 2015 ARM")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH arm)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 14 2015")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH x86)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 15 2017 Win64")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 15 2017 ARM")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH arm)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 15 2017")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH x86)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 16 2019" AND CMAKE_VS_PLATFORM_NAME_DEFAULT STREQUAL "ARM64")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH arm64)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 16 2019")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 17 2022" AND CMAKE_VS_PLATFORM_NAME_DEFAULT STREQUAL "ARM64")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH arm64)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 17 2022")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 18 2026" AND CMAKE_VS_PLATFORM_NAME_DEFAULT STREQUAL "ARM64")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH arm64)
    elseif(CMAKE_GENERATOR STREQUAL "Visual Studio 18 2026")
        set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin" AND DEFINED CMAKE_OSX_ARCHITECTURES)
        list(LENGTH CMAKE_OSX_ARCHITECTURES Z_KMPKG_OSX_ARCH_COUNT)
        if(Z_KMPKG_OSX_ARCH_COUNT EQUAL "0")
            message(WARNING "Unable to determine target architecture. "
                            "Consider providing a value for the CMAKE_OSX_ARCHITECTURES cache variable. "
                            "Continuing without kmpkg.")
            set(KMPKG_TOOLCHAIN ON)
            cmake_policy(POP)
            return()
        endif()

        if(Z_KMPKG_OSX_ARCH_COUNT GREATER "1")
            message(WARNING "Detected more than one target architecture. Using the first one.")
        endif()
        list(GET CMAKE_OSX_ARCHITECTURES "0" Z_KMPKG_OSX_TARGET_ARCH)
        if(Z_KMPKG_OSX_TARGET_ARCH STREQUAL "arm64")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH arm64)
        elseif(Z_KMPKG_OSX_TARGET_ARCH STREQUAL "arm64s")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH arm64s)
        elseif(Z_KMPKG_OSX_TARGET_ARCH STREQUAL "armv7s")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH armv7s)
        elseif(Z_KMPKG_OSX_TARGET_ARCH STREQUAL "armv7")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH arm)
        elseif(Z_KMPKG_OSX_TARGET_ARCH STREQUAL "x86_64")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
        elseif(Z_KMPKG_OSX_TARGET_ARCH STREQUAL "i386")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH x86)
        else()
            message(WARNING "Unable to determine target architecture, continuing without kmpkg.")
            set(KMPKG_TOOLCHAIN ON)
            cmake_policy(POP)
            return()
        endif()
    else()
        find_program(Z_KMPKG_CL cl)
        if(Z_KMPKG_CL MATCHES "amd64/cl.exe$" OR Z_KMPKG_CL MATCHES "x64/cl.exe$")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
        elseif(Z_KMPKG_CL MATCHES "arm/cl.exe$")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH arm)
        elseif(Z_KMPKG_CL MATCHES "arm64/cl.exe$")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH arm64)
        elseif(Z_KMPKG_CL MATCHES "bin/cl.exe$" OR Z_KMPKG_CL MATCHES "x86/cl.exe$")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH x86)
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64" OR
               CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "AMD64" OR
               CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "amd64")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH x64)
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "s390x")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH s390x)
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "ppc64le")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH ppc64le)
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "armv7l")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH arm)
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH arm64)
	elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "riscv32")
	    set(Z_KMPKG_TARGET_TRIPLET_ARCH riscv32)
	elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "riscv64")
	    set(Z_KMPKG_TARGET_TRIPLET_ARCH riscv64)
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "loongarch32")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH loongarch32)
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "loongarch64")
            set(Z_KMPKG_TARGET_TRIPLET_ARCH loongarch64)
        else()
            if(Z_KMPKG_CMAKE_IN_TRY_COMPILE)
                message(STATUS "Unable to determine target architecture, continuing without kmpkg.")
            else()
                message(WARNING "Unable to determine target architecture, continuing without kmpkg.")
            endif()
            set(KMPKG_TOOLCHAIN ON)
            cmake_policy(POP)
            return()
        endif()
    endif()
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" OR CMAKE_SYSTEM_NAME STREQUAL "WindowsPhone")
    set(Z_KMPKG_TARGET_TRIPLET_PLAT uwp)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR (NOT CMAKE_SYSTEM_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux"))
    set(Z_KMPKG_TARGET_TRIPLET_PLAT linux)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" OR (NOT CMAKE_SYSTEM_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin"))
    set(Z_KMPKG_TARGET_TRIPLET_PLAT osx)
elseif(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    set(Z_KMPKG_TARGET_TRIPLET_PLAT ios)
elseif(CMAKE_SYSTEM_NAME STREQUAL "watchOS")
    set(Z_KMPKG_TARGET_TRIPLET_PLAT watchos)
elseif(CMAKE_SYSTEM_NAME STREQUAL "tvOS")
    set(Z_KMPKG_TARGET_TRIPLET_PLAT tvos)
elseif(CMAKE_SYSTEM_NAME STREQUAL "visionOS")
    set(Z_KMPKG_TARGET_TRIPLET_PLAT visionos)
elseif(MINGW)
    set(Z_KMPKG_TARGET_TRIPLET_PLAT mingw-dynamic)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows" OR (NOT CMAKE_SYSTEM_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows"))
    if(XBOX_CONSOLE_TARGET STREQUAL "scarlett")
        set(Z_KMPKG_TARGET_TRIPLET_PLAT xbox-scarlett)
    elseif(XBOX_CONSOLE_TARGET STREQUAL "xboxone")
        set(Z_KMPKG_TARGET_TRIPLET_PLAT xbox-xboxone)
    else()
        set(Z_KMPKG_TARGET_TRIPLET_PLAT windows)
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR (NOT CMAKE_SYSTEM_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "FreeBSD"))
    set(Z_KMPKG_TARGET_TRIPLET_PLAT freebsd)
elseif(CMAKE_SYSTEM_NAME STREQUAL "OpenBSD" OR (NOT CMAKE_SYSTEM_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "OpenBSD"))
    set(Z_KMPKG_TARGET_TRIPLET_PLAT openbsd)
elseif(CMAKE_SYSTEM_NAME STREQUAL "NetBSD" OR (NOT CMAKE_SYSTEM_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "NetBSD"))
    set(Z_KMPKG_TARGET_TRIPLET_PLAT netbsd)
elseif(CMAKE_SYSTEM_NAME STREQUAL "SunOS" OR (NOT CMAKE_SYSTEM_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "SunOS"))
    set(Z_KMPKG_TARGET_TRIPLET_PLAT solaris)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android" OR (NOT CMAKE_SYSTEM_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Android"))
    set(Z_KMPKG_TARGET_TRIPLET_PLAT android)
endif()

if(EMSCRIPTEN)
    set(Z_KMPKG_TARGET_TRIPLET_ARCH wasm32)
    set(Z_KMPKG_TARGET_TRIPLET_PLAT emscripten)
endif()

set(KMPKG_TARGET_TRIPLET "${Z_KMPKG_TARGET_TRIPLET_ARCH}-${Z_KMPKG_TARGET_TRIPLET_PLAT}" CACHE STRING "Kmpkg target triplet (ex. x86-windows)")
set(Z_KMPKG_TOOLCHAIN_DIR "${CMAKE_CURRENT_LIST_DIR}")

# Detect .kmpkg-root to figure KMPKG_ROOT_DIR
set(Z_KMPKG_ROOT_DIR_CANDIDATE "${CMAKE_CURRENT_LIST_DIR}")
while(NOT DEFINED Z_KMPKG_ROOT_DIR)
    if(EXISTS "${Z_KMPKG_ROOT_DIR_CANDIDATE}/.kmpkg-root")
        set(Z_KMPKG_ROOT_DIR "${Z_KMPKG_ROOT_DIR_CANDIDATE}" CACHE INTERNAL "Kmpkg root directory")
    elseif(IS_DIRECTORY "${Z_KMPKG_ROOT_DIR_CANDIDATE}")
        get_filename_component(Z_KMPKG_ROOT_DIR_TEMP "${Z_KMPKG_ROOT_DIR_CANDIDATE}" DIRECTORY)
        if(Z_KMPKG_ROOT_DIR_TEMP STREQUAL Z_KMPKG_ROOT_DIR_CANDIDATE)
            break() # If unchanged, we have reached the root of the drive without finding kmpkg.
        endif()
        SET(Z_KMPKG_ROOT_DIR_CANDIDATE "${Z_KMPKG_ROOT_DIR_TEMP}")
        unset(Z_KMPKG_ROOT_DIR_TEMP)
    else()
        break()
    endif()
endwhile()
unset(Z_KMPKG_ROOT_DIR_CANDIDATE)

if(NOT Z_KMPKG_ROOT_DIR)
    z_kmpkg_add_fatal_error("Could not find .kmpkg-root")
endif()

if(DEFINED KMPKG_INSTALLED_DIR)
    set(Z_KMPKG_INSTALLED_DIR_INITIAL_VALUE "${KMPKG_INSTALLED_DIR}")
elseif(DEFINED _KMPKG_INSTALLED_DIR)
    set(Z_KMPKG_INSTALLED_DIR_INITIAL_VALUE "${_KMPKG_INSTALLED_DIR}")
elseif(KMPKG_MANIFEST_MODE)
    set(Z_KMPKG_INSTALLED_DIR_INITIAL_VALUE "${CMAKE_BINARY_DIR}/kmpkg_installed")
else()
    set(Z_KMPKG_INSTALLED_DIR_INITIAL_VALUE "${Z_KMPKG_ROOT_DIR}/installed")
endif()

set(KMPKG_INSTALLED_DIR "${Z_KMPKG_INSTALLED_DIR_INITIAL_VALUE}"
    CACHE PATH
    "The directory which contains the installed libraries for each triplet" FORCE)
set(_KMPKG_INSTALLED_DIR "${KMPKG_INSTALLED_DIR}"
    CACHE PATH
    "The directory which contains the installed libraries for each triplet" FORCE)

function(z_kmpkg_add_kmpkg_to_cmake_path list suffix)
    set(kmpkg_paths
        "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}${suffix}"
        "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/debug${suffix}"
    )
    if(NOT DEFINED CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE MATCHES "^[Dd][Ee][Bb][Uu][Gg]$")
        list(REVERSE kmpkg_paths) # Debug build: Put Debug paths before Release paths.
    endif()
    if(KMPKG_PREFER_SYSTEM_LIBS)
        list(APPEND "${list}" "${kmpkg_paths}")
    else()
        list(INSERT "${list}" "0" "${kmpkg_paths}") # CMake 3.15 is required for list(PREPEND ...).
    endif()
    set("${list}" "${${list}}" PARENT_SCOPE)
endfunction()
z_kmpkg_add_kmpkg_to_cmake_path(CMAKE_PREFIX_PATH "")
z_kmpkg_add_kmpkg_to_cmake_path(CMAKE_LIBRARY_PATH "/lib/manual-link")
z_kmpkg_add_kmpkg_to_cmake_path(CMAKE_FIND_ROOT_PATH "")

if(NOT KMPKG_PREFER_SYSTEM_LIBS)
    set(CMAKE_FIND_FRAMEWORK "LAST") # we assume that frameworks are usually system-wide libs, not kmpkg-built
    set(CMAKE_FIND_APPBUNDLE "LAST") # we assume that appbundles are usually system-wide libs, not kmpkg-built
endif()

# If one CMAKE_FIND_ROOT_PATH_MODE_* variables is set to ONLY, to  make sure that ${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}
# and ${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/debug are searched, it is not sufficient to just add them to CMAKE_FIND_ROOT_PATH,
# as CMAKE_FIND_ROOT_PATH specify "one or more directories to be prepended to all other search directories", so to make sure that
# the libraries are searched as they are, it is necessary to add "/" to the CMAKE_PREFIX_PATH
if(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE STREQUAL "ONLY" OR
   CMAKE_FIND_ROOT_PATH_MODE_LIBRARY STREQUAL "ONLY" OR
   CMAKE_FIND_ROOT_PATH_MODE_PACKAGE STREQUAL "ONLY")
   list(APPEND CMAKE_PREFIX_PATH "/")
endif()

set(KMPKG_CMAKE_FIND_ROOT_PATH "${CMAKE_FIND_ROOT_PATH}")

# CMAKE_EXECUTABLE_SUFFIX is not yet defined
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(Z_KMPKG_EXECUTABLE "${Z_KMPKG_ROOT_DIR}/kmpkg.exe")
    set(Z_KMPKG_BOOTSTRAP_SCRIPT "${Z_KMPKG_ROOT_DIR}/bootstrap-kmpkg.bat")
else()
    set(Z_KMPKG_EXECUTABLE "${Z_KMPKG_ROOT_DIR}/kmpkg")
    set(Z_KMPKG_BOOTSTRAP_SCRIPT "${Z_KMPKG_ROOT_DIR}/bootstrap-kmpkg.sh")
endif()

if(KMPKG_MANIFEST_MODE AND KMPKG_MANIFEST_INSTALL AND NOT Z_KMPKG_CMAKE_IN_TRY_COMPILE AND NOT Z_KMPKG_HAS_FATAL_ERROR)
    if(NOT EXISTS "${Z_KMPKG_EXECUTABLE}" AND NOT Z_KMPKG_HAS_FATAL_ERROR)
        message(STATUS "Bootstrapping kmpkg before install")

        set(Z_KMPKG_BOOTSTRAP_LOG "${CMAKE_BINARY_DIR}/kmpkg-bootstrap.log")
        file(TO_NATIVE_PATH "${Z_KMPKG_BOOTSTRAP_LOG}" Z_NATIVE_KMPKG_BOOTSTRAP_LOG)
        execute_process(
            COMMAND "${Z_KMPKG_BOOTSTRAP_SCRIPT}" ${KMPKG_BOOTSTRAP_OPTIONS}
            OUTPUT_FILE "${Z_KMPKG_BOOTSTRAP_LOG}"
            ERROR_FILE "${Z_KMPKG_BOOTSTRAP_LOG}"
            RESULT_VARIABLE Z_KMPKG_BOOTSTRAP_RESULT)

        if(Z_KMPKG_BOOTSTRAP_RESULT EQUAL "0")
            message(STATUS "Bootstrapping kmpkg before install - done")
        else()
            message(STATUS "Bootstrapping kmpkg before install - failed")
            z_kmpkg_add_fatal_error("kmpkg install failed. See logs for more information: ${Z_NATIVE_KMPKG_BOOTSTRAP_LOG}")
        endif()
    endif()

    if(NOT Z_KMPKG_HAS_FATAL_ERROR)
        message(STATUS "Running kmpkg install")

        set(Z_KMPKG_ADDITIONAL_MANIFEST_PARAMS)

        if(DEFINED KMPKG_HOST_TRIPLET AND NOT KMPKG_HOST_TRIPLET STREQUAL "")
            list(APPEND Z_KMPKG_ADDITIONAL_MANIFEST_PARAMS "--host-triplet=${KMPKG_HOST_TRIPLET}")
        endif()

        if(KMPKG_OVERLAY_PORTS)
            foreach(Z_KMPKG_OVERLAY_PORT IN LISTS KMPKG_OVERLAY_PORTS)
                list(APPEND Z_KMPKG_ADDITIONAL_MANIFEST_PARAMS "--overlay-ports=${Z_KMPKG_OVERLAY_PORT}")
            endforeach()
        endif()
        if(KMPKG_OVERLAY_TRIPLETS)
            foreach(Z_KMPKG_OVERLAY_TRIPLET IN LISTS KMPKG_OVERLAY_TRIPLETS)
                list(APPEND Z_KMPKG_ADDITIONAL_MANIFEST_PARAMS "--overlay-triplets=${Z_KMPKG_OVERLAY_TRIPLET}")
            endforeach()
        endif()

        if(DEFINED KMPKG_FEATURE_FLAGS OR DEFINED CACHE{KMPKG_FEATURE_FLAGS})
            list(JOIN KMPKG_FEATURE_FLAGS "," Z_KMPKG_FEATURE_FLAGS)
            set(Z_KMPKG_FEATURE_FLAGS "--feature-flags=${Z_KMPKG_FEATURE_FLAGS}")
        endif()

        foreach(Z_KMPKG_FEATURE IN LISTS KMPKG_MANIFEST_FEATURES)
            list(APPEND Z_KMPKG_ADDITIONAL_MANIFEST_PARAMS "--x-feature=${Z_KMPKG_FEATURE}")
        endforeach()

        if(KMPKG_MANIFEST_NO_DEFAULT_FEATURES)
            list(APPEND Z_KMPKG_ADDITIONAL_MANIFEST_PARAMS "--x-no-default-features")
        endif()

        if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.18")
            set(Z_KMPKG_MANIFEST_INSTALL_ECHO_PARAMS ECHO_OUTPUT_VARIABLE ECHO_ERROR_VARIABLE)
        else()
            set(Z_KMPKG_MANIFEST_INSTALL_ECHO_PARAMS)
        endif()

        execute_process(
            COMMAND "${Z_KMPKG_EXECUTABLE}" install
                --triplet "${KMPKG_TARGET_TRIPLET}"
                --kmpkg-root "${Z_KMPKG_ROOT_DIR}"
                "--x-wait-for-lock"
                "--x-manifest-root=${KMPKG_MANIFEST_DIR}"
                "--x-install-root=${_KMPKG_INSTALLED_DIR}"
                ${Z_KMPKG_FEATURE_FLAGS}
                ${Z_KMPKG_ADDITIONAL_MANIFEST_PARAMS}
                ${KMPKG_INSTALL_OPTIONS}
            OUTPUT_VARIABLE Z_KMPKG_MANIFEST_INSTALL_LOGTEXT
            ERROR_VARIABLE Z_KMPKG_MANIFEST_INSTALL_LOGTEXT
            RESULT_VARIABLE Z_KMPKG_MANIFEST_INSTALL_RESULT
            ${Z_KMPKG_MANIFEST_INSTALL_ECHO_PARAMS}
        )

        set(Z_KMPKG_MANIFEST_INSTALL_LOGFILE "${CMAKE_BINARY_DIR}/kmpkg-manifest-install.log")
        file(TO_NATIVE_PATH "${Z_KMPKG_MANIFEST_INSTALL_LOGFILE}" Z_NATIVE_KMPKG_MANIFEST_INSTALL_LOGFILE)
        file(WRITE "${Z_KMPKG_MANIFEST_INSTALL_LOGFILE}" "${Z_KMPKG_MANIFEST_INSTALL_LOGTEXT}")

        if(Z_KMPKG_MANIFEST_INSTALL_RESULT EQUAL "0")
            message(STATUS "Running kmpkg install - done")
            set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
                "${KMPKG_MANIFEST_DIR}/kmpkg.json")
            if(EXISTS "${KMPKG_MANIFEST_DIR}/kmpkg-configuration.json")
                set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
                    "${KMPKG_MANIFEST_DIR}/kmpkg-configuration.json")
            endif()
        else()
            message(STATUS "Running kmpkg install - failed")
            z_kmpkg_add_fatal_error("kmpkg install failed. See logs for more information: ${Z_NATIVE_KMPKG_MANIFEST_INSTALL_LOGFILE}")
        endif()
    endif()
endif()

option(KMPKG_SETUP_CMAKE_PROGRAM_PATH  "Enable the setup of CMAKE_PROGRAM_PATH to kmpkg paths" ON)
set(KMPKG_CAN_USE_HOST_TOOLS OFF)
if(DEFINED KMPKG_HOST_TRIPLET AND NOT KMPKG_HOST_TRIPLET STREQUAL "")
    set(KMPKG_CAN_USE_HOST_TOOLS ON)
endif()
cmake_dependent_option(KMPKG_USE_HOST_TOOLS "Setup CMAKE_PROGRAM_PATH to use host tools" ON "KMPKG_CAN_USE_HOST_TOOLS" OFF)
unset(KMPKG_CAN_USE_HOST_TOOLS)

if(KMPKG_SETUP_CMAKE_PROGRAM_PATH)
    set(tools_base_path "${KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/tools")
    if(KMPKG_USE_HOST_TOOLS)
        set(tools_base_path "${KMPKG_INSTALLED_DIR}/${KMPKG_HOST_TRIPLET}/tools")
    endif()
    list(APPEND CMAKE_PROGRAM_PATH "${tools_base_path}")
    file(GLOB Z_KMPKG_TOOLS_DIRS LIST_DIRECTORIES true "${tools_base_path}/*")
    file(GLOB Z_KMPKG_TOOLS_FILES LIST_DIRECTORIES false "${tools_base_path}/*")
    file(GLOB Z_KMPKG_TOOLS_DIRS_BIN LIST_DIRECTORIES true "${tools_base_path}/*/bin")
    file(GLOB Z_KMPKG_TOOLS_FILES_BIN LIST_DIRECTORIES false "${tools_base_path}/*/bin")
    list(REMOVE_ITEM Z_KMPKG_TOOLS_DIRS ${Z_KMPKG_TOOLS_FILES} "") # need at least one item for REMOVE_ITEM if CMake <= 3.19
    list(REMOVE_ITEM Z_KMPKG_TOOLS_DIRS_BIN ${Z_KMPKG_TOOLS_FILES_BIN} "")
    string(REPLACE "/bin" "" Z_KMPKG_TOOLS_DIRS_TO_REMOVE "${Z_KMPKG_TOOLS_DIRS_BIN}")
    list(REMOVE_ITEM Z_KMPKG_TOOLS_DIRS ${Z_KMPKG_TOOLS_DIRS_TO_REMOVE} "")
    list(APPEND Z_KMPKG_TOOLS_DIRS ${Z_KMPKG_TOOLS_DIRS_BIN})
    foreach(Z_KMPKG_TOOLS_DIR IN LISTS Z_KMPKG_TOOLS_DIRS)
        list(APPEND CMAKE_PROGRAM_PATH "${Z_KMPKG_TOOLS_DIR}")
    endforeach()
    unset(Z_KMPKG_TOOLS_DIR)
    unset(Z_KMPKG_TOOLS_DIRS)
    unset(Z_KMPKG_TOOLS_FILES)
    unset(Z_KMPKG_TOOLS_DIRS_BIN)
    unset(Z_KMPKG_TOOLS_FILES_BIN)
    unset(Z_KMPKG_TOOLS_DIRS_TO_REMOVE)
    unset(tools_base_path)
endif()

cmake_policy(POP)

function(add_executable)
    z_kmpkg_function_arguments(ARGS)
    _add_executable(${ARGS})
    set(target_name "${ARGV0}")

    list(FIND ARGV "IMPORTED" IMPORTED_IDX)
    list(FIND ARGV "ALIAS" ALIAS_IDX)
    list(FIND ARGV "MACOSX_BUNDLE" MACOSX_BUNDLE_IDX)
    if(IMPORTED_IDX EQUAL "-1" AND ALIAS_IDX EQUAL "-1")
        if(KMPKG_APPLOCAL_DEPS)
            if(Z_KMPKG_TARGET_TRIPLET_PLAT MATCHES "windows|uwp|xbox")
                z_kmpkg_set_powershell_path()
                set(EXTRA_OPTIONS "")
                if(X_KMPKG_APPLOCAL_DEPS_SERIALIZED)
                    set(EXTRA_OPTIONS USES_TERMINAL)
                endif()
                add_custom_command(TARGET "${target_name}" POST_BUILD
                    COMMAND "${Z_KMPKG_POWERSHELL_PATH}" -noprofile -executionpolicy Bypass -file "${Z_KMPKG_TOOLCHAIN_DIR}/msbuild/applocal.ps1"
                        -targetBinary "$<TARGET_FILE:${target_name}>"
                        -installedDir "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>/bin"
                        -OutVariable out
                    VERBATIM
                    ${EXTRA_OPTIONS}
                )
            elseif(Z_KMPKG_TARGET_TRIPLET_PLAT MATCHES "osx")
                if(NOT MACOSX_BUNDLE_IDX EQUAL "-1")
                    find_package(Python COMPONENTS Interpreter)
                    add_custom_command(TARGET "${target_name}" POST_BUILD
                        COMMAND "${Python_EXECUTABLE}" "${Z_KMPKG_TOOLCHAIN_DIR}/osx/applocal.py"
                            "$<TARGET_FILE:${target_name}>"
                            "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>"
                        VERBATIM
                    )
                endif()
            endif()
        endif()
        set_target_properties("${target_name}" PROPERTIES VS_USER_PROPS do_not_import_user.props)
        set_target_properties("${target_name}" PROPERTIES VS_GLOBAL_KmpkgEnabled false)
    endif()
endfunction()

function(add_library)
    z_kmpkg_function_arguments(ARGS)
    _add_library(${ARGS})
    set(target_name "${ARGV0}")

    list(FIND ARGS "IMPORTED" IMPORTED_IDX)
    list(FIND ARGS "INTERFACE" INTERFACE_IDX)
    list(FIND ARGS "ALIAS" ALIAS_IDX)
    if(IMPORTED_IDX EQUAL "-1" AND INTERFACE_IDX EQUAL "-1" AND ALIAS_IDX EQUAL "-1")
        get_target_property(IS_LIBRARY_SHARED "${target_name}" TYPE)
        if(KMPKG_APPLOCAL_DEPS AND Z_KMPKG_TARGET_TRIPLET_PLAT MATCHES "windows|uwp|xbox" AND (IS_LIBRARY_SHARED STREQUAL "SHARED_LIBRARY" OR IS_LIBRARY_SHARED STREQUAL "MODULE_LIBRARY"))
            z_kmpkg_set_powershell_path()
            add_custom_command(TARGET "${target_name}" POST_BUILD
                COMMAND "${Z_KMPKG_POWERSHELL_PATH}" -noprofile -executionpolicy Bypass -file "${Z_KMPKG_TOOLCHAIN_DIR}/msbuild/applocal.ps1"
                    -targetBinary "$<TARGET_FILE:${target_name}>"
                    -installedDir "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>/bin"
                    -OutVariable out
                    VERBATIM
            )
        endif()
        set_target_properties("${target_name}" PROPERTIES VS_USER_PROPS do_not_import_user.props)
        set_target_properties("${target_name}" PROPERTIES VS_GLOBAL_KmpkgEnabled false)
    endif()
endfunction()

# This is an experimental function to enable applocal install of dependencies as part of the `make install` process
# Arguments:
#   TARGETS - a list of installed targets to have dependencies copied for
#   DESTINATION - the runtime directory for those targets (usually `bin`)
#   COMPONENT - the component this install command belongs to (optional)
#
# Note that this function requires CMake 3.14 for policy CMP0087
function(x_kmpkg_install_local_dependencies)
    if(CMAKE_VERSION VERSION_LESS "3.14")
        message(FATAL_ERROR "x_kmpkg_install_local_dependencies and X_KMPKG_APPLOCAL_DEPS_INSTALL require at least CMake 3.14
(current version: ${CMAKE_VERSION})"
        )
    endif()

    cmake_parse_arguments(PARSE_ARGV "0" arg
        ""
        "DESTINATION;COMPONENT"
        "TARGETS"
    )
    if(DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} was passed extra arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()
    if(NOT DEFINED arg_DESTINATION)
        message(FATAL_ERROR "DESTINATION must be specified")
    endif()

    if(Z_KMPKG_TARGET_TRIPLET_PLAT MATCHES "^(windows|uwp|xbox-.*)$")
        # Install CODE|SCRIPT allow the use of generator expressions
        cmake_policy(SET CMP0087 NEW) # CMake 3.14

        z_kmpkg_set_powershell_path()
        if(NOT IS_ABSOLUTE "${arg_DESTINATION}")
            set(arg_DESTINATION "\${CMAKE_INSTALL_PREFIX}/${arg_DESTINATION}")
        endif()

        set(component_param "")
        if(DEFINED arg_COMPONENT)
            set(component_param COMPONENT "${arg_COMPONENT}")
        endif()

        set(allowed_target_types MODULE_LIBRARY SHARED_LIBRARY EXECUTABLE)
        foreach(target IN LISTS arg_TARGETS)
            get_target_property(target_type "${target}" TYPE)
            if(target_type IN_LIST allowed_target_types)
                install(CODE "message(\"-- Installing app dependencies for ${target}...\")
                    execute_process(COMMAND \"${Z_KMPKG_POWERSHELL_PATH}\" -noprofile -executionpolicy Bypass -file \"${Z_KMPKG_TOOLCHAIN_DIR}/msbuild/applocal.ps1\"
                        -targetBinary \"${arg_DESTINATION}/$<TARGET_FILE_NAME:${target}>\"
                        -installedDir \"${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}$<$<CONFIG:Debug>:/debug>/bin\"
                        -OutVariable out)"
                    ${component_param}
                )
            endif()
        endforeach()
    endif()
endfunction()

if(X_KMPKG_APPLOCAL_DEPS_INSTALL)
    function(install)
        z_kmpkg_function_arguments(ARGS)
        _install(${ARGS})

        if(ARGV0 STREQUAL "TARGETS")
            # Will contain the list of targets
            set(parsed_targets "")

            # Destination - [RUNTIME] DESTINATION argument overrides this
            set(destination "bin")

            set(component_param "")

            # Parse arguments given to the install function to find targets and (runtime) destination
            set(modifier "") # Modifier for the command in the argument
            set(last_command "") # Last command we found to process
            foreach(arg IN LISTS ARGS)
                if(arg MATCHES "^(ARCHIVE|LIBRARY|RUNTIME|OBJECTS|FRAMEWORK|BUNDLE|PRIVATE_HEADER|PUBLIC_HEADER|RESOURCE|INCLUDES)$")
                    set(modifier "${arg}")
                    continue()
                endif()
                if(arg MATCHES "^(TARGETS|DESTINATION|PERMISSIONS|CONFIGURATIONS|COMPONENT|NAMELINK_COMPONENT|OPTIONAL|EXCLUDE_FROM_ALL|NAMELINK_ONLY|NAMELINK_SKIP|EXPORT|FILE_SET)$")
                    set(last_command "${arg}")
                    continue()
                endif()

                if(last_command STREQUAL "TARGETS")
                    list(APPEND parsed_targets "${arg}")
                endif()

                if(last_command STREQUAL "DESTINATION" AND (modifier STREQUAL "" OR modifier STREQUAL "RUNTIME"))
                    set(destination "${arg}")
                endif()
                if(last_command STREQUAL "COMPONENT" AND (modifier STREQUAL "" OR modifier STREQUAL "RUNTIME"))
                    set(component_param "COMPONENT" "${arg}")
                endif()
            endforeach()

            x_kmpkg_install_local_dependencies(
                TARGETS ${parsed_targets}
                DESTINATION "${destination}"
                ${component_param}
            )
        endif()
    endfunction()
endif()

option(KMPKG_TRACE_FIND_PACKAGE "Trace calls to find_package()" OFF)
if(NOT DEFINED KMPKG_OVERRIDE_FIND_PACKAGE_NAME)
    set(KMPKG_OVERRIDE_FIND_PACKAGE_NAME find_package)
endif()
# NOTE: this is not a function, which means that arguments _are not_ perfectly forwarded
# this is fine for `find_package`, since there are no usecases for `;` in arguments,
# so perfect forwarding is not important
set(z_kmpkg_find_package_backup_id "0")
macro("${KMPKG_OVERRIDE_FIND_PACKAGE_NAME}" z_kmpkg_find_package_package_name)
    if(KMPKG_TRACE_FIND_PACKAGE)
        string(REPEAT "  " "${z_kmpkg_find_package_backup_id}" z_kmpkg_find_package_indent)
        string(JOIN " " z_kmpkg_find_package_argn ${ARGN})
        message(STATUS "${z_kmpkg_find_package_indent}find_package(${z_kmpkg_find_package_package_name} ${z_kmpkg_find_package_argn})")
        unset(z_kmpkg_find_package_argn)
        unset(z_kmpkg_find_package_indent)
    endif()

    math(EXPR z_kmpkg_find_package_backup_id "${z_kmpkg_find_package_backup_id} + 1")
    set(z_kmpkg_find_package_package_name "${z_kmpkg_find_package_package_name}")
    set(z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN "${ARGN}")
    set(z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_vars "")

    if(z_kmpkg_find_package_backup_id EQUAL "1")
        # This is the top-level find_package call
        if("${KMPKG_LOCK_FIND_PACKAGE_${z_kmpkg_find_package_package_name}}")
            # Avoid CMake warning when both REQUIRED and CMAKE_REQUIRE_FIND_PACKAGE_<Pkg> are used
            if(NOT "REQUIRED" IN_LIST "z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN")
                list(APPEND "z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_vars" "CMAKE_REQUIRE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}")
                if(DEFINED "CMAKE_REQUIRE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}")
                    set("z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_CMAKE_REQUIRE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}" "${CMAKE_REQUIRE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}}")
                endif()
                set("CMAKE_REQUIRE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}" 1)
            endif()
            if(KMPKG_TRACE_FIND_PACKAGE)
                message(STATUS "  (required by KMPKG_LOCK_FIND_PACKAGE_${z_kmpkg_find_package_package_name}=${KMPKG_LOCK_FIND_PACKAGE_${z_kmpkg_find_package_package_name}})")
            endif()
        elseif(DEFINED "KMPKG_LOCK_FIND_PACKAGE_${z_kmpkg_find_package_package_name}")
            list(APPEND "z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_vars" "CMAKE_DISABLE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}")
            if(DEFINED "CMAKE_DISABLE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}")
                set("z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_CMAKE_DISABLE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}" "${CMAKE_DISABLE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}}")
            endif()
            # We don't need to worry about clearing this for transitive users because
            # once this top level find_package is disabled, we immediately will return
            # not found and not try to visit transitive dependencies in the first place.
            set("CMAKE_DISABLE_FIND_PACKAGE_${z_kmpkg_find_package_package_name}" 1)
            if(KMPKG_TRACE_FIND_PACKAGE)
                message(STATUS "  (disabled by KMPKG_LOCK_FIND_PACKAGE_${z_kmpkg_find_package_package_name}=${KMPKG_LOCK_FIND_PACKAGE_${z_kmpkg_find_package_package_name}})")
            endif()
        elseif(KMPKG_TRACE_FIND_PACKAGE)
            message(STATUS "  (could be controlled by KMPKG_LOCK_FIND_PACKAGE_${z_kmpkg_find_package_package_name})")
        endif()
    endif()

    # Workaround to set the ROOT_PATH until upstream CMake stops overriding
    # the ROOT_PATH at apple OS initialization phase.
    # See https://gitlab.kitware.com/cmake/cmake/merge_requests/3273
    # Fixed in CMake 3.15
    if(CMAKE_SYSTEM_NAME STREQUAL "iOS" OR CMAKE_SYSTEM_NAME STREQUAL "watchOS" OR CMAKE_SYSTEM_NAME STREQUAL "tvOS" OR CMAKE_SYSTEM_NAME STREQUAL "visionOS")
        list(APPEND z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_vars "CMAKE_FIND_ROOT_PATH")
        if(DEFINED CMAKE_FIND_ROOT_PATH)
            set(z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_CMAKE_FIND_ROOT_PATH "${CMAKE_FIND_ROOT_PATH}")
        endif()
        list(APPEND CMAKE_FIND_ROOT_PATH "${KMPKG_CMAKE_FIND_ROOT_PATH}")
    endif()

    string(TOLOWER "${z_kmpkg_find_package_package_name}" z_kmpkg_find_package_lowercase_package_name)
    set(z_kmpkg_find_package_kmpkg_cmake_wrapper_path
        "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/share/${z_kmpkg_find_package_lowercase_package_name}/kmpkg-cmake-wrapper.cmake")
    if(CMAKE_DISABLE_FIND_PACKAGE_${z_kmpkg_find_package_package_name})
        # Skip wrappers, fail if REQUIRED.
        _find_package("${z_kmpkg_find_package_package_name}" ${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN})
    elseif(EXISTS "${z_kmpkg_find_package_kmpkg_cmake_wrapper_path}")
        if(KMPKG_TRACE_FIND_PACKAGE)
            string(REPEAT "  " "${z_kmpkg_find_package_backup_id}" z_kmpkg_find_package_indent)
            message(STATUS "${z_kmpkg_find_package_indent}using share/${z_kmpkg_find_package_lowercase_package_name}/kmpkg-cmake-wrapper.cmake")
            unset(z_kmpkg_find_package_indent)
        endif()
        list(APPEND z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_vars "ARGS")
        if(DEFINED ARGS)
            set(z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_ARGS "${ARGS}")
        endif()
        set(ARGS "${z_kmpkg_find_package_package_name};${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN}")
        include("${z_kmpkg_find_package_kmpkg_cmake_wrapper_path}")
    elseif(z_kmpkg_find_package_package_name STREQUAL "Boost" AND EXISTS "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/include/boost")
        # Checking for the boost headers disables this wrapper unless the user has installed at least one boost library
        # these intentionally are not backed up
        set(Boost_USE_STATIC_LIBS OFF)
        set(Boost_USE_MULTITHREADED ON)
        set(Boost_NO_BOOST_CMAKE ON)
        set(Boost_USE_STATIC_RUNTIME)
        unset(Boost_USE_STATIC_RUNTIME CACHE)
        if(CMAKE_VS_PLATFORM_TOOLSET STREQUAL "v120")
            set(Boost_COMPILER "-vc120")
        else()
            set(Boost_COMPILER "-vc140")
        endif()
        _find_package("${z_kmpkg_find_package_package_name}" ${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN})
    elseif(z_kmpkg_find_package_package_name STREQUAL "ICU" AND EXISTS "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/include/unicode/utf.h")
        list(FIND z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN "COMPONENTS" z_kmpkg_find_package_COMPONENTS_IDX)
        if(NOT z_kmpkg_find_package_COMPONENTS_IDX EQUAL "-1")
            _find_package("${z_kmpkg_find_package_package_name}" ${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN} COMPONENTS data)
        else()
            _find_package("${z_kmpkg_find_package_package_name}" ${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN})
        endif()
    elseif(z_kmpkg_find_package_package_name STREQUAL "GSL" AND EXISTS "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/include/gsl")
        _find_package("${z_kmpkg_find_package_package_name}" ${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN})
        if(GSL_FOUND AND TARGET GSL::gsl)
            set_property( TARGET GSL::gslcblas APPEND PROPERTY IMPORTED_CONFIGURATIONS Release )
            set_property( TARGET GSL::gsl APPEND PROPERTY IMPORTED_CONFIGURATIONS Release )
            if( EXISTS "${GSL_LIBRARY_DEBUG}" AND EXISTS "${GSL_CBLAS_LIBRARY_DEBUG}")
                set_property( TARGET GSL::gsl APPEND PROPERTY IMPORTED_CONFIGURATIONS Debug )
                set_target_properties( GSL::gsl PROPERTIES IMPORTED_LOCATION_DEBUG "${GSL_LIBRARY_DEBUG}" )
                set_property( TARGET GSL::gslcblas APPEND PROPERTY IMPORTED_CONFIGURATIONS Debug )
                set_target_properties( GSL::gslcblas PROPERTIES IMPORTED_LOCATION_DEBUG "${GSL_CBLAS_LIBRARY_DEBUG}" )
            endif()
        endif()
    elseif("${z_kmpkg_find_package_package_name}" STREQUAL "CURL" AND EXISTS "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/include/curl")
        _find_package("${z_kmpkg_find_package_package_name}" ${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN})
        if(CURL_FOUND)
            if(EXISTS "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/lib/nghttp2.lib")
                list(APPEND CURL_LIBRARIES
                    "debug" "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/debug/lib/nghttp2.lib"
                    "optimized" "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/lib/nghttp2.lib")
            endif()
        endif()
    elseif("${z_kmpkg_find_package_lowercase_package_name}" STREQUAL "grpc" AND EXISTS "${_KMPKG_INSTALLED_DIR}/${KMPKG_TARGET_TRIPLET}/share/grpc")
        _find_package(gRPC ${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN})
    else()
        _find_package("${z_kmpkg_find_package_package_name}" ${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_ARGN})
    endif()
    # Do not use z_kmpkg_find_package_package_name beyond this point since it might have changed!
    # Only variables using z_kmpkg_find_package_backup_id can used correctly below!
    foreach(z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_var IN LISTS z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_vars)
        if(DEFINED z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_var})
            set("${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_var}" "${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_var}}")
        else()
            unset("${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_var}")
        endif()
        unset("z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_${z_kmpkg_find_package_${z_kmpkg_find_package_backup_id}_backup_var}")
    endforeach()
    math(EXPR z_kmpkg_find_package_backup_id "${z_kmpkg_find_package_backup_id} - 1")
    if(z_kmpkg_find_package_backup_id LESS "0")
        message(FATAL_ERROR "[kmpkg]: find_package ended with z_kmpkg_find_package_backup_id being less than 0! This is a logical error and should never happen. Please provide a cmake trace log via cmake cmd line option '--trace-expand'!")
    endif()
endmacro()

cmake_policy(PUSH)
cmake_policy(VERSION 3.16)

set(KMPKG_TOOLCHAIN ON)
set(Z_KMPKG_UNUSED "${CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION}")
set(Z_KMPKG_UNUSED "${CMAKE_EXPORT_NO_PACKAGE_REGISTRY}")
set(Z_KMPKG_UNUSED "${CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY}")
set(Z_KMPKG_UNUSED "${CMAKE_FIND_PACKAGE_NO_SYSTEM_PACKAGE_REGISTRY}")
set(Z_KMPKG_UNUSED "${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP}")

# Propagate these values to try-compile configurations so the triplet and toolchain load
if(NOT Z_KMPKG_CMAKE_IN_TRY_COMPILE)
    list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
        KMPKG_TARGET_TRIPLET
        KMPKG_TARGET_ARCHITECTURE
        KMPKG_HOST_TRIPLET
        KMPKG_INSTALLED_DIR
        KMPKG_PREFER_SYSTEM_LIBS
        # KMPKG_APPLOCAL_DEPS # This should be off within try_compile!
        KMPKG_CHAINLOAD_TOOLCHAIN_FILE
        Z_KMPKG_ROOT_DIR
    )
else()
    set(KMPKG_APPLOCAL_DEPS OFF)
endif()

if(Z_KMPKG_HAS_FATAL_ERROR)
    message(FATAL_ERROR "${Z_KMPKG_FATAL_ERROR}")
endif()

cmake_policy(POP)
