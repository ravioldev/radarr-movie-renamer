#!/usr/bin/env bash
[ -z "$BASH_VERSION" ] && exec /usr/bin/env bash "$0" "$@"
set -euo pipefail
export LC_ALL=C.UTF-8

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

log(){ printf '[%s] %s\n' "$(date +'%F %T')" "$*" >&2; }

# Auto-detect language preferences from Radarr (optional)
detect_radarr_language_preference() {
  [[ $AUTO_DETECT_FROM_RADARR != "true" ]] && return 1
  
  log "🔍 Attempting to detect language preference from Radarr..."
  
  # Try to get Radarr's UI settings
  local ui_config=$(curl -sf --max-time 10 --retry 1 \
                         -H "X-Api-Key:$RADARR_API_KEY" \
                         "$RADARR_URL/api/v3/config/ui" 2>/dev/null)
  
  if [[ $? -eq 0 && -n $ui_config ]]; then
    local ui_language=$(jq -r '.uiLanguage // empty' <<<"$ui_config" 2>/dev/null)
    if [[ -n $ui_language && $ui_language != "null" ]]; then
      # Convert UI language codes to ISO 639-1 (e.g., "en-US" -> "en")
      ui_language=${ui_language:0:2}
      log "✅ Detected Radarr UI language: $ui_language"
      echo "$ui_language"
      return 0
    fi
  fi
  
  log "ℹ️  Could not detect language preference from Radarr"
  return 1
}

# TMDB integration (optional) - Only called for native language movies
fetch_tmdb_data() {
  local tmdb_id="$1"
  local language="$2"
  
  # Validate TMDB API key
  if [[ -z $TMDB_API_KEY ]]; then
    log "ℹ️  TMDB disabled (no API key configured)"
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
  
  for v; do
    # Skip empty or null values
    [[ -z "$v" || "$v" == "null" ]] && continue
    
    case "${v,,}" in
      # High resolution formats
      *2160*|*4k*) echo "2160p"; return ;;
      *1440*)      echo "1440p"; return ;;
      *1080*)      echo "1080p"; return ;;
      *720*)       echo "720p" ; return ;;
      
      # DVD and standard definition formats
      *576*|*dvd*) echo "DVD-Rip"; return ;;
      *480*)       echo "480p" ; return ;;
      
      # Specific Radarr quality names
      *sdtv*)      echo "480p" ; return ;;  # Map SDTV to 480p
      *webdl*)     echo "1080p"; return ;;  # Common WebDL format
      *bluray*)    echo "1080p"; return ;;  # Common Bluray format
      *webrip*)    echo "1080p"; return ;;  # Common WebRip format
    esac
  done
  # Fallback if no patterns matched
  echo "LowQuality"
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
# Fix: Quote paths in rsync command to handle spaces
copy_tree(){ rsync $RSYNC_OPTIONS --chmod="$FILE_PERMISSIONS_DIR,$FILE_PERMISSIONS_FILE" "$1/" "$2/"; }
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
  
  log "🔤 Language preference: ${native_lang:-'(none)'} → ${fallback_lang}"
  log "🌍 Movie original language: '${orig_lang_name}' → '${orig_lang}'"
  log "🔍 Language comparison: native='${native_lang}' vs original='${orig_lang}'"
  
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
SIMPLE=$(quality_tag "$QUALITY_NAME" "$RESOLUTION")

# Debug quality processing
log "🔍 Quality Debug:"
log "   QUALITY_NAME: ${QUALITY_NAME:-'(empty)'}"
log "   RESOLUTION: ${RESOLUTION:-'(empty)'}"
log "   SIMPLE (quality_tag result): ${SIMPLE:-'(empty)'}"

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

log "🔍 Final Results:"
log "   TITLE_RAW: $TITLE_RAW"
log "   TITLE: $TITLE"
log "   SIMPLE: $SIMPLE"
log "   NEW_FOLDER: $NEW_FOLDER"
log "   DEST: $DEST"

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

log "📂 Source directory: $ORIG_DIR"

# Already in destination
if [[ "$(norm "$ORIG_DIR")" == "$(norm "$DEST")" ]]; then
  log "ℹ️  Already in destination folder; nothing to do"; exit 0
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

# Rename folder if different from destination
if [[ -d "$ORIG_DIR" && "$ORIG_DIR" != "$DEST" ]]; then
  log "🔄 Renaming folder from: $ORIG_DIR"
  log "🔄 Renaming folder to: $DEST"
  if mv -n "$ORIG_DIR" "$DEST" 2>/dev/null; then
    ORIG_DIR="$DEST"
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
[[ $HAS_FILE == true && ! -f "$DEST/$BASE" ]] && { log "❌ File not found in destination"; exit 95; }

# ───────────── 8. PUT a Radarr ────────────────────────────────────────
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
UPD=$(jq --arg p "$DEST" '.path=$p' <<<"$CLEAN")

# Debug: Show the JSON being sent and save to temp file for inspection
TEMP_JSON_FILE="./logs/radarr_put_debug.json"
echo "$UPD" > "$TEMP_JSON_FILE"
log "🔍 JSON being sent to Radarr (first 1000 chars):"
log "$(echo "$UPD" | head -c 1000)..."
log "🔍 Full JSON saved to: $TEMP_JSON_FILE"

# Validate JSON structure
if ! echo "$UPD" | jq empty 2>/dev/null; then
  log "❌ Invalid JSON structure detected!"
  log "🔍 JSON validation error:"
  echo "$UPD" | jq empty 2>&1 | head -5 | while read line; do log "   $line"; done
fi

# Debug curl command
log "🔍 Curl command being executed:"
log "curl -X PUT -H 'X-Api-Key:$RADARR_API_KEY' -H 'Content-Type:application/json' -d '<JSON>' '$RADARR_URL/api/v3/movie/$ID'"

# Try multiple curl approaches for UTF-8 support
log "🔍 Attempting curl with UTF-8 encoding..."

# Method 1: Save JSON to temp file and use --data-binary with file
TEMP_JSON_REQUEST="./logs/radarr_request_$ID.json"
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
  log "❌ PUT failed (HTTP $HTTP)"; sed -E 's/^/│ /' "$TEMP_LOG_FILE"; exit 92
fi
log "✅ DB updated"

# ───────────── 9. Refresh + Rescan ────────────────────────────────────
for cmd in RefreshMovie RescanMovie; do
  curl -sf --max-time 15 --retry 1 \
       -X POST -H "X-Api-Key:$RADARR_API_KEY" -H "Content-Type:application/json" \
       -d "{\"name\":\"$cmd\",\"movieIds\":[$ID]}" \
       "$RADARR_URL/api/v3/command" >/dev/null
done
log "🔍 Refresh + Rescan sent"
