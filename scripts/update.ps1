<#
.SYNOPSIS
  Points the filee package at an upstream Filee release.

.DESCRIPTION
  Looks up the release on GitHub (the latest one by default), takes the SHA-256 of its win-Setup.exe and rewrites
  the version, release notes, URL and checksum in filee.nuspec and chocolateyInstall.ps1.
  Prints the package version and writes version/package_version to $GITHUB_OUTPUT when run in Actions.

.PARAMETER Version
  Upstream version (1.12.0 or v1.12.0). Defaults to the latest release.

.PARAMETER PackageVersion
  Chocolatey package version, when it must differ from the upstream one (a package fix: 1.12.0.20261020).
#>
param(
  [string]$Version,
  [string]$PackageVersion
)

$ErrorActionPreference = 'Stop'

$repo = 'KnifeLemon/Filee'
$root = Split-Path $PSScriptRoot -Parent
$nuspecPath  = Join-Path $root 'filee\filee.nuspec'
$installPath = Join-Path $root 'filee\tools\chocolateyInstall.ps1'

$headers = @{ 'Accept' = 'application/vnd.github+json'; 'User-Agent' = 'choco-filee' }
if ($env:GITHUB_TOKEN) { $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN" }

if ($Version) {
  $tag = 'v' + $Version.TrimStart('v')
  $release = Invoke-RestMethod -Headers $headers "https://api.github.com/repos/$repo/releases/tags/$tag"
} else {
  $release = Invoke-RestMethod -Headers $headers "https://api.github.com/repos/$repo/releases/latest"
}

$tag = $release.tag_name
$Version = $tag.TrimStart('v')
if (-not $PackageVersion) { $PackageVersion = $Version }

$assetName = "Filee-$Version-win-Setup.exe"
$asset = $release.assets | Where-Object name -eq $assetName
if (-not $asset) { throw "Release $tag has no $assetName" }
$url = $asset.browser_download_url

# GitHub records each asset's SHA-256; cross-check it with the release's own SHA256SUMS file.
$checksum = if ($asset.digest -match '^sha256:([0-9a-f]{64})$') { $Matches[1] }
$sums = $release.assets | Where-Object name -eq "Filee-$Version-SHA256SUMS.txt"
if ($sums) {
  $line = (Invoke-RestMethod -Headers @{ 'User-Agent' = 'choco-filee' } $sums.browser_download_url) -split "`n" |
    Where-Object { $_ -match [regex]::Escape($assetName) } | Select-Object -First 1
  if ($line -match '([0-9a-fA-F]{64})') {
    $listed = $Matches[1].ToLowerInvariant()
    if ($checksum -and $checksum -ne $listed) { throw "Checksum mismatch for ${assetName}: GitHub $checksum, SHA256SUMS $listed" }
    $checksum = $listed
  }
}
if (-not $checksum) {
  Write-Host "No published checksum for $assetName, downloading it"
  $tmp = Join-Path ([IO.Path]::GetTempPath()) $assetName
  Invoke-WebRequest -UseBasicParsing $url -OutFile $tmp
  $checksum = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLowerInvariant()
  Remove-Item $tmp
}

$current = ([xml][IO.File]::ReadAllText($nuspecPath)).package.metadata.version

$nuspec = [IO.File]::ReadAllText($nuspecPath)
$nuspec = $nuspec -replace '<version>[^<]*</version>', "<version>$PackageVersion</version>"
$nuspec = $nuspec -replace '<releaseNotes>[^<]*</releaseNotes>', "<releaseNotes>$($release.html_url)</releaseNotes>"
[IO.File]::WriteAllText($nuspecPath, $nuspec)

$install = [IO.File]::ReadAllText($installPath)
$install = $install -replace "(?m)^\`$url64\s*=\s*'[^']*'", "`$url64      = '$url'"
$install = $install -replace "(?m)^\`$checksum64\s*=\s*'[^']*'", "`$checksum64 = '$checksum'"
[IO.File]::WriteAllText($installPath, $install)

Write-Host "filee $current -> $PackageVersion ($tag, sha256 $checksum)"

if ($env:GITHUB_OUTPUT) {
  "version=$Version", "package_version=$PackageVersion" |
    Add-Content -Path $env:GITHUB_OUTPUT
}
