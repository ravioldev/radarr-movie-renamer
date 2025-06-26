# Test TMDB Integration for Spanish Movies
# This script tests the TMDB integration with a known Spanish movie

param(
    [string]$ConfigFile = "config.env",
    [int]$MovieId = 0,
    [string]$TestTitle = "El Laberinto del Fauno",
    [int]$TestYear = 2006
)

Write-Host "🧪 Testing TMDB Integration for Spanish Movies" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Load configuration
if (Test-Path $ConfigFile) {
    Write-Host "📋 Loading configuration from: $ConfigFile" -ForegroundColor Yellow
    
    # Read config file and set environment variables
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match '^([^#][^=]*?)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            # Handle variable expansion ${VARIABLE}
            while ($value -match '\$\{([^}]+)\}') {
                $varName = $matches[1]
                $varValue = [Environment]::GetEnvironmentVariable($varName, "Process")
                if (-not $varValue) {
                    $varValue = [Environment]::GetEnvironmentVariable($varName, "Machine")
                }
                if (-not $varValue) {
                    $varValue = [Environment]::GetEnvironmentVariable($varName, "User")
                }
                if (-not $varValue) {
                    Write-Warning "Variable $varName not found, leaving unexpanded"
                    break
                }
                $value = $value -replace "\$\{$varName\}", $varValue
            }
            
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "   $name = $value" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

# Validate required configuration
$radarrUrl = [Environment]::GetEnvironmentVariable("RADARR_URL", "Process")
$radarrApiKey = [Environment]::GetEnvironmentVariable("RADARR_API_KEY", "Process")
$tmdbApiKey = [Environment]::GetEnvironmentVariable("TMDB_API_KEY", "Process")
$nativeLanguage = [Environment]::GetEnvironmentVariable("NATIVE_LANGUAGE", "Process")

if (-not $radarrUrl -or -not $radarrApiKey) {
    Write-Error "RADARR_URL and RADARR_API_KEY must be configured"
    exit 1
}

Write-Host ""
Write-Host "🔧 Configuration:" -ForegroundColor Cyan
Write-Host "   RADARR_URL: $radarrUrl" -ForegroundColor White
Write-Host "   RADARR_API_KEY: $($radarrApiKey.Substring(0,8))..." -ForegroundColor White
Write-Host "   TMDB_API_KEY: $(if($tmdbApiKey) { $tmdbApiKey.Substring(0,8) + '...' } else { '(not configured)' })" -ForegroundColor White
Write-Host "   NATIVE_LANGUAGE: $nativeLanguage" -ForegroundColor White

# Find a Spanish movie to test with
Write-Host ""
Write-Host "🔍 Looking for Spanish movies in Radarr..." -ForegroundColor Yellow

try {
    $headers = @{
        'X-Api-Key' = $radarrApiKey
        'Accept' = 'application/json'
    }
    
    $movies = Invoke-RestMethod -Uri "$radarrUrl/api/v3/movie" -Headers $headers -TimeoutSec 30
    
    # Find Spanish movies (originalLanguage = "es")
    $spanishMovies = $movies | Where-Object { $_.originalLanguage -eq "es" } | Select-Object -First 5
    
    if ($spanishMovies.Count -eq 0) {
        Write-Warning "No Spanish movies found in Radarr. Using manual test parameters."
        $testMovie = @{
            id = $MovieId
            title = $TestTitle
            year = $TestYear
            originalLanguage = "es"
        }
    } else {
        Write-Host "✅ Found $($spanishMovies.Count) Spanish movies:" -ForegroundColor Green
        $spanishMovies | ForEach-Object {
            Write-Host "   • ID: $($_.id) - $($_.title) ($($_.year)) - TMDB: $($_.tmdbId)" -ForegroundColor White
        }
        
        # Use the first Spanish movie found
        $testMovie = $spanishMovies[0]
    }
    
    Write-Host ""
    Write-Host "🎬 Testing with movie:" -ForegroundColor Cyan
    Write-Host "   ID: $($testMovie.id)" -ForegroundColor White
    Write-Host "   Title: $($testMovie.title)" -ForegroundColor White
    Write-Host "   Year: $($testMovie.year)" -ForegroundColor White
    Write-Host "   Original Language: $($testMovie.originalLanguage)" -ForegroundColor White
    Write-Host "   TMDB ID: $($testMovie.tmdbId)" -ForegroundColor White
    
    # Test the rename script
    Write-Host ""
    Write-Host "🚀 Testing rename script..." -ForegroundColor Green
    
    $env:radarr_movie_id = $testMovie.id
    $env:radarr_movie_title = $testMovie.title
    $env:radarr_movie_year = $testMovie.year
    $env:radarr_moviefile_quality = "Bluray-1080p"
    
    # Execute the batch script which will call the bash script
    $batchScript = "rename-radarr-folders.bat"
    if (Test-Path $batchScript) {
        Write-Host "   Executing: $batchScript" -ForegroundColor Yellow
        Write-Host "   Arguments: radarr_movie_id=$($testMovie.id) radarr_movie_title='$($testMovie.title)' radarr_movie_year=$($testMovie.year) radarr_moviefile_quality=Bluray-1080p" -ForegroundColor DarkGray
        
        $result = & cmd /c "$batchScript" $testMovie.id "`"$($testMovie.title)`"" $testMovie.year "Bluray-1080p" 2>&1
        $exitCode = $LASTEXITCODE
        
        Write-Host ""
        Write-Host "📋 Script Output:" -ForegroundColor Yellow
        $result | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
        
        Write-Host ""
        if ($exitCode -eq 0) {
            Write-Host "✅ Test completed successfully (Exit Code: $exitCode)" -ForegroundColor Green
        } else {
            Write-Host "❌ Test failed (Exit Code: $exitCode)" -ForegroundColor Red
        }
    } else {
        Write-Error "Batch script not found: $batchScript"
    }
    
} catch {
    Write-Error "Failed to connect to Radarr: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "🧪 TMDB Integration Test Complete" -ForegroundColor Green 