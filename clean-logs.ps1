#!/usr/bin/env pwsh
# Log Cleanup Script
# Cleans up oversized logs and creates compressed backups

param(
    [switch]$DryRun,      # Show what would be done without doing it
    [switch]$Compress,    # Compress old logs instead of deleting them
    [int]$KeepDays = 7,   # Keep logs from last N days
    [int64]$MaxSizeMB = 50 # Maximum log file size in MB before cleanup
)

function Format-FileSize {
    param($SizeInBytes)
    
    if ($SizeInBytes -gt 1GB) {
        return "{0:N2} GB" -f ($SizeInBytes / 1GB)
    } elseif ($SizeInBytes -gt 1MB) {
        return "{0:N2} MB" -f ($SizeInBytes / 1MB)
    } elseif ($SizeInBytes -gt 1KB) {
        return "{0:N2} KB" -f ($SizeInBytes / 1KB)
    } else {
        return "$SizeInBytes bytes"
    }
}

function Write-Status {
    param($Message, $Type = "Info")
    
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

Write-Status "`n🧹 Log Cleanup Utility`n" "Info"

# Load configuration to find log file location
$configFile = Join-Path $PSScriptRoot "config.env"
$logFile = ""

if (Test-Path $configFile) {
    Get-Content $configFile | ForEach-Object {
        if ($_ -match '^LOG_FILE=(.+)$') {
            $logFile = $matches[1] -replace '"', ''
            # Expand variables like ${SCRIPTS_DIR}
            if ($logFile -match '\$\{SCRIPTS_DIR\}') {
                Get-Content $configFile | ForEach-Object {
                    if ($_ -match '^SCRIPTS_DIR=(.+)$') {
                        $scriptsDir = $matches[1] -replace '"', ''
                        $logFile = $logFile -replace '\$\{SCRIPTS_DIR\}', $scriptsDir
                    }
                }
            }
        }
    }
}

if (-not $logFile) {
    Write-Status "❌ Could not determine log file location from config.env" "Error"
    return
}

Write-Status "📋 Target log file: $logFile" "Info"

# Check if log file exists
if (-not (Test-Path $logFile)) {
    Write-Status "✅ Log file doesn't exist - nothing to clean" "Success"
    return
}

# Get log file info
$logFileInfo = Get-Item $logFile
$logSizeMB = [math]::Round($logFileInfo.Length / 1MB, 2)
$logLines = (Get-Content $logFile | Measure-Object -Line).Lines

Write-Status "📊 Current log statistics:" "Info"
Write-Status "   Size: $(Format-FileSize $logFileInfo.Length) ($logSizeMB MB)" "Info"
Write-Status "   Lines: $('{0:N0}' -f $logLines)" "Info"
Write-Status "   Last modified: $($logFileInfo.LastWriteTime)" "Info"

# Check if cleanup is needed
if ($logFileInfo.Length -lt ($MaxSizeMB * 1MB)) {
    Write-Status "✅ Log file size is acceptable (under $MaxSizeMB MB)" "Success"
    return
}

Write-Status "`n⚠️  Log file exceeds maximum size ($MaxSizeMB MB)" "Warning"

if ($DryRun) {
    Write-Status "🧪 DRY RUN MODE - No actual changes will be made" "Warning"
}

# Create backup/compressed version if requested
if ($Compress) {
    $backupPath = $logFile -replace '\.log$', "_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    Write-Status "`n📦 Creating compressed backup..." "Info"
    
    if ($DryRun) {
        Write-Status "   Would create: $backupPath" "Info"
    } else {
        try {
            # Create a summary of the old log
            $summary = @(
                "=== LOG CLEANUP SUMMARY ($(Get-Date)) ===",
                "Original file: $logFile",
                "Original size: $(Format-FileSize $logFileInfo.Length)",
                "Original lines: $('{0:N0}' -f $logLines)",
                "Cleanup reason: File exceeded $MaxSizeMB MB limit",
                "",
                "=== ERRORS AND WARNINGS FROM ORIGINAL LOG ===",
                ""
            )
            
            # Extract important lines (errors, warnings, final results)
            Write-Status "   📋 Extracting important entries..." "Info"
            $importantLines = Get-Content $logFile | Where-Object {
                $_ -match '❌|⚠️|ERROR|WARNING|FAILED|Failed|✅.*processed|Finished rename-radarr-folders'
            }
            
            $summary += $importantLines
            $summary += @("", "=== END OF SUMMARY ===")
            
            Set-Content -Path $backupPath -Value $summary -Encoding UTF8
            
            Write-Status "   ✅ Backup created: $backupPath" "Success"
            Write-Status "   📋 Backup size: $(Format-FileSize (Get-Item $backupPath).Length)" "Info"
            
        } catch {
            Write-Status "   ❌ Failed to create backup: $($_.Exception.Message)" "Error"
            return
        }
    }
}

# Clean up the main log file
Write-Status "`n🗑️  Cleaning up main log file..." "Info"

if ($DryRun) {
    Write-Status "   Would truncate: $logFile" "Info"
} else {
    try {
        # Keep recent entries (last few hours)
        $cutoffTime = (Get-Date).AddHours(-6)
        $recentLines = @()
        
        Write-Status "   📋 Preserving recent entries (last 6 hours)..." "Info"
        
        Get-Content $logFile | ForEach-Object {
            # Try to parse timestamp from log line
            if ($_ -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]' -or 
                $_ -match '^\[(.{3} \d{2}/\d{2}/\d{4}\s+\d{1,2}:\d{2}:\d{2})') {
                try {
                    $timestamp = [DateTime]::Parse($matches[1])
                    if ($timestamp -gt $cutoffTime) {
                        $recentLines += $_
                    }
                } catch {
                    # If timestamp parsing fails, keep the line anyway
                    $recentLines += $_
                }
            } elseif ($recentLines.Count -gt 0) {
                # If we've started collecting recent lines, keep subsequent lines too
                $recentLines += $_
            }
        }
        
        # Write cleaned log
        $header = @(
            "=== LOG CLEANED ON $(Get-Date) ===",
            "Previous log size: $(Format-FileSize $logFileInfo.Length)",
            "New logging configuration applied for reduced verbosity",
            "Set LOG_LEVEL=MINIMAL in config.env for production use",
            "",
            "=== RECENT ENTRIES (LAST 6 HOURS) ===",
            ""
        )
        
        $newContent = $header + $recentLines
        Set-Content -Path $logFile -Value $newContent -Encoding UTF8
        
        $newSize = (Get-Item $logFile).Length
        $spaceSaved = $logFileInfo.Length - $newSize
        
        Write-Status "   ✅ Log file cleaned successfully!" "Success"
        Write-Status "   📊 New size: $(Format-FileSize $newSize)" "Success"
        Write-Status "   💾 Space saved: $(Format-FileSize $spaceSaved)" "Success"
        
    } catch {
        Write-Status "   ❌ Failed to clean log file: $($_.Exception.Message)" "Error"
        return
    }
}

# Show configuration recommendations
Write-Status "`n💡 To prevent future log bloat:" "Warning"
Write-Status "   1. Set LOG_LEVEL=MINIMAL in config.env for production" "Info"
Write-Status "   2. Set LOG_CUSTOM_FORMATS=false to reduce Custom Format noise" "Info"
Write-Status "   3. Set LOG_QUALITY_DEBUG=false to reduce quality detection verbosity" "Info"
Write-Status "   4. Set LOG_LANGUAGE_DEBUG=false to reduce language detection verbosity" "Info"
Write-Status "`n   Current configuration in config.env:" "Info"

try {
    $currentSettings = @{}
    Get-Content $configFile | ForEach-Object {
        if ($_ -match '^(LOG_LEVEL|LOG_CUSTOM_FORMATS|LOG_QUALITY_DEBUG|LOG_LANGUAGE_DEBUG)=(.+)$') {
            $currentSettings[$matches[1]] = $matches[2]
        }
    }
    
    foreach ($setting in $currentSettings.Keys | Sort-Object) {
        $value = $currentSettings[$setting]
        $color = if ($setting -eq "LOG_LEVEL" -and $value -eq "MINIMAL") { "Green" } 
                elseif ($setting -ne "LOG_LEVEL" -and $value -eq "false") { "Green" }
                else { "Yellow" }
        Write-Host "     $setting=$value" -ForegroundColor $color
    }
} catch {
    Write-Status "   Could not read current configuration" "Warning"
}

Write-Status "`n🏁 Cleanup complete" "Info" 