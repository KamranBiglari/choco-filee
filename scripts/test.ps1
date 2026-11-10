<#
.SYNOPSIS
  Installs the packed filee package from a local folder, checks it, uninstalls it and checks again.
  Meant for a throwaway machine (the CI runner): it really installs Filee, and uninstalling deletes its engines.

.PARAMETER Headless
  Runs the test as SYSTEM from a scheduled task: no desktop shell, like Chocolatey's package verifier
  (chocolatey-test-environment, driven over WinRM) and remote deployments. A Setup that waits on something there
  fails after -Timeout instead of hanging.

.PARAMETER Timeout
  Seconds Chocolatey waits for the installer and for the uninstaller (the verifier allows 2700).
#>
param(
  [Parameter(Mandatory)]
  [string]$Source,
  [switch]$Headless,
  [int]$Timeout = 600,
  # Internal: where the headless run writes its output.
  [string]$LogFile
)

$ErrorActionPreference = 'Stop'
$Source = (Resolve-Path $Source).Path

if ($Headless) {
  $name = 'filee-package-test'
  $work = Join-Path $env:ProgramData $name
  New-Item -ItemType Directory -Force $work | Out-Null
  $log = Join-Path $work 'test.log'
  Remove-Item $log -ErrorAction SilentlyContinue
  $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $action = New-ScheduledTaskAction -Execute $powershell `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Source `"$Source`" -Timeout $Timeout -LogFile `"$log`""
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 2)
  Register-ScheduledTask -TaskName $name -Action $action -Settings $settings -User 'NT AUTHORITY\SYSTEM' -RunLevel Highest -Force | Out-Null
  try {
    Write-Host 'Running the test as SYSTEM, without a desktop shell'
    Start-ScheduledTask -TaskName $name
    $deadline = (Get-Date).AddSeconds(2 * $Timeout + 300)
    do {
      Start-Sleep -Seconds 5
      $state = (Get-ScheduledTask -TaskName $name).State
    } while ($state -in 'Running', 'Queued' -and (Get-Date) -lt $deadline)
    if ($state -in 'Running', 'Queued') {
      Stop-ScheduledTask -TaskName $name
      $result = 'timed out'
    } else {
      $result = (Get-ScheduledTaskInfo -TaskName $name).LastTaskResult
    }
    if (Test-Path $log) { Get-Content $log | Write-Host }
    if ($result -ne 0) { throw "The headless test failed ($result)" }
    exit 0
  } finally {
    Unregister-ScheduledTask -TaskName $name -Confirm:$false
  }
}

if ($LogFile) { Start-Transcript -Path $LogFile -Force | Out-Null }

$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{C8686E06-8327-40A2-B0F7-3DEDD61D9248}_is1'
$exe = Join-Path $env:ProgramFiles 'Filee\Filee.exe'

function Invoke-Choco {
  # Through Out-Host, so that a transcript records it.
  choco @args --yes --no-progress --execution-timeout $Timeout | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "choco $($args -join ' ') failed with exit code $LASTEXITCODE" }
}

try {
  Invoke-Choco install filee --source $Source

  if (-not (Test-Path $exe)) { throw "$exe is missing after install" }
  if (-not (Test-Path $uninstallKey)) { throw 'Filee is not registered in Programs and Features after install' }
  $installed = (Get-ItemProperty $uninstallKey).DisplayVersion
  Write-Host "Installed Filee $installed at $exe"
  $running = [bool](Get-Process Filee -ErrorAction SilentlyContinue)
  Write-Host "Filee running: $running"

  Invoke-Choco uninstall filee

  if (Test-Path $uninstallKey) { throw 'Filee is still registered in Programs and Features after uninstall' }
  # Setup removes files Windows still holds at the next restart, so leftovers are only worth a warning.
  if (Test-Path $exe) { Write-Warning "$exe is still there after uninstall" }
  Write-Host 'Uninstalled Filee'
} catch {
  Write-Host "FAILED: $_"
  exit 1
} finally {
  if ($LogFile) { Stop-Transcript | Out-Null }
}
