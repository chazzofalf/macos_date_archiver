#!/usr/bin/env python3
"""
archive_files.py

A utility script that:
1. Accepts a base output name and a list of input paths (files or directories).
2. Creates a temporary folder named with the base name and a timestamp.
3. Moves the input items into that folder.
4. Uses the macOS `ditto` command to create a zip archive that preserves
   extended attributes and resource forks.
5. Verifies the zip file exists and can be listed.
6. Trashes the temporary folder (which now contains the original items).

Usage:
    python3 archive_files.py -b BASE_NAME path1 [path2 ...]
"""

import argparse
import datetime
import os
import sys
import subprocess
import shutil

def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Archive files/folders into a timestamped zip preserving macOS attributes."
    )
    parser.add_argument(
        "-b",
        "--base",
        required=True,
        help="Base name for the output zip file (without extension).",
    )
    parser.add_argument(
        "paths",
        nargs="+",
        help="One or more files or directories to include in the archive.",
    )
    return parser.parse_args()

def timestamped_names(base_name):
    """Return (temp_folder_name, zip_file_name) with a timestamp."""
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    folder_name = f"{base_name}_{ts}"
    zip_name = f"{folder_name}.zip"
    return folder_name, zip_name

def move_items_to_folder(folder, items):
    """Create folder (if needed) and move each item (file or directory) into it."""
    os.makedirs(folder, exist_ok=True)
    for src in items:
        if not os.path.exists(src):
            print(f"Warning: '{src}' does not exist. Skipping.")
            continue
        dest = os.path.join(folder, os.path.basename(src.rstrip(os.sep)))
        try:
            shutil.move(src, dest)
        except Exception as e:
            print(f"Error moving '{src}' to '{dest}': {e}")
            sys.exit(1)
    print(f"All existing items moved into temporary folder '{folder}'.")

def run_ditto(source_folder, zip_path):
    """
    Run the macOS ditto command:
    ditto -ckV --keepParent --sequesterRsrc --zlibCompressionLevel 9 INPUTFOLDER OUTPUT
    Note: The -ckV flag (capital V) preserves the file permissions and metadata.
    """
    cmd = [
        "ditto",
        "-ckV",
        "--keepParent",
        "--sequesterRsrc",
        "--zlibCompressionLevel",
        "9",
        source_folder,
        zip_path,
    ]
    try:
        subprocess.run(cmd, check=True)
        print(f"Archive created with ditto: {zip_path}")
    except subprocess.CalledProcessError as e:
        print(f"Ditto command failed: {e}")
        sys.exit(1)

def verify_zip(zip_path):
    """Simple verification: ensure file exists and can be listed with unzip."""
    if not os.path.isfile(zip_path):
        print(f"Verification failed: archive '{zip_path}' not found.")
        return False
    try:
        subprocess.run(
            ["unzip", "-l", zip_path],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        print("Archive verification successful.")
        return True
    except Exception:
        print("Verification failed: unable to read archive contents.")
        return False

def trash_path(target):
    """Send a file or folder to the macOS Trash."""
    try:
        subprocess.run(["trash", target], check=True)
        print(f"Trashed: {target}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to trash '{target}': {e}")

def main():
    args = parse_arguments()
    temp_folder, zip_file = timestamped_names(args.base)

    # 1. Move all input items (files or directories) into the temp folder
    move_items_to_folder(temp_folder, args.paths)

    # 2. Create the zip archive with ditto (using -ckV flag)
    run_ditto(temp_folder, zip_file)

    # 3. Verify the archive
    if verify_zip(zip_file):
        # 4. Trash the temporary folder (original items are now inside the trash)
        trash_path(temp_folder)
    else:
        print("Archive verification failed. Temporary folder retained for inspection.")

if __name__ == "__main__":
    main()
