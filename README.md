# choco-filee

Chocolatey package for [Filee](https://github.com/KnifeLemon/Filee), the free, open-source drag-and-drop file converter.

```powershell
choco install filee
```

The package downloads the official `Filee-<version>-win-Setup.exe` from the
[Filee releases](https://github.com/KnifeLemon/Filee/releases), checks its SHA-256 and runs it silently.

## Package parameters

| Parameter        | Effect                                                  |
|------------------|---------------------------------------------------------|
| `/NoContextMenu` | Don't add Filee to the File Explorer right-click menu   |
| `/NoStartup`     | Don't start Filee when you sign in                      |
| `/NoCli`         | Don't add the `filee` command to PATH                   |
| `/DesktopIcon`   | Add a desktop shortcut                                  |

```powershell
choco install filee --params "'/NoStartup /DesktopIcon'"
```

## How it is maintained

| Workflow | When | What |
|---|---|---|
| [CI](.github/workflows/ci.yml) | push, pull request | Packs the package, installs it on a Windows runner, checks it, uninstalls it |
| [Update and publish](.github/workflows/publish.yml) | every 6 hours, or by hand | Points the package at the latest Filee release, tests it, pushes it to the Chocolatey Community Repository, then commits, tags `v<version>` and creates a GitHub release with the `.nupkg` |

A version is published when this repository has no `v<version>` tag for it yet.

### Setup

1. Create an account on [community.chocolatey.org](https://community.chocolatey.org/) and copy your API key from
   your account page.
2. Add it to this repository as the secret `CHOCO_API_KEY` (Settings → Secrets and variables → Actions).
3. Set `<owners>` in [filee.nuspec](filee/filee.nuspec) to your Chocolatey user name.
4. Run **Update and publish** from the Actions tab, or wait for the schedule.

Every version goes through Chocolatey's moderation before it shows up in `choco install`.

### Manual run

**Update and publish** takes three optional inputs:

- **version**: an upstream version, such as `1.11.0`. Leave it blank for the latest release.
- **package_version**: a package fix for the same upstream version, such as `1.12.0.20261020`.
- **force**: publish even if the version is already tagged.

### Locally

```powershell
./scripts/update.ps1                  # latest release
./scripts/update.ps1 -Version 1.12.0  # a given release
choco pack filee/filee.nuspec --outputdirectory dist
./scripts/test.ps1 -Source dist       # installs Filee for real, use a VM
```
