$ErrorActionPreference = 'Stop'

# Filee's Setup is Inno Setup (installer/Filee.iss upstream), x64 only, installed for all users.
$url64      = 'https://github.com/KnifeLemon/Filee/releases/download/v2.0.0/Filee-2.0.0-win-Setup.exe'
$checksum64 = 'fe341f84cec4dab2d95aad2cbce1ffbae2459e278137778b9fb3800f46549d81'

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
