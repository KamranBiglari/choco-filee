$ErrorActionPreference = 'Stop'

# Filee's Setup is Inno Setup (installer/Filee.iss upstream), x64 only, installed for all users.
$url64      = 'https://github.com/KnifeLemon/Filee/releases/download/v2.3.0/Filee-2.3.0-win-Setup.exe'
$checksum64 = '2eade31c9bb262706b2dd2a986c1c20999b57cd166f37f702a054c431e0bc400'

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
