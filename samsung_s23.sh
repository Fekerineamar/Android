#!/bin/bash

# Define colors
RESET='\033[0m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'

# Function to clear screen based on OS
clear_screen() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    clear
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
    cls
  fi
}

# Function to detect the OS and execute relevant commands
detect_os_and_run() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux-specific commands
    echo -e "${CYAN}${BOLD}
    _    ___      __        ____             _     __
    | |  / (_)____/ /___  __/ __ \_________  (_)___/ /
    | | / / / ___/ __/ / / / / / ___/ __ \/ / __  / 
    | |/ / / /  / /_/ /_/ / /_/ / /  / /_/ / / /_/ /  
    |___/_/_/   \__/\__,_/_____/_/   \____/_/\__,_/   
                          
                          By Cody4code (@fekerineamar)     ${RESET}"

    # Ensure dependencies are installed
   # List of required packages
    packages=(wget unzip curl)
    
    # Detect the package manager and install the packages
    if command -v apt-get &> /dev/null; then
      # For Debian-based systems (Ubuntu, Debian, etc.)
      sudo apt-get update
      for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
          echo -e "${YELLOW}$pkg is not installed. Installing...${RESET}"
          sudo apt-get install -y "$pkg"
        fi
      done
    
    elif command -v dnf &> /dev/null; then
      # For Fedora-based systems (Fedora, CentOS 8+, RHEL 8+)
      for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
          echo -e "${YELLOW}$pkg is not installed. Installing...${RESET}"
          sudo dnf install -y "$pkg"
        fi
      done
    
    elif command -v yum &> /dev/null; then
      # For older CentOS/RHEL (7 and below)
      for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
          echo -e "${YELLOW}$pkg is not installed. Installing...${RESET}"
          sudo yum install -y "$pkg"
        fi
      done
    
    elif command -v pacman &> /dev/null; then
      # For Arch Linux and Manjaro
      for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
          echo -e "${YELLOW}$pkg is not installed. Installing...${RESET}"
          sudo pacman -S --noconfirm "$pkg"
        fi
      done
    
    elif command -v brew &> /dev/null; then
      # For macOS with Homebrew
      for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
          echo -e "${YELLOW}$pkg is not installed. Installing...${RESET}"
          brew install "$pkg"
        fi
      done
    
    else
      echo -e "${RED}Error: Unsupported package manager or OS.${RESET}"
    fi


    # Variables
    CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    SDK_ROOT="$HOME/Android/Sdk"
    CMDLINE_TOOLS_DIR="$SDK_ROOT/cmdline-tools"
    TEMP_ZIP="commandlinetools.zip"
    AVD_NAME="Samsung_S23"
    SYSTEM_IMAGE="system-images;android-33;google_apis;x86_64"
    PLAY_STORE_IMAGE="system-images;android-33;google_apis_playstore;x86_64"

    # Download SDK if not already present
     # Download SDK if not already present
    if [ ! -d "$CMDLINE_TOOLS_DIR/latest" ]; then
      wget -q "$CMDLINE_TOOLS_URL" -O "$TEMP_ZIP"
      mkdir -p "$CMDLINE_TOOLS_DIR"
      unzip -q "$TEMP_ZIP" -d "$CMDLINE_TOOLS_DIR/"
      mv "$CMDLINE_TOOLS_DIR/cmdline-tools" "$CMDLINE_TOOLS_DIR/latest"
      rm "$TEMP_ZIP"
    fi


    export PATH="$CMDLINE_TOOLS_DIR/latest/bin:$PATH"

    # Install required components
    yes | sdkmanager --licenses
    sdkmanager "platform-tools" "platforms;android-33"

    # Ask if Play Store image is needed
    read -p "$(echo -e ${CYAN}Include Play Store image? (y/n): ${RESET})" INCLUDE_PLAY_STORE
    if [[ "$INCLUDE_PLAY_STORE" == "y" ]]; then
      SYSTEM_IMAGE=$PLAY_STORE_IMAGE
    fi
    sdkmanager "$SYSTEM_IMAGE"

    # Create AVD if not exists
    if ! avdmanager list avd | grep -q "$AVD_NAME"; then
      echo "no" | avdmanager create avd -n "$AVD_NAME" -k "$SYSTEM_IMAGE" --device "pixel_3"
    fi

    create_linux_shortcut
    emulator -avd "$AVD_NAME" &

    echo -e "${GREEN}Setup Complete! Emulator is running.${RESET}"

  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
    # Windows-specific commands
    echo -e "${CYAN}

     _    ___      __        ____             _     __
    | |  / (_)____/ /___  __/ __ \_________  (_)___/ /
    | | / / / ___/ __/ / / / / / ___/ __ \/ / __  / 
    | |/ / / /  / /_/ /_/ / /_/ / /  / /_/ / / /_/ /  
    |___/_/_/   \__/\__,_/_____/_/   \____/_/\__,_/   
                          
                          By Cody4code (@fekerineamar) 
    ${RESET}"

    # Check and install dependencies
    for cmd in wget unzip curl; do
      if ! command -v "$cmd" &> /dev/null; then
        echo -e "${YELLOW}$cmd is missing. Installing via Chocolatey...${RESET}"
        choco install "$cmd" -y
      fi
    done

    CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    SDK_ROOT="$HOME\\Android\\Sdk"
    CMDLINE_TOOLS_DIR="$SDK_ROOT\\cmdline-tools"
    TEMP_ZIP="commandlinetools.zip"
    AVD_NAME="Samsung_S23"
    SYSTEM_IMAGE="system-images;android-33;google_apis;x86_64"
    PLAY_STORE_IMAGE="system-images;android-33;google_apis_playstore;x86_64"

    if [ ! -d "$CMDLINE_TOOLS_DIR/latest" ]; then
      Invoke-WebRequest -Uri $CMDLINE_TOOLS_URL -OutFile $TEMP_ZIP
      mkdir -p "$CMDLINE_TOOLS_DIR"
      Expand-Archive -Path $TEMP_ZIP -DestinationPath $CMDLINE_TOOLS_DIR
      Rename-Item "$CMDLINE_TOOLS_DIR/cmdline-tools" "$CMDLINE_TOOLS_DIR/latest"
      Remove-Item $TEMP_ZIP
    fi

    Start-Process -Wait -NoNewWindow -FilePath "sdkmanager" -ArgumentList "--licenses"
    Start-Process -Wait -NoNewWindow -FilePath "sdkmanager" -ArgumentList "platform-tools", "platforms;android-33"

    read -p "$(echo -e ${CYAN}Include Play Store image? (y/n): ${RESET})" INCLUDE_PLAY_STORE
    if [[ "$INCLUDE_PLAY_STORE" == "y" ]]; then
      SYSTEM_IMAGE=$PLAY_STORE_IMAGE
    fi
    Start-Process -Wait -NoNewWindow -FilePath "sdkmanager" -ArgumentList "$SYSTEM_IMAGE"

    create_windows_shortcut
    Start-Process -Wait -NoNewWindow -FilePath "emulator" -ArgumentList "-avd $AVD_NAME"

    echo -e "${GREEN}Setup Complete! Emulator is running.${RESET}"
  else
    echo "Unsupported OS: $OSTYPE"
  fi
}

# Linux shortcut
create_linux_shortcut() {
  DESKTOP_FILE="$HOME/Desktop/Samsung_S23.desktop"
  ICON_PATH="$(pwd)/icon.png"

  if [ ! -f "$ICON_PATH" ]; then
    echo -e "${YELLOW}Icon file not found. Using default icon.${RESET}"
    ICON_PATH="/usr/share/icons/default.png"  # Fallback icon
  fi

  echo "[Desktop Entry]
  Name=Android Emulator
  Exec=emulator -avd Samsung_S23
  Icon=$ICON_PATH
  Terminal=false
  Type=Application
  Categories=Development;
  " > "$DESKTOP_FILE"
  chmod +x "$DESKTOP_FILE"
  echo -e "${GREEN}Shortcut created on Desktop.${RESET}"
}

# Windows shortcut
create_windows_shortcut() {
  # Determine the directory of the script
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  powershell -Command "
  \$WScript = New-Object -ComObject WScript.Shell
  \$Shortcut = \$WScript.CreateShortcut('$HOME\\Desktop\\Samsung_S23.lnk')
  \$Shortcut.TargetPath = '${SCRIPT_DIR//\//\\}\\emulator.exe'
  \$Shortcut.Arguments = '-avd Samsung_S23'
  \$Shortcut.IconLocation = '${SCRIPT_DIR//\//\\}\\icon.png'
  \$Shortcut.Save()
  "
  echo -e "${GREEN}Shortcut created on Desktop.${RESET}"
}


# Start script
clear_screen
detect_os_and_run
