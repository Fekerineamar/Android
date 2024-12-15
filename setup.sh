#!/usr/bin/env bash

# Define colors for output
RESET='\033[0m'
CYAN='\033[0;36m'
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'

# Display banner
echo -e "${CYAN}${BOLD}
    _    ___      __        ____             _     __
    | |  / (_)____/ /___  __/ __ \_________  (_)___/ /
    | | / / / ___/ __/ / / / / / ___/ __ \/ / __  / 
    | |/ / / /  / /_/ /_/ / /_/ / /  / /_/ / / /_/ /  
    |___/_/_/   \__/\__,_/_____/_/   \____/_/\__,_/   
                          
                          By Cody4code (@fekerineamar)     
${RESET}"

# Setup environment variables
setup_environment() {
    case "$(uname -s)" in
        Linux*)     
            OS_TYPE="linux"
            PACKAGE_MANAGERS=("apt-get" "dnf" "yum" "pacman")
            SDK_ROOT="$HOME/Android/Sdk"
            CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
            ;;
        Darwin*)    
            OS_TYPE="darwin"
            PACKAGE_MANAGERS=("brew")
            SDK_ROOT="$HOME/Library/Android/sdk"
            CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
            ;;
        *)  
            echo -e "${RED}Unsupported OS${RESET}"
            exit 1
            ;;
    esac

    TEMP_ZIP="commandlinetools.zip"
    AVD_NAME="Samsung_S23"
    SYSTEM_IMAGE="system-images;android-33;google_apis;x86_64"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install required dependencies
install_dependencies() {
    local deps=("wget" "unzip" "curl")
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            echo -e "${RED}$dep not found, installing...${RESET}"
            for pm in "${PACKAGE_MANAGERS[@]}"; do
                if command_exists "$pm"; then
                    case "$pm" in
                        apt-get)
                            sudo apt-get update && sudo apt-get install -y "$dep"
                            ;;
                        dnf|yum)
                            sudo "$pm" install -y "$dep"
                            ;;
                        pacman)
                            sudo pacman -S --noconfirm "$dep"
                            ;;
                        brew)
                            brew install "$dep"
                            ;;
                    esac
                    break
                fi
            done
        fi
    done
}

# Download and setup Android SDK with progress
setup_android_sdk() {
    mkdir -p "$SDK_ROOT/cmdline-tools"
    echo -e "${CYAN}Downloading Android SDK tools...${RESET}"
    wget --progress=bar:force -q "$CMDLINE_TOOLS_URL" -O "$TEMP_ZIP" || { echo -e "${RED}Failed to download SDK tools.${RESET}"; exit 1; }
    echo -e "${CYAN}Unzipping Android SDK tools...${RESET}"
    unzip -q "$TEMP_ZIP" -d "$SDK_ROOT/cmdline-tools/" || { echo -e "${RED}Failed to unzip SDK tools.${RESET}"; exit 1; }
    mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
    rm "$TEMP_ZIP"
    export PATH="$SDK_ROOT/cmdline-tools/latest/bin:$PATH"
}

# Install Android components
install_android_components() {
    echo -e "${CYAN}Accepting licenses and installing components...${RESET}"
    yes | sdkmanager --licenses
    sdkmanager "platform-tools" "platforms;android-33"
}

# Install System Image with or without Play Store based on user choice
install_system_image() {
    echo -e "${CYAN}Do you want to install a Google Play Store system image? (y/n): ${RESET}"
    read -r playstore_choice
    if [[ "$playstore_choice" == "y" || "$playstore_choice" == "Y" ]]; then
        SYSTEM_IMAGE="system-images;android-33;google_apis_playstore;x86_64"
        echo -e "${CYAN}Installing Google Play Store system image...${RESET}"
    else
        SYSTEM_IMAGE="system-images;android-33;google_apis;x86_64"
        echo -e "${CYAN}Installing system image without Google Play Store...${RESET}"
    fi
    sdkmanager "$SYSTEM_IMAGE"
}

# Main function
main() {
    setup_environment
    install_dependencies
    setup_android_sdk
    install_android_components
    install_system_image
    echo -e "${GREEN}Android Emulator setup complete!${RESET}"
}

main
