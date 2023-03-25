![Coldest Night logo.](header.png)

[Go back](../readme.md)

# Contents
1. [Building Coldest Night](#building-coldest-night)
2. [Channels](#channels)
3. [Versions](#versions)
4. [Dependencies](#dependencies)
5. [Building from the Command Line](#building-from-the-command-line)
6. [Building from Godot Engine](#building-from-godot-engine)

# Building Coldest Night
This document contains detailed instructions on how to build Coldest Night.
Please read it carefully before attempting to build the game.

There are two methods of building the game: building from the command line, and
building manually from the Godot Engine editor. Building from the command line
is recommended, and is more automatic, but requires more dependencies and
initial setup.

# Channels
The game is built to three channels: `win-demo`, `linux-demo`, and `mac-demo`.
These correspond to the channel names on
[itch.io](https://krobbizoid.itch.io/coldest-night), the names of the build
output directories in `builds/`, and the names of the export presets in the
Godot Engine project.

# Versions
Different versions of the game expect different target versions of Godot
Engine. Make sure you are using the correct versions before you open the
project in Godot Engine or build the game.

| Game version      | Target Godot Engine version |
| ----------------: | :-------------------------- |
| `0.7.0`           | `3.5.1`                     |
| `0.6.0`           | `3.4.4`                     |
| `0.5.0`           | `3.4.2`                     |
| `0.3.0` - `0.4.0` | `3.3.3`                     |
| `0.0.0` - `0.2.0` | `3.3.2`                     |

# Dependencies
The following dependencies are required by both methods of building the game:

* The appropriate version of [Godot Engine](https://godotengine.org) as listed
in the above table.
* The matching version of the Godot Engine export templates. These must be
installed from the Godot Engine editor by selecting
`Editor > Manage Export Templates...`.
* Optional, but recommended - export tools such as
[rcedit](https://github.com/electron/rcedit) and signtool set up in Godot
Engine's settings.

# Building from the Command Line
In addition to the above dependencies, building from the command line also
requires the following dependencies:

* A modern version of [Python](https://www.python.org) - at least version `3.5`
but preferably higher - that can be accessed from the command line as `python`.
* A file named `godot_path.txt` in `builds/` containing an absolute path to the
Godot Engine executable. This file is ignored by Git for privacy and
compatibility.

The build script itself is located in `build.py` alongside two wrapper scripts:
`build.bat` (for Windows), and `build` (for Linux and macOS). These wrapper
scripts are used to shorten the command so that it can be run from the command
line with `build <subcommand>`.

If you are using Linux or macOS you will need to make the wrapper script
executable by running the following command:

```
chmod +x build
```

If the build script isn't running correctly from the wrapper scripts, you can
try running it directly from Python with the following command:

```
python build.py <subcommand>
```

Once all of the requirements are met, the following commands should be
available from the root directory of the repository:

```
build help             - Display a list of commands.
build list             - Display a list of channels.
build clean            - Clean all channels.
build clean <channel>  - Clean a single channel.
build export           - Export all channels.
build export <channel> - Export a single channel.
```

The `build export` command will clean the relevant channels before building the
game. You do not need to run `build clean` beforehand.

After running `build export` the exported game will be available in the build
output directories at `builds/<channel>/`, including any additional files
normally distributed with the game. The `.empty` files in the build output
directories are not normally distributed.

There are plans for a command for publishing the game to itch.io, but this has
not yet been implemented.

# Building from Godot Engine
The following steps should be taken to successfully export the game from Godot
Engine:

1. Make sure that all of the [dependencies](#dependencies) have been met.
2. Clear all files from the build output directories at `builds/<channel>/`
except for the `.empty` files.
3. Open the game in the [correct version](#versions) of the Godot Engine
editor.
4. Wait for any assets to be reimported (a progress bar may appear).
5. Close the project settings menu. Select `Project > Export...` to open the
export menu.
6. Select `Export All... > Release` to begin exporting the game.
7. Wait for the exporting process to finish. You may now close the Godot Engine
editor.

In addition to the files generated in the build output directories, the
`/docs/eula.md` file is also included in each distribution as `readme.md`.
