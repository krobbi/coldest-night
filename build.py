#!/usr/bin/env python

import os
import shutil
import sys

from enum import Enum, auto

class Trit(Enum):
    """ A state that may be false, unknown, or true. """
    
    FALSE = auto()
    """ A state that is known to be false. """
    
    UNKNOWN = auto()
    """ An unknown state that may be resolved to true or false. """
    
    TRUE = auto()
    """ A state that is known to be true. """


class App:
    """ Build app. Stores the actions and state for building. """
    
    CHANNELS_PATH: str = "builds/channels.txt"
    """ The path to the channels configuration file. """
    
    GODOT_PATH_PATH: str = "builds/godot_path.txt"
    """ The path to the Godot Engine path configuration file. """
    
    channels_state: Trit = Trit.UNKNOWN
    """ The state of loading the channels list. """
    
    git_state: Trit = Trit.UNKNOWN
    """ The state of Git's availablity. """
    
    godot_state: Trit = Trit.UNKNOWN
    """ The state of Godot Engine's availablity. """
    
    channels: list[str]
    """ All channels. """
    
    godot_path: str = ""
    """ The path to the Godot Engine executable. """
    
    def __init__(self) -> None:
        """ Initialize the build app's channel list. """
        
        self.channels = []
    
    
    def load_config_string(self, path: str) -> str:
        """ Load a configuration string from its path. """
        
        if not os.path.isfile(path):
            return ""
        
        try:
            with open(path, "rt") as file:
                return file.read().strip()
        except IOError:
            return ""
    
    
    def run_godot(self, command: str) -> bool:
        """
        Return a Godot Engine command and return whether a zero exit
        code was returned.
        """
        
        command = f"{self.godot_path} --path . --no-window {command}"
        return os.system(command) == 0
    
    
    def validate_channels(self) -> bool:
        """
        Validate whether channels are available and log an error message
        if they are not.
        """
        
        if self.channels_state == Trit.UNKNOWN:
            channels_string: str = self.load_config_string(self.CHANNELS_PATH)
            
            for channel in channels_string.split("\n"):
                channel = channel.strip()
                
                if channel and not channel in self.channels:
                    self.channels.append(channel)
            
            if self.channels:
                self.channels_state = Trit.TRUE
            else:
                self.channels_state = Trit.FALSE
        
        if self.channels_state == Trit.TRUE:
            return True
        
        print(f"Expected a list of channels in '{self.CHANNELS_PATH}'!")
        return False
    
    
    def validate_channel(self, channel: str) -> bool:
        """
        Validate whether a single channel is available and log an error
        message if it is not.
        """
        
        if not self.validate_channels():
            return False
        
        if channel in self.channels:
            return True
        
        print(
                f"Channel '{channel}' does not exist! "
                "Use 'build list' for a list of channels.")
        return False
    
    
    def validate_git(self) -> bool:
        """
        Validate whether Git is available and log an error message if it
        is not.
        """
        
        if self.git_state == Trit.UNKNOWN:
            if os.system("git version"):
                self.git_state = Trit.FALSE
            else:
                self.git_state = Trit.TRUE
        
        if self.git_state == Trit.TRUE:
            return True
        
        print("Cannot complete the action as Git is unavailable!")
        return False
    
    
    def validate_godot(self) -> bool:
        """
        Validate whether Godot Engine is available and log an error
        message if it is not.
        """
        
        if self.godot_state == Trit.UNKNOWN:
            self.godot_path = self.load_config_string(self.GODOT_PATH_PATH)
            
            if not self.godot_path:
                print(
                        "Expected a path to the Godot Engine executable "
                        f"in '{self.GODOT_PATH_PATH}'!")
                self.godot_state = Trit.FALSE
                return False
            
            if not os.path.isfile(self.godot_path):
                print(
                        "Failed to find a file for the "
                        f"Godot Engine executable at '{self.godot_path}'!")
                self.godot_state = Trit.FALSE
                return False
            
            if self.run_godot("-q -quiet"):
                self.godot_state = Trit.TRUE
            else:
                self.godot_state = Trit.FALSE
        
        if self.godot_state == Trit.TRUE:
            return True
        
        print("Cannot complete the action as Godot Engine is unavailable!")
        return False
    
    
    def display_godot_info(self) -> bool:
        """
        Display verbose information about Godot Engine and return
        whether no errors occured.
        """
        
        if not self.validate_godot():
            return False
        
        return self.run_godot("-v -q")
    
    
    def list_all_channels(self) -> bool:
        """ List all channels and return whether no errors occured. """
        
        if not self.validate_channels():
            return False
        
        for channel in self.channels:
            print(channel)
        
        return True
    
    
    def clean_channel(self, channel: str) -> bool:
        """
        Clean a single channel and return whether no errors occured.
        """
        
        if not self.validate_git() or not self.validate_channel(channel):
            return False
        
        if os.system(f"git clean -d -f -x builds/{channel}"):
            print(f"Failed to clean channel '{channel}'!")
            return False
        
        return True
    
    
    def clean_all_channels(self) -> bool:
        """ Clean all channels and return whether no errors occured. """
        
        if not self.validate_git() or not self.validate_channels():
            return False
        
        for channel in self.channels:
            if not self.clean_channel(channel):
                return False
        
        return True
    
    
    def export_channel(self, channel: str) -> bool:
        """
        Export a single channel and return whether no errors occured.
        """
        
        if(
                not self.validate_git()
                or not self.validate_channel(channel)
                or not self.validate_godot()
                or not self.clean_channel(channel)):
            return False
        
        if not self.run_godot(f"--export {channel}"):
            print(f"Failed to export channel '{channel}'!")
            return False
        
        shutil.copy("docs/eula.md", f"builds/{channel}/readme.md")
        return True
    
    
    def export_all_channels(self) -> bool:
        """
        Export all channels and return whether no errors occured.
        """
        
        if(
                not self.validate_git()
                or not self.validate_channels()
                or not self.validate_godot()):
            return False
        
        for channel in self.channels:
            if not self.export_channel(channel):
                return False
        
        return True


def print_usage() -> None:
    """ Print the build script's argument usage. """
    
    print("Usage:")
    print("  build help             - Display a list of commands.")
    print("  build info             - Display information about Godot Engine.")
    print("  build list             - List all channels.")
    print("  build clean            - Clean all channels' build output.")
    print("  build clean <channel>  - Clean a single channel's build output.")
    print("  build export           - Export all channels.")
    print("  build export <channel> - Export a single channel.")


def run_app(args: list[str]) -> bool:
    """
    Run the build app from arguments and return whether no errors
    occured.
    """
    
    app: App = App()
    
    if len(args) == 1:
        if args[0] == "help":
            print_usage()
            return True
        elif args[0] == "info":
            return app.display_godot_info()
        elif args[0] == "list":
            return app.list_all_channels()
        elif args[0] == "clean":
            return app.clean_all_channels()
        elif args[0] == "export":
            return app.export_all_channels()
    elif len(args) == 2:
        if args[0] == "clean":
            return app.clean_channel(args[1])
        elif args[0] == "export":
            return app.export_channel(args[1])
    
    print_usage()
    return False


def main(args: list[str]) -> int:
    """ Run the build script with arguments and return an exit code. """
    
    if not __file__:
        print("Failed to get the build script path! Build the game manually.")
        return 1
    
    root_dir: str = os.path.dirname(os.path.realpath(__file__))
    
    if not os.path.isdir(root_dir):
        print("Failed to get the repository path! Build the game manually.")
        return 1
    
    return_dir: str = os.path.dirname(os.path.realpath(os.getcwd()))
    os.chdir(root_dir)
    
    exit_code: int = 0 if run_app(args) else 1
    
    os.chdir(return_dir)
    return exit_code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
