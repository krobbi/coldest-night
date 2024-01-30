#!/usr/bin/env python3

import os
import sys

from typing import Self

class BuildError(Exception):
    """ An error raised by the build script. """
    
    message: str
    """ The build error's message. """
    
    def __init__(self: Self, message: str) -> None:
        """ Initialize the build error's message. """
        
        super().__init__(message)
        self.message = message


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
    # TODO: Implement build command. <krobbi>
    
    return_path: str = os.path.realpath(os.getcwd())
    
    if not os.path.isdir(return_path):
        sys.exit("Could not find return path.")
    
    try:
        change_to_builds_path()
        print("Hello, build.py!")
    except BuildError as build_error:
        sys.exit(build_error.message)
    finally:
        try:
            os.chdir(return_path)
        except OSError:
            sys.exit("Could not change to return path.")


if __name__ == "__main__":
    main()
