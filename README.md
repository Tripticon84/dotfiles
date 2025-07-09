# Windows Dotfiles

Welcome to my Windows dotfiles repository! This collection provides a complete development environment setup for Windows with tiling window management, customized status bar, and enhanced terminal experience.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Software Stack](#software-stack)
- [Configuration Files](#configuration-files)
- [Windhawk Modules](#windhawk-modules)
- [Installation](#installation)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Inspirations](#inspirations)

## Overview

This dotfiles repository contains my personal Windows environment configuration, featuring:

- **Tiling Window Management** with Komorebi
- **Custom Status Bar** with YASB (Yet Another Status Bar)
- **Enhanced Terminal Experience** with PowerShell 7, Oh-My-Posh, and custom modules
- **System Customizations** through Windhawk modules
- **Automated Installation** script for quick setup

## Features

- 🖥️ **Tiling Window Manager**: Automatic window arrangement and keyboard-driven navigation
- 📊 **Custom Status Bar**: System monitoring, workspace indicators, and quick controls
- 🎨 **Modern Terminal**: PowerShell 7 with syntax highlighting, auto-completion, and custom prompt
- ⚡ **Productivity Tools**: Smart directory navigation, enhanced file operations, and Git shortcuts
- 🎯 **System Tweaks**: UI improvements and performance optimizations
- 🔧 **Easy Configuration**: Centralized config files and automated setup

## Software Stack

### Core Tools

- [**Windows Terminal**](https://aka.ms/terminal) - Modern terminal application
- [**PowerShell 7**](https://github.com/PowerShell/PowerShell) - Cross-platform task automation solution
- [**Komorebi**](https://github.com/LGUG2Z/komorebi) - Tiling window manager for Windows
- [**WHKD**](https://github.com/LGUG2Z/whkd/) - Hotkey daemon for Windows
- [**YASB**](https://github.com/amnweb/yasb) - Yet Another Status Bar
- [**Windhawk**](https://windhawk.net/) - Windows customization platform

### Terminal Enhancement

- [**Oh-My-Posh**](https://ohmyposh.dev/) - Prompt theme engine for any shell
- [**Terminal Icons**](https://github.com/devblackops/Terminal-Icons) - Folder and file icons in the terminal
- [**PSReadLine**](https://learn.microsoft.com/powershell/module/psreadline) - Command line editing experience
- [**Zoxide**](https://github.com/ajeetdsouza/zoxide) - Smarter cd command inspired by z and autojump

### System Information

- [**Winfetch**](https://github.com/lptstr/winfetch/) - System information tool like neofetch but for Windows

## Configuration Files

| Component                            | Location              | Description                                         |
| ------------------------------------ | --------------------- | --------------------------------------------------- |
| [Windows Terminal](.config/terminal) | `.config/terminal/`   | Terminal appearance, profiles, and key bindings     |
| [PowerShell](.config/powershell)     | `.config/powershell/` | Custom profile with aliases, functions, and modules |
| [Komorebi](.config/komorebi)         | `.config/komorebi/`   | Window management rules and workspace configuration |
| [WHKD](.config/whkdrc)               | `.config/whkdrc`      | Hotkey mappings for window management               |
| [YASB](.config/yasb)                 | `.config/yasb/`       | Status bar widgets and styling                      |
| [Winfetch](.config/winfetch)         | `.config/winfetch/`   | System information display configuration            |

## Windhawk Modules

A curated collection of Windhawk modules to enhance the Windows experience:

### System & Interface Enhancement

- [**Disable Feedback Hub Hotkey**](https://windhawk.net/mods/disable-feedback-hub-hotkey) - Removes the conflicting Win+F feedback hotkey
- [**Disable Office Hotkeys**](https://windhawk.net/mods/disable-office-hotkeys) - Prevents Office applications from hijacking system shortcuts
- [**No Focus Rectangle**](https://windhawk.net/mods/no-focus-rectangle) - Removes visual focus rectangles for cleaner UI
- [**Play-Media-Key fix in Explorer**](https://windhawk.net/mods/lm-mediakey-explorer-fix) - Ensures media keys work properly in File Explorer

### File Management Improvements

- [**Modernize Folder Picker Dialog**](https://windhawk.net/mods/modernize-folder-picker-dialog) - Updates the outdated folder selection dialog
- [**Remove File Explorer Suffixes**](https://windhawk.net/mods/file-explorer-remove-suffixes) - Cleans up unnecessary file name suffixes
- [**Open With - Remove Microsoft Store Menu Item**](https://windhawk.net/mods/remove-ms-store-open-with) - Removes unwanted Store suggestions from context menus
- [**Turn off change file extension warning**](https://windhawk.net/mods/extension-change-no-warning) - Disables annoying extension change warnings

### Taskbar Customization

- [**Middle Click to close on the taskbar**](https://windhawk.net/mods/taskbar-button-click) | [Config](.config/windhawk/taskbar-button-click.json)
- [**Taskbar Background Helper**](https://windhawk.net/mods/taskbar-background-helper) | [Config](.config/windhawk/taskbar-background-helper.json)
- [**Taskbar height and icon size**](https://windhawk.net/mods/taskbar-icon-size) | [Config](.config/windhawk/taskbar-icon-size.json)
- [**Taskbar tray system icon tweaks**](https://windhawk.net/mods/taskbar-tray-system-icon-tweaks) | [Config](.config/windhawk/taskbar-tray-system-icon-tweaks.json)

### Windows 11 Styling

- [**Windows 11 Notification Center Styler**](https://windhawk.net/mods/windows-11-notification-center-styler) | [Config](.config/windhawk/windows-11-notification-center-styler.json)
- [**Windows 11 Start Menu Styler**](https://windhawk.net/mods/windows-11-start-menu-styler) | [Config](.config/windhawk/windows-11-start-menu-styler.json)
- [**Windows 11 Taskbar Styler**](https://windhawk.net/mods/windows-11-taskbar-styler) | [Config](.config/windhawk/windows-11-taskbar-styler.json)

### Development Tools

- [**Themed Regedit ListView**](https://windhawk.net/mods/themed-regedit-listview) | [Config](.config/windhawk/themed-regedit-listview.json)

## Installation

### Prerequisites

- [**Git**](https://git-scm.com/downloads)

### Quick Installation

Run the following command in an **Administrator PowerShell** session:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force;
irm "https://raw.githubusercontent.com/Tripticon84/dotfiles/main/install.ps1" | iex
```

### Manual Installation

1. **Clone the repository**:

   ```powershell
   git clone https://github.com/Tripticon84/dotfiles.git $HOME\.dotfiles
   ```

2. **Create symbolic links**:

   ```powershell
   # Copy existing config (if needed)
   Copy-Item -Path "$HOME\.config\*" -Destination "$HOME\.dotfiles\.config" -Recurse

   # Remove the old config folder
   Remove-Item -Path "$HOME\.config" -Recurse -Force

   # Create the symbolic link
   New-Item -Path "$HOME\.config" -ItemType SymbolicLink -Value "$HOME\.dotfiles\.config"
   ```

3. **Install required software** using the package managers or manual downloads

4. **Configure PowerShell profile**:

   ```powershell
   echo ". $HOME\.config\powershell\profile.ps1" | Out-File $PROFILE -Encoding UTF8
   ```

## Usage

### Window Management

- **Win + TODO** - Navigate between windows
- **Win + TODO** - Move windows
- **Win + TODO** - Switch to workspace
- **Win + TODO** - Move window to workspace
- **Win + TODO** - Open terminal
- **Win + TODO** - Close window

### Terminal Features

- **Smart directory navigation** with `z <partial-name>`
- **Git shortcuts**: `gs` (status), `ga` (add all), `gc "message"` (commit), `gp` (push)
- **System utilities**: `uptime`, `sysinfo`, `flushdns`
- **File operations**: `touch`, `mkcd`, `trash`

### Status Bar

- **Left side**: Workspaces, active window title
- **Center**: Clock and wheather information
- **Right side**: Music, System monitoring, network, power menu

## Troubleshooting

### Common Issues

**Komorebi not starting**:

- Ensure `KOMOREBI_CONFIG_HOME` environment variable is set

**PowerShell profile not loading**:

- Verify execution policy: `Get-ExecutionPolicy`
- Check profile path: `$PROFILE`

**YASB widgets not displaying**:

- Restart YASB: `yasbc restart`
- Check configuration syntax in YAML files

**Fonts not displaying correctly**:

- Install Nerd Fonts: CascadiaCode and JetBrainsMono
- Restart terminal applications

## Inspirations

- [**ashwinjadhav818's dotfiles**](https://github.com/ashwinjadhav818/dotfiles) - Overall structure and Windows setup approach
- [**YASB Acrylic theme by amnweb**](https://github.com/amnweb/yasb-themes/tree/main?tab=readme-ov-file#acrylic) - Status bar styling inspiration
- [**ChrisTitusTech's PowerShell profile**](https://github.com/ChrisTitusTech/powershell-profile) - PowerShell configuration and utilities
- **Windhawk themes**:
  - Start Menu theme based on Windows11_Metro10
  - Taskbar theme based on Docklike
- **Oh-My-Posh theme**: PLACEHOLDER

---

**Note**: This configuration is tailored for my personal workflow. Feel free to adapt it to your needs!
