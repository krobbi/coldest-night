# ![Coldest Night](header.png)
_Space is lonely_  
__A stealth-focused RPG in Godot Engine.__  
__Version 0.6.0__  
__Krobbizoid Proprietary-Open Game Development License__ -
https://krobbi.github.io/license/2021/2022/kpogdl.txt  
__Copyright &copy; 2021-2022 Chris Roberts__ (Krobbizoid).  
_All rights reserved._

# Contents
1. [Coldest Night](#coldest-night)
2. [Running](#running)
3. [Building](#building)
   * [Build Pipeline](#build-pipeline)
4. [Known Issues](#known-issues)
   * [Issues Affecting All Platforms](#issues-affecting-all-platforms)
   * [Issues Affecting MacOS](#issues-affecting-macos)
   * [Issues Affecting Windows](#issues-affecting-windows)
5. [Translating](#translating)
6. [Credits and Licensing](#credits-and-licensing)
7. [License](#license)

# Coldest Night
Coldest Night is a stealth-focused RPG being developed in
[Godot Engine](https://godotengine.org). The game is in development and may not
represent the quality of the final product. Significant changes may occur
between versions.

_Coldest Night is not affiliated with Godot Engine or its contributors._

# Running
Pre-built demo versions of the game can be found on the
[GitHub releases page](https://github.com/krobbi/coldest-night/releases) and on
[itch.io](https://krobbizoid.itch.io/coldest-night). The Godot Engine project
source can be found in the `src/` directory.

Running the game will create directories and files in a
`krobbizoid/coldest-night/` directory alongside the Godot Engine editor
data/settings folder (in `%AppData%` on Windows). This is known as the
`user://` directory.

__Do not distribute any builds or source material of the game.__

Below is a table containing the target versions of Godot Engine for each
version of Coldest Night:

| Game version      | Target Godot Engine version |
| :---------------- | :-------------------------- |
| `0.0.0` - `0.2.0` | `3.3.2`                     |
| `0.3.0` - `0.4.0` | `3.3.3`                     |
| `0.5.0`           | `3.4.2`                     |
| `0.6.0`           | `3.4.4`                     |

# Building
The following requirements should be fulfilled to successfully build the game
in release mode:

* The game should be exported from the Godot Engine editor in the target
version after the game's assets have been reimported.
* The `editor/convert_text_resources_to_binary_on_export` project setting must
be disabled.
* The `Coldest Night Development Toolkit` plugin must be enabled.
* The resource export mode must be `Export all resources in the project`.
* The resource include filter must include `*.ns` and `*.txt`.
* The GDScript export mode must be `Text`.

Building the game in release mode will write to the `tmp.res` and `tmp.scn`
files in the `user://` directory many times. There does not appear to be a
documented method of converting text resources to binary without disk usage by
using GDScript.

## Build Pipeline
The `Coldest Night Development Toolkit` plugin includes a 'build pipeline' that
performs the following actions on release builds of the game:

* Excludes unnecessary files from the game.
* Compiles NightScript source files to compiled NightScript files.
* Excludes GDScript source code between `# DEBUG:BEGIN` and `# DEBUG:END`
comment lines.
* Minifies GDScript source code and parses it to GDScript bytecode.
* Converts text resources to binary.
* Bypasses the default file remapping to reduce the size of remap files and
store remapped files at short, obfuscated paths.

# Known Issues
You may encounter the following issues when running the game:

## Issues Affecting All Platforms
* The internal payload format version of save files will only change between
public builds, which may result in corrupted save files when running
development versions.
* Using a high DPI display may cause issues as compatibility with high DPI
displays has not been tested.
* Setting controls to controller inputs may cause issues as mapping controller
inputs has not been tested.

## Issues Affecting MacOS
* There is no native icon for MacOS. The native icon from versions 0.3.0 and
below has been removed due to being poorly formatted and potentially causing a
crash when running the game.

## Issues Affecting Windows
* Using an audio playback format with a sample rate other than 44100 Hz may
cause game audio to be distorted.

# Translating
Coldest Night is now fully translatable, although it is currently only
available in English. A table for translation keys in alphabetical order can be
found at `src/assets/translations/text.csv`.

More lengthy or complex translations are determined from their file paths:

| File type                | Naming convention                                            |
| :----------------------- | :----------------------------------------------------------- |
| Credits files            | `src/assets/data/credits/credits_<locale>.txt`               |
| NightScript source files | `src/assets/data/nightscript/<locale>/<program key path>.ns` |

NightScript source files may have a 'global' locale, meaning they do not need
to be translated. If a complex script needs to display translatable text,
(such as in a cutscene,) it can be given a global locale, but call external
scripts containing dialog by using the `call <program key>` command. The
appropriate translation will be selected automatically.

If more than one locale is available to the game, a language menu will appear
in the settings menu, otherwise it will be hidden. The translation system
should respond automatically to the game's loaded locales and `locale/fallback`
project setting.

The story, character names, and other attributes may not be final and may
change.

# Credits and Licensing
See [CREDITS.md](./CREDITS.md) for a copy of the credits.  
See [dist/readme.md](./dist/readme.md) for the end-user license agreement and
third-party license texts.

`dist/readme.md` is a copy of the latest version of the distribution readme,
which is included with all releases of The Game.

# License
Coldest Night is released under the Krobbizoid Proprietary-Open Game
Development License (KPOGDL) -
https://krobbi.github.io/license/2021/2022/kpogdl.txt

See [LICENSE.txt](./LICENSE.txt) for a full copy of the license text.
