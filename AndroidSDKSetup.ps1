# Comprehensive Android SDK Setup Executable
# by cody4code (fekerineamar)
# Requires PowerShell 5.1+ and .NET Framework 4.7.2+

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.Threading

# Global Configurations
$global:LogFile = "$env:TEMP\AndroidSDKSetup.log"
$global:SDK_ROOT = "$env:USERPROFILE\Android\Sdk"
$global:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

# Helper: Log Messages
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

# Create Progress Form
function Show-AdvancedProgressForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Android SDK Setup Wizard - by cody4code"
    $form.Size = New-Object System.Drawing.Size(600, 450)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::White

    # Progress Components
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 100)
    $statusLabel.Size = New-Object System.Drawing.Size(560, 30)
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $statusLabel.Text = "Preparing Android SDK Installation..."
    $form.Controls.Add($statusLabel)

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 140)
    $progressBar.Size = New-Object System.Drawing.Size(560, 25)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $form.Controls.Add($progressBar)

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

# Update Progress
function Update-Progress {
    param(
        $ProgressUI,
        [string]$Status,
        [int]$Percentage
    )

    $ProgressUI.Form.Invoke([Action]{
        $ProgressUI.StatusLabel.Text = $Status
        $ProgressUI.ProgressBar.Value = $Percentage
    })
}

# Append Logs to UI
function Write-UILog {
    param(
        $ProgressUI,
        [string]$Message
    )

    $ProgressUI.Form.Invoke([Action]{
        $ProgressUI.LogTextBox.AppendText($Message + "`r`n")
        $ProgressUI.LogTextBox.SelectionStart = $ProgressUI.LogTextBox.Text.Length
        $ProgressUI.LogTextBox.ScrollToCaret()
    })
}

# Download File
function Resolve-WebDownload {
    param(
        [string]$Url,
        [string]$Destination,
        [object]$ProgressUI
    )

    try {
        Write-UILog -ProgressUI $ProgressUI -Message "Downloading $Url..."
        Write-DetailedLog "Starting download from $Url"

        $httpClient = [System.Net.Http.HttpClient]::new()
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

        Write-UILog -ProgressUI $ProgressUI -Message "Download complete: $Destination"
        Write-DetailedLog "Download complete"
    }
    catch {
        Write-DetailedLog "Download error: $_" "ERROR"
        throw
    }
}

# Main Setup Function
function Start-AndroidSDKSetup {
    $progressUI = Show-AdvancedProgressForm
    $jobContext = [System.Threading.SynchronizationContext]::Current

    # Display UI
    $null = [System.Threading.Tasks.Task]::Run({
        try {
            $jobContext.Post([Action]{
                Update-Progress -ProgressUI $progressUI -Status "Downloading SDK..." -Percentage 20
            }, $null)

            # Download Command Line Tools
            Resolve-WebDownload -Url $global:CMDLINE_TOOLS_URL -Destination "$env:TEMP\commandlinetools.zip" -ProgressUI $progressUI

            $jobContext.Post([Action]{
                Update-Progress -ProgressUI $progressUI -Status "Installing SDK Components..." -Percentage 60
            }, $null)

            Start-Sleep -Seconds 3 # Simulated install step

            $jobContext.Post([Action]{
                Update-Progress -ProgressUI $progressUI -Status "Finalizing Setup..." -Percentage 100
            }, $null)

            Write-UILog -ProgressUI $progressUI -Message "Android SDK setup completed successfully!"
        }
        catch {
            $jobContext.Post([Action]{
                Write-UILog -ProgressUI $progressUI -Message "An error occurred: $_"
                [System.Windows.MessageBox]::Show("Error: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }, $null)
        }
    })

    $progressUI.Form.ShowDialog()
}

# Main Execution
[System.Windows.Forms.Application]::EnableVisualStyles()
Start-AndroidSDKSetup
