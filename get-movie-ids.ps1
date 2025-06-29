# Script to get movie IDs from Radarr for testing
param(
    [string]$ConfigFile = "config.env",
    [string]$SearchTitle = "",
    [int]$MaxResults = 10
)

# Import config function
function Import-EnvFile {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        Write-Error "Configuration file not found: $Path"
        exit 1
    }
    
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*$' -or $_ -match '^\s*#') { return }
        
        if ($_ -match '^([^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            # Expand variables
            $value = $value -replace '\$\{([^}]+)\}', { 
                $varName = $_.Groups[1].Value
                $expandedValue = [System.Environment]::GetEnvironmentVariable($varName, "Process")
                if (-not $expandedValue) {
                    $expandedValue = [System.Environment]::GetEnvironmentVariable($varName)
                }
                if (-not $expandedValue) {
                    return "`${$varName}"
                }
                return $expandedValue
            }
            
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

# Load configuration
Import-EnvFile -Path $ConfigFile

$radarr = [System.Environment]::GetEnvironmentVariable("RADARR_URL")
$apiKey = [System.Environment]::GetEnvironmentVariable("RADARR_API_KEY")

if (!$radarr -or !$apiKey -or $apiKey -eq "your_radarr_api_key_here") {
    Write-Error "Please configure RADARR_URL and RADARR_API_KEY in $ConfigFile first"
    exit 1
}

Write-Host "Getting movie IDs from Radarr..." -ForegroundColor Cyan
Write-Host "Radarr URL: $radarr" -ForegroundColor Gray

try {
    # Get movies from Radarr
    $movies = Invoke-RestMethod -Headers @{ 'X-Api-Key' = $apiKey } -Uri "$radarr/api/v3/movie"
    
    # Filter by search title if provided
    if ($SearchTitle) {
        $movies = $movies | Where-Object { $_.title -like "*$SearchTitle*" }
        Write-Host "Filtering by title containing: '$SearchTitle'" -ForegroundColor Yellow
    }
    
    # Limit results
    $movies = $movies | Select-Object -First $MaxResults | Sort-Object title
    
    Write-Host "" 
    Write-Host "Movie IDs (showing first $MaxResults):" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Gray
    
    foreach ($movie in $movies) {
        $quality = if ($movie.hasFile) { $movie.movieFile.quality.quality.name } else { "No file" }
        $collection = if ($movie.collection) { $movie.collection.title } else { "None" }
        
        Write-Host ""
        Write-Host "ID: $($movie.id) | $($movie.title) ($($movie.year))" -ForegroundColor White
        Write-Host "  Path: $($movie.path)" -ForegroundColor Gray
        Write-Host "  Quality: $quality" -ForegroundColor Gray
        Write-Host "  Collection: $collection" -ForegroundColor Gray
        Write-Host "  Has file: $($movie.hasFile)" -ForegroundColor Gray
        
        # Show the exact command to test this movie
        Write-Host "  TEST COMMAND:" -ForegroundColor Yellow
        $testCmd = ".\rename-radarr-folders.bat radarr_movie_id=$($movie.id) `"radarr_movie_title=$($movie.title)`" radarr_movie_year=$($movie.year) `"radarr_moviefile_quality=$quality`""
        Write-Host "    $testCmd" -ForegroundColor Magenta
    }
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Gray
    Write-Host "Found $($movies.Count) movies" -ForegroundColor Green
    Write-Host "Copy any TEST COMMAND above to test individual movies" -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to connect to Radarr: $($_.Exception.Message)"
    Write-Host "Check your RADARR_URL and RADARR_API_KEY in $ConfigFile" -ForegroundColor Yellow
} 