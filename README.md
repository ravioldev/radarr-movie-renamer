# Radarr Movie Folders Renamer

**Automatically organize and rename your existing Radarr movie collection with intelligent, standardized folder naming patterns.**

## 🎯 What This Project Does

**Radarr Movie Folders Renamer** transforms your messy movie folder collection into a beautifully organized library. It automatically renames movie folders using consistent patterns that make your collection easier to browse, search, and manage.

### 📁 Transform Your Movie Library

**Before (messy, inconsistent names):**
```
/movies/Iron.Man.2008.1080p.BluRay.x264-GROUP/
/movies/The Dark Knight (2008)/
/movies/avengers_endgame_2019_4k/
/movies/LOTR.Fellowship.2001.Extended.BluRay/
/movies/Parasite.2019.Korean.1080p/
```

**After (organized, standardized patterns):**
```
/movies/Marvel Cinematic Universe (2008) - Iron Man [1080p]/
/movies/The Dark Knight (2008) [1080p]/
/movies/Marvel Cinematic Universe (2019) - Avengers Endgame [2160p]/
/movies/The Lord of the Rings Collection (2001) - Fellowship of the Ring [1080p]/
/movies/Parasite (2019) [1080p]/
```

### ✨ Key Benefits

- **🎬 Collection Organization**: Group franchise movies together (Marvel, DC, Star Wars, etc.)
- **🏷️ Quality Tags**: Clear quality indicators (2160p, 1080p, 720p, DVD-Rip, etc.)
- **🌍 Multi-Language Support**: Use native language titles for foreign films
- **📁 Consistent Naming**: Uniform folder structure across your entire library
- **🔄 Radarr Integration**: Works seamlessly with your existing Radarr setup
- **🛡️ Safe Testing**: Test with small subsets before processing entire library

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
├── config.env                    # Main configuration file (template)
├── run.ps1                      # PowerShell launcher for bulk processing
├── rename-radarr-folders.bat    # Windows batch wrapper for individual movies
├── rename-radarr-folders.sh     # Main bash script with all logic
├── get-movie-ids.ps1            # Testing utility: List movies with IDs
├── get-single-movie.ps1         # Testing utility: Get single movie info
├── logs/                        # Log files directory (created automatically)
└── README.md                    # Complete documentation
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
# Process all movies in your Radarr library
.\run.ps1

# Test mode: Process only first 5 movies (recommended for testing)
.\run.ps1 -MaxMovies 5

# Test mode: Process only first 10 movies
.\run.ps1 -MaxMovies 10
```

**🧪 Testing Recommendation**: Always use `-MaxMovies` parameter first to test with a small subset before processing your entire library.

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

## 🛡️ Path and Character Support

### Spaces in Paths
All scripts fully support paths with spaces without any special configuration:

```bash
# These paths work perfectly:
SCRIPTS_DIR=D:\my scripts\rename script\
LOG_FILE=C:\Program Files (x86)\Logs\rename-radarr-folders.log
GIT_BASH_PATH=C:\Program Files\Git\bin\bash.exe
```

**No quotes or escaping needed** - the scripts handle spaces automatically.

### Special Characters in Movie Titles
The scripts handle special characters in movie titles correctly:

- ✅ **Single quotes**: `'71 (2014)` → `'71 (2014) [1080p]`
- ✅ **Commas**: `10,000 BC (2008)` → `10,000 BC (2008) [1080p]`
- ✅ **Periods**: `10.0 Earthquake (2014)` → `10.0 Earthquake (2014) [1080p]`
- ✅ **Hyphens**: `11-11-11 (2011)` → `11-11-11 (2011) [480p]`
- ✅ **Unicode characters**: Properly sanitized for Windows compatibility

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
The Lord of the Rings Collection (2001) - Fellowship of the Ring [2160p]  # Has collection  
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
Fellowship of the Ring (2001) [2160p]         # Collection ignored
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

#### Individual Script Exit Codes (rename-radarr-folders.bat/.sh)

| Code | Meaning | Solution |
|------|---------|----------|
| 0 | Success | Movie processed successfully |
| 1 | Git Bash not found | Check `GIT_BASH_PATH` in config |
| 2 | Script file not found | Check `RENAME_BAT_PATH` and `RENAME_SH_PATH` |
| 3 | jq not installed | Install jq from https://stedolan.github.io/jq/download/ |
| 4 | curl not installed | curl should be available in Git Bash by default |
| 5 | RADARR_API_KEY not configured | Set valid API key in config.env |
| 90 | Failed to connect to Radarr API | Check `RADARR_URL` and `RADARR_API_KEY` |
| 95 | File not found in destination | Check source files and permissions |
| 96 | Source directory not found | Check movie paths in Radarr |
| 97 | Failed to create destination directory | Check disk space and permissions |
| 98 | Missing required parameter | Check movie ID, title, or year parameters |

#### Bulk Processing Exit Codes (run.ps1)

| Code | Meaning | Details |
|------|---------|---------|
| 0 | All movies processed successfully | No errors encountered |
| 1 | One or more movies failed | Check logs for specific failures; some movies may have succeeded |

**Note**: `run.ps1` shows detailed success/error counts: `✅ Success: 8 movies` / `❌ Errors: 2 movies`

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
   ✅ On Update
   ✅ On Rename
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

# Test mode: Process only first 5 movies (recommended for testing)
.\run.ps1 -MaxMovies 5

# Use custom configuration file
.\run.ps1 -ConfigFile "my-personal.env"

# Combine MaxMovies with custom config for testing
.\run.ps1 -ConfigFile "my-personal.env" -MaxMovies 10
```

### When to Use Each Method

| Method | Use Case | Scope | Trigger |
|--------|----------|-------|---------|
| **Radarr Integration** | Automatic maintenance | Single movie | Import/Upgrade/Rename events |
| **Manual Bulk** | Initial setup, mass reorganization | All movies | Manual execution |

## 🔧 Advanced Usage

### Test Mode with MaxMovies Parameter

**🧪 Always test with a subset first!** The `run.ps1` script includes a `-MaxMovies` parameter for safe testing:

```powershell
# Test with just 3 movies first
.\run.ps1 -MaxMovies 3

# Test with 10 movies after initial validation
.\run.ps1 -MaxMovies 10

# Only after successful testing, process all movies
.\run.ps1
```

**Benefits of MaxMovies:**
- ✅ **Safe testing**: Verify configuration with small subset
- ✅ **Quick validation**: Check folder naming patterns before full run
- ✅ **Error isolation**: Identify issues without affecting entire library
- ✅ **Progress monitoring**: See detailed processing logs for each movie

### Custom Configuration Files

You can create personal configuration files for different setups:

```powershell
# Copy the template and customize it
copy config.env my-personal.env

# Edit my-personal.env with your specific settings
# Then use it with run.ps1
.\run.ps1 -ConfigFile "my-personal.env"

# Combine with MaxMovies for safe testing
.\run.ps1 -ConfigFile "my-personal.env" -MaxMovies 5
```

**Note**: Personal config files (ending in `-personal.env` or `.local.env`) are automatically ignored by Git to protect your API keys and settings.

### TMDB Integration

**Important**: TMDB integration is **required for native language support**. The script intelligently calls TMDB **only for movies in your native language**.

```bash
TMDB_API_KEY=your_tmdb_api_key_here
NATIVE_LANGUAGE=es  # Your native language (e.g., es, de, fr, pt, ja)
```

**How TMDB Integration Works:**

🎯 **Smart Language Detection:**
- **Native Language Movies**: If `originalLanguage` matches `NATIVE_LANGUAGE`, calls TMDB for native title
- **Other Movies**: Uses English/fallback titles from Radarr (no TMDB call needed)

**Example with `NATIVE_LANGUAGE=es`:**
```bash
# Spanish movie (originalLanguage=es) → Calls TMDB for Spanish title
El Laberinto del Fauno (2006) → "El Laberinto del Fauno" (from TMDB)

# French movie (originalLanguage=fr) → Uses English title from Radarr  
Amélie (2001) → "Amélie" (from Radarr, no TMDB call)

# English movie (originalLanguage=en) → Uses English title from Radarr
The Dark Knight (2008) → "The Dark Knight" (from Radarr, no TMDB call)
```

**Benefits:**
- **Efficient**: Only calls TMDB when needed (native language movies)
- **Accurate**: Gets proper native language titles from TMDB
- **Fast**: Reduces API calls by 80-90% compared to calling TMDB for every movie
- **Reliable**: Falls back to Radarr titles if TMDB fails

**Without TMDB:**
- Native language movies use `originalTitle` from Radarr (may be English)
- `NATIVE_LANGUAGE` setting still works but with limited accuracy
- All other functionality remains the same

## 🏷️ Quality Tag Detection

The script automatically detects video quality from Radarr's quality profiles and file metadata to add quality tags to folder names.

### Supported Quality Tags

| Quality Tag | Detection Pattern | Source |
|-------------|-------------------|---------|
| **2160p** | Contains "2160" or "4k" | Quality profile name or video resolution |
| **1440p** | Contains "1440" | Quality profile name or video resolution |
| **1080p** | Contains "1080", "bluray", "webdl", "webrip" | Quality profile name or video resolution |
| **720p** | Contains "720" | Quality profile name or video resolution |
| **DVD-Rip** | Contains "576" or "dvd" | Quality profile name or video resolution |
| **480p** | Contains "480" or "sdtv" | Quality profile name or video resolution |
| **LowQuality** | Everything else | Fallback for unrecognized formats |

### How Quality Detection Works

The script uses **automatic detection** - no specific Radarr quality profile configuration required:

1. **Primary Source**: Radarr's quality profile name (e.g., "Ultra-HD", "HD-1080p", "HD-720p")
2. **Secondary Source**: Video file resolution metadata (from MediaInfo)
3. **Case-insensitive matching**: Works with any naming convention
4. **Fallback**: If no pattern matches, defaults to "LowQuality"

### Examples

```bash
# These Radarr quality profiles would be detected as:
"Ultra-HD" → 2160p          # Contains "4k" or "2160"
"HD-1080p" → 1080p          # Contains "1080"  
"WEBDL-1080p" → 1080p       # Contains "webdl"
"Bluray-1080p" → 1080p      # Contains "bluray"
"WebRip-1080p" → 1080p      # Contains "webrip"
"HD-720p" → 720p            # Contains "720"
"DVD" → DVD-Rip             # Contains "dvd"
"DVD-576p" → DVD-Rip        # Contains "576"
"HDTV-480p" → 480p          # Contains "480"
"SDTV" → 480p               # Contains "sdtv"
"Custom Quality" → LowQuality  # No recognizable pattern
```

**Note**: Quality detection is **automatic** and works with any Radarr quality profile names or video resolutions. You don't need to configure specific profiles.

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

### Testing Utilities

Two optional PowerShell helper scripts are included for safe testing:

| Script | Purpose |
|--------|---------|
| `get-movie-ids.ps1` | Lists movies in Radarr, shows ID, path, quality and generates a ready-to-paste command for each title so you can run the rename script on a single movie. |
| `get-single-movie.ps1` | Displays detailed information for one movie ID and prints the exact command plus the expected new folder name according to your current configuration. |

#### get-movie-ids.ps1

```powershell
# List first 10 movies (default)
./get-movie-ids.ps1

# List movies containing the word "Matrix"
./get-movie-ids.ps1 -SearchTitle "Matrix"

# Show up to 50 results
./get-movie-ids.ps1 -MaxResults 50
```

#### get-single-movie.ps1

```powershell
# Inspect movie with ID 123
./get-single-movie.ps1 -MovieId 123
```

Both scripts are **read-only**: they never modify files or folders.  
They simply query Radarr's API using the credentials stored in `config.env`.

Use them to verify IDs, preview commands and confirm what the rename script will do before touching your library.

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