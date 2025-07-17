<#
.SYNOPSIS
    Dotfiles installation and configuration script for Windows development environment
.DESCRIPTION
    This script automatically installs and configures:
    - PowerShell 7 with custom modules and profile
    - Komorebi window manager with Whkd
    - Yasb status bar
    - Oh-My-Posh for prompt customization
    - Nerd Fonts
    - Chocolatey and various tools
#>

#=====================================
# PRELIMINARY CHECKS
#=====================================

# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrator privileges. Please run it as Administrator."
    break
}

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
Write-Host "PowerShell execution policy set to Bypass" -ForegroundColor Green

#=====================================
# UTILITY FUNCTIONS
#=====================================

# PWSH5 -> PWSH7 function from winutil
# https://winutil.christitus.com/dev/tweaks/essential-tweaks/powershell7
function Invoke-WPFTweakPS7{
    <#
    .SYNOPSIS
        This will edit the config file of the Windows Terminal Replacing the Powershell 5 to Powershell 7 and install Powershell 7 if necessary
    .PARAMETER action
        PS7:           Configures Powershell 7 to be the default Terminal
        PS5:           Configures Powershell 5 to be the default Terminal
    #>
    param (
        [ValidateSet("PS7", "PS5")]
        [string]$action
    )

    switch ($action) {
        "PS7"{
            if (Test-Path -Path "$env:ProgramFiles\PowerShell\7") {
                Write-Host "Powershell 7 is already installed."
            } else {
                Write-Host "Installing Powershell 7..."
                winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements
            }
            $targetTerminalName = "PowerShell"
        }
        "PS5"{
            $targetTerminalName = "Windows PowerShell"
        }
    }
    # Check if the Windows Terminal is installed and return if not (Prerequisite for the following code)
    if (-not (Get-Command "wt" -ErrorAction SilentlyContinue)) {
        Write-Host "Windows Terminal not installed. Skipping Terminal preference"
        return
    }
    # Check if the Windows Terminal settings.json file exists and return if not (Prereqisite for the following code)
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path -Path $settingsPath)) {
        Write-Host "Windows Terminal Settings file not found at $settingsPath"
        return
    }

    Write-Host "Settings file found."
    $settingsContent = Get-Content -Path $settingsPath | ConvertFrom-Json
    $ps7Profile = $settingsContent.profiles.list | Where-Object { $_.name -eq $targetTerminalName }
    if ($ps7Profile) {
        $settingsContent.defaultProfile = $ps7Profile.guid
        $updatedSettings = $settingsContent | ConvertTo-Json -Depth 100
        Set-Content -Path $settingsPath -Value $updatedSettings
        Write-Host "Default profile updated to " -NoNewline
        Write-Host "$targetTerminalName " -ForegroundColor White -NoNewline
        Write-Host "using the name attribute."
    } else {
        Write-Host "No PowerShell 7 profile found in Windows Terminal settings using the name attribute."
    }
}
function Test-InternetConnection {
    <#
    .SYNOPSIS
        Tests Internet connectivity by pinging Google
    .OUTPUTS
        Boolean - True if connection is available, False otherwise
    #>
    try {
        Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Nerd Fonts installation function
function Install-NerdFonts {
    <#
    .SYNOPSIS
        Downloads and installs specified Nerd Fonts
    .PARAMETER FontName
        Font name to download (ZIP file name)
    .PARAMETER FontDisplayName
        Font display name for installation verification
    .PARAMETER Version
        Nerd Fonts version to download
    #>
    param (
        [string]$FontName = "CascadiaCode",
        [string]$FontDisplayName = "CaskaydiaCove NF",
        [string]$Version = "3.4.0"
    )

    try {
        Write-Host "Checking installation of font $FontDisplayName..." -ForegroundColor Yellow

        # Load assembly to check installed fonts
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

        if ($fontFamilies -notcontains $FontDisplayName) {
            Write-Host "Installing font $FontDisplayName..." -ForegroundColor Blue

            # Download URLs and paths
            $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
            $zipFilePath = "$env:TEMP\${FontName}.zip"
            $extractPath = "$env:TEMP\${FontName}"

            # Download font
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri($fontZipUrl)), $zipFilePath)

            # Wait for download completion
            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            # Extract and install
            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)

            Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                if (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            # Clean up temporary files
            Remove-Item -Path $extractPath -Recurse -Force
            Remove-Item -Path $zipFilePath -Force
            Write-Host "Font $FontDisplayName installed successfully" -ForegroundColor Green
        } else {
            Write-Host "Font $FontDisplayName already installed" -ForegroundColor Gray
        }
    }
    catch {
        Write-Error "Failed to download or install font $FontDisplayName. Error: $_"
    }
}

#=====================================
# POWERSHELL 7 ENVIRONMENT SETUP
#=====================================

# Check if script is running in PowerShell 7
if ($PSVersionTable.PSEdition -ne 'Core') {
    Write-Warning "This script requires PowerShell 7 (Core). Attempting to restart in PowerShell 7..."

    # Install PowerShell 7 if not present
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        Write-Host "PowerShell 7 not found. Installing..." -ForegroundColor Yellow
        Invoke-WPFTweakPS7 -action PS7
    }

    # Restart script in PowerShell 7
    try {
        $arguments = @("-NoExit", "-Command", "& { irm 'https://raw.githubusercontent.com/Tripticon84/dotfiles/main/install.ps1' | iex }")
        Start-Process -FilePath "pwsh.exe" -ArgumentList $arguments -Verb RunAs
        exit
    }
    catch {
        Write-Error "Failed to restart in PowerShell 7: $_"
        exit 1
    }
}

# If we reach here, we're running in PowerShell 7
Write-Host "Running in PowerShell 7 environment." -ForegroundColor Green

#=====================================
# SYSTEM PREREQUISITES
#=====================================

Write-Host "Setting up system prerequisites..." -ForegroundColor Blue

# Check Git installation
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed. Please install Git before continuing."
    exit 1
}

# Set environment variables
$Env:KOMOREBI_CONFIG_HOME = "$HOME\.config\komorebi"

# Add KOMOREBI_CONFIG_HOME to permanent user environment variables
Write-Host "Adding KOMOREBI_CONFIG_HOME to user environment variables..." -ForegroundColor Yellow
try {
    [Environment]::SetEnvironmentVariable("KOMOREBI_CONFIG_HOME", "$HOME\.config\komorebi", "User")
    Write-Host "KOMOREBI_CONFIG_HOME environment variable set permanently." -ForegroundColor Green
} catch {
    Write-Warning "Failed to set KOMOREBI_CONFIG_HOME environment variable: $_"
    Write-Host "Please manually add KOMOREBI_CONFIG_HOME=$HOME\.config\komorebi to your user environment variables." -ForegroundColor Yellow
}


# Enable long paths in Windows
Write-Host "Enabling long paths in Windows..." -ForegroundColor Yellow
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

#=====================================
# PACKAGE MANAGERS INSTALLATION
#=====================================

Write-Host "Installing package managers..." -ForegroundColor Blue

# Install Chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Chocolatey installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Chocolatey. Error: $_"
    }
} else {
    Write-Host "Chocolatey already installed." -ForegroundColor Gray
}

# Install NuGet package provider
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "Installing NuGet package provider..." -ForegroundColor Yellow
        Install-PackageProvider NuGet -Force
        Write-Host "NuGet package provider installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install NuGet package provider. Error: $_"
    }
} else {
    Write-Host "NuGet package provider already installed." -ForegroundColor Gray
}

# Set PSGallery as trusted repository
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
    try {
        Write-Host "Setting PSGallery as trusted repository..." -ForegroundColor Yellow
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Write-Host "PSGallery repository configured as trusted." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to configure PSGallery repository. Error: $_"
    }
} else {
    Write-Host "PSGallery repository already trusted." -ForegroundColor Gray
}

#=====================================
# DOTFILES REPOSITORY SETUP
#=====================================

Write-Host "Setting up dotfiles repository..." -ForegroundColor Blue

# Create .config directory if it doesn't exist
if (-not (Test-Path -Path "$HOME\.config")) {
    Write-Host "Creating .config directory..." -ForegroundColor Yellow
    New-Item -Path "$HOME\.config" -ItemType Directory -Force | Out-Null
} else {
    Write-Host ".config directory already exists." -ForegroundColor Gray
}

# Clone or update dotfiles repository
$repoUrl = "https://github.com/Tripticon84/dotfiles.git"
$dotfilesPath = "$HOME\.dotfiles"

if (-not (Test-Path -Path $dotfilesPath)) {
    Write-Host "Cloning dotfiles repository..." -ForegroundColor Yellow
    git clone $repoUrl $dotfilesPath
} else {
    Write-Host "Dotfiles repository already exists. Pulling latest changes..." -ForegroundColor Yellow
    Push-Location $dotfilesPath
    git pull
    Pop-Location
}

# Copy existing config (if needed)
if (Test-Path "$HOME\.config") {
    Write-Host "Copying existing .config to dotfiles..." -ForegroundColor Yellow
    Copy-Item -Path "$HOME\.config\*" -Destination "$HOME\.dotfiles\.config" -Recurse
}

# Remove the old config folder
if (Test-Path "$HOME\.config") {
    Write-Host "Removing old .config directory..." -ForegroundColor Yellow
    Remove-Item -Path "$HOME\.config" -Recurse -Force
}

# Create symbolic link
Write-Host "Creating symbolic link for .config..." -ForegroundColor Blue
New-Item -Path "$HOME\.config" -ItemType SymbolicLink -Value "$HOME\.dotfiles\.config" -Force

#=====================================
# POWERSHELL MODULES INSTALLATION
#=====================================

Write-Host "Installing PowerShell modules..." -ForegroundColor Blue

# Install Terminal-Icons module
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    try {
        Write-Host "Installing Terminal-Icons module..." -ForegroundColor Yellow
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        Write-Host "Terminal-Icons module installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Terminal-Icons module. Error: $_"
    }
} else {
    Write-Host "Terminal-Icons module already installed." -ForegroundColor Gray
}

# Install PSReadLine module
if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
    try {
        Write-Host "Installing PSReadLine module..." -ForegroundColor Yellow
        Install-Module -Name PSReadLine -Repository PSGallery -Force
        Write-Host "PSReadLine module installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install PSReadLine module. Error: $_"
    }
} else {
    Write-Host "PSReadLine module already installed." -ForegroundColor Gray
}

#=====================================
# POWERSHELL PROFILE CONFIGURATION
#=====================================

Write-Host "Configuring PowerShell profile..." -ForegroundColor Blue

$profilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# Ensure the PowerShell profile exists
if (-not (Test-Path -Path $profilePath)) {
    # Create directory if it doesn't exist
    $profileDir = Split-Path $profilePath -Parent
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }

    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Write-Host "PowerShell profile created at $profilePath" -ForegroundColor Green
}
else {
    Write-Host "PowerShell profile already exists. Backing up existing profile." -ForegroundColor Yellow
    $backupPath = "$profilePath.bak"
    Copy-Item -Path $profilePath -Destination $backupPath -Force
    Write-Host "Backup created at $backupPath" -ForegroundColor Green
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Write-Host "PowerShell profile reset at $profilePath" -ForegroundColor Green
}

# Redirect profile to custom script
$profileContent = ". $HOME\.config\powershell\profile.ps1"
$profileRaw = Get-Content -Path $profilePath -Raw
if ($null -eq $profileRaw -or -not $profileRaw.Contains($profileContent)) {
    Add-Content -Path $profilePath -Value $profileContent
    Write-Host "PowerShell profile configured to use dotfiles" -ForegroundColor Green
}

#=====================================
# TERMINAL CUSTOMIZATION TOOLS
#=====================================

Write-Host "Installing terminal customization tools..." -ForegroundColor Blue

# Install Oh-My-Posh
try {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Oh-My-Posh..." -ForegroundColor Yellow
        winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
        Write-Host "Oh-My-Posh installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Oh-My-Posh already installed." -ForegroundColor Gray
    }
} catch {
    Write-Error "Failed to install Oh-My-Posh: $_"
}

# Install Starship
try {
    if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Starship..." -ForegroundColor Yellow
        winget install -e --accept-source-agreements --accept-package-agreements Starship.Starship
        Write-Host "Starship installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Starship already installed." -ForegroundColor Gray
    }
} catch {
    Write-Error "Failed to install Starship: $_"
}

# Install Winfetch script
if (-not (Get-Command winfetch -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "Installing Winfetch script..." -ForegroundColor Yellow
        Install-Script -Name winfetch -Force
        Write-Host "Winfetch script installed successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to install Winfetch script. Error: $_"
    }
} else {
    Write-Host "Winfetch script already installed." -ForegroundColor Gray
}

#=====================================
# SYSTEM UTILITIES
#=====================================

Write-Host "Installing system utilities..." -ForegroundColor Blue

# Install zoxide
if (-not (Get-Command zoxide -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "Installing zoxide..." -ForegroundColor Yellow
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
} else {
    Write-Host "zoxide already installed." -ForegroundColor Gray
}

#=====================================
# WINDOW MANAGER SETUP
#=====================================

Write-Host "Installing window management tools..." -ForegroundColor Blue

# Install Whkd
if (-not (Get-Command whkd -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Whkd..." -ForegroundColor Yellow
    winget install -e --id LGUG2Z.whkd
    Write-Host "Whkd installed successfully." -ForegroundColor Green
} else {
    Write-Host "Whkd already installed." -ForegroundColor Gray
}

# Install Komorebi
if (-not (Get-Command komorebi -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Komorebi..." -ForegroundColor Yellow
    winget install -e --id LGUG2Z.komorebi
    Write-Host "Komorebi installed successfully." -ForegroundColor Green
} else {
    Write-Host "Komorebi already installed." -ForegroundColor Gray
}

# Install Yasb
if (-not (Get-Command yasb -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Yasb..." -ForegroundColor Yellow
    winget install -e --id AmN.yasb
    Write-Host "Yasb installed successfully." -ForegroundColor Green
} else {
    Write-Host "Yasb already installed." -ForegroundColor Gray
}

# Reload path for newly installed tools
Write-Host "Reloading PATH environment variable..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")

#=====================================
# FONTS INSTALLATION
#=====================================

Write-Host "Installing Nerd Fonts..." -ForegroundColor Blue
# Install-NerdFonts -FontName "CascadiaCode" -FontDisplayName "CaskaydiaCove NF"
# Install-NerdFonts -FontName "JetBrainsMono" -FontDisplayName "JetBrainsMono NF"
# Install-NerdFonts -FontName "FiraCode" -FontDisplayName "FiraCode NF"

# Using oh-my-posh to install fonts

# Cascadia Code NF
try {
    Write-Host "Installing Cascadia Code NF font..." -ForegroundColor Yellow
    oh-my-posh font install "CascadiaCode"
    Write-Host "Cascadia Code NF font installed successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to install Cascadia Code NF font: $_"
}

# Fira Code NF
try {
    Write-Host "Installing Fira Code NF font..." -ForegroundColor Yellow
    oh-my-posh font install "FiraCode"
    Write-Host "Fira Code NF font installed successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to install Fira Code NF font: $_"
}

#=====================================
# AUTOSTART CONFIGURATION
#=====================================

Write-Host "Configuring autostart services..." -ForegroundColor Blue

# Configure Komorebi autostart
try {
    Write-Host "Configuring Komorebi autostart..." -ForegroundColor Yellow
    komorebic enable-autostart --whkd
    Write-Host "Komorebi configured to start automatically." -ForegroundColor Green
} catch {
    Write-Warning "Unable to configure Komorebi autostart: $_"
}

# Configure Yasb autostart
try {
    Write-Host "Configuring Yasb autostart..." -ForegroundColor Yellow
    yasbc enable-autostart
    Write-Host "Yasb configured to start automatically." -ForegroundColor Green
} catch {
    Write-Warning "Unable to configure Yasb autostart: $_"
}

#=====================================
# ADDITIONAL TOOLS
#=====================================

Write-Host "Installing additional tools..." -ForegroundColor Blue

# Install Windhawk
$windhawkInstalled = winget list --name "Windhawk" 2>$null | Where-Object { $_ -match "Windhawk" }
if (-not $windhawkInstalled) {
    Write-Host "Installing Windhawk..." -ForegroundColor Yellow
    winget install -e --id RamenSoftware.Windhawk
    Write-Host "Windhawk installed successfully." -ForegroundColor Green
} else {
    Write-Host "Windhawk already installed." -ForegroundColor Gray
}

#=====================================
# INSTALLATION COMPLETE
#=====================================

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Dotfiles have been installed and configured." -ForegroundColor White
Write-Host "Please restart your session for all changes to take effect." -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
