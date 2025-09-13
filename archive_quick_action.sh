#!/usr/bin/env bash
# ------------------------------------------------------------
# Single‑file Automator Quick Action
# ------------------------------------------------------------
# This script is meant to be pasted directly into Automator’s
# “Run Shell Script” action (Shell: /bin/bash, Pass input: as arguments).
#
# What it does:
#   1. Determines the parent folder of the first selected item.
#   2. Uses that folder’s name as the base name for the archive.
#   3. Writes an embedded Python helper (the full archive logic) to a
#      temporary file.
#   4. Executes the Python helper with the calculated base name and
#      all selected items.
#   5. Cleans up the temporary Python file.
#
# The embedded Python code is exactly the same as the previously
# provided archive_files.py, preserving macOS extended attributes via
# ditto, verifying the archive, and moving the originals to Trash.
# ------------------------------------------------------------

# ---- Step 1: Determine base name from the first item ----
if [[ $# -eq 0 ]]; then
    echo "No input items provided."
    exit 0
fi

first_item="$1"
parent_dir="$(dirname "$first_item")"
base_name="$(basename "$parent_dir")"

# ---- Step 2: Create a temporary Python script with the embedded code ----
PY_SCRIPT="$(mktemp /tmp/archive_helper.XXXXXX.py)"

cat >"$PY_SCRIPT" <<'PY_EOF'
#!/usr/bin/env python3
"""
Embedded archive helper (originally archive_files.py)
"""

import argparse
import datetime
import os
import sys
import subprocess
import shutil
import zipfile

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
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    folder_name = f"{base_name}_{ts}"
    zip_name = f"{folder_name}.zip"
    return folder_name, zip_name

def move_items_to_folder(folder, items):
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

def run_ditto(source_folder, zip_path):
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
    try:
        subprocess.run(["trash", target], check=True)
        print(f"Trashed: {target}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to trash '{target}': {e}")

def main():
    args = parse_arguments()
    temp_folder, zip_name = timestamped_names(args.base)
    output_dir = os.path.abspath(os.path.dirname(args.paths[0]))
    zip_file = os.path.join(output_dir, zip_name)

    move_items_to_folder(temp_folder, args.paths)
    run_ditto(temp_folder, zip_file)

    if verify_zip(zip_file):
        trash_path(temp_folder)
    else:
        print("Archive verification failed. Temporary folder retained for inspection.")

if __name__ == "__main__":
    main()
PY_EOF

chmod +x "$PY_SCRIPT"

# ---- Step 3: Execute the embedded Python helper ----
"$PY_SCRIPT" -b "$base_name" "$@"

# ---- Step 4: Clean up temporary Python script ----
rm -f "$PY_SCRIPT"
