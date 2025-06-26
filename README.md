# Radarr Movie Folders Renamer

Scripts to automatically organize your Radarr movie library with proper folder naming that actually makes sense.

## Why Use This Instead of Radarr's Built-in Renaming?

Radarr's standard renaming is limited and frustrating. Here's what you get with these scripts that Radarr can't do:

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

### **Dual Usage: Auto-Rename + Bulk Processing**
- **Auto-rename**: Add as Radarr custom script - renames new downloads automatically
- **Bulk processing**: Process your entire library in one command (tested with 9000+ movies)

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
3. Test with a few movies: `.\run.ps1 -MaxMovies 5`
4. Process everything: `.\run.ps1`
5. Resume after interruption: `.\run.ps1 -Skip 100` (continues from movie #101)

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

### Auto-Rename (Radarr Custom Script)
```batch
# Radarr calls this automatically on import/upgrade
rename-radarr-folders.bat movieID "Movie Title" year "Quality"
```

Both methods use the same logic, just different triggers.

## How It Works

**Important**: This script only renames **folders**, not individual **files**.

1. Reads your movie data from Radarr API
2. Checks if movie is in your native language
3. Gets the right title (original for native language, English for others)
4. Builds folder name: `Collection (Year) - Title [Quality]`
5. **Renames only the folder** containing the movie
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

- **Extensive logging**: Every operation is logged with timestamps
- **Error handling**: Won't break if a movie fails
- **Dry run capable**: Test with small batches first (`-MaxMovies`)
- **Resume capability**: Continue from any point after interruption (`-Skip`)
- **Rollback friendly**: Radarr database backup lets you undo everything

## Troubleshooting

**"Git Bash not found"**: Install Git for Windows or update `GIT_BASH_PATH`

**"API key invalid"**: Get your API key from Radarr Settings > General

**"jq not found"**: Install with `winget install jqlang.jq` (Windows) or your package manager

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

## Credits

Built by someone tired of manually organizing movies. Extensively tested and proven on a library of 9000+ movies - a mix of 4K remuxes, 1080p rips, and random quality downloads across multiple languages.

Made this public because folder organization shouldn't be this hard.
