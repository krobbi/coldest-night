#!/usr/bin/env python3

import os
import random
import sys

from collections.abc import Callable
from typing import Self

VERSION: str = "0.7.0"
""" The version tag to publish with. Only update when ready. """

CHANNELS: list[str] = ["win-demo", "linux-demo", "mac-demo"]
""" All available channels. """

has_checked_files: bool = False
""" Whether expected files have been checked for. """

class BuildError(Exception):
    """ An error raised by the build script. """
    
    message: str
    """ The build error's message. """
    
    def __init__(self: Self, message: str) -> None:
        """ Initialize the build error's message. """
        
        super().__init__(message)
        self.message = message


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


def check_channel(channel: str) -> None:
    """ Raise an error if a channel does not exist. """
    
    if channel not in CHANNELS:
        raise BuildError(f"Channel '{channel}' does not exist.")


def clean_channel(channel: str) -> None:
    """ Clean a channel. """
    # TODO: Implement channel cleaning. <krobbi>
    
    check_files()
    check_channel(channel)
    print(f"Clean channel '{channel}'.")


def export_channel(channel: str) -> None:
    """ Clean and export a channel. """
    # TODO: Implement channel exporting. <krobbi>
    
    clean_channel(channel)
    print(f"Export channel '{channel}'.")


def publish_channel(channel: str) -> None:
    """ Publish an exported channel. """
    # TODO: Implement channel publishing. <krobbi>
    
    print(f"Publish channel '{channel}'.")


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
