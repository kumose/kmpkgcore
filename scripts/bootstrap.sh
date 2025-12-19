#!/bin/sh

# Find .kmpkg-root
kmpkgRootDir=$(cd -- "$(dirname -- "$0")" && pwd -P)
while [ "$kmpkgRootDir" != "/" ] && [ ! -e "$kmpkgRootDir/.kmpkg-root" ]; do
    kmpkgRootDir="$(dirname "$kmpkgRootDir")"
done

# Parse arguments
kmpkgDisableMetrics="OFF"
kmpkgUseSystem="false"
kmpkgUseMuslC="OFF"
kmpkgSkipDependencyChecks="OFF"

for var in "$@"; do
    case "$var" in
        -disableMetrics|--disableMetrics)
            kmpkgDisableMetrics="ON"
            ;;
        -useSystemBinaries|--useSystemBinaries)
            echo "Warning: -useSystemBinaries no longer has any effect; ignored."
            ;;
        -allowAppleClang|--allowAppleClang)
            echo "Warning: -allowAppleClang no longer has any effect; ignored."
            ;;
        -buildTests)
            echo "Warning: -buildTests no longer has any effect; ignored."
            ;;
        -skipDependencyChecks)
            kmpkgSkipDependencyChecks="ON"
            ;;
        -musl)
            kmpkgUseMuslC="ON"
            ;;
        -help|--help)
            echo "Usage: ./bootstrap-kmpkg.sh [options]"
            echo
            echo "Options:"
            echo "    -help                 Display usage help"
            echo "    -disableMetrics       Mark this kmpkg root to disable metrics."
            echo "    -skipDependencyChecks Skip checks for kmpkg prerequisites."
            echo "    -musl                 Use the musl binary rather than the glibc binary on Linux."
            exit 0
            ;;
        *)
            echo "Unknown argument $var. Use '-help' for help."
            exit 1
            ;;
    esac
done

# Enable running from msys2/cygwin/bash on Windows
unixKernelName=$(uname -s | sed -E 's/(CYGWIN|MINGW|MSYS).*_NT.*/\1_NT/')
if [ "$unixKernelName" = "CYGWIN_NT" ] || [ "$unixKernelName" = "MINGW_NT" ] || [ "$unixKernelName" = "MSYS_NT" ]; then
    args=""
    [ "$kmpkgDisableMetrics" = "ON" ] && args="-disableMetrics"

    kmpkgRootDir=$(cygpath -aw "$kmpkgRootDir")
    cmd "/C $kmpkgRootDir\\bootstrap-kmpkg.bat $args" || exit 1
    exit 0
fi

# Check for minimal prerequisites
kmpkgCheckRepoTool() {
    tool=$1
    if [ "$kmpkgSkipDependencyChecks" = "OFF" ]; then
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "Could not find $tool. Please install it:"
            echo "Debian/Ubuntu: sudo apt-get install curl zip unzip tar"
            echo "Fedora/RHEL: sudo dnf install curl zip unzip tar"
            echo "Arch: sudo pacman -Syu base-devel git curl zip unzip tar cmake ninja"
            echo "Alpine: apk add build-base cmake ninja zip unzip curl git"
            exit 1
        fi
    fi
}

kmpkgCheckRepoTool curl
kmpkgCheckRepoTool zip
kmpkgCheckRepoTool unzip
kmpkgCheckRepoTool tar

UNAME=$(uname)
ARCH=$(uname -m)

if [ -e /etc/alpine-release ]; then
    kmpkgUseSystem="ON"
    kmpkgUseMuslC="ON"
fi

[ "$UNAME" = "OpenBSD" ] && kmpkgUseSystem="ON"

if [ "$kmpkgUseSystem" = "ON" ]; then
    kmpkgCheckRepoTool cmake
    kmpkgCheckRepoTool ninja
    kmpkgCheckRepoTool git
fi

# Read kmpkg-tool config
. "$kmpkgRootDir/scripts/kmpkg-tool-metadata.txt"

kmdoLink=~/.kmdo/links/kmpkg
# Link or build kmpkg
if [ -f $kmdoLink ]; then
    if ! [ -f "$kmpkgRootDir/kmpkg" ]; then
        # Copy the actual executable instead of linking
        cp -f "$(readlink -f $kmdoLink)" "$kmpkgRootDir/kmpkg"
        chmod +x "$kmpkgRootDir/kmpkg"
    fi
else
    kmpkgToolUrl="https://github.com/kumose/kmpkg-tool.git"
    baseBuildDir="$kmpkgRootDir/buildtrees/_kmpkg"
    buildDir="$baseBuildDir/build"
    srcBaseDir="$baseBuildDir/src"
    srcDir="$srcBaseDir/kmpkg-tool"

    [ -d "$baseBuildDir" ] && rm -rf "$baseBuildDir"

    echo "Cloning kmpkg-tool..."
    mkdir -p "$srcBaseDir" && cd "$srcBaseDir"
    git clone "$kmpkgToolUrl"
    cd -

    echo "Building kmpkg-tool..."
    mkdir -p "$buildDir"

    cmakeConfigOptions="-DCMAKE_BUILD_TYPE=Release -DKMPKG_DEVELOPMENT_WARNINGS=OFF"
    [ ! -z "$KMPKG_MAX_CONCURRENCY" ] && \
        cmakeConfigOptions="$cmakeConfigOptions -DCMAKE_JOB_POOL_COMPILE=compile -DCMAKE_JOB_POOL_LINK=link -DCMAKE_JOB_POOLS=compile=$KMPKG_MAX_CONCURRENCY;link=$KMPKG_MAX_CONCURRENCY"

    (cd "$buildDir" && cmake "$srcDir" $cmakeConfigOptions) || exit 1
    (cd "$buildDir" && cmake --build .) || exit 1

    rm -f "$kmpkgRootDir/kmpkg"
    cp "$buildDir/kmpkg" "$kmpkgRootDir/"
fi

"$kmpkgRootDir/kmpkg" version --disable-metrics

# Apply disable-metrics marker
if [ "$kmpkgDisableMetrics" = "ON" ]; then
    touch "$kmpkgRootDir/kmpkg.disable-metrics"
elif [ ! -f "$kmpkgRootDir/kmpkg.disable-metrics" ]; then
    cat <<EOF
Telemetry
---------
kmpkg collects usage data in order to help us improve your experience.
The data collected is anonymous.
You can opt-out by re-running this script with -disableMetrics,
or by setting KMPKG_DISABLE_METRICS in your environment.
EOF
fi
