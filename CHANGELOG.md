# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2] - 2025-07-02

### 🎯 LOGGING OPTIMIZATION PATCH

**v2.2 optimizes the logging system for better performance and readability in production environments.**

### 📊 Enhanced Logging System
- **Proper Level Enforcement**: Log levels now correctly filter output based on configuration
- **90% Log Reduction**: Debug and technical analysis moved to appropriate levels
- **Smart Categorization**: All logging functions properly respect LOG_LEVEL settings
- **Production Ready**: NORMAL level now shows only relevant information for end users

### 🔧 Improvements
- **Debug Cleanup**: Technical analysis, token debugging, and internal tests moved to DEBUG level
- **Detailed Refinement**: Process steps and validation moved to DETAILED level  
- **User Focus**: NORMAL level optimized for daily use with essential information only
- **Performance**: Reduced I/O overhead from excessive logging in production

### 🎯 Impact
- **Cleaner Logs**: Users see only relevant information at their configured level
- **Better Performance**: Reduced logging overhead during normal operation
- **Easier Troubleshooting**: Clear separation between user info and debug data
- **Production Friendly**: Default NORMAL level perfect for automated processing

### ⚡ No Configuration Changes Required
- Fully automatic improvement - existing configurations work unchanged
- All log levels maintained with proper filtering
- Immediate benefit upon update

## [2.1] - 2025-06-29

### 🚨 CRITICAL STABILITY UPDATE - ESSENTIAL UPGRADE

**v2.1 fixes critical issues that were causing movies to fail processing and creating massive unusable logs.**

### 🔧 Fixed Quality Detection Issues
- **TC/CAM Pattern Detection**: Fixed overly broad patterns causing false positives
- **YIFY & BrRip Quality**: Now correctly detected as proper resolution instead of LowQuality
- **Pattern Matching**: Made quality detection patterns more precise and specific

### 📊 Massive Log Size Reduction (90%)
- **Smart Logging System**: Dramatically reduced log file sizes while maintaining useful information
- **New Logging Levels**: MINIMAL, NORMAL, DETAILED, DEBUG for better control
- **Smart Controls**: Separate logging for Custom Formats and quality detection
- **Default Setting**: LOG_LEVEL=NORMAL provides perfect balance for most users

### 🔧 Critical Error Fixes
- **Bash Syntax Errors**: Fixed script failures that appeared as "Git Bash not found"
- **Exit Code Issues**: Resolved random exit code 1 failures
- **Processing Reliability**: Scripts now run consistently without random failures
- **Variable Declarations**: Fixed invalid local variable usage

### 🛠️ New Utility Scripts
- **`check-git-bash.ps1`**: Auto-detects Git Bash installation and fixes path issues
- **`clean-logs.ps1`**: Compresses oversized logs while preserving important information
- **Smart Configuration**: Automatic path detection and setup assistance

### 📁 Updated File Structure
```
├── config.env                   # Enhanced configuration with logging controls
├── run.ps1                     # Bulk processing script
├── rename-radarr-folders.bat   # Individual movie processing (folders)
├── rename-radarr-folders.sh    # Main folder logic (bash) - enhanced quality detection
├── rename-radarr-files.sh      # File renaming logic (bash) - enhanced logging
├── get-movie-ids.ps1           # List your movies for testing
├── check-git-bash.ps1          # 🆕 NEW: Diagnostic tool for Git Bash
├── clean-logs.ps1              # 🆕 NEW: Log management utility
├── CHANGELOG.md                # Version history and release notes
└── logs/                       # Detailed logs (now manageable sizes)
```

### 🎯 Impact
- **Processing Reliability**: Movies that were failing now process correctly
- **Log Management**: Dramatically reduced log file sizes while maintaining useful information
- **System Stability**: More consistent execution without unexpected failures
- **User Experience**: Easier troubleshooting with manageable log files

### ⚡ Migration
- **Fully Automatic**: Just update files and run - no configuration changes needed
- **Backward Compatible**: All existing settings continue to work
- **Immediate Benefits**: Better quality detection and smaller logs from first run

## [2.0] - 2025-06-29

### 🚀 MAJOR RELEASE - Complete Library Organization

**v2.0 is a significant upgrade that transforms this from a folder renamer into a complete library organization solution.**

### ✨ New Features
- **🎬 File Renaming Support**: Now renames both folders AND movie files with intelligent naming patterns
- **🧠 Smart Quality Processing**: Different quality logic for folders vs files
  - Folders: Clean tags like `[1080p]`, `[720p]`
  - Files: Detailed quality like `720p-SCREENER`, `480p-SDTV`, `2160p-TELESYNC`
- **📊 Enhanced MediaInfo Integration**: Automatic extraction of video/audio technical details
  - Video codecs: `h265`, `x264`, `AV1`
  - Audio codecs: `EAC3`, `DTS`, `AAC`, `TrueHD`
  - Audio channels: `5.1`, `7.1`, `Atmos`
- **📝 Configurable File Naming**: Customizable file naming patterns with Radarr tokens

### 🔧 Major Improvements
- **🌐 Enhanced UTF-8 Support**: Better handling of international characters and emojis
- **🛡️ Robust Error Handling**: Improved error recovery and graceful failure handling
- **🗂️ Path Processing Fixes**: Resolved issues with spaces and backslashes in Windows paths
- **🔄 Token Processing**: Fixed token replacement logic for more accurate file naming
- **⚡ Performance Optimizations**: More efficient processing and logging

### 🔄 Changed
- Project renamed from "Radarr Movie Folders Renamer" to "Radarr Movie Renamer"
- Configuration now includes file naming patterns
- Processing logic enhanced to handle both folders and files
- Quality detection logic improved for different use cases

### 🎯 Migration from v1.x
- Fully backward compatible - existing configurations continue to work
- New file renaming feature is automatically enabled
- No manual migration required - just update and run

### 📁 Updated File Structure
Complete library organization solution with both folder and file renaming:
```
├── config.env                   # Enhanced configuration with file naming patterns
├── run.ps1                     # Bulk processing script  
├── rename-radarr-folders.bat   # Individual movie processing (folders)
├── rename-radarr-folders.sh    # Main folder logic (bash) - enhanced
├── rename-radarr-files.sh      # 🆕 NEW: File renaming logic (bash)
├── get-movie-ids.ps1           # Movie listing utility
├── get-single-movie.ps1       # Single movie utility
├── CHANGELOG.md                # Version history and release notes
└── logs/                       # Log directory
```

### Examples
**Folder Organization** (existing functionality enhanced):
```
Marvel Cinematic Universe (2008) - Iron Man [1080p]
The Dark Knight (2008) [2160p]
```

**File Naming** (NEW in v2.0):
```
Iron.Man.2008.1080p.h264.DTS.5.1-GROUP.mkv
The.Dark.Knight.2008.2160p.h265.TrueHD.Atmos.7.1-GROUP.mkv
Screener.Movie.2024.720p-SCREENER.x264.AAC.2.0-GROUP.mkv
```

## [1.2] - 2025-06-27

### 🚨 CRITICAL SECURITY FIX
- Fixed security vulnerability that could copy unrelated files during folder operations
- Script now only copies video files and subtitles instead of entire directories
- Added safety checks to prevent processing system directories
- Fixed configuration path inconsistencies

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