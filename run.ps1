# run.ps1 - Main launcher for rename scripts with configuration support
# Reads config.env and executes the rename process for all movies

param(
    [string]$ConfigFile = "config.env"
)

# Function to import environment variables from .env file
function Import-EnvFile {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        Write-Error "Configuration file not found: $Path"
        exit 1
    }
    
    Write-Host "Loading configuration from: $Path" -ForegroundColor Green
    
    Get-Content $Path | ForEach-Object {
        # Skip empty lines and comments
        if ($_ -match '^\s*$' -or $_ -match '^\s*#') { return }
        
        # Parse variable=value pairs
        if ($_ -match '^([^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            # Expand variables in value (e.g., ${SCRIPTS_DIR})
            # First, try to get from already loaded process environment variables
            $value = $value -replace '\$\{([^}]+)\}', { 
                $varName = $_.Groups[1].Value
                $expandedValue = [System.Environment]::GetEnvironmentVariable($varName, "Process")
                if (-not $expandedValue) {
                    # Fallback to system environment variables
                    $expandedValue = [System.Environment]::GetEnvironmentVariable($varName)
                }
                if (-not $expandedValue) {
                    Write-Warning "Variable ${$varName} not found during expansion"
                    return "`${$varName}"  # Return original if not found
                }
                return $expandedValue
            }
            
            # Set environment variable
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "  $name = $value" -ForegroundColor Gray
        }
    }
}

# Load configuration
Import-EnvFile -Path $ConfigFile

# Get configuration values
$radarr = [System.Environment]::GetEnvironmentVariable("RADARR_URL")
$apiKey = [System.Environment]::GetEnvironmentVariable("RADARR_API_KEY")
$renameBatPath = [System.Environment]::GetEnvironmentVariable("RENAME_BAT_PATH")
$logFile = [System.Environment]::GetEnvironmentVariable("LOG_FILE")
$scriptsDir = [System.Environment]::GetEnvironmentVariable("SCRIPTS_DIR")

# Validate required configuration
if (!$radarr -or !$apiKey) {
    Write-Error "Missing required configuration: RADARR_URL or RADARR_API_KEY"
    exit 1
}

if (!$renameBatPath -or !(Test-Path $renameBatPath)) {
    Write-Error "Batch script not found: $renameBatPath"
    Write-Host "ℹ️  Check RENAME_BAT_PATH in config.env" -ForegroundColor Yellow
    exit 2
}

# Create log directory if specified and doesn't exist
if ($logFile) {
    $logDir = Split-Path $logFile -Parent
    if ($logDir -and !(Test-Path $logDir)) {
        try {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            Write-Host "📁 Created log directory: $logDir" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not create log directory: $logDir"
        }
    }
}

Write-Host "`n🎬 Starting batch rename process..." -ForegroundColor Cyan
Write-Host "   Radarr URL: $radarr" -ForegroundColor Gray
Write-Host "   Using script: $renameBatPath" -ForegroundColor Gray
if ($logFile) {
    Write-Host "   Log file: $logFile" -ForegroundColor Gray
}
if ($scriptsDir) {
    Write-Host "   Scripts directory: $scriptsDir" -ForegroundColor Gray
}

try {
    # Get all movies from Radarr
    $movies = Invoke-RestMethod -Headers @{ 'X-Api-Key' = $apiKey } -Uri "$radarr/api/v3/movie"
    
    Write-Host "`n📊 Found $($movies.Count) movies to process" -ForegroundColor Yellow
    
    $i = 0
    foreach ($m in $movies) {
        $i++
        $qual = $m.movieFile.quality.quality.name
        Write-Host "[$i/$($movies.Count)]  →  $($m.title)" -ForegroundColor White
        
        # Execute rename script with movie parameters
        & $renameBatPath `
          ("radarr_movie_id=$($m.id)") `
          ("radarr_movie_title=$($m.title)") `
          ("radarr_movie_year=$($m.year)") `
          ("radarr_moviefile_quality=$qual")
        
        if ($LASTEXITCODE -ne 0) {
            $errorMsg = "Script failed for movie: $($m.title) (Exit code: $LASTEXITCODE)"
            Write-Warning $errorMsg
            
            # Log detailed error information if log file is configured
            if ($logFile -and (Test-Path $logFile)) {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Add-Content -Path $logFile -Value "[$timestamp] PowerShell: $errorMsg"
            }
            
            # Show common exit codes meaning
            switch ($LASTEXITCODE) {
                1 { Write-Host "   → Git Bash not found" -ForegroundColor Red }
                2 { Write-Host "   → Script file not found" -ForegroundColor Red }
                3 { Write-Host "   → jq not installed" -ForegroundColor Red }
                4 { Write-Host "   → curl not installed" -ForegroundColor Red }
                5 { Write-Host "   → RADARR_API_KEY not configured" -ForegroundColor Red }
                90 { Write-Host "   → Failed to connect to Radarr API" -ForegroundColor Red }
                92 { Write-Host "   → Failed to update Radarr database" -ForegroundColor Red }
                95 { Write-Host "   → File not found in destination" -ForegroundColor Red }
                96 { Write-Host "   → Source directory not found" -ForegroundColor Red }
                97 { Write-Host "   → Failed to create destination directory" -ForegroundColor Red }
                default { Write-Host "   → Unknown error (check log for details)" -ForegroundColor Red }
            }
        }
    }
    
    Write-Host "`n✅ Batch rename process completed!" -ForegroundColor Green
    
    # Log completion if log file is configured
    if ($logFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFile -Value "[$timestamp] PowerShell: Batch process completed successfully - $($movies.Count) movies processed"
    }
}
catch {
    $errorMsg = "Failed to connect to Radarr or process movies: $($_.Exception.Message)"
    Write-Error $errorMsg
    
    # Log error if log file is configured
    if ($logFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFile -Value "[$timestamp] PowerShell ERROR: $errorMsg"
    }
    
    exit 1
} 