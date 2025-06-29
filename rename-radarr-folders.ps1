#!/usr/bin/env pwsh
# Radarr Movie Folders Renamer - PowerShell Cross-Platform Version
# Compatible with Windows, Linux, and macOS

param(
    [string]$Arg1,
    [string]$Arg2,
    [string]$Arg3,
    [string]$Arg4
)

# Load configuration from config file (default: config.env, can be overridden with CONFIG_FILE env var)
$ConfigFile = if ($env:CONFIG_FILE) { $env:CONFIG_FILE } else { Join-Path $PSScriptRoot "config.env" }

if (-not (Test-Path $ConfigFile)) {
    $ConfigFile = Join-Path $PSScriptRoot "config.env"
}

# Function to expand variables in format ${VARIABLE}
function Expand-ConfigVariable {
    param([string]$Value)
    
    if ($Value -match '\$\{(\w+)\}') {
        $VarName = $Matches[1]
        $VarValue = [Environment]::GetEnvironmentVariable($VarName, "Process")
        if (-not $VarValue) {
            $VarValue = [Environment]::GetEnvironmentVariable($VarName, "Machine")
        }
        if ($VarValue) {
            $Value = $Value -replace "\$\{$VarName\}", $VarValue
        } else {
            Write-Warning "Variable $VarName is not defined"
        }
    }
    return $Value
}

# Read config.env and set environment variables
if (Test-Path $ConfigFile) {
    Get-Content $ConfigFile | ForEach-Object {
        $line = $_.Trim()
        # Skip empty lines and comments
        if ($line -and -not $line.StartsWith('#')) {
            if ($line -contains '=') {
                $parts = $line -split '=', 2
                if ($parts.Count -eq 2) {
                    $varName = $parts[0].Trim()
                    $varValue = Expand-ConfigVariable $parts[1].Trim()
                    [Environment]::SetEnvironmentVariable($varName, $varValue, "Process")
                }
            }
        }
    }
}

# Set default values for required variables
$LogFile = if ($env:LOG_FILE) { $env:LOG_FILE } else { 
    if ($IsWindows) { "C:\path\to\your\logs\rename-radarr-folders.log" }
    else { "/tmp/rename-radarr-folders.log" }
}

$RenameShPath = if ($env:RENAME_SH_PATH) { $env:RENAME_SH_PATH } else { 
    Join-Path $PSScriptRoot "rename-radarr-folders.sh"
}

# Validate critical paths before execution
if (-not (Test-Path $RenameShPath)) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorMsg = "[$timestamp] ERROR: Script not found at: $RenameShPath"
    Add-Content -Path $LogFile -Value $errorMsg -ErrorAction SilentlyContinue
    Write-Error $errorMsg
    exit 2
}

# Create log directory if it doesn't exist
$logDir = Split-Path $LogFile -Parent
if ($logDir -and -not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Log startup information
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$startupInfo = @(
    "[$timestamp] Starting rename-radarr-folders (PowerShell Cross-Platform)",
    "[$timestamp] Script: $RenameShPath",
    "[$timestamp] SCRIPTS_DIR: $($env:SCRIPTS_DIR)",
    "[$timestamp] Platform: $($PSVersionTable.Platform)"
)
$startupInfo | Add-Content -Path $LogFile -ErrorAction SilentlyContinue

# Handle both Radarr environment variables and manual arguments
if ($env:radarr_movie_id) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $radarrInfo = @(
        "[$timestamp] Mode: Radarr environment variables",
        "[$timestamp] radarr_movie_id=$($env:radarr_movie_id)",
        "[$timestamp] radarr_movie_title=$($env:radarr_movie_title)",
        "[$timestamp] radarr_movie_year=$($env:radarr_movie_year)",
        "[$timestamp] radarr_moviefile_quality=$($env:radarr_moviefile_quality)"
    )
    $radarrInfo | Add-Content -Path $LogFile -ErrorAction SilentlyContinue
    
    $scriptArgs = @(
        "radarr_movie_id=$($env:radarr_movie_id)",
        "radarr_movie_title=$($env:radarr_movie_title)",
        "radarr_movie_year=$($env:radarr_movie_year)",
        "radarr_moviefile_quality=$($env:radarr_moviefile_quality)"
    )
} else {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] Mode: Command line arguments" | Add-Content -Path $LogFile -ErrorAction SilentlyContinue
    "[$timestamp] Arguments: $($args -join ' ')" | Add-Content -Path $LogFile -ErrorAction SilentlyContinue
    
    $scriptArgs = @($Arg1, $Arg2, $Arg3, $Arg4) | Where-Object { $_ }
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] Executing with arguments:" | Add-Content -Path $LogFile -ErrorAction SilentlyContinue
$scriptArgs | ForEach-Object { "[$timestamp]   $_" | Add-Content -Path $LogFile -ErrorAction SilentlyContinue }

# Execute the bash script
try {
    $process = Start-Process -FilePath "bash" -ArgumentList @($RenameShPath) + $scriptArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput $LogFile -RedirectStandardError $LogFile
    $exitCode = $process.ExitCode
} catch {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] ERROR: Failed to execute bash script: $_" | Add-Content -Path $LogFile -ErrorAction SilentlyContinue
    $exitCode = 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] Finished rename-radarr-folders, exit code=$exitCode" | Add-Content -Path $LogFile -ErrorAction SilentlyContinue

if ($exitCode -ne 0) {
    "[$timestamp] WARNING: Script failed with exit code $exitCode" | Add-Content -Path $LogFile -ErrorAction SilentlyContinue
}

exit $exitCode 