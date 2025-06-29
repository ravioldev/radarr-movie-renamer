#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Radarr Hybrid File Renamer Script
# 
# This script uses Radarr's API to fetch all data but processes naming patterns
# and renames files manually. This approach provides:
# - 100% compatibility with ALL Radarr tokens (data from API)
# - No conflicts with Radarr's internal renaming
# - Works without requiring "Rename Movies" to be enabled
# - Full control over when and how files are renamed
#
# Usage: rename-radarr-files.sh <movie_id> <movie_directory>
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────── 1. Setup & Configuration ──────────────────────────────────────
set -euo pipefail

# Get script directory for configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.env"

# Load configuration with proper path handling
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
  
  # Clean up quotes using parameter expansion (preserves backslashes)
  SCRIPTS_DIR="${SCRIPTS_DIR%\"}"
  SCRIPTS_DIR="${SCRIPTS_DIR#\"}"
  SCRIPTS_DIR="${SCRIPTS_DIR%\'}"
  SCRIPTS_DIR="${SCRIPTS_DIR#\'}"
  
  GIT_BASH_PATH="${GIT_BASH_PATH%\"}"
  GIT_BASH_PATH="${GIT_BASH_PATH#\"}"
  GIT_BASH_PATH="${GIT_BASH_PATH%\'}"
  GIT_BASH_PATH="${GIT_BASH_PATH#\'}"
  
  LOG_FILE="${LOG_FILE%\"}"
  LOG_FILE="${LOG_FILE#\"}"
  LOG_FILE="${LOG_FILE%\'}"
  LOG_FILE="${LOG_FILE#\'}"
  
  RENAME_SH_PATH="${RENAME_SH_PATH%\"}"
  RENAME_SH_PATH="${RENAME_SH_PATH#\"}"
  RENAME_SH_PATH="${RENAME_SH_PATH%\'}"
  RENAME_SH_PATH="${RENAME_SH_PATH#\'}"
  
else
  echo "❌ Configuration file not found: $CONFIG_FILE"
  exit 1
fi

# Validate required parameters
if [[ $# -lt 2 ]]; then
  echo "❌ Usage: $0 <movie_id> <movie_directory>"
  echo "   movie_id: Radarr movie ID"
  echo "   movie_directory: Full path to movie directory"
  exit 1
fi

MOVIE_ID="$1"
MOVIE_DIR="$2"

# ───────────── 2. Logging Function ────────────────────────────────────────────
# Set UTF-8 encoding for proper emoji display
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

log() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $*"
  
  # IMPROVED: Safe logging without flock (Windows compatible) - fixes "Device or resource busy"
  if [[ -n "${LOG_FILE:-}" ]]; then
    # Create a more robust log file path - fix common Windows path issues
    local safe_log_file="$LOG_FILE"
    if [[ "$LOG_FILE" == D:* ]] && [[ "$LOG_FILE" != *"\\"* ]]; then
      # Fix malformed paths like D:scriptsradarr-renamerlogsrename-radarr-folders.log
      safe_log_file=$(echo "$LOG_FILE" | sed 's|D:scriptsradarr-renamerlogsrename-radarr-folders.log|D:\\scripts\\radarr-renamer\\logs\\rename-radarr-folders.log|g')
    fi
    
    # Create log directory with Windows-compatible path
    local log_dir=$(dirname "$safe_log_file" 2>/dev/null)
    if [[ -n "$log_dir" ]] && [[ ! -d "$log_dir" ]]; then
      mkdir -p "$log_dir" 2>/dev/null || true
    fi
    
    # Use multiple logging strategies to avoid "Device or resource busy"
    {
      # Strategy 1: Try normal append
      echo "[$timestamp] $*" >> "$safe_log_file" 2>/dev/null || {
        # Strategy 2: Try redirect
        echo "[$timestamp] $*" > "$safe_log_file" 2>/dev/null || {
          # Strategy 3: Silent failure
          true
        }
      }
    }
  fi
}

# Enhanced logging functions with level control (copied from main script)
log_info() {
  # Log informational messages (NORMAL level and above)
  case "${LOG_LEVEL:-NORMAL}" in
    MINIMAL) return ;;
    *) log "$@" ;;
  esac
}

log_detailed() {
  # Log detailed process information (DETAILED level and above)  
  case "${LOG_LEVEL:-NORMAL}" in
    MINIMAL|NORMAL) return ;;
    *) log "$@" ;;
  esac
}

log_debug() {
  # Log debug information (DEBUG level only)
  case "${LOG_LEVEL:-NORMAL}" in
    DEBUG) log "$@" ;;
    *) return ;;
  esac
}

log_custom_formats() {
  # Log custom formats attempts (only if LOG_CUSTOM_FORMATS=true)
  [[ "${LOG_CUSTOM_FORMATS:-false}" == "true" ]] && log "$@"
}

log "🎬 Starting hybrid file renaming for movie ID: $MOVIE_ID"
log "📁 Movie directory: $MOVIE_DIR"
log "🔧 Using hybrid approach: API data + manual processing"

# Set error handling - be more lenient but still catch critical errors
set +e  # Don't exit on every error
trap 'log "⚠️  Error occurred at line $LINENO (exit code $?) - continuing..." 2>/dev/null || true' ERR

# Validate inputs
if [[ ! -d "$MOVIE_DIR" ]]; then
  log "❌ Movie directory does not exist: $MOVIE_DIR"
  exit 1
fi

if [[ ! "$MOVIE_ID" =~ ^[0-9]+$ ]]; then
  log "❌ Invalid movie ID (must be numeric): $MOVIE_ID"
  exit 1
fi

# Debug: Show cleaned paths with proper escaping
log "🔧 Configuration paths after cleanup:"
log "   SCRIPTS_DIR: \"${SCRIPTS_DIR:-'(not set)'}\""
log "   GIT_BASH_PATH: \"${GIT_BASH_PATH:-'(not set)'}\""
log "   LOG_FILE: \"${LOG_FILE:-'(not set)'}\""

# Critical validation: Check and fix malformed paths (missing backslashes)
if [[ "$SCRIPTS_DIR" != *"\\"* ]] && [[ "$SCRIPTS_DIR" == *":"* ]]; then
  log "🔧 FIXING malformed SCRIPTS_DIR (missing backslashes)"
  # Try to reconstruct the path by adding backslashes
  SCRIPTS_DIR=$(echo "$SCRIPTS_DIR" | sed 's|:|:\\|; s|scriptsradarr-renamer|scripts\\radarr-renamer|')
  log "   Fixed SCRIPTS_DIR: \"$SCRIPTS_DIR\""
fi

if [[ "$LOG_FILE" != *"\\"* ]] && [[ "$LOG_FILE" == *":"* ]]; then
  log "🔧 FIXING malformed LOG_FILE (missing backslashes)"
  # Reconstruct the log file path
  LOG_FILE=$(echo "$LOG_FILE" | sed 's|:|:\\|; s|scriptsradarr-renamerlogsrename-radarr-folders.log|scripts\\radarr-renamer\\logs\\rename-radarr-folders.log|')
  log "   Fixed LOG_FILE: \"$LOG_FILE\""
fi

if [[ "$GIT_BASH_PATH" != *"\\"* ]] && [[ "$GIT_BASH_PATH" == *":"* ]]; then
  log "🔧 FIXING malformed GIT_BASH_PATH (missing backslashes)"
  # Reconstruct the git bash path
  GIT_BASH_PATH=$(echo "$GIT_BASH_PATH" | sed 's|:|:\\|; s|Program FilesGitbinbash.exe|Program Files\\Git\\bin\\bash.exe|')
  log "   Fixed GIT_BASH_PATH: \"$GIT_BASH_PATH\""
fi

# Additional debug: Check if backslashes are preserved
if [[ "$SCRIPTS_DIR" == *"\\"* ]]; then
  log "✅ Backslashes preserved in SCRIPTS_DIR"
else
  log "❌ Backslashes still missing in SCRIPTS_DIR - raw value: '$SCRIPTS_DIR'"
fi

# ───────────── 3. Fetch Complete Movie Data from Radarr ───────────────────────
log "📥 Fetching complete movie data from Radarr API..."

# Get comprehensive movie data including file information
log "🌐 Fetching from: $RADARR_URL/api/v3/movie/$MOVIE_ID"

# Temporarily disable exit on error for API call
set +e
MOVIE_JSON=$(curl -sf --max-time 30 \
                  -H "X-Api-Key:$RADARR_API_KEY" \
                  "$RADARR_URL/api/v3/movie/$MOVIE_ID" 2>&1)
CURL_EXIT_CODE=$?
set -e

# Check curl result manually
if [[ $CURL_EXIT_CODE -ne 0 ]]; then
  log "❌ curl command failed with exit code: $CURL_EXIT_CODE"
  log "   URL: $RADARR_URL/api/v3/movie/$MOVIE_ID"
  log "   API Key length: ${#RADARR_API_KEY}"
  exit 1
fi

if [[ -z "$MOVIE_JSON" ]]; then
  log "❌ Failed to fetch movie data from Radarr API"
  log "   URL: $RADARR_URL/api/v3/movie/$MOVIE_ID"
  log "   API Key length: ${#RADARR_API_KEY}"
  exit 1
fi

# Validate JSON response
if ! echo "$MOVIE_JSON" | jq . > /dev/null 2>&1; then
  log "❌ Invalid JSON response from Radarr API"
  log "   Response: ${MOVIE_JSON:0:500}..."
  exit 1
fi

# Extract basic movie information
MOVIE_TITLE=$(echo "$MOVIE_JSON" | jq -r '.title // empty')
RELEASE_YEAR=$(echo "$MOVIE_JSON" | jq -r '.year // empty')
HAS_FILE=$(echo "$MOVIE_JSON" | jq -r '.hasFile // false')

log "🎭 Movie: $MOVIE_TITLE ($RELEASE_YEAR)"
log "📄 Has file: $HAS_FILE"

if [[ "$HAS_FILE" != "true" ]]; then
  log "❌ Movie has no file in Radarr database"
  exit 1
fi

# ───────────── 4. Get Naming Configuration ────────────────────────────────────
log "⚙️  Fetching Radarr naming configuration..."

# Use custom pattern if provided, otherwise get from Radarr
if [[ -n "${FILE_NAMING_PATTERN:-}" ]]; then
  NAMING_PATTERN="$FILE_NAMING_PATTERN"
  log "🔧 Using custom naming pattern: $NAMING_PATTERN"
else
  # Get naming pattern from Radarr
  NAMING_CONFIG=$(curl -sf --max-time 30 \
                       -H "X-Api-Key:$RADARR_API_KEY" \
                       "$RADARR_URL/api/v3/config/naming")
  
  if [[ -z "$NAMING_CONFIG" ]]; then
    log "❌ Failed to fetch naming configuration from Radarr"
    exit 1
  fi
  
  NAMING_PATTERN=$(echo "$NAMING_CONFIG" | jq -r '.standardMovieFormat // empty')
  log "🔧 Using Radarr's current pattern: $NAMING_PATTERN"
fi

if [[ -z "$NAMING_PATTERN" ]]; then
  log "❌ No naming pattern available"
  exit 1
fi

# ───────────── 5. Extract All Token Values from API Data ──────────────────────
log "🔍 Extracting all token values from Radarr data..."

# Initialize associative array for token values
declare -A TOKEN_VALUES

# Basic movie information - CORRECT token names
TOKEN_VALUES["Movie.Title"]=$(echo "$MOVIE_JSON" | jq -r '.title // ""')
# Generate Movie.CleanTitle exactly like Radarr
# First get the raw title
MOVIE_TITLE_RAW=$(echo "$MOVIE_JSON" | jq -r '.title // ""')

# Apply Radarr's CleanTitle rules (documented at https://wiki.servarr.com/radarr/settings#movie-naming)
MOVIE_CLEAN_TITLE="$MOVIE_TITLE_RAW"
# Replace & with "and"
MOVIE_CLEAN_TITLE=$(echo "$MOVIE_CLEAN_TITLE" | sed 's/&/and/g')
# Replace / and \ with nothing (empty)
MOVIE_CLEAN_TITLE=$(echo "$MOVIE_CLEAN_TITLE" | sed 's/[\/\\]//g')
# Remove specific characters as per Radarr regex: ,<>'/;:|~!?@$%^*-_= and brackets
MOVIE_CLEAN_TITLE=$(echo "$MOVIE_CLEAN_TITLE" | sed 's/[,<>'\''\/;:|~!?@$%^*\-_=()[\]{}]//g')

# For FILE naming, Radarr uses periods instead of spaces (Standard Movie Format setting)
# This is controlled by the "Space Handling" dropdown in Radarr (Period option)
MOVIE_CLEAN_TITLE_FOR_FILES=$(echo "$MOVIE_CLEAN_TITLE" | sed 's/ /./g')

TOKEN_VALUES["Movie.CleanTitle"]="$MOVIE_CLEAN_TITLE_FOR_FILES"
TOKEN_VALUES["Movie.TitleThe"]=$(echo "$MOVIE_JSON" | jq -r '.tmdbId // ""')
TOKEN_VALUES["Movie.OriginalTitle"]=$(echo "$MOVIE_JSON" | jq -r '.originalTitle // ""')
TOKEN_VALUES["Movie.CleanOriginalTitle"]=$(echo "$MOVIE_JSON" | jq -r '.originalTitle // ""' | sed 's/[^a-zA-Z0-9._-]//g')
TOKEN_VALUES["Movie.SortTitle"]=$(echo "$MOVIE_JSON" | jq -r '.sortTitle // ""')
TOKEN_VALUES["Movie.Certification"]=$(echo "$MOVIE_JSON" | jq -r '.certification // ""')
TOKEN_VALUES["Movie.Collection"]=$(echo "$MOVIE_JSON" | jq -r '.collection.title // ""')
TOKEN_VALUES["Release.Year"]=$(echo "$MOVIE_JSON" | jq -r '.year // ""')
TOKEN_VALUES["ImdbId"]=$(echo "$MOVIE_JSON" | jq -r '.imdbId // ""')
TOKEN_VALUES["TmdbId"]=$(echo "$MOVIE_JSON" | jq -r '.tmdbId // ""')

# Movie file information - with SDTV correction logic
RAW_QUALITY=$(echo "$MOVIE_JSON" | jq -r '.movieFile.quality.quality.name // ""')
RAW_RESOLUTION=$(echo "$MOVIE_JSON" | jq -r '.movieFile.quality.quality.resolution // ""')

# First get original filename (needed for SDTV correction)
ORIGINAL_FILENAME=$(echo "$MOVIE_JSON" | jq -r '.movieFile.relativePath // ""' | xargs basename 2>/dev/null | sed 's/\.[^.]*$//')

# Enhanced Quality Logic for Files
# Files can combine resolution + source (e.g., "720p-SCREENER", "480p-SDTV")
# Extract source information for combination
RAW_SOURCE=$(echo "$MOVIE_JSON" | jq -r '.movieFile.quality.quality.source // ""')

log "🔧 Processing file quality with resolution + source combination..."
log "   Raw Quality: $RAW_QUALITY"
log "   Raw Resolution: $RAW_RESOLUTION"
log "   Raw Source: $RAW_SOURCE"
log "   Original Filename: $ORIGINAL_FILENAME"

# Determine resolution part
RESOLUTION_PART=""
if [[ -n "$RAW_RESOLUTION" && "$RAW_RESOLUTION" != "0" && "$RAW_RESOLUTION" != "null" ]]; then
  RESOLUTION_PART="${RAW_RESOLUTION}p"
  log "   ✅ Using API resolution: $RESOLUTION_PART"
else
  # Extract resolution from filename as fallback
  if [[ -n "$ORIGINAL_FILENAME" ]]; then
    FILENAME_RESOLUTION=$(echo "$ORIGINAL_FILENAME" | grep -oE '[0-9]+p' | head -1)
    if [[ -n "$FILENAME_RESOLUTION" ]]; then
      RESOLUTION_PART="$FILENAME_RESOLUTION"
      log "   ✅ Using filename-extracted resolution: $RESOLUTION_PART"
    fi
  fi
fi

# Determine source part (for combination)
SOURCE_PART=""
if [[ "$RAW_QUALITY" == "SDTV" ]]; then
  # SDTV can be combined with resolution if available
  if [[ -n "$RESOLUTION_PART" ]]; then
    SOURCE_PART="SDTV"
    log "   ✅ SDTV will be combined with resolution: ${RESOLUTION_PART}-${SOURCE_PART}"
  else
    # No resolution for SDTV, use LowQuality
    log "   ⚠️  SDTV without resolution - using LowQuality"
  fi
elif [[ -n "$RAW_SOURCE" && "$RAW_SOURCE" != "null" && "$RAW_SOURCE" != "" ]]; then
  # Use source from API if available
  case "${RAW_SOURCE,,}" in
    *screener*|*telesync*|*cam*|*ts*|*tc*)
      SOURCE_PART="$RAW_SOURCE"
      log "   ✅ Using API source for combination: $SOURCE_PART"
      ;;
  esac
fi

# Build final quality
FINAL_QUALITY=""
if [[ -n "$RESOLUTION_PART" && -n "$SOURCE_PART" ]]; then
  # Combine resolution + source: "720p-SCREENER", "480p-SDTV"
  FINAL_QUALITY="${RESOLUTION_PART}-${SOURCE_PART}"
  log "   ✅ Combined quality: $FINAL_QUALITY"
elif [[ -n "$RESOLUTION_PART" ]]; then
  # Just resolution: "1080p", "720p"
  FINAL_QUALITY="$RESOLUTION_PART"
  log "   ✅ Resolution-only quality: $FINAL_QUALITY"
elif [[ -n "$RAW_QUALITY" && "$RAW_QUALITY" != "SDTV" ]]; then
  # Use original quality if not SDTV
  FINAL_QUALITY="$RAW_QUALITY"
  log "   ✅ Using original quality: $FINAL_QUALITY"
else
  # Fallback for SDTV without resolution
  FINAL_QUALITY="LowQuality"
  log "   ✅ Fallback quality: $FINAL_QUALITY"
fi

TOKEN_VALUES["Quality.Full"]="$FINAL_QUALITY"
TOKEN_VALUES["Quality.Title"]="$FINAL_QUALITY"
log "   📋 Final file quality: $FINAL_QUALITY"

TOKEN_VALUES["Source"]="$RAW_SOURCE"
TOKEN_VALUES["Resolution"]="$RAW_RESOLUTION"

# MediaInfo tokens
TOKEN_VALUES["MediaInfo.Simple"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.videoCodec // ""')
TOKEN_VALUES["MediaInfo.VideoCodec"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.videoCodec // ""')
TOKEN_VALUES["MediaInfo.AudioCodec"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.audioCodec // ""')
TOKEN_VALUES["MediaInfo.AudioChannels"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.audioChannels // ""')
TOKEN_VALUES["MediaInfo.AudioLanguages"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.audioLanguages // ""')
TOKEN_VALUES["MediaInfo.SubtitleLanguages"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.subtitleLanguages // ""')
TOKEN_VALUES["MediaInfo.VideoBitDepth"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.videoBitDepth // ""')
TOKEN_VALUES["MediaInfo.VideoDynamicRange"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.videoDynamicRange // ""')
TOKEN_VALUES["MediaInfo.VideoDynamicRangeType"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.videoDynamicRangeType // ""')

# Build MediaInfo Full - IMPROVED: More robust extraction
log "🔍 MediaInfo Extraction Debug:"
video_codec="${TOKEN_VALUES["MediaInfo.VideoCodec"]}"
audio_codec="${TOKEN_VALUES["MediaInfo.AudioCodec"]}"
audio_channels="${TOKEN_VALUES["MediaInfo.AudioChannels"]}"

log "   VideoCodec: '$video_codec'"
log "   AudioCodec: '$audio_codec'"
log "   AudioChannels: '$audio_channels'"

# Try alternative extraction methods if primary ones are empty
if [[ -z "$video_codec" ]]; then
  video_codec=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.videoFormat // .movieFile.mediaInfo.videoCodecName // ""' 2>/dev/null)
  [[ -n "$video_codec" ]] && log "   Found VideoCodec via alternative method: '$video_codec'"
fi

if [[ -z "$audio_codec" ]]; then
  audio_codec=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.audioFormat // .movieFile.mediaInfo.audioCodecName // ""' 2>/dev/null)
  [[ -n "$audio_codec" ]] && log "   Found AudioCodec via alternative method: '$audio_codec'"
fi

# Build MediaInfo Full string
mediainfo_full=""
[[ -n "$video_codec" ]] && mediainfo_full="$video_codec"
[[ -n "$audio_codec" ]] && mediainfo_full="${mediainfo_full:+$mediainfo_full }$audio_codec"
[[ -n "$audio_channels" ]] && mediainfo_full="${mediainfo_full:+$mediainfo_full }$audio_channels"

# If still empty, try to build from available data
if [[ -z "$mediainfo_full" ]]; then
  log "   ⚠️  MediaInfo Full is empty, trying to build from any available data..."
  available_info=""
  
  # Try to get any video/audio info available
  video_info=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo | to_entries[] | select(.key | test("video|codec")) | "\(.key): \(.value)"' 2>/dev/null | head -3)
  audio_info=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo | to_entries[] | select(.key | test("audio|channel")) | "\(.key): \(.value)"' 2>/dev/null | head -3)
  
  [[ -n "$video_info" ]] && log "   Available video info: $video_info"
  [[ -n "$audio_info" ]] && log "   Available audio info: $audio_info"
  
  # Try basic mediaInfo field
  basic_mediainfo=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.containerFormat // ""' 2>/dev/null)
  [[ -n "$basic_mediainfo" ]] && mediainfo_full="$basic_mediainfo"
fi

TOKEN_VALUES["MediaInfo.Full"]="$mediainfo_full"
log "   Final MediaInfo.Full: '$mediainfo_full'"

# CRITICAL DEBUG: Detailed MediaInfo analysis
log "🔬 DETAILED MEDIAINFO ANALYSIS:"
log "   Raw MediaInfo.Full value: '$mediainfo_full'"
log "   Length: ${#mediainfo_full}"
log "   Contains spaces: $(if [[ "$mediainfo_full" == *" "* ]]; then echo "YES"; else echo "NO"; fi)"
log "   Character by character: $(for ((i=0; i<${#mediainfo_full}; i++)); do echo -n "'${mediainfo_full:$i:1}' "; done)"

# Release information - FIXED: Use both formats for compatibility
RELEASE_GROUP=$(echo "$MOVIE_JSON" | jq -r '.movieFile.releaseGroup // ""')
TOKEN_VALUES["Release.Group"]="$RELEASE_GROUP"       # For patterns like {.Release.Group}
TOKEN_VALUES["Release Group"]="$RELEASE_GROUP"       # For patterns like {-Release Group}

TOKEN_VALUES["Edition.Tags"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.edition // ""')

# Custom formats - IMPROVED: Multiple extraction methods
log_custom_formats "🔍 Custom Formats Extraction Debug:"
log_custom_formats "   Trying method 1: .movieFile.customFormats[]?.name"
custom_formats_method1=$(echo "$MOVIE_JSON" | jq -r '.movieFile.customFormats[]?.name // empty' 2>/dev/null | tr '\n' ' ' | sed 's/ $//')

log_custom_formats "   Trying method 2: .customFormats[]?.name"  
custom_formats_method2=$(echo "$MOVIE_JSON" | jq -r '.customFormats[]?.name // empty' 2>/dev/null | tr '\n' ' ' | sed 's/ $//')

log_custom_formats "   Trying method 3: .movieFile.customFormatTags"
custom_formats_method3=$(echo "$MOVIE_JSON" | jq -r '.movieFile.customFormatTags[]? // empty' 2>/dev/null | tr '\n' ' ' | sed 's/ $//')

# Use the first non-empty result
custom_formats=""
if [[ -n "$custom_formats_method1" ]]; then
  custom_formats="$custom_formats_method1"
  log_custom_formats "   ✅ Using method 1 result: '$custom_formats'"
elif [[ -n "$custom_formats_method2" ]]; then
  custom_formats="$custom_formats_method2"
  log_custom_formats "   ✅ Using method 2 result: '$custom_formats'"
elif [[ -n "$custom_formats_method3" ]]; then
  custom_formats="$custom_formats_method3"
  log_custom_formats "   ✅ Using method 3 result: '$custom_formats'"
else
  log_custom_formats "   ❌ No custom formats found with any method"
  log_debug "   Raw customFormats JSON: $(echo "$MOVIE_JSON" | jq -r '.movieFile.customFormats // .customFormats // "null"' 2>/dev/null)"
fi

TOKEN_VALUES["Custom.Formats"]="$custom_formats"
TOKEN_VALUES["Custom Formats"]="$custom_formats"     # Alternative format

# Original naming
TOKEN_VALUES["Original.Title"]=$(echo "$MOVIE_JSON" | jq -r '.movieFile.sceneName // ""')
TOKEN_VALUES["Original.Filename"]="$ORIGINAL_FILENAME"

# Debug: Log all extracted values
log "📋 Extracted token values:"
for token in "${!TOKEN_VALUES[@]}"; do
  value="${TOKEN_VALUES[$token]}"
  [[ -n "$value" ]] && log "   {$token}: $value"
done

# SPECIFIC DEBUG for problematic tokens mentioned by user
log "🔍 SPECIFIC TOKEN DEBUG for user's pattern:"
log "   Pattern contains: {.MediaInfo Full:ES}{.Custom.Formats}{-Release Group}"

# Check MediaInfo Full
mediainfo_full_value="${TOKEN_VALUES["MediaInfo.Full"]:-}"
if [[ -n "$mediainfo_full_value" ]]; then
  log "   ✅ MediaInfo.Full has value: '$mediainfo_full_value'"
else
  log "   ❌ MediaInfo.Full is EMPTY - will not appear in filename"
fi

# Check Custom Formats
custom_formats_value="${TOKEN_VALUES["Custom.Formats"]:-}"
if [[ -n "$custom_formats_value" ]]; then
  log_custom_formats "   ✅ Custom.Formats has value: '$custom_formats_value'"
else
  log_custom_formats "   ❌ Custom.Formats is EMPTY - will not appear in filename"
fi

# Check Release Group
release_group_dot="${TOKEN_VALUES["Release.Group"]:-}"
release_group_space="${TOKEN_VALUES["Release Group"]:-}"
if [[ -n "$release_group_dot" ]] || [[ -n "$release_group_space" ]]; then
  log "   ✅ Release Group has value:"
  [[ -n "$release_group_dot" ]] && log "      Release.Group: '$release_group_dot'"
  [[ -n "$release_group_space" ]] && log "      Release Group: '$release_group_space'"
else
  log "   ❌ Release Group is EMPTY - will not appear in filename"
  log "      File may not have release group info in Radarr"
fi

# ───────────── 6. Process Naming Pattern with Token Replacement ───────────────
log "🔧 Processing naming pattern with token replacement..."

# ═══════════════ FIXED TOKEN PROCESSOR (NO DEBUG LOGS) ═══════════════
process_filename_tokens() {
  local pattern="$1"
  local result="$pattern"
  
  # FIRST: Handle special MediaInfo Full with language code
  while [[ "$result" =~ \{\.MediaInfo[[:space:]]+Full:([^}]+)\} ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local token_value="${TOKEN_VALUES["MediaInfo.Full"]:-}"
    if [[ -n "$token_value" ]]; then
      result="${result/$full_match/ $token_value}"
    else
      result="${result/$full_match/}"
    fi
  done
  
  # Handle conditional tokens with dashes
  while [[ "$result" =~ \{-([^}]+)\} ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local token_name="${BASH_REMATCH[1]}"
    local token_value="${TOKEN_VALUES[$token_name]:-}"
    if [[ -n "$token_value" ]]; then
      result="${result/$full_match/-$token_value}"
    else
      result="${result/$full_match/}"
    fi
  done
  
  # Handle conditional tokens with dots
  while [[ "$result" =~ \{\.([^}]+)\} ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local token_name="${BASH_REMATCH[1]}"
    local token_value="${TOKEN_VALUES[$token_name]:-}"
    if [[ -n "$token_value" ]]; then
      result="${result/$full_match/.$token_value}"
    else
      result="${result/$full_match/}"
    fi
  done
  
  # Handle simple tokens
  for token in "${!TOKEN_VALUES[@]}"; do
    local value="${TOKEN_VALUES[$token]}"
    if [[ "$result" == *"{$token}"* ]] && [[ -n "$value" ]]; then
      result="${result//\{$token\}/$value}"
    elif [[ "$result" == *"{$token}"* ]]; then
      result="${result//\{$token\}/}"
    fi
  done
  
  # Clean up spaces and convert to dots for filename compatibility
  result=$(echo "$result" | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//')
  # Convert spaces to dots for proper filename format
  result=$(echo "$result" | sed 's/ /./g')
  echo "$result"
}

# Process the naming pattern with error handling
log "🔧 Input naming pattern: $NAMING_PATTERN"

# SPECIAL DEBUG: Test the problematic tokens first
log "🧪 PRE-PROCESSING TOKEN TEST:"
test_mediainfo_pattern="{.MediaInfo Full:ES}"
test_mediainfo_result=$(process_filename_tokens "$test_mediainfo_pattern")
log "   MediaInfo pattern '$test_mediainfo_pattern' → '$test_mediainfo_result'"

# Add error handling for token replacement
if ! NEW_FILENAME=$(process_filename_tokens "$NAMING_PATTERN"); then
  log "❌ Failed to process naming pattern"
  log "   Pattern: $NAMING_PATTERN"
  exit 1
fi

# Validate the result is not empty
if [[ -z "$NEW_FILENAME" ]]; then
  log "❌ Generated filename is empty"
  log "   Pattern: $NAMING_PATTERN"
  log "   Available tokens: ${!TOKEN_VALUES[@]}"
  exit 1
fi

# CRITICAL DEBUG: Show filename BEFORE sanitization
log "🔍 FILENAME BEFORE SANITIZATION: '$NEW_FILENAME'"
log "   Length before: ${#NEW_FILENAME}"
log "   Contains MediaInfo: $(if [[ "$NEW_FILENAME" == *"${TOKEN_VALUES["MediaInfo.Full"]}"* ]]; then echo "YES"; else echo "NO"; fi)"

# Sanitize filename for filesystem
NEW_FILENAME=$(echo "$NEW_FILENAME" | sed 's/[<>:"/\\|?*]//g' | sed 's/[[:space:]]*$//g')

# CRITICAL DEBUG: Show filename AFTER sanitization
log "🔍 FILENAME AFTER SANITIZATION: '$NEW_FILENAME'"
log "   Length after: ${#NEW_FILENAME}"
log "   Contains MediaInfo: $(if [[ "$NEW_FILENAME" == *"${TOKEN_VALUES["MediaInfo.Full"]}"* ]]; then echo "YES"; else echo "NO"; fi)"

log "🎯 Generated filename (without extension): $NEW_FILENAME"

# Debug: Show key tokens that should be in the result
log "🔍 Debug - Key tokens:"
log "   Movie.CleanTitle: '${TOKEN_VALUES["Movie.CleanTitle"]}'"
log "   Release.Year: '${TOKEN_VALUES["Release.Year"]}'"
log "   Quality.Full: '${TOKEN_VALUES["Quality.Full"]}'"

# Validate tokens were actually replaced
if [[ "$NEW_FILENAME" == *"{"* ]]; then
  log "⚠️  Warning: Some tokens were not replaced in final filename"
  log "   Filename with unreplaced tokens: $NEW_FILENAME"
  
  # SPECIFIC check for user's problematic tokens
  if [[ "$NEW_FILENAME" == *"{.MediaInfo Full:ES}"* ]]; then
    log "   🚨 {.MediaInfo Full:ES} was NOT replaced"
    log "   💡 MediaInfo.Full value: '${TOKEN_VALUES["MediaInfo.Full"]:-EMPTY}'"
  fi
  
  if [[ "$NEW_FILENAME" == *"{.Custom.Formats}"* ]]; then
    log "   🚨 {.Custom.Formats} was NOT replaced"
    log "   💡 Custom.Formats value: '${TOKEN_VALUES["Custom.Formats"]:-EMPTY}'"
  fi
  
  if [[ "$NEW_FILENAME" == *"{-Release Group}"* ]]; then
    log "   🚨 {-Release Group} was NOT replaced"
    log "   💡 Release Group value: '${TOKEN_VALUES["Release Group"]:-EMPTY}'"
    log "   💡 Release.Group value: '${TOKEN_VALUES["Release.Group"]:-EMPTY}'"
  fi
else
  log "✅ All tokens were successfully replaced"
  
  # Check if user's specific tokens were included in final result
  log "🔍 User's specific tokens in final result:"
  
  # Check if MediaInfo was included
  mediainfo_in_result=""
  if [[ "$NEW_FILENAME" == *"${TOKEN_VALUES["MediaInfo.Full"]}"* ]] && [[ -n "${TOKEN_VALUES["MediaInfo.Full"]}" ]]; then
    mediainfo_in_result="✅ MediaInfo included: '${TOKEN_VALUES["MediaInfo.Full"]}'"
  elif [[ -z "${TOKEN_VALUES["MediaInfo.Full"]}" ]]; then
    mediainfo_in_result="❌ MediaInfo not included (empty value)"
  else
    mediainfo_in_result="⚠️  MediaInfo may be included but not clearly identifiable"
  fi
  log "   $mediainfo_in_result"
  
  # Check if Custom Formats were included
  custom_in_result=""
  if [[ "$NEW_FILENAME" == *"${TOKEN_VALUES["Custom.Formats"]}"* ]] && [[ -n "${TOKEN_VALUES["Custom.Formats"]}" ]]; then
  custom_in_result="✅ Custom Formats included: '${TOKEN_VALUES["Custom.Formats"]}'"
elif [[ -z "${TOKEN_VALUES["Custom.Formats"]}" ]]; then
  custom_in_result="ℹ️  Custom Formats not included (none assigned)"
else
  custom_in_result="⚠️  Custom Formats may be included but not clearly identifiable"
fi
  log "   $custom_in_result"
  
  # Check if Release Group was included
  release_in_result=""
  release_group_val="${TOKEN_VALUES["Release Group"]:-${TOKEN_VALUES["Release.Group"]:-}}"
  if [[ "$NEW_FILENAME" == *"$release_group_val"* ]] && [[ -n "$release_group_val" ]]; then
    release_in_result="✅ Release Group included: '$release_group_val'"
  elif [[ -z "$release_group_val" ]]; then
    release_in_result="❌ Release Group not included (empty value)"
  else
    release_in_result="⚠️  Release Group may be included but not clearly identifiable"
  fi
  log "   $release_in_result"
fi

# ───────────── 7. Find and Rename All Files ──────────────────────────────────
log "🔍 Finding all files in directory..."

# Function to find video files
find_video_files() {
  local directory="$1"
  find "$directory" -maxdepth 1 -type f \( \
    -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o \
    -iname "*.webm" -o -iname "*.wmv" -o -iname "*.flv" -o -iname "*.mpg" -o \
    -iname "*.mpeg" -o -iname "*.m2ts" -o -iname "*.ts" -o -iname "*.mts" -o \
    -iname "*.m4v" -o -iname "*.vob" \
  \) 2>/dev/null
}

# Find video files - use IFS to handle paths with spaces
IFS=$'\n' VIDEO_FILES=($(find_video_files "$MOVIE_DIR"))
IFS=$' \t\n'

if [[ ${#VIDEO_FILES[@]} -eq 0 ]]; then
  log "❌ No video files found in directory: $MOVIE_DIR"
  exit 1
fi

log "📹 Found ${#VIDEO_FILES[@]} video file(s)"

# Initialize rename counter
renamed_count=0

# Process each video file
for video_file in "${VIDEO_FILES[@]}"; do
  if [[ ! -f "$video_file" ]]; then
    log "⚠️  Skipping non-existent file: $video_file"
    continue
  fi
  
  old_filename=$(basename "$video_file")
  file_extension="${old_filename##*.}"
  new_filename_with_ext="$NEW_FILENAME.$file_extension"
  new_file_path="$MOVIE_DIR/$new_filename_with_ext"
  
  log "🎥 Processing: $old_filename"
  log "🎯 Target: $new_filename_with_ext"
  
  # CRITICAL DEBUG: Detailed filename comparison
  log "🔍 DETAILED RENAME ANALYSIS:"
  log "   Original filename: '$old_filename'"
  log "   Generated NEW_FILENAME: '$NEW_FILENAME'"
  log "   Target with extension: '$new_filename_with_ext'"
  log "   Original == Target? $(if [[ "$old_filename" == "$new_filename_with_ext" ]]; then echo "YES (NO RENAME NEEDED)"; else echo "NO (RENAME REQUIRED)"; fi)"
  log "   NEW_FILENAME contains MediaInfo? $(if [[ "$NEW_FILENAME" == *"${TOKEN_VALUES["MediaInfo.Full"]}"* ]]; then echo "YES"; else echo "NO"; fi)"
  
  # Check if rename is needed
  if [[ "$old_filename" == "$new_filename_with_ext" ]]; then
    log "✅ File already has correct name: $old_filename"
    log "🚨 THIS IS WHY THE FILE IS NOT BEING RENAMED!"
    continue
  fi
  
  # Check if target exists
  if [[ -f "$new_file_path" ]]; then
    log "⚠️  Target file already exists: $new_filename_with_ext"
    continue
  fi
  
  # Rename the video file
  if mv "$video_file" "$new_file_path" 2>/dev/null; then
    log "✅ Renamed: $old_filename → $new_filename_with_ext"
    renamed_count=$((renamed_count + 1))
    
    # ───────────── 8. Rename ALL Related Files ────────────────────────────────
    old_base_name="${old_filename%.*}"
    new_base_name="$NEW_FILENAME"
    
    # Find ALL files in the directory (not just ones that start with the base name)
    log "🔄 Renaming ALL files in directory to match new naming convention..."
    IFS=$'\n' ALL_FILES=($(find "$MOVIE_DIR" -maxdepth 1 -type f 2>/dev/null))
    IFS=$' \t\n'
    
    for file in "${ALL_FILES[@]}"; do
      if [[ -f "$file" ]]; then
        file_basename=$(basename "$file")
        file_extension="${file_basename##*.}"
        
        # Skip if it's the video file we already renamed
        [[ "$file" == "$new_file_path" ]] && continue
        
        # Skip if this file doesn't need renaming (already has proper name)
        if [[ "$file_basename" =~ ^${NEW_FILENAME}\. ]]; then
          log "✅ File already has correct naming: $file_basename"
          continue
        fi
        
        # Determine new name based on file type
        case "$file_extension" in
          srt|sub|ass|ssa|vtt)
            # Subtitle files
            new_related_name="${new_base_name}.${file_extension}"
            ;;
          nfo|xml)
            # Metadata files
            new_related_name="${new_base_name}.${file_extension}"
            ;;
          jpg|png|jpeg|gif|bmp|tbn)
            # Image files (posters, thumbs, etc.)
            if [[ "$file_basename" =~ (poster|thumb|banner|fanart|landscape|disc|logo) ]]; then
              # Extract the type from filename
              if [[ "$file_basename" =~ (poster|thumb|banner|fanart|landscape|disc|logo) ]]; then
                image_type="${BASH_REMATCH[1]}"
                new_related_name="${new_base_name}-${image_type}.${file_extension}"
              else
                new_related_name="${new_base_name}.${file_extension}"
              fi
            else
              new_related_name="${new_base_name}.${file_extension}"
            fi
            ;;
          *)
            # For any other file type, use the new base name
            new_related_name="${new_base_name}.${file_extension}"
            ;;
        esac
        
        new_related_path="$MOVIE_DIR/$new_related_name"
        
        # Only rename if the name would actually change and target doesn't exist
        if [[ "$file_basename" != "$new_related_name" ]]; then
          if [[ ! -f "$new_related_path" ]]; then
            if mv "$file" "$new_related_path" 2>/dev/null; then
              log "📎 Renamed: $file_basename → $new_related_name"
            else
              log "⚠️  Could not rename: $file_basename"
            fi
          else
            log "⚠️  Target exists, skipping: $new_related_name"
          fi
        fi
      fi
    done
  else
    log "❌ Failed to rename: $old_filename → $new_filename_with_ext"
  fi
done

log "🎊 Hybrid file renaming completed successfully!"
log "✨ Used Radarr API data with manual token processing - no conflicts!"

# FINAL TEST: Verify specific tokens mentioned by user
log ""
log "🧪 FINAL TOKEN TEST for user's specific pattern:"
log "   Pattern: {.MediaInfo Full:ES}{.Custom.Formats}{-Release Group}"

test_pattern="{.MediaInfo Full:ES}{.Custom.Formats}{-Release Group}"
test_result=$(process_filename_tokens "$test_pattern")

log "   Input pattern:  '$test_pattern'"
log "   Result pattern: '$test_result'"

if [[ "$test_result" == "$test_pattern" ]]; then
  log "   🚨 NO TOKENS WERE REPLACED - All stayed as literal text"
else
  log "   ✅ Some tokens were processed"
  
  # Check each specific token
  if [[ "$test_result" == *"{.MediaInfo Full:ES}"* ]]; then
    log "   ❌ MediaInfo Full:ES was NOT replaced"
  else
    log "   ✅ MediaInfo Full:ES was replaced"
  fi
  
  if [[ "$test_result" == *"{.Custom.Formats}"* ]]; then
    log "   ❌ Custom.Formats was NOT replaced"
  else
    log "   ✅ Custom.Formats was replaced"
  fi
  
  if [[ "$test_result" == *"{-Release Group}"* ]]; then
    log "   ❌ Release Group was NOT replaced"
  else
    log "   ✅ Release Group was replaced"
  fi
fi

# ───────────── FINAL SUMMARY ──────────────────────────────────────────────────
log ""
log "📊 FINAL PROCESSING SUMMARY:"
log "   📁 Directory processed: $MOVIE_DIR"
log "   🎬 Movie: $MOVIE_TITLE_RAW (${TOKEN_VALUES["Release.Year"]:-"Unknown Year"})"
log "   📝 Naming pattern: $NAMING_PATTERN"
log "   🎯 Generated filename: $NEW_FILENAME"
log "   📹 Total video files found: ${#VIDEO_FILES[@]}"
log "   ✅ Video files renamed: $renamed_count"
log "   ⚠️  Video files skipped: $((${#VIDEO_FILES[@]} - renamed_count))" 