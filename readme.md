![Coldest Night logo.](docs/header.png)  
_Space is lonely. A stealth-focused RPG in Godot Engine._  
__Version 0.7.0__  
__Copyright &copy; 2021-2023 Chris Roberts__ (Krobbizoid).  
_All rights reserved._

# Contents
1. [Coldest Night](#coldest-night)
2. [Running](#running)
3. [Building](#building)
4. [Known Issues](#known-issues)
   * [Issues Affecting All Platforms](#issues-affecting-all-platforms)
   * [Issues Affecting Windows](#issues-affecting-windows)
   * [Issues Affecting macOS](#issues-affecting-macos)
5. [Translating](#translating)
6. [Credits and Licensing](#credits-and-licensing)
7. [License](#license)

# Coldest Night
Coldest Night is a stealth-focused RPG being developed in
[Godot Engine](https://godotengine.org). The game is in development and may not
represent the quality of the final product. Significant changes may occur
between versions.

# Running
Pre-built demo versions of the game can be found on the
[GitHub releases page](https://github.com/krobbi/coldest-night/releases) and on
[itch.io](https://krobbizoid.itch.io/coldest-night). The Godot Engine project
source is located in the root direcory of this repository.

The current version of the game expects to be run on version `3.5.1` of Godot
Engine.

Running the game will create directories and files in a
`krobbizoid/coldest-night/` directory alongside the Godot Engine editor
data/settings folder (in `%AppData%` on Windows.)

# Building
See [docs/building.md](./docs/building.md) for detailed instructions on
building the game.

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

## Issues Affecting Windows
* Using an audio playback format with a sample rate other than 44100 Hz may
cause game audio to be distorted.

## Issues Affecting macOS
* The macOS app is not notarized and you may need to bypass security settings
in order to run it.
* The native macOS icon from versions `0.3.0` and below is poorly formatted and
may cause a crash when running the game.
* There is no native macOS icon between versions `0.4.0` and `0.6.0`.

# Translating
Coldest Night is fully translatable, although it is currently only available in
English. A table for translation keys in alphabetical order can be found at
`resources/translations/text.csv`.

More lengthy or complex translations are determined from their file paths:

| File type                | Naming convention                                      |
| :----------------------- | :----------------------------------------------------- |
| Credits files            | `resources/data/credits/credits_<locale>.txt`          |
| NightScript source files | `resources/data/nightscript/<program key>.<locale>.ns` |

NightScript source files may be given a 'global' locale by omitting the locale
extension. A global locale means that the script should not need to be
translated. If a complex script such as a cutscene needs to display
translatable text it can be given a global locale, but call external scripts
containing dialog by using the `call <program key>` statement. The appropriate
translation will be selected automatically.

If more than one locale is available to the game, a language menu will appear
in the settings menu, otherwise it will be hidden. The translation system
should respond automatically to the game's loaded locales and `locale/fallback`
project setting.

The story, character names, and other attributes may not be final and may
change.

# Credits and Licensing
See [docs/credits.md](./docs/credits.md) for a full copy of the credits.  
See [docs/eula.md](./docs/eula.md) for the end-user license agreement and
third-party license texts.

# License
Coldest Night is released under the Krobbizoid Game License (KGL):
https://krobbi.github.io/license/2021/2023/kgl.txt

See [license.txt](./license.txt) for a full copy of the license text.
