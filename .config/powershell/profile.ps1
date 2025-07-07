#==============================================================================
# PowerShell Profile Configuration
#==============================================================================


#------------------------------------------------------------------------------
# Security and Telemetry Configuration
#------------------------------------------------------------------------------

# Allow execution of locally signed scripts for the current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

#------------------------------------------------------------------------------
# Module Imports and External Profiles
#------------------------------------------------------------------------------

# Ensure Terminal-Icons module is installed before importing
Import-Module -Name Terminal-Icons

# Import Chocolatey profile if available
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

#------------------------------------------------------------------------------
# Administrative Privileges and Prompt Customization
#------------------------------------------------------------------------------

# Check for administrative privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Custom prompt function
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}

# Set window title with admin indicator
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

#------------------------------------------------------------------------------
# Utility Functions
#------------------------------------------------------------------------------

# Check if a command exists
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

#------------------------------------------------------------------------------
# Editor Configuration
#------------------------------------------------------------------------------

# Set preferred editor based on availability
# $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
#           elseif (Test-CommandExists vim) { 'vim' }
#           elseif (Test-CommandExists code) { 'code' }
#           elseif (Test-CommandExists sublime_text) { 'sublime_text' }
#           else { 'notepad' }
$EDITOR = "code"
Set-Alias -Name vim -Value $EDITOR

# Quick access to editing the profile
function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile

#------------------------------------------------------------------------------
# File System Utilities
#------------------------------------------------------------------------------

# Create empty file (Unix-like touch command)
function touch($file) { "" | Out-File $file -Encoding ASCII }

# Find files recursively
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Create new file with specified name
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Create directory and change to it
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

# Extract zip files
function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

# Compress files to archive
function zip {
    param(
        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [string[]]$Items
    )
    $archive = "archive.zip"
    Compress-Archive -Path $Items -DestinationPath $archive -Force
}

# Move items to recycle bin
function trash($path) {
    $fullPath = (Resolve-Path -Path $path).Path

    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath

        if ($item.PSIsContainer) {
          # Handle directory
            $parentPath = $item.Parent.FullName
        } else {
            # Handle file
            $parentPath = $item.DirectoryName
        }

        $shell = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

        if ($item) {
            $shellItem.InvokeVerb('delete')
            Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
        } else {
            Write-Host "Error: Could not find the item '$fullPath' to trash."
        }
    } else {
        Write-Host "Error: Item '$fullPath' does not exist."
    }
}

#------------------------------------------------------------------------------
# Navigation Shortcuts
#------------------------------------------------------------------------------

# Navigate to Documents folder
function docs {
    $docs = if(([Environment]::GetFolderPath("MyDocuments"))) {([Environment]::GetFolderPath("MyDocuments"))} else {$HOME + "\Documents"}
    Set-Location -Path $docs
}

# Navigate to Desktop folder
function dtop {
    $dtop = if ([Environment]::GetFolderPath("Desktop")) {[Environment]::GetFolderPath("Desktop")} else {$HOME + "\Documents"}
    Set-Location -Path $dtop
}

#------------------------------------------------------------------------------
# Network Utilities
#------------------------------------------------------------------------------

# Get public IP address
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# Flush DNS cache
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

#------------------------------------------------------------------------------
# System Utilities and Tools
#------------------------------------------------------------------------------

# Open WinUtil full-release
function winutil { irm https://christitus.com/win | iex }

# Run commands with elevated privileges
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}
Set-Alias -Name su -Value admin

# Display system uptime
function uptime {
    $os = Get-CimInstance Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot

    $days = $uptime.Days
    $hours = $uptime.Hours
    $minutes = $uptime.Minutes
    $seconds = $uptime.Seconds

    $result = @()
    if ($days -gt 0) {
        $result += "$days jour" + ($(if ($days -eq 1) { "" } else { "s" }))
    }
    if ($hours -gt 0) {
        $result += "$hours heure" + ($(if ($hours -eq 1) { "" } else { "s" }))
    }
    if ($minutes -gt 0) {
        $result += "$minutes minute" + ($(if ($minutes -eq 1) { "" } else { "s" }))
    }
    if ($seconds -gt 0 -or $result.Count -eq 0) {
        $result += "$seconds seconde" + ($(if ($seconds -eq 1) { "" } else { "s" }))
    }

    Write-Host ($result -join ", ")
}

# Reload PowerShell profile
function reload-profile {
    & $profile
}

# Get system information
function sysinfo { Get-ComputerInfo }

#------------------------------------------------------------------------------
# System Cache Management
#------------------------------------------------------------------------------

function Clear-Cache {
    # add clear cache logic here
    Write-Host "Clearing cache..." -ForegroundColor Cyan

    # Clear Windows Prefetch
    Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

    # Clear Windows Temp
    Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear User Temp
    Write-Host "Clearing User Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear Internet Explorer Cache
    Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Cache clearing completed." -ForegroundColor Green
}

#------------------------------------------------------------------------------
# Komorebi Window Manager Functions
#------------------------------------------------------------------------------

# Start Komorebi with components
function start-komorebi {
    komorebic start --whkd
}

# Stop Komorebi with components
function stop-komorebi {
    komorebic stop --whkd
}

# Short aliases for Komorebi
function startk {
    komorebic start --whkd
}

function stopk {
    komorebic stop --whkd
}

#------------------------------------------------------------------------------
# Unix-like Command Implementations
#------------------------------------------------------------------------------

# Grep functionality
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

# Display volume information (like df in Unix)
function df {
    get-volume
}

# Stream editor functionality (like sed in Unix)
function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

# Find command location (like which in Unix)
function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

# Set environment variables (like export in Unix)
function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

# Display first n lines of a file (like head in Unix)
function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

# Display last n lines of a file (like tail in Unix)
function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

#------------------------------------------------------------------------------
# Process Management
#------------------------------------------------------------------------------

# Kill processes by name
function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

# Find processes by name
function pgrep($name) {
    Get-Process $name
}

# Simplified process termination
function k9 { Stop-Process -Name $args[0] }

#------------------------------------------------------------------------------
# Enhanced Directory Listing
#------------------------------------------------------------------------------

# List all files with formatting
function la { Get-ChildItem | Format-Table -AutoSize }

# List all files including hidden with formatting
function ll { Get-ChildItem -Force | Format-Table -AutoSize }

#------------------------------------------------------------------------------
# Git Shortcuts and Aliases
#------------------------------------------------------------------------------

# Basic git commands
function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m "$m" }
function gp { git push }
function gcl { git clone "$args" }

# Navigate to GitHub directory
function g { __zoxide_z github }

# Combined git operations
function gcom {
    git add .
    git commit -m "$args"
}

# Lazy git workflow (add, commit, push)
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

#------------------------------------------------------------------------------
# Clipboard Utilities
#------------------------------------------------------------------------------

# Copy to clipboard
function cpy { Set-Clipboard $args[0] }

# Paste from clipboard
function pst { Get-Clipboard }

#------------------------------------------------------------------------------
# Enhanced PSReadLine Configuration
#------------------------------------------------------------------------------

# Configure PSReadLine options for better user experience
$PSReadLineOptions = @{
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Command = '#87CEEB'  # SkyBlue (pastel)
        Parameter = '#98FB98'  # PaleGreen (pastel)
        Operator = '#FFB6C1'  # LightPink (pastel)
        Variable = '#DDA0DD'  # Plum (pastel)
        String = '#FFDAB9'  # PeachPuff (pastel)
        Number = '#B0E0E6'  # PowderBlue (pastel)
        Type = '#F0E68C'  # Khaki (pastel)
        Comment = '#D3D3D3'  # LightGray (pastel)
        Keyword = '#8367c7'  # Violet (pastel)
        Error = '#FF6347'  # Tomato (keeping it close to red for visibility)
    }
    PredictionSource = 'HistoryAndPlugin'
    PredictionViewStyle = 'ListView'
    BellStyle = 'None'
}
Set-PSReadLineOption @PSReadLineOptions

# Custom key handlers for enhanced navigation
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

# Custom functions for PSReadLine
Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
    $hasSensitive = $sensitive | Where-Object { $line -match $_ }
    return ($null -eq $hasSensitive)
}

# Improved prediction settings
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -MaximumHistoryCount 10000

#------------------------------------------------------------------------------
# Command Completion Configuration
#------------------------------------------------------------------------------

# Custom completion for common commands
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    $customCompletions = @{
        'git' = @(
            'status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout', 'branch', 'merge', 'rebase', 'reset', 'log', 'diff', 'fetch', 'remote', 'tag', 'stash', 'show', 'cherry-pick', 'revert',
            'switch', 'restore', 'worktree', 'bisect', 'blame', 'clean', 'config', 'describe', 'grep', 'mv', 'notes', 'shortlog', 'submodule', 'verify-commit', 'range-diff'
        )
        'npm' = @(
            'install', 'start', 'run', 'test', 'build', 'init', 'publish', 'update', 'uninstall', 'list', 'search', 'audit', 'outdated', 'ci', 'login', 'logout', 'whoami', 'config', 'cache', 'version',
            'rebuild', 'link', 'prune', 'doctor', 'dedupe', 'exec', 'fund', 'set-script', 'explain', 'edit', 'root', 'completion'
        )
        'deno' = @(
            'run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade', 'install', 'uninstall', 'completions', 'types', 'eval', 'repl', 'task', 'bench', 'coverage', 'check',
            'vendor', 'lsp'
        )
        'docker' = @(
            'build', 'run', 'pull', 'push', 'images', 'ps', 'stop', 'start', 'restart', 'rm', 'rmi', 'exec', 'logs', 'inspect', 'commit', 'tag', 'login', 'logout', 'search', 'volume', 'network', 'compose',
            'context', 'events', 'stats', 'system', 'save', 'load', 'attach', 'cp', 'diff', 'export', 'import', 'update'
        )
        'kubectl' = @(
            'get', 'describe', 'create', 'delete', 'apply', 'edit', 'logs', 'exec', 'port-forward', 'scale', 'rollout', 'config', 'cluster-info', 'top', 'patch', 'replace', 'expose', 'run', 'cp', 'auth',
            'explain', 'attach', 'cordon', 'drain', 'uncordon', 'label', 'annotate', 'api-resources', 'api-versions', 'wait', 'version'
        )
        'dotnet' = @(
            'new', 'restore', 'build', 'run', 'test', 'publish', 'pack', 'clean', 'add', 'remove', 'list', 'sln', 'nuget', 'tool', 'dev-certs', 'user-secrets', 'ef', 'watch', 'format',
            'migrate', 'fsharp', 'msbuild', 'vstest', 'help', 'diagnostics'
        )
        'cargo' = @(
            'new', 'build', 'run', 'test', 'check', 'clean', 'doc', 'publish', 'install', 'uninstall', 'update', 'search', 'login', 'logout', 'owner', 'package', 'bench', 'fix', 'clippy', 'fmt',
            'tree', 'generate-lockfile', 'metadata', 'version', 'verify-project'
        )
        'pip' = @(
            'install', 'uninstall', 'upgrade', 'list', 'show', 'search', 'freeze', 'download', 'wheel', 'hash', 'completion', 'debug', 'config', 'cache', 'check',
            'index', 'inspect', 'help'
        )
        'yarn' = @(
            'add', 'remove', 'install', 'upgrade', 'run', 'test', 'build', 'start', 'init', 'publish', 'info', 'list', 'cache', 'config', 'global', 'outdated', 'audit', 'login', 'logout', 'whoami',
            'set', 'unset', 'why', 'workspace', 'workspaces', 'version', 'dlx'
        )
        'terraform' = @(
            'init', 'plan', 'apply', 'destroy', 'validate', 'fmt', 'show', 'output', 'refresh', 'import', 'state', 'workspace', 'providers', 'version', 'graph', 'console', 'force-unlock', 'taint', 'untaint',
            'login', 'logout', 'test'
        )
        'az' = @(
            'login', 'logout', 'account', 'group', 'vm', 'storage', 'network', 'webapp', 'sql', 'keyvault', 'ad', 'role', 'policy', 'resource', 'deployment', 'monitor', 'backup', 'batch', 'cdn', 'cosmos',
            'acr', 'aks', 'apim', 'appconfig', 'functionapp', 'identity', 'iot', 'pipelines', 'security', 'spring', 'synapse'
        )
        'winget' = @(
            'install', 'uninstall', 'upgrade', 'search', 'show', 'source', 'list', 'export', 'import', 'pin', 'configure', 'download', 'hash', 'validate', 'settings', 'features', 'repair',
            'info', 'reset'
        )
        'choco' = @(
            'install', 'uninstall', 'upgrade', 'search', 'list', 'info', 'source', 'feature', 'config', 'pin', 'outdated', 'export', 'sync', 'download', 'push', 'new', 'pack', 'apikey', 'setapikey', 'unsetapikey',
            'upgrade-all', 'list-all', 'template', 'help'
        )
    }

    $command = $commandAst.CommandElements[0].Value
    if ($customCompletions.ContainsKey($command)) {
        $customCompletions[$command] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}
Register-ArgumentCompleter -Native -CommandName git, npm, deno, docker, kubectl, dotnet, cargo, pip, yarn, terraform, az, winget, choco -ScriptBlock $scriptblock

# .NET CLI completion
$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

#------------------------------------------------------------------------------
# Prompt Theme Initialization
#------------------------------------------------------------------------------

# Initialize Oh My Posh prompt theme
oh-my-posh init pwsh | Invoke-Expression

#------------------------------------------------------------------------------
# Zoxide Integration (Smart Directory Navigation)
#------------------------------------------------------------------------------

# Initialize zoxide
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })

# Set zoxide aliases
Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

#------------------------------------------------------------------------------
# Help Function
#------------------------------------------------------------------------------

# Display help information for custom functions
function Show-Help {
    $helpText = @"
$($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)

$($PSStyle.Foreground.Green)Update-Profile$($PSStyle.Reset) - Checks for profile updates from a remote repository and updates if necessary.

$($PSStyle.Foreground.Green)Update-PowerShell$($PSStyle.Reset) - Checks for the latest PowerShell release and updates if a new version is available.

$($PSStyle.Foreground.Green)Edit-Profile$($PSStyle.Reset) - Opens the current user's profile for editing using the configured editor.

$($PSStyle.Foreground.Green)touch$($PSStyle.Reset) <file> - Creates a new empty file.

$($PSStyle.Foreground.Green)ff$($PSStyle.Reset) <name> - Finds files recursively with the specified name.

$($PSStyle.Foreground.Green)Get-PubIP$($PSStyle.Reset) - Retrieves the public IP address of the machine.

$($PSStyle.Foreground.Green)winutil$($PSStyle.Reset) - Runs the latest WinUtil full-release script from Chris Titus Tech.

$($PSStyle.Foreground.Green)winutildev$($PSStyle.Reset) - Runs the latest WinUtil pre-release script from Chris Titus Tech.

$($PSStyle.Foreground.Green)uptime$($PSStyle.Reset) - Displays the system uptime.

$($PSStyle.Foreground.Green)reload-profile$($PSStyle.Reset) - Reloads the current user's PowerShell profile.

$($PSStyle.Foreground.Green)unzip$($PSStyle.Reset) <file> - Extracts a zip file to the current directory.

$($PSStyle.Foreground.Green)hb$($PSStyle.Reset) <file> - Uploads the specified file's content to a hastebin-like service and returns the URL.

$($PSStyle.Foreground.Green)grep$($PSStyle.Reset) <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.

$($PSStyle.Foreground.Green)df$($PSStyle.Reset) - Displays information about volumes.

$($PSStyle.Foreground.Green)sed$($PSStyle.Reset) <file> <find> <replace> - Replaces text in a file.

$($PSStyle.Foreground.Green)which$($PSStyle.Reset) <name> - Shows the path of the command.

$($PSStyle.Foreground.Green)export$($PSStyle.Reset) <name> <value> - Sets an environment variable.

$($PSStyle.Foreground.Green)pkill$($PSStyle.Reset) <name> - Kills processes by name.

$($PSStyle.Foreground.Green)pgrep$($PSStyle.Reset) <name> - Lists processes by name.

$($PSStyle.Foreground.Green)head$($PSStyle.Reset) <path> [n] - Displays the first n lines of a file (default 10).

$($PSStyle.Foreground.Green)tail$($PSStyle.Reset) <path> [n] - Displays the last n lines of a file (default 10).

$($PSStyle.Foreground.Green)nf$($PSStyle.Reset) <name> - Creates a new file with the specified name.

$($PSStyle.Foreground.Green)mkcd$($PSStyle.Reset) <dir> - Creates and changes to a new directory.

$($PSStyle.Foreground.Green)docs$($PSStyle.Reset) - Changes the current directory to the user's Documents folder.

$($PSStyle.Foreground.Green)dtop$($PSStyle.Reset) - Changes the current directory to the user's Desktop folder.

$($PSStyle.Foreground.Green)ep$($PSStyle.Reset) - Opens the profile for editing.

$($PSStyle.Foreground.Green)k9$($PSStyle.Reset) <name> - Kills a process by name.

$($PSStyle.Foreground.Green)la$($PSStyle.Reset) - Lists all files in the current directory with detailed formatting.

$($PSStyle.Foreground.Green)ll$($PSStyle.Reset) - Lists all files, including hidden, in the current directory with detailed formatting.

$($PSStyle.Foreground.Green)gs$($PSStyle.Reset) - Shortcut for 'git status'.

$($PSStyle.Foreground.Green)ga$($PSStyle.Reset) - Shortcut for 'git add .'.

$($PSStyle.Foreground.Green)gc$($PSStyle.Reset) <message> - Shortcut for 'git commit -m'.

$($PSStyle.Foreground.Green)gp$($PSStyle.Reset) - Shortcut for 'git push'.

$($PSStyle.Foreground.Green)g$($PSStyle.Reset) - Changes to the GitHub directory.

$($PSStyle.Foreground.Green)gcom$($PSStyle.Reset) <message> - Adds all changes and commits with the specified message.

$($PSStyle.Foreground.Green)lazyg$($PSStyle.Reset) <message> - Adds all changes, commits with the specified message, and pushes to the remote repository.

$($PSStyle.Foreground.Green)sysinfo$($PSStyle.Reset) - Displays detailed system information.

$($PSStyle.Foreground.Green)flushdns$($PSStyle.Reset) - Clears the DNS cache.

$($PSStyle.Foreground.Green)cpy$($PSStyle.Reset) <text> - Copies the specified text to the clipboard.

$($PSStyle.Foreground.Green)pst$($PSStyle.Reset) - Retrieves text from the clipboard.

Use '$($PSStyle.Foreground.Magenta)Show-Help$($PSStyle.Reset)' to display this help message.
"@
    Write-Host $helpText
}

#------------------------------------------------------------------------------
# Envornment Variables
#------------------------------------------------------------------------------

$Env:KOMOREBI_CONFIG_HOME = "$HOME\.config\komorebi"


#------------------------------------------------------------------------------
# Profile Initialization Message
#------------------------------------------------------------------------------

Write-Host "$($PSStyle.Foreground.Yellow)Use 'Show-Help' to display help$($PSStyle.Reset)"
