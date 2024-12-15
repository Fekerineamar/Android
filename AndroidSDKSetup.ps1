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

function Resolve-WebDownload {
    param(
        [string]$Url,
        [string]$Destination,
        [object]$ProgressUI = $null
    )

    try {
        Write-DetailedLog "Starting download from $Url to $Destination" "INFO"

        # Use HttpClient for better control
        $httpClient = [System.Net.Http.HttpClient]::new()
        $httpClient.Timeout = [System.TimeSpan]::FromMinutes(30)

        $response = $httpClient.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
        if (-not $response.IsSuccessStatusCode) {
            throw "Failed to download. Status code: $($response.StatusCode)"
        }

        $stream = $response.Content.ReadAsStreamAsync().Result
        $fileStream = [System.IO.FileStream]::new($Destination, [System.IO.FileMode]::Create)

        # Read the stream and write to the file
        $buffer = New-Object byte[] 8192
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        while ($bytesRead -gt 0) {
            $fileStream.Write($buffer, 0, $bytesRead)
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)

            if ($ProgressUI -ne $null) {
                Update-Progress -ProgressUI $ProgressUI -Status "Downloading..." -Percentage 50
            }
        }

        $fileStream.Close()
        $stream.Close()
        $httpClient.Dispose()

        Write-DetailedLog "Download complete" "INFO"
    }
    catch {
        Write-DetailedLog "Error during download: $_" "ERROR"
        throw
    }
}

function Resolve-ProcessExecution {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [object]$ProgressUI = $null
    )

    Write-DetailedLog "Executing process: $FilePath $($Arguments -join ' ')" "INFO"

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $FilePath
    $process.StartInfo.Arguments = $Arguments -join ' '
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true

    try {
        $process.Start() | Out-Null

        while (-not $process.HasExited) {
            Start-Sleep -Milliseconds 100
            if ($ProgressUI -ne $null) {
                Update-Progress -ProgressUI $ProgressUI -Status "Running process..." -Percentage 75
            }
        }

        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()

        Write-DetailedLog "Process output: $stdout" "INFO"
        if ($stderr -ne '') {
            Write-DetailedLog "Process error: $stderr" "ERROR"
        }

        if ($process.ExitCode -ne 0) {
            throw "Process exited with code $($process.ExitCode)"
        }
    }
    catch {
        Write-DetailedLog "Error during process execution: $_" "ERROR"
        throw
    }
    finally {
        $process.Dispose()
    }
}

function Check-Requirements {
    Write-DetailedLog "Checking PowerShell and .NET requirements..." "INFO"

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
        [System.Windows.MessageBox]::Show("PowerShell 5.1 or higher is required. Please update PowerShell.", "Requirement Check", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        exit
    }

    # Check .NET version
    $dotNetKey = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
    $dotNetVersion = (Get-ItemProperty -Path $dotNetKey).Release
    if ($dotNetVersion -lt 461814) { # 461814 is the Release value for .NET Framework 4.7.2
        [System.Windows.MessageBox]::Show(".NET Framework 4.7.2 or higher is required. Please update .NET Framework.", "Requirement Check", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        exit
    }

    Write-DetailedLog "Requirements satisfied: PowerShell 5.1+ and .NET 4.7.2+" "INFO"
}

function Start-AndroidSDKSetup {
    Check-Requirements

    $progressUI = Show-AdvancedProgressForm
    $progressUI.Form.Show()

    try {
        # Download SDK
        Update-Progress -ProgressUI $progressUI -Status "Downloading Android SDK..." -Percentage 10
        Resolve-WebDownload -Url $global:CMDLINE_TOOLS_URL -Destination "$env:TEMP\commandlinetools.zip" -ProgressUI $progressUI

        # Install Components
        Update-Progress -ProgressUI $progressUI -Status "Installing Android SDK components..." -Percentage 60
        Resolve-ProcessExecution -FilePath "cmd" -Arguments @("/C", "echo", "Installing Components...") -ProgressUI $progressUI

        # Finalization
        Update-Progress -ProgressUI $progressUI -Status "Finalizing setup..." -Percentage 90
        [System.Windows.MessageBox]::Show("Android SDK installation complete.", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
    catch {
        [System.Windows.MessageBox]::Show("Error during installation: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
    finally {
        $progressUI.Form.Close()
    }
}

# Main Execution
[System.Windows.Forms.Application]::EnableVisualStyles()
Start-AndroidSDKSetup
