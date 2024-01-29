[![Coldest Night logo.](/etc/images/logo.png)](/README.md)  
_A prototype stealth game._  
__Version__ `0.8.0`  
__Godot Engine__ `4.0.2`  
__Copyright &copy; 2021-2024 Chris Roberts__ (Krobbizoid).  
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
6. [Credits](#credits)
7. [Licenses](#licenses)

# Coldest Night
Coldest Night is a stealth game being developed in
[Godot Engine](https://godotengine.org). The game is in a prototype stage and
may not represent its final quality. Significant changes may occur between
versions.

# Running
Pre-built demo versions of the game can be found on the
[GitHub releases page](https://github.com/krobbi/coldest-night/releases) and on
[itch.io](https://krobbizoid.itch.io/coldest-night). The Godot Engine project
source is located in the root direcory of this repository.

Running the game will create directories and files in a
`krobbizoid/coldest-night/` directory alongside the Godot Engine editor
data/settings folder (in `%AppData%` on Windows.)

# Building
See [docs/building.md](./docs/building.md) for detailed instructions on
building the game.

# Known Issues
You may encounter the following issues when running the game:

## Issues Affecting All Platforms
* The format version of save files will only change between public builds,
which may result in corrupted save files from running development versions.
* Using a high DPI display may cause issues as compatibility with high DPI
displays has not been tested.
* Controller buttons cannot be mapped to controls in versions `0.7.0` and below
unless they have an analog pressure input. (Not tested on real hardware.)
* Mapping controls to controller inputs may cause issues as controller inputs
have not been tested with real hardware.

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
The game's GUI and credits are fully translatable, although they are currently
only available in English. Cutscene dialogue is not yet translatable.

A table for translation keys in alphabetical order can be found at
`resources/translations/text.csv`.

The credits can be found at `scenes/credits/credits_<locale>.txt`.

If more than one locale is available to the game, a language menu will appear
in the settings menu, otherwise it will be hidden. The translation system
should respond automatically to the game's loaded locales and `locale/fallback`
project setting.

The story, character names, and other attributes may not be final and may
change.

# Credits
* Color palette: [Faraway48](https://lospec.com/palette-list/faraway48) by
[Igor Ferreira (Diemorth)](https://twitter.com/diemorth)
* Alternate font:
[Atkinson Hyperlegible](https://brailleinstitute.org/freefont) by
[Braille Institute of America, Inc.](https://brailleinstitute.org)

# Licenses
Coldest Night is released under the Krobbizoid Game License (KGL):  
https://krobbi.github.io/license/2021/2024/kgl.txt

See [LICENSE.txt](/LICENSE.txt) for a full copy of the license text.  
See [docs/eula.md](/docs/eula.md) for the end-user license agreement and
third-party license texts.

The game's default font 'Coldnight' is considered a separate, public domain
component. See [etc/font/README.md](/etc/font/README.md) for more information.
