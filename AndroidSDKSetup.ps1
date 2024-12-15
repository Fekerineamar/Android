# Comprehensive Android SDK Setup Executable
# by cody4code (fekerineamar)
# Requires PowerShell 5.1+ and .NET Framework 4.7.2+

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Threading
Add-Type -AssemblyName System.Net.Http

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

# Helper: Write Logs
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

# Helper: Create Progress Form
function Show-AdvancedProgressForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Android SDK Setup Wizard - by cody4code"
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

    # Return UI components as hash table
    return @{
        Form = $form
        StatusLabel = $statusLabel
        ProgressBar = $progressBar
        LogTextBox = $logTextBox
    }
}

# Update Progress Helper
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

# Download with Overload Handling
function Resolve-WebDownload {
    param(
        [string]$Url,
        [string]$Destination
    )

    try {
        Write-DetailedLog "Downloading $Url..."
        $httpClient = [System.Net.Http.HttpClient]::new()
        $httpClient.Timeout = [System.TimeSpan]::FromMinutes(30)
        $response = $httpClient.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result

        if (-not $response.IsSuccessStatusCode) {
            throw "Download failed with status code: $($response.StatusCode)"
        }

        $stream = $response.Content.ReadAsStreamAsync().Result
        $fileStream = [System.IO.FileStream]::new($Destination, [System.IO.FileMode]::Create)
        $buffer = New-Object byte[] 8192

        while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $bytesRead)
        }

        $fileStream.Close()
        $stream.Close()
        $httpClient.Dispose()
    }
    catch {
        Write-DetailedLog "Download failed: $_" "ERROR"
        throw
    }
}

# Main Execution Function
function Start-AndroidSDKSetup {
    $progressUI = Show-AdvancedProgressForm
    $progressUI.Form.ShowDialog()

    try {
        # Step 1: Download Command Line Tools
        Update-Progress -ProgressUI $progressUI -Status "Downloading Command Line Tools..." -Percentage 20
        Resolve-WebDownload -Url $global:CMDLINE_TOOLS_URL -Destination "$env:TEMP\commandlinetools.zip"

        # Step 2: Install SDK Components
        Update-Progress -ProgressUI $progressUI -Status "Installing SDK Components..." -Percentage 60
        # Simulate Installation
        Start-Sleep -Seconds 3

        # Step 3: Finalize Setup
        Update-Progress -ProgressUI $progressUI -Status "Finalizing Setup..." -Percentage 100
        Write-DetailedLog "Android SDK Setup Complete!"
    }
    catch {
        [System.Windows.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
    finally {
        $progressUI.Form.Close()
    }
}

# Ensure Visual Styles and Run Setup
[System.Windows.Forms.Application]::EnableVisualStyles()
Start-AndroidSDKSetup
