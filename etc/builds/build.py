#!/usr/bin/env python3

import configparser
import os
import random
import shutil
import subprocess
import sys

from collections.abc import Callable
from typing import Self

VERSION: str = "0.7.0"
""" The version tag to publish with. Only update when ready. """

CHANNELS: list[str] = ["win-demo", "linux-demo", "mac-demo"]
""" All available channels. """

PROJECT: str = "krobbizoid/coldest-night"
""" The itch.io project to publish to. """

godot: str = ""
""" The command for calling Godot Engine. """

butler: str = ""
""" The command for calling butler. """

has_checked_files: bool = False
""" Whether expected files have been checked for. """

has_checked_config: bool = False
""" Whether a config file has been checked for. """

has_checked_godot: bool = False
""" Whether a Godot Engine command has been checked for. """

has_checked_butler: bool = False
""" Whether a butler command has been checked for. """

class BuildError(Exception):
    """ An error raised by the build script. """
    
    message: str
    """ The build error's message. """
    
    def __init__(self: Self, message: str) -> None:
        """ Initialize the build error's message. """
        
        super().__init__(message)
        self.message = message


def call(*args: str) -> None:
    """ Call a subprocess and raise an error if it failed. """
    
    try:
        subprocess.check_call(args)
    except (subprocess.CalledProcessError, OSError):
        raise BuildError(f"Could not call subprocess.")


def check_files() -> None:
    """ Raise an error if expected files are not found. """
    
    global has_checked_files
    
    if has_checked_files:
        return
    
    for path in [
        "../../export_presets.cfg",
        "../../project.godot",
        "../.gdignore",
        "build.py",
        "eula.md",
    ] + [f"{channel}/.itch" for channel in CHANNELS]:
        if not os.path.isfile(path):
            raise BuildError("Run the build script from 'etc/builds/'.")
    
    has_checked_files = True


def check_config() -> None:
    """ Raise an error if a valid config file is not found. """
    
    global has_checked_config, godot, butler
    
    if has_checked_config:
        return
    
    check_files()
    
    if not os.path.isfile("build.cfg"):
        raise BuildError(f"Create a 'build.cfg' file.")
    
    try:
        config: configparser.ConfigParser = configparser.ConfigParser()
        config.read("build.cfg")
        godot = config.get("commands", "godot")
        butler = config.get("commands", "butler")
    except configparser.Error:
        raise BuildError(f"Could not parse 'build.cfg'.")
    
    has_checked_config = True


def check_godot() -> None:
    """ Raise an error if a valid Godot Engine command is not found. """
    
    global has_checked_godot
    
    if has_checked_godot:
        return
    
    print("Checking Godot Engine...")
    check_config()
    call(godot, "--version")
    has_checked_godot = True


def check_butler() -> None:
    """ Raise an error if a valid butler command is not found. """
    
    global has_checked_butler
    
    if has_checked_butler:
        return
    
    print("Checking butler...")
    check_config()
    call(butler, "version")
    has_checked_butler = True


def check_channel(channel: str) -> None:
    """ Raise an error if a channel does not exist. """
    
    check_files()
    
    if channel not in CHANNELS:
        raise BuildError(f"Channel '{channel}' does not exist.")


def is_entry_file(entry: os.DirEntry[str]) -> bool:
    """ Return whether a directory entry is a file or symbolic link. """
    
    if entry.is_file(follow_symlinks=False) or entry.is_symlink():
        return True
    
    try:
        return bool(os.readlink(entry))
    except OSError:
        return False


def clean_dir(path: str, depth: int = 0) -> None:
    """ Recursively clean a directory. May raise an OS error. """
    
    if depth >= 8:
        raise BuildError(f"Cleaning depth exceeded at '{path}'.")
    
    with os.scandir(path) as dir:
        for entry in dir:
            if entry.name == ".itch" and depth == 0:
                continue
            
            if is_entry_file(entry):
                os.remove(entry)
            elif entry.is_dir(follow_symlinks=False):
                clean_dir(entry.path, depth + 1)
                os.rmdir(entry)
            else:
                raise BuildError(f"Broken directory entry at '{entry.path}'.")


def clean_channel(channel: str) -> None:
    """ Clean a channel. """
    
    check_channel(channel)
    
    try:
        clean_dir(channel)
    except OSError:
        raise BuildError(f"Could not clean channel '{channel}'.")


def export_channel(channel: str) -> None:
    """ Clean and export a channel. """
    
    check_channel(channel)
    check_godot()
    
    clean_channel(channel)
    call(godot, "--path", "../..", "--headless", "--export-release", channel)
    
    try:
        shutil.copy("eula.md", f"{channel}/readme.md")
    except shutil.Error:
        raise BuildError(f"Could not copy 'eula.md' to channel '{channel}'.")


def publish_channel(channel: str) -> None:
    """ Publish an exported channel. """
    
    check_channel(channel)
    check_butler()
    
    call(
            butler, "push", f"--userversion={VERSION}", channel,
            f"{PROJECT}:{channel}")


def for_channels(channels: list[str], fn: Callable[[str], None]) -> None:
    """ Call a function for a set of channels. """
    
    for channel in channels:
        fn(channel)


def for_each_channel(fn: Callable[[str], None]) -> None:
    """ Call a function for each available channel. """
    
    for_channels(CHANNELS, fn)


def publish_all_channels() -> None:
    """ Clean, export, and publish all available channels. """
    
    passcode: str = f"v{VERSION}:{random.randint(1111, 9999)}"
    print(f"Are you sure you want to publish? Enter '{passcode}' to continue.")
    prompt: str = input("> ")
    
    if prompt == passcode:
        for_each_channel(export_channel)
        for_each_channel(publish_channel)
    else:
        print("Publishing canceled.")


def raise_usage_error() -> None:
    """ Raise a build command usage error. """
    
    raise BuildError(
            "Usage:"
            "\n * build.py clean               - Clean all channels."
            "\n * build.py clean <channel>...  - Clean one or more channels."
            "\n * build.py export              - Export all channels"
            "\n * build.py export <channel>... - Export one or more channels."
            "\n * build.py publish             - Publish all channels.")


def run_command(command: list[str]) -> None:
    """ Run a build command. """
    
    if len(command) == 1:
        if command[0] == "clean":
            for_each_channel(clean_channel)
        elif command[0] == "export":
            for_each_channel(export_channel)
        elif command[0] == "publish":
            publish_all_channels()
        else:
            raise_usage_error()
    elif len(command) > 1:
        if command[0] == "clean":
            for_channels(command[1:], clean_channel)
        elif command[0] == "export":
            for_channels(command[1:], export_channel)
        else:
            raise_usage_error()
    else:
        raise_usage_error()


def change_to_builds_path() -> None:
    """ Change to the builds path. """
    
    try:
        path: str = __file__
    except NameError:
        if not sys.argv or sys.argv[0] in ("", "-c"):
            raise BuildError("Could not find script path.")
        
        path = sys.argv[0]
    
    path = os.path.realpath(path)
    
    if os.path.isfile(path):
        path = os.path.dirname(path)
    
    if not os.path.isdir(path):
        raise BuildError("Could not find builds path.")
    
    try:
        os.chdir(path)
    except OSError:
        raise BuildError("Could not change to builds path.")


def main() -> None:
    """
    Run a build command from command line arguments and exit if an error
    occurred.
    """
    
    return_path: str = os.path.realpath(os.getcwd())
    
    if not os.path.isdir(return_path):
        sys.exit("Could not find return path.")
    
    try:
        change_to_builds_path()
        run_command(sys.argv[1:])
    except BuildError as build_error:
        sys.exit(build_error.message)
    finally:
        try:
            os.chdir(return_path)
        except OSError:
            sys.exit("Could not change to return path.")


if __name__ == "__main__":
    main()
