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
    
    GODOT_PATH: str = "builds/godot_path.txt"
    """ The path to the Godot Engine path. """
    
    VERSION_PATH: str = "builds/version.txt"
    """ The path to the version tag. """
    
    VERSION_LOCK_PATH: str = "builds/version_lock.txt"
    """ The path to the locked version tag. """
    
    BUTLER_PATH: str = "builds/butler_path.txt"
    """ The path to the butler path. """
    
    BUTLER_TARGET: str = "krobbizoid/coldest-night"
    """ The target for butler to publish to. """
    
    CHANNELS: tuple[str] = ("win-demo", "linux-demo", "mac-demo")
    """ The available channels. """
    
    correct_dir_state: int = MAYBE
    """
    Whether the build command has the correct current working directory.
    """
    
    version_state: int = MAYBE
    """ Whether the build command has a version. """
    
    version: str = ""
    """ The game's current version tag. """
    
    version_lock: str = ""
    """ The game's published version tag. """
    
    godot_state: int = MAYBE
    """ Whether the build command has Godot Engine. """
    
    godot: str = ""
    """ The path to Godot Engine. """
    
    butler_state: int = MAYBE
    """ Whether the build command has butler. """
    
    butler: str = ""
    """ The path to butler. """
    
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
    
    
    def has_version(self) -> bool:
        """ Return whether the build command has a version. """
        
        if self.version_state != self.MAYBE:
            return self.version_state > self.MAYBE
        
        if not self.has_correct_dir():
            self.version_state = self.NO
            return False
        
        if not os.path.isfile(self.VERSION_PATH):
            print(f"Version tag does not exist at `{self.VERSION_PATH}`!")
            self.version_state = self.NO
            return False
        
        try:
            with open(self.VERSION_PATH) as file:
                self.version = file.read().strip()
        except IOError:
            print(f"Failed to read version tag at `{self.VERSION_PATH}`!")
            self.version_state = self.NO
            return False
        
        if not self.version:
            print("Version tag is empty!")
            self.version_state = self.NO
            return False
        
        if os.path.isfile(self.VERSION_LOCK_PATH):
            try:
                with open(self.VERSION_LOCK_PATH) as file:
                    self.version_lock = file.read().strip()
            except IOError:
                print(
                        "Failed to read version lock "
                        f"at `{self.VERSION_LOCK_PATH}`!")
                self.version_state = self.NO
                return False
        
        self.version_state = self.YES
        return True
    
    
    def has_butler(self) -> bool:
        """ Return whether the build command has butler. """
        
        if self.butler_state != self.MAYBE:
            return self.butler_state > self.MAYBE
        
        if not self.has_correct_dir():
            self.butler_state = self.NO
            return False
        
        if not os.path.isfile(self.BUTLER_PATH):
            print(f"butler path does not exist at `{self.BUTLER_PATH}`!")
            self.butler_state = self.NO
            return False
        
        try:
            with open(self.BUTLER_PATH) as file:
                self.butler = file.read().strip()
        except IOError:
            print(f"Failed to read butler path at `{self.BUTLER_PATH}`")
            self.butler = self.NO
            return False
        
        if not self.butler:
            print("butler path is empty!")
            self.butler_state = self.NO
            return False
        
        if not os.path.isfile(self.butler):
            print("No file was found at the butler path!")
            self.butler_state = self.NO
            return False
        
        try:
            subprocess.check_call([self.butler, "version"])
        except (subprocess.CalledProcessError, OSError):
            print("Attempting to run butler caused an error!")
            self.butler_state = self.NO
            return False
        
        self.butler_state = self.YES
        return True
    
    
    def list_all_channels(self) -> bool:
        """ List all channels and return whether no errors occured. """
        
        for channel in self.CHANNELS:
            print(channel)
        
        return True
    
    
    def clean_channel(self, channel: str) -> bool:
        """
        Clean a single channel and return whether no errors occured.
        """
        
        if not channel in self.CHANNELS:
            print(f"Channel `{channel}` does not exist!")
            return False
        
        if not self.has_correct_dir():
            return False
        
        channel_path: str = os.path.realpath(f"builds/{channel}")
        
        for entry_name in os.listdir(channel_path):
            if entry_name == ".itch":
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
        
        for channel in self.CHANNELS:
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
        
        for channel in self.CHANNELS:
            if not self.export_channel(channel):
                return False
        
        return True
    
    
    def publish_all_channels(self) -> bool:
        """
        Publish all channels and return whether no errors occured.
        """
        
        if not self.has_version():
            return False
        
        if self.version == self.version_lock:
            print("Protected against accidental publish using version lock!")
            return True
        
        self.version_lock = self.version
        
        try:
            with open(self.VERSION_LOCK_PATH, "w", newline="\n") as file:
                file.write(f"{self.version_lock}\n")
        except IOError:
            print("Failed to save locked version!")
            return False
        
        if not self.export_all_channels():
            return False
        
        if not self.has_butler():
            return False
        
        for channel in self.CHANNELS:
            try:
                subprocess.check_call(
                        [
                            self.butler,
                            "push",
                            f"builds/{channel}",
                            f"{self.BUTLER_TARGET}:{channel}",
                            "--userversion",
                            self.version
                        ])
            except subprocess.CalledProcessError:
                print(f"Failed to publish channel `{channel}`!")
                return False
        
        return True
    
    
    def print_usage(self) -> None:
        """ Print the build command's usage. """
        
        print("Usage:")
        print("  build help             - Display a list of commands.")
        print("  build list             - Display a list of channels.")
        print("  build test godot       - Test Godot Engine version.")
        print("  build test butler      - Test butler version.")
        print("  build clean            - Clean all channels.")
        print("  build clean <channel>  - Clean a single channel.")
        print("  build export           - Export all channels.")
        print("  build export <channel> - Export a single channel.")
        print("  build publish          - Publish all channels.")
    
    
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
            elif arguments[0] == "publish":
                return self.publish_all_channels()
        elif len(arguments) == 2:
            if arguments[0] == "test":
                if arguments[1] == "godot":
                    return self.has_godot()
                elif arguments[1] == "butler":
                    return self.has_butler()
            elif arguments[0] == "clean":
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
