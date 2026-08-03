#!/bin/bash

# Universal iPod Video Conversion Tool (Rockbox + Official Apple Firmware)
# Programmed by Elliott Schott
# Version 2.7.0
# Changelog 2.7.0: Fixed a bug where official-firmware (H.264/AAC) conversions
#                   could develop a high-pitched squeal/chirp every 30-60
#                   seconds - this is a documented defect in ffmpeg's built-in
#                   "aac" encoder (its Perceptual Noise Substitution logic
#                   mis-fires on certain high-frequency/transient content,
#                   e.g. sibilant speech), so it's now disabled, plus a
#                   15kHz cutoff is set to keep the encoder out of the
#                   problematic near-Nyquist range it handles poorly at
#                   these bitrates - both are skipped gracefully on ffmpeg
#                   builds too old to support the option. Dependency check
#                   now also verifies "bc" (used throughout for all bitrate/
#                   progress math) and shows a live checklist instead of a
#                   static "please wait", with install hints that adapt to
#                   apt/dnf/pacman/apk in addition to Homebrew. Every iPod
#                   resolution and H.264 profile/level was re-verified a
#                   second time directly against Apple's archived tech-spec
#                   pages - all were already correct, no changes needed.
#                   Source/destination path errors are now more specific
#                   (permission-denied vs. does-not-exist vs. wrong-type),
#                   and a failed output-folder creation now shows the
#                   actual OS error instead of a generic message. Added a
#                   dot-based step indicator (Step 1-4) and a total-elapsed-
#                   time line on the finish screen. Replaced "OR" in
#                   "Enter path to source video OR folder:" with lowercase
#                   "or".
# Version 2.6.0
# Changelog 2.6.0: Added a self-syntax-check at launch so a corrupted file
#                   (e.g. from a text editor smart-quoting it) fails
#                   instantly with a clear message instead of crashing
#                   deep inside the wizard with a raw shell error. Also:
#                   validates ffprobe is installed; skips (rather than
#                   blindly attempts) unreadable/non-video input files;
#                   checks the output location is writable before
#                   grinding through file analysis; captures and shows
#                   ffmpeg's actual error output on a failed conversion
#                   instead of just silently not counting it as success;
#                   removes a zero-byte output file left behind by a
#                   failed conversion; the two hardware case statements
#                   are reformatted to one-assignment-per-line (more
#                   robust and readable than dense semicolon-chained
#                   one-liners) with a defensive fallback for an
#                   out-of-range selection.
# Version 2.5.0
# Changelog 2.5.0: Rockbox-vs-stock question is now asked after source
#                   and destination are entered, as Step 1 of 4 (hardware,
#                   fitting, and volume shifted to Steps 2-4 accordingly).
#                   Removed iPod Touch support (too much spec variance
#                   across generations to keep accurate). Re-verified
#                   every remaining resolution against Apple's own specs -
#                   no corrections needed. Fixed a bug where switching
#                   Rockbox/stock answers on a re-visit to Step 1 could
#                   leave the hardware menu's selection on a stale,
#                   out-of-range index. Destination prompt's back-hotkey
#                   hint text is gone (the 'b'/'back' feature still
#                   works, just undocumented); B is also now a back
#                   hotkey in every arrow-key menu, alongside Backspace.
# Version 2.4.0
# Changelog 2.4.0: Audio now encodes at the documented 48kHz for official
#                   firmware instead of 44.1kHz.
# Version 2.3.0
# Changelog 2.3.0: Non-Rockbox (stock Apple firmware) devices are now
#                   fully supported - selecting "No" at the gate question
#                   picks from official video-capable iPods and encodes
#                   H.264/AAC .m4v sized to that device's real screen
#                   resolution, instead of just listing them.
# Version 2.2.0
# Changelog 2.2.0: Added a Rockbox vs. stock-firmware gate question up
#                   front; answering "No" lists officially video-capable
#                   Apple-firmware iPods instead of running the wizard.
# Changelog 2.1.0: Added back-button navigation (Backspace / Left arrow)
#                   to every menu, and a "b"/"back" shortcut on the
#                   destination path prompt.

# Hide the terminal cursor immediately on script launch
printf "\e[?25l"

# Automatically restore the cursor and clean temporary entries when exiting
cleanup() {
    printf "\e[?25h"
    stty echo icanon 2>/dev/null
    rm -f "$PROGRESS_LOG" "$ERROR_LOG" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Function to center text based on current terminal columns
print_center() {
    local text="$1"
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)
    local text_length=${#text}
    
    # Strip ANSI escape codes from character count calculation if they are passed
    local clean_text
    clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    text_length=${#clean_text}

    local padding=$(( (term_width - text_length) / 2 ))
    if [ $padding -lt 0 ]; then padding=0; fi
    
    printf "%${padding}s%b\n" "" "$text"
}

# Function to center a solid dividing line
print_center_line() {
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)
    if [ $term_width -gt 50 ]; then term_width=50; fi # Cap visual width for clean scaling
    
    local line
    line=$(printf '%0.s-' $(seq 1 $term_width))
    print_center "$line"
}

# Clear and draw centered main header
draw_header() {
    clear
    print_center "=== Universal iPod Video Converter ==="
    print_center "=== Version \033[1m2.7.0\033[22m ==="
    print_center_line
    if [ -n "$IS_ROCKBOX" ]; then
        if [ "$IS_ROCKBOX" = true ]; then
            print_center "\e[2mMode: Rockbox (.mpg / MPEG-1)\e[0m"
        else
            print_center "\e[2mMode: Official Apple Firmware (.m4v / H.264)\e[0m"
        fi
    fi
    echo
}

draw_header
print_center "Checking dependencies..."
echo

# Self-check: verify this file wasn't corrupted before doing any real work.
# The most common cause is a text editor "smart-quoting" it (TextEdit,
# Notes, and Pages all do this by default to .sh files opened for editing
# on macOS), which silently turns straight quotes into curly ones and
# breaks every string literal after that point. Without this check, a
# corrupted file can run several menus successfully - since a live script
# run only fails once it actually reaches the bad code - and then crash
# with a raw, confusing shell error deep inside the wizard instead of
# failing clearly up front.
if ! SYNTAX_CHECK=$(bash -n "$0" 2>&1); then
    clear
    printf "\e[41m Error: \e[0m This script file looks corrupted or was edited by\n"
    printf "something that changed plain quotes into curly \"smart quotes\" -\n"
    printf "a common side effect of opening .sh files in TextEdit, Notes, or\n"
    printf "Pages on macOS.\n\n"
    printf "Please re-download a fresh copy, and if you need to edit it, use a\n"
    printf "plain-text editor instead (e.g. VS Code, BBEdit, nano).\n\n"
    printf "\e[2mDetails: %s\e[0m\n\n" "$SYNTAX_CHECK"
    printf "\e[30;47m> [OK]\e[0m\n"
    printf "\e[?25h"
    read -r
    exit 1
fi

command -v brew >/dev/null 2>&1 && BREW_INSTALLED=true || BREW_INSTALLED=false

# Suggests a platform-appropriate install command for a missing dependency
# instead of only ever assuming Homebrew - the old version gave no install
# hint at all when running on Linux, which this script also supports.
suggest_install() {
    local pkg="$1"
    if [ "$BREW_INSTALLED" = true ]; then
        echo "brew install $pkg"
    elif command -v apt >/dev/null 2>&1; then
        echo "sudo apt install $pkg"
    elif command -v dnf >/dev/null 2>&1; then
        echo "sudo dnf install $pkg"
    elif command -v pacman >/dev/null 2>&1; then
        echo "sudo pacman -S $pkg"
    elif command -v apk >/dev/null 2>&1; then
        echo "sudo apk add $pkg"
    fi
}

DEPS_OK=true

if command -v ffmpeg >/dev/null 2>&1; then
    printf "  \e[32m✓\e[0m ffmpeg\n"
else
    printf "  \e[31m✗\e[0m ffmpeg\n"
    DEPS_OK=false
fi

if command -v ffprobe >/dev/null 2>&1; then
    printf "  \e[32m✓\e[0m ffprobe\n"
else
    printf "  \e[31m✗\e[0m ffprobe\n"
    DEPS_OK=false
fi

# bc drives every bit of bitrate/percentage/ETA math further down. Without
# it, those calculations used to silently return an empty string (e.g. a
# blank bitrate handed straight to ffmpeg), which failed confusingly deep
# inside the conversion instead of with a clear message right here.
if command -v bc >/dev/null 2>&1; then
    printf "  \e[32m✓\e[0m bc\n"
else
    printf "  \e[31m✗\e[0m bc\n"
    DEPS_OK=false
fi

if [ "$DEPS_OK" = false ]; then
    echo
    printf "\e[41m Error: \e[0m Missing one or more required tools above.\n\n"

    if ! command -v ffmpeg >/dev/null 2>&1; then
        HINT=$(suggest_install ffmpeg)
        [ -n "$HINT" ] && echo "  $HINT"
    elif ! command -v ffprobe >/dev/null 2>&1; then
        echo "  ffprobe normally installs alongside ffmpeg, so your ffmpeg"
        echo "  install looks incomplete - try reinstalling it."
        [ "$BREW_INSTALLED" = true ] && echo "  (brew reinstall ffmpeg)"
    fi

    if ! command -v bc >/dev/null 2>&1; then
        HINT=$(suggest_install bc)
        [ -n "$HINT" ] && echo "  $HINT"
    fi

    echo
    printf "\e[30;47m> [OK]\e[0m\n"
    printf "\e[?25h"
    read -r
    exit 1
fi

# Prints a small dot progress indicator for the 4-step wizard
# (green/filled = done, cyan/filled = current, dim/hollow = upcoming).
draw_step_dots() {
    local current=$1
    local total=4
    local dots=""
    local i
    for ((i = 1; i <= total; i++)); do
        if [ "$i" -eq "$current" ]; then
            dots+="\e[36m●\e[0m"
        elif [ "$i" -lt "$current" ]; then
            dots+="\e[32m●\e[0m"
        else
            dots+="\e[2m○\e[0m"
        fi
        [ "$i" -lt "$total" ] && dots+=" "
    done
    printf "%b  \e[2mStep %d of %d\e[0m\n" "$dots" "$current" "$total"
}

# Helper function to read keyboard entries
get_key() {
    stty -icanon -echo min 1 time 0
    local key rest
    IFS= read -r -n 1 key
    if [[ "$key" == $'\e' ]]; then
        IFS= read -r -n 2 -t 1 rest
        key="$key$rest"
    fi
    stty icanon echo
    printf '%s' "$key"
}

# Returns success (0) if the given key should be treated as "go back".
# Recognizes Backspace, Delete, Left arrow, and B.
is_back_key() {
    case "$1" in
        $'\x7f'|$'\x08'|$'\e[D'|b|B) return 0 ;;
        *) return 1 ;;
    esac
}

# ==========================================
# MENU DATA + DRAW FUNCTIONS
# (Defined once up front so selections persist if the user navigates
#  back and forth between steps.)
# ==========================================

ROCKBOX_MODELS=(
    "iPod Mini (1st / 2nd Gen)"
    "iPod Nano (1st / 2nd Gen)"
    "iPod 4th Gen (Monochrome)"
    "iPod Color / Photo (4th Gen)"
    "iPod Video (5th / 5.5 Gen)"
    "iPod Classic (6th / 6.5 / 7th Gen)"
)
ROCKBOX_RES=(
    "138x110"
    "176x132"
    "160x128"
    "220x176"
    "320x240"
    "320x240"
)

# Devices running Apple's own firmware, grouped by their native video
# resolution (several generations share the same screen and can share
# one preset - though not the Nano 5th Gen, whose larger 2.2" screen is
# a different resolution than the 3rd/4th Gen's). The Nano 6th Gen is
# deliberately absent - it dropped video playback entirely.
OFFICIAL_MODELS=(
    "iPod (5th / 5.5 Gen 'iPod Video')"
    "iPod Classic (6th / 6.5 / 7th Gen)"
    "iPod Nano (3rd / 4th Gen)"
    "iPod Nano (5th Gen)"
    "iPod Nano (7th Gen)"
)
OFFICIAL_RES=(
    "320x240"
    "320x240"
    "320x240"
    "376x240"
    "432x240"
)

# ipod_models/ipod_res point at whichever list above applies, set right
# after the Rockbox gate question below. draw_ipod_menu and the encoding
# step further down just read these two generic names either way.
ipod_selected=0

draw_ipod_menu() {
    for ((i=0; i<${#ipod_models[@]}; i++)); do
        printf "\r\033[K"
        if [ $i -eq $ipod_selected ]; then
            printf "\e[36m>\e[0m \e[30;47m\e[1m %s \e[22m- %s \e[0m\n" "${ipod_models[$i]}" "${ipod_res[$i]}"
        else
            printf "   \e[1m%s\e[22m - %s\e[0m \n" "${ipod_models[$i]}" "${ipod_res[$i]}"
        fi
    done
    printf "\r\033[K\n"
    printf "\r\033[K"
    if [ $ipod_selected -eq $IPOD_BACK_IDX ]; then
        printf "\e[36m>\e[0m \e[30;47m ← Back \e[0m\n"
    else
        printf "   \e[2m← Back\e[0m \n"
    fi
    printf "\r\033[K\n\r\033[K\e[2m↑/↓ to choose   Enter to select\e[0m\n"
}

options=("Letterbox" "Pillarbox" "Crop" "Resize (May cause video to look streched)")
selected=0
FIT_BACK_IDX=${#options[@]}

draw_menu() {
    for ((i=0; i<${#options[@]}; i++)); do
        printf "\r\033[K"
        if [ $i -eq $selected ]; then
            printf "\e[36m>\e[0m \e[30;47m %s \e[0m\n" "${options[$i]}"
        else
            printf "   %s \n" "${options[$i]}"
        fi
    done
    printf "\r\033[K\n"
    printf "\r\033[K"
    if [ $selected -eq $FIT_BACK_IDX ]; then
        printf "\e[36m>\e[0m \e[30;47m ← Back \e[0m\n"
    else
        printf "   \e[2m← Back\e[0m \n"
    fi
    printf "\r\033[K\n\r\033[K\e[2m↑/↓ to choose   Enter to select\e[0m\n"
}

vol_options=("Normal Volume / 0 dB (If unsure)" "Slight Boost (+3 dB)" "Medium Boost (+6 dB)" "Heavy Boost (+9 dB)")
vol_selected=0
VOL_BACK_IDX=${#vol_options[@]}

draw_vol_menu() {
    for ((i=0; i<${#vol_options[@]}; i++)); do
        printf "\r\033[K"
        if [ $i -eq $vol_selected ]; then
            printf "\e[36m>\e[0m \e[30;47m %s \e[0m\n" "${vol_options[$i]}"
        else
            printf "   %s \n" "${vol_options[$i]}"
        fi
    done
    printf "\r\033[K\n"
    printf "\r\033[K"
    if [ $vol_selected -eq $VOL_BACK_IDX ]; then
        printf "\e[36m>\e[0m \e[30;47m ← Back \e[0m\n"
    else
        printf "   \e[2m← Back\e[0m \n"
    fi
    printf "\r\033[K\n\r\033[K\e[2m↑/↓ to choose   Enter to select\e[0m\n"
}

# ==========================================
# ROCKBOX GATE (data + draw function; the question itself runs as Step 1
# of the wizard, after source/destination are entered - see below)
# This tool only produces Rockbox's MPEG-1 (.mpg) format for the
# mpegplayer plugin, which Apple's stock firmware cannot play.
# ==========================================
rockbox_options=("Yes, it's running Rockbox" "No, it's on stock Apple firmware")
rockbox_selected=0
ROCKBOX_BACK_IDX=${#rockbox_options[@]}

draw_rockbox_menu() {
    for ((i=0; i<${#rockbox_options[@]}; i++)); do
        printf "\r\033[K"
        if [ $i -eq $rockbox_selected ]; then
            printf "\e[36m>\e[0m \e[30;47m %s \e[0m\n" "${rockbox_options[$i]}"
        else
            printf "   %s \n" "${rockbox_options[$i]}"
        fi
    done
    printf "\r\033[K\n"
    printf "\r\033[K"
    if [ $rockbox_selected -eq $ROCKBOX_BACK_IDX ]; then
        printf "\e[36m>\e[0m \e[30;47m ← Back \e[0m\n"
    else
        printf "   \e[2m← Back\e[0m \n"
    fi
    printf "\r\033[K\n\r\033[K\e[2m↑/↓ to choose   Enter to select\e[0m\n"
}

draw_rockbox_screen() {
    draw_rockbox_menu
    printf "\n"
    printf "This tool can encode video either for Rockbox's MPEG-1 mpegplayer\n"
    printf "plugin, or as an H.264 file for Apple's own stock firmware.\n"
}

BACK_TO_SOURCE=false

# Outer wizard loop: covers picking a source, picking a destination,
# confirming a batch job, and the four numbered steps (Rockbox gate,
# hardware, fitting mode, volume). Backing out of any stage drops back
# to the previous one; backing out of Step 1 (or typing 'b'/'back' at
# the destination prompt) restarts this whole loop so source and
# destination can be reconsidered.
while true; do

while true; do
    draw_header
    IS_BATCH=false
    printf "\e[?25h"
    read -r -p "Enter path to source video or folder: " INPUT
    printf "\e[?25l"
    INPUT="${INPUT%\"}"
    INPUT="${INPUT#\"}"
    INPUT=$(echo "$INPUT" | sed 's/\\//g')
    [ -z "$INPUT" ] && echo "No input provided." && sleep 1 && continue
    
    if [ -d "$INPUT" ]; then
        if [ ! -r "$INPUT" ]; then
            printf "\e[31mCan't read the folder \"%s\" - check its permissions.\e[0m\n" "$(basename "$INPUT")"
            sleep 1.8
            continue
        fi
        FOLDER_NAME=$(basename "$INPUT")

        # Supported input container formats. (Deliberately NOT including .mpg/.mpeg:
        # that's this tool's own output format, so including it could cause a folder
        # to pick up files this same tool already produced on a prior run.)
        VIDEO_EXTENSIONS=(mp4 m4v mov mkv avi webm wmv flv ts m2ts mts 3gp 3g2 ogv)
        SUPPORTED_FORMATS_DISPLAY="MP4, MOV, M4V, MKV, AVI, WEBM, WMV, FLV, TS, M2TS, 3GP, OGV"

        FIND_NAME_ARGS=()
        for ext in "${VIDEO_EXTENSIONS[@]}"; do
            [ ${#FIND_NAME_ARGS[@]} -gt 0 ] && FIND_NAME_ARGS+=(-o)
            FIND_NAME_ARGS+=(-iname "*.${ext}")
        done

        # Scan for supported video files right away, so the confirmation
        # reflects what's actually in the folder instead of asking blind.
        FILES_TO_PROCESS=()
        while IFS= read -r -d '' file; do
            FILES_TO_PROCESS+=("$file")
        done < <(find "$INPUT" -maxdepth 1 -type f \( "${FIND_NAME_ARGS[@]}" \) -print0 | sort -z)

        if [ ${#FILES_TO_PROCESS[@]} -eq 0 ]; then
            printf "\e[31mNo supported video files found in \"%s\".\e[0m\n\n" "$FOLDER_NAME"
            printf "\e[2mSupported formats: %s\e[0m\n\n" "$SUPPORTED_FORMATS_DISPLAY"
            printf "\e[2mReturning to path entry...\e[0m\n"
            sleep 2.2
            continue
        fi

        FILE_COUNT=${#FILES_TO_PROCESS[@]}
        [ "$FILE_COUNT" -eq 1 ] && FILE_WORD="file" || FILE_WORD="files"

        IS_BATCH=true
        break
    elif [ -f "$INPUT" ]; then
        if [ ! -r "$INPUT" ]; then
            printf "\e[31mCan't read \"%s\" - check the file's permissions.\e[0m\n" "$(basename "$INPUT")"
            sleep 1.8
            continue
        fi
        IS_BATCH=false
        break
    elif [ -e "$INPUT" ]; then
        printf "\e[31m\"%s\" isn't a file or folder this tool can use.\e[0m\n" "$(basename "$INPUT")"
        sleep 1.8
        continue
    else
        echo "Path doesn't exist."
        sleep 1
        continue
    fi
done

echo

while true; do
    printf "\e[?25h"
    read -r -p "Enter output destination path: " OUTPUT
    printf "\e[?25l"
    OUTPUT="${OUTPUT%\"}"
    OUTPUT="${OUTPUT#\"}"
    OUTPUT=$(echo "$OUTPUT" | sed 's/\\//g')
    OUTPUT_LOWER=$(printf '%s' "$OUTPUT" | tr '[:upper:]' '[:lower:]')
    if [[ "$OUTPUT_LOWER" == "b" || "$OUTPUT_LOWER" == "back" ]]; then
        BACK_TO_SOURCE=true
        break
    fi
    [ -z "$OUTPUT" ] && echo "No output provided." && exit 1
    break
done

if [ "$BACK_TO_SOURCE" = true ]; then
    BACK_TO_SOURCE=false
    continue
fi

if [ "$IS_BATCH" = true ]; then
    clear
    printf "\e[1mAre you sure you want to batch convert \"%s\"?\e[0m\n" "$FOLDER_NAME"
    printf "\e[2m%s video %s found\e[0m\n" "$FILE_COUNT" "$FILE_WORD"
    printf "\e[2mOutput to: %s\e[0m\n\n" "$OUTPUT"

    batch_options=("Yes, batch convert this folder" "No, start over")
    batch_sel=0

    draw_batch_menu() {
        for ((i=0; i<${#batch_options[@]}; i++)); do
            printf "\r\033[K"
            if [ $i -eq $batch_sel ]; then
                printf "\e[36m>\e[0m \e[30;47m %s \e[0m\n" "${batch_options[$i]}"
            else
                printf "   %s \n" "${batch_options[$i]}"
            fi
        done
        printf "\r\033[K\n\r\033[K\e[2m↑/↓ to choose   Enter to confirm\e[0m\n"
    }
    draw_batch_menu

    while true; do
        key=$(get_key)
        if [[ "$key" == $'\e[A' || "$key" == $'\e[B' ]]; then # Up/Down toggles between the 2 options
            batch_sel=$((1 - batch_sel))
            printf "\033[%dA" "$((${#batch_options[@]} + 2))"
            draw_batch_menu
        elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then # Enter key
            break
        fi
    done

    if [ $batch_sel -eq 0 ]; then
        : # confirmed: fall through to the preset menus below
    else
        clear
        continue # declined: restart the outer wizard loop (re-prompt source AND destination)
    fi
fi

# ==========================================
# STAGE-BASED PRESET MENUS
# MENU_STEP: 1 = Rockbox gate, 2 = hardware, 3 = fitting mode,
# 4 = volume boost, 5 = done. Landing on 0 means the user backed out of
# Step 1, which sends control back to the top of the outer wizard loop
# (re-prompt source and destination).
# ==========================================
MENU_STEP=1
while [ "$MENU_STEP" -ge 1 ] && [ "$MENU_STEP" -le 4 ]; do
    case $MENU_STEP in
        1)
            clear
            draw_step_dots 1
            printf "\e[1mIs the target device running Rockbox?\e[0m\n"
            printf "\e[2m(If you don't know, select No.)\e[0m\n\n"
            draw_rockbox_screen

            while true; do
                key=$(get_key)
                if [[ "$key" == $'\e[A' ]]; then
                    ((rockbox_selected--))
                    [ $rockbox_selected -lt 0 ] && rockbox_selected=$ROCKBOX_BACK_IDX
                    printf "\033[%dA" "$((${#rockbox_options[@]} + 7))"
                    draw_rockbox_screen
                elif [[ "$key" == $'\e[B' ]]; then
                    ((rockbox_selected++))
                    [ $rockbox_selected -gt $ROCKBOX_BACK_IDX ] && rockbox_selected=0
                    printf "\033[%dA" "$((${#rockbox_options[@]} + 7))"
                    draw_rockbox_screen
                elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then
                    if [ $rockbox_selected -eq $ROCKBOX_BACK_IDX ]; then
                        rockbox_selected=0
                        MENU_STEP=0
                        break
                    fi
                    if [ $rockbox_selected -eq 0 ]; then
                        IS_ROCKBOX=true
                        OUT_EXT="mpg"
                        ipod_models=("${ROCKBOX_MODELS[@]}")
                        ipod_res=("${ROCKBOX_RES[@]}")
                    else
                        IS_ROCKBOX=false
                        OUT_EXT="m4v"
                        ipod_models=("${OFFICIAL_MODELS[@]}")
                        ipod_res=("${OFFICIAL_RES[@]}")

                        if ! ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libx264; then
                            clear
                            printf "\e[41m Error: \e[0m Your \e[1mffmpeg\e[22m build doesn't include \e[1mlibx264\e[22m,\n"
                            printf "which is required to encode H.264 for official Apple firmware.\n"
                            [ "$BREW_INSTALLED" = true ] && echo && echo "brew reinstall ffmpeg"
                            echo
                            printf "\e[30;47m> [OK]\e[0m\n"
                            printf "\e[?25h"
                            read -r
                            printf "\e[?25l"
                            break # leave MENU_STEP at 1, re-show this step
                        fi

                        # One-time capability probe for the aac_pns option (see the
                        # ENC_ARGS comment further down for what this fixes and why).
                        # Checked once here rather than every file so the per-file
                        # loop doesn't re-run ffmpeg's help output on each pass.
                        if [ -z "$AAC_PNS_CHECKED" ]; then
                            AAC_PNS_CHECKED=true
                            if ffmpeg -hide_banner -h encoder=aac 2>/dev/null | grep -q aac_pns; then
                                AAC_PNS_SUPPORTED=true
                            else
                                AAC_PNS_SUPPORTED=false
                            fi
                        fi
                    fi
                    ipod_selected=0
                    IPOD_BACK_IDX=${#ipod_models[@]}
                    MENU_STEP=2
                    break
                elif is_back_key "$key"; then
                    MENU_STEP=0
                    break
                fi
            done
            ;;
        2)
            clear
            draw_step_dots 2
            printf "\e[1mSelect your iPod Target Hardware:\e[0m\n\n"
            draw_ipod_menu

            while true; do
                key=$(get_key)
                if [[ "$key" == $'\e[A' ]]; then
                    ((ipod_selected--))
                    [ $ipod_selected -lt 0 ] && ipod_selected=$IPOD_BACK_IDX
                    printf "\033[%dA" "$((${#ipod_models[@]} + 4))"
                    draw_ipod_menu
                elif [[ "$key" == $'\e[B' ]]; then
                    ((ipod_selected++))
                    [ $ipod_selected -gt $IPOD_BACK_IDX ] && ipod_selected=0
                    printf "\033[%dA" "$((${#ipod_models[@]} + 4))"
                    draw_ipod_menu
                elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then
                    if [ $ipod_selected -eq $IPOD_BACK_IDX ]; then
                        ipod_selected=0
                        MENU_STEP=1
                    else
                        MENU_STEP=3
                    fi
                    break
                elif is_back_key "$key"; then
                    MENU_STEP=1
                    break
                fi
            done
            ;;
        3)
            clear
            draw_step_dots 3
            printf "\e[1mSelect video fitting mode:\e[0m\n\n"
            draw_menu

            while true; do
                key=$(get_key)
                if [[ "$key" == $'\e[A' ]]; then
                    ((selected--))
                    [ $selected -lt 0 ] && selected=$FIT_BACK_IDX
                    printf "\033[%dA" "$((${#options[@]} + 4))"
                    draw_menu
                elif [[ "$key" == $'\e[B' ]]; then
                    ((selected++))
                    [ $selected -gt $FIT_BACK_IDX ] && selected=0
                    printf "\033[%dA" "$((${#options[@]} + 4))"
                    draw_menu
                elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then
                    if [ $selected -eq $FIT_BACK_IDX ]; then
                        selected=0
                        MENU_STEP=2
                    else
                        MENU_STEP=4
                    fi
                    break
                elif is_back_key "$key"; then
                    MENU_STEP=2
                    break
                fi
            done
            ;;
        4)
            clear
            draw_step_dots 4
            printf "\e[1mSelect audio volume boost level:\e[0m\n\n"
            draw_vol_menu

            while true; do
                key=$(get_key)
                if [[ "$key" == $'\e[A' ]]; then
                    ((vol_selected--))
                    [ $vol_selected -lt 0 ] && vol_selected=$VOL_BACK_IDX
                    printf "\033[%dA" "$((${#vol_options[@]} + 4))"
                    draw_vol_menu
                elif [[ "$key" == $'\e[B' ]]; then
                    ((vol_selected++))
                    [ $vol_selected -gt $VOL_BACK_IDX ] && vol_selected=0
                    printf "\033[%dA" "$((${#vol_options[@]} + 4))"
                    draw_vol_menu
                elif [[ "$key" == "" || "$key" == $'\n' || "$key" == $'\r' ]]; then
                    if [ $vol_selected -eq $VOL_BACK_IDX ]; then
                        vol_selected=0
                        MENU_STEP=3
                    else
                        MENU_STEP=5
                    fi
                    break
                elif is_back_key "$key"; then
                    MENU_STEP=3
                    break
                fi
            done
            ;;
    esac
done

if [ "$MENU_STEP" -eq 0 ]; then
    continue # back out of Step 1: re-prompt source AND destination
fi

# All four steps confirmed - resolve the selections into concrete
# encoding settings now that they're final.
if [ "$IS_ROCKBOX" = true ]; then
    # Monochrome-screen iPods (4th Gen) are intentionally NOT converted to
    # grayscale here - Rockbox itself handles rendering color video down
    # to the monochrome display, so the encoded file stays in color.
    case "$ipod_selected" in
        0) # Mini (1st/2nd Gen)
            WIDTH=138
            HEIGHT=110
            SHARP="unsharp=5:5:0.6:3:3:0.3"
            HARDWARE_MAX=400
            AUDIO_RATE=44100
            ;;
        1) # Nano (1st/2nd Gen)
            WIDTH=176
            HEIGHT=132
            SHARP="unsharp=5:5:0.6:3:3:0.3"
            HARDWARE_MAX=500
            AUDIO_RATE=44100
            ;;
        2) # 4th Gen (Monochrome)
            WIDTH=160
            HEIGHT=128
            SHARP="unsharp=5:5:0.6:3:3:0.3"
            HARDWARE_MAX=500
            AUDIO_RATE=44100
            ;;
        3) # Color / Photo (4th Gen)
            WIDTH=220
            HEIGHT=176
            SHARP="unsharp=5:5:0.5:3:3:0.2"
            HARDWARE_MAX=600
            AUDIO_RATE=44100
            ;;
        4) # Video (5th/5.5 Gen)
            WIDTH=320
            HEIGHT=240
            SHARP="none"
            HARDWARE_MAX=1200
            AUDIO_RATE=44100
            ;;
        5) # Classic (6th/6.5/7th Gen)
            WIDTH=320
            HEIGHT=240
            SHARP="none"
            HARDWARE_MAX=1500
            AUDIO_RATE=44100
            ;;
        *)
            HARDWARE_SELECTION_ERROR=true
            ;;
    esac
else
    # Native screen resolution per official-firmware device tier. Profile
    # and level matter here, unlike bitrate/resolution: the 5th/5.5 Gen
    # iPod's decoder only understands Baseline Level 1.3 - feeding it a
    # Level 3.0 stream (even at a tiny bitrate) can make it refuse the
    # file outright. Nano 7th Gen is documented to accept Main Profile,
    # which encodes more efficiently at the same bitrate. Audio is 48kHz
    # to match Apple's documented spec exactly.
    case "$ipod_selected" in
        0) # iPod Video (5th/5.5 Gen)
            WIDTH=320
            HEIGHT=240
            SHARP="none"
            HARDWARE_MAX=768
            AUDIO_RATE=48000
            H264_PROFILE="baseline"
            H264_LEVEL="1.3"
            ;;
        1) # Classic (6th/6.5/7th Gen)
            WIDTH=320
            HEIGHT=240
            SHARP="none"
            HARDWARE_MAX=900
            AUDIO_RATE=48000
            H264_PROFILE="baseline"
            H264_LEVEL="3.0"
            ;;
        2) # Nano (3rd/4th Gen)
            WIDTH=320
            HEIGHT=240
            SHARP="none"
            HARDWARE_MAX=900
            AUDIO_RATE=48000
            H264_PROFILE="baseline"
            H264_LEVEL="3.0"
            ;;
        3) # Nano (5th Gen)
            WIDTH=376
            HEIGHT=240
            SHARP="none"
            HARDWARE_MAX=950
            AUDIO_RATE=48000
            H264_PROFILE="baseline"
            H264_LEVEL="3.0"
            ;;
        4) # Nano (7th Gen)
            WIDTH=432
            HEIGHT=240
            SHARP="none"
            HARDWARE_MAX=1000
            AUDIO_RATE=48000
            H264_PROFILE="main"
            H264_LEVEL="3.0"
            ;;
        *)
            HARDWARE_SELECTION_ERROR=true
            ;;
    esac
fi

if [ "$HARDWARE_SELECTION_ERROR" = true ]; then
    clear
    printf "\e[31mInternal error: unrecognized hardware selection (%s).\e[0m\n" "$ipod_selected"
    printf "Please re-run the script and pick a hardware option from the menu.\n\n"
    printf "\e[30;47m> [OK]\e[0m\n"
    printf "\e[?25h"
    read -r
    exit 1
fi

if [ "$SHARP" = "none" ]; then SHARP_FILTER=""; else SHARP_FILTER=",$SHARP"; fi

case "$selected" in
    0|1) VIDEO_FILTER="scale=$WIDTH:$HEIGHT:force_original_aspect_ratio=decrease,pad=$WIDTH:$HEIGHT:(ow-iw)/2:(oh-ih)/2:black$SHARP_FILTER";;
    2) VIDEO_FILTER="scale=$WIDTH:$HEIGHT:force_original_aspect_ratio=increase,crop=$WIDTH:$HEIGHT$SHARP_FILTER";;
    3) VIDEO_FILTER="scale=$WIDTH:$HEIGHT,setsar=1$SHARP_FILTER";;
esac

case "$vol_selected" in
    0) AUDIO_FILTER="volume=1.0";;
    1) AUDIO_FILTER="volume=3dB";;
    2) AUDIO_FILTER="volume=6dB";;
    3) AUDIO_FILTER="volume=9dB";;
esac

break # everything confirmed, proceed to conversion

done

# Collect processing file targets array
# (For batch mode, FILES_TO_PROCESS was already populated and confirmed
# with the user back when the folder path was entered.)
if [ "$IS_BATCH" = true ]; then
    if [ ${#FILES_TO_PROCESS[@]} -eq 0 ]; then
        clear
        printf "\e[31mError: No supported video files found in that directory.\e[0m\n\n"
        printf "\e[30;47m> [OK]\e[0m\n"
        printf "\e[?25h"
        read -r
        exit 1
    fi
else
    FILES_TO_PROCESS=()
    FILES_TO_PROCESS+=("$INPUT")
fi

# Verify the output location is writable before starting - catching this
# now avoids analyzing/converting files only to fail writing the first one.
if [ "$IS_BATCH" = true ] || [ -d "$OUTPUT" ]; then
    OUTPUT_WRITE_CHECK_DIR="$OUTPUT"
else
    OUTPUT_WRITE_CHECK_DIR=$(dirname "$OUTPUT")
fi
MKDIR_ERR=$(mkdir -p "$OUTPUT_WRITE_CHECK_DIR" 2>&1)
if [ ! -w "$OUTPUT_WRITE_CHECK_DIR" ]; then
    clear
    printf "\e[31mError:\e[0m Can't write to \"%s\".\n" "$OUTPUT_WRITE_CHECK_DIR"
    if [ -n "$MKDIR_ERR" ]; then
        printf "\e[2m%s\e[0m\n\n" "$MKDIR_ERR"
    else
        printf "Check the path exists and that you have permission to write there.\n\n"
    fi
    printf "\e[30;47m> [OK]\e[0m\n"
    printf "\e[?25h"
    read -r
    exit 1
fi

TOTAL_FILES=${#FILES_TO_PROCESS[@]}
CURRENT_FILE_INDEX=0
SUCCESS_COUNT=0
SKIPPED_COUNT=0
RUN_START_TIME=$(date +%s)

# Core Batch File Processing Loop
for TARGET_INPUT in "${FILES_TO_PROCESS[@]}"; do
    ((CURRENT_FILE_INDEX++))
FILENAME=$(basename "$TARGET_INPUT")
NAME_NO_EXT="${FILENAME%.*}"

if [ "$IS_BATCH" = true ]; then
    mkdir -p "$OUTPUT"
    TARGET_OUTPUT="$OUTPUT/$NAME_NO_EXT.$OUT_EXT"

elif [ -d "$OUTPUT" ]; then
    TARGET_OUTPUT="$OUTPUT/$NAME_NO_EXT.$OUT_EXT"

else
    OUTPUT_DIR=$(dirname "$OUTPUT")
    mkdir -p "$OUTPUT_DIR"
    OUT_NAME=$(basename "$OUTPUT")
    TARGET_OUTPUT="$OUTPUT_DIR/${OUT_NAME%.*}.$OUT_EXT"
fi

clear

printf "\e[1m[%d/%d] Analyzing: %s...\e[0m\n" \
    "$CURRENT_FILE_INDEX" "$TOTAL_FILES" "$FILENAME"

# Confirm ffmpeg/ffprobe can actually decode a video stream from this file
# before committing to it - an unsupported, corrupt, or non-video file
# would otherwise either hang, fail confusingly deep in the progress bar
# logic, or silently produce a broken output.
if ! ffprobe -v error -select_streams v:0 -show_entries stream=codec_type \
    -of csv=p=0 "$TARGET_INPUT" 2>/dev/null | grep -q video; then
    printf "\e[31mSkipping - not a readable video file: %s\e[0m\n" "$FILENAME"
    sleep 1.5
    ((SKIPPED_COUNT++))
    continue
fi

DURATION=$(ffprobe -v error \
    -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 \
    "$TARGET_INPUT" 2>/dev/null)

[ -z "$DURATION" ] || [ "$DURATION" = "N/A" ] && DURATION=0

INT_DURATION=$(echo "$DURATION / 1" | bc 2>/dev/null || echo 0)

if [ "$INT_DURATION" -le 300 ]; then
    CALC_BITRATE=$HARDWARE_MAX
elif [ "$INT_DURATION" -le 1800 ]; then
    CALC_BITRATE=$(echo "$HARDWARE_MAX * 0.85" | bc | cut -d. -f1)
elif [ "$INT_DURATION" -le 3600 ]; then
    CALC_BITRATE=$(echo "$HARDWARE_MAX * 0.75" | bc | cut -d. -f1)
else
    CALC_BITRATE=$(echo "$HARDWARE_MAX * 0.60" | bc | cut -d. -f1)
fi

BITRATE="${CALC_BITRATE}k"

# Rockbox needs raw MPEG-1/MP2 in an .mpg container for its mpegplayer
# plugin. Stock firmware needs H.264/AAC in an MP4-family container;
# baseline profile is used since it's the one profile every generation
# above (including the oldest 5th Gen) is guaranteed to decode.
if [ "$IS_ROCKBOX" = true ]; then
    ENC_ARGS=(-c:v mpeg1video -b:v "$BITRATE" -c:a mp2 -af "$AUDIO_FILTER" -b:a 64k -ar "$AUDIO_RATE" -f mpeg)
else
    # -cutoff 15000 and -aac_pns 0 fix a real bug in ffmpeg's built-in "aac"
    # encoder: its Perceptual Noise Substitution can mis-fire on transient
    # or high-frequency content (sibilant speech, cymbals, etc.), producing
    # a short high-pitched squeal/chirp wherever that content happens to
    # land in the source - which on typical dialogue or music is roughly
    # every 30-60 seconds. Capping the encoded bandwidth at 15kHz (well
    # above what 128kbps stereo AAC reproduces cleanly anyway, and well
    # above what stock iPod earbuds resolve) and disabling PNS outright
    # removes the bug instead of just making it less likely.
    ENC_ARGS=(-c:v libx264 -profile:v "$H264_PROFILE" -level "$H264_LEVEL" -pix_fmt yuv420p -b:v "$BITRATE" -maxrate "$BITRATE" -bufsize "$((CALC_BITRATE * 2))k" -c:a aac -af "$AUDIO_FILTER" -b:a 128k -ar "$AUDIO_RATE" -cutoff 15000 -movflags +faststart -f mp4)
    [ "$AAC_PNS_SUPPORTED" = true ] && ENC_ARGS+=(-aac_pns 0)
fi

clear  # Standard clear, ensuring header title is wiped during conversion cycles

printf "\e[1mFile %d of %d | Processing: %s\e[0m\n" \
    "$CURRENT_FILE_INDEX" "$TOTAL_FILES" "$FILENAME"

printf "Target Profile: \e[1m%s\e[22m - %s | Bitrate: %s\n" \
    "${ipod_models[$ipod_selected]}" \
    "${ipod_res[$ipod_selected]}" \
    "$BITRATE"

echo

PROGRESS_LOG=$(mktemp)
ERROR_LOG=$(mktemp)
START_TIME=$(date +%s)

ffmpeg -y -loglevel error \
    -progress "$PROGRESS_LOG" \
    -i "$TARGET_INPUT" \
    -vf "$VIDEO_FILTER" \
    -r 30 \
    "${ENC_ARGS[@]}" \
    "$TARGET_OUTPUT" 2>"$ERROR_LOG" &

FFMPEG_PID=$!

while kill -0 $FFMPEG_PID 2>/dev/null; do
    if [ -f "$PROGRESS_LOG" ] && [ $(echo "$DURATION > 0" | bc -l) -eq 1 ]; then

        OUT_TIME_US=$(grep "out_time_us=" "$PROGRESS_LOG" | tail -n 1 | cut -d= -f2)
        FPS_VAL=$(grep "fps=" "$PROGRESS_LOG" | tail -n 1 | cut -d= -f2)
        FPS_VAL=$(echo "$FPS_VAL" | xargs)
        [ -z "$FPS_VAL" ] && FPS_VAL="0"

        if [ ! -z "$OUT_TIME_US" ]; then
            CURRENT_SEC=$(echo "scale=2; $OUT_TIME_US / 1000000" | bc -l)
            PCT=$(echo "scale=0; ($CURRENT_SEC * 100) / $DURATION" | bc -l)

            [ $PCT -gt 100 ] && PCT=100
            [ $PCT -lt 0 ] && PCT=0

            TOTAL_WIDTH=40
            DONE_BLOCKS=$(echo "$PCT * $TOTAL_WIDTH / 100" | bc)
            LEFT_BLOCKS=$((TOTAL_WIDTH - DONE_BLOCKS))

            BAR=$(printf "%0.s█" $(seq 1 $DONE_BLOCKS 2>/dev/null))
            SPACES=$(printf "%0.s░" $(seq 1 $LEFT_BLOCKS 2>/dev/null))

            FILE_SIZE_MB="0.0"
            if [ -f "$TARGET_OUTPUT" ]; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    FILE_SIZE_BYTES=$(stat -f%z "$TARGET_OUTPUT" 2>/dev/null)
                else
                    FILE_SIZE_BYTES=$(stat -c%s "$TARGET_OUTPUT" 2>/dev/null)
                fi

                if [ ! -z "$FILE_SIZE_BYTES" ]; then
                    FILE_SIZE_MB=$(echo "scale=1; $FILE_SIZE_BYTES / 1048576" | bc -l)
                    [[ "$FILE_SIZE_MB" == .* ]] && FILE_SIZE_MB="0$FILE_SIZE_MB"
                fi
            fi

            CURRENT_TIME=$(date +%s)
            ELAPSED=$((CURRENT_TIME - START_TIME))

            if [ $PCT -gt 0 ] && [ $ELAPSED -gt 0 ]; then
                TOTAL_EST_TIME=$(echo "$ELAPSED * 100 / $PCT" | bc)
                REMAINING=$((TOTAL_EST_TIME - ELAPSED))
                [ $REMAINING -lt 0 ] && REMAINING=0
                ETA=$(printf "%02d:%02d" $((REMAINING / 60)) $((REMAINING % 60)))
            else
                ETA="--:--"
            fi

            printf "\r[%s%s]\033[K\n %d%% (%s fps) | Size: %s MB | ETA: %s\033[K\033[1A" \
                "$BAR" "$SPACES" "$PCT" "$FPS_VAL" "$FILE_SIZE_MB" "$ETA"
        fi
    fi

    sleep 1
done

rm -f "$PROGRESS_LOG"
wait $FFMPEG_PID
FFMPEG_EXIT=$?

if [ $FFMPEG_EXIT -eq 0 ] && [ -s "$TARGET_OUTPUT" ]; then
    ((SUCCESS_COUNT++))
else
    printf "\n\e[31mFailed to convert %s:\e[0m\n" "$FILENAME"
    if [ -s "$ERROR_LOG" ]; then
        tail -n 4 "$ERROR_LOG" | sed 's/^/  /'
    else
        echo "  ffmpeg exited with no error output (code $FFMPEG_EXIT)."
    fi
    rm -f "$TARGET_OUTPUT" 2>/dev/null
    sleep 2.5
fi
rm -f "$ERROR_LOG"

done

clear

RUN_ELAPSED=$(( $(date +%s) - RUN_START_TIME ))
RUN_MIN=$((RUN_ELAPSED / 60))
RUN_SEC=$((RUN_ELAPSED % 60))
if [ $RUN_MIN -gt 0 ]; then
    RUN_TIME_STR="${RUN_MIN}m ${RUN_SEC}s"
else
    RUN_TIME_STR="${RUN_SEC}s"
fi

if [ $SUCCESS_COUNT -eq $TOTAL_FILES ]; then
    if [ "$IS_ROCKBOX" = true ]; then
        printf "\e[32mDone! All %d file(s) are ready for Rockbox.\e[0m\n" "$TOTAL_FILES"
    else
        printf "\e[32mDone! All %d file(s) are ready to sync to your iPod.\e[0m\n" "$TOTAL_FILES"
    fi
    printf "\e[2mFinished in %s\e[0m\n" "$RUN_TIME_STR"
    # \e[37m sets text color to white
    printf "\e[37mSaved to: %s\e[0m\n\n" "$OUTPUT"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        open -R "$TARGET_OUTPUT"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        command -v xdg-open >/dev/null 2>&1 && xdg-open "$(dirname "$TARGET_OUTPUT")"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        explorer.exe /select,"$(cygpath -w "$TARGET_OUTPUT")"
    fi
else
    printf "\e[31mConversion finished with issues.\e[0m\n"
    printf "\e[31mSuccessfully converted %d out of %d file(s).\e[0m\n" "$SUCCESS_COUNT" "$TOTAL_FILES"
    if [ "$SKIPPED_COUNT" -gt 0 ]; then
        printf "\e[31m%d skipped as unsupported/unreadable.\e[0m\n" "$SKIPPED_COUNT"
    fi
    printf "\e[2mFinished in %s\e[0m\n" "$RUN_TIME_STR"
    echo
    [ "$SUCCESS_COUNT" -gt 0 ] && printf "\e[37mSaved to: %s\e[0m\n\n" "$OUTPUT"
fi

printf "\e[30;47m> [OK]\e[0m\n"
printf "\e[?25h"
read -r
clear
