# Clear the screen for a clean start
Clear-Host

# Colors for output
$Cyan = "`e[36m"
$Bold = "`e[1m"
$Reset = "`e[0m"

# Function to check if running as administrator
function Test-Admin {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Enhanced Execution Policy Handler with Elevation
function Set-ExecutionPolicyWithElevation {
    try {
        # Check current execution policy
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser

        # If policy is not RemoteSigned, attempt to change it
        if ($currentPolicy -ne 'RemoteSigned') {
            # Create a temporary script to change execution policy
            $tempScript = "$env:TEMP\set_execution_policy.ps1"
            
            @"
# Script to set execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
"@ | Out-File $tempScript -Encoding UTF8

            # Relaunch with elevated privileges to change execution policy
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "powershell.exe"
            $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
            $psi.Verb = "runas"
            $psi.WorkingDirectory = $env:TEMP

            $process = [System.Diagnostics.Process]::Start($psi)
            $process.WaitForExit()

            # Verify the change
            $newPolicy = Get-ExecutionPolicy -Scope CurrentUser
            if ($newPolicy -eq 'RemoteSigned') {
                Write-Host "Execution policy successfully set to RemoteSigned." -ForegroundColor Green
                return $true
            } else {
                Write-Host "Failed to set execution policy." -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-Host "Execution policy is already set to RemoteSigned." -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Error setting execution policy: $_" -ForegroundColor Red
        return $false
    }
    finally {
        # Clean up temporary script if it exists
        $tempScript = "$env:TEMP\set_execution_policy.ps1"
        if (Test-Path $tempScript) {
            Remove-Item $tempScript -Force
        }
    }
}

# Function to relaunch script as administrator if not already running as admin
function Relaunch-As-Admin {
    if (-not (Test-Admin)) {
        # Relaunch the script with elevated privileges
        Write-Host "This script requires administrator privileges. Relaunching as administrator..." -ForegroundColor Red
        
        # Create a temporary script to run the main script
        $tempScript = "$env:TEMP\android_sdk_setup.ps1"
        $currentScript = $PSCommandPath
        
        @"
# Temporary script to run Android SDK setup
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$currentScript`"" -Verb RunAs
"@ | Out-File $tempScript -Encoding UTF8

        # Start the temporary script with elevation
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs
        exit
    }
}

# Display banner
function Show-Banner {
    Write-Host "${Cyan}${Bold}
    _    ___      __        ____             _     __
    | |  / (_)____/ /___  __/ __ \_________  (_)___/ /
    | | / / / ___/ __/ / / / / / ___/ __ \/ / __  / 
    | |/ / / /  / /_/ /_/ / /_/ / /  / /_/ / / /_/ /  
    |___/_/_/   \__/\__,_/_____/_/   \____/_/\__,_/   
                          
                          By Cody4code (@fekerineamar)     
${Reset}"
}

# Function to check if a command exists
function Command-Exists {
    param([string]$Command)
    return (Get-Command $Command -ErrorAction SilentlyContinue) -ne $null
}

# Variables
$SDK_ROOT = "$env:USERPROFILE\Android\Sdk"
$CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$TEMP_ZIP = "$env:TEMP\commandlinetools.zip"
$Dependencies = @("wget", "unzip", "curl")
$SYSTEM_IMAGE = "system-images;android-33;google_apis;x86_64"
$PLAYSTORE_IMAGE = "system-images;android-33;google_apis_playstore;x86_64"

# Function to install Chocolatey if not present
function Install-Choco {
    if (-not (Command-Exists "choco")) {
        Write-Host "Chocolatey not found, installing..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
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
        New-Item -ItemType Directory -Path $SDK_ROOT | Out-Null
        Write-Host "Created Android SDK directory: $SDK_ROOT" -ForegroundColor Green
    }
}

# Function to download and set up Android SDK with a progress bar
function Setup-AndroidSDK {
    try {
        # Create WebClient for download
        $webClient = New-Object System.Net.WebClient

        # Download with progress
        Write-Host "Downloading Android SDK Command Line Tools..." -ForegroundColor Yellow
        $webClient.DownloadFile($CMDLINE_TOOLS_URL, $TEMP_ZIP)
        
        # Verify download
        if (-not (Test-Path $TEMP_ZIP)) {
            throw "Download failed. Unable to find downloaded file."
        }

        # Extract with progress
        Write-Host "Extracting Android SDK..." -ForegroundColor Yellow
        Expand-Archive -Path $TEMP_ZIP -DestinationPath "$SDK_ROOT\cmdline-tools" -Force
        
        # Rename extracted folder
        Rename-Item "$SDK_ROOT\cmdline-tools\cmdline-tools" "latest" -Force
        
        # Clean up temporary zip
        Remove-Item $TEMP_ZIP -Force

        Write-Host "Android SDK Command Line Tools installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error during Android SDK setup: $_" -ForegroundColor Red
        throw
    }
}

# Function to install Android components
function Install-AndroidComponents {
    # Accept licenses
    Write-Host "Accepting Android SDK licenses..." -ForegroundColor Yellow
    & "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" --licenses | Out-Null

    # Install platform tools and platform
    $componentsToInstall = @("platform-tools", "platforms;android-33")

    # Ask about Play Store image
    $IncludePlayStore = Read-Host "Include Play Store system image? (y/n)"
    if ($IncludePlayStore -eq "y") {
        $componentsToInstall += $PLAYSTORE_IMAGE
    } else {
        $componentsToInstall += $SYSTEM_IMAGE
    }

    # Install components
    foreach ($component in $componentsToInstall) {
        Write-Host "Installing $component..." -ForegroundColor Yellow
        & "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" "$component"
    }
}

# Add environment variables
function Set-AndroidEnvironmentVariables {
    # Set ANDROID_HOME
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $SDK_ROOT, "Machine")
    
    # Add platform-tools to PATH
    $platformToolsPath = "$SDK_ROOT\platform-tools"
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*$platformToolsPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$platformToolsPath", "Machine")
    }

    Write-Host "Android environment variables set successfully!" -ForegroundColor Green
}

# Main function to orchestrate the entire setup
function Main {
    # Show welcome banner
    Show-Banner

    # Attempt to set execution policy
    $policySet = Set-ExecutionPolicyWithElevation
    if (-not $policySet) {
        Write-Host "Cannot proceed: Failed to set execution policy." -ForegroundColor Red
        exit
    }

    # Ensure admin privileges
    Relaunch-As-Admin

    # Perform setup steps
    try {
        Install-Dependencies         # Install necessary dependencies
        Setup-Environment            # Prepare SDK directory
        Setup-AndroidSDK             # Download Android SDK tools
        Install-AndroidComponents    # Install Android components
        Set-AndroidEnvironmentVariables  # Set up environment variables

        Write-Host "`n`n🎉 Android Emulator Setup Complete! 🎉" -ForegroundColor Green
        Write-Host "Android SDK installed in: $SDK_ROOT" -ForegroundColor Cyan
        
        # Prompt to refresh environment
        Write-Host "`nPlease restart your PowerShell or command prompt to apply environment changes." -ForegroundColor Yellow
    }
    catch {
        Write-Host "An error occurred during setup: $_" -ForegroundColor Red
    }
}

# Run the main function
Main
