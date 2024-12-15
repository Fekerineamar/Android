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

# Function to check if a command exists
function Command-Exists {
    param([string]$Command)
    return (Get-Command $Command -ErrorAction SilentlyContinue) -ne $null
}

# Function to set the execution policy if needed
function Set-ExecutionPolicyIfNeeded {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -ne 'RemoteSigned') {
        Write-Host "Current execution policy is '$currentPolicy'. Setting to 'RemoteSigned'."
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    } else {
        Write-Host "Execution policy is already set to 'RemoteSigned'."
    }
}

# Call the function to ensure execution policy is set
Set-ExecutionPolicyIfNeeded

# Variables
$SDK_ROOT = "$env:USERPROFILE\Android\Sdk"
$CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$TEMP_ZIP = "commandlinetools.zip"
$Dependencies = @("wget", "unzip", "curl")
$SYSTEM_IMAGE = "system-images;android-33;google_apis;x86_64"
$PLAYSTORE_IMAGE = "system-images;android-33;google_apis_playstore;x86_64"

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

# Function to download and set up Android SDK with a progress bar
function Setup-AndroidSDK {
    $filePath = "$TEMP_ZIP"
    $webClient = New-Object System.Net.WebClient

    # Subscribe to the DownloadProgressChanged event
    $webClient.DownloadProgressChanged += {
        param ($sender, $e)
        Write-Progress -Activity "Downloading Android SDK Command Line Tools" `
                       -Status "$($e.ProgressPercentage)% Complete" `
                       -PercentComplete $e.ProgressPercentage
    }

    # Subscribe to the DownloadFileCompleted event
    $webClient.DownloadFileCompleted += {
        param ($sender, $e)
        if ($e.Error) {
            Write-Host "Error downloading file: $($e.Error.Message)" -ForegroundColor Red
        } else {
            Write-Host "Download completed!" -ForegroundColor Green
        }
    }

    # Start the download
    Write-Host "Starting download..." -ForegroundColor Yellow
    $webClient.DownloadFileAsync($CMDLINE_TOOLS_URL, $filePath)

    # Wait for the download to complete
    while ($webClient.IsBusy) {
        Start-Sleep -Seconds 1
    }

    # Cleanup and extract the downloaded file
    Expand-Archive -Path $filePath -DestinationPath "$SDK_ROOT\cmdline-tools"
    Rename-Item "$SDK_ROOT\cmdline-tools\cmdline-tools" "latest"
    Remove-Item $filePath
}

# Function to install Android components
function Install-AndroidComponents {
    & "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
    & "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" "platform-tools" "platforms;android-33"

    # Ask user if they want the Play Store image
    $IncludePlayStore = Read-Host "Include Play Store system image? (y/n)"
    if ($IncludePlayStore -eq "y") {
        & "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" $PLAYSTORE_IMAGE
    } else {
        & "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" $SYSTEM_IMAGE
    }
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
