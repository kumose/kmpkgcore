[CmdletBinding()]
param(
    $badParam,
    [Parameter(Mandatory=$False)][switch]$win64 = $false,
    [Parameter(Mandatory=$False)][string]$withVSPath = "",
    [Parameter(Mandatory=$False)][string]$withWinSDK = "",
    [Parameter(Mandatory=$False)][switch]$disableMetrics = $false
)
Set-StrictMode -Version Latest

if ($badParam)
{
    if ($disableMetrics -and $badParam -eq "1")
    {
        Write-Warning "'disableMetrics 1' is deprecated, please change to 'disableMetrics' (without '1')."
    }
    else
    {
        throw "Only named parameters are allowed."
    }
}

if ($win64) { Write-Warning "-win64 no longer has any effect; ignored." }
if (-Not [string]::IsNullOrWhiteSpace($withVSPath)) { Write-Warning "-withVSPath no longer has any effect; ignored." }
if (-Not [string]::IsNullOrWhiteSpace($withWinSDK)) { Write-Warning "-withWinSDK no longer has any effect; ignored." }

# Find .kmpkg-root
$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$kmpkgRootDir = $scriptsDir
while (!($kmpkgRootDir -eq "") -and !(Test-Path "$kmpkgRootDir\.kmpkg-root")) {
    Write-Verbose "Examining $kmpkgRootDir for .kmpkg-root"
    $kmpkgRootDir = Split-Path $kmpkgRootDir -Parent
}

Write-Verbose "Examining $kmpkgRootDir for .kmpkg-root - Found"

# 优先使用 kmdo 安装的 kmpkg
$kmdoKmpkg = Join-Path $env:USERPROFILE ".kmdo\bin\kmpkg.exe"
if (Test-Path $kmdoKmpkg) {
    # 拷贝真实文件到 repo 隔离
    if (-Not (Test-Path "$kmpkgRootDir\kmpkg.exe")) {
        Copy-Item -Path (Resolve-Path $kmdoKmpkg) -Destination "$kmpkgRootDir\kmpkg.exe" -Force
    }
} else {
    # 下载 kmpkg-tool
    $Config = ConvertFrom-StringData (Get-Content "$PSScriptRoot\kmpkg-tool-metadata.txt" -Raw)
    $versionDate = $Config.KMPKG_TOOL_RELEASE_TAG

    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_IDENTIFIER -match "ARMv[8,9] \(64-bit\)") {
        & "$scriptsDir\tls12-download-arm64.exe" github.com "/microsoft/kmpkg-tool/releases/download/$versionDate/kmpkg-arm64.exe" "$kmpkgRootDir\kmpkg.exe"
    } else {
        & "$scriptsDir\tls12-download.exe" github.com "/microsoft/kmpkg-tool/releases/download/$versionDate/kmpkg.exe" "$kmpkgRootDir\kmpkg.exe"
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Downloading kmpkg.exe failed. Please check your internet connection, or download manually from https://github.com/microsoft/kmpkg-tool."
        throw
    }
}

# 显示版本
& "$kmpkgRootDir\kmpkg.exe" version --disable-metrics

# 处理 disableMetrics
if ($disableMetrics) {
    Set-Content -Value "" -Path "$kmpkgRootDir\kmpkg.disable-metrics" -Force
} elseif (-Not (Test-Path "$kmpkgRootDir\kmpkg.disable-metrics")) {
    Write-Host @"
Telemetry
---------
kmpkg collects usage data in order to help us improve your experience.
The data collected by Microsoft is anonymous.
You can opt-out of telemetry by re-running the bootstrap-kmpkg script with -disableMetrics,
passing --disable-metrics to kmpkg on the command line,
or by setting the KMPKG_DISABLE_METRICS environment variable.

Read more about kmpkg telemetry at docs/about/privacy.md
"@
}
