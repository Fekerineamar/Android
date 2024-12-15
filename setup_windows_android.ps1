# Comprehensive Android SDK Setup Executable
# by cody4code (fekerineamar)
# Requires PowerShell 5.1+ and .NET Framework 4.7.2+

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# Logging and Configuration
$global:LogFile = "$env:TEMP\AndroidSDKSetup.log"
$global:SDK_ROOT = "$env:USERPROFILE\Android\Sdk"
$global:CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

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

# Function to display the progress form
function Show-AdvancedProgressForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Android SDK Setup Wizard - by cody4code (fekerineamar)"
    $form.Size = New-Object System.Drawing.Size(500, 400)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::White

    # Branding Panel
    $brandingPanel = New-Object System.Windows.Forms.Panel
    $brandingPanel.Location = New-Object System.Drawing.Point(0, 0)
    $brandingPanel.Size = New-Object System.Drawing.Size(500, 60)
    $brandingPanel.BackColor = [System.Drawing.Color]::FromArgb(36, 41, 46)
    $form.Controls.Add($brandingPanel)

    # Branding Text
    $brandingLabel = New-Object System.Windows.Forms.Label
    $brandingLabel.Text = "Android SDK - By cody4code (fekerineamar)"
    $brandingLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $brandingLabel.ForeColor = [System.Drawing.Color]::White
    $brandingLabel.Location = New-Object System.Drawing.Point(10, 15)
    $brandingLabel.Size = New-Object System.Drawing.Size(480, 30)
    $brandingPanel.Controls.Add($brandingLabel)

    # Status Label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 80)
    $statusLabel.Size = New-Object System.Drawing.Size(460, 30)
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $statusLabel.Text = "Preparing Android SDK Installation..."
    $form.Controls.Add($statusLabel)

    # Progress Bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 120)
    $progressBar.Size = New-Object System.Drawing.Size(460, 25)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $form.Controls.Add($progressBar)

    # Detailed Log TextBox
    $logTextBox = New-Object System.Windows.Forms.TextBox
    $logTextBox.Location = New-Object System.Drawing.Point(20, 160)
    $logTextBox.Size = New-Object System.Drawing.Size(460, 150)
    $logTextBox.Multiline = $true
    $logTextBox.ScrollBars = "Vertical"
    $logTextBox.ReadOnly = $true
    $form.Controls.Add($logTextBox)

    # Credits Label
    $creditsLabel = New-Object System.Windows.Forms.Label
    $creditsLabel.Text = "Powered by cody4code (fekerineamar)"
    $creditsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $creditsLabel.ForeColor = [System.Drawing.Color]::Gray
    $creditsLabel.Location = New-Object System.Drawing.Point(20, 330)
    $creditsLabel.Size = New-Object System.Drawing.Size(460, 20)
    $form.Controls.Add($creditsLabel)

    return @{
        Form = $form
        StatusLabel = $statusLabel
        ProgressBar = $progressBar
        LogTextBox = $logTextBox
    }
}

# Function to update progress UI
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

# Function to write logs to UI
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

# Run tasks on a separate thread to keep UI responsive
function Run-InBackground {
    param(
        [scriptblock]$Task,
        $ProgressUI
    )
    Start-Job -ScriptBlock {
        Param ($Task, $ProgressUI)
        try {
            &$Task
        }
        catch {
            Write-UILog -ProgressUI $ProgressUI -Message "Error: $_"
        }
    } -ArgumentList $Task, $ProgressUI
}

# Main Execution
function Start-AndroidSDKSetup {
    $progressUI = Show-AdvancedProgressForm
    $progressUI.Form.Show()

    $task = {
        Install-Prerequisites -ProgressUI $ProgressUI
        Download-AndroidSDK -ProgressUI $ProgressUI
        Install-AndroidComponents -ProgressUI $ProgressUI
        Set-AndroidEnvironment -ProgressUI $ProgressUI
        Update-Progress -ProgressUI $ProgressUI -Status "Setup Complete!" -Percentage 100
    }

    Run-InBackground -Task $task -ProgressUI $progressUI
}

[System.Windows.Forms.Application]::EnableVisualStyles()
Start-AndroidSDKSetup
