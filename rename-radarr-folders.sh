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

log(){ printf '[%s] %s\n' "$(date +'%F %T')" "$*"; }

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

# TMDB integration (optional)
fetch_tmdb_data() {
  local tmdb_id="$1"
  local language="$2"
  
  [[ -z $TMDB_API_KEY ]] && { log "ℹ️  TMDB disabled (no API key)"; return 1; }
  [[ -z $tmdb_id || $tmdb_id == null ]] && { log "ℹ️  No TMDB ID available"; return 1; }
  
  log "🎬 Fetching TMDB data (ID: $tmdb_id, Lang: $language)"
  
  local tmdb_url="https://api.themoviedb.org/3/movie/$tmdb_id"
  [[ -n $language ]] && tmdb_url+="?language=$language"
  
  # Add timeout and retry logic for TMDB API
  local tmdb_json=$(curl -sf --max-time 10 --retry 2 --retry-delay 1 \
                         -H "Authorization: Bearer $TMDB_API_KEY" \
                         "$tmdb_url" 2>/dev/null)
  
  if [[ $? -eq 0 && -n $tmdb_json ]]; then
    log "✅ TMDB data fetched successfully"
    echo "$tmdb_json"
    return 0
  else
    log "⚠️  TMDB fetch failed (timeout or API error)"
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
      *2160*|*4k*) echo "2160p"; return ;;
      *1440*)      echo "1440p"; return ;;
      *1080*)      echo "1080p"; return ;;
      *720*)       echo "720p" ; return ;;
      *576*|*dvd*) echo "DVD-Rip"; return ;;
      *480*)       echo "480p" ; return ;;
    esac
  done
  # Fallback if no patterns matched
  echo "LowQuality"
}

sanitize(){             # Clean for Windows (maintains UTF-8)
  local s="$1"
  s=$(perl -CS -Mutf8 -pe 's/[♥\x{2764}]//g; s/ć/c/g; s/Ć/C/g' <<<"$s")
  s=${s//[$'\u2018\u2019\u201A\u201B\u0060\u00B4']/\'}
  s=${s//[•·–—]/-}
  s=$(perl -CS -Mutf8 -pe 's/[:\x{F03A}\x{FF1A}\x{FE55}\x{A789}]/ - /g' <<<"$s")
  s=$(perl -CS -Mutf8 -pe 's![/\\\x{2215}\x{2044}]!-!g' <<<"$s")
  s=${s//[<>\"?*|]/ }
  s=$(sed -E 's/[[:space:]]+/ /g; s/ - +/ - /g; s/^ //; s/ $//' <<<"$s")
  [[ -z $s ]] && s="$1"
  printf '%s' "$s"
}

drive(){ echo "${1%%:*}"; }
copy_tree(){ rsync $RSYNC_OPTIONS --chmod=$FILE_PERMISSIONS_DIR,$FILE_PERMISSIONS_FILE "$1"/ "$2"/; }
norm(){ tr '\\' '/' <<<"$1"; }

# ───────────── 3. Arguments var=val ──────────────────────────────────
for a in "$@"; do case $a in
  radarr_movie_id=*)          radarr_movie_id=${a#*=} ;;
  radarr_movie_title=*)       radarr_movie_title=${a#*=} ;;
  radarr_movie_year=*)        radarr_movie_year=${a#*=} ;;
  radarr_moviefile_quality=*) radarr_moviefile_quality=${a#*=} ;;
esac; done
: "${radarr_movie_id:?}" "${radarr_movie_title:?}" "${radarr_movie_year:?}"
ID=$radarr_movie_id

# ───────────── 4. Metadata ───────────────────────────────────────────
MOVIE_JSON=$(curl -sf --max-time 30 --retry 2 --retry-delay 1 \
                  -H "X-Api-Key:$RADARR_API_KEY" \
                  "$RADARR_URL/api/v3/movie/$ID") || exit 90

HAS_FILE=$(jq -r '.hasFile' <<<"$MOVIE_JSON")
QP_ID=$(jq  -r '.qualityProfileId' <<<"$MOVIE_JSON")
LANG=$(jq   -r '.originalLanguage // empty' <<<"$MOVIE_JSON")

# 4.1 Preferred title with native language detection
get_preferred_title() {
  local movie_json="$1"
  local native_lang="$2"
  local fallback_lang="$3"
  local title=""
  
  # Auto-detect language preference from Radarr if enabled
  if [[ -z $native_lang ]] && [[ $AUTO_DETECT_FROM_RADARR == "true" ]]; then
    native_lang=$(detect_radarr_language_preference)
  fi
  
  local orig_lang=$(jq -r '.originalLanguage // empty' <<<"$movie_json")
  
  # Determine which language to use based on movie's original language
  local target_lang="$fallback_lang"
  if [[ -n $native_lang && $orig_lang == "$native_lang" ]]; then
    target_lang="$native_lang"
    log "🌍 Movie is originally in $native_lang - using native language preference"
  else
    log "🌐 Movie is originally in ${orig_lang:-'unknown'} - using fallback language ($fallback_lang)"
  fi
  
  # Step 1: If using native language and movie is originally in that language, prefer original title
  if [[ $target_lang == "$native_lang" && $orig_lang == "$native_lang" ]]; then
    title=$(jq -r '.originalTitle // .title' <<<"$movie_json")
    [[ -n $title && $title != null ]] && { log "✅ Using original title (native language)"; echo "$title"; return; }
  fi
  
  # Step 2: Look for alternative title in target language
  title=$(jq -r ".alternativeTitles[]? | select(.language==\"$target_lang\") | .title" <<<"$movie_json" | head -n1)
  [[ -n $title && $title != null ]] && { log "✅ Using $target_lang alternative title"; echo "$title"; return; }
  
  # Step 3: Look for alternative title in fallback language (if different from target)
  if [[ $target_lang != "$fallback_lang" ]]; then
    title=$(jq -r ".alternativeTitles[]? | select(.language==\"$fallback_lang\") | .title" <<<"$movie_json" | head -n1)
    [[ -n $title && $title != null ]] && { log "✅ Using $fallback_lang fallback title"; echo "$title"; return; }
  fi
  
  # Step 4: Use default title from Radarr
  title=$(jq -r '.title' <<<"$movie_json")
  [[ -n $title && $title != null ]] && { log "✅ Using default Radarr title"; echo "$title"; return; }
  
  # Step 5: Final fallback to parameter
  log "⚠️  Using parameter title (last resort)"
  echo "$radarr_movie_title"
}

TITLE_RAW=$(get_preferred_title "$MOVIE_JSON" "$NATIVE_LANGUAGE" "$FALLBACK_LANGUAGE")

# 4.2 Quality
QUALITY_NAME=${radarr_moviefile_quality:-$(jq -r '.movieFile.quality.quality.name // empty' <<<"$MOVIE_JSON")}
RESOLUTION=$(jq -r '.movieFile.mediaInfo.video.resolution // empty' <<<"$MOVIE_JSON")
SIMPLE=$(quality_tag "$QUALITY_NAME" "$RESOLUTION")

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
  
  log "🏗️  Building folder name..."
  log "   Title: $title"
  log "   Year: $year"
  log "   Quality: $quality"
  log "   Collection: ${collection:-'(none)'}"
  log "   Use collections: $USE_COLLECTIONS"
  log "   Include quality: $INCLUDE_QUALITY_TAG"
  
  # Start with base: Title (Year)
  folder_name="$title ($year)"
  
  # Add collection prefix if enabled and available
  if [[ $USE_COLLECTIONS == "true" && -n $collection ]]; then
    folder_name="$collection ($year) - $title"
    log "✅ Using collection format: Collection (Year) - Title"
  else
    log "✅ Using simple format: Title (Year)"
  fi
  
  # Add quality suffix if enabled
  if [[ $INCLUDE_QUALITY_TAG == "true" && -n $quality ]]; then
    folder_name="$folder_name [$quality]"
    log "✅ Added quality tag: [$quality]"
  else
    log "ℹ️  Quality tag omitted"
  fi
  
  log "🎯 Final folder name: $folder_name"
  echo "$folder_name"
}

TITLE=$(sanitize "$TITLE_RAW")
COLL=$(sanitize "$COLLECTION_TITLE")
NEW_FOLDER=$(build_folder_name "$TITLE" "$radarr_movie_year" "$SIMPLE" "$COLL")
NEW_FOLDER=$(sanitize "$NEW_FOLDER")
DEST="${ROOT}${NEW_FOLDER}"
log "🔄 Destination → $DEST"

# ───────────── 6. Current paths & possible renaming ─────────────────
OLD=$(jq -r '.movieFile.path // empty' <<<"$MOVIE_JSON")
ORIG_DIR=$(dirname "${OLD:-.}")
[[ -d "${radarr_movie_path:-}" ]] && ORIG_DIR="$radarr_movie_path"
[[ ! -d $ORIG_DIR ]] && ORIG_DIR=$(jq -r '.path' <<<"$MOVIE_JSON")

# Validate source directory exists
if [[ ! -d $ORIG_DIR ]]; then
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
if [[ ! -f $OLD ]]; then
  # Build find command with configurable extensions
  find_cmd="find \"$ORIG_DIR\" -maxdepth $FIND_MAXDEPTH -type f \\("
  first=true
  for ext in $VIDEO_EXTENSIONS; do
    [[ $first == true ]] && first=false || find_cmd+=" -o"
    find_cmd+=" -iname '*.$ext'"
  done
  find_cmd+=" \\) | head -n1"
  OLD=$(eval "$find_cmd")
  [[ -n $OLD ]] && BASE=$(basename "$OLD")
fi

# Rename only tag
if [[ -d $ORIG_DIR && "$ORIG_DIR" != "$DEST" && "${ORIG_DIR%[*}" == "${DEST%[*}" ]]; then
  mv -n "$ORIG_DIR" "$DEST" && ORIG_DIR="$DEST" && log "📂 Folder renamed to new quality"
fi
[[ ! -d $DEST ]] && { DEST="$ORIG_DIR"; NEW_FOLDER=$(basename "$DEST"); }

# ───────────── 7. Copy / move content ────────────────────────────
if ! mkdir -p "$DEST"; then
  log "❌ Failed to create destination directory: $DEST"
  log "ℹ️  Check permissions and disk space"
  exit 97
fi
log "📁 Destination directory ready: $DEST"
if [[ $(drive "$ORIG_DIR") == $(drive "$DEST") ]]; then
  shopt -s dotglob nullglob
  mv -n "$ORIG_DIR"/* "$DEST"/ 2>/dev/null || true
  shopt -u dotglob nullglob
  [[ -d $ORIG_DIR && "$ORIG_DIR" != "$DEST" ]] && rmdir "$ORIG_DIR" 2>/dev/null || true
else
  copy_tree "$ORIG_DIR" "$DEST"
fi
[[ $HAS_FILE == true && ! -f "$DEST/$BASE" ]] && { log "❌ File not found in destination"; exit 95; }

# ───────────── 8. PUT a Radarr ────────────────────────────────────────
CLEAN=$(jq 'del(
  .images,.statistics,.alternateTitles,.movieFile.mediaInfo,
  .overview,.studio,.keywords,.ratings
)' <<<"$MOVIE_JSON")

if [[ $HAS_FILE == true ]]; then
  UPD=$(jq --arg p "$DEST" --arg n "$NEW_FOLDER" --arg b "$BASE" --argjson q "$QP_ID" '
    .folderPath=$p | .folderName=$n | .path=$p |
    .qualityProfileId=$q |
    .movieFile.path=($p+"\\"+$b) | .movieFile.relativePath=$b
  ' <<<"$CLEAN")
else
  UPD=$(jq --arg p "$DEST" --arg n "$NEW_FOLDER" --argjson q "$QP_ID" '
    .folderPath=$p | .folderName=$n | .path=$p | .qualityProfileId=$q
  ' <<<"$CLEAN")
fi

HTTP=$(curl -s --max-time 30 --retry 2 --retry-delay 1 \
             -o "$TEMP_LOG_FILE" -w '%{http_code}' -X PUT \
             -H "X-Api-Key:$RADARR_API_KEY" -H "Content-Type:application/json" \
             -d "$UPD" "$RADARR_URL/api/v3/movie/$ID")

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
