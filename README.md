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

### **Bulk Processing**
- **Radarr**: Rename movies one by one through the UI (painful for large libraries)
- **This script**: Process your entire 2000+ movie library in one command

### **TMDB Integration**
- **Radarr**: Limited metadata sources
- **This script**: Pull native language titles directly from TMDB when needed

### **Better Folder Structure**
Instead of this mess:
```
Iron.Man.2008.1080p.BluRay.x264-GROUP/
The Dark Knight (2008)/
avengers_endgame_2019_4k/
```

You get this:
```
Marvel Cinematic Universe (2008) - Iron Man [1080p]/
The Dark Knight (2008) [1080p]/
Marvel Cinematic Universe (2019) - Avengers Endgame [2160p]/
```

## Quick Setup

1. **Back up your Radarr database** (seriously, do this first)
2. Edit `config.env` with your Radarr URL and API key
3. Test with a few movies: `.\run.ps1 -MaxMovies 5`
4. Process everything: `.\run.ps1`

## Configuration

Copy and edit `config.env`:

```bash
# Your Radarr setup
RADARR_URL=http://127.0.0.1:7878
RADARR_API_KEY=your_api_key_here

# Language preferences (leave NATIVE_LANGUAGE empty for English-only)
NATIVE_LANGUAGE=es              # Spanish movies show Spanish titles
FALLBACK_LANGUAGE=en            # English movies show English titles

# What you want in folder names
USE_COLLECTIONS=true            # Group franchise movies together
INCLUDE_QUALITY_TAG=true        # Add [1080p], [720p], etc.

# Paths (Windows example)
SCRIPTS_DIR=C:\scripts\
GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe
```

## Usage

### Process All Movies
```powershell
.\run.ps1
```

### Test with 10 Movies First
```powershell
.\run.ps1 -MaxMovies 10
```

### Single Movie (for Radarr custom scripts)
```batch
rename-radarr-folders.bat movieID "Movie Title" year "Quality"
```

## How It Works

1. Reads your movie data from Radarr API
2. Checks if movie is in your native language
3. Gets the right title (original for native language, English for others)
4. Builds folder name: `Collection (Year) - Title [Quality]`
5. Renames the folder and updates Radarr database

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

## Radarr Integration

Add this as a custom script in Radarr Settings > Connect:

- **On Import**: Automatically rename new downloads
- **On Upgrade**: Rename when quality improves
- **Path**: Point to `rename-radarr-folders.bat`

## Safety Features

- **Extensive logging**: Every operation is logged with timestamps
- **Error handling**: Won't break if a movie fails
- **Dry run capable**: Test with small batches first
- **Rollback friendly**: Radarr database backup lets you undo everything

## Troubleshooting

**"Git Bash not found"**: Install Git for Windows or update `GIT_BASH_PATH`

**"API key invalid"**: Get your API key from Radarr Settings > General

**"jq not found"**: Install with `winget install jqlang.jq` (Windows) or your package manager

**Movies not updating**: Check the log file for detailed error messages

## Requirements

- **Windows**: Git Bash (comes with Git for Windows)
- **Linux/macOS**: bash, curl, jq, PowerShell Core
- **Radarr**: Any recent version with API access

## Development

These scripts evolved from personal frustration with Radarr's limited renaming. Started simple, grew into something that handles edge cases like:

- Movies with apostrophes and special characters
- Collection detection and grouping
- Multiple quality profiles
- Bilingual libraries
- Batch processing thousands of movies

Feel free to fork and adapt for your setup. The bash script (`rename-radarr-folders.sh`) contains the main logic if you want to understand or modify the behavior.

## What Gets Changed

The script only renames folders and updates Radarr's database. It doesn't:
- Move files between drives
- Modify video files
- Change Radarr settings
- Delete anything

Your movie files stay exactly the same, just better organized.

## Credits

Built by someone tired of manually organizing 2000+ movies. Tested on a mix of 4K remuxes, 1080p rips, and random quality downloads across multiple languages.

Made this public because folder organization shouldn't be this hard.
