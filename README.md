# ![Coldest Night](header.png)
_Space is lonely_  
__A stealth-focused RPG in Godot__  
__Version 0.3.0__  
__Krobbizoid Proprietary-Open Game Development License__ -
https://krobbi.github.io/license/2021/kpogdl.txt  
__Copyright &copy; 2021 Chris Roberts__ (Krobbizoid)  
_All rights reserved._

# Contents
1. [About](#about)
2. [Demo](#demo)
3. [Settings](#settings)
4. [Known Issues](#known-issues)
   * [Issues Affecting All Platforms](#issues-affecting-all-platforms)
   * [Issues Affecting MacOS](#issues-affecting-macos)
   * [Issues Affecting Windows](#issues-affecting-windows)
5. [Documentation](#documentation)
6. [Credits](#credits)
   * [Development Team](#development-team)
   * [Tools and Resources](#tools-and-resources)
7. [License](#license)

# About
Coldest Night is a stealth-focused RPG made in [Godot](https://godotengine.org).
The game is in very early development and currently only contains basic
movement, background music, a radar display, and level transitions.

Running the game creates the directories `krobbizoid/coldest_night` alongside
the Godot editor data/settings folder (in `%AppData%` on Windows). This
directory is known as `user://`.

Quitting the game creates a `settings.cfg` file in the `user://` directory. This
is an INI-style file containing audio and display settings for the game.

Saving the game creates a `user://saves/` directory containing a `cn_save_1.dat`
file. This file has a custom binary format, and is typically less than 100 bytes
in the current version.

# Demo
Pre-built demo versions of Coldest Night are not yet available. The Godot
project source for the game can be found in the `src/` directory of this
repository.

# Settings
The settings file created by the game contains the following settings:

* `audio/main_volume` - The final output volume as a percentage.
* `audio/music_volume` - The volume of background music as a percentage.
* `audio/interface_volume` - The volume of user interface sound effects as a
percentage
* `display/display_mode` - The window mode of the game. This setting can be
toggled at any time by pressing `F11`.
   * `"windowed"` uses windowed mode.
   * `"fullscreen"` uses borderless window full-screen mode.
* `display/scale_mode` - The method used to scale the game's viewport to the
window. This setting can be toggled at any time by pressing `F12`.
   * `"stretch"` stretches the viewport to fill the entire window.
   * `"aspect"` makes the viewport as large as possible while maintaining its
   aspect ratio.
   * `"pixel"` uses 'pixel-perfect' scaling, so that each viewport pixel is a
   whole number of screen pixels across.
* `display/window_scale` - The scale of the window as a multiple of the game's
resolution (640x360). This setting can be adjusted at any time by pressing `F9`
and `F10`.
   * `"max"` uses the largest whole number window scale that can fit on the
   screen.
   * `"auto"` uses the largest whole number window scale that can fit on the
   screen with a 64-pixel margin on each axis. Useful if `"max"` causes the
   window to go off the screen.
   * __Numeric values__ will be rounded to the nearest whole number, and clamped
   between `1` and `"max"`. Invalid values, and values of `0` or below will
   default to `"auto"`.

# Known Issues
You may encounter the following issues when running Coldest Night or using the
Godot editor:

## Issues Affecting All Platforms
* The internal payload format version of save files will only change between
public builds, which may result in corrupted save files when running development
versions.
* Using a high DPI display may cause issues as compatibility with high DPI
displays has not been tested.

## Issues Affecting MacOS
* The MacOS native icons do not contain a 48x48 pixel icon image.

# Documentation
Documentation for Coldest Night is not yet available.

# Credits

## Development Team
__Lead Developer__ -
* [Chris Roberts (Krobbizoid)](https://twitter.com/krobbizoid)

## Tools and Resources
_The following credits list publicly-available tools and resources used in the
production of Coldest Night. These credits are not affiliated with Coldest Night
or its copyright holders._

__Game Engine__ -
* [Godot](https://godotengine.org) by
[its authors](https://github.com/godotengine/godot/blob/master/AUTHORS.md)

__Image Editor__ -
* [Krita](https://krita.org) by [KDE](https://kde.org)

__Color Palette__ -
* [Faraway48](https://lospec.com/palette-list/faraway48) by
[Igor Ferreira (Diemorth)](https://twitter.com/diemorth)

__Bitmap Font to TTF Converter__ -
* [Pixel Font Converter](https://yal.cc/r/20/pixelfont) by
[Vadim (YellowAfterlife)](https://twitter.com/yellowafterlife)

__Digital Audio Workstation__ -
* [LMMS](https://lmms.io) by
[its contributors](https://github.com/LMMS/lmms/graphs/contributors)

# License
Krobbizoid Proprietary-Open Game Development License -
https://krobbi.github.io/license/2021/kpogdl.txt

---

```
Krobbizoid Proprietary-Open Game Development License

Copyright (c) 2021 Chris Roberts
All rights reserved.

1. Definitions
- 'The License' refers to this license text, the Krobbizoid Proprietary-Open
Game Development License.

- 'The Copyright Holders' or 'COPYRIGHT HOLDERS' refers to the copyright holder
or copyright holders shown above in The License.

- 'Other Entities' refers to any person or organization other than
The Copyright Holders.

- 'The Software' or 'THE SOFTWARE' refers to any software or other files
included with or associated with The License.
'The Software' may include, but is not limited to: executable files, bundled
assets intended for use with executable files, documentation files, source
code, images, audio, video, text, configuration files, data files, and project
settings or project meta-data files.
'The Software' includes image, audio, video, and data files generated by The
Software in alternative formats from the source files in The Software.
'The Software' does NOT include configuration files or saved data files
generated by The Software.

- 'The Source Material' refers to all parts of The Software, as well as images,
audio, or video depicting The Software in use.
'The Source Material' also includes all intellectual property of The Copyright
Holders which is contained in The Software, such as fictional characters or
situations.

- 'The User' refers to any Other Entities who obtain a copy of The Software or
parts of The Software.
'The User' excludes retailers, file hosting services, content delivery
networks, and digital stores or distribution services.

- 'Fan Media' refers to any media produced by Other Entities, which uses, or is
based on The Source Material.
'Fan Media' includes physical artworks which are based on The Source Material.

- 'Mods' refers to software or data produced by Other Entities, with the
intention of being used for modifying The Software.

- 'Interactive Fan Media' refers to Fan Media in the form of software, such as
video games based on The Source Material.
'Interactive Fan Media' includes Mods.

- 'The Terms' refers to the permissions, conditions, and limitations applying
to The User as shown in The License.
'The Terms' includes the rights reserved by The Copyright Holders.


2. Outline
The License details the permissions, conditions, and limitations applying to
The User, as well as the rights reserved by The Copyright Holders (The Terms).

The Terms apply to The User upon obtaining a copy of The Software, or any parts
of The Software. The Terms apply free of charge, and without express permission
from The User or The Copyright Holders.
Other Entities who do not agree to The Terms should not obtain a copy of The
Software, or any parts of The Software.


3. Permissions
- The User may produce and distribute Fan Media.
- The User may use Fan Media commercially.
- The User may produce and distribute Mods.


4. Conditions
- Fan Media must be transformative from The Source Material.
- Fan Media must contain, or be associated with easily noticeable credits that
acknowledge the Fan Media's use of The Source Material.
- Interactive Fan Media must not be used commercially.
- Mods and Fan Media must not contain significant portions of The Software.


5. Limitations
- The User must not distribute copies of The Software or any parts of The
Software.
- The User must not produce or distribute physical merchandise that uses media
contained in The Software which is copyright of The Copyright Holders.
- Other Entities, Fan Media, or Mods must not falsely suggest that they are
affiliated with The Copyright Holders or The Source Material.


6. Reserved Rights
- Sources for obtaining The Software or parts of The Software may be made
unavailable at any time by The Copyright Holders.
- The Copyright Holders may distribute The Software commercially.
- The Copyright Holders may remove, request the removal of, or take legal
action against material which infringes on the copyright of The Source
Material, or Fan Media which does not comply with The Terms.
- Any permissions that are not explicitly granted to The User may be reserved
at any time by The Copyright Holders.


7. Disclaimer
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
