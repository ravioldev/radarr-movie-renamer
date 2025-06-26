# 🚀 Radarr Movie Folders Renamer v1.0 - Initial Release

Complete automated system for organizing and renaming Radarr movie folders with intelligent naming patterns.

## 🎯 What This Project Does

**Radarr Movie Folders Renamer** automatically organizes your existing Radarr movie collection by renaming folders with consistent, organized patterns. Transform messy folder names into clean, standardized formats that make your library easier to browse and manage.

### 📁 Folder Naming Examples

Transform your movie folders from random names to organized patterns:

**Before:**
```
/movies/Iron.Man.2008.1080p.BluRay.x264-GROUP/
/movies/The Dark Knight (2008)/
/movies/avengers_endgame_2019_4k/
```

**After:**
```
/movies/Marvel Cinematic Universe (2008) - Iron Man [1080p]/
/movies/The Dark Knight (2008) [1080p]/
/movies/Marvel Cinematic Universe (2019) - Avengers Endgame [4K]/
```

## ✨ KEY FEATURES

### 🧪 Safe Testing with MaxMovies Parameter
- **run.ps1 -MaxMovies N**: Process only first N movies for safe testing
- Detailed success/error counting and reporting
- Perfect for testing configuration before processing entire library

### 🎯 Intelligent Quality Detection
- **SDTV → 480p mapping**: Standard definition content handling
- **Enhanced 1080p detection**: WebDL, Bluray, WebRip pattern matching
- **4K/UHD support**: Proper 4K and UHD quality tag extraction
- **Case-insensitive matching**: Reliable quality tag detection

### 📁 Full Paths with Spaces Support
- **No escaping needed**: Works seamlessly with paths containing spaces
- **Enhanced parsing**: Robust Windows batch and PowerShell handling
- **Cross-platform**: Works on Windows, Linux, and macOS

### 🔤 Special Character Handling
- **Single quotes**: Proper handling of titles like "'71"
- **Complex punctuation**: Commas, periods, hyphens, and special characters
- **International support**: Unicode characters and accents

### 🛠️ Testing and Debugging Utilities
- **get-movie-ids.ps1**: List all movies with IDs for targeted testing
- **get-single-movie.ps1**: Get detailed info for specific movie by ID
- **Comprehensive logging**: Full operation tracking for troubleshooting

## 🔧 CORE CAPABILITIES

### 🎯 Intelligent Folder Organization
- **Collection grouping**: Movies organized by franchise/collection
- **Quality tags**: Automatic quality detection and tagging
- **Language preferences**: Configurable native and fallback languages
- **Flexible patterns**: Multiple naming format options

### ⚡ Robust Configuration System
- **Centralized config**: Single config.env file for all settings
- **Variable expansion**: Support for ${VARIABLE} substitution
- **Comprehensive validation**: Clear error messages and guidance

### 📊 Advanced Error Handling
- **Detailed exit codes**: Specific codes for different scenarios
- **Progress tracking**: Full operation logging with timestamps
- **Safe operations**: Validation before making changes

## 📦 What's Included

- `config.env` - Configuration template with all options
- `rename-radarr-folders.bat` - Windows batch script for Radarr integration
- `rename-radarr-folders.sh` - Main bash script with renaming logic
- `run.ps1` - PowerShell launcher for bulk processing
- `get-movie-ids.ps1` - Movie listing utility for testing
- `get-single-movie.ps1` - Single movie info utility
- `README.md` - Complete documentation with examples

## 🚀 Quick Start

1. **Download and extract** the ZIP file
2. **Copy `config.env`** to your preferred location
3. **Edit configuration**: Add your Radarr API key and paths
4. **Test safely**: Use `run.ps1 -MaxMovies 5` to test with 5 movies first
5. **Integrate with Radarr**: Configure as custom script in Radarr settings

## 🛡️ Safety Features

- **MaxMovies parameter**: Test with limited movie count before full deployment
- **Comprehensive validation**: API key, paths, and dependency checking
- **Detailed logging**: Full operation tracking and error reporting
- **Non-destructive**: Only renames folders, doesn't modify movie files

## 📋 Requirements

- **Windows**: PowerShell 5.1+ and Windows Subsystem for Linux (WSL) or Git Bash
- **Linux/macOS**: Bash 4.0+, curl, jq
- **Radarr**: v3.0+ with API access
- **Optional**: TMDB API key for enhanced collection support

---

**Complete setup guide and configuration options available in README.md** 