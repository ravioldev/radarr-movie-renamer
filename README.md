# Radarr Folder Rename Scripts

A comprehensive set of scripts for automatically organizing and renaming movie folders in Radarr with customizable configurations.

## ⚠️ **IMPORTANT DISCLAIMER**

**USE AT YOUR OWN RISK!** This script has been extensively tested and proven useful in the author's specific Radarr setup, but may not work identically in all library configurations. Different setups, folder structures, and Radarr configurations can produce unexpected results.

### 🛡️ **CRITICAL SAFETY STEPS**

**Before running these scripts:**

1. **🗄️ BACKUP YOUR RADARR DATABASE** 
   - Stop Radarr service
   - Copy your entire Radarr data folder (especially `radarr.db`)
   - This allows you to restore if something goes wrong

2. **📁 BACKUP YOUR MOVIE FOLDERS**
   - Consider backing up a few movie folders before testing
   - Or at minimum, ensure you have recovery options

3. **🧪 TEST WITH A SMALL SUBSET FIRST**
   - Start with 5-10 movies to test the behavior
   - Verify the results match your expectations
   - Check that Radarr updates correctly
   - Only proceed with full library after successful testing

4. **📋 VERIFY YOUR CONFIGURATION**
   - Double-check all paths in `config.env`
   - Ensure API keys are correct
   - Test configuration with a single movie first

**The author is not responsible for any data loss, corruption, or issues that may arise from using these scripts.**

## 🎬 Features

- **Automated Movie Organization**: Rename and organize movie folders based on configurable patterns
- **Multi-Language Support**: Configure native language preferences with intelligent fallback
- **Collection Support**: Optional movie collection integration in folder names
- **Quality Tags**: Optional quality indicators in folder names
- **TMDB Integration**: Optional TMDB API support for enhanced metadata
- **Cross-Platform**: Works on Windows with Git Bash
- **Extensive Logging**: Detailed logs with error tracking and troubleshooting
- **Flexible Configuration**: Centralized config file with sensible defaults

## 📁 Project Structure

```
rename-script/
├── config.env                    # Main configuration file
├── run.ps1                      # PowerShell launcher for bulk processing
├── rename-radarr-folders.bat    # Windows batch wrapper for individual movies
├── rename-radarr-folders.sh     # Main bash script with all logic
└── README.md                    # This file
```

## 🚀 Quick Start

### 1. Prerequisites

- **Radarr**: Running instance with API access
- **Git Bash**: For Windows (usually installed with Git)
- **PowerShell**: 5.1+ or PowerShell Core

### 2. Configuration

⚠️ **BEFORE CONFIGURING: Complete the safety steps in the disclaimer above!**

1. Copy `config.env` and edit with your settings:

```bash
# Radarr Configuration
RADARR_URL=http://127.0.0.1:7878
RADARR_API_KEY=your_radarr_api_key_here

# TMDB Configuration (optional - leave empty to disable)
TMDB_API_KEY=

# Language Configuration  
NATIVE_LANGUAGE=             # Your native language (empty for English-only)
FALLBACK_LANGUAGE=en         # Fallback language (usually English)
AUTO_DETECT_FROM_RADARR=false

# Paths Configuration
SCRIPTS_DIR=C:\path\to\your\scripts
LOG_FILE=C:\path\to\your\logs\rename-radarr-folders.log
GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe

# Folder Naming Configuration  
USE_COLLECTIONS=true         # Include collection names in folder structure
INCLUDE_QUALITY_TAG=true     # Include quality tags in folder names
```

2. Update script paths to match your environment

### 3. Usage

#### Bulk Processing (All Movies):
```powershell
.\run.ps1
```

This processes all movies in your Radarr library at once.

## ⚙️ Configuration Options

### Core Settings

| Setting | Description | Default | Example |
|---------|-------------|---------|---------|
| `RADARR_URL` | Radarr instance URL | `http://127.0.0.1:7878` | `http://192.168.1.100:7878` |
| `RADARR_API_KEY` | Radarr API key | `your_radarr_api_key_here` | `abc123def456...` |
| `TMDB_API_KEY` | TMDB API key (optional) | *(empty)* | `xyz789abc123...` |

### Language Configuration

| Setting | Description | Default | Example |
|---------|-------------|---------|---------|
| `NATIVE_LANGUAGE` | Your native language for original-language movies | *(empty)* | `es`, `de`, `pt`, `fr`, `ja` |
| `FALLBACK_LANGUAGE` | Language for all other movies | `en` | `en`, `es`, `fr` |
| `AUTO_DETECT_FROM_RADARR` | Auto-detect language from Radarr UI | `false` | `true`, `false` |

### Folder Naming

| Setting | Description | Default | Example |
|---------|-------------|---------|---------|
| `USE_COLLECTIONS` | Include collection names in folders | `true` | `true`, `false` |
| `INCLUDE_QUALITY_TAG` | Include quality tags in folders | `true` | `true`, `false` |

### File System

| Setting | Description | Default |
|---------|-------------|---------|
| `VIDEO_EXTENSIONS` | Supported video file extensions | `mkv mp4 avi mov webm wmv flv...` |
| `FILE_PERMISSIONS_DIR` | Directory permissions for rsync | `D755` |
| `FILE_PERMISSIONS_FILE` | File permissions for rsync | `F644` |
| `FIND_MAXDEPTH` | Search depth for video files | `1` |
| `RSYNC_OPTIONS` | Options for rsync file operations | `-a --ignore-existing` |

### Path Configuration

| Setting | Description | Default | Example |
|---------|-------------|---------|---------|
| `SCRIPTS_DIR` | Directory containing the scripts | `C:\path\to\your\scripts` | `D:\scripts\rename script\` |
| `LOG_FILE` | Log file location | `C:\path\to\your\logs\...` | `D:\scripts\logs\rename.log` |
| `GIT_BASH_PATH` | Path to Git Bash executable | `C:\Program Files\Git\bin\bash.exe` | Same for most systems |

## 🏗️ Folder Naming Configuration

### How Collections Work

**Important**: Not all movies have collections. The behavior depends on both your settings AND whether each individual movie belongs to a collection:

- **Movies WITH collections** (e.g., Marvel, Lord of the Rings): Can use collection format if enabled
- **Movies WITHOUT collections** (e.g., standalone films): Always use simple "Title (Year)" format regardless of `USE_COLLECTIONS` setting

### Configuration Impact

| Setting | Movies WITH Collections | Movies WITHOUT Collections |
|---------|------------------------|----------------------------|
| `USE_COLLECTIONS=true` | `Collection (Year) - Title [Quality]` | `Title (Year) [Quality]` |
| `USE_COLLECTIONS=false` | `Title (Year) [Quality]` | `Title (Year) [Quality]` |

## 🏗️ Folder Naming Examples

### With Collections + Quality (Default)
```bash
USE_COLLECTIONS=true
INCLUDE_QUALITY_TAG=true
```
**Result (movies with AND without collections coexist):**
```
Marvel Cinematic Universe (2008) - Iron Man [1080p]          # Has collection
The Lord of the Rings Collection (2001) - Fellowship of the Ring [4K]  # Has collection  
Parasite (2019) [1080p]                                      # No collection - simple format
Joker (2019) [1080p]                                         # No collection - simple format
```

### Simple Title + Quality (Collections Ignored)
```bash
USE_COLLECTIONS=false
INCLUDE_QUALITY_TAG=true
```
**Result (uniform format, collections ignored):**
```
Iron Man (2008) [1080p]                    # Collection ignored
Fellowship of the Ring (2001) [4K]         # Collection ignored
Parasite (2019) [1080p]                    # No collection anyway
Joker (2019) [1080p]                       # No collection anyway
```

### Title Only (Minimal)
```bash
USE_COLLECTIONS=false
INCLUDE_QUALITY_TAG=false
```
**Result (clean, no extras):**
```
Iron Man (2008)                            # Collection + quality ignored
Fellowship of the Ring (2001)              # Collection + quality ignored
Parasite (2019)                            # No extras
Joker (2019)                               # No extras
```

### Collection without Quality
```bash
USE_COLLECTIONS=true
INCLUDE_QUALITY_TAG=false
```
**Result (mixed formats, no quality tags):**
```
Marvel Cinematic Universe (2008) - Iron Man          # Has collection, no quality
The Lord of the Rings Collection (2001) - Fellowship of the Ring  # Has collection, no quality
Parasite (2019)                                      # No collection, no quality  
Joker (2019)                                         # No collection, no quality
```

## 🌐 Language Behavior

### Native Language Logic

The script uses intelligent language detection:

1. **Original Language Match**: If movie's original language matches your `NATIVE_LANGUAGE`, uses native titles
2. **Fallback Language**: For all other movies, uses `FALLBACK_LANGUAGE` titles
3. **Auto-Detection**: Optionally reads language preference from Radarr UI settings

### Examples

#### Spanish User Configuration:
```bash
NATIVE_LANGUAGE=es
FALLBACK_LANGUAGE=en
```

**Results:**
- Spanish movie: "El Laberinto del Fauno (2006)" *(uses Spanish title)*
- French movie: "Amélie (2001)" *(uses English title)*
- English movie: "The Dark Knight (2008)" *(uses English title)*

#### German User Configuration:
```bash
NATIVE_LANGUAGE=de  
FALLBACK_LANGUAGE=en
```

**Results:**
- German movie: "Das Boot (1981)" *(uses German title)*
- Spanish movie: "Pan's Labyrinth (2006)" *(uses English title)*

## 📊 Logging & Troubleshooting

### Log Levels

The scripts provide detailed logging for troubleshooting:

```
[2024-01-15 10:30:15] 🔤 Language preference: es → en
[2024-01-15 10:30:15] 🌍 Movie is originally in es - using native language preference
[2024-01-15 10:30:15] ✅ Using original title (native language)
[2024-01-15 10:30:15] 🏗️  Building folder name...
[2024-01-15 10:30:15] ✅ Using collection format: Collection (Year) - Title
[2024-01-15 10:30:15] ✅ Added quality tag: [1080p]
[2024-01-15 10:30:15] 🔄 Destination → D:\Movies\El Laberinto del Fauno (2006) [1080p]
```

### Common Exit Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 1 | Git Bash not found | Check `GIT_BASH_PATH` in config |
| 2 | Script file not found | Check `RENAME_BAT_PATH` and `RENAME_SH_PATH` |
| 3 | jq not installed | Install jq from https://stedolan.github.io/jq/download/ |
| 4 | curl not installed | curl should be available in Git Bash by default |
| 5 | RADARR_API_KEY not configured | Set valid API key in config.env |
| 90 | Failed to connect to Radarr API | Check `RADARR_URL` and `RADARR_API_KEY` |
| 95 | File not found in destination | Check source files and permissions |
| 96 | Source directory not found | Check movie paths in Radarr |
| 97 | Failed to create destination directory | Check disk space and permissions |

## 🔄 Integration with Radarr

The scripts support two different usage patterns:

### Automatic Processing (Individual Movies)

Configure Radarr to automatically rename movies when they are imported, upgraded, or renamed:

1. **In Radarr**: Go to `Settings` → `Connect` → `Add Connection` → `Custom Script`

2. **Configure the connection**:
   ```
   Name: Auto Rename Folders
   Path: C:\path\to\your\scripts\rename-radarr-folders.bat
   
   Triggers:
   ✅ On Import
   ✅ On Upgrade  
   ✅ On Rename
   
   Arguments: (leave empty - Radarr passes them automatically)
   ```

3. **How it works**:
   - Radarr automatically calls the `.bat` script for each individual movie
   - The script reads configuration from `config.env` automatically
   - Radarr passes movie parameters (`radarr_movie_id`, `radarr_movie_title`, etc.) to the script
   - Processes only the specific movie that triggered the event
   - Runs in the background without user interaction
   - Updates Radarr database with new folder location

### Manual Bulk Processing (All Movies)

Use `run.ps1` when you want to process your entire library:

```powershell
# Process all movies in Radarr
.\run.ps1

# Use custom configuration file
.\run.ps1 -ConfigFile "my-personal.env"
```

### When to Use Each Method

| Method | Use Case | Scope | Trigger |
|--------|----------|-------|---------|
| **Radarr Integration** | Automatic maintenance | Single movie | Import/Upgrade/Rename events |
| **Manual Bulk** | Initial setup, mass reorganization | All movies | Manual execution |

## 🔧 Advanced Usage

### Custom Configuration Files

You can create personal configuration files for different setups:

```powershell
# Copy the template and customize it
copy config.env my-personal.env

# Edit my-personal.env with your specific settings
# Then use it with run.ps1
.\run.ps1 -ConfigFile "my-personal.env"
```

**Note**: Personal config files (ending in `-personal.env` or `.local.env`) are automatically ignored by Git to protect your API keys and settings.

### TMDB Integration

**Important**: TMDB integration is **required for multi-language support**. Without TMDB, the script only uses titles from Radarr (typically English).

```bash
TMDB_API_KEY=your_tmdb_api_key_here
```

**What TMDB enables:**
- **Multi-language titles**: Access to movie titles in different languages (Spanish, German, French, etc.)
- **Native language detection**: Ability to use original titles for movies in your native language
- **Alternative titles**: Access to regional and alternative movie titles
- **Language fallback system**: The full language preference system described in this guide

**Without TMDB:**
- Only uses titles available in Radarr database (usually English)
- `NATIVE_LANGUAGE` and `FALLBACK_LANGUAGE` settings have no effect
- No international title support

### Auto-Detection from Radarr

```bash
AUTO_DETECT_FROM_RADARR=true
NATIVE_LANGUAGE=  # Will be auto-detected
```

The script will attempt to read your language preference from Radarr's UI settings.

## 🛠️ Development

### Script Architecture

1. **PowerShell Layer** (`run.ps1`): Configuration loading and bulk movie enumeration
2. **Batch Layer** (`rename-radarr-folders.bat`): Windows compatibility, logging wrapper, and Radarr integration
3. **Bash Layer** (`rename-radarr-folders.sh`): Core logic for renaming and file operations

### Execution Flow

#### Radarr Automatic Mode:
```
Radarr Event → .bat → .sh → File Operations → Radarr API Update
```

#### Manual Bulk Mode:
```
run.ps1 → Radarr API (get all movies) → .bat (per movie) → .sh → File Operations
```

### Key Functions

- `get_preferred_title()`: Language-aware title selection
- `build_folder_name()`: Configurable folder name generation
- `sanitize()`: Windows-compatible filename cleaning
- `detect_radarr_language_preference()`: Auto-detection from Radarr

## 📝 License

This project is provided as-is for personal use. Feel free to modify and adapt to your needs.

## 🤝 Contributing

Contributions welcome! Please ensure:
- All comments and code in English
- Maintain backward compatibility
- Update documentation for new features
- Test with different language configurations

## ⚠️ Important Notes

- **USE AT YOUR OWN RISK**: This script works well for the author's setup but may behave differently in your environment
- **Backup Everything**: Always backup your Radarr database and movie library before running scripts
- **Test Extensively**: Use a small subset of movies (5-10) for initial testing and validation
- **Path Safety**: Ensure all paths in config.env are correct for your system
- **API Limits**: Be mindful of API rate limits when processing large libraries
- **Different Results**: Your library structure, naming conventions, and Radarr configuration may produce different results than expected

## 🆘 Support

**Remember: Use at your own risk. These scripts work for the author's specific setup but may not work identically in all environments.**

Check the log files for detailed error information. Most issues are configuration-related and can be resolved by:

1. **First**: Ensure you followed all safety steps (backups, small test group)
2. Verifying API keys and URLs
3. Checking file/folder permissions  
4. Ensuring all paths exist and are accessible
5. Validating Git Bash installation
6. Testing with a different movie or subset to isolate issues

If something goes wrong:
- Restore from your Radarr database backup
- Check the detailed logs for specific error messages
- Verify your configuration matches your actual setup

## 💖 Support the Project

If this project helped you organize your movie library and you'd like to support continued development, consider sponsoring! Your support helps maintain and improve these scripts.

**[💖 Sponsor this project on GitHub](https://github.com/sponsors/ravioldev)**

Every contribution, no matter how small, is greatly appreciated and helps keep this project active and improving! 🙏

---

*Thank you for using the Radarr Folder Rename System!* 