# Development Environment Setup Script 

This document provides a detailed explanation of the `setup_dev_env.sh` Bash script, designed to automate the installation and configuration of a common development environment on Linux (Debian/Ubuntu, Fedora, Arch) and macOS systems.

## Overview

The script guides the user through the installation of several key development tools:

1.  **Git Configuration:** Sets up global user name and email.
2.  **Python 3, pip, venv:** Installs the Python 3 interpreter, package installer, and virtual environment tools.
3.  **Zsh (Z Shell):** An extended Bourne shell with many improvements.
4.  **Oh My Zsh:** A framework for managing Zsh configuration, themes, and plugins.
5.  **NVM (Node Version Manager):** A tool to manage multiple active Node.js versions.
6.  **Node.js:** A JavaScript runtime environment (installed via NVM).
7.  **Visual Studio Code:** A popular source code editor.
8.  **DBeaver Community Edition:** A universal database GUI tool.

The script aims to be user-friendly by:

* Detecting the operating system's package manager.
* Checking for necessary prerequisites (`git`, `curl`/`wget`) and attempting to install them if missing.
* Prompting the user for confirmation before installing each major component or performing configurations.
* Providing feedback on the success or failure of each step.

## Script Breakdown

### 1. Helper Functions

The script begins by defining several utility functions:

* `command_exists()`: Checks if a given command-line utility is available in the system's PATH.
* `ask_yes_no()`: Presents a prompt to the user and waits for a 'yes' (y) or 'no' (n) response (defaults to 'no' if Enter is pressed). This is used to make the installation steps optional.
* `detect_package_manager()`: Determines which package manager (`apt`, `dnf`, `pacman`, `brew`) is available on the system. This allows the script to use the correct installation commands for different distributions/OS.

### 2. Initial Setup & Checks

* **Package Manager Detection:** Calls `detect_package_manager()` and stores the result. If no supported manager is found, the script exits with an error.
* **Prerequisite Check:** Uses `command_exists()` to ensure `git` and either `curl` or `wget` are installed. If missing, it prompts the user and attempts to install them using the detected package manager before proceeding. Exits if prerequisites are missing and cannot be installed.

### 3. Git Configuration

* **Prompt:** Asks the user if they want to configure global Git settings.
* **Check Existing:** Retrieves current global `user.name` and `user.email` to use as defaults in the prompts.
* **Input:** Prompts the user to enter their desired Git user name and email address.
* **Apply:** If valid inputs (not the placeholder defaults) are provided, it uses `git config --global` to set the `user.name` and `user.email`.

### 4. Python 3, pip, and venv Installation

* **Check Installation:** Verifies if `python3`, `pip3` (or `pip` linked to Python 3), and the `venv` module are available.
* **Prompt & Install:** If any component is missing, it prompts the user. If agreed, it uses the detected package manager to install the necessary packages (e.g., `python3`, `python3-pip`, `python3-venv` on Debian/Ubuntu). Package names may vary slightly between distributions.
* **Verify:** After attempting installation, it re-checks the commands to confirm success or failure.

### 5. Zsh Installation & Configuration

* **Check Installation:** Uses `command_exists zsh` to see if Zsh is already installed.
* **Prompt & Install:** If Zsh is not found, it calls `ask_yes_no()`. If the user agrees, it uses a `case` statement based on the detected `$PKG_MANAGER` to run the appropriate installation command (e.g., `sudo apt install -y zsh`). It checks again if the installation was successful. Sets a flag (`ZSH_ENABLED`) based on whether Zsh is installed.
* **Set as Default Shell:**
    * Only proceeds if Zsh is enabled.
    * It retrieves the user's current default shell using `getent passwd "$USER" | cut -d: -f7`.
    * It finds the path to the installed Zsh using `which zsh`.
    * If Zsh is not already the default, it prompts the user using `ask_yes_no()`.
    * If the user agrees, it attempts to change the default shell using `chsh -s "$zsh_path"`. **Note:** This change typically requires the user to log out and log back in to take effect, and might require a password.

### 6. Oh My Zsh Installation

* **Check Prerequisite:** Only proceeds if Zsh is enabled.
* **Check Installation:** Checks if the `$HOME/.oh-my-zsh` directory exists.
* **Prompt & Install:** If the directory doesn't exist, it prompts the user. If agreed, it downloads and executes the official Oh My Zsh installation script using `curl` or `wget`. The `--unattended` flag is used to prevent the script from dropping the user into a new Zsh shell immediately. Sets a flag (`OMZ_INSTALLED`) based on success.
* **Error Check:** Verifies if the `$HOME/.oh-my-zsh` directory was created successfully.

### 7. Oh My Zsh Plugins (Syntax Highlighting & Autosuggestions)

* **Check Prerequisite:** Only proceeds if Oh My Zsh was installed (`OMZ_INSTALLED` is true).
* **Define Plugin Paths:** Sets variables for the expected plugin directories within the Oh My Zsh custom plugins folder (`$ZSH_CUSTOM/plugins/...`).
* **Check Installation:** Checks if both plugin directories already exist.
* **Prompt & Install:** If either plugin is missing, it prompts the user. If agreed, it uses `git clone` to download the `zsh-syntax-highlighting` and `zsh-autosuggestions` plugins into their respective directories.
* **Configure `.zshrc`:**
    * Checks if the plugins were installed (or already existed) and if `$HOME/.zshrc` exists.
    * Uses `grep` to check if `zsh-syntax-highlighting` and `zsh-autosuggestions` are already present in the `plugins=(...)` line within `.zshrc`.
    * If a plugin is missing from the list, it uses `awk -i inplace` (for better cross-system compatibility than `sed -i`) to attempt to add it to the `plugins` array.
    * **Warning:** If automatic addition fails (e.g., due to non-standard `.zshrc` format), the script prints a warning instructing manual addition.
    * Reminds the user to source `.zshrc` or restart the shell.

### 8. NVM (Node Version Manager) Installation

* **Check Installation:** Checks more reliably by looking for NVM initialization lines within `$HOME/.zshrc` and the existence of the `$HOME/.nvm` directory.
* **Source if Found:** If NVM seems installed, it attempts to source `nvm.sh` into the *current* script's environment to make the `nvm` command available.
* **Prompt & Install:** If NVM is not found, it prompts the user. If agreed, it downloads and executes the official NVM installation script using `curl` or `wget`.
* **Post-Installation Check:** Verifies if the NVM directory was created and if the configuration lines were added to `.zshrc`. Sources NVM for the current script session if installation succeeded.

### 9. Node.js Installation (via NVM)

* **Check Prerequisite:** Only proceeds if NVM was successfully installed and sourced (`NVM_INSTALLED` is true and `command_exists nvm`).
* **Prompt:** Asks the user to enter a desired Node.js version (e.g., `--lts`, `latest`, `20`) or leave blank to skip.
* **Install & Set Default:** If a version is provided, it uses `nvm install <version>` to install it and `nvm alias default <installed_version>` to set it as the default Node.js version for future shell sessions.

### 10. Visual Studio Code Installation

* **Check Installation:** Uses `command_exists code` to see if the VS Code command-line tool is available.
* **Prompt & Install:** If `code` is not found, it prompts the user. If agreed, it determines the correct installation method based on `$PKG_MANAGER`:
    * **apt (Debian/Ubuntu):** Tries `snap` first. If `snap` isn't available, it falls back to adding the Microsoft APT repository (using GPG key management best practices) and installing via `apt`.
    * **dnf (Fedora):** Adds the Microsoft YUM/DNF repository and installs via `dnf`.
    * **pacman (Arch):** Checks if `code` is available in the official repositories. If so, installs via `pacman`. If not, it informs the user they might need to use the AUR (Arch User Repository) and skips automatic installation.
    * **brew (macOS):** Installs using `brew install --cask visual-studio-code`.
* **Execute & Report:** Runs the determined installation command and reports success or failure.

### 11. DBeaver Community Edition Installation

* **Check Installation:** Checks common command names (`dbeaver-ce`, `dbeaver`).
* **Prompt & Install:** If not found, prompts the user. Installation logic varies:
    * **apt (Debian/Ubuntu):** Prefers `snap install dbeaver-ce`. Falls back to attempting to download the latest `.deb` package from dbeaver.io if snap fails or isn't available.
    * **dnf (Fedora):** Attempts to download the latest `.rpm` package from dbeaver.io and install it.
    * **pacman (Arch):** Informs the user that DBeaver is typically installed via the AUR and skips automatic installation.
    * **brew (macOS):** Uses `brew install --cask dbeaver-community`.
* **Error Handling:** Includes basic checks for download/installation success and provides manual installation instructions on failure.

### 12. Final Instructions

* Prints a "Setup script finished" message.
* Reminds the user to log out and log back in if Zsh was set as the default shell.
* Reminds the user to restart their terminal or run `source ~/.zshrc` to ensure all changes (Oh My Zsh plugins, NVM paths) are loaded into their active shell environment.

## How to Use

1.  **Save:** Save the script content to a file named `setup_dev_env.sh`.
2.  **Make Executable:** Open a terminal and run `chmod +x setup_dev_env.sh`.
3.  **Run:** Execute the script using `./setup_dev_env.sh`. Follow the prompts.

This script provides a solid foundation for setting up a development environment quickly and consistently across different systems.
