# Complete Android SDK Setup Executable
# by cody4code (fekerineamar) - Revised and Enhanced (Final)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Net.Http

# --- Configuration and Constants ---
$LogFile = "$env:TEMP\AndroidSDKSetup.log"
$SDK_ROOT = "$env:USERPROFILE\Android\Sdk"
$CMDLINE_TOOLS_URL = "https://dl.google.com/android/repository/commandlinetools-win-$(Get-Architecture)_latest.zip"
$Components = @(
    "platform-tools",
    "platforms;android-34",
    "build-tools;34.0.0",
    "system-images;android-34;google_apis;x86_64"
)

# --- ASCII Art Logo (Optional) ---
$AndroidAsciiLogo = @"
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

# --- Helper Functions ---
function Write-DetailedLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$Level] $timestamp - $Message"
    Add-Content -Path $LogFile -Value $logEntry
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

# --- Networking and File Operations ---
function Resolve-WebDownload {
    param(
        [string]$Url,
        [string]$DestinationPath,
        $ProgressUI
    )
    $httpClient = $null
    try {
        $handler = New-Object System.Net.Http.HttpClientHandler
        $handler.ServerCertificateCustomValidationCallback = [System.Func[System.Net.Http.HttpRequestMessage, System.Security.Cryptography.X509Certificates.X509Certificate2, System.Security.Cryptography.X509Certificates.X509Chain, System.Net.Security.SslPolicyErrors, bool]]{ return $true }
        
        $httpClient = New-Object System.Net.Http.HttpClient($handler)
        $httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("PowerShell SDK Installer")


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

# --- Process Execution ---
function Resolve-ProcessExecution {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        $ProgressUI
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.ArgumentList.AddRange($ArgumentList)

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null

    $outputBuffer = New-Object System.Text.StringBuilder
    $errorBuffer = New-Object System.Text.StringBuilder
    $outputReader = [System.IO.StreamReader]$process.StandardOutput
    $errorReader = [System.IO.StreamReader]$process.StandardError

     while (-not $process.HasExited) {
        $outputBuffer.Append($outputReader.ReadToEnd())
        $errorBuffer.Append($errorReader.ReadToEnd())
        Start-Sleep -Milliseconds 100
    }
     # Read remaining output after the process exits
    $outputBuffer.Append($outputReader.ReadToEnd())
    $errorBuffer.Append($errorReader.ReadToEnd())


    if ($errorBuffer.Length -gt 0) {
        throw "Process Error: $($errorBuffer.ToString())"
    }
    Write-UILog -ProgressUI $ProgressUI -Message $outputBuffer.ToString()
}


# --- SDK Installation Functions ---
function Download-AndroidSDK {
    param($ProgressUI)
    $downloadPath = "$env:TEMP\commandlinetools.zip"
    $extractPath = "$SDK_ROOT\cmdline-tools"
    Write-UILog -ProgressUI $ProgressUI -Message "Downloading Android SDK Command Line Tools..."
    try {
        if (-not (Test-Path $SDK_ROOT)) {
            New-Item -ItemType Directory -Path $SDK_ROOT -Force | Out-Null
        }
        Resolve-WebDownload -Url $CMDLINE_TOOLS_URL -DestinationPath $downloadPath -ProgressUI $ProgressUI
        Write-UILog -ProgressUI $ProgressUI -Message "Extracting Android SDK..."
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        if (Test-Path "$extractPath\cmdline-tools") {
            Rename-Item -Path "$extractPath\cmdline-tools" -NewName "latest" -Force
        }
        Remove-Item $downloadPath -Force
    }
    catch {
        Write-UILog -ProgressUI $ProgressUI -Message "SDK Download Error: $_"
        throw
    }
}

function Install-AndroidComponents {
    param($ProgressUI)
    Write-UILog -ProgressUI $ProgressUI -Message "Installing Android SDK components..."
    $sdkManagerPath = "$SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat"
    try {
        Resolve-ProcessExecution -FilePath $sdkManagerPath -ArgumentList @("--licenses") -ProgressUI $ProgressUI
        foreach ($component in $Components) {
            Write-UILog -ProgressUI $ProgressUI -Message "Installing $component..."
            Resolve-ProcessExecution -FilePath $sdkManagerPath -ArgumentList @($component) -ProgressUI $ProgressUI
        }
    }
    catch {
        Write-UILog -ProgressUI $ProgressUI -Message "Component Installation Error: $_"
        throw
    }
}

# --- Main Setup Orchestration ---
function Start-AndroidSDKSetup {
    $progressUI = Show-AdvancedProgressForm
    $progressUI.Form.Show()

    try {
        Update-Progress -ProgressUI $progressUI -Status "Downloading SDK Tools..." -Percentage 20
        Download-AndroidSDK -ProgressUI $progressUI

        Update-Progress -ProgressUI $progressUI -Status "Installing SDK Components..." -Percentage 60
        Install-AndroidComponents -ProgressUI $progressUI

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

# --- Entry Point ---
[System.Windows.Forms.Application]::EnableVisualStyles()
Start-AndroidSDKSetup
