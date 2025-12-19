[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Date
)

[string]$metadata = "KMPKG_TOOL_RELEASE_TAG=$Date`n"
Set-Content -LiteralPath "$PSScriptRoot\kmpkg-tool-metadata.txt" -Value $metadata -NoNewline -Encoding utf8NoBOM
& "$PSScriptRoot\bootstrap.ps1"
[string]$kmpkg = "$PSScriptRoot\..\kmpkg.exe"

# Windows arm64 (VS Code only)
& $kmpkg x-download "$PSScriptRoot\kmpkg-arm64.exe" `
    "--url=https://github.com/microsoft/kmpkg-tool/releases/download/$Date/kmpkg-arm64.exe" --skip-sha512

# Linux Binaries
foreach ($binary in @('macos', 'muslc', 'glibc', 'glibc-arm64')) {
    $caps = $binary.ToUpperInvariant().Replace('-', '_')
    & $kmpkg x-download "$PSScriptRoot\kmpkg-$binary" `
      "--url=https://github.com/microsoft/kmpkg-tool/releases/download/$Date/kmpkg-$binary" --skip-sha512
    $sha512 = & $kmpkg hash "$PSScriptRoot\kmpkg-$binary"
    $metadata += "KMPKG_$($caps)_SHA=$sha512`n"
}

# Source
$sourceName = "$Date.zip"
& $kmpkg x-download "$PSScriptRoot\$sourceName" `
    "--url=https://github.com/microsoft/kmpkg-tool/archive/refs/tags/$Date.zip" --skip-sha512
$sha512 = & $kmpkg hash "$PSScriptRoot\$sourceName"
$metadata += "KMPKG_TOOL_SOURCE_SHA=$sha512`n"

# Cleanup
Remove-Item @(
    "$PSScriptRoot\kmpkg-arm64.exe",
    "$PSScriptRoot\kmpkg-macos",
    "$PSScriptRoot\kmpkg-muslc",
    "$PSScriptRoot\kmpkg-glibc",
    "$PSScriptRoot\kmpkg-glibc-arm64",
    "$PSScriptRoot\$sourceName"
)

Set-Content -LiteralPath "$PSScriptRoot\kmpkg-tool-metadata.txt" -Value $metadata -NoNewline -Encoding utf8NoBOM

Write-Host "Metadata Written"
