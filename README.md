# Radarr Movie Renamer v2.0

Complete Radarr library organization solution that renames both folders AND files with intelligent quality detection and MediaInfo extraction.

## 📋 Latest Updates

**Version 2.0** is a major upgrade with file renaming support and enhanced quality processing. Your movie library will never look better!

**🆕 New in v2.0**: File renaming, smart SDTV handling, improved MediaInfo extraction, enhanced UTF-8 support, and robust error handling.

## 🚀 What's New in v2.0

### **Complete File Renaming**
Not just folders anymore! v2.0 now renames your actual movie files with proper naming conventions:
- **Before**: `Movie.Name.2024.1080p.WEB-DL.x264-GROUP.mkv`
- **After**: `Movie.Name.2024.1080p.h265.EAC3.Atmos.5.1-GROUP.mkv`

### **Smart Quality Processing**
Intelligent quality detection that works differently for folders vs files:
- **Folders**: Clean quality tags like `[1080p]`, `[720p]` - never shows `[SDTV]`
- **Files**: Detailed quality info like `720p-SCREENER`, `480p-SDTV`, `2160p-TELESYNC`

### **Enhanced MediaInfo Integration**
Automatically extracts and includes technical details in filenames:
- Video codec: `h265`, `x264`, `AV1`
- Audio codec: `EAC3`, `DTS`, `AAC`, `TrueHD`
- Audio channels: `5.1`, `7.1`, `Atmos`

### **Robust Error Handling**
v2.0 handles edge cases gracefully with improved UTF-8 support and better path handling for Windows systems.

## Why Use This Instead of Radarr's Built-in Renaming?

Radarr's standard renaming is limited and frustrating. Here's what you get with v2.0 that Radarr can't do:

### **Collections Support**
- **Radarr**: `Iron Man (2008)` and `Avengers Endgame (2019)` sit randomly in your library
- **This script**: `Marvel Cinematic Universe (2008) - Iron Man` and `Marvel Cinematic Universe (2019) - Avengers Endgame` 

Now all Marvel movies group together alphabetically. Same for DC, Star Wars, Harry Potter, etc.

### **Smart Language Handling**
- **Radarr**: Foreign movies keep English titles even when you prefer the original
- **This script**: Spanish movies show Spanish titles, English movies show English titles

Perfect if you're bilingual or prefer original titles for foreign films.

### **Quality Tags That Actually Work**
- **Radarr**: Quality formatting is inconsistent and ugly
- **This script**: Clean `[1080p]`, `[2160p]`, `[720p]` tags that work with every quality profile

### **Complete Library Organization**
- **Auto-rename**: Add as Radarr custom script - renames new downloads automatically (folders + files)
- **Bulk processing**: Process your entire library in one command (tested with 9000+ movies)
- **Dual renaming**: Both folder structure AND file names get properly organized

### **Cross-Platform Support**
- **Radarr**: Only basic renaming, OS-dependent limitations
- **This script**: Works on Windows, Linux, and macOS with proper dependencies

### **Flexible Configuration**
- **Radarr**: Fixed naming patterns, can't easily toggle features
- **This script**: Toggle collections on/off, quality tags on/off, configure languages independently

### **Smart Placeholder Handling**
- **Radarr**: If movie has no collection, you get ugly empty placeholders: `" - (2019) Movie Title []"`
- **This script**: Adapts the pattern automatically:
  - **With collection**: `Marvel Cinematic Universe (2008) - Iron Man [1080p]`
  - **No collection**: `Iron Man (2008) [1080p]` (clean, no empty dashes)

### **TMDB Integration**
- **Radarr**: Limited metadata sources
- **This script**: Pull native language titles directly from TMDB when needed

### **Better Folder Structure**
**Radarr's naming problem**: If you set a pattern like `{Movie Collection} - ({Release Year}) {Movie Title} [{Quality Title}]` but the movie has no collection, you get ugly empty placeholders:
```
 - (2008) The Dark Knight []    # Empty collection and quality placeholders
 - (2019) Joker []              # Looks broken and unprofessional
```

**This script adapts intelligently**:
```
Marvel Cinematic Universe (2008) - Iron Man [1080p]    # Has collection
The Dark Knight (2008) [1080p]                         # No collection, clean format
Joker (2019) [1080p]                                   # No empty dashes or brackets
```

Instead of random download names:
```
Iron.Man.2008.1080p.BluRay.x264-GROUP/
The.Dark.Knight.2008.IMAX.1080p.BluRay.x264-SECTOR7/
avengers_endgame_2019_4k_hdr_atmos/
```

## Quick Setup

1. **Back up your Radarr database** (seriously, do this first)
2. Edit `config.env` with your Radarr URL and API key
3. **Preview what would be changed**: `.\run.ps1 -MaxMovies 5 -DryRun`
4. **Test with a few movies**: `.\run.ps1 -MaxMovies 5`
5. **Fix specific issues**: `.\run.ps1 -FilterPath "[Unknown]"` or `.\run.ps1 -FilterNoQuality`
6. **Process everything**: `.\run.ps1`
7. **Resume after interruption**: `.\run.ps1 -Skip 100` (continues from movie #101)

### Quick Fixes (v1.1)
```powershell
# See movies that need fixing without making changes
.\run.ps1 -FilterPath "[Unknown]" -DryRun
.\run.ps1 -FilterNoQuality -DryRun

# Fix most common issues
.\run.ps1 -FilterPath "[Unknown]"        # Fix folders with [Unknown] 
.\run.ps1 -FilterNoQuality               # Fix movies without quality
.\run.ps1 -DaysBack 7                    # Fix recent additions only
```

> 💡 **More examples and detailed usage**: See [CHANGELOG.md](CHANGELOG.md) for comprehensive v1.1 feature documentation.

## Configuration

Copy and edit `config.env`:

```bash
# Your Radarr setup
RADARR_URL=http://127.0.0.1:7878
RADARR_API_KEY=your_api_key_here

# Language preferences (leave NATIVE_LANGUAGE empty for English-only)
NATIVE_LANGUAGE=es              # Spanish movies show Spanish titles
FALLBACK_LANGUAGE=en            # English movies show English titles

# Folder naming options - toggle what you want
USE_COLLECTIONS=true            # true: "Collection - Title", false: just "Title"
INCLUDE_QUALITY_TAG=true        # true: add [1080p], false: no quality tags

# File naming pattern (NEW in v2.0)
FILE_NAMING_PATTERN="{Movie.CleanTitle}.{Release.Year}.{Quality.Full}.{MediaInfo.VideoCodec}.{MediaInfo.AudioCodec}.{MediaInfo.AudioChannels}-{Release.Group}"

# Optional TMDB integration for better native language titles
TMDB_API_KEY=your_tmdb_key      # Leave empty to disable

# Paths (adjust for your OS)
# Windows:
SCRIPTS_DIR=C:\scripts\
GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe

# Linux/macOS:
# SCRIPTS_DIR=/home/user/scripts/
# GIT_BASH_PATH=/bin/bash
```

### Naming Pattern Examples

With these settings you get different results:

```bash
# USE_COLLECTIONS=true, INCLUDE_QUALITY_TAG=true
"Marvel Cinematic Universe (2008) - Iron Man [1080p]"
"The Dark Knight (2008) [1080p]"  # No collection = no empty placeholder

# USE_COLLECTIONS=false, INCLUDE_QUALITY_TAG=true  
"Iron Man (2008) [1080p]"
"The Dark Knight (2008) [1080p]"

# USE_COLLECTIONS=true, INCLUDE_QUALITY_TAG=false
"Marvel Cinematic Universe (2008) - Iron Man"
"The Dark Knight (2008)"

# USE_COLLECTIONS=false, INCLUDE_QUALITY_TAG=false
"Iron Man (2008)"
"The Dark Knight (2008)"
```

## Usage

### Bulk Processing (Process Entire Library)
```powershell
# Process all movies in your library
.\run.ps1

# Test with 10 movies first (recommended)
.\run.ps1 -MaxMovies 10

# Resume after interruption (skip first 100 movies)
.\run.ps1 -Skip 100

# Skip first 50, then process next 25 movies
.\run.ps1 -Skip 50 -MaxMovies 25
```

### Selective Processing (New in v1.1)
Target specific movies instead of processing everything:

```powershell
# See what movies would be processed (no changes made)
.\run.ps1 -FilterPath "[Unknown]" -DryRun

# Process only movies with "[Unknown]" in folder path
.\run.ps1 -FilterPath "[Unknown]"

# Process movies without quality defined (no files or Unknown quality)
.\run.ps1 -FilterNoQuality

# Process movies added in the last 7 days
.\run.ps1 -DaysBack 7

# Process movies with specific text in title
.\run.ps1 -SearchTitle "Marvel"

# Combine filters for precise targeting
.\run.ps1 -FilterPath "temp" -FilterNoQuality -DaysBack 30

# Process movies in download folders
.\run.ps1 -FilterPath "downloads" -MaxMovies 20 -DryRun
```

#### Filter Examples
```powershell
# Fix movies in temporary folders
.\run.ps1 -FilterPath "temp"
.\run.ps1 -FilterPath "tmp" 
.\run.ps1 -FilterPath "downloads"

# Fix movies with broken quality detection
.\run.ps1 -FilterPath "[Unknown]"
.\run.ps1 -FilterPath "Unknown"
.\run.ps1 -FilterNoQuality

# Process recent additions only
.\run.ps1 -DaysBack 3                    # Last 3 days
.\run.ps1 -DaysBack 7 -MaxMovies 50      # Last week, limit 50

# Target specific collections or patterns
.\run.ps1 -SearchTitle "Marvel" -DryRun
.\run.ps1 -FilterPath "2024"             # Movies with "2024" in path
.\run.ps1 -FilterPath "4K"               # 4K movies needing organization
```

### Available Filters

| Filter | Description | Example |
|--------|-------------|---------|
| `-FilterPath "text"` | Movies with specific text in folder path | `.\run.ps1 -FilterPath "[Unknown]"` |
| `-FilterNoQuality` | Movies without quality defined | `.\run.ps1 -FilterNoQuality` |
| `-DaysBack N` | Movies added/modified in last N days | `.\run.ps1 -DaysBack 7` |
| `-SearchTitle "text"` | Movies with text in title | `.\run.ps1 -SearchTitle "Marvel"` |
| `-DryRun` | Preview what would be processed | `.\run.ps1 -DryRun` |
| `-MaxMovies N` | Limit processing to N movies | `.\run.ps1 -MaxMovies 10` |
| `-Skip N` | Skip first N movies | `.\run.ps1 -Skip 100` |

### Auto-Rename (Radarr Custom Script)
```batch
# Radarr calls this automatically on import/upgrade
rename-radarr-folders.bat movieID "Movie Title" year "Quality"
```

Both methods use the same logic, just different triggers.

## How It Works

**Important**: v2.0 renames both **folders** AND **files** for complete library organization.

1. Reads your movie data from Radarr API
2. Checks if movie is in your native language
3. Gets the right title (original for native language, English for others)
4. Builds folder name: `Collection (Year) - Title [Quality]`
5. **Renames both the folder and files** for complete organization
6. Moves all files (unchanged) to the new folder
7. Updates Radarr database with new folder path
8. Triggers Radarr to refresh and apply **its own file naming rules**

**Example workflow**:
```
Before: Iron.Man.2008.1080p.BluRay.x264-GROUP/
        ├── Iron.Man.2008.1080p.BluRay.x264-GROUP.mkv
        └── Iron.Man.2008.1080p.BluRay.x264-GROUP.srt

After:  Marvel Cinematic Universe (2008) - Iron Man [1080p]/
        ├── Iron.Man.2008.1080p.BluRay.x264-GROUP.mkv  # Still original name
        └── Iron.Man.2008.1080p.BluRay.x264-GROUP.srt  # Still original name

Radarr:  Marvel Cinematic Universe (2008) - Iron Man [1080p]/
         ├── Iron Man (2008) [Bluray-1080p].mkv        # Renamed by Radarr
         └── Iron Man (2008) [Bluray-1080p].en.srt     # Renamed by Radarr
```

## Language Examples

With `NATIVE_LANGUAGE=es`:
- **Spanish movie**: "El Laberinto del Fauno" → `El Laberinto del Fauno (2006) [1080p]`
- **English movie**: "The Dark Knight" → `The Dark Knight (2008) [1080p]`
- **French movie**: "Amélie" → `Amélie (2001) [720p]` (uses original title)

## File Structure

```
├── config.env                  # Your configuration
├── run.ps1                    # Bulk processing script
├── rename-radarr-folders.bat  # Individual movie processing
├── rename-radarr-folders.sh   # Main logic (bash)
├── get-movie-ids.ps1          # List your movies for testing
├── CHANGELOG.md               # Version history and release notes
└── logs/                      # Detailed logs
```

## Radarr Integration (Auto-Rename)

Add this as a custom script in Radarr Settings > Connect:

- **On Import**: Automatically rename new downloads
- **On Upgrade**: Rename when quality improves  
- **On Rename**: Triggered when you rename through Radarr UI
- **Path**: Point to `rename-radarr-folders.bat`

This way new movies get organized automatically while you can bulk-process existing ones with `run.ps1`.

## Safety Features

- **Preview mode**: See what would be changed without making any modifications (`-DryRun`)
- **Selective processing**: Target specific movies instead of processing everything
- **Extensive logging**: Every operation is logged with timestamps
- **Error handling**: Won't break if a movie fails - continues with remaining movies  
- **Batch testing**: Test with small batches first (`-MaxMovies`)
- **Resume capability**: Continue from any point after interruption (`-Skip`)
- **Rollback friendly**: Radarr database backup lets you undo everything

## Troubleshooting

**"Git Bash not found"**: Install Git for Windows or update `GIT_BASH_PATH`

**"API key invalid"**: Get your API key from Radarr Settings > General

**"jq not found"**: Install with `winget install jqlang.jq` (Windows) or your package manager

**"Script not found at: \rename-radarr-folders.sh"**: This happens when `${SCRIPTS_DIR}` variable expansion fails in `config.env`. Make sure your `SCRIPTS_DIR` path ends with a backslash (`\`) on Windows or forward slash (`/`) on Linux/macOS, and doesn't contain spaces in the middle without proper quoting.

**"Script exited with code: 2" in Radarr**: Usually means the batch script can't find the shell script. Check that all paths in `config.env` are correct and that Git Bash is properly installed.

**Movies not updating**: Check the log file for detailed error messages

## Requirements

### Windows
- Git Bash (comes with Git for Windows)
- PowerShell 5.1+ (usually pre-installed)

### Linux  
- bash, curl, jq (install via package manager)
- PowerShell Core (for bulk processing with `run.ps1`)

### macOS
- bash (pre-installed), curl, jq (via Homebrew)
- PowerShell Core (via Homebrew: `brew install --cask powershell`)

### All Platforms
- **Radarr**: Any recent version with API access
- **TMDB API key**: Optional, for enhanced native language support

## Development

These scripts evolved from personal frustration with Radarr's limited renaming. Started simple, grew into something that handles edge cases like:

- Movies with apostrophes and special characters
- Collection detection and grouping
- Multiple quality profiles
- Bilingual libraries
- Batch processing thousands of movies

Feel free to fork and adapt for your setup. The bash script (`rename-radarr-folders.sh`) contains the main logic if you want to understand or modify the behavior.

## What Gets Changed

### ✅ **What This Script Does**:
- **Renames movie folders** with intelligent naming patterns
- **Moves all files** (unchanged) to the new folder
- **Updates Radarr's database** to point to new folder location
- **Triggers Radarr refresh** so it can apply its own file naming rules

### ❌ **What This Script Does NOT Do**:
- Rename individual video files (`.mkv`, `.mp4`, etc.)
- Rename subtitle files (`.srt`, `.ass`, etc.) 
- Rename or delete extra files (`RARBG.txt`, `sample.mkv`, etc.)
- Modify video file content or metadata
- Change Radarr settings or configuration
- Delete anything from your system

### 🔄 **The Complete Process**:
1. **This script**: `Random.Movie.2023.x264-GROUP/` → `Action Collection (2023) - Movie Title [1080p]/`
2. **Files moved unchanged**: All `.mkv`, `.srt`, `.nfo` files keep original names
3. **Radarr triggered**: Receives refresh command and detects files in new location
4. **Radarr renames files**: Applies your file naming rules automatically

**Result**: Perfect folder organization + Radarr's file naming = Complete library organization

## Common Use Cases (v1.1)

### 🚀 **Getting Started**
```powershell
# First time setup - see what would change
.\run.ps1 -MaxMovies 10 -DryRun

# Test with a small batch
.\run.ps1 -MaxMovies 5
```

### 🔧 **Fix Specific Problems**
```powershell
# Fix movies Radarr couldn't identify properly
.\run.ps1 -FilterPath "[Unknown]"

# Fix movies without quality tags
.\run.ps1 -FilterNoQuality

# Fix movies in download/temp folders
.\run.ps1 -FilterPath "downloads"
.\run.ps1 -FilterPath "temp"
```

### 📅 **Maintenance Tasks**
```powershell
# Weekly cleanup - new additions only
.\run.ps1 -DaysBack 7

# Monthly check - recent movies without quality
.\run.ps1 -DaysBack 30 -FilterNoQuality

# Fix specific collection issues
.\run.ps1 -SearchTitle "Marvel" -DryRun
```

### 🎯 **Targeted Processing**
```powershell
# Work on specific quality tiers
.\run.ps1 -FilterPath "720p" -MaxMovies 50
.\run.ps1 -FilterPath "4K"

# Fix movies from specific years
.\run.ps1 -FilterPath "2023"
.\run.ps1 -FilterPath "2024"

# Process specific collections gradually
.\run.ps1 -SearchTitle "Harry Potter" -DryRun
.\run.ps1 -SearchTitle "Star Wars" -MaxMovies 20
```

### 🔄 **Bulk Operations**
```powershell
# Full library organization (use after testing!)
.\run.ps1

# Large library - process in chunks
.\run.ps1 -MaxMovies 100
.\run.ps1 -Skip 100 -MaxMovies 100    # Next 100
.\run.ps1 -Skip 200 -MaxMovies 100    # Next 100, etc.
```

## Credits

Built by someone tired of manually organizing movies. Extensively tested and proven on a library of 9000+ movies - a mix of 4K remuxes, 1080p rips, and random quality downloads across multiple languages.

Made this public because folder organization shouldn't be this hard.
