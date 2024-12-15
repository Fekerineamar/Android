# Comprehensive Android SDK Setup Executable with Explicit Overload Handling
# by cody4code (fekerineamar)
# Requires PowerShell 5.1+ and .NET Framework 4.7.2+

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
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

function Update-Progress {
    param(
        $ProgressUI,
        [string]$Status,
        [int]$Percentage
    )
    if ($ProgressUI) {
        $ProgressUI.Form.Invoke([Action]{
            if ($Status) { $ProgressUI.StatusLabel.Text = $Status }
            if ($Percentage -ge 0) { $ProgressUI.ProgressBar.Value = [Math]::Min($Percentage, 100) }
        })
    }
}

# Explicit Overload Resolution Functions
function Resolve-WebDownload {
    param(
        [string]$Url,
        [string]$DestinationPath,
        $ProgressUI
    )

    try {
        # Create HttpClient with explicit configuration
        $handler = New-Object System.Net.Http.HttpClientHandler
        $handler.ServerCertificateCustomValidationCallback = [System.Func[System.Net.Http.HttpRequestMessage, System.Security.Cryptography.X509Certificates.X509Certificate2, System.Security.Cryptography.X509Certificates.X509Chain, System.Net.Security.SslPolicyErrors, bool]]{ return $true }
        
        $httpClient = New-Object System.Net.Http.HttpClient($handler)
        $httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShell SDK Installer")

        # Explicit async download
        $downloadTask = $httpClient.GetStreamAsync($Url)
        $downloadTask.Wait()
        
        $fileStream = [System.IO.File]::Create($DestinationPath)
        $downloadTask.Result.CopyTo($fileStream)
        $fileStream.Close()

        Write-UILog -ProgressUI $ProgressUI -Message "Download completed successfully."
    }
    catch {
        Write-UILog -ProgressUI $ProgressUI -Message "Download error: $_"
        throw
    }
    finally {
        if ($httpClient) { $httpClient.Dispose() }
    }
}

function Resolve-ProcessExecution {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        $ProgressUI
    )

    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $FilePath
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        
        foreach ($arg in $ArgumentList) {
            $processInfo.ArgumentList.Add($arg)
        }

        $process = [System.Diagnostics.Process]::Start($processInfo)
        $output = $process.StandardOutput.ReadToEnd()
        $error = $process.StandardError.ReadToEnd()
        
        $process.WaitForExit()

        if ($error) {
            Write-UILog -ProgressUI $ProgressUI -Message "Process Error: $error"
        }
        
        Write-UILog -ProgressUI $ProgressUI -Message "Process Output: $output"
    }
    catch {
        Write-UILog -ProgressUI $ProgressUI -Message "Execution error: $_"
        throw
    }
}

# SDK Download Function
function Download-AndroidSDK {
    param($ProgressUI)

    $downloadPath = "$env:TEMP\commandlinetools.zip"
    $extractPath = "$global:SDK_ROOT\cmdline-tools"

    Write-UILog -ProgressUI $ProgressUI -Message "Downloading Android SDK Command Line Tools..."
    
    try {
        # Explicit directory creation
        if (-not (Test-Path $global:SDK_ROOT)) {
            New-Item -ItemType Directory -Path $global:SDK_ROOT -Force | Out-Null
        }

        # Use explicit download method
        Resolve-WebDownload -Url $global:CMDLINE_TOOLS_URL -DestinationPath $downloadPath -ProgressUI $ProgressUI

        Write-UILog -ProgressUI $ProgressUI -Message "Extracting Android SDK..."
        
        # Explicit archive expansion
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force

        # Explicit folder renaming
        if (Test-Path "$extractPath\cmdline-tools") {
            Rename-Item -Path "$extractPath\cmdline-tools" -NewName "latest" -Force
        }

        # Clean up zip
        Remove-Item $downloadPath -Force
    }
    catch {
        Write-UILog -ProgressUI $ProgressUI -Message "SDK Download Error: $_"
        throw
    }
}

# Android Component Installation Function
function Install-AndroidComponents {
    param($ProgressUI)

    Write-UILog -ProgressUI $ProgressUI -Message "Installing Android SDK components..."
    
    $sdkManagerPath = "$global:SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat"
    
    try {
        # Explicit license acceptance
        Resolve-ProcessExecution -FilePath $sdkManagerPath -ArgumentList @("--licenses") -ProgressUI $ProgressUI

        # Install core components
        $components = @(
            "platform-tools", 
            "platforms;android-33", 
            "system-images;android-33;google_apis;x86_64"
        )

        foreach ($component in $components) {
            Write-UILog -ProgressUI $ProgressUI -Message "Installing $component..."
            Resolve-ProcessExecution -FilePath $sdkManagerPath -ArgumentList @($component) -ProgressUI $ProgressUI
        }
    }
    catch {
        Write-UILog -ProgressUI $ProgressUI -Message "Component Installation Error: $_"
        throw
    }
}

# Main Setup Function
function Start-AndroidSDKSetup {
    $progressUI = Show-AdvancedProgressForm
    $progressUI.Form.Show()

    try {
        # Download Command Line Tools
        Update-Progress -ProgressUI $progressUI -Status "Downloading SDK Tools..." -Percentage 20
        Download-AndroidSDK -ProgressUI $progressUI

        # Install SDK Components
        Update-Progress -ProgressUI $progressUI -Status "Installing SDK Components..." -Percentage 60
        Install-AndroidComponents -ProgressUI $progressUI

        # Finalize
        Update-Progress -ProgressUI $progressUI -Status "Finalizing Setup..." -Percentage 100
        Write-UILog -ProgressUI $progressUI -Message "Android SDK setup completed successfully!"
    }
    catch {
        Write-UILog -ProgressUI $progressUI -Message "Error: $_"
        [System.Windows.MessageBox]::Show("Error: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
    finally {
        $progressUI.Form.Close()
    }
}

# Main Execution
[System.Windows.Forms.Application]::EnableVisualStyles()
Start-AndroidSDKSetup
