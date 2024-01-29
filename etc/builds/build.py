#!/usr/bin/env python3

import sys

def main() -> None:
    """ Run the build script from command line arguments. """
    # TODO: Implement build script. <krobbi>
    
    print("Running 'build.py' with arguments:")
    
    for index, value in enumerate(sys.argv):
        print(f" [{index}] - '{value}'")


if __name__ == "__main__":
    main()
