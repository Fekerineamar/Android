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
  # Check the OS and clear the terminal
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    clear  # For Linux (Bash)
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
    cls  # For Windows (PowerShell or Git Bash)
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
                          
                          By Cody4code (@fekerineamar) 
    ${RESET}"
    
    if ! command -v wget &> /dev/null; then
        echo -e "${YELLOW}wget is not installed. Installing wget...${RESET}"
        sudo apt-get update && sudo apt-get install -y wget
    fi

    # Check if unzip is installed
    if ! command -v unzip &> /dev/null; then
        echo -e "${YELLOW}unzip is not installed. Installing unzip...${RESET}"
        sudo apt-get install -y unzip
    fi

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}curl is not installed. Installing curl...${RESET}"
        sudo apt-get install -y curl
    fi

    # Variables
    CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    SDK_ROOT="$HOME/Android/Sdk"
    CMDLINE_TOOLS_DIR="$SDK_ROOT/cmdline-tools"
    TEMP_ZIP="commandlinetools.zip"
    AVD_NAME="Samsung_S23"
    SYSTEM_IMAGE="system-images;android-33;google_apis;x86_64"
    PLAY_STORE_IMAGE="system-images;android-33;google_apis_playstore;x86_64"

    # Step 1: Check if Android SDK already exists
    if [ -d "$CMDLINE_TOOLS_DIR/latest" ]; then
      echo -e "${GREEN}Android SDK Command Line Tools already installed.${RESET}"
    else
      # Download and Extract the tools
      echo -e "${YELLOW}Downloading Command Line Tools...${RESET}"
      wget -q "$CMDLINE_TOOLS_URL" -O "$TEMP_ZIP"
      echo -e "${YELLOW}Extracting Command Line Tools...${RESET}"
      mkdir -p "$CMDLINE_TOOLS_DIR"
      unzip -q "$TEMP_ZIP" -d "$CMDLINE_TOOLS_DIR/"
      mv "$CMDLINE_TOOLS_DIR/cmdline-tools" "$CMDLINE_TOOLS_DIR/latest"
      rm "$TEMP_ZIP"
    fi

    # Step 2: Update PATH
    export PATH="$CMDLINE_TOOLS_DIR/latest/bin:$PATH"

    # Step 3: Install SDK Components
    echo -e "${MAGENTA}Installing required SDK components...${RESET}"
    yes | sdkmanager --licenses
    sdkmanager "platform-tools" "platforms;android-33"

    # Step 4: Ask User if Play Store Image is Needed
    read -p "$(echo -e ${CYAN}Do you want to include a Play Store image? (y/n): ${RESET})" INCLUDE_PLAY_STORE
    if [[ "$INCLUDE_PLAY_STORE" == "y" ]]; then
      SYSTEM_IMAGE=$PLAY_STORE_IMAGE
    fi

    # Install the selected system image
    sdkmanager "$SYSTEM_IMAGE"

    # Step 5: Check if AVD already exists
    if avdmanager list avd | grep -q "$AVD_NAME"; then
      echo -e "${GREEN}AVD '$AVD_NAME' already exists.${RESET}"
    else
      # Create AVD
      echo -e "${YELLOW}Creating AVD...${RESET}"
      echo "no" | avdmanager create avd -n "$AVD_NAME" -k "$SYSTEM_IMAGE" --device "pixel_3"
    fi

    # Step 6: Launch the Emulator
    echo -e "${CYAN}Launching Emulator...${RESET}"
    emulator -avd "$AVD_NAME" &

    echo -e "${GREEN}Setup Complete! Emulator is running.${RESET}"

  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
    # Windows-specific commands
    Write-Host "$CYAN$BOLD
    _    ___      __        ____             _     __
    | |  / (_)____/ /___  __/ __ \_________  (_)___/ /
    | | / / / ___/ __/ / / / / / ___/ __ \/ / __  / 
    | |/ / / /  / /_/ /_/ / /_/ / /  / /_/ / / /_/ /  
    |___/_/_/   \__/\__,_/_____/_/   \____/_/\__,_/   

                          By Cody4code (@fekerineamar) 
    $RESET"
 

    # Check if wget is installed
    if (-not (Get-Command wget -ErrorAction SilentlyContinue)) {
        Write-Host "$YELLOW wget is not installed. Installing wget...$RESET"
        choco install wget -y
    }

    # Check if unzip is installed
    if (-not (Get-Command unzip -ErrorAction SilentlyContinue)) {
        Write-Host "$YELLOW unzip is not installed. Installing unzip...$RESET"
        choco install unzip -y
    }

    # Check if curl is installed
    if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
        Write-Host "$YELLOW curl is not installed. Installing curl...$RESET"
        choco install curl -y
    }

    # Variables
    $CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    $SDK_ROOT = [System.Environment]::GetFolderPath('MyDocuments') + "\Android\Sdk"
    $CMDLINE_TOOLS_DIR = "$SDK_ROOT\cmdline-tools"
    $TEMP_ZIP = "commandlinetools.zip"
    $AVD_NAME = "Samsung_S23"
    $SYSTEM_IMAGE = "system-images;android-33;google_apis;x86_64"
    $PLAY_STORE_IMAGE = "system-images;android-33;google_apis_playstore;x86_64"

    # Step 1: Check if Android SDK already exists
    if (Test-Path "$CMDLINE_TOOLS_DIR\latest") {
        Write-Host "$GREEN Android SDK Command Line Tools already installed.$RESET"
    } else {
        # Download and Extract the tools
        Write-Host "$YELLOW Downloading Command Line Tools...$RESET"
        Invoke-WebRequest -Uri $CMDLINE_TOOLS_URL -OutFile $TEMP_ZIP
        Write-Host "$YELLOW Extracting Command Line Tools...$RESET"
        New-Item -ItemType Directory -Force -Path $CMDLINE_TOOLS_DIR
        Expand-Archive -Path $TEMP_ZIP -DestinationPath $CMDLINE_TOOLS_DIR
        Rename-Item "$CMDLINE_TOOLS_DIR\cmdline-tools" "$CMDLINE_TOOLS_DIR\latest"
        Remove-Item $TEMP_ZIP
    }

    # Step 2: Update PATH
    $env:Path += ";$CMDLINE_TOOLS_DIR\latest\bin"

    # Step 3: Install SDK Components
    Write-Host "$MAGENTA Installing required SDK components...$RESET"
    Start-Process -NoNewWindow -Wait -FilePath "sdkmanager" -ArgumentList "--licenses"
    Start-Process -NoNewWindow -Wait -FilePath "sdkmanager" -ArgumentList "platform-tools", "platforms;android-33"

    # Step 4: Ask User if Play Store Image is Needed
    $INCLUDE_PLAY_STORE = Read-Host "$CYAN Do you want to include a Play Store image? (y/n): $RESET"
    if ($INCLUDE_PLAY_STORE -eq "y") {
        $SYSTEM_IMAGE = $PLAY_STORE_IMAGE
    }

    # Install the selected system image
    Write-Host "$BLUE Installing selected system image: $SYSTEM_IMAGE...$RESET"
    Start-Process -NoNewWindow -Wait -FilePath "sdkmanager" -ArgumentList $SYSTEM_IMAGE

    # Step 5: Check if AVD already exists
    $AVD_EXISTS = & "avdmanager" list avd | Select-String -Pattern $AVD_NAME
    if ($AVD_EXISTS) {
        Write-Host "$GREEN AVD '$AVD_NAME' already exists.$RESET"
    } else {
        # Create AVD
        Write-Host "$YELLOW Creating AVD...$RESET"
        echo "no" | & "avdmanager" create avd -n $AVD_NAME -k $SYSTEM_IMAGE --device "pixel_3"
    }

    # Step 6: Launch the Emulator
    Write-Host "$CYAN Launching Emulator...$RESET"
    Start-Process -NoNewWindow -Wait -FilePath "emulator" -ArgumentList "-avd $AVD_NAME"

    Write-Host "$GREEN Setup Complete! Emulator is running.$RESET"


  else
    echo "Unsupported OS type: $OSTYPE"
  fi
}

# Clear the screen before starting the setup
clear_screen

# Detect OS and run corresponding code
detect_os_and_run
