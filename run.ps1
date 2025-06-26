# run.ps1 - Main launcher for rename scripts with configuration support
# Reads config.env and executes the rename process for all movies

param(
    [string]$ConfigFile = "config.env",
    [int]$MaxMovies = 0,  # 0 = process all movies, any positive number = limit to that many movies
    [int]$Skip = 0        # Number of movies to skip from the beginning (useful for resuming interrupted processes)
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
            $value = $value -replace '\$\{([^}]+)\}', { 
                $varName = $_.Groups[1].Value
                $expandedValue = [System.Environment]::GetEnvironmentVariable($varName, "Process")
                if (-not $expandedValue) {
                    $expandedValue = [System.Environment]::GetEnvironmentVariable($varName)
                }
                if (-not $expandedValue) {
                    Write-Warning "Variable ${$varName} not found during expansion"
                    return "`${$varName}"
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
if ($MaxMovies -gt 0) {
    Write-Host "   🧪 Test mode: Processing max $MaxMovies movies" -ForegroundColor Yellow
}
if ($Skip -gt 0) {
    Write-Host "   ⏭️  Skip mode: Skipping first $Skip movies" -ForegroundColor Yellow
}

try {
    # Get all movies from Radarr
    $allMovies = Invoke-RestMethod -Headers @{ 'X-Api-Key' = $apiKey } -Uri "$radarr/api/v3/movie"
    
    # Apply Skip parameter first (skip the first X movies)
    if ($Skip -gt 0) {
        if ($Skip -ge $allMovies.Count) {
            Write-Host "`n⚠️  Skip value ($Skip) is greater than or equal to total movies ($($allMovies.Count)). Nothing to process." -ForegroundColor Yellow
            exit 0
        }
        $allMovies = $allMovies | Select-Object -Skip $Skip
        Write-Host "`n📊 Skipped first $Skip movies, $($allMovies.Count) remaining" -ForegroundColor Yellow
    }
    
    # Apply MaxMovies limit if specified
    if ($MaxMovies -gt 0 -and $allMovies.Count -gt $MaxMovies) {
        $movies = $allMovies | Select-Object -First $MaxMovies
        $statusMsg = if ($Skip -gt 0) {
            "Found $($allMovies.Count + $Skip) movies total, skipped $Skip, processing next $($movies.Count) (MaxMovies=$MaxMovies)"
        } else {
            "Found $($allMovies.Count) movies total, processing first $($movies.Count) (MaxMovies=$MaxMovies)"
        }
        Write-Host "`n📊 $statusMsg" -ForegroundColor Yellow
    } else {
        $movies = $allMovies
        $statusMsg = if ($Skip -gt 0) {
            "Found $($allMovies.Count + $Skip) movies total, skipped $Skip, processing remaining $($movies.Count)"
        } else {
            "Found $($movies.Count) movies to process"
        }
        Write-Host "`n📊 $statusMsg" -ForegroundColor Yellow
    }
    
    $successCount = 0
    $errorCount = 0
    $i = 0
    
    foreach ($m in $movies) {
        $i++
        $qual = if ($m.movieFile -and $m.movieFile.quality -and $m.movieFile.quality.quality) { 
            $m.movieFile.quality.quality.name 
        } else { 
            "Unknown" 
        }
        
        # Adjust counter display to show actual position (including skipped movies)
        $actualPosition = $Skip + $i
        $totalToProcess = $movies.Count
        Write-Host "[$actualPosition] [$i/$totalToProcess] Processing: $($m.title) ($($m.year)) [$qual]" -ForegroundColor White
        
        # Prepare arguments for the batch script in var=val format
        $movieTitle = $m.title -replace "'", "\''"
        $arguments = @(
            "radarr_movie_id=$($m.id)",
            "radarr_movie_title=`"$movieTitle`"",
            "radarr_movie_year=$($m.year)",
            "radarr_moviefile_quality=`"$qual`""
        )
        
        try {
            $process = Start-Process -FilePath $renameBatPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
            $exitCode = $process.ExitCode
            
            if ($exitCode -eq 0) {
                Write-Host "   ✅ Success" -ForegroundColor Green
                $successCount++
            } else {
                $errorMsg = "Script failed for movie: $($m.title) (Exit code: $exitCode)"
                Write-Host "   ❌ Failed (Exit code: $exitCode)" -ForegroundColor Red
                $errorCount++
                
                if ($logFile -and (Test-Path $logFile)) {
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Add-Content -Path $logFile -Value "[$timestamp] PowerShell: $errorMsg"
                }
                
                switch ($exitCode) {
                    1 { Write-Host "      → Git Bash not found" -ForegroundColor Red }
                    2 { Write-Host "      → Script file not found" -ForegroundColor Red }
                    3 { Write-Host "      → jq not installed" -ForegroundColor Red }
                    4 { Write-Host "      → curl not installed" -ForegroundColor Red }
                    5 { Write-Host "      → RADARR_API_KEY not configured" -ForegroundColor Red }
                    90 { Write-Host "      → Failed to connect to Radarr API" -ForegroundColor Red }
                    92 { Write-Host "      → Failed to update Radarr database" -ForegroundColor Red }
                    95 { Write-Host "      → File not found in destination" -ForegroundColor Red }
                    96 { Write-Host "      → Source directory not found" -ForegroundColor Red }
                    97 { Write-Host "      → Failed to create destination directory" -ForegroundColor Red }
                    default { Write-Host "      → Unknown error (check log for details)" -ForegroundColor Red }
                }
            }
        }
        catch {
            Write-Host "   ❌ Exception: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
        
        Start-Sleep -Milliseconds 100
    }
    
    Write-Host "`n📈 Batch rename process completed!" -ForegroundColor Green
    Write-Host "   ✅ Success: $successCount movies" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "   ❌ Errors: $errorCount movies" -ForegroundColor Red
    }
    
    if ($logFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $completionMsg = if ($Skip -gt 0) {
            "Batch process completed - $successCount success, $errorCount errors out of $($movies.Count) movies processed (skipped first $Skip movies)"
        } else {
            "Batch process completed - $successCount success, $errorCount errors out of $($movies.Count) movies processed"
        }
        Add-Content -Path $logFile -Value "[$timestamp] PowerShell: $completionMsg"
    }
    
    if ($errorCount -gt 0) {
        exit 1
    }
}
catch {
    $errorMsg = "Failed to connect to Radarr or process movies: $($_.Exception.Message)"
    Write-Error $errorMsg
    
    if ($logFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFile -Value "[$timestamp] PowerShell ERROR: $errorMsg"
    }
    
    exit 1
}

# Updated: Fixed PowerShell syntax and added Skip parameter (v1.1)