# macOS Date Archiver Quick Action

## Overview

This repository provides a **self‑contained Bash script** (`archive_quick_action.sh`) that can be pasted into an Automator **Quick Action**.  
When run, it:

1. Determines the parent folder of the first selected Finder item and uses that folder’s name as the base name for the archive.
2. Packs the selected files/folders into a timestamped ZIP using macOS `ditto` with the `-ckV` flag to preserve extended attributes and resource forks.
3. Verifies the archive and moves the original items to the Trash.

The script embeds the full Python archiving logic (identical to `archive_files.py`) in a temporary file, so you only need a single script block in Automator.

## Quick Action Installation

1. **Open Automator** ( `/Applications/Automator.app` ).  
2. Choose **File → New** → **Quick Action** → **Choose**.  
3. Configure the top of the workflow:  

   * **Workflow receives current** → `files or folders`  
   * **in** → `Finder`

4. In the library on the left, drag **Run Shell Script** into the workflow area.  
5. Set the **Shell** to `/bin/bash` (or `/bin/zsh`).  
   Set **Pass input** to **as arguments**.  
6. Open `archive_quick_action.sh` in this repository, copy **the entire file contents**, and paste them into the script box in Automator.  
7. (Optional) Rename the Quick Action at the top, e.g. **“Archive with Timestamp”**.  
8. Save the Quick Action (`File → Save`). It will now appear in the Services menu and when you right‑click files/folders in Finder.

## Usage

1. Select one or more files/folders in Finder.  
2. Right‑click → **Quick Actions** → **Archive with Timestamp** (or the name you gave it).  
3. A ZIP file named `ParentFolder_YYYYMMDD_HHMMSS.zip` will be created in the current directory, preserving macOS metadata.  
4. The original items are moved to the Trash after successful verification.

## Development / Contribution

- The core archiving logic lives in the embedded Python script (derived from `archive_files.py`).  
- The Bash wrapper handles argument parsing and temporary script creation.  
- Feel free to fork, modify, and submit pull requests.

## Credits

This project was scaffolded with the assistance of:

- **Cline** – senior software engineer (guidance & implementation)  
- **Ollama** – local LLM integration  
- **gpt‑oss:120b** – open‑source language model used for code generation  

## License

This project is licensed under the MIT License – see the `LICENSE` file for details.

## Installation from GitHub

```bash
# Clone the repository
git clone https://github.com/chazzofalf/macos_date_archiver.git
cd macos_date_archiver

# (Optional) Open the script in your editor to review or customize
open archive_quick_action.sh
```

You can now follow the **Quick Action Installation** steps above.

**Note:** The archive is created in the same directory as the first selected item (the parent folder of the first file/folder you right‑click). This ensures the archive works correctly even when invoked from your home folder or any other location.
