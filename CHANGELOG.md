# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1] - 2025-06-27

### Added
- **🎯 Selective Processing**: Target specific movies instead of processing your entire library
- **🔍 Smart Filters**: Multiple filtering options for precise movie selection
  - `-FilterPath "text"`: Filter movies with specific text in folder path (configurable)
  - `-FilterNoQuality`: Filter movies without quality defined or missing files
  - `-DaysBack N`: Filter movies added/modified in the last N days
  - `-SearchTitle "text"`: Filter movies with text in title
- **🧪 Preview Mode**: See exactly what would be changed before making any modifications (`-DryRun`)
- **⚡ Enhanced Safety**: Multiple safety features for better control
  - Preview mode to see changes before applying
  - Selective processing instead of all-or-nothing approach
  - Better error handling and logging
- **📚 Comprehensive Documentation**: Updated README with extensive examples and use cases

### Changed
- **FilterPath Parameter**: Replaced fixed `FilterUnknown` switch with configurable `FilterPath` string parameter
- **Processing Logic**: Filters are now applied before Skip/MaxMovies for better control
- **Status Messages**: Enhanced progress reporting with filter-specific information
- **Safety Features**: Improved error handling and user confirmation

### Technical Details
- Maintains 100% backward compatibility with existing commands
- All new parameters are optional - existing scripts continue to work unchanged
- Enhanced logging shows filter application results
- Combinable filters allow for precise targeting (e.g., `-FilterPath "[Unknown]" -FilterNoQuality -DaysBack 7`)

### Examples
```powershell
# See what movies would be processed (no changes made)
.\run.ps1 -FilterPath "[Unknown]" -DryRun

# Process only movies with "[Unknown]" in folder path
.\run.ps1 -FilterPath "[Unknown]"

# Process movies without quality defined
.\run.ps1 -FilterNoQuality

# Process movies added in the last 7 days
.\run.ps1 -DaysBack 7

# Combine filters for precise targeting
.\run.ps1 -FilterPath "temp" -FilterNoQuality -DaysBack 30
```

## [1.0] - 2025-06-26

### Added
- **Cross-Platform Support**: Works on Windows, Linux, and macOS
- **Dual Usage Modes**: 
  - Auto-rename: Radarr custom script for new downloads
  - Bulk processing: Process entire library with `run.ps1`
- **Smart Collection Handling**: Groups movies by collection (Marvel, DC, Star Wars, etc.)
- **Language-Aware Processing**: Native language titles for foreign movies
- **Quality Tag Integration**: Clean quality tags ([1080p], [2160p], etc.)
- **TMDB Integration**: Optional TMDB API support for enhanced metadata
- **Flexible Configuration**: Toggle collections and quality tags independently
- **Safety Features**: 
  - Extensive logging with timestamps
  - Error handling that continues processing
  - Resume capability with `-Skip` parameter
  - Test mode with `-MaxMovies` parameter
- **Smart Folder Organization**: 
  - Collection-based: `Marvel Cinematic Universe (2008) - Iron Man [1080p]`
  - Non-collection: `The Dark Knight (2008) [1080p]`
  - No empty placeholders for missing data

### Technical Features
- **PowerShell + Bash**: PowerShell wrapper with bash processing logic
- **UTF-8 Support**: Proper handling of international characters
- **Path Validation**: Extensive path and dependency checking
- **API Integration**: Full Radarr API integration for metadata and updates
- **File Safety**: Only renames folders, never touches video files
- **Dependency Validation**: Automatic checking for required tools (jq, curl, etc.)

### Initial File Structure
```
├── config.env                  # Configuration file
├── run.ps1                     # Bulk processing script  
├── rename-radarr-folders.bat   # Windows batch script
├── rename-radarr-folders.ps1   # PowerShell wrapper
├── rename-radarr-folders.sh    # Main bash logic
├── get-movie-ids.ps1          # Movie listing utility
├── get-single-movie.ps1       # Single movie utility
└── logs/                      # Log directory
``` 