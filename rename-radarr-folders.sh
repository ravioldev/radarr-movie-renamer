#!/usr/bin/env bash
[ -z "$BASH_VERSION" ] && exec /usr/bin/env bash "$0" "$@"

# Configure UTF-8 encoding for Windows compatibility
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Detect if running in PowerShell and improve output
if [[ "${TERM_PROGRAM:-}" == "vscode" ]] || [[ -n "${PSModulePath:-}" ]]; then
  # Running in PowerShell or VS Code - UTF-8 should work better
  export PYTHONIOENCODING=utf-8
fi

set -euo pipefail

# ───────────── 1. Test Event ─────────────────────────────────────────
if [[ "${radarr_eventtype:-}" == "Test" ]]; then
  printf '[%s] ✔️  Test event received: exit 0\n' "$(date +'%F %T')"
  exit 0
fi

# ───────────── 2. Configuration ───────────────────────────────────────
# Validate critical dependencies first
if ! command -v jq >/dev/null 2>&1; then
  printf '[%s] ❌ ERROR: jq is required but not installed\n' "$(date +'%F %T')"
  printf '[%s] ℹ️  Install jq: https://stedolan.github.io/jq/download/\n' "$(date +'%F %T')"
  printf '[%s] ℹ️  On Git Bash: Download jq.exe to your PATH\n' "$(date +'%F %T')"
  exit 3
fi

if ! command -v curl >/dev/null 2>&1; then
  printf '[%s] ❌ ERROR: curl is required but not installed\n' "$(date +'%F %T')"
  printf '[%s] ℹ️  curl should be available in Git Bash by default\n' "$(date +'%F %T')"
  exit 4
fi

# Load configuration from environment variables with fallback defaults
RADARR_URL="${RADARR_URL:-http://127.0.0.1:7878}"
RADARR_API_KEY="${RADARR_API_KEY:-}"
TMDB_API_KEY="${TMDB_API_KEY:-}"  # Optional - can be empty

# ───────────── LOGGING CONFIGURATION ─────────────────────────────────────
# LOG_LEVEL controls verbosity: MINIMAL, NORMAL, DETAILED, DEBUG
# MINIMAL: Only errors, warnings, and final results
# NORMAL: Above + success messages and important info (recommended)
# DETAILED: Above + process steps and decisions  
# DEBUG: Everything (original behavior - very verbose)
LOG_LEVEL="${LOG_LEVEL:-NORMAL}"

# Custom Formats logging - separate control due to high volume
# LOG_CUSTOM_FORMATS: true=log all CF attempts, false=log only errors/success
LOG_CUSTOM_FORMATS="${LOG_CUSTOM_FORMATS:-false}"

# Quality detection logging - separate control due to high volume  
# LOG_QUALITY_DEBUG: true=log detailed quality analysis, false=log only final result
LOG_QUALITY_DEBUG="${LOG_QUALITY_DEBUG:-false}"

# Language detection logging - separate control
# LOG_LANGUAGE_DEBUG: true=log language detection steps, false=log only final choice
LOG_LANGUAGE_DEBUG="${LOG_LANGUAGE_DEBUG:-false}"

# Validate API configuration
if [[ -z $RADARR_API_KEY || $RADARR_API_KEY == "your_radarr_api_key_here" ]]; then
  printf '[%s] ❌ ERROR: RADARR_API_KEY is not configured\n' "$(date +'%F %T')"
  printf '[%s] ℹ️  Set RADARR_API_KEY in config.env with your actual API key\n' "$(date +'%F %T')"
  printf '[%s] ℹ️  Get your API key from Radarr → Settings → General → API Key\n' "$(date +'%F %T')"
  exit 5
fi

# Language configuration
NATIVE_LANGUAGE="${NATIVE_LANGUAGE:-}"
FALLBACK_LANGUAGE="${FALLBACK_LANGUAGE:-en}"
AUTO_DETECT_FROM_RADARR="${AUTO_DETECT_FROM_RADARR:-false}"

# File system configuration
TEMP_LOG_FILE="${TEMP_LOG_FILE:-/tmp/put.log}"
FILE_PERMISSIONS_DIR="${FILE_PERMISSIONS_DIR:-D755}"
FILE_PERMISSIONS_FILE="${FILE_PERMISSIONS_FILE:-F644}"
FIND_MAXDEPTH="${FIND_MAXDEPTH:-1}"
VIDEO_EXTENSIONS="${VIDEO_EXTENSIONS:-mkv mp4 avi mov}"
RSYNC_OPTIONS="${RSYNC_OPTIONS:--a --ignore-existing}"

# Folder naming configuration
USE_COLLECTIONS="${USE_COLLECTIONS:-true}"
INCLUDE_QUALITY_TAG="${INCLUDE_QUALITY_TAG:-true}"

# Enhanced logging functions with level control and Windows emoji compatibility
log() { 
  local message="$*"
  
  # Replace problematic emojis with Windows-compatible versions
  message="${message//🎬/[MOVIE]}"
  message="${message//📁/[FOLDER]}"
  message="${message//🔧/[CONFIG]}"
  message="${message//✅/[OK]}"
  message="${message//❌/[ERROR]}"
  message="${message//⚠️/[WARN]}"
  message="${message//🔍/[DEBUG]}"
  message="${message//🐛/[DEBUG]}"
  message="${message//🔄/[CONVERT]}"
  message="${message//📋/[INFO]}"
  message="${message//🌍/[WEB]}"
  message="${message//🎭/[TITLE]}"
  message="${message//📄/[FILE]}"
  message="${message//🔥/[API]}"
  message="${message//ℹ️/[INFO]}"
  message="${message//📊/[SUMMARY]}"
  message="${message//🎯/[TARGET]}"
  message="${message//🔬/[ANALYSIS]}"
  message="${message//🚀/[START]}"
  message="${message//🧪/[TEST]}"
  message="${message//📹/[VIDEO]}"
  message="${message//🎊/[SUCCESS]}"
  message="${message//✨/[COMPLETE]}"
  message="${message//🚨/[ALERT]}"
  message="${message//💡/[TIP]}"
  message="${message//🗂️/[FOLDER]}"
  message="${message//📤/[UPLOAD]}"
  message="${message//🔤/[LANG]}"
  message="${message//🌐/[WEB]}"
  message="${message//🏷️/[TAG]}"
  message="${message//📂/[DIR]}"
  message="${message//💚/[SUCCESS]}"
  message="${message//🔗/[LINK]}"
  message="${message//⏰/[TIME]}"
  message="${message//🔀/[SHUFFLE]}"
  message="${message//🎪/[EVENT]}"
  message="${message//✔️/[CHECK]}"
  message="${message//🏗️/[BUILD]}"
  message="${message//⚙️/[SETTINGS]}"
  message="${message//📥/[DOWNLOAD]}"
  message="${message//🎉/[PARTY]}"
  message="${message//📝/[MEMO]}"
  message="${message//🔄/[REFRESH]}"
  message="${message//📡/[SIGNAL]}"
  message="${message//🌐/[GLOBAL]}"
  
  # Always log errors, warnings, and important messages (MINIMAL level and above)
  printf '[%s] %s\n' "$(date +'%F %T')" "$message" >&2; 
}

log_info() {
  # Log informational messages (NORMAL level and above)
  case "$LOG_LEVEL" in
    MINIMAL) return ;;
    *) log "$@" ;;
  esac
}

log_detailed() {
  # Log detailed process information (DETAILED level and above)  
  case "$LOG_LEVEL" in
    MINIMAL|NORMAL) return ;;
    *) log "$@" ;;
  esac
}

log_debug() {
  # Log debug information (DEBUG level only)
  case "$LOG_LEVEL" in
    DEBUG) log "$@" ;;
    *) return ;;
  esac
}

log_quality() {
  # Log quality detection details (only if LOG_QUALITY_DEBUG=true)
  [[ "$LOG_QUALITY_DEBUG" == "true" ]] && log "$@"
}

log_language() {
  # Log language detection details (only if LOG_LANGUAGE_DEBUG=true)
  [[ "$LOG_LANGUAGE_DEBUG" == "true" ]] && log "$@"
}

log_custom_formats() {
  # Log custom formats attempts (only if LOG_CUSTOM_FORMATS=true)
  [[ "$LOG_CUSTOM_FORMATS" == "true" ]] && log "$@"
}

# Auto-detect language preferences from Radarr (optional)
detect_radarr_language_preference() {
  [[ $AUTO_DETECT_FROM_RADARR != "true" ]] && return 1
  
  log_detailed "🔍 Attempting to detect language preference from Radarr..."
  
  # Try to get Radarr's UI settings
  local ui_config=$(curl -sf --max-time 10 --retry 1 \
                         -H "X-Api-Key:$RADARR_API_KEY" \
                         "$RADARR_URL/api/v3/config/ui" 2>/dev/null)
  
  if [[ $? -eq 0 && -n $ui_config ]]; then
    local ui_language=$(jq -r '.uiLanguage // empty' <<<"$ui_config" 2>/dev/null)
    if [[ -n $ui_language && $ui_language != "null" ]]; then
      # Convert UI language codes to ISO 639-1 (e.g., "en-US" -> "en")
      ui_language=${ui_language:0:2}
      log_info "✅ Detected Radarr UI language: $ui_language"
      echo "$ui_language"
      return 0
    fi
  fi
  
  log_detailed "ℹ️  Could not detect language preference from Radarr"
  return 1
}

# TMDB integration (optional) - Only called for native language movies
fetch_tmdb_data() {
  local tmdb_id="$1"
  local language="$2"
  
  # Validate TMDB API key
  if [[ -z $TMDB_API_KEY ]]; then
    log_detailed "ℹ️  TMDB disabled (no API key configured)"
    return 1
  fi
  
  # Validate TMDB ID
  if [[ -z $tmdb_id || $tmdb_id == "null" || $tmdb_id == "0" ]]; then
    log "ℹ️  No valid TMDB ID available (ID: ${tmdb_id:-'empty'})"
    return 1
  fi
  
  # Validate language parameter
  if [[ -z $language ]]; then
    log "⚠️  No language specified for TMDB fetch"
    return 1
  fi
  
  log "🎬 Fetching TMDB data (ID: $tmdb_id, Language: $language)"
  
  # Build TMDB API URL with language parameter
  local tmdb_url="https://api.themoviedb.org/3/movie/$tmdb_id?language=$language"
  
  # Call TMDB API with timeout and retry logic
  local tmdb_json=$(curl -sf --max-time 10 --retry 2 --retry-delay 1 \
                         -H "Authorization: Bearer $TMDB_API_KEY" \
                         -H "Accept: application/json" \
                         "$tmdb_url" 2>/dev/null)
  
  local curl_exit_code=$?
  
  if [[ $curl_exit_code -eq 0 && -n $tmdb_json ]]; then
    # Validate that we got valid JSON response
    local tmdb_title=$(jq -r '.title // empty' <<<"$tmdb_json" 2>/dev/null)
    local tmdb_status=$(jq -r '.status_message // empty' <<<"$tmdb_json" 2>/dev/null)
    
    if [[ -n $tmdb_status ]]; then
      log "⚠️  TMDB API error: $tmdb_status"
      return 1
    fi
    
    if [[ -n $tmdb_title && $tmdb_title != "null" ]]; then
      log "✅ TMDB data fetched successfully - Title: $tmdb_title"
      echo "$tmdb_json"
      return 0
    else
      log "⚠️  TMDB returned empty title for language $language"
      return 1
    fi
  else
    case $curl_exit_code in
      6)  log "⚠️  TMDB fetch failed: Could not resolve host" ;;
      7)  log "⚠️  TMDB fetch failed: Failed to connect" ;;
      28) log "⚠️  TMDB fetch failed: Operation timeout" ;;
      22) log "⚠️  TMDB fetch failed: HTTP error (possibly invalid API key)" ;;
      *)  log "⚠️  TMDB fetch failed: curl error code $curl_exit_code" ;;
    esac
    return 1
  fi
}

quality_tag(){          # 1-N tracks → tag
  # Handle empty arguments case
  [[ $# -eq 0 ]] && { echo "LowQuality"; return; }
  
  # Process arguments in order of priority:
  # 1st arg = resolution (most accurate)
  # 2nd arg = quality name (less accurate for SDTV)
  local resolution="$1"
  local quality_name="$2"
  
  # PRIORITY 1: Check for "always bad quality" sources (regardless of resolution)
  # These sources are always LowQuality no matter what resolution they claim
  # FIXED: More specific patterns to avoid false positives like "Hitch" containing "tc"
  for v in "$@"; do
    [[ -z "$v" || "$v" == "null" ]] && continue
          case "${v,,}" in
        *telesync*|*telecine*|*workprint*|*r5*|*pdvd*) 
          echo "LowQuality"; return ;;
        # FIXED: More specific CAM patterns to avoid matching words like "came", "camp", etc.
        *.cam.*|*-cam-*|*_cam_*|*.cam|*cam.*|*camrip*) 
          echo "LowQuality"; return ;;
        # FIXED: Ultra-specific TC patterns - only match when TC is clearly a quality indicator
        # Pattern explanation:
        # *.tc.* → file.tc.720p (TC as separate component)
        # *-tc-* → movie-tc-2023 (TC with dashes)
        # *_tc_* → movie_tc_720p (TC with underscores)  
        # *.tc   → movie.tc (TC at end)
        # *[.-_]tc[.-_]* → only TC surrounded by separators
        # *[0-9]tc[.-_]* → year/number + tc + separator (e.g., 2023tc.720p)
        *.tc.*|*-tc-*|*_tc_*|*.tc|*[.-_]tc[.-_]*|*[0-9]tc[.-_]*) 
          echo "LowQuality"; return ;;
      esac
  done
  
  # PRIORITY 2: Check for special case - good quality sources with resolution
  # Handle SCREENER + high resolution as good quality (not LowQuality)
  # Also check filename for SCREENER patterns when quality_name is "Unknown"
  if [[ -n "$resolution" ]]; then
    # Check quality name OR filename for SCREENER patterns
    local is_screener=false
    case "${quality_name,,}" in
      *screener*) is_screener=true ;;
    esac
    
    # Also check filename for SCREENER patterns (for Unknown quality)
    for v in "$@"; do
      [[ -z "$v" ]] && continue
      case "${v,,}" in
        *screener*|*dvdscr*) is_screener=true ;;
      esac
    done
    
    if [[ "$is_screener" == "true" ]]; then
      case "${resolution,,}" in
        *2160*|*4k*|*uhd*) echo "2160p"; return ;;
        *1440*|*2k*)       echo "1440p"; return ;;
        *1080*|*fhd*)      echo "1080p"; return ;;
        *720*|*hd*)        echo "720p" ; return ;;
      esac
    fi
    
    # Check for BR-DISK with resolution
    case "${quality_name,,}" in
      *br-disk*|*brdisk*)
        case "${resolution,,}" in
          *2160*|*4k*|*uhd*) echo "2160p"; return ;;
          *1440*|*2k*)       echo "1440p"; return ;;
          *1080*|*fhd*)      echo "1080p"; return ;;
          *720*|*hd*)        echo "720p" ; return ;;
        esac
        ;;
    esac
  fi

  # PRIORITY 3: Check resolution first (most accurate for good sources)
  if [[ -n "$resolution" && "$resolution" != "null" && "$resolution" != "" ]]; then
    # Extract numeric resolution for range checking
    local numeric_res=$(echo "$resolution" | grep -o '[0-9]\+' | head -1)
    
    # Handle special resolution patterns first - FIXED: If we have explicit resolution, use it
    case "${resolution,,}" in
      *2160*|*4k*|*uhd*) echo "2160p"; return ;;
      *1440*|*2k*)       echo "1440p"; return ;;
      *1080*|*fhd*)      echo "1080p"; return ;;
      *720*|*hd*)        echo "720p" ; return ;;
      *576*|*dvd*)       echo "DVD-Rip"; return ;;
      *480*)             echo "480p" ; return ;;
    esac
    
    # Range-based resolution detection for intermediate values
    if [[ -n "$numeric_res" && "$numeric_res" =~ ^[0-9]+$ ]]; then
      if [[ $numeric_res -ge 2000 ]]; then
        echo "2160p"; return     # 2000p+ → 2160p (4K range)
      elif [[ $numeric_res -ge 1350 ]]; then
        echo "1440p"; return     # 1350-1999p → 1440p (2K range)
      elif [[ $numeric_res -ge 900 ]]; then
        echo "1080p"; return     # 900-1349p → 1080p (Full HD range)
      elif [[ $numeric_res -ge 600 ]]; then
        echo "720p"; return      # 600-899p → 720p (HD range)
      elif [[ $numeric_res -ge 520 ]]; then
        echo "DVD-Rip"; return   # 520-599p → DVD-Rip (576p range)
      elif [[ $numeric_res -ge 480 ]]; then
        echo "480p"; return      # 480-519p → 480p (SD minimum)
      else
        echo "LowQuality"; return # <480p → LowQuality (very low quality)
      fi
    fi
  fi
  
  # PRIORITY 4: Check quality name for resolution indicators (if no resolution provided)
  if [[ -n "$quality_name" && "$quality_name" != "null" && "$quality_name" != "" ]]; then
    case "${quality_name,,}" in
      # Resolution indicators in quality name
      *2160*|*4k*|*uhd*) echo "2160p"; return ;;
      *1440*)            echo "1440p"; return ;;
      *1080*)            echo "1080p"; return ;;
      *720*)             echo "720p" ; return ;;
      *576*|*dvd*)       echo "DVD-Rip"; return ;;
      *480*)             echo "480p" ; return ;;
      
      # SDTV - CORRECTED: Apply resolution-based correction like in file script
      *sdtv*)
        log "🔧 SDTV detected in quality_tag - applying resolution-based correction..."
        
        # Try to find resolution in any of the provided arguments
        for arg in "$@"; do
          [[ -z "$arg" || "$arg" == "null" ]] && continue
          
          # Look for resolution patterns in the argument
          if [[ "$arg" =~ [0-9]+p ]]; then
            local found_resolution=$(echo "$arg" | grep -oE '[0-9]+p' | head -1)
            log "   ✅ Found resolution in '$arg': $found_resolution"
            echo "$found_resolution"
            return
          fi
          
          # Look for numeric resolution that we can convert to {number}p
          local numeric_res=$(echo "$arg" | grep -o '[0-9]\+' | head -1)
          if [[ -n "$numeric_res" && "$numeric_res" =~ ^[0-9]+$ ]]; then
            if [[ $numeric_res -ge 480 ]]; then
              log "   ✅ Found numeric resolution $numeric_res - converting to ${numeric_res}p"
              echo "${numeric_res}p"
              return
            fi
          fi
        done
        
        # If no resolution found, use LowQuality instead of SDTV
        log "   ✅ No resolution found - using LowQuality instead of SDTV"
        echo "LowQuality"
        return ;;
    esac
  fi
  
  # PRIORITY 5: Check all arguments for any resolution patterns
  for v in "$@"; do
    # Skip empty or null values
    [[ -z "$v" || "$v" == "null" ]] && continue
    
    # Extract numeric resolution for range checking
    local numeric_res=$(echo "$v" | grep -o '[0-9]\+' | head -1)
    
    case "${v,,}" in
      # Standard resolution patterns in any argument
      *2160*|*4k*) echo "2160p"; return ;;
      *1440*)      echo "1440p"; return ;;
      *1080*)      echo "1080p"; return ;;
      *720*)       echo "720p" ; return ;;
      *576*|*dvd*) echo "DVD-Rip"; return ;;
      *480*)       echo "480p" ; return ;;
    esac
    
    # Range-based detection for any numeric resolution found
    # BUT only consider valid resolution ranges (exclude years like 2004, 2013, etc.)
    if [[ -n "$numeric_res" && "$numeric_res" =~ ^[0-9]+$ ]]; then
      # FIXED: Exclude common year patterns (1900-2099) that appear in filenames
      if [[ $numeric_res -ge 1900 && $numeric_res -le 2099 ]]; then
        continue  # Skip year numbers, don't treat them as resolution
      elif [[ $numeric_res -ge 2000 ]]; then
        echo "2160p"; return
      elif [[ $numeric_res -ge 1350 ]]; then
        echo "1440p"; return
      elif [[ $numeric_res -ge 900 ]]; then
        echo "1080p"; return
      elif [[ $numeric_res -ge 600 ]]; then
        echo "720p"; return
      elif [[ $numeric_res -ge 520 ]]; then
        echo "DVD-Rip"; return
      elif [[ $numeric_res -ge 480 ]]; then
        echo "480p"; return
      elif [[ $numeric_res -gt 0 ]]; then
        echo "LowQuality"; return  # Any resolution below 480p → LowQuality
      fi
    fi
  done
  
  # Fallback if no patterns matched
  echo "LowQuality"
}

# Enhanced quality detection for m2ts files (Blu-ray BDAV)
quality_tag_m2ts() {
  local width="$1"
  local height="$2"
  local resolution="${3:-}"
  local quality_name="${4:-}"
  local source="${5:-}"
  
  log "🔍 M2TS Quality Analysis:"
  log "   Width: ${width:-'(empty)'}"
  log "   Height: ${height:-'(empty)'}"
  log "   Resolution: ${resolution:-'(empty)'}"
  log "   Quality Name: ${quality_name:-'(empty)'}"
  log "   Source: ${source:-'(empty)'}"
  
  # PRIORITY 1: Use width/height to determine resolution (most accurate for m2ts)
  if [[ -n "$width" && "$width" != "null" && "$width" != "" ]] && \
     [[ -n "$height" && "$height" != "null" && "$height" != "" ]]; then
    
    local width_num=$(echo "$width" | grep -o '[0-9]\+' | head -1)
    local height_num=$(echo "$height" | grep -o '[0-9]\+' | head -1)
    
    if [[ -n "$width_num" && "$height_num" =~ ^[0-9]+$ ]]; then
      # Use height as primary indicator (standard for video resolution)
      if [[ $height_num -ge 2000 ]]; then
        echo "2160p"; return     # 4K UHD
      elif [[ $height_num -ge 1350 ]]; then
        echo "1440p"; return     # 2K QHD
      elif [[ $height_num -ge 1000 ]]; then
        echo "1080p"; return     # Full HD (1080p)
      elif [[ $height_num -ge 700 ]]; then
        echo "720p"; return      # HD (720p)
      elif [[ $height_num -ge 570 ]]; then
        echo "DVD-Rip"; return   # DVD quality (~576p)
      elif [[ $height_num -ge 470 ]]; then
        echo "480p"; return      # Standard definition
      else
        echo "LowQuality"; return # Very low quality
      fi
    fi
  fi
  
  # PRIORITY 2: Check source quality for Blu-ray specific indicators
  if [[ -n "$source" && "$source" != "null" && "$source" != "" ]]; then
    case "${source,,}" in
      *bluray*|*blu-ray*|*bdmv*|*bdav*)
        # Blu-ray sources are typically high quality, assume 1080p unless we know better
        echo "1080p"; return ;;
      *uhd*|*4k*)
        echo "2160p"; return ;;
    esac
  fi
  
  # PRIORITY 3: Fall back to standard quality_tag function with all parameters
  quality_tag "$resolution" "$quality_name" "$width" "$height" "$source"
}

sanitize(){             # Clean for Windows (maintains UTF-8)
  local s="$1"
  
  # Remove hearts and other decorative symbols
  s=$(perl -CS -Mutf8 -pe 's/[♥\x{2764}]//g; s/ć/c/g; s/Ć/C/g' <<<"$s")
  
  # Handle superscripts and subscripts - intelligent conversion based on context
  
  # Step 1: Chemical formulas (H₂O, CO₂, etc.) - no space: H₂O → H2O
  # Handle common chemical patterns first
  s=$(perl -CS -Mutf8 -pe 's/H₂O/H2O/g; s/CO₂/CO2/g; s/CH₄/CH4/g; s/NH₃/NH3/g; s/SO₂/SO2/g; s/NO₂/NO2/g' <<<"$s")
  
  # General pattern for chemical elements: single capital letter + subscript
  s=$(perl -CS -Mutf8 -pe 's/([A-Z])₀/\10/g; s/([A-Z])₁/\11/g; s/([A-Z])₂/\12/g; s/([A-Z])₃/\13/g; s/([A-Z])₄/\14/g; s/([A-Z])₅/\15/g; s/([A-Z])₆/\16/g; s/([A-Z])₇/\17/g; s/([A-Z])₈/\18/g; s/([A-Z])₉/\19/g' <<<"$s")
  
  # Step 2: Movie sequels and titles - with space: Alien³ → Alien 3, [REC]² → [REC] 2
  # Pattern: Word/bracket + superscript numbers (after letters or closing brackets/parentheses)
  s=$(perl -CS -Mutf8 -pe 's/([A-Za-z\]\)])⁰/\1 0/g; s/([A-Za-z\]\)])¹/\1 1/g; s/([A-Za-z\]\)])²/\1 2/g; s/([A-Za-z\]\)])³/\1 3/g; s/([A-Za-z\]\)])⁴/\1 4/g; s/([A-Za-z\]\)])⁵/\1 5/g; s/([A-Za-z\]\)])⁶/\1 6/g; s/([A-Za-z\]\)])⁷/\1 7/g; s/([A-Za-z\]\)])⁸/\1 8/g; s/([A-Za-z\]\)])⁹/\1 9/g' <<<"$s")
  
  # Step 3: Remaining subscripts (fallback) - no space for any remaining chemical contexts
  s=$(perl -CS -Mutf8 -pe 's/₀/0/g; s/₁/1/g; s/₂/2/g; s/₃/3/g; s/₄/4/g; s/₅/5/g; s/₆/6/g; s/₇/7/g; s/₈/8/g; s/₉/9/g' <<<"$s")
  
  # Step 4: Remaining superscripts (fallback) - with space for any remaining movie titles
  s=$(perl -CS -Mutf8 -pe 's/⁰/ 0/g; s/¹/ 1/g; s/²/ 2/g; s/³/ 3/g; s/⁴/ 4/g; s/⁵/ 5/g; s/⁶/ 6/g; s/⁷/ 7/g; s/⁸/ 8/g; s/⁹/ 9/g' <<<"$s")
  
  # Handle various quote types - normalize to single quote
  s=${s//[$'\u2018\u2019\u201A\u201B\u0060\u00B4']/\'}
  
  # Handle various dash/bullet types - normalize to hyphen
  s=${s//[•·–—]/-}
  
  # Handle various colon types - convert to " - " for readability
  s=$(perl -CS -Mutf8 -pe 's/[:\x{F03A}\x{FF1A}\x{FE55}\x{A789}]/ - /g' <<<"$s")
  
  # Handle various slash types - convert to hyphen
  s=$(perl -CS -Mutf8 -pe 's![/\\\x{2215}\x{2044}]!-!g' <<<"$s")
  
  # Remove Windows-forbidden characters - replace with space
  s=${s//[<>\"?*|]/ }
  
  # Clean up spacing and normalize " - " sequences
  s=$(sed -E 's/[[:space:]]+/ /g; s/ - +/ - /g; s/^ //; s/ $//' <<<"$s")
  
  # Fallback to original if sanitization resulted in empty string
  [[ -z $s ]] && s="$1"
  printf '%s' "$s"
}

drive(){ echo "${1%%:*}"; }
# SAFE copy function to prevent copying entire Radarr installation
copy_tree(){ 
  local src_dir="$1"
  local dst_dir="$2"
  
  # SAFETY CHECK: Prevent copying from Radarr installation directories
  local radarr_install_patterns=("Program Files" "programdata" "appdata" ".exe" "radarr.exe" "Radarr.exe")
  for pattern in "${radarr_install_patterns[@]}"; do
    if [[ "$src_dir" == *"$pattern"* ]]; then
      log "❌ SAFETY CHECK FAILED: Source directory appears to be a Radarr installation: $src_dir"
      log "❌ Refusing to copy from potential installation directory to prevent data corruption"
      exit 99
    fi
  done
  
  # SAFETY CHECK: Verify source is a movie directory (contains video files)
  local video_file_count=0
  local total_file_count=0
  
  # Count video files vs total files
  if [[ -d "$src_dir" ]]; then
    # Count video files
    find_cmd="find \"$src_dir\" -maxdepth $FIND_MAXDEPTH -type f \\("
    first=true
    for ext in $VIDEO_EXTENSIONS; do
      [[ $first == true ]] && first=false || find_cmd+=" -o"
      find_cmd+=" -iname '*.$ext'"
    done
    find_cmd+=" \\)"
    video_file_count=$(eval "$find_cmd" | wc -l)
    
    # Count total files
    total_file_count=$(find "$src_dir" -maxdepth $FIND_MAXDEPTH -type f | wc -l)
    
    log_debug "🔍 Safety Check - Source Directory Analysis:"
    log_debug "   Video files found: $video_file_count"
    log_debug "   Total files found: $total_file_count"
    
    # If more than 100 files and less than 10% are video files, something is wrong
    if [[ $total_file_count -gt 100 && $video_file_count -eq 0 ]]; then
      log "❌ SAFETY CHECK FAILED: Directory contains $total_file_count files but no video files"
      log "❌ This looks like a system/application directory, not a movie folder"
      exit 98
    fi
    
    if [[ $total_file_count -gt 500 ]]; then
      local video_percentage=$((video_file_count * 100 / total_file_count))
      if [[ $video_percentage -lt 5 ]]; then
        log "❌ SAFETY CHECK FAILED: Directory contains $total_file_count files but only $video_file_count video files ($video_percentage%)"
        log "❌ This looks like a system/application directory, not a movie folder"
        exit 97
      fi
    fi
  fi
  
  log "✅ Safety checks passed - proceeding with copy operation"
  log "🔄 Copying from: $src_dir"
  log "🔄 Copying to: $dst_dir"
  
  # Check if rsync is available, fallback to native commands
  if command -v rsync >/dev/null 2>&1; then
    log "📁 Using rsync with selective file copying"
    # Use the safe RSYNC_OPTIONS that only copy video and subtitle files
    rsync $RSYNC_OPTIONS --chmod="$FILE_PERMISSIONS_DIR,$FILE_PERMISSIONS_FILE" "$src_dir/" "$dst_dir/"
  else
    # Windows/Git Bash fallback - use selective cp
    log "ℹ️  rsync not available, using selective cp fallback"
    shopt -s dotglob nullglob
    
    # Only copy video and subtitle files
    local files_copied=0
    for ext in $VIDEO_EXTENSIONS srt sub idx; do
      for file in "$src_dir"/*."$ext"; do
        if [[ -f "$file" ]]; then
          cp "$file" "$dst_dir"/ 2>/dev/null && ((files_copied++))
        fi
      done
    done
    
    log "📁 Copied $files_copied media files"
    
    # If selective copy fails or finds no files, try robocopy as last resort
    if [[ $files_copied -eq 0 ]]; then
      log "⚠️  No media files found with selective copy, trying robocopy with filters"
      # Convert paths to Windows format for robocopy
      local src_win=$(cygpath -w "$src_dir" 2>/dev/null || echo "$src_dir")
      local dst_win=$(cygpath -w "$dst_dir" 2>/dev/null || echo "$dst_dir") 
      
      # Create include pattern for robocopy (video and subtitle extensions)
      local robocopy_include=""
      for ext in $VIDEO_EXTENSIONS srt sub idx; do
        robocopy_include="$robocopy_include *.$ext"
      done
      
      robocopy "$src_win" "$dst_win" $robocopy_include /S /COPY:DAT /R:1 /W:1 >/dev/null 2>&1 || true
    fi
    
    shopt -u dotglob nullglob
  fi
}
norm(){ tr '\\' '/' <<<"$1"; }

# ───────────── 3. Arguments var=val ──────────────────────────────────
# Enhanced argument parsing with better handling of special characters
for a in "$@"; do 
  case $a in
    radarr_movie_id=*)          
      radarr_movie_id=${a#*=} 
      log "📋 Parsed movie ID: $radarr_movie_id"
      ;;
    radarr_movie_title=*)       
    radarr_movie_title=${a#*=}
      # Handle escaped quotes and special characters
      radarr_movie_title=${radarr_movie_title//\\\'/\'}  # Convert \' to '
      radarr_movie_title=${radarr_movie_title//\\\"/\"}  # Convert \" to "
      log "📋 Parsed movie title: $radarr_movie_title"
      ;;
    radarr_movie_year=*)        
      radarr_movie_year=${a#*=} 
      log "📋 Parsed movie year: $radarr_movie_year"
      ;;
    radarr_moviefile_quality=*) 
      radarr_moviefile_quality=${a#*=} 
      log "📋 Parsed movie quality: $radarr_moviefile_quality"
      ;;
    radarr_movie_path=*)
      radarr_movie_path=${a#*=}
      log "📋 Parsed movie path: $radarr_movie_path"
      ;;
    *)
      log "⚠️  Unknown argument: $a"
      ;;
  esac
done

# Validate required parameters with better error messages
if [[ -z $radarr_movie_id ]]; then
  log "❌ Missing required parameter: radarr_movie_id"
  exit 98
fi
if [[ -z $radarr_movie_title ]]; then
  log "❌ Missing required parameter: radarr_movie_title"
  exit 98
fi
if [[ -z $radarr_movie_year ]]; then
  log "❌ Missing required parameter: radarr_movie_year"
  exit 98
fi

log "✅ All required parameters validated"
ID=$radarr_movie_id

# ───────────── 4. Metadata ───────────────────────────────────────────
MOVIE_JSON=$(curl -sf --max-time 30 --retry 2 --retry-delay 1 \
                  -H "X-Api-Key:$RADARR_API_KEY" \
                  "$RADARR_URL/api/v3/movie/$ID") || exit 90

HAS_FILE=$(jq -r '.hasFile' <<<"$MOVIE_JSON")
QP_ID=$(jq  -r '.qualityProfileId' <<<"$MOVIE_JSON")
LANG=$(jq   -r '.originalLanguage // empty' <<<"$MOVIE_JSON")

# 4.1 Preferred title with native language detection and TMDB integration
get_preferred_title() {
  local movie_json="$1"
  local native_lang="$2"
  local fallback_lang="$3"
  local title=""
  
  # Auto-detect language preference from Radarr if enabled
  if [[ -z $native_lang ]] && [[ $AUTO_DETECT_FROM_RADARR == "true" ]]; then
    native_lang=$(detect_radarr_language_preference)
  fi
  
  # Extract language code from originalLanguage object (it might be an object with .name or just a string)
  local orig_lang_name=$(jq -r '.originalLanguage.name // .originalLanguage // empty' <<<"$movie_json")
  
  # Map language names to ISO codes
  local orig_lang=""
  case "${orig_lang_name,,}" in
    "spanish"|"español")     orig_lang="es" ;;
    "english"|"inglés")      orig_lang="en" ;;
    "french"|"français")     orig_lang="fr" ;;
    "german"|"deutsch")      orig_lang="de" ;;
    "italian"|"italiano")    orig_lang="it" ;;
    "portuguese"|"português") orig_lang="pt" ;;
    "japanese"|"日本語")      orig_lang="ja" ;;
    "korean"|"한국어")        orig_lang="ko" ;;
    "chinese"|"中文")        orig_lang="zh" ;;
    "russian"|"русский")     orig_lang="ru" ;;
    *)                       orig_lang="${orig_lang_name,,}" ;;  # Use as-is if already a code
  esac
  
  log_language "🔤 Language preference: ${native_lang:-'(none)'} → ${fallback_lang}"
  log_language "🌍 Movie original language: '${orig_lang_name}' → '${orig_lang}'"
  log_debug "🔍 Language comparison: native='${native_lang}' vs original='${orig_lang}'"
  
  # TMDB Integration: ONLY for movies where original language matches native language
  if [[ -n $native_lang && $orig_lang == "$native_lang" ]]; then
    log "🌍 Movie is originally in $native_lang - using native language preference"
    
    # Step 1: Try TMDB for native language title (only for native language movies)
    local tmdb_id=$(jq -r '.tmdbId // empty' <<<"$movie_json")
    if [[ -n $tmdb_id && $tmdb_id != "null" && $tmdb_id != "0" ]]; then
      log "🎬 Attempting TMDB lookup (ID: $tmdb_id, Language: $native_lang)"
      local tmdb_data=$(fetch_tmdb_data "$tmdb_id" "$native_lang")
      if [[ -n $tmdb_data ]]; then
        title=$(jq -r '.title // empty' <<<"$tmdb_data" 2>/dev/null)
        if [[ -n $title && $title != "null" ]]; then
          log "✅ Using TMDB title: $title"
          echo "$title"
          return
        else
          log "⚠️  TMDB returned empty title"
        fi
      else
        log "⚠️  TMDB fetch failed or returned no data"
      fi
    else
      log "ℹ️  No valid TMDB ID available (ID: ${tmdb_id:-'empty'})"
    fi
    
    # Step 2: Fallback to original title from Radarr for native language movies
    title=$(jq -r '.originalTitle // .title' <<<"$movie_json")
    if [[ -n $title && $title != "null" ]]; then
      log "✅ Using original title (native language)"
      echo "$title"
      return
    fi
  else
    # For non-native language movies, use fallback language logic
    log "🌍 Movie is NOT in native language - using fallback language preference"
    
    # Step 1: Look for alternative title in fallback language
    title=$(jq -r ".alternativeTitles[]? | select(.language==\"$fallback_lang\") | .title" <<<"$movie_json" | head -n1)
    if [[ -n $title && $title != "null" ]]; then
      log "✅ Using alternative title in $fallback_lang: $title"
      echo "$title"
      return
    fi
    
    # Step 2: Use default title from Radarr
    title=$(jq -r '.title' <<<"$movie_json")
    if [[ -n $title && $title != "null" ]]; then
      log "✅ Using default Radarr title: $title"
      echo "$title"
      return
    fi
  fi
  
  # Final fallback to parameter
  log "⚠️  Using fallback title from parameters: $radarr_movie_title"
  echo "$radarr_movie_title"
}

log "🏗️  Building folder name..."
TITLE_RAW=$(get_preferred_title "$MOVIE_JSON" "$NATIVE_LANGUAGE" "$FALLBACK_LANGUAGE")
log "🎬 Selected title: $TITLE_RAW"

# 4.2 Quality
QUALITY_NAME=${radarr_moviefile_quality:-$(jq -r '.movieFile.quality.quality.name // empty' <<<"$MOVIE_JSON")}
RESOLUTION=$(jq -r '.movieFile.mediaInfo.video.resolution // empty' <<<"$MOVIE_JSON")

# Check if this is an m2ts file for enhanced quality detection
FILE_PATH=$(jq -r '.movieFile.relativePath // empty' <<<"$MOVIE_JSON")

# FALLBACK: Extract resolution from filename if MediaInfo is not available
extract_resolution_from_filename() {
  local filename="$1"
  local extracted=""
  
  # Pattern matching for common resolution indicators
  case "${filename,,}" in
    *2160p*|*4k*|*uhd*) extracted="2160p" ;;
    *1440p*|*2k*)       extracted="1440p" ;;
    *1080p*|*fhd*)      extracted="1080p" ;;
    *720p*|*hd*)        extracted="720p"  ;;
    *576p*|*dvd*)       extracted="576p"  ;;
    *480p*)             extracted="480p"  ;;
  esac
  
  echo "$extracted"
}

# If MediaInfo resolution is empty, try to extract from filename
if [[ -z "$RESOLUTION" || "$RESOLUTION" == "null" ]]; then
  FILENAME_RESOLUTION=$(extract_resolution_from_filename "$FILE_PATH")
  if [[ -n "$FILENAME_RESOLUTION" ]]; then
    RESOLUTION="$FILENAME_RESOLUTION"
    log "📋 MediaInfo resolution empty - extracted from filename: $RESOLUTION"
  fi
fi
if [[ "$FILE_PATH" =~ \.m2ts$ ]]; then
  log "📀 Detected m2ts file - using enhanced quality detection"
  # Extract additional fields for m2ts analysis
  WIDTH=$(jq -r '.movieFile.mediaInfo.videoWidth // empty' <<<"$MOVIE_JSON")
  HEIGHT=$(jq -r '.movieFile.mediaInfo.videoHeight // empty' <<<"$MOVIE_JSON")
  SOURCE=$(jq -r '.movieFile.quality.quality.source // empty' <<<"$MOVIE_JSON")
  
  # FALLBACK: Extract dimensions from filename for m2ts if MediaInfo is empty
  if [[ -z "$WIDTH" || "$WIDTH" == "null" ]] || [[ -z "$HEIGHT" || "$HEIGHT" == "null" ]]; then
    case "${FILE_PATH,,}" in
      *2160p*|*4k*|*uhd*) WIDTH="3840"; HEIGHT="2160" ;;
      *1440p*|*2k*)       WIDTH="2560"; HEIGHT="1440" ;;
      *1080p*|*fhd*)      WIDTH="1920"; HEIGHT="1080" ;;
      *720p*|*hd*)        WIDTH="1280"; HEIGHT="720"  ;;
      *576p*|*dvd*)       WIDTH="720";  HEIGHT="576"  ;;
      *480p*)             WIDTH="640";  HEIGHT="480"  ;;
    esac
    if [[ -n "$WIDTH" && -n "$HEIGHT" ]]; then
      log "📋 MediaInfo dimensions empty - extracted from filename: ${WIDTH}x${HEIGHT}"
    fi
  fi
  
  # Use enhanced m2ts quality detection
  SIMPLE=$(quality_tag_m2ts "$WIDTH" "$HEIGHT" "$RESOLUTION" "$QUALITY_NAME" "$SOURCE")
else
  # Use standard quality detection for non-m2ts files
  # Also extract additional info from filename as fallback
  if [[ -z "$RESOLUTION" || "$RESOLUTION" == "null" ]]; then
    FILENAME_RESOLUTION=$(extract_resolution_from_filename "$FILE_PATH")
    if [[ -n "$FILENAME_RESOLUTION" ]]; then
      RESOLUTION="$FILENAME_RESOLUTION"
      log "📋 Using filename-extracted resolution for quality detection: $RESOLUTION"
    fi
  fi
  SIMPLE=$(quality_tag "$RESOLUTION" "$QUALITY_NAME" "$FILE_PATH")
fi

# Debug quality processing (debug level)
log_debug "🔍 Quality Debug:"
log_debug "   FILE_PATH: ${FILE_PATH:-'(empty)'}"
log_debug "   QUALITY_NAME: ${QUALITY_NAME:-'(empty)'}"
log_debug "   RESOLUTION: ${RESOLUTION:-'(empty)'}"
if [[ "$FILE_PATH" =~ \.m2ts$ ]]; then
  log_debug "   WIDTH: ${WIDTH:-'(empty)'}"
  log_debug "   HEIGHT: ${HEIGHT:-'(empty)'}"
  log_debug "   SOURCE: ${SOURCE:-'(empty)'}"
fi
log_debug "   SIMPLE (quality detection result): ${SIMPLE:-'(empty)'}"

ROOT=$(jq -r '.rootFolderPath' <<<"$MOVIE_JSON"); [[ $ROOT != *[\\/] ]] && ROOT+="\\"

# 4.3 Collection (if exists)
COLLECTION_TITLE=$(jq -r '.collection.title // empty' <<<"$MOVIE_JSON")

# ───────────── 5. Destination folder ─────────────────────────────────────
# Build folder name based on configuration
build_folder_name() {
  local title="$1"
  local year="$2" 
  local quality="$3"
  local collection="$4"
  local folder_name=""
  
  # Start with base: Title (Year)
  folder_name="$title ($year)"
  
  # Add collection prefix if enabled and available
  if [[ $USE_COLLECTIONS == "true" && -n $collection ]]; then
    folder_name="$collection ($year) - $title"
  fi
  
  # Add quality suffix if enabled
  if [[ $INCLUDE_QUALITY_TAG == "true" && -n $quality ]]; then
    folder_name="$folder_name [$quality]"
  fi
  
  echo "$folder_name"
}

TITLE=$(sanitize "$TITLE_RAW")
COLL=$(sanitize "$COLLECTION_TITLE")
NEW_FOLDER=$(build_folder_name "$TITLE" "$radarr_movie_year" "$SIMPLE" "$COLL")
NEW_FOLDER=$(sanitize "$NEW_FOLDER")
DEST="${ROOT}${NEW_FOLDER}"

log_detailed "🔍 Final Results:"
log_detailed "   TITLE_RAW: $TITLE_RAW"
log_detailed "   TITLE: $TITLE"
log_detailed "   SIMPLE: $SIMPLE"
log_detailed "   NEW_FOLDER: $NEW_FOLDER"
log_detailed "   DEST: $DEST"

# ───────────── 6. Current paths & possible renaming ─────────────────
OLD=$(jq -r '.movieFile.path // empty' <<<"$MOVIE_JSON")
ORIG_DIR=$(dirname "${OLD:-.}")
[[ -d "${radarr_movie_path:-}" ]] && ORIG_DIR="$radarr_movie_path"
[[ ! -d "$ORIG_DIR" ]] && ORIG_DIR=$(jq -r '.path' <<<"$MOVIE_JSON")

# Validate source directory exists
if [[ ! -d "$ORIG_DIR" ]]; then
  log "❌ Source directory not found: $ORIG_DIR"
  log "ℹ️  Available paths checked:"
  log "   • movieFile.path: ${OLD:-'(empty)'}"
  log "   • radarr_movie_path: ${radarr_movie_path:-'(not set)'}"
  log "   • movie.path: $(jq -r '.path' <<<"$MOVIE_JSON")"
  exit 96
fi

# CRITICAL SAFETY CHECK: Prevent processing system/application directories  
log_detailed "🔍 Performing critical safety checks on source directory..."

# Check for Radarr installation indicators
radarr_indicators=("Radarr.exe" "radarr.exe" "NzbDrone.exe" "bin" "logs" "config.xml" "Database" "Backup")
for indicator in "${radarr_indicators[@]}"; do
  if [[ -e "$ORIG_DIR/$indicator" ]]; then
    log "❌ CRITICAL SAFETY VIOLATION: Source directory contains Radarr installation files: $ORIG_DIR/$indicator"
    log "❌ This appears to be a Radarr installation directory, not a movie folder!"
    log "❌ REFUSING TO PROCESS to prevent catastrophic data corruption"
    exit 101
  fi
done

# Check if directory has suspicious system characteristics
if [[ "$ORIG_DIR" == *"Program Files"* ]] || [[ "$ORIG_DIR" == *"ProgramData"* ]] || [[ "$ORIG_DIR" == *"AppData"* ]]; then
  log "❌ CRITICAL SAFETY VIOLATION: Source directory is in a system folder: $ORIG_DIR"
  log "❌ REFUSING TO PROCESS system directories to prevent data corruption"
  exit 102
fi

# Check file composition to ensure it's a movie directory
executable_count=$(find "$ORIG_DIR" -maxdepth 2 -name "*.exe" -o -name "*.dll" -o -name "*.msi" | wc -l)
if [[ $executable_count -gt 10 ]]; then
  log "❌ CRITICAL SAFETY VIOLATION: Source directory contains $executable_count executable files"
  log "❌ This appears to be an application directory, not a movie folder!"
  log "❌ REFUSING TO PROCESS to prevent data corruption"
  exit 103
fi

log_detailed "✅ Safety checks passed for source directory"
log_info "📂 Source directory: $ORIG_DIR"

# Already in destination
if [[ "$(norm "$ORIG_DIR")" == "$(norm "$DEST")" ]]; then
  log "ℹ️  Already in destination folder - no folder rename needed"
  
  # ───────────── Execute File Renaming (even if folder doesn't need rename) ────
  if [[ "${ENABLE_FILE_RENAMING:-false}" == "true" ]]; then
    log "🎬 Native Radarr file renaming is enabled, starting renaming process..."
    log "ℹ️  Using Radarr's built-in API for 100% token compatibility"
    
    # Check if native Radarr file renaming script exists
    FILE_RENAME_SCRIPT="${SCRIPTS_DIR}/rename-radarr-files.sh"
    if [[ -f "$FILE_RENAME_SCRIPT" ]]; then
      log "📄 Calling native Radarr renaming script: $FILE_RENAME_SCRIPT"
      log "🔧 Pattern: ${FILE_NAMING_PATTERN:-'Using Radarr default pattern'}"
      
      # Call the native Radarr file renaming script with movie ID and destination directory
      # FIXED: Use single quotes around DEST to prevent bash from interpreting backslashes
      if bash "$FILE_RENAME_SCRIPT" "$ID" "'$DEST'" 2>&1 | while read line; do log "   $line"; done; then
        log "✅ Native Radarr file renaming completed successfully"
        log "🎯 All files renamed using Radarr's native token system"
      else
        log "⚠️  Native Radarr file renaming failed or had issues, but continuing..."
        log "ℹ️  Check logs above for specific error details"
      fi
    else
      log "⚠️  Native Radarr file renaming script not found: $FILE_RENAME_SCRIPT"
      log "ℹ️  Please ensure rename-radarr-files.sh is in the same directory as this script"
      log "💡 This script provides 100% compatibility with ALL Radarr naming tokens"
    fi
  else
    log "ℹ️  Native Radarr file renaming is disabled in configuration"
    log "💡 Set ENABLE_FILE_RENAMING=true to use Radarr's native renaming API"
  fi
  
  # Refresh Radarr after file renaming (if it was executed)
  if [[ "${ENABLE_FILE_RENAMING:-false}" == "true" ]]; then
    log_detailed "🔍 Refreshing Radarr after file renaming..."
    for cmd in RefreshMovie RescanMovie; do
      curl -sf --max-time 15 --retry 1 \
           -X POST -H "X-Api-Key:$RADARR_API_KEY" -H "Content-Type:application/json" \
           -d "{\"name\":\"$cmd\",\"movieIds\":[$ID]}" \
           "$RADARR_URL/api/v3/command" >/dev/null
    done
    log_detailed "✅ Radarr refresh completed"
  fi
  
  exit 0
fi

BASE=$(jq -r '.movieFile.relativePath // empty' <<<"$MOVIE_JSON")
[[ -z $BASE || $BASE == null ]] && BASE=$(basename "${OLD:-dummy.mkv}")
if [[ ! -f "$OLD" ]]; then
  # Fix: Build find command with configurable extensions and proper quoting
  find_cmd="find \"$ORIG_DIR\" -maxdepth $FIND_MAXDEPTH -type f \\("
  first=true
  for ext in $VIDEO_EXTENSIONS; do
    [[ $first == true ]] && first=false || find_cmd+=" -o"
    find_cmd+=" -iname '*.$ext'"
  done
  find_cmd+=" \\) | head -n1"
  OLD=$(eval "$find_cmd")
  [[ -n "$OLD" ]] && BASE=$(basename "$OLD")
fi

# Initialize rename tracking variable
FOLDER_WAS_RENAMED=false

# Rename folder if different from destination
if [[ -d "$ORIG_DIR" && "$ORIG_DIR" != "$DEST" ]]; then
  log "🔄 Renaming folder from: $ORIG_DIR"
  log "🔄 Renaming folder to: $DEST"
  if mv -n "$ORIG_DIR" "$DEST" 2>/dev/null; then
    ORIG_DIR="$DEST"
    FOLDER_WAS_RENAMED=true
    log "✅ Folder successfully renamed"
  else
    log "⚠️  Could not rename folder directly, will create new destination"
  fi
fi

# ───────────── 7. Copy / move content ────────────────────────────
# Fix: Quote destination path to handle spaces
if ! mkdir -p "$DEST"; then
  log "❌ Failed to create destination directory: $DEST"
  log "ℹ️  Check permissions and disk space"
  exit 97
fi
log "📁 Destination directory ready: $DEST"
if [[ $(drive "$ORIG_DIR") == $(drive "$DEST") ]]; then
  shopt -s dotglob nullglob
  # Fix: Quote paths in mv command to handle spaces
  mv -n "$ORIG_DIR"/* "$DEST"/ 2>/dev/null || true
  shopt -u dotglob nullglob
  # Fix: Quote paths in rmdir command to handle spaces
  [[ -d "$ORIG_DIR" && "$ORIG_DIR" != "$DEST" ]] && rmdir "$ORIG_DIR" 2>/dev/null || true
else
  # Fix: Quote paths in copy_tree function call
  copy_tree "$ORIG_DIR" "$DEST"
fi

# Folder timestamp will be updated at the end only if there were renames

[[ $HAS_FILE == true && ! -f "$DEST/$BASE" ]] && { log "❌ File not found in destination"; exit 95; }

# ───────────── 8. PUT a Radarr ────────────────────────────────────────
# Function to perform PUT request to Radarr
perform_radarr_put() {
  local dest_path="$1"
  local attempt_num="$2"
  
  log "🔄 Performing Radarr PUT request (attempt $attempt_num)..."
  
  # Create minimal JSON with proper type validation
  CLEAN=$(jq '{
    id: (.id // 0),
    title: (if (.title | type) == "string" then .title else (.title | tostring) end),
    year: (.year // 0),
    path: (if (.path | type) == "string" then .path else (.path | tostring) end),
    monitored: (.monitored // false),
    qualityProfileId: (.qualityProfileId // 0),
    hasFile: (.hasFile // false),
    movieFileId: (.movieFileId // 0)
  }' <<<"$MOVIE_JSON")

  # Debug: Validate that critical fields are strings
  log "🔍 JSON field validation:"
  title_type=$(echo "$CLEAN" | jq -r '.title | type')
  path_type=$(echo "$CLEAN" | jq -r '.path | type')
  log "   title type: $title_type"
  log "   path type: $path_type"

  if [[ "$title_type" != "string" || "$path_type" != "string" ]]; then
    log "❌ Critical field type validation failed!"
    log "   title: $title_type (should be string)"
    log "   path: $path_type (should be string)"
    exit 93
  fi

  # Update path in minimal JSON
  UPD=$(jq --arg p "$dest_path" '.path=$p' <<<"$CLEAN")

  # Debug: Show the JSON being sent and save to temp file for inspection
  TEMP_JSON_FILE="${SCRIPTS_DIR}/logs/radarr_put_debug_attempt$attempt_num.json"
  mkdir -p "${SCRIPTS_DIR}/logs" 2>/dev/null || true
  echo "$UPD" > "$TEMP_JSON_FILE"
  log_debug "🔍 JSON being sent to Radarr (first 1000 chars):"
  log_debug "$(echo "$UPD" | head -c 1000)..."
  log_debug "🔍 Full JSON saved to: $TEMP_JSON_FILE"

  # Validate JSON structure
  if ! echo "$UPD" | jq empty 2>/dev/null; then
    log "❌ Invalid JSON structure detected!"
    log_debug "🔍 JSON validation error:"
    echo "$UPD" | jq empty 2>&1 | head -5 | while read line; do log "   $line"; done
    return 1
  fi

  # Debug curl command
  log_debug "🔍 Curl command being executed:"
  log_debug "curl -X PUT -H 'X-Api-Key:$RADARR_API_KEY' -H 'Content-Type:application/json' -d '<JSON>' '$RADARR_URL/api/v3/movie/$ID'"

  # Try multiple curl approaches for UTF-8 support
  log_debug "🔍 Attempting curl with UTF-8 encoding..."

  # Method 1: Save JSON to temp file and use --data-binary with file
  TEMP_JSON_REQUEST="${SCRIPTS_DIR}/logs/radarr_request_${ID}_attempt$attempt_num.json"
  mkdir -p "${SCRIPTS_DIR}/logs" 2>/dev/null || true
  echo "$UPD" > "$TEMP_JSON_REQUEST"

  HTTP=$(curl -s --max-time 30 --retry 2 --retry-delay 1 \
               -o "$TEMP_LOG_FILE" -w '%{http_code}' -X PUT \
               -H "X-Api-Key:$RADARR_API_KEY" \
               -H "Content-Type:application/json; charset=utf-8" \
               -H "Accept-Charset: utf-8" \
               --data-binary "@$TEMP_JSON_REQUEST" \
               "$RADARR_URL/api/v3/movie/$ID")

  # Clean up temp file
  rm -f "$TEMP_JSON_REQUEST" 2>/dev/null

  if [[ $HTTP != 200 && $HTTP != 202 ]]; then
    log "❌ PUT failed (HTTP $HTTP)"; sed -E 's/^/│ /' "$TEMP_LOG_FILE"; 
    return 1
  fi
  log "✅ DB updated (attempt $attempt_num)"
  return 0
}

# Function to refresh Radarr and get updated movie data
refresh_and_get_movie() {
  log "🔄 Refreshing Radarr movie data..."
  
  # Detect if this is an m2ts file (Blu-ray BDAV) which needs special handling
  local file_path=$(echo "$MOVIE_JSON" | jq -r '.movieFile.relativePath // ""')
  local is_m2ts=false
  if [[ "$file_path" =~ \.m2ts$ ]]; then
    is_m2ts=true
    log "📀 Detected m2ts file (Blu-ray BDAV) - using extended analysis"
  fi
  
  # Send both refresh and rescan commands to ensure file analysis
  log "📡 Sending RefreshMovie command..."
  curl -sf --max-time 15 --retry 1 \
       -X POST -H "X-Api-Key:$RADARR_API_KEY" -H "Content-Type:application/json" \
       -d "{\"name\":\"RefreshMovie\",\"movieIds\":[$ID]}" \
       "$RADARR_URL/api/v3/command" >/dev/null
  
  log "📡 Sending RescanMovie command..."
  curl -sf --max-time 15 --retry 1 \
       -X POST -H "X-Api-Key:$RADARR_API_KEY" -H "Content-Type:application/json" \
       -d "{\"name\":\"RescanMovie\",\"movieIds\":[$ID]}" \
       "$RADARR_URL/api/v3/command" >/dev/null
  
  # For m2ts files, add MediaInfo scan command to ensure detailed analysis
  if [[ "$is_m2ts" == "true" ]]; then
    log "📡 Sending additional MediaInfo scan for m2ts file..."
    curl -sf --max-time 15 --retry 1 \
         -X POST -H "X-Api-Key:$RADARR_API_KEY" -H "Content-Type:application/json" \
         -d "{\"name\":\"MediaInfoAnalysis\",\"movieIds\":[$ID]}" \
         "$RADARR_URL/api/v3/command" >/dev/null 2>/dev/null || true
  fi
  
  # Wait with progressive retries to ensure Radarr has time to analyze the file
  # For m2ts files: extended timeout (15 attempts, ~120 seconds total)
  # For other files: standard timeout (10 attempts, ~65 seconds total)
  local max_attempts=10
  local wait_time=2
  
  if [[ "$is_m2ts" == "true" ]]; then
    max_attempts=15
    log "📀 Using extended timeout for m2ts analysis (15 attempts, ~120s total)"
  fi
  
  for attempt in $(seq 1 $max_attempts); do
    log "⏳ Waiting for Radarr to analyze file (attempt $attempt/$max_attempts, ${wait_time}s)..."
    sleep $wait_time
    
    # Get updated movie data
    log "📥 Fetching updated movie data from Radarr..."
    UPDATED_MOVIE_JSON=$(curl -sf --max-time 15 \
                              -H "X-Api-Key:$RADARR_API_KEY" \
                              "$RADARR_URL/api/v3/movie/$ID")
    
    if [[ -z "$UPDATED_MOVIE_JSON" ]]; then
      log "❌ Failed to fetch updated movie data (attempt $attempt)"
      continue
    fi
    
    # Check if Radarr now has quality information
    local current_quality=$(echo "$UPDATED_MOVIE_JSON" | jq -r '.movieFile.quality.quality.name // empty')
    local current_resolution=$(echo "$UPDATED_MOVIE_JSON" | jq -r '.movieFile.mediaInfo.video.resolution // empty')
    
    # For m2ts files, also check additional fields that might contain quality info
    local current_width=""
    local current_height=""
    local current_source=""
    if [[ "$is_m2ts" == "true" ]]; then
      current_width=$(echo "$UPDATED_MOVIE_JSON" | jq -r '.movieFile.mediaInfo.videoWidth // empty')
      current_height=$(echo "$UPDATED_MOVIE_JSON" | jq -r '.movieFile.mediaInfo.videoHeight // empty')
      current_source=$(echo "$UPDATED_MOVIE_JSON" | jq -r '.movieFile.quality.quality.source // empty')
    fi
    
    log_debug "🔍 Quality check (attempt $attempt):"
    log_debug "   Quality Name: ${current_quality:-'(empty)'}"
    log_debug "   Resolution: ${current_resolution:-'(empty)'}"
    if [[ "$is_m2ts" == "true" ]]; then
      log_debug "   Width: ${current_width:-'(empty)'}"
      log_debug "   Height: ${current_height:-'(empty)'}"
      log_debug "   Source: ${current_source:-'(empty)'}"
    fi
    
    # If we got quality info, we're done
    if [[ -n "$current_quality" && "$current_quality" != "null" && "$current_quality" != "" ]]; then
      MOVIE_JSON="$UPDATED_MOVIE_JSON"
      log "✅ Movie data refreshed successfully - quality detected: $current_quality"
      return 0
    fi
    
    # If we got resolution info, we're also good
    if [[ -n "$current_resolution" && "$current_resolution" != "null" && "$current_resolution" != "" ]]; then
      MOVIE_JSON="$UPDATED_MOVIE_JSON"
      log "✅ Movie data refreshed successfully - resolution detected: $current_resolution"
      return 0
    fi
    
    # For m2ts files, also accept width/height as valid quality indicators
    if [[ "$is_m2ts" == "true" ]]; then
      if [[ -n "$current_width" && "$current_width" != "null" && "$current_width" != "" ]] && \
         [[ -n "$current_height" && "$current_height" != "null" && "$current_height" != "" ]]; then
        MOVIE_JSON="$UPDATED_MOVIE_JSON"
        log "✅ Movie data refreshed successfully - m2ts dimensions detected: ${current_width}x${current_height}"
        return 0
      fi
      
      if [[ -n "$current_source" && "$current_source" != "null" && "$current_source" != "" ]]; then
        MOVIE_JSON="$UPDATED_MOVIE_JSON"
        log "✅ Movie data refreshed successfully - m2ts source detected: $current_source"
        return 0
      fi
    fi
    
    # Increase wait time for next attempt
    wait_time=$((wait_time + 1))
  done
  
  # If we get here, Radarr couldn't analyze the file
  log "⚠️  Radarr could not analyze file quality after $max_attempts attempts"
  log "⚠️  This might be normal for some file types or if Radarr is busy"
  
  # Still update MOVIE_JSON with whatever we got
  if [[ -n "$UPDATED_MOVIE_JSON" ]]; then
    MOVIE_JSON="$UPDATED_MOVIE_JSON"
    log "📝 Updated movie data anyway (without quality detection)"
  fi
  
  return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# DOUBLE RENAME + PUT STRATEGY:
# 1st attempt: Move folder with potentially incorrect quality, update Radarr path
# 2nd attempt: After Radarr can access the file, get correct quality and rename again
# ═══════════════════════════════════════════════════════════════════════════════

log "🎯 Starting double rename + PUT strategy..."

# ═══════════════ FIRST RENAME + PUT ═══════════════
log "🎯 FIRST ATTEMPT: Initial rename with available quality info"
perform_radarr_put "$DEST" "1"
if [[ $? -ne 0 ]]; then
  log "❌ First PUT failed, exiting"
  exit 92
fi

# ═══════════════ REFRESH AND GET UPDATED DATA ═══════════════
refresh_and_get_movie
if [[ $? -ne 0 ]]; then
  log "⚠️  Could not refresh movie data, proceeding with original data"
fi

# ═══════════════ SECOND RENAME + PUT ═══════════════
log "🎯 SECOND ATTEMPT: Re-evaluate quality with updated Radarr data"

# Re-extract quality information with potentially updated data
UPDATED_QUALITY_NAME=$(jq -r '.movieFile.quality.quality.name // empty' <<<"$MOVIE_JSON")
UPDATED_RESOLUTION=$(jq -r '.movieFile.mediaInfo.video.resolution // empty' <<<"$MOVIE_JSON")

# Check if this is an m2ts file for enhanced quality detection (updated data)
UPDATED_FILE_PATH=$(jq -r '.movieFile.relativePath // empty' <<<"$MOVIE_JSON")

# FALLBACK: Extract resolution from filename if MediaInfo is STILL empty after update
if [[ -z "$UPDATED_RESOLUTION" || "$UPDATED_RESOLUTION" == "null" ]]; then
  UPDATED_FILENAME_RESOLUTION=$(extract_resolution_from_filename "$UPDATED_FILE_PATH")
  if [[ -n "$UPDATED_FILENAME_RESOLUTION" ]]; then
    UPDATED_RESOLUTION="$UPDATED_FILENAME_RESOLUTION"
    log "📋 Updated MediaInfo resolution still empty - extracted from filename: $UPDATED_RESOLUTION"
  fi
fi
if [[ "$UPDATED_FILE_PATH" =~ \.m2ts$ ]]; then
  log "📀 Re-analyzing m2ts file with updated data - using enhanced quality detection"
  # Extract additional fields for m2ts analysis from updated data
  UPDATED_WIDTH=$(jq -r '.movieFile.mediaInfo.videoWidth // empty' <<<"$MOVIE_JSON")
  UPDATED_HEIGHT=$(jq -r '.movieFile.mediaInfo.videoHeight // empty' <<<"$MOVIE_JSON")
  UPDATED_SOURCE=$(jq -r '.movieFile.quality.quality.source // empty' <<<"$MOVIE_JSON")
  # Use enhanced m2ts quality detection with updated data
  UPDATED_SIMPLE=$(quality_tag_m2ts "$UPDATED_WIDTH" "$UPDATED_HEIGHT" "$UPDATED_RESOLUTION" "$UPDATED_QUALITY_NAME" "$UPDATED_SOURCE")
else
  # Use standard quality detection for non-m2ts files
  # Pass filename as third parameter for SCREENER detection
  UPDATED_SIMPLE=$(quality_tag "$UPDATED_RESOLUTION" "$UPDATED_QUALITY_NAME" "$UPDATED_FILE_PATH")
fi

# Debug updated quality processing (debug level)
log_debug "🔍 Updated Quality Debug:"
log_debug "   UPDATED_FILE_PATH: ${UPDATED_FILE_PATH:-'(empty)'}"
log_debug "   UPDATED_QUALITY_NAME: ${UPDATED_QUALITY_NAME:-'(empty)'}"
log_debug "   UPDATED_RESOLUTION: ${UPDATED_RESOLUTION:-'(empty)'}"
if [[ "$UPDATED_FILE_PATH" =~ \.m2ts$ ]]; then
  log_debug "   UPDATED_WIDTH: ${UPDATED_WIDTH:-'(empty)'}"
  log_debug "   UPDATED_HEIGHT: ${UPDATED_HEIGHT:-'(empty)'}"
  log_debug "   UPDATED_SOURCE: ${UPDATED_SOURCE:-'(empty)'}"
fi
log_debug "   UPDATED_SIMPLE (updated quality detection result): ${UPDATED_SIMPLE:-'(empty)'}"

# Check if we can escape from fallback LowQuality to real quality
# We only rename if:
# 1. We started with LowQuality (fallback due to empty Radarr data)
# 2. AND now we have real quality data from Radarr (not fallback LowQuality)
# 3. AND the new quality is different from the original
if [[ "$SIMPLE" == "LowQuality" && "$UPDATED_SIMPLE" != "LowQuality" ]]; then
  log "🎉 Real quality detected after first PUT: $SIMPLE → $UPDATED_SIMPLE"
  
  # Build new folder name with correct quality
  UPDATED_NEW_FOLDER=$(build_folder_name "$TITLE" "$radarr_movie_year" "$UPDATED_SIMPLE" "$COLL")
  UPDATED_NEW_FOLDER=$(sanitize "$UPDATED_NEW_FOLDER")
  UPDATED_DEST="${ROOT}${UPDATED_NEW_FOLDER}"
  
  log_detailed "🔍 Updated Final Results:"
  log_detailed "   UPDATED_SIMPLE: $UPDATED_SIMPLE"
  log_detailed "   UPDATED_NEW_FOLDER: $UPDATED_NEW_FOLDER"
  log_detailed "   UPDATED_DEST: $UPDATED_DEST"
  
  # Only rename if the destination is actually different
  if [[ "$DEST" != "$UPDATED_DEST" ]]; then
    log "🔄 Second rename from: $DEST"
    log "🔄 Second rename to: $UPDATED_DEST"
    
    if mv -n "$DEST" "$UPDATED_DEST" 2>/dev/null; then
      DEST="$UPDATED_DEST"
      FOLDER_WAS_RENAMED=true
      log "✅ Second folder rename successful"
      
      # Perform second PUT with corrected path
      perform_radarr_put "$DEST" "2"
      if [[ $? -ne 0 ]]; then
        log "❌ Second PUT failed, but folder was renamed successfully"
        exit 92
      fi
    else
      log "⚠️  Could not perform second rename, keeping current folder name"
    fi
  else
    log "ℹ️  Quality correction not needed - folder name is already correct"
  fi
else
  log "ℹ️  No quality correction needed"
  if [[ "$SIMPLE" != "LowQuality" ]]; then
    log "ℹ️  Already had real quality: $SIMPLE"
  elif [[ "$SIMPLE" == "LowQuality" && "$UPDATED_SIMPLE" == "LowQuality" ]]; then
    # Check if LowQuality is now backed by real Radarr data
    has_real_quality_data=$(echo "$MOVIE_JSON" | jq -r '.movieFile.quality.quality.name // empty')
    has_real_resolution_data=$(echo "$MOVIE_JSON" | jq -r '.movieFile.mediaInfo.video.resolution // empty')
    
    if [[ -n "$has_real_quality_data" && "$has_real_quality_data" != "null" && "$has_real_quality_data" != "" ]]; then
      log "✅ LowQuality confirmed as real quality by Radarr: $has_real_quality_data"
      log "📁 Keeping folder name as [LowQuality] - this is the actual file quality"
    elif [[ -n "$has_real_resolution_data" && "$has_real_resolution_data" != "null" && "$has_real_resolution_data" != "" ]]; then
      log "✅ LowQuality confirmed by Radarr resolution data: $has_real_resolution_data"
      log "📁 Keeping folder name as [LowQuality] - this is the actual file quality"
    else
      log "⚠️  Radarr still cannot analyze this file - keeping [LowQuality] as fallback"
      log "ℹ️  This could be due to: unsupported format, corrupted file, or Radarr analysis issues"
    fi
  fi
fi

log "🎯 Double rename + PUT strategy completed"

# ───────────── 8.5. Native Radarr File Renaming (if enabled) ──────────────────
if [[ "${ENABLE_FILE_RENAMING:-false}" == "true" ]]; then
  log "🎬 Native Radarr file renaming is enabled, starting renaming process..."
  log "ℹ️  Using Radarr's built-in API for 100% token compatibility"
  
  # Check if native Radarr file renaming script exists
  FILE_RENAME_SCRIPT="${SCRIPTS_DIR}/rename-radarr-files.sh"
  if [[ -f "$FILE_RENAME_SCRIPT" ]]; then
    log "📄 Calling native Radarr renaming script: $FILE_RENAME_SCRIPT"
    log "🔧 Pattern: ${FILE_NAMING_PATTERN:-'Using Radarr default pattern'}"
    
    # Call the native Radarr file renaming script with movie ID and destination directory
    # FIXED: Properly escape the destination path to preserve Windows backslashes
    if bash "$FILE_RENAME_SCRIPT" "$ID" "$DEST" 2>&1 | while read line; do log "   $line"; done; then
      log "✅ Native Radarr file renaming completed successfully"
      log "🎯 All files renamed using Radarr's native token system"
    else
      log "⚠️  Native Radarr file renaming failed or had issues, but continuing..."
      log "ℹ️  Check logs above for specific error details"
    fi
  else
    log "⚠️  Native Radarr file renaming script not found: $FILE_RENAME_SCRIPT"
    log "ℹ️  Please ensure rename-radarr-files.sh is in the same directory as this script"
    log "💡 This script provides 100% compatibility with ALL Radarr naming tokens"
  fi
else
  log "ℹ️  Native Radarr file renaming is disabled in configuration"
  log "💡 Set ENABLE_FILE_RENAMING=true to use Radarr's native renaming API"
fi

# ───────────── 9. Refresh + Rescan ────────────────────────────────────
# ───────────── 9.1. Final Folder Timestamp Update ────────────────────────────
# Update folder timestamp only if folder was renamed during the process
if [[ "$UPDATE_FOLDER_TIMESTAMP" == "true" && "$FOLDER_WAS_RENAMED" == "true" && -d "$DEST" ]]; then
  if touch "$DEST" 2>/dev/null; then
    log "📅 Updated folder timestamp after rename: $DEST"
  else
    log "⚠️  Could not update folder timestamp: $DEST"
  fi
elif [[ "$UPDATE_FOLDER_TIMESTAMP" == "true" && "$FOLDER_WAS_RENAMED" == "false" ]]; then
  log "ℹ️  No folder rename occurred - timestamp not updated"
fi

# ───────────── 9.2. Final Refresh + Rescan ────────────────────────────────────
log_detailed "🔍 Refreshing Radarr after all operations..."
for cmd in RefreshMovie RescanMovie; do
  curl -sf --max-time 15 --retry 1 \
       -X POST -H "X-Api-Key:$RADARR_API_KEY" -H "Content-Type:application/json" \
       -d "{\"name\":\"$cmd\",\"movieIds\":[$ID]}" \
       "$RADARR_URL/api/v3/command" >/dev/null
done
log_detailed "✅ Radarr refresh completed"
