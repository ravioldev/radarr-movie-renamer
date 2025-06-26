# run.ps1 - Main launcher for rename scripts
param(
    [string]$ConfigFile = "config.env",
    [int]$MaxMovies = 0,
    [int]$Skip = 0
)

# Simple config loading - read key=value pairs
Write-Host "Loading configuration from: $ConfigFile" -ForegroundColor Green
if (Test-Path $ConfigFile) {
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$' -and $_ -notmatch '^\s*#') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "  $name = $value" -ForegroundColor Gray
        }
    }
}

# Get configuration values
$radarr = [System.Environment]::GetEnvironmentVariable("RADARR_URL")
$apiKey = [System.Environment]::GetEnvironmentVariable("RADARR_API_KEY")
$renameBatPath = [System.Environment]::GetEnvironmentVariable("RENAME_BAT_PATH")
$logFile = [System.Environment]::GetEnvironmentVariable("LOG_FILE")

# Validate required configuration
if (!$radarr -or !$apiKey) {
    Write-Error "Missing required configuration: RADARR_URL or RADARR_API_KEY"
    exit 1
}

if (!$renameBatPath -or !(Test-Path $renameBatPath)) {
    Write-Error "Batch script not found: $renameBatPath"
    exit 2
}

Write-Host "`n🎬 Starting batch rename process..." -ForegroundColor Cyan
if ($MaxMovies -gt 0) {
    Write-Host "   🧪 Test mode: Processing max $MaxMovies movies" -ForegroundColor Yellow
}
if ($Skip -gt 0) {
    Write-Host "   ⏭️  Skip mode: Skipping first $Skip movies" -ForegroundColor Yellow
}

try {
    # Get all movies from Radarr
    $allMovies = Invoke-RestMethod -Headers @{ 'X-Api-Key' = $apiKey } -Uri "$radarr/api/v3/movie"
    
    # Apply Skip parameter
    if ($Skip -gt 0) {
        if ($Skip -ge $allMovies.Count) {
            Write-Host "⚠️  Skip value too high. Nothing to process." -ForegroundColor Yellow
            exit 0
        }
        $allMovies = $allMovies | Select-Object -Skip $Skip
    }
    
    # Apply MaxMovies limit
    if ($MaxMovies -gt 0 -and $allMovies.Count -gt $MaxMovies) {
        $movies = $allMovies | Select-Object -First $MaxMovies
    } else {
        $movies = $allMovies
    }
    
    Write-Host "📊 Processing $($movies.Count) movies" -ForegroundColor Yellow
    
    $successCount = 0
    $errorCount = 0
    $i = 0
    
    foreach ($m in $movies) {
        $i++
        $qual = if ($m.movieFile -and $m.movieFile.quality) { 
            $m.movieFile.quality.quality.name 
        } else { 
            "Unknown" 
        }
        
        $actualPosition = $Skip + $i
        Write-Host "[$actualPosition] [$i/$($movies.Count)] Processing: $($m.title) ($($m.year)) [$qual]" -ForegroundColor White
        
        # Prepare arguments in var=val format
        $movieTitle = $m.title -replace "'", "\''"
        $arguments = @(
            "radarr_movie_id=$($m.id)",
            "radarr_movie_title=`"$movieTitle`"",
            "radarr_movie_year=$($m.year)",
            "radarr_moviefile_quality=`"$qual`""
        )
        
        try {
            $process = Start-Process -FilePath $renameBatPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Write-Host "   ✅ Success" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "   ❌ Failed (Exit code: $($process.ExitCode))" -ForegroundColor Red
                $errorCount++
            }
        }
        catch {
            Write-Host "   ❌ Exception: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
        
        Start-Sleep -Milliseconds 100
    }
    
    Write-Host "`n📈 Batch rename completed!" -ForegroundColor Green
    Write-Host "   ✅ Success: $successCount movies" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "   ❌ Errors: $errorCount movies" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Error "Failed to connect to Radarr: $($_.Exception.Message)"
    exit 1
} 