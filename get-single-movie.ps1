# Get specific movie info by ID
param(
    [Parameter(Mandatory=$true)]
    [int]$MovieId,
    [string]$ConfigFile = "config.env"
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
                return $expandedValue ?? "`${$varName}"
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
    Write-Error "❌ Please configure RADARR_URL and RADARR_API_KEY in $ConfigFile first"
    exit 1
}

Write-Host "🔍 Getting movie info for ID: $MovieId" -ForegroundColor Cyan
Write-Host "   🔗 Radarr URL: $radarr" -ForegroundColor Gray

try {
    # Get specific movie from Radarr
    $movie = Invoke-RestMethod -Headers @{ 'X-Api-Key' = $apiKey } -Uri "$radarr/api/v3/movie/$MovieId"
    
    $quality = if ($movie.hasFile) { $movie.movieFile.quality.quality.name } else { "No file" }
    $collection = if ($movie.collection) { $movie.collection.title } else { "None" }
    
    Write-Host "`n📋 MOVIE INFORMATION:" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Gray
    
    Write-Host "`n🎬 Movie: $($movie.title) ($($movie.year))" -ForegroundColor White
    Write-Host "   🆔 ID: $($movie.id)" -ForegroundColor Gray
    Write-Host "   📁 Current path: $($movie.path)" -ForegroundColor Gray
    Write-Host "   🏷️  Quality: $quality" -ForegroundColor Gray
    Write-Host "   📚 Collection: $collection" -ForegroundColor Gray
    Write-Host "   🎭 Has file: $($movie.hasFile)" -ForegroundColor Gray
    Write-Host "   🌐 Original language: $($movie.originalLanguage)" -ForegroundColor Gray
    
    if ($movie.hasFile) {
        Write-Host "   📄 File path: $($movie.movieFile.path)" -ForegroundColor Gray
        Write-Host "   📏 Resolution: $($movie.movieFile.mediaInfo.video.resolution)" -ForegroundColor Gray
    }
    
    Write-Host "`n🧪 READY TO TEST:" -ForegroundColor Yellow
    Write-Host ("=" * 80) -ForegroundColor Gray
    
    # Generate the exact command
    $testCommand = ".\rename-radarr-folders.bat radarr_movie_id=$($movie.id) radarr_movie_title=`"$($movie.title)`" radarr_movie_year=$($movie.year) radarr_moviefile_quality=`"$quality`""
    
    Write-Host "`n📋 COPY THIS COMMAND:" -ForegroundColor Magenta
    Write-Host $testCommand -ForegroundColor White
    
    Write-Host "`n⚠️  IMPORTANT REMINDERS:" -ForegroundColor Red
    Write-Host "   1. 🛡️  BACKUP your Radarr database first!" -ForegroundColor Yellow
    Write-Host "   2. 📂 This will make REAL changes to folders" -ForegroundColor Yellow
    Write-Host "   3. 🔍 Check the current path above to see what will be affected" -ForegroundColor Yellow
    
    Write-Host "`n🎯 EXPECTED RESULT:" -ForegroundColor Green
    
    # Show expected new folder name (simplified logic)
    $newName = "$($movie.title) ($($movie.year))"
    if ($collection -and [System.Environment]::GetEnvironmentVariable("USE_COLLECTIONS") -eq "true") {
        $newName = "$collection ($($movie.year)) - $($movie.title)"
    }
    if ([System.Environment]::GetEnvironmentVariable("INCLUDE_QUALITY_TAG") -eq "true" -and $quality -and $quality -ne "No file") {
        # Simplified quality detection
        $qualityTag = switch -Regex ($quality) {
            "2160|4k" { "2160p"; break }
            "1080" { "1080p"; break }
            "720" { "720p"; break }
            "dvd|576" { "DVD-Rip"; break }
            "480" { "480p"; break }
            default { "LowQuality" }
        }
        $newName += " [$qualityTag]"
    }
    
    Write-Host "   📁 New folder name: $newName" -ForegroundColor Cyan
    
} catch {
    Write-Error "❌ Failed to get movie info: $($_.Exception.Message)"
    Write-Host "🔧 Check your RADARR_URL and RADARR_API_KEY in $ConfigFile" -ForegroundColor Yellow
    Write-Host "🔧 Also verify that movie ID $MovieId exists in your Radarr" -ForegroundColor Yellow
} 