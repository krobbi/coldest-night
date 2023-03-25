#!/usr/bin/env python

import os
import shutil
import subprocess
import sys

class BuildCommand:
    """
    Contains the actions and state for building the game. The build
    command expects to be run with the current working directory at the
    script directory.
    """
    
    NO: int = -1
    """ A constant representing a known false boolean state. """
    
    MAYBE: int = 0
    """ A constant representing an unknown boolean state. """
    
    YES: int = 1
    """ A constant representing a known true boolean state. """
    
    CHANNELS_PATH: str = "builds/channels.txt"
    """ The path to the channel list. """
    
    GODOT_PATH: str = "builds/godot_path.txt"
    """ The path to the Godot Engine path. """
    
    correct_dir_state: int = MAYBE
    """
    Whether the build command has the correct current working directory.
    """
    
    channels_state: int = MAYBE
    """ Whether the build command has channels. """
    
    channels: list[str]
    """ A list of available channels. """
    
    godot_state: int = MAYBE
    """ Whether the build command has Godot Engine. """
    
    godot: str = ""
    """ The path to Godot Engine. """
    
    def __init__(self) -> None:
        """ Initialize the build command's channel list. """
        
        self.channels = []
    
    
    def has_correct_dir(self) -> bool:
        """
        Return whether the build command has the correct current working
        directory.
        """
        
        if self.correct_dir_state != self.MAYBE:
            return self.correct_dir_state > self.MAYBE
        
        for dir_path in ("builds", "docs"):
            if not os.path.isdir(dir_path):
                print(f"Expected directory `{dir_path}` does not exist!")
                self.correct_dir_state = self.NO
                return False
        
        for file_path in ("build.py", "export_presets.cfg", "project.godot"):
            if not os.path.isfile(file_path):
                print(f"Expected file `{file_path}` does not exist!")
                self.correct_dir_state = self.NO
                return False
        
        self.correct_dir_state = self.YES
        return True
    
    
    def has_channels(self) -> bool:
        """ Return whether the build command has channels. """
        
        if self.channels_state != self.MAYBE:
            return self.channels_state > self.MAYBE
        
        if not self.has_correct_dir():
            self.channels_state = self.NO
            return False
        
        if not os.path.isfile(self.CHANNELS_PATH):
            print(f"Channel list at does not exist at `{self.CHANNELS_PATH}`!")
            self.channels_state = self.NO
            return False
        
        try:
            with open(self.CHANNELS_PATH) as file:
                channel_lines: list[str] = file.readlines()
        except IOError:
            print(f"Failed to read channel list at `{self.CHANNELS_PATH}`!")
            self.channels_state = self.NO
            return False
        
        for channel_line in channel_lines:
            channel: str = channel_line.strip()
            
            if channel and not channel in self.channels:
                self.channels.append(channel)
        
        if not self.channels:
            print(f"Channel list at `{self.CHANNELS_PATH}` is empty!")
            self.channels_state = self.NO
            return False
        
        self.channels_state = self.YES
        return True
    
    
    def has_channel(self, channel: str) -> bool:
        """ Return whether the build command has a channel. """
        
        if not self.has_channels():
            return False
        
        if not channel in self.channels:
            print(f"Channel `{channel}` does not exist!")
            return False
        
        return True
    
    
    def has_godot(self) -> bool:
        """ Return whether the build command has Godot Engine. """
        
        if self.godot_state != self.MAYBE:
            return self.godot_state > self.MAYBE
        
        if not self.has_correct_dir():
            self.godot_state = self.NO
            return False
        
        if not os.path.isfile(self.GODOT_PATH):
            print(f"Godot Engine path does not exist at `{self.GODOT_PATH}`!")
            self.godot_state = self.NO
            return False
        
        try:
            with open(self.GODOT_PATH) as file:
                self.godot = file.read().strip()
        except IOError:
            print(f"Failed to read Godot Engine path at `{self.GODOT_PATH}`!")
            self.godot_state = self.NO
            return False
        
        if not self.godot:
            print("Godot Engine path is empty!")
            self.godot_state = self.NO
            return False
        
        if not os.path.isfile(self.godot):
            print("No file was found at the Godot Engine path!")
            self.godot_state = self.NO
            return False
        
        try:
            subprocess.check_call([self.godot, "--version"])
        except (subprocess.CalledProcessError, OSError):
            print("Attempting to run Godot Engine caused an error!")
            self.godot_state = self.NO
            return False
        
        self.godot_state = self.YES
        return True
    
    
    def list_all_channels(self) -> bool:
        """ List all channels and return whether no errors occured. """
        
        if not self.has_channels():
            return False
        
        for channel in self.channels:
            print(channel)
        
        return True
    
    
    def clean_channel(self, channel: str) -> bool:
        """
        Clean a single channel and return whether no errors occured.
        """
        
        if not self.has_channel(channel):
            return False
        
        channel_path: str = os.path.realpath(f"builds/{channel}")
        
        for entry_name in os.listdir(channel_path):
            if entry_name == ".empty":
                continue
            
            entry_path: str = os.path.join(channel_path, entry_name)
            
            if os.path.isdir(entry_path):
                try:
                    shutil.rmtree(entry_path)
                except shutil.Error:
                    print(
                            f"Failed to delete the directory `{entry_path}` "
                            f"in channel `{channel}`!")
                    return False
            else:
                try:
                    os.remove(entry_path)
                except OSError:
                    print(
                            f"Failed to delete the file `{entry_path}` "
                            f"in channel `{channel}`!")
                    return False
        
        return True
    
    def clean_all_channels(self) -> bool:
        """ Clean all channels and return whether no errors occured. """
        
        if not self.has_channels():
            return False
        
        for channel in self.channels:
            if not self.clean_channel(channel):
                return False
        
        return True
    
    
    def export_channel(self, channel: str) -> bool:
        """
        Export a single channel and return whether no errors occured.
        """
        
        if not self.clean_channel(channel):
            return False
        
        if not self.has_godot():
            return False
        
        try:
            subprocess.check_call(
                    [self.godot, "--no-window", "--export", channel])
        except subprocess.CalledProcessError:
            print(f"Failed to export channel `{channel}`!")
            return False
        
        try:
            shutil.copy("docs/eula.md", f"builds/{channel}/readme.md")
        except shutil.Error:
            print(f"Failed to copy the EULA to channel `{channel}`!")
            return False
        
        return True
    
    
    def export_all_channels(self) -> bool:
        """
        Export all channels and return whether no errors occured.
        """
        
        if not self.has_channels():
            return False
        
        for channel in self.channels:
            if not self.export_channel(channel):
                return False
        
        return True
    
    
    def print_usage(self) -> None:
        """ Print the build command's usage. """
        
        print("Usage:")
        print("  build help             - Display a list of commands.")
        print("  build list             - Display a list of channels.")
        print("  build clean            - Clean all channels.")
        print("  build clean <channel>  - Clean a single channel.")
        print("  build export           - Export all channels.")
        print("  build export <channel> - Export a single channel.")
    
    
    def run(self, arguments: list[str]) -> bool:
        """
        Run the build command with arguments and return whether no
        errors occured.
        """
        
        if len(arguments) == 1:
            if arguments[0] == "help":
                self.print_usage()
                return True
            elif arguments[0] == "list":
                return self.list_all_channels()
            elif arguments[0] == "clean":
                return self.clean_all_channels()
            elif arguments[0] == "export":
                return self.export_all_channels()
        elif len(arguments) == 2:
            if arguments[0] == "clean":
                return self.clean_channel(arguments[1])
            elif arguments[0] == "export":
                return self.export_channel(arguments[1])
        
        self.print_usage()
        return False


def main(argv: list[str]) -> int:
    """
    Create and run a build command from system arguments and return an
    exit code.
    """
    
    if not argv:
        print("Failed to get arguments!")
        return 1
    
    try:
        script_path: str = os.path.dirname(os.path.realpath(__file__))
    except NameError:
        if argv[0] in ("", "-c"):
            print("Failed to get the script name from arguments!")
            return 1
        
        script_path: str = os.path.realpath(argv[0])
        
        if os.path.isfile(script_path):
            script_path = os.path.dirname(script_path)
    
    if not os.path.isdir(script_path):
        print("Failed to get the script path!")
        return 1
    
    return_path: str = os.path.realpath(os.getcwd())
    
    if not os.path.isdir(return_path):
        print("Failed to get the return path!")
        return 1
    
    os.chdir(script_path)
    
    build_command: BuildCommand = BuildCommand()
    exit_code: int = 0 if build_command.run(argv[1:]) else 1
    
    os.chdir(return_path)
    return exit_code


if __name__ == "__main__":
    sys.exit(main(sys.argv))
