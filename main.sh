#!/bin/bash

# Define colors and formatting
RESET='\033[0m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'

# Determine the operating system and set paths
detect_os_and_set_paths() {
    case "$OSTYPE" in
        linux-gnu*)
            OS_TYPE="linux"
            SDK_ROOT="$HOME/Android/Sdk"
            CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
            PACKAGE_MANAGERS=("apt-get" "dnf" "yum" "pacman")
            ;;
        darwin*)
            OS_TYPE="darwin"
            SDK_ROOT="$HOME/Library/Android/sdk"
            CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
            PACKAGE_MANAGERS=("brew")
            ;;
        cygwin*|msys*)
            OS_TYPE="windows"
            SDK_ROOT="$USERPROFILE\\Android\\Sdk"
            CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
            PACKAGE_MANAGERS=("choco")
            ;;
        *)
            echo -e "${RED}Unsupported operating system: $OSTYPE${RESET}"
            exit 1
            ;;
    esac

    CMDLINE_TOOLS_DIR="$SDK_ROOT/cmdline-tools"
    TEMP_ZIP="commandlinetools.zip"
    AVD_NAME="Samsung_S23"
    SYSTEM_IMAGE="system-images;android-33;google_apis;x86_64"
    PLAY_STORE_IMAGE="system-images;android-33;google_apis_playstore;x86_64"
}

# Function to install dependencies
install_dependencies() {
    local packages=("wget" "unzip" "curl")
    
    case "$OS_TYPE" in
        linux)
            for pm in "${PACKAGE_MANAGERS[@]}"; do
                if command -v "$pm" &> /dev/null; then
                    case "$pm" in
                        apt-get)
                            sudo apt-get update
                            for pkg in "${packages[@]}"; do
                                if ! command -v "$pkg" &> /dev/null; then
                                    sudo apt-get install -y "$pkg"
                                fi
                            done
                            ;;
                        dnf)
                            for pkg in "${packages[@]}"; do
                                if ! command -v "$pkg" &> /dev/null; then
                                    sudo dnf install -y "$pkg"
                                fi
                            done
                            ;;
                        yum)
                            for pkg in "${packages[@]}"; do
                                if ! command -v "$pkg" &> /dev/null; then
                                    sudo yum install -y "$pkg"
                                fi
                            done
                            ;;
                        pacman)
                            for pkg in "${packages[@]}"; do
                                if ! command -v "$pkg" &> /dev/null; then
                                    sudo pacman -S --noconfirm "$pkg"
                                fi
                            done
                            ;;
                    esac
                    break
                fi
            done
            ;;
        darwin)
            if command -v brew &> /dev/null; then
                for pkg in "${packages[@]}"; do
                    if ! command -v "$pkg" &> /dev/null; then
                        brew install "$pkg"
                    fi
                done
            else
                echo -e "${RED}Homebrew not found. Please install Homebrew first.${RESET}"
                exit 1
            fi
            ;;
        windows)
            if command -v choco &> /dev/null; then
                for pkg in "${packages[@]}"; do
                    if ! command -v "$pkg" &> /dev/null; then
                        choco install "$pkg" -y
                    fi
                done
            else
                echo -e "${RED}Chocolatey not found. Please install Chocolatey first.${RESET}"
                exit 1
            fi
            ;;
    esac
}

# Function to download and setup Android SDK
setup_android_sdk() {
    mkdir -p "$CMDLINE_TOOLS_DIR"
    
    case "$OS_TYPE" in
        linux|darwin)
            wget -q "$CMDLINE_TOOLS_URL" -O "$TEMP_ZIP"
            unzip -q "$TEMP_ZIP" -d "$CMDLINE_TOOLS_DIR/"
            mv "$CMDLINE_TOOLS_DIR/cmdline-tools" "$CMDLINE_TOOLS_DIR/latest"
            rm "$TEMP_ZIP"
            ;;
        windows)
            # Use PowerShell for Windows download and extraction
            powershell -Command "
            Invoke-WebRequest -Uri $CMDLINE_TOOLS_URL -OutFile $TEMP_ZIP
            Expand-Archive -Path $TEMP_ZIP -DestinationPath $CMDLINE_TOOLS_DIR
            Rename-Item \"$CMDLINE_TOOLS_DIR/cmdline-tools\" \"$CMDLINE_TOOLS_DIR/latest\"
            Remove-Item $TEMP_ZIP
            "
            ;;
    esac

    # Update PATH
    export PATH="$CMDLINE_TOOLS_DIR/latest/bin:$PATH"
}

# Function to install Android components
install_android_components() {
    case "$OS_TYPE" in
        linux|darwin)
            yes | sdkmanager --licenses
            sdkmanager "platform-tools" "platforms;android-33"
            ;;
        windows)
            Start-Process -Wait -NoNewWindow -FilePath "sdkmanager" -ArgumentList "--licenses"
            Start-Process -Wait -NoNewWindow -FilePath "sdkmanager" -ArgumentList "platform-tools", "platforms;android-33"
            ;;
    esac

    # Prompt for Play Store image
    read -p "$(echo -e ${CYAN}Include Play Store image? (y/n): ${RESET})" INCLUDE_PLAY_STORE
    if [[ "$INCLUDE_PLAY_STORE" == "y" ]]; then
        SYSTEM_IMAGE=$PLAY_STORE_IMAGE
    fi

    case "$OS_TYPE" in
        linux|darwin)
            sdkmanager "$SYSTEM_IMAGE"
            ;;
        windows)
            Start-Process -Wait -NoNewWindow -FilePath "sdkmanager" -ArgumentList "$SYSTEM_IMAGE"
            ;;
    esac
}

# Create desktop shortcut
create_desktop_shortcut() {
    case "$OS_TYPE" in
        linux)
            DESKTOP_FILE="$HOME/Desktop/Samsung_S23.desktop"
            ICON_PATH="$(pwd)/icon.png"

            if [ ! -f "$ICON_PATH" ]; then
                ICON_PATH="/usr/share/icons/default.png"
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
            ;;
        darwin)
            # macOS shortcut creation using AppleScript
            osascript <<EOD
            tell application "Finder"
                make new alias file to file "/Applications/Android Studio.app/Contents/MacOS/emulator" at desktop
                set name of result to "Samsung_S23 Emulator"
            end tell
EOD
            ;;
        windows)
            powershell -Command "
            \$WScript = New-Object -ComObject WScript.Shell
            \$Shortcut = \$WScript.CreateShortcut('$USERPROFILE\\Desktop\\Samsung_S23.lnk')
            \$Shortcut.TargetPath = '${SCRIPT_DIR//\//\\}\\emulator.exe'
            \$Shortcut.Arguments = '-avd Samsung_S23'
            \$Shortcut.IconLocation = '${SCRIPT_DIR//\//\\}\\icon.png'
            \$Shortcut.Save()
            "
            ;;
    esac

    echo -e "${GREEN}Shortcut created on Desktop.${RESET}"
}

# Launch emulator
launch_emulator() {
    case "$OS_TYPE" in
        linux|darwin)
            emulator -avd "$AVD_NAME" &
            ;;
        windows)
            Start-Process -NoNewWindow -FilePath "emulator" -ArgumentList "-avd $AVD_NAME"
            ;;
    esac
}

# Main script execution
main() {
    # Clear screen (OS-independent method)
    printf "\033c"

    # Detect OS and set paths
    detect_os_and_set_paths

    # Banner
    echo -e "${CYAN}${BOLD}
    _    ___      __        ____             _     __
    | |  / (_)____/ /___  __/ __ \_________  (_)___/ /
    | | / / / ___/ __/ / / / / / ___/ __ \/ / __  / 
    | |/ / / /  / /_/ /_/ / /_/ / /  / /_/ / / /_/ /  
    |___/_/_/   \__/\__,_/_____/_/   \____/_/\__,_/   
                          
                          By Cody4code (@fekerineamar)
    ${RESET}"

    # Install dependencies
    install_dependencies

    # Setup Android SDK
    setup_android_sdk

    # Install Android components
    install_android_components

    # Create desktop shortcut
    create_desktop_shortcut

    # Launch emulator
    launch_emulator

    echo -e "${GREEN}Setup Complete! Emulator is running.${RESET}"
}

# Execute main function
main
