<p align="center">
  <img src="icons/filee.png" alt="Filee" width="96">
</p>

<h1 align="center">Filee for Chocolatey</h1>

<p align="center">
  Install <a href="https://filee.sh">Filee</a>, the free, open-source drag-and-drop file converter, with one command.
</p>

<p align="center">
  <a href="https://community.chocolatey.org/packages/filee"><img src="https://img.shields.io/chocolatey/v/filee?label=chocolatey" alt="Chocolatey version"></a>
  <a href="https://community.chocolatey.org/packages/filee"><img src="https://img.shields.io/chocolatey/dt/filee" alt="Chocolatey downloads"></a>
  <a href="https://github.com/KamranBiglari/choco-filee/actions/workflows/ci.yml"><img src="https://github.com/KamranBiglari/choco-filee/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
</p>

```powershell
choco install filee
```

Filee converts files offline by dragging them: hold <kbd>Ctrl</kbd>, drag files and drop them on a format in the donut
that opens at your cursor. It handles 255 formats, including images, PDF, Word, Excel, PowerPoint, HWP, e-books, video,
audio and archives, without Office or LibreOffice. See [filee.sh](https://filee.sh) and the
[Filee repository](https://github.com/KnifeLemon/Filee) for what it can do.

## Usage

```powershell
choco install filee     # install
choco upgrade filee     # update to the latest version
choco uninstall filee   # remove
```

Run them from an administrator shell. Filee installs for all users into `C:\Program Files\Filee`.

Requires Windows 10 version 1809 or later, 64-bit.

## Options

By default you get the same setup as the regular installer: Filee in the File Explorer right-click menu, Filee
starting when you sign in, and the [`filee` command](https://filee.sh/cli/) on PATH. Turn any of them off, or add a
desktop shortcut, with package parameters:

| Parameter        | Effect                                                |
|------------------|-------------------------------------------------------|
| `/NoContextMenu` | Don't add Filee to the File Explorer right-click menu |
| `/NoStartup`     | Don't start Filee when you sign in                    |
| `/NoCli`         | Don't add the `filee` command to PATH                 |
| `/DesktopIcon`   | Add a desktop shortcut                                |

```powershell
choco install filee --params "'/NoStartup /DesktopIcon'"
```

The right-click menu and sign-in options apply to a first install. After that, change them in Filee under
Settings → General; upgrades keep what you chose.

## Good to know

- **Filee starts after installing.** Look for it in the notification area of the taskbar. On a first install it also
  downloads the conversion engines its installer suggests by default. Manage engines in Settings → Engines.
- **Filee updates itself too.** Both ways of updating work: Filee's own updater and `choco upgrade filee`. If Filee has
  already updated itself, Chocolatey may list an older version than the one you're running.
- **Uninstalling keeps your settings** in `%APPDATA%\Filee`, so reinstalling picks up where you left off. Delete
  that folder to start fresh.
- **New versions are published automatically**, usually within a few hours of a Filee release, then appear once
  Chocolatey's moderators approve them.

## How the package works

The package contains no binaries. It downloads the official `Filee-<version>-win-Setup.exe` from
[Filee's GitHub releases](https://github.com/KnifeLemon/Filee/releases), checks it against the SHA-256 that Filee
publishes for that release, and runs it silently. See [chocolateyInstall.ps1](filee/tools/chocolateyInstall.ps1).

A [scheduled workflow](.github/workflows/publish.yml) picks up each new Filee release. It installs and uninstalls the
updated package on a clean Windows runner before pushing it to Chocolatey, and attaches the same `.nupkg` to this
repository's [releases](https://github.com/KamranBiglari/choco-filee/releases).

## Problems

- **Filee itself** (a conversion fails, a crash, a missing format): report it to
  [Filee's issue tracker](https://github.com/KnifeLemon/Filee/issues).
- **This package** (install or uninstall fails, a parameter doesn't work, the package is out of date): open an issue
  [here](https://github.com/KamranBiglari/choco-filee/issues). Include the output of the `choco` command, and the
  log at `%TEMP%\chocolatey\filee.<version>.Install.log` if there is one.

## Building it yourself

```powershell
./scripts/update.ps1                                  # point the package at the latest Filee release
choco pack filee/filee.nuspec --outputdirectory dist
choco install filee --source dist
```

[scripts/test.ps1](scripts/test.ps1) installs, checks and uninstalls the package as CI does. It really installs Filee,
so run it in a VM or Windows Sandbox.

## License

The packaging in this repository is licensed under the [Apache License 2.0](LICENSE). Filee is licensed separately,
under the [MIT License](https://github.com/KnifeLemon/Filee/blob/main/LICENSE). This package is maintained by the
community and isn't an official Filee release.
