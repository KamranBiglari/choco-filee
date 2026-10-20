<#
.SYNOPSIS
  Installs the packed filee package from a local folder, checks it, uninstalls it and checks again.
  Meant for a throwaway machine (the CI runner): it really installs Filee.
#>
param(
  [Parameter(Mandatory)]
  [string]$Source
)

$ErrorActionPreference = 'Stop'

$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{C8686E06-8327-40A2-B0F7-3DEDD61D9248}_is1'
$exe = Join-Path $env:ProgramFiles 'Filee\Filee.exe'

function Invoke-Choco {
  choco @args --yes --no-progress
  if ($LASTEXITCODE -ne 0) { throw "choco $($args -join ' ') failed with exit code $LASTEXITCODE" }
}

Invoke-Choco install filee --source (Resolve-Path $Source).Path

if (-not (Test-Path $exe)) { throw "$exe is missing after install" }
if (-not (Test-Path $uninstallKey)) { throw 'Filee is not registered in Programs and Features after install' }
$installed = (Get-ItemProperty $uninstallKey).DisplayVersion
Write-Host "Installed Filee $installed at $exe"

Invoke-Choco uninstall filee

if (Test-Path $uninstallKey) { throw 'Filee is still registered in Programs and Features after uninstall' }
# Setup removes files Windows still holds at the next restart, so leftovers are only worth a warning.
if (Test-Path $exe) { Write-Warning "$exe is still there after uninstall" }
Write-Host 'Uninstalled Filee'
