# Radarr Movie Renamer v2.1

Complete Radarr library organization solution that renames both folders AND files with intelligent quality detection, smart logging, and robust error handling.

## Why Use This Instead of Radarr's Built-in Renaming?

Radarr's standard renaming is limited and frustrating. Here's what you get with this script that Radarr can't do:

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

### 🛠️ Initial Setup
1. **Back up your Radarr database** (seriously, do this first)
2. Edit `config.env` with your Radarr URL and API key

### 🎬 Processing Movies
3. **Preview what would be changed**: `.\run.ps1 -MaxMovies 5 -DryRun`
4. **Test with a few movies**: `.\run.ps1 -MaxMovies 5`
5. **Process everything**: `.\run.ps1`
6. **Resume after interruption**: `.\run.ps1 -Skip 100` (continues from movie #101)

> 💡 **More examples and detailed usage**: See [CHANGELOG.md](CHANGELOG.md) for comprehensive feature documentation.

## Configuration

Copy and edit `config.env`:

```bash
# Your Radarr setup
RADARR_URL=http://127.0.0.1:7878
RADARR_API_KEY=your_api_key_here

# Language preferences (leave NATIVE_LANGUAGE empty for English-only)
NATIVE_LANGUAGE=es              # Spanish movies show Spanish titles
FALLBACK_LANGUAGE=en            # English movies show English titles

# Logging configuration - smart logging prevents oversized logs
LOG_LEVEL=NORMAL               # MINIMAL/NORMAL/DETAILED/DEBUG (see details below)
LOG_CUSTOM_FORMATS=false       # Keep false - prevents log spam
LOG_QUALITY_DEBUG=false        # Keep false - reduces noise
LOG_LANGUAGE_DEBUG=false       # Keep false - reduces noise

# Folder naming options - toggle what you want
USE_COLLECTIONS=true            # true: "Collection - Title", false: just "Title"
INCLUDE_QUALITY_TAG=true        # true: add [1080p], false: no quality tags
UPDATE_FOLDER_TIMESTAMP=false  # true: update folder dates, false: preserve original

# File renaming (renames both folders AND files)
ENABLE_FILE_RENAMING=false     # Enable Radarr-compatible file renaming
FILE_NAMING_PATTERN="{Movie.CleanTitle}.{Release.Year}.{Quality.Full}.{MediaInfo.VideoCodec}.{MediaInfo.AudioCodec}.{MediaInfo.AudioChannels}-{Release.Group}"

# Optional TMDB integration for better native language titles
TMDB_API_KEY=your_tmdb_key      # Leave empty to disable

# System paths (adjust for your OS)
SCRIPTS_DIR="C:\Scripts\radarr-renamer"           # Where scripts are located
LOG_FILE="C:\Scripts\radarr-renamer\logs\rename-radarr-folders.log"  # Log file location
GIT_BASH_PATH="C:\Program Files\Git\bin\bash.exe"  # Git Bash executable

# Linux/macOS examples:
# SCRIPTS_DIR="/home/user/scripts/radarr-renamer"
# LOG_FILE="/var/log/rename-radarr-folders.log"
# GIT_BASH_PATH="/bin/bash"
```

### Logging Levels Explained

Choose the right logging level for your needs:

- **MINIMAL**: Only errors, warnings, and final results (production use)
- **NORMAL**: Above + success messages and important info (recommended)
- **DETAILED**: Above + process steps and decisions (troubleshooting)
- **DEBUG**: Everything including technical details (development only)

### File Renaming Options

- **ENABLE_FILE_RENAMING=false**: Only renames folders (default, safest)
- **ENABLE_FILE_RENAMING=true**: Renames both folders AND movie files using Radarr's API

### Folder Naming Examples

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

### Utility Scripts

The package includes helpful diagnostic and maintenance scripts:

- **`check-git-bash.ps1 -Fix`**: Auto-detects Git Bash installation and fixes configuration issues
- **`clean-logs.ps1 -Compress`**: Compresses oversized log files while preserving important information
- **`get-movie-ids.ps1`**: Lists all movies in your Radarr library for testing purposes

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

### Selective Processing
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

**Important**: The script provides intelligent folder organization with optional file renaming capabilities.

1. Reads your movie data from Radarr API
2. Applies smart quality detection with precise TC/CAM pattern matching
3. Checks if movie is in your native language preference
4. Gets the appropriate title (original for native language, English for others)
5. Builds intelligent folder name: `Collection (Year) - Title [Quality]`
6. **Organizes folder structure** with configurable collection and quality options
7. **Optionally renames files** using Radarr's native API (if enabled)
8. Updates Radarr database with new folder path and triggers refresh

**Example workflow**:

**Folder Mode** (ENABLE_FILE_RENAMING=false):
```
Before: Iron.Man.2008.1080p.BluRay.x264-GROUP/
        ├── Iron.Man.2008.1080p.BluRay.x264-GROUP.mkv
        └── Iron.Man.2008.1080p.BluRay.x264-GROUP.srt

After:  Marvel Cinematic Universe (2008) - Iron Man [1080p]/
        ├── Iron.Man.2008.1080p.BluRay.x264-GROUP.mkv  # Files keep original names
        └── Iron.Man.2008.1080p.BluRay.x264-GROUP.srt  # Perfect for manual management
```

**File Renaming Mode** (ENABLE_FILE_RENAMING=true):
```
Before: Iron.Man.2008.1080p.BluRay.x264-GROUP/
        ├── Iron.Man.2008.1080p.BluRay.x264-GROUP.mkv
        └── Iron.Man.2008.1080p.BluRay.x264-GROUP.srt

After:  Marvel Cinematic Universe (2008) - Iron Man [1080p]/
        ├── Iron.Man.2008.1080p.h264.DTS.5.1-GROUP.mkv    # Renamed with MediaInfo
        └── Iron.Man.2008.1080p.h264.DTS.5.1-GROUP.en.srt # Complete organization
```

## Language Examples

With `NATIVE_LANGUAGE=es`:
- **Spanish movie**: "El Laberinto del Fauno" → `El Laberinto del Fauno (2006) [1080p]`
- **English movie**: "The Dark Knight" → `The Dark Knight (2008) [1080p]`
- **French movie**: "Amélie" → `Amélie (2001) [720p]` (uses original title)

## File Structure

```
├── config.env                   # Your configuration
├── run.ps1                     # Bulk processing script
├── rename-radarr-folders.bat   # Individual movie processing (folders)
├── rename-radarr-folders.ps1   # PowerShell wrapper
├── rename-radarr-folders.sh    # Main folder logic (bash)
├── rename-radarr-folders       # Shell script for Linux/macOS compatibility
├── rename-radarr-files.sh      # File renaming logic (bash)
├── get-movie-ids.ps1           # List your movies for testing
├── get-single-movie.ps1        # Single movie processing utility
├── check-git-bash.ps1          # Diagnostic tool for Git Bash
├── clean-logs.ps1              # Log management utility
├── README.md                   # This documentation file
├── CHANGELOG.md                # Version history and release notes
└── logs/                       # Detailed logs
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

### 🔧 Diagnostic Tools
- **Diagnose Git Bash Issues**: `.\check-git-bash.ps1 -Fix` (auto-detects and fixes Git Bash configuration)
- **Clean Oversized Logs**: `.\clean-logs.ps1 -Compress` (reduces log file sizes while preserving important info)

### ⚡ Quick Fixes
```powershell
# See movies that need fixing without making changes
.\run.ps1 -FilterPath "[Unknown]" -DryRun
.\run.ps1 -FilterNoQuality -DryRun

# Fix most common issues
.\run.ps1 -FilterPath "[Unknown]"        # Fix folders with [Unknown] 
.\run.ps1 -FilterNoQuality               # Fix movies without quality
.\run.ps1 -DaysBack 7                    # Fix recent additions only
```

### Common Issues
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

### ✅ **What This Script Always Does**:
- **Renames movie folders** with intelligent naming patterns and quality detection
- **Moves all files** to the new organized folder structure
- **Updates Radarr's database** to point to new folder location
- **Triggers Radarr refresh** to detect files in new location
- **Smart logging** with configurable verbosity levels

### 🔧 **What This Script Can Do** (if enabled):
- **Rename movie files** using Radarr's native API (`ENABLE_FILE_RENAMING=true`)
- **Apply Radarr naming patterns** to individual video and subtitle files
- **Extract MediaInfo details** for enhanced file naming

### ❌ **What This Script Never Does**:
- Rename or delete extra files (`RARBG.txt`, `sample.mkv`, etc.)
- Modify video file content, metadata, or quality
- Change Radarr settings or configuration
- Delete anything from your system
- Process files outside of Radarr's library

### 🔄 **The Complete Process**:

**Folder Mode** (default):
1. **This script**: `Random.Movie.2023.x264-GROUP/` → `Action Collection (2023) - Movie Title [1080p]/`
2. **Files moved unchanged**: All `.mkv`, `.srt`, `.nfo` files keep original names
3. **Radarr triggered**: Receives refresh command and detects files in new location

**File Renaming Mode** (if enabled):
1. **Folders organized**: Same intelligent folder structure as above
2. **Files renamed**: Uses Radarr's API to rename files with proper patterns
3. **MediaInfo extracted**: Video/audio codec and quality details included in filenames

**Result**: Perfect folder organization + optional comprehensive file naming = Complete library organization

## Common Workflows

### 📚 **Library Migration**
When moving from unorganized to organized structure:
1. **Test first**: Use `-DryRun` with a small subset
2. **Process by quality**: Start with high-quality files (`-FilterPath "1080p"`)
3. **Handle problematic movies**: Fix `[Unknown]` and missing quality tags
4. **Collections last**: Process collection-based movies after individual titles are clean

### 🔄 **Ongoing Maintenance** 
For libraries that are mostly organized:
- **Weekly**: Process recent additions (`-DaysBack 7`)
- **Monthly**: Clean up download folders (`-FilterPath "downloads"`)
- **As needed**: Fix specific collections or quality issues

### 🎯 **Selective Organization**
For large libraries (1000+ movies):
- **Process in chunks**: Use `-MaxMovies` and `-Skip` for manageable batches
- **Target specific issues**: Focus on movies with quality problems first
- **Collection by collection**: Organize Marvel, DC, Star Wars separately for better control

## Credits

Built by someone tired of manually organizing movies. Extensively tested and proven on a library of 9000+ movies - a mix of 4K remuxes, 1080p rips, and random quality downloads across multiple languages.

Made this public because folder organization shouldn't be this hard.
