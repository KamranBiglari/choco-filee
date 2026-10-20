$ErrorActionPreference = 'Stop'

# Filee's Setup is Inno Setup (installer/Filee.iss upstream), x64 only, installed for all users.
$url64      = 'https://github.com/KnifeLemon/Filee/releases/download/v1.12.0/Filee-1.12.0-win-Setup.exe'
$checksum64 = '3288794cf95c21254d22ade158ba7fcaa92ed64d445ebc197070370e806eb624'

$pp = Get-PackageParameters

# Inno Setup tasks from Filee.iss; tasks that are not listed keep their defaults.
$tasks = @()
if ($pp.NoContextMenu) { $tasks += '!contextmenu', '!contextmenu\top' }
if ($pp.NoStartup)     { $tasks += '!startup' }
if ($pp.NoCli)         { $tasks += '!cli' }
if ($pp.DesktopIcon)   { $tasks += 'desktopicon' }

$logFile = Join-Path $env:TEMP "$($env:ChocolateyPackageName).$($env:ChocolateyPackageVersion).Install.log"
$silentArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG=`"$logFile`""
if ($tasks) { $silentArgs += " /MERGETASKS=`"$($tasks -join ',')`"" }

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
  softwareName   = 'Filee'
  silentArgs     = $silentArgs
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
