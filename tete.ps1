$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-Section {
    param([string]$Message)

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-File {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $file = Get-Item -LiteralPath $Path
        Write-Log "File exists: $Path" Green
        Write-Log "  Size: $($file.Length) bytes" DarkGray
        Write-Log "  Last modified: $($file.LastWriteTime)" DarkGray
        return $true
    }

    Write-Log "FILE NOT FOUND: $Path" Red
    return $false
}

Write-Section "Apple USB and Mobile Device Drivers Installer"

Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" DarkGray
Write-Log "OS: $([System.Environment]::OSVersion.VersionString)" DarkGray
Write-Log "Computer: $env:COMPUTERNAME" DarkGray
Write-Log "User: $env:USERNAME" DarkGray
Write-Log "Current directory: $($PWD.Path)" DarkGray
Write-Log "Temporary directory: $env:TEMP" DarkGray

$AppleDri1 = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2020/11/01d96dfd-2f6f-46f7-8bc3-fd82088996d2_a31ff7000e504855b3fa124bf27b3fe5bc4d0893.cab"
$AppleDri2 = "https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2017/11/netaapl_7503681835e08ce761c52858949731761e1fa5a1.cab"
$AppleITunesLink = "https://www.apple.com/itunes/download/win64"

Write-Section "Checking Administrator Privileges"

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Administrator privileges: NOT DETECTED" Red
    Write-Log "This script requires administrative privileges." Yellow
    Write-Log "Please run PowerShell as Administrator and run the script again." Yellow
    pause
    exit 1
}

Write-Log "Administrator privileges: OK" Green

Write-Section "Preparing Temporary Directory"

$destinationFolder = [System.IO.Path]::Combine($env:TEMP, "AppleDriTemp")

Write-Log "Temporary driver directory: $destinationFolder"

if (-not (Test-Path -LiteralPath $destinationFolder)) {
    Write-Log "Directory does not exist. Creating it..." Yellow
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
    Write-Log "Directory created successfully." Green
}
else {
    Write-Log "Temporary directory already exists." Green
}

try {
    $currentPath = $PWD.Path

    Write-Section "Downloading Apple iTunes"

    $itunesInstaller = Join-Path $destinationFolder "iTunes64Setup.exe"

    Write-Log "Source:"
    Write-Log "  $AppleITunesLink" DarkGray

    Write-Log "Destination:"
    Write-Log "  $itunesInstaller" DarkGray

    Write-Log "Starting download..." Yellow

    $downloadTimer = [System.Diagnostics.Stopwatch]::StartNew()
Write-Log "Downloading iTunes with Invoke-WebRequest..." Yellow
Write-Log "URL: $AppleITunesLink" DarkGray
Write-Log "Output: $itunesInstaller" DarkGray

$downloadTimer = [System.Diagnostics.Stopwatch]::StartNew()

try {
    Invoke-WebRequest `
        -Uri $AppleITunesLink `
        -OutFile $itunesInstaller `
        -UseBasicParsing `
        -TimeoutSec 120 `
        -MaximumRedirection 10 `
        -Verbose

    $downloadTimer.Stop()

    Write-Log "Download completed in $([math]::Round($downloadTimer.Elapsed.TotalSeconds, 2)) seconds." Green
}
catch {
    $downloadTimer.Stop()

    Write-Log "iTunes download failed after $([math]::Round($downloadTimer.Elapsed.TotalSeconds, 2)) seconds." Red
    Write-Log "Exception: $($_.Exception.Message)" Red
    throw
}

    $downloadTimer.Stop()

    Write-Log "iTunes download completed in $([math]::Round($downloadTimer.Elapsed.TotalSeconds, 2)) seconds." Green

    if (-not (Test-File $itunesInstaller)) {
        throw "iTunes installer was not downloaded successfully."
    }

    Write-Section "Extracting AppleMobileDeviceSupport64.msi"

    Write-Log "Changing directory to temporary folder..."
    Set-Location "$destinationFolder"

    Write-Log "Running:"
    Write-Log "  $itunesInstaller /extract" DarkGray

    $process = Start-Process `
        -FilePath $itunesInstaller `
        -ArgumentList "/extract" `
        -Wait `
        -PassThru

    Write-Log "iTunes extraction process exited with code: $($process.ExitCode)"

    if ($process.ExitCode -ne 0) {
        Write-Log "WARNING: iTunes extraction returned a non-zero exit code." Yellow
    }

    Set-Location "$currentPath"

    $appleMsi = Join-Path $destinationFolder "AppleMobileDeviceSupport64.msi"

    if (-not (Test-File $appleMsi)) {
        throw "AppleMobileDeviceSupport64.msi was not found after extraction."
    }

    Write-Section "Installing Apple Mobile Device Support"

    Write-Log "MSI:"
    Write-Log "  $appleMsi" DarkGray

    Write-Log "Arguments:"
    Write-Log "  /qn" DarkGray

    Write-Log "Starting MSI installation..." Yellow

    $process = Start-Process `
        -FilePath $appleMsi `
        -ArgumentList "/qn" `
        -Wait `
        -PassThru

    Write-Log "MSI installer exited with code: $($process.ExitCode)"

    if ($process.ExitCode -ne 0) {
        throw "Apple Mobile Device Support installation failed with exit code $($process.ExitCode)."
    }

    Write-Log "Apple Mobile Device Support installed successfully." Green

    Write-Section "Downloading Apple USB Drivers"

    $appleUsbCab = Join-Path $destinationFolder "AppleUSB-486.0.0.0-driv.cab"

    Write-Log "Source:"
    Write-Log "  $AppleDri1" DarkGray

    Write-Log "Destination:"
    Write-Log "  $appleUsbCab" DarkGray

    Write-Log "Downloading Apple USB driver CAB..." Yellow

    Invoke-WebRequest `
        -Uri $AppleDri1 `
        -OutFile $appleUsbCab

    if (-not (Test-File $appleUsbCab)) {
        throw "Apple USB driver CAB was not downloaded."
    }

    Write-Log "Apple USB driver download completed." Green

    Write-Section "Downloading Apple Mobile Device Ethernet Driver"

    $appleNetCab = Join-Path $destinationFolder "AppleNet-1.8.5.1-driv.cab"

    Write-Log "Source:"
    Write-Log "  $AppleDri2" DarkGray

    Write-Log "Destination:"
    Write-Log "  $appleNetCab" DarkGray

    Write-Log "Downloading Apple Ethernet driver CAB..." Yellow

    Invoke-WebRequest `
        -Uri $AppleDri2 `
        -OutFile $appleNetCab

    if (-not (Test-File $appleNetCab)) {
        throw "Apple Ethernet driver CAB was not downloaded."
    }

    Write-Log "Apple Ethernet driver download completed." Green

    Write-Section "Extracting Driver CAB Files"

    Write-Log "Extracting Apple USB driver..."
    Write-Log "Command: expand.exe -F:* `"$appleUsbCab`" `"$destinationFolder`"" DarkGray

    & expand.exe -F:* "$appleUsbCab" "$destinationFolder"

    $expandExitCode = $LASTEXITCODE

    Write-Log "Apple USB extraction exit code: $expandExitCode"

    if ($expandExitCode -ne 0) {
        throw "Apple USB driver extraction failed with exit code $expandExitCode."
    }

    Write-Log "Apple USB driver extracted successfully." Green

    Write-Log "Extracting Apple Ethernet driver..."
    Write-Log "Command: expand.exe -F:* `"$appleNetCab`" `"$destinationFolder`"" DarkGray

    & expand.exe -F:* "$appleNetCab" "$destinationFolder"

    $expandExitCode = $LASTEXITCODE

    Write-Log "Apple Ethernet extraction exit code: $expandExitCode"

    if ($expandExitCode -ne 0) {
        throw "Apple Ethernet driver extraction failed with exit code $expandExitCode."
    }

    Write-Log "Apple Ethernet driver extracted successfully." Green

    Write-Section "Installing Drivers"

    $infFiles = @(Get-ChildItem -Path "$destinationFolder\*.inf" -File)

    Write-Log "Found $($infFiles.Count) INF driver files."

    if ($infFiles.Count -eq 0) {
        throw "No INF driver files were found after extraction."
    }

    foreach ($inf in $infFiles) {
        Write-Host ""
        Write-Log "------------------------------------------------------------" DarkGray
        Write-Log "Installing driver: $($inf.Name)" Yellow
        Write-Log "Full path: $($inf.FullName)" DarkGray
        Write-Log "File size: $($inf.Length) bytes" DarkGray
        Write-Log "Command: pnputil /add-driver `"$($inf.FullName)`" /install" DarkGray
        Write-Log "------------------------------------------------------------" DarkGray

        & pnputil /add-driver "$($inf.FullName)" /install

        $pnputilExitCode = $LASTEXITCODE

        Write-Log "pnputil exit code: $pnputilExitCode"

        switch ($pnputilExitCode) {
            0 {
                Write-Log "Driver installed successfully." Green
            }
            default {
                Write-Log "pnputil returned a non-zero exit code: $pnputilExitCode" Yellow
                Write-Log "Continuing with the remaining drivers..." Yellow
            }
        }
    }

    Write-Section "Driver Installation Summary"

    $installedInfFiles = @(Get-ChildItem -Path "$destinationFolder\*.inf" -File)

    Write-Log "INF files processed: $($installedInfFiles.Count)"

    foreach ($inf in $installedInfFiles) {
        Write-Log "  $($inf.Name)" DarkGray
    }

    Write-Section "Cleaning Temporary Files"

    if (Test-Path -LiteralPath $destinationFolder) {
        Write-Log "Removing temporary directory:"
        Write-Log "  $destinationFolder" DarkGray

        Remove-Item -Path $destinationFolder -Recurse -Force

        Write-Log "Temporary files removed successfully." Green
    }
    else {
        Write-Log "Temporary directory was already removed." Yellow
    }

}
catch {
    Write-Section "INSTALLATION FAILED"

    Write-Log "Error message:" Red
    Write-Log "  $($_.Exception.Message)" Red

    Write-Log "Error type:" Red
    Write-Log "  $($_.Exception.GetType().FullName)" Red

    if ($_.InvocationInfo) {
        Write-Log "Script location:" Red
        Write-Log "  Line $($_.InvocationInfo.ScriptLineNumber)" Red
        Write-Log "  $($_.InvocationInfo.Line.Trim())" Red
    }

    Write-Log "" Red
    Write-Log "Temporary files have NOT been automatically removed so they can be inspected." Yellow

    Write-Log "Temporary directory:" Yellow
    Write-Log "  $destinationFolder" Yellow
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Installation process complete." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "If Apple devices are still not working, a reboot may be required." Yellow
Write-Log "Press any key to exit..." DarkGray

pause
