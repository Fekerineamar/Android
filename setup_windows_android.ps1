# Clear the screen for a clean start
Clear-Host

# Colors for output
$Cyan = "`e[36m"
$Bold = "`e[1m"
$Reset = "`e[0m"

# Display banner
Write-Host "${Cyan}${Bold}
    _    ___      __        ____             _     __
    | |  / (_)____/ /___  __/ __ \_________  (_)___/ /
    | | / / / ___/ __/ / / / / / ___/ __ \/ / __  / 
    | |/ / / /  / /_/ /_/ / /_/ / /  / /_/ / / /_/ /  
    |___/_/_/   \__/\__,_/_____/_/   \____/_/\__,_/   
                          
                          By Cody4code (@fekerineamar)     
${Reset}"

# Variables
$SDK_ROOT = "$env:USERPROFILE\Android\Sdk"
$CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$TEMP_ZIP = "commandlinetools.zip"
$Dependencies = @("wget", "unzip", "curl")

# Function to check if a command exists
function Command-Exists {
    param([string]$Command)
    return (Get-Command $Command -ErrorAction SilentlyContinue) -ne $null
}

# Function to install Chocolatey if not present
function Install-Choco {
    if (-not (Command-Exists "choco")) {
        Write-Host "Chocolatey not found, installing..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is already installed." -ForegroundColor Green
    }
}

# Function to install required dependencies
function Install-Dependencies {
    Install-Choco
    foreach ($dep in $Dependencies) {
        if (-not (Command-Exists $dep)) {
            Write-Host "$dep not found, installing..." -ForegroundColor Yellow
            choco install $dep -y
        }
    }
}

# Function to set up the environment
function Setup-Environment {
    if (-not (Test-Path -Path $SDK_ROOT)) {
        New-Item -ItemType Directory -Path $SDK_ROOT
    }
}

# Function to download and set up Android SDK
function Setup-AndroidSDK {
    Invoke-WebRequest -Uri $CMDLINE_TOOLS_URL -OutFile $TEMP_ZIP
    Expand-Archive -Path $TEMP_ZIP -DestinationPath "$SDK_ROOT\cmdline-tools"
    Rename-Item "$SDK_ROOT\cmdline-tools\cmdline-tools" "latest"
    Remove-Item $TEMP_ZIP
}

# Function to install Android components
function Install-AndroidComponents {
    & "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
    & "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" "platform-tools" "platforms;android-33"
}

# Main function
function Main {
    Install-Dependencies         # Install dependencies
    Setup-Environment            # Set up environment
    Setup-AndroidSDK             # Download and set up Android SDK
    Install-AndroidComponents    # Install Android SDK components
    Write-Host "Android Emulator setup complete!" -ForegroundColor Green
}

# Run the main function
Main
