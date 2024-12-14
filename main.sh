#!/usr/bin/env bash

# Define colors for output
RESET='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'

# Detect and set OS-specific variables
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
        MINGW*|MSYS*|CYGWIN*)  
            OS_TYPE="windows"
            PACKAGE_MANAGERS=("choco")
            SDK_ROOT="$USERPROFILE\\Android\\Sdk"
            CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
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

# Install required dependencies
install_dependencies() {
    local deps=("wget" "unzip" "curl")
    
    for pm in "${PACKAGE_MANAGERS[@]}"; do
        if command -v "$pm" &> /dev/null; then
            case "$pm" in
                apt-get)
                    sudo apt-get update
                    sudo apt-get install -y "${deps[@]}"
                    ;;
                dnf|yum)
                    sudo "$pm" install -y "${deps[@]}"
                    ;;
                pacman)
                    sudo pacman -S --noconfirm "${deps[@]}"
                    ;;
                brew)
                    brew install "${deps[@]}"
                    ;;
                choco)
                    choco install "${deps[@]}" -y
                    ;;
            esac
            break
        else
            echo -e "${RED}Package manager $pm not found. Skipping...${RESET}"
        fi
    done
}

# Download and setup Android SDK
setup_android_sdk() {
    mkdir -p "$SDK_ROOT/cmdline-tools"
    
    case "$OS_TYPE" in
        linux|darwin)
            wget -q "$CMDLINE_TOOLS_URL" -O "$TEMP_ZIP" || { echo -e "${RED}Failed to download SDK tools.${RESET}"; exit 1; }
            unzip -q "$TEMP_ZIP" -d "$SDK_ROOT/cmdline-tools/" || { echo -e "${RED}Failed to unzip SDK tools.${RESET}"; exit 1; }
            mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
            rm "$TEMP_ZIP"
            ;;
        windows)
            powershell -Command "
            Invoke-WebRequest -Uri $CMDLINE_TOOLS_URL -OutFile $TEMP_ZIP
            Expand-Archive -Path $TEMP_ZIP -DestinationPath $SDK_ROOT\\cmdline-tools
            Rename-Item \"$SDK_ROOT\\cmdline-tools\\cmdline-tools\" \"latest\"
            Remove-Item $TEMP_ZIP
            "
            ;;
    esac

    export PATH="$SDK_ROOT/cmdline-tools/latest/bin:$PATH"
}

# Install Android components
install_android_components() {
    yes | sdkmanager --licenses
    sdkmanager "platform-tools" "platforms;android-33"

    read -p "Include Play Store image? (y/n): " INCLUDE_PLAY_STORE
    if [[ "$INCLUDE_PLAY_STORE" == "y" ]]; then
        sdkmanager "system-images;android-33;google_apis_playstore;x86_64"
    fi
}

# Create desktop shortcut
create_desktop_shortcut() {
    case "$OS_TYPE" in
        linux)
            cat > "$HOME/Desktop/Android_Emulator.desktop" << EOF
[Desktop Entry]
Name=Android Emulator
Exec=emulator -avd $AVD_NAME
Icon=android
Type=Application
Categories=Development;
EOF
            chmod +x "$HOME/Desktop/Android_Emulator.desktop"
            ;;
        darwin)
            osascript <<EOD
tell application "Finder"
    make new alias file to file "/Applications/Android Studio.app/Contents/MacOS/emulator" at desktop
    set name of result to "$AVD_NAME Emulator"
end tell
EOD
            ;;
        windows)
            powershell -Command "
            \$WScript = New-Object -ComObject WScript.Shell
            \$Shortcut = \$WScript.CreateShortcut('$USERPROFILE\\Desktop\\Android_Emulator.lnk')
            \$Shortcut.TargetPath = 'emulator'
            \$Shortcut.Arguments = '-avd $AVD_NAME'
            \$Shortcut.Save()
            "
            ;;
    esac
}

# Main script
main() {
    # Clear screen
    clear

    # Setup environment variables
    setup_environment

    # Install dependencies
    install_dependencies

    # Setup Android SDK
    setup_android_sdk

    # Install Android components
    install_android_components

    # Create desktop shortcut
    create_desktop_shortcut

    # Launch emulator
    emulator -avd "$AVD_NAME" &

    echo -e "${GREEN}Android Emulator setup complete!${RESET}"
}

# Execute main function
main
