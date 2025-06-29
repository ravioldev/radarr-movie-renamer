#!/usr/bin/env pwsh
# Git Bash Diagnostic Script
# Checks for Git Bash installation and helps fix configuration issues

param(
    [switch]$Fix,  # Attempt to fix configuration automatically
    [switch]$Quiet # Suppress verbose output
)

function Write-Status {
    param($Message, $Type = "Info")
    if ($Quiet) { return }
    
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Test-GitPath {
    param($Path)
    
    if (-not $Path) { return $false }
    if (-not (Test-Path $Path)) { return $false }
    
    try {
        $result = & $Path --version 2>$null
        return $result -match "bash"
    }
    catch {
        return $false
    }
}

Write-Status "`n🔍 Git Bash Installation Diagnostics`n" "Info"

# Load current configuration
$configFile = Join-Path $PSScriptRoot "config.env"
$currentGitBashPath = ""

if (Test-Path $configFile) {
    Write-Status "✅ Configuration file found: $configFile" "Success"
    
    Get-Content $configFile | ForEach-Object {
        if ($_ -match '^GIT_BASH_PATH=(.+)$') {
            $currentGitBashPath = $matches[1] -replace '"', ''
        }
    }
    
    if ($currentGitBashPath) {
        Write-Status "📋 Current configured path: $currentGitBashPath" "Info"
    }
} else {
    Write-Status "❌ Configuration file not found: $configFile" "Error"
    return
}

# Test current configuration
if ($currentGitBashPath -and (Test-GitPath $currentGitBashPath)) {
    Write-Status "✅ Current Git Bash path is working correctly!" "Success"
    if (-not $Quiet) {
        $version = & $currentGitBashPath --version 2>$null
        Write-Status "   Version: $version" "Info"
    }
    return
}

Write-Status "❌ Current Git Bash path is not working" "Error"

# Search for Git Bash installations
Write-Status "`n🔍 Searching for Git Bash installations..." "Info"

$commonPaths = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe", 
    "C:\PortableGit\bin\bash.exe",
    "C:\Git\bin\bash.exe",
    "C:\tools\git\bin\bash.exe"
)

$foundPaths = @()

foreach ($path in $commonPaths) {
    if (Test-GitPath $path) {
        $foundPaths += $path
        $version = & $path --version 2>$null
        Write-Status "✅ Found working Git Bash: $path" "Success"
        Write-Status "   Version: $version" "Info"
    }
}

# Also search in registry
try {
    $gitInstalls = Get-ItemProperty -Path "HKLM:\SOFTWARE\GitForWindows" -ErrorAction SilentlyContinue
    if ($gitInstalls -and $gitInstalls.InstallPath) {
        $regPath = Join-Path $gitInstalls.InstallPath "bin\bash.exe"
        if ((Test-GitPath $regPath) -and ($regPath -notin $foundPaths)) {
            $foundPaths += $regPath
            Write-Status "✅ Found Git Bash via registry: $regPath" "Success"
        }
    }
} catch {
    # Registry search failed, continue
}

# Check WSL as alternative
if (Test-Path "C:\Windows\System32\wsl.exe") {
    try {
        $wslTest = & "C:\Windows\System32\wsl.exe" -e bash --version 2>$null
        if ($wslTest) {
            $foundPaths += "C:\Windows\System32\wsl.exe"
            Write-Status "✅ Found WSL bash alternative: C:\Windows\System32\wsl.exe" "Success"
        }
    }
    catch {
        # WSL test failed
    }
}

if ($foundPaths.Count -eq 0) {
    Write-Status "`n❌ No working Git Bash installations found!" "Error"
    Write-Status "`n💡 To fix this issue:" "Warning"
    Write-Status "   1. Install Git for Windows from: https://git-scm.com/download/win" "Info"
    Write-Status "   2. Make sure to select 'Git Bash Here' during installation" "Info"
    Write-Status "   3. Re-run this script to verify installation" "Info"
    return
}

Write-Status "`n✅ Found $($foundPaths.Count) working Git Bash installation(s)" "Success"

# Fix configuration automatically if requested
if ($Fix -and $foundPaths.Count -gt 0) {
    $bestPath = $foundPaths[0]  # Use first found path
    Write-Status "`n🔧 Updating configuration with: $bestPath" "Warning"
    
    try {
        # Read current config
        $configContent = Get-Content $configFile
        $newContent = @()
        $pathUpdated = $false
        
        foreach ($line in $configContent) {
            if ($line -match '^GIT_BASH_PATH=') {
                $newContent += "GIT_BASH_PATH=`"$bestPath`""
                $pathUpdated = $true
            } else {
                $newContent += $line
            }
        }
        
        if (-not $pathUpdated) {
            $newContent += "GIT_BASH_PATH=`"$bestPath`""
        }
        
        # Backup original config
        Copy-Item $configFile "$configFile.backup" -Force
        Set-Content $configFile $newContent -Encoding UTF8
        
        Write-Status "✅ Configuration updated successfully!" "Success"
        Write-Status "   Backup saved as: $configFile.backup" "Info"
        
    } catch {
        Write-Status "❌ Failed to update configuration: $($_.Exception.Message)" "Error"
    }
} elseif ($foundPaths.Count -gt 0) {
    Write-Status "`n💡 To fix the configuration, you can:" "Warning"
    Write-Status "   1. Run this script with -Fix parameter to auto-update" "Info"
    Write-Status "   2. Or manually edit config.env and set:" "Info"
    Write-Status "      GIT_BASH_PATH=`"$($foundPaths[0])`"" "Info"
    
    if ($foundPaths.Count -gt 1) {
        Write-Status "`n   Alternative paths available:" "Info"
        for ($i = 1; $i -lt $foundPaths.Count; $i++) {
            Write-Status "      GIT_BASH_PATH=`"$($foundPaths[$i])`"" "Info"
        }
    }
}

Write-Status "`n🏁 Diagnostic complete" "Info" 