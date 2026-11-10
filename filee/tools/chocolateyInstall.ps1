$ErrorActionPreference = 'Stop'

# Filee's own Setup (src/Filee.Setup upstream, since 2.0), x64 only, installed for all users. It takes the switches
# of the Inno Setup installer it replaced.
$url64      = 'https://github.com/KnifeLemon/Filee/releases/download/v2.4.0/Filee-2.4.0-win-Setup.exe'
$checksum64 = '8f8decc2ce6fb9b4415e64ea47a7bea8447abbd33b873dc8353a63c1ecba40e5'

$pp = Get-PackageParameters

# Setup tasks; tasks that are not listed keep their defaults.
$tasks = @()
if ($pp.NoContextMenu) { $tasks += '!contextmenu', '!contextmenu\top' }
if ($pp.NoStartup)     { $tasks += '!startup' }
if ($pp.NoCli)         { $tasks += '!cli' }
if ($pp.DesktopIcon)   { $tasks += 'desktopicon' }

$logFile = Join-Path $env:TEMP "$($env:ChocolateyPackageName).$($env:ChocolateyPackageVersion).Install.log"
$silentArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG=`"$logFile`""
if ($tasks) { $silentArgs += " /MERGETASKS=`"$($tasks -join ',')`"" }

# At the end Setup starts Filee as the user of the desktop shell. Without one (WinRM, SSH, SYSTEM: remote deployments
# and Chocolatey's package verifier) Setup starts Filee itself, Filee inherits Chocolatey's output pipes and the
# install never ends. There Filee is not started.
if (-not ('Filee.Choco.Shell' -as [type])) {
  Add-Type -Namespace Filee.Choco -Name Shell -MemberDefinition '[DllImport("user32.dll")] public static extern IntPtr GetShellWindow();'
}
$noShell = [Filee.Choco.Shell]::GetShellWindow() -eq [IntPtr]::Zero
if ($pp.NoLaunch -or $noShell) {
  $silentArgs += ' /NOLAUNCH'
  if ($noShell) { Write-Host 'No desktop session: Filee is not started after installing.' }
  # Filee gets the right-click menu and sign-in choices when Setup starts it; started later, it uses its defaults (on).
  if ($pp.NoContextMenu -or $pp.NoStartup) {
    Write-Warning "Filee isn't started after this install, so it can't take /NoContextMenu or /NoStartup. Turn them off in Filee under Settings > General."
  }
}

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
