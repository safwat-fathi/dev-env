# Development Environment Setup Script - Detailed Description

This document provides a detailed explanation of the `setup_dev_env.sh` Bash script, designed to automate the installation and configuration of a common development environment on Linux (Debian/Ubuntu, Fedora, Arch) and macOS systems.

## Overview

The script guides the user through the installation of several key development tools:

1.  **Zsh (Z Shell):** An extended Bourne shell with many improvements.
2.  **Oh My Zsh:** A framework for managing Zsh configuration, themes, and plugins.
3.  **NVM (Node Version Manager):** A tool to manage multiple active Node.js versions.
4.  **Node.js:** A JavaScript runtime environment (installed via NVM).
5.  **Visual Studio Code:** A popular source code editor.

The script aims to be user-friendly by:

* Detecting the operating system's package manager.
* Checking for necessary prerequisites (`git`, `curl`/`wget`).
* Prompting the user for confirmation before installing each major component.
* Providing feedback on the success or failure of each step.

## Script Breakdown

### 1. Helper Functions

The script begins by defining several utility functions:

* `command_exists()`: Checks if a given command-line utility is available in the system's PATH.
* `ask_yes_no()`: Presents a prompt to the user and waits for a 'yes' (y) or 'no' (n) response. This is used to make the installation steps optional.
* `detect_package_manager()`: Determines which package manager (`apt`, `dnf`, `pacman`, `brew`) is available on the system. This allows the script to use the correct installation commands for different distributions/OS.

### 2. Initial Setup & Checks

* **Package Manager Detection:** Calls `detect_package_manager()` and stores the result. If no supported manager is found, the script exits with an error.
* **Prerequisite Check:** Uses `command_exists()` to ensure `git` and either `curl` or `wget` are installed, as these are required by subsequent installation steps (Oh My Zsh, NVM). Exits if prerequisites are missing.

### 3. Zsh Installation & Configuration

* **Check Installation:** Uses `command_exists zsh` to see if Zsh is already installed.
* **Prompt & Install:** If Zsh is not found, it calls `ask_yes_no()`. If the user agrees, it uses a `case` statement based on the detected `$PKG_MANAGER` to run the appropriate installation command (e.g., `sudo apt install -y zsh`). It checks again if the installation was successful. If the user declines or installation fails, the script exits as Zsh is fundamental for the next steps.
* **Set as Default Shell:**
    * It retrieves the user's current default shell using `getent passwd "$USER" | cut -d: -f7`.
    * It finds the path to the installed Zsh using `which zsh`.
    * If Zsh is not already the default, it prompts the user using `ask_yes_no()`.
    * If the user agrees, it attempts to change the default shell using `chsh -s "$zsh_path"`. **Note:** This change typically requires the user to log out and log back in to take effect.

### 4. Oh My Zsh Installation

* **Check Installation:** Checks if the `$HOME/.oh-my-zsh` directory exists.
* **Prompt & Install:** If the directory doesn't exist, it prompts the user. If agreed, it downloads and executes the official Oh My Zsh installation script using `curl` or `wget`. The `--unattended` flag is used to prevent the script from dropping the user into a new Zsh shell immediately.
* **Error Check:** Verifies if the `$HOME/.oh-my-zsh` directory was created successfully.

### 5. Oh My Zsh Plugins (Syntax Highlighting & Autosuggestions)

* **Check Prerequisite:** Only proceeds if Oh My Zsh is installed (`$HOME/.oh-my-zsh` exists).
* **Define Plugin Paths:** Sets variables for the expected plugin directories within the Oh My Zsh custom plugins folder (`$ZSH_CUSTOM/plugins/...`).
* **Check Installation:** Checks if both plugin directories already exist.
* **Prompt & Install:** If either plugin is missing, it prompts the user. If agreed, it uses `git clone` to download the `zsh-syntax-highlighting` and `zsh-autosuggestions` plugins into their respective directories.
* **Configure `.zshrc`:**
    * Checks if the plugins were installed (or already existed) and if `$HOME/.zshrc` exists.
    * Uses `grep` to check if `zsh-syntax-highlighting` and `zsh-autosuggestions` are already present in the `plugins=(...)` line within `.zshrc`.
    * If a plugin is missing from the list, it uses `sed` to attempt to add it. A backup of the original `.zshrc` is created (`.zshrc.bak`).
    * **Warning:** The `sed` command relies on a specific format (`plugins=(...)`). If the user has a highly customized `.zshrc`, automatic addition might fail, and the script prints a warning instructing manual addition.
    * Reminds the user to source `.zshrc` or restart the shell.

### 6. NVM (Node Version Manager) Installation

* **Check Installation:** Checks if the `$HOME/.nvm` directory exists.
* **Prompt & Install:** If the directory doesn't exist, it prompts the user. If agreed, it downloads and executes the official NVM installation script using `curl` or `wget`.
* **Post-Installation:**
    * If installation appears successful (directory exists), it sources the `nvm.sh` script into the *current* script's environment. This makes the `nvm` command available immediately for the next step.
    * It prompts the user to enter a desired Node.js version (e.g., `--lts`, `latest`, `20`).
    * If a version is provided, it uses `nvm install <version>` to install it and `nvm alias default <version>` to set it as the default Node.js version for future shell sessions.
    * Handles potential errors if the `nvm` command isn't found even after sourcing.

### 7. Visual Studio Code Installation

* **Check Installation:** Uses `command_exists code` to see if the VS Code command-line tool is available.
* **Prompt & Install:** If `code` is not found, it prompts the user. If agreed, it determines the correct installation method based on `$PKG_MANAGER`:
    * **apt (Debian/Ubuntu):** Tries `snap` first (common method). If `snap` isn't available, it falls back to adding the Microsoft APT repository and installing via `apt`.
    * **dnf (Fedora):** Adds the Microsoft YUM/DNF repository and installs via `dnf`.
    * **pacman (Arch):** Checks if `code` is available in the official repositories. If so, installs via `pacman`. If not, it informs the user they might need to use the AUR (Arch User Repository) and skips automatic installation.
    * **brew (macOS):** Installs using `brew install --cask visual-studio-code`.
* **Execute & Report:** Runs the determined installation command and reports success or failure.

### 8. Final Instructions

* Prints a "Setup script finished" message.
* Reminds the user to log out and log back in if Zsh was set as the default shell.
* Reminds the user to restart their terminal or run `source ~/.zshrc` to ensure all changes (Oh My Zsh plugins, NVM paths) are loaded into their active shell environment.

## How to Use

1.  **Save:** Save the script content to a file (e.g., `setup_dev_env.sh`).
2.  **Make Executable:** Open a terminal and run `chmod +x setup_dev_env.sh`.
3.  **Run:** Execute the script using `./setup_dev_env.sh`. Follow the prompts.

This script provides a solid foundation for setting up a development environment quickly and consistently across different systems.
