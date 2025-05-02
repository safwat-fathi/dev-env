#!/bin/bash

# --- Helper Functions ---

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to ask Yes/No questions
ask_yes_no() {
  local prompt="$1"
  while true; do
    # Set default to No if input is empty
    read -p "$prompt [y/N]: " yn
    case $yn in
      [Yy]*) return 0 ;; # Yes
      [Nn]|"") return 1 ;; # No or Enter
      *) echo "Please answer yes (y) or no (n)." ;;
    esac
  done
}

# Function to detect the package manager
detect_package_manager() {
  if command_exists apt; then
    echo "apt"
  elif command_exists dnf; then
    echo "dnf"
  elif command_exists pacman; then
    echo "pacman"
  elif command_exists brew; then
    echo "brew"
  else
    echo "unknown"
  fi
}

# --- Main Script ---

echo "Starting Development Environment Setup..."
echo "-----------------------------------------"

# Determine Package Manager
PKG_MANAGER=$(detect_package_manager)
echo "Detected Package Manager: $PKG_MANAGER"

if [ "$PKG_MANAGER" == "unknown" ]; then
  echo "Error: Could not detect a supported package manager (apt, dnf, pacman, brew)."
  echo "Please install the required tools manually."
  exit 1
fi

# --- Check Prerequisites ---
echo "Checking prerequisites (git, curl/wget)..."
if ! command_exists git; then
  echo "Error: 'git' is required but not found. Please install git first."
  # Attempt to install git if possible
  if ask_yes_no "'git' not found. Attempt to install git?"; then
      case $PKG_MANAGER in
        apt) sudo apt update && sudo apt install -y git ;;
        dnf) sudo dnf install -y git ;;
        pacman) sudo pacman -Syu --noconfirm git ;;
        brew) brew install git ;;
        *) echo "Cannot automatically install git for this package manager." ;;
      esac
      if ! command_exists git; then
          echo "Error: Failed to install git. Please install it manually and restart the script."
          exit 1
      fi
      echo "Git installed successfully."
  else
      echo "Exiting because git is required."
      exit 1
  fi
fi
if ! command_exists curl && ! command_exists wget; then
   echo "Error: 'curl' or 'wget' is required but not found. Please install one of them first."
   # Attempt to install curl if possible
   if ask_yes_no "'curl' or 'wget' not found. Attempt to install curl?"; then
       case $PKG_MANAGER in
         apt) sudo apt update && sudo apt install -y curl ;;
         dnf) sudo dnf install -y curl ;;
         pacman) sudo pacman -Syu --noconfirm curl ;;
         brew) brew install curl ;;
         *) echo "Cannot automatically install curl for this package manager." ;;
       esac
       if ! command_exists curl; then
           echo "Error: Failed to install curl. Please install it manually and restart the script."
           exit 1
       fi
       echo "curl installed successfully."
   else
       echo "Exiting because curl or wget is required."
       exit 1
   fi
fi
echo "Prerequisites met."
echo "-----------------------------------------"

# --- Configure Git ---
if ask_yes_no "Configure global Git user name and email?"; then
    # Check if already configured
    current_git_name=$(git config --global user.name)
    current_git_email=$(git config --global user.email)

    default_name=${current_git_name:-"Your Name"}
    default_email=${current_git_email:-"you@example.com"}

    read -p "Enter your Git user name [$default_name]: " git_user_name
    git_user_name=${git_user_name:-$default_name} # Use default if empty

    read -p "Enter your Git user email [$default_email]: " git_user_email
    git_user_email=${git_user_email:-$default_email} # Use default if empty

    if [[ -n "$git_user_name" && "$git_user_name" != "Your Name" && -n "$git_user_email" && "$git_user_email" != "you@example.com" ]]; then
        git config --global user.name "$git_user_name"
        git config --global user.email "$git_user_email"
        echo "Git global user name and email configured."
        echo "Name: $(git config --global user.name)"
        echo "Email: $(git config --global user.email)"
    else
        echo "Skipping Git configuration as valid name and email were not provided."
    fi
else
    echo "Skipping Git configuration."
fi
echo "-----------------------------------------"


# --- Install Python 3, pip, and venv ---
echo "Checking for Python 3, pip, and venv..."
PYTHON_INSTALLED=false
PIP_INSTALLED=false
VENV_INSTALLED=false

if command_exists python3; then
    echo "Python 3 found: $(python3 --version)"
    PYTHON_INSTALLED=true
else
    echo "Python 3 not found."
fi

if command_exists pip3; then
    echo "pip3 found: $(pip3 --version | head -n 1)"
    PIP_INSTALLED=true
else
     # Sometimes pip is just 'pip' even for python3
     if command_exists pip && [[ "$(pip --version)" == *"python 3"* ]]; then
         echo "pip (for Python 3) found: $(pip --version | head -n 1)"
         PIP_INSTALLED=true
     else
        echo "pip for Python 3 not found."
     fi
fi

# Check venv by trying to access its help module
if python3 -m venv --help > /dev/null 2>&1; then
    echo "Python 3 venv module found."
    VENV_INSTALLED=true
else
    echo "Python 3 venv module not found."
fi

if ! $PYTHON_INSTALLED || ! $PIP_INSTALLED || ! $VENV_INSTALLED; then
    if ask_yes_no "Install Python 3, pip, and venv?"; then
        echo "Installing Python 3 components..."
        case $PKG_MANAGER in
            apt)
                sudo apt update
                sudo apt install -y python3 python3-pip python3-venv
                ;;
            dnf)
                sudo dnf install -y python3 python3-pip python3-virtualenv # dnf often uses virtualenv package for venv module
                ;;
            pacman)
                sudo pacman -Syu --noconfirm python python-pip python-virtualenv # Arch uses python, python-pip
                ;;
            brew)
                # Brew usually installs pip and provides venv with python
                brew install python
                ;;
        esac

        # Verify installation
        if command_exists python3; then echo "Python 3 installed: $(python3 --version)"; else echo "Python 3 installation failed."; fi
        if command_exists pip3 || (command_exists pip && [[ "$(pip --version)" == *"python 3"* ]]); then echo "pip for Python 3 installed."; else echo "pip installation failed."; fi
        if python3 -m venv --help > /dev/null 2>&1; then echo "venv module installed."; else echo "venv installation failed."; fi
    else
        echo "Skipping Python 3 installation."
    fi
else
    echo "Python 3, pip, and venv are already installed."
fi
echo "-----------------------------------------"


# --- Install Zsh ---
if ! command_exists zsh; then
  if ask_yes_no "Zsh is not installed. Install Zsh?"; then
    echo "Installing Zsh..."
    case $PKG_MANAGER in
      apt) sudo apt update && sudo apt install -y zsh ;;
      dnf) sudo dnf install -y zsh ;;
      pacman) sudo pacman -Syu --noconfirm zsh ;;
      brew) brew install zsh ;;
    esac
    if ! command_exists zsh; then
      echo "Error: Zsh installation failed."
      exit 1
    fi
    echo "Zsh installed successfully."
  else
    echo "Skipping Zsh installation."
    # If Zsh isn't installed, we can't proceed with Oh My Zsh or making it default
    echo "Cannot proceed with Oh My Zsh without Zsh. Exiting dependent steps."
    # Set a flag or exit if Zsh is absolutely required for later steps
    ZSH_ENABLED=false
  fi
else
  echo "Zsh is already installed."
  ZSH_ENABLED=true
fi

# --- Set Zsh as Default Shell ---
if $ZSH_ENABLED; then
    # Check if Zsh is the current user's default shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    zsh_path=$(which zsh)
    if [ "$current_shell" != "$zsh_path" ]; then
        if ask_yes_no "Zsh is not the default shell. Make Zsh the default shell?"; then
            echo "Setting Zsh as the default shell..."
            # Using 'chsh -s' requires user interaction (password) usually.
            # Inform the user they might need to enter password.
            echo "You might be prompted for your password to change the shell."
            if chsh -s "$zsh_path"; then
                echo "Zsh set as default. Please log out and log back in for the change to take effect."
            else
                echo "Error: Failed to set Zsh as default. You might need to run 'chsh -s $zsh_path' manually."
            fi
        else
            echo "Skipping setting Zsh as default shell."
        fi
    else
        echo "Zsh is already the default shell."
    fi
else
    echo "Skipping Zsh default shell setup because Zsh is not installed."
fi
echo "-----------------------------------------"


# --- Install Oh My Zsh ---
if $ZSH_ENABLED; then
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
      if ask_yes_no "Oh My Zsh is not installed. Install Oh My Zsh?"; then
        echo "Installing Oh My Zsh..."
        # Run the installer non-interactively; it will back up existing .zshrc if present
        if command_exists curl; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        elif command_exists wget; then
            sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi

        if [ -d "$HOME/.oh-my-zsh" ]; then
          echo "Oh My Zsh installed successfully."
          OMZ_INSTALLED=true
        else
          echo "Error: Oh My Zsh installation failed."
          OMZ_INSTALLED=false
        fi
      else
        echo "Skipping Oh My Zsh installation."
        OMZ_INSTALLED=false
      fi
    else
      echo "Oh My Zsh is already installed."
      OMZ_INSTALLED=true
    fi
else
    echo "Skipping Oh My Zsh installation because Zsh is not installed."
    OMZ_INSTALLED=false
fi
echo "-----------------------------------------"

# --- Install Oh My Zsh Plugins ---
# Only proceed if Oh My Zsh was installed or already exists
if $OMZ_INSTALLED; then
    ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    SYNTAX_HIGHLIGHTING_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    PLUGINS_TO_INSTALL=() # Array to hold names of plugins to install

    if [ ! -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
        PLUGINS_TO_INSTALL+=("zsh-syntax-highlighting")
    fi
     if [ ! -d "$AUTOSUGGESTIONS_DIR" ]; then
        PLUGINS_TO_INSTALL+=("zsh-autosuggestions")
    fi

    if [ ${#PLUGINS_TO_INSTALL[@]} -gt 0 ]; then
        plugin_list=$(printf ", %s" "${PLUGINS_TO_INSTALL[@]}") # Format list for prompt
        plugin_list=${plugin_list:2} # Remove leading comma and space
        if ask_yes_no "Install Oh My Zsh plugins ($plugin_list)?"; then
            echo "Installing plugins..."
            # Clone Syntax Highlighting if needed
            if [[ " ${PLUGINS_TO_INSTALL[@]} " =~ " zsh-syntax-highlighting " ]] && [ ! -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
                echo "Cloning zsh-syntax-highlighting..."
                git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_HIGHLIGHTING_DIR" || echo "Error cloning syntax-highlighting."
            fi
            # Clone Autosuggestions if needed
            if [[ " ${PLUGINS_TO_INSTALL[@]} " =~ " zsh-autosuggestions " ]] && [ ! -d "$AUTOSUGGESTIONS_DIR" ]; then
                echo "Cloning zsh-autosuggestions..."
                git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR" || echo "Error cloning autosuggestions."
            fi
            PLUGINS_CONFIGURED=true # Assume we want to configure if we installed
        else
            echo "Skipping Oh My Zsh plugin installation."
            PLUGINS_CONFIGURED=false
        fi
    else
        echo "Oh My Zsh plugins (zsh-syntax-highlighting, zsh-autosuggestions) seem to be installed."
        PLUGINS_CONFIGURED=true # Assume they are okay if directories exist
    fi

    # Add plugins to .zshrc if they were installed or already exist and user didn't skip install
    if $PLUGINS_CONFIGURED && [ -f "$HOME/.zshrc" ]; then
        echo "Checking .zshrc for plugins..."
        # Check and add zsh-syntax-highlighting
        if ! grep -q "plugins=(.*zsh-syntax-highlighting" "$HOME/.zshrc"; then
            echo "Adding zsh-syntax-highlighting to .zshrc plugins..."
            # Use awk for potentially safer modification than sed across systems
            awk -i inplace '/^plugins=\(/ {sub(/\)$/, " zsh-syntax-highlighting)"); print; next} {print}' "$HOME/.zshrc"
             if ! grep -q "plugins=(.*zsh-syntax-highlighting" "$HOME/.zshrc"; then # Verify addition
                 echo "Warning: Could not automatically add zsh-syntax-highlighting to plugins in .zshrc."
                 echo "Please add 'zsh-syntax-highlighting' to the plugins=(...) list in ~/.zshrc manually."
             fi
        else
            echo "zsh-syntax-highlighting already in .zshrc plugins."
        fi

        # Check and add zsh-autosuggestions
        if ! grep -q "plugins=(.*zsh-autosuggestions" "$HOME/.zshrc"; then
             echo "Adding zsh-autosuggestions to .zshrc plugins..."
             awk -i inplace '/^plugins=\(/ {sub(/\)$/, " zsh-autosuggestions)"); print; next} {print}' "$HOME/.zshrc"
             if ! grep -q "plugins=(.*zsh-autosuggestions" "$HOME/.zshrc"; then # Verify addition
                 echo "Warning: Could not automatically add zsh-autosuggestions to plugins in .zshrc."
                 echo "Please add 'zsh-autosuggestions' to the plugins=(...) list in ~/.zshrc manually."
             fi
        else
            echo "zsh-autosuggestions already in .zshrc plugins."
        fi
        echo "Plugin configuration updated. Please run 'source ~/.zshrc' or restart your shell."
    elif $PLUGINS_CONFIGURED; then
         echo "Warning: ~/.zshrc not found. Could not configure plugins."
    fi
else
    echo "Skipping Oh My Zsh plugin setup because Oh My Zsh is not installed."
fi
echo "-----------------------------------------"


# --- Install NVM ---
# Check if NVM sourcing line exists in .zshrc (better check than just dir)
NVM_INSTALLED=false
if grep -q 'export NVM_DIR="$HOME/.nvm"' "$HOME/.zshrc" && grep -q '[ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"' "$HOME/.zshrc"; then
    echo "NVM configuration found in ~/.zshrc."
    NVM_INSTALLED=true
    # Source NVM for the current script session
    export NVM_DIR="$HOME/.nvm"
    # Check if directory exists before sourcing
    if [ -s "$NVM_DIR/nvm.sh" ]; then
       \. "$NVM_DIR/nvm.sh" # This loads nvm
       [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
    else
        echo "Warning: NVM config found in .zshrc, but NVM directory ($NVM_DIR) seems missing or empty."
        NVM_INSTALLED=false # Treat as not installed if dir is bad
    fi
elif [ -d "$HOME/.nvm" ]; then
     echo "NVM directory found, but configuration might be missing from ~/.zshrc."
     # Source NVM for the current script session
     export NVM_DIR="$HOME/.nvm"
     [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
     NVM_INSTALLED=true # Consider it installed if dir exists
else
    echo "NVM not found."
fi


if ! $NVM_INSTALLED; then
  if ask_yes_no "NVM (Node Version Manager) is not installed. Install NVM?"; then
    echo "Installing NVM..."
    # NVM install script (fetches the latest version)
    NVM_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh" # Use a specific version for stability
     if command_exists curl; then
        curl -o- "$NVM_INSTALL_SCRIPT_URL" | bash
    elif command_exists wget; then
        wget -qO- "$NVM_INSTALL_SCRIPT_URL" | bash
    fi

    # Check if installation added lines to .zshrc and created the directory
    if [ -d "$HOME/.nvm" ] && grep -q 'export NVM_DIR="$HOME/.nvm"' "$HOME/.zshrc"; then
      echo "NVM installed successfully."
      echo "NVM configuration added to your ~/.zshrc. Please source it or restart your shell."
      # Source NVM for the current script session to install Node
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
      NVM_INSTALLED=true # Mark as installed for Node step
    else
      echo "Error: NVM installation failed or did not configure ~/.zshrc correctly."
      NVM_INSTALLED=false
    fi
  else
    echo "Skipping NVM installation."
  fi
fi

# --- Install Node.js via NVM ---
if $NVM_INSTALLED && command_exists nvm; then
    # Prompt for Node version only if nvm is usable
    read -p "Enter the Node.js version you want to install via NVM (e.g., --lts, latest, 20, 18.17.0) or leave empty to skip: " node_version
    if [ -n "$node_version" ]; then
        echo "Installing Node.js version: $node_version..."
        if nvm install "$node_version"; then
            # Make the installed version the default
            installed_version=$(nvm current) # Get the actual version string installed
            nvm alias default "$installed_version"
            echo "Node.js $installed_version installed via NVM and set as default."
        else
             echo "Error: Failed to install Node.js version $node_version using NVM."
        fi
    else
        echo "No Node.js version specified. Skipping Node.js installation via NVM."
    fi
elif $NVM_INSTALLED; then
     echo "NVM seems installed but the 'nvm' command is not available in this script session."
     echo "Cannot install Node.js via NVM automatically. Please run 'source ~/.zshrc' and then 'nvm install <version>' manually."
fi
echo "-----------------------------------------"


# --- Install VS Code ---
if ! command_exists code; then
  if ask_yes_no "Visual Studio Code is not installed. Install VS Code?"; then
    echo "Attempting to install VS Code..."
    INSTALL_CMD=""
    case $PKG_MANAGER in
      apt)
        # Try snap first as it's often preferred for VS Code on Ubuntu/Debian
        if command_exists snap; then
           INSTALL_CMD="sudo snap install code --classic"
        else
           # Fallback to apt repo method (more complex)
           echo "Snap not found. Trying apt repository method..."
           sudo apt update
           sudo apt install -y software-properties-common apt-transport-https wget gpg
           wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
           sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
           sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
           rm -f packages.microsoft.gpg # Clean up key file
           sudo apt update
           INSTALL_CMD="sudo apt install -y code"
        fi
        ;;
      dnf)
        # Fedora/CentOS method
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        sudo dnf check-update
        INSTALL_CMD="sudo dnf install -y code"
        ;;
      pacman)
        # Arch Linux - often in community repo or AUR
        # Check official repo first
        if pacman -Si code > /dev/null 2>&1; then
            INSTALL_CMD="sudo pacman -Syu --noconfirm code"
        else
            echo "VS Code not found in official Arch repositories."
            echo "You might need to install it from the AUR (e.g., using 'yay -S visual-studio-code-bin')."
            echo "Skipping automatic installation."
        fi
        ;;
      brew)
        # macOS
        INSTALL_CMD="brew install --cask visual-studio-code"
        ;;
    esac

    if [ -n "$INSTALL_CMD" ]; then
        echo "Running: $INSTALL_CMD"
        if eval $INSTALL_CMD; then # Use eval to handle potential complex commands with pipes/redirections if needed later
            echo "VS Code installed successfully."
        else
            echo "Error: VS Code installation failed. Please try installing it manually."
        fi
    elif [ "$PKG_MANAGER" != "pacman" ]; then # Pacman has its own message
         echo "Could not determine VS Code installation command for your system ($PKG_MANAGER)."
         echo "Please install it manually."
    fi
  else
    echo "Skipping VS Code installation."
  fi
else
  echo "Visual Studio Code is already installed."
fi
echo "-----------------------------------------"

# --- Install DBeaver Community ---
# Check common command names or application paths
DBEAVER_CMD="dbeaver-ce" # Snap/some package managers use this
if ! command_exists $DBEAVER_CMD && ! command_exists dbeaver; then
    if ask_yes_no "DBeaver Community Edition is not installed. Install DBeaver?"; then
        echo "Attempting to install DBeaver Community Edition..."
        INSTALL_SUCCESS=false
        case $PKG_MANAGER in
            apt)
                # Prefer Snap for easier installation on Debian/Ubuntu
                if command_exists snap; then
                    echo "Using Snap to install DBeaver..."
                    if sudo snap install dbeaver-ce; then
                        INSTALL_SUCCESS=true
                    else
                        echo "Snap installation failed. You might need to install manually from .deb package."
                    fi
                else
                    # Manual .deb download (more complex, might break if URL changes)
                    echo "Snap not found. Attempting manual .deb download (may fail if URL changes)..."
                    DBEAVER_DEB_URL=$(curl -s https://dbeaver.io/files/ | grep -oP 'dbeaver-ce_[\d\.]+_amd64\.deb' | head -n 1) # Try to find latest .deb
                    if [ -n "$DBEAVER_DEB_URL" ]; then
                        DBEAVER_DOWNLOAD_URL="https://dbeaver.io/files/$DBEAVER_DEB_URL"
                        echo "Downloading $DBEAVER_DEB_URL..."
                        if wget "$DBEAVER_DOWNLOAD_URL"; then
                            sudo apt update
                            if sudo dpkg -i "$DBEAVER_DEB_URL"; then
                                sudo apt --fix-broken install -y # Install dependencies
                                INSTALL_SUCCESS=true
                            else
                                echo "dpkg installation failed."
                            fi
                            rm "$DBEAVER_DEB_URL" # Clean up downloaded file
                        else
                            echo "Failed to download DBeaver .deb package."
                        fi
                    else
                        echo "Could not automatically find the DBeaver .deb download URL."
                    fi
                     if ! $INSTALL_SUCCESS; then echo "Please visit https://dbeaver.io/download/ and install manually."; fi
                fi
                ;;
            dnf)
                # Manual .rpm download for Fedora/CentOS
                echo "Attempting manual .rpm download (may fail if URL changes)..."
                DBEAVER_RPM_URL=$(curl -s https://dbeaver.io/files/ | grep -oP 'dbeaver-ce-[\d\.]+\.x86_64\.rpm' | head -n 1) # Try to find latest .rpm
                if [ -n "$DBEAVER_RPM_URL" ]; then
                    DBEAVER_DOWNLOAD_URL="https://dbeaver.io/files/$DBEAVER_RPM_URL"
                     echo "Downloading $DBEAVER_RPM_URL..."
                     if wget "$DBEAVER_DOWNLOAD_URL"; then
                         sudo dnf install -y "$DBEAVER_RPM_URL"
                         INSTALL_SUCCESS=$? # Check exit status of dnf install
                         rm "$DBEAVER_RPM_URL" # Clean up downloaded file
                     else
                         echo "Failed to download DBeaver .rpm package."
                     fi
                else
                    echo "Could not automatically find the DBeaver .rpm download URL."
                fi
                 if ! $INSTALL_SUCCESS; then echo "Please visit https://dbeaver.io/download/ and install manually."; fi
                ;;
            pacman)
                # Arch Linux - Usually via AUR
                echo "On Arch Linux, DBeaver is typically installed from the AUR (e.g., using 'yay -S dbeaver')."
                echo "Skipping automatic installation. Please install manually if needed."
                ;;
            brew)
                # macOS
                echo "Using Homebrew Cask to install DBeaver..."
                if brew install --cask dbeaver-community; then
                    INSTALL_SUCCESS=true
                fi
                ;;
        esac

        if $INSTALL_SUCCESS; then
            echo "DBeaver Community Edition installed successfully."
        else
            echo "Error: DBeaver installation failed or was skipped. Please try installing it manually from https://dbeaver.io/download/"
        fi
    else
        echo "Skipping DBeaver installation."
    fi
else
    echo "DBeaver Community Edition appears to be installed."
fi
echo "-----------------------------------------"


echo "Setup script finished."
echo "Remember to:"
# Only show Zsh login message if it was actually changed
if $ZSH_ENABLED && [ -n "$zsh_path" ] && [ "$current_shell" != "$zsh_path" ] && grep -q "$zsh_path" /etc/shells; then
    echo "  - Log out and log back in for Zsh to become your default shell."
fi
echo "  - Restart your terminal or run 'source ~/.zshrc' to apply Zsh/Oh My Zsh/NVM changes."

