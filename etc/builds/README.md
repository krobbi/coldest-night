[![Coldest Night logo.](/etc/images/logo.png)](/README.md)

# Contents
1. [Building Coldest Night](#building-coldest-night)
2. [Dependencies](#dependencies)
   * [Python](#python)
   * [Godot Engine](#godot-engine)
   * [Rcedit](#rcedit)
   * [Butler](#butler)
   * [Build Configuration File](#build-configuration-file)
2. [Channels](#channels)
3. [Running the Build Script](#running-the-build-script)

# Building Coldest Night
Coldest Night is built using a script. This document contains instructions for
installing the build script's dependencies and running it. Please read this
document carefully before attempting to build the game.

# Dependencies
Several dependencies must be installed for the build script to successfully
export and publish the game.

## Python
The build script is written in [Python](https://python.org), so a modern
version of Python must be installed to run it.

## Godot Engine
The game is created with [Godot Engine](https://godotengine.org), which is also
needed to export the game.

Different versions of the game expect different versions of Godot Engine, which
are shown in the table below:
| Game version      | Godot Engine version |
| :---------------- | :------------------- |
| `0.8.0`           | `4.0.2`              |
| `0.7.0`           | `3.5.1`              |
| `0.6.0`           | `3.4.4`              |
| `0.5.0`           | `3.4.2`              |
| `0.3.0` - `0.4.0` | `3.3.3`              |
| `0.0.0` - `0.2.0` | `3.3.2`              |

To export the game, export templates must be installed. This can be done in the
Godot Engine editor at `Editor > Manage Export Templates...`.

The game may need to be opened in the Godot Engine editor before exporting to
reimport assets (a progress bar may appear.)

The Godot Engine editor should be fully closed before running the build script.

## Rcedit
Godot Engine uses [rcedit](https://github.com/electron/rcedit) to set the icon
and metadata for Windows builds.

Download and save an rcedit executable and configure its path at
`Editor > Editor Settings... > Export > Windows > rcedit` in the Godot Engine
editor.

## Butler
The game is published to using [itch.io](https://itch.io) using
[butler](https://itchio.itch.io/butler). Butler is a command line tool that
allows games to be uploaded as patches with version numbers.

Butler is only used for publishing and does not need to be installed to create
local builds.

## Build Configuration File
The build script expects an [INI](https://en.wikipedia.org/wiki/INI_file)-style
configuration file at `etc/builds/build.cfg`. This provides the build script
with the commands to run Godot Engine and butler. Because this will vary
between users and may expose personal information, the build configuration file
is ignored by the repository.

```ini
; Both keys must be in a section named 'commands'.
[commands]

; A key named 'godot' must exist containing the path or command to run Godot
; Engine. Paths may be absolute, or relative to the build script.
godot=C:\Users\Username\Documents\Godot\Godot_v4.0.2-stable_win64.exe

; A key named 'butler' must exist containing the path or command to run butler.
; This may be dummied out (e.g. 'butler=echo') if butler is not installed or
; you do not intend on publishing.
butler=butler
```

# Channels
The game is built to three channels: `win-demo`, `linux-demo`, and `mac-demo`.
These correspond to the channel names on
[itch.io](https://krobbizoid.itch.io/coldest-night), the names of the build
output directories in `etc/builds/`, and the names of the export presets in the
Godot Engine project.

The build output directories each contain a `.itch` file. These are empty files
that allow the directories to be tracked by Git, but are ignored by butler. Do
not delete these files.

# Running the Build Script
Run the build script at `etc/builds/build.py`. This must be done through the
command line to provide arguments. The `build.bat` script allows Windows users
to run this as `build` from the root of the repository.

Several subcommands are available:
```shell
build.py clean [<channel>...]
```
Delete the build output for all channels. Optionally delete the build output
for one or more specified channels.

```shell
build.py export [<channel>...]
```
Clean and export all channels. Optionally clean and export one or more
specified channels. When exporting, the EULA at `etc/builds/eula.md` is copied
to each channel as `readme.md`.

```shell
build.py publish
```
Clean, export, and publish all channels. A randomized passcode must be entered
for safety.
