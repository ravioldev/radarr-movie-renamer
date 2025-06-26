# 🚀 Radarr Folder Rename Scripts v1.0 - Major Feature Update

Complete Radarr movie folder rename system with comprehensive improvements and new features.

## ✨ NEW FEATURES

### 🧪 Safe Testing with MaxMovies Parameter
- **run.ps1 -MaxMovies N**: Process only first N movies for safe testing
- Detailed success/error counting and reporting
- Perfect for testing configuration changes without affecting entire library

### 🎯 Enhanced Quality Detection
- **New SDTV → 480p mapping**: Better handling of standard definition content
- **Improved 1080p detection**: Enhanced WebDL, Bluray, WebRip pattern matching
- **Better DVD mapping**: 576p → DVD-Rip for accurate quality representation
- **Case-insensitive matching**: More reliable quality tag extraction

### 📁 Full Paths with Spaces Support
- **No escaping needed**: Works seamlessly with paths containing spaces
- **Enhanced batch parsing**: Improved Windows batch file configuration handling
- **Better argument processing**: Robust PowerShell and Bash argument handling

### 🔤 Special Character Handling
- **Single quotes**: Proper handling of titles like "'71"
- **Complex punctuation**: Commas, periods, hyphens, and other special characters
- **Unicode support**: International characters and accents

### 🛠️ New Testing Utilities
- **get-movie-ids.ps1**: List all movies with IDs for targeted testing
- **get-single-movie.ps1**: Get detailed info for specific movie by ID
- Better debugging and troubleshooting capabilities

## 🔧 MAJOR IMPROVEMENTS

### 🎯 Fixed Critical Folder Renaming Logic
- **Destination reversion bug fixed**: Folders no longer revert to original names
- **Improved path handling**: Better validation and error checking
- **Enhanced logging**: Detailed progress tracking for troubleshooting

### ⚡ Simplified Configuration Parsing
- **Batch file improvements**: Avoid syntax errors with complex configurations
- **Better variable expansion**: More reliable ${VARIABLE} substitution
- **Enhanced validation**: Clear error messages for configuration issues

### 📊 Enhanced Error Handling
- **Detailed exit codes**: Specific codes for different error types
- **Better error messages**: Clear guidance for troubleshooting
- **Comprehensive logging**: Full operation tracking with timestamps

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

## 🔄 Upgrade from Previous Versions

- **Backup your config**: Save your existing configuration
- **Replace scripts**: Update all script files
- **Update config**: Add new MaxMovies and quality options
- **Test first**: Use MaxMovies parameter before full deployment

## 🛡️ Safety Features

- **MaxMovies parameter**: Test with limited movie count
- **Comprehensive validation**: API key, paths, and dependency checking
- **Detailed logging**: Full operation tracking
- **Rollback support**: Clear error messages for troubleshooting

## 📋 Requirements

- **Windows**: PowerShell 5.1+ and Windows Subsystem for Linux (WSL) or Git Bash
- **Linux/macOS**: Bash 4.0+, curl, jq
- **Radarr**: v3.0+ with API access
- **Optional**: TMDB API key for enhanced collection support

---

**Full changelog and documentation available in README.md** 