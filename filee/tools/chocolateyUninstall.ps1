$ErrorActionPreference = 'Stop'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'
  validExitCodes = @(0)
}

[array]$keys = Get-UninstallRegistryKey -SoftwareName 'Filee'

if ($keys.Count -eq 1) {
  $packageArgs['file'] = $keys[0].UninstallString.Trim('"')
  Uninstall-ChocolateyPackage @packageArgs
} elseif ($keys.Count -eq 0) {
  Write-Warning "$($packageArgs.packageName) has already been uninstalled by other means."
} else {
  Write-Warning "$($keys.Count) matches found for 'Filee'. To prevent accidental data loss, no programs will be uninstalled."
  $keys | ForEach-Object { Write-Warning "- $($_.DisplayName)" }
}
