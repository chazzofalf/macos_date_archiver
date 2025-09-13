#!/usr/bin/env bash
# archive.sh – wrapper for archive_files.py
# This script can be called from any directory. It determines its own location
# and invokes the Python script that resides in the same folder, passing through
# all arguments unchanged.

# Resolve the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the Python script with all provided arguments
python3 "$SCRIPT_DIR/archive_files.py" "$@"
