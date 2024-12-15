# Comprehensive Android SDK Setup Executable with Threading
# Requires PowerShell 5.1+ and .NET Framework 4.7.2+

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Threading

# Logging and Configuration
$global:LogFile = "$env:TEMP\AndroidSDKSetup.log"
$global:SDK_ROOT = "$env:USERPROFILE\Android\Sdk"
$global:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

# ASCII Art Logo
$global:AndroidAsciiLogo = @"
    /\__/\   Android SDK
   /`    '\  Setup Wizard
  === 0  0 ===
  \  --   --  /
  /        \ 
 /          \
|            |
 \  ||  ||  /
  \_oo__oo_/#
"@

# Helper Functions
function Write-DetailedLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$Level] $timestamp - $Message"
    Add-Content -Path $global:LogFile -Value $logEntry
    Write-Host $logEntry
}

function Show-AdvancedProgressForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Android SDK Setup Wizard"
    $form.Size = New-Object System.Drawing.Size(600, 450)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::White

    # Logo Panel
    $logoPanel = New-Object System.Windows.Forms.Panel
    $logoPanel.Location = New-Object System.Drawing.Point(0, 0)
    $logoPanel.Size = New-Object System.Drawing.Size(600, 80)
    $logoPanel.BackColor = [System.Drawing.Color]::FromArgb(36, 41, 46)
    $form.Controls.Add($logoPanel)

    # ASCII Logo Label
    $asciiLogoLabel = New-Object System.Windows.Forms.Label
    $asciiLogoLabel.Text = $global:AndroidAsciiLogo
    $asciiLogoLabel.Font = New-Object System.Drawing.Font("Consolas", 10)
    $asciiLogoLabel.ForeColor = [System.Drawing.Color]::White
    $asciiLogoLabel.Location = New-Object System.Drawing.Point(20, 10)
    $asciiLogoLabel.Size = New-Object System.Drawing.Size(300, 150)
    $logoPanel.Controls.Add($asciiLogoLabel)

    # Title Label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Android SDK Setup"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.Location = New-Object System.Drawing.Point(330, 25)
    $titleLabel.Size = New-Object System.Drawing.Size(250, 40)
    $logoPanel.Controls.Add($titleLabel)

    # Status Label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 100)
    $statusLabel.Size = New-Object System.Drawing.Size(560, 30)
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $statusLabel.Text = "Preparing Android SDK Installation..."
    $form.Controls.Add($statusLabel)

    # Progress Bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 140)
    $progressBar.Size = New-Object System.Drawing.Size(560, 25)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $form.Controls.Add($progressBar)

    # Detailed Log TextBox
    $logTextBox = New-Object System.Windows.Forms.TextBox
    $logTextBox.Location = New-Object System.Drawing.Point(20, 180)
    $logTextBox.Size = New-Object System.Drawing.Size(560, 200)
    $logTextBox.Multiline = $true
    $logTextBox.ScrollBars = "Vertical"
    $logTextBox.ReadOnly = $true
    $form.Controls.Add($logTextBox)

    return @{
        Form = $form
        StatusLabel = $statusLabel
        ProgressBar = $progressBar
        LogTextBox = $logTextBox
    }
}

function Update-Progress {
    param(
        $ProgressUI,
        [string]$Status,
        [int]$Percentage = -1
    )

    if ($ProgressUI) {
        $ProgressUI.Form.Invoke([Action]{
            if ($Status) {
                $ProgressUI.StatusLabel.Text = $Status
            }
            
            if ($Percentage -ge 0) {
                $ProgressUI.ProgressBar.Value = [Math]::Min($Percentage, 100)
            }
        })
    }
}

function Write-UILog {
    param(
        $ProgressUI,
        [string]$Message
    )

    if ($ProgressUI) {
        $ProgressUI.Form.Invoke([Action]{
            $ProgressUI.LogTextBox.AppendText($Message + "`r`n")
            $ProgressUI.LogTextBox.SelectionStart = $ProgressUI.LogTextBox.TextLength
            $ProgressUI.LogTextBox.ScrollToCaret()
        })
    }
}

function Install-Prerequisites {
    param($ProgressUI)

    Write-UILog -ProgressUI $ProgressUI -Message "Checking and installing prerequisites..."
    
    # Install Chocolatey if not exists
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-UILog -ProgressUI $ProgressUI -Message "Installing Chocolatey package manager..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    # Install required tools
    $tools = @("wget", "unzip", "curl")
    foreach ($tool in $tools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-UILog -ProgressUI $ProgressUI -Message "Installing $tool..."
            choco install $tool -y | Out-Null
        }
    }
}

function Download-AndroidSDK {
    param($ProgressUI)

    $downloadPath = "$env:TEMP\commandlinetools.zip"
    $extractPath = "$global:SDK_ROOT\cmdline-tools"

    Write-UILog -ProgressUI $ProgressUI -Message "Downloading Android SDK Command Line Tools..."
    
    try {
        # Create SDK directory if not exists
        if (-not (Test-Path $global:SDK_ROOT)) {
            New-Item -ItemType Directory -Path $global:SDK_ROOT | Out-Null
        }

        # Download SDK with progress tracking
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadProgressChanged += {
            param($sender, $e)
            Update-Progress -ProgressUI $ProgressUI -Percentage $e.ProgressPercentage
        }
        $webClient.DownloadFileAsync($global:CMDLINE_TOOLS_URL, $downloadPath)

        # Wait for download to complete
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 100
        }

        Write-UILog -ProgressUI $ProgressUI -Message "Extracting Android SDK..."
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force

        # Rename extracted folder
        Rename-Item "$extractPath\cmdline-tools" "latest" -Force

        # Clean up zip
        Remove-Item $downloadPath -Force
    }
    catch {
        Write-UILog -ProgressUI $ProgressUI -Message "Error downloading SDK: $_"
        throw
    }
}

function Install-AndroidComponents {
    param($ProgressUI)

    Write-UILog -ProgressUI $ProgressUI -Message "Installing Android SDK components..."
    
    # Accept licenses
    Start-Process "$global:SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" --licenses -Wait

    # Install core components
    $components = @(
        "platform-tools", 
        "platforms;android-33", 
        "system-images;android-33;google_apis;x86_64"
    )

    foreach ($component in $components) {
        Write-UILog -ProgressUI $ProgressUI -Message "Installing $component..."
        Start-Process "$global:SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" $component -Wait
    }
}

function Set-AndroidEnvironment {
    param($ProgressUI)

    Write-UILog -ProgressUI $ProgressUI -Message "Configuring Android environment variables..."
    
    # Set ANDROID_HOME
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $global:SDK_ROOT, "Machine")
    
    # Add platform-tools to PATH
    $platformToolsPath = "$global:SDK_ROOT\platform-tools"
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*$platformToolsPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$platformToolsPath", "Machine")
    }
}

function Start-AndroidSDKSetup {
    $progressUI = $null
    try {
        # Initialize Progress UI
        $progressUI = Show-AdvancedProgressForm
        $progressUI.Form.Show()

        # Create a synchronized thread-safe job
        $jobContext = [System.Threading.SynchronizationContext]::Current
        $job = [System.Threading.Tasks.Task]::Run({
            try {
                # Installation Stages with Threading and Progress Updates
                $jobContext.Post([Action]{
                    Update-Progress -ProgressUI $progressUI -Status "Installing Prerequisites..." -Percentage 10
                }, $null)
                Install-Prerequisites -ProgressUI $progressUI

                $jobContext.Post([Action]{
                    Update-Progress -ProgressUI $progressUI -Status "Downloading Android SDK..." -Percentage 40
                }, $null)
                Download-AndroidSDK -ProgressUI $progressUI

                $jobContext.Post([Action]{
                    Update-Progress -ProgressUI $progressUI -Status "Installing Android Components..." -Percentage 70
                }, $null)
                Install-AndroidComponents -ProgressUI $progressUI

                $jobContext.Post([Action]{
                    Update-Progress -ProgressUI $progressUI -Status "Configuring Environment..." -Percentage 90
                }, $null)
                Set-AndroidEnvironment -ProgressUI $progressUI

                # Completion
                $jobContext.Post([Action]{
                    Update-Progress -ProgressUI $progressUI -Status "Android SDK Installation Complete!" -Percentage 100
                    [System.Windows.MessageBox]::Show("Android SDK has been successfully installed!", "Installation Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                }, $null)
            }
            catch {
                $jobContext.Post([Action]{
                    [System.Windows.MessageBox]::Show("Installation failed: $_", "Installation Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }, $null)
            }
        })
    }
    catch {
        [System.Windows.MessageBox]::Show("Installation failed: $_", "Installation Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}

# Main Execution
[System.Windows.Forms.Application]::EnableVisualStyles()
Start-AndroidSDKSetup
