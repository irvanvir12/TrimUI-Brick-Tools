#!/bin/sh
DIR=$(dirname "$0")
cd "$DIR"

YTDLP_PATH="$DIR/yt-dlp"
export LD_LIBRARY_PATH="$DIR/.lib:$LD_LIBRARY_PATH"
CHANNELS_FILE="$DIR/channels.txt"

###############################################################################
normalize_channel() {
    name="$1"
    name=$(echo "$name" | sed 's|https://||;s|http://||;s|www.youtube.com/||')
    name=$(echo "$name" | sed 's|/@|@|')
    name=$(echo "$name" | sed 's|/videos||')
    echo "$name" | grep -q "^@" || name="@$name"
    echo "$name"
}

###############################################################################
check_connectivity() {
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 ||
    ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1
}

###############################################################################
open_tools_menu() {
    while true; do
        > /tmp/tools_menu.txt
        echo "Add New Channel|add" >> /tmp/tools_menu.txt
        echo "Remove Channel|remove" >> /tmp/tools_menu.txt
        echo "Update yt-dlp|update" >> /tmp/tools_menu.txt

        choice=$(./picker /tmp/tools_menu.txt -b "BACK" -a "SELECT")
        status=$?

        [ $status -eq 2 ] && return

        action=$(echo "$choice" | cut -d'|' -f2)

        case "$action" in
            add) add_channel ;;
            remove) remove_channel ;;
            update)
                ./update_yt_dlp.sh
                ./show_message "yt-dlp Updated" -l a
            ;;
        esac
    done
}

###############################################################################
add_channel() {
    while true; do
        ./show_message "Add Channel|Enter channel name" -t 2
        channel=$(./keyboard minui.ttf)
        kb_status=$?

        [ $kb_status -ne 0 ] && return
        [ -z "$channel" ] && continue

        channel=$(normalize_channel "$channel")

        grep -iq "^$channel$" "$CHANNELS_FILE" 2>/dev/null && {
            ./show_message "Channel Already Exists" -l a
            continue
        }

        display=$(echo "$channel" | sed 's/@//' | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g')
        echo "$channel" >> "$CHANNELS_FILE"

        ./show_message "Channel Added|$display" -l a
        return
    done
}

###############################################################################
remove_channel() {

    [ ! -s "$CHANNELS_FILE" ] && {
        ./show_message "No Channel Found" -l a
        return
    }

    cp "$CHANNELS_FILE" /tmp/remove_list.txt
    choice=$(./picker /tmp/remove_list.txt -b "BACK" -a "REMOVE")
    [ $? -ne 0 ] && return

    grep -iv "^$choice$" "$CHANNELS_FILE" > /tmp/ch_tmp.txt
    mv /tmp/ch_tmp.txt "$CHANNELS_FILE"

    ./show_message "Channel Removed" -l a
}

###############################################################################
# STREAM (Progressive 720p, pasti ada audio)
###############################################################################
###############################################################################
# STREAM (Smart Stream System)
###############################################################################
stream_video() {

    URL="$1"

    ./show_message "Preparing Stream..." -t 1

    # -------------------------------------------------
    # 1️⃣ Try Progressive 720p (pasti ada audio)
    # -------------------------------------------------
    STREAM_URL=$("$YTDLP_PATH" -g \
        -f "best[height<=720]/best" \
        "$URL" 2>/dev/null | head -n 1)

    if [ -n "$STREAM_URL" ]; then
        /mnt/SDCARD/Emus/$PLATFORM/MPV.pak/launch.sh "$STREAM_URL"
        return
    fi

    # -------------------------------------------------
    # 2️⃣ Try any progressive format
    # -------------------------------------------------
    STREAM_URL=$("$YTDLP_PATH" -g \
        -f "best" \
        "$URL" 2>/dev/null | head -n 1)

    if [ -n "$STREAM_URL" ]; then
        /mnt/SDCARD/Emus/$PLATFORM/MPV.pak/launch.sh "$STREAM_URL"
        return
    fi

    # -------------------------------------------------
    # 3️⃣ Fallback DASH (video + audio split)
    # -------------------------------------------------
    URLS=$("$YTDLP_PATH" -g \
        -f "bestvideo[height<=720]+bestaudio/bestvideo+bestaudio" \
        "$URL" 2>/dev/null)

    VIDEO_URL=$(echo "$URLS" | sed -n '1p')
    AUDIO_URL=$(echo "$URLS" | sed -n '2p')

    if [ -n "$VIDEO_URL" ] && [ -n "$AUDIO_URL" ]; then
        /mnt/SDCARD/Emus/$PLATFORM/MPV.pak/launch.sh "$VIDEO_URL" --audio-file="$AUDIO_URL"
        return
    fi

    # -------------------------------------------------
    # ❌ Final Fail
    # -------------------------------------------------
    ./show_message "Stream Not Available" -l a
}


###############################################################################
# DOWNLOAD WITH PROGRESS (Percent Only – Stable)
###############################################################################
download_with_progress() {

    URL="$1"
    TITLE="$2"
    DOWNLOAD_DIR="/mnt/SDCARD/Roms/Media Player (MPV)"

    mkdir -p "$DOWNLOAD_DIR"

    OUTPUT_TEMPLATE="$DOWNLOAD_DIR/%(title)s.%(ext)s"
    PROGRESS_FILE="/tmp/yt_progress.txt"
    rm -f "$PROGRESS_FILE"

    # 🔥 Format stabil + merge mp4
    "$YTDLP_PATH" "$URL" \
        -f "bestvideo[vcodec^=avc1][height<=1080]+bestaudio[acodec^=mp4a]/best[height<=1080]/best" \
        --merge-output-format mp4 \
        --newline \
        -o "$OUTPUT_TEMPLATE" \
        > "$PROGRESS_FILE" 2>&1 &

    YT_PID=$!
    LAST_PERCENT=-1

    while kill -0 $YT_PID 2>/dev/null; do

        # Ambil persen terbaru
        PERCENT=$(grep -o '[0-9]\{1,3\}\.[0-9]\+%' "$PROGRESS_FILE" \
            | tail -n 1 \
            | tr -d '%' \
            | cut -d'.' -f1)

        if [ -z "$PERCENT" ]; then
            sleep 0.5
            continue
        fi

        # Update hanya jika berubah
        if [ "$PERCENT" -ne "$LAST_PERCENT" ]; then
            LAST_PERCENT="$PERCENT"
            ./show_message "Downloading|$TITLE|$LAST_PERCENT%" -t 1
        fi

        sleep 0.5
    done

    wait $YT_PID
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        ./show_message "Download Finished|$TITLE|100%" -l a
    else
        ./show_message "Download Failed" -l a
    fi
}

###############################################################################
show_video_info_screen() {

    URL="$1"

    ./show_message "Loading Info..." -t 1

    INFO=$("$YTDLP_PATH" --dump-single-json "$URL" 2>/dev/null)

    TITLE=$(echo "$INFO" | grep -o '"title": *"[^"]*"' | head -1 | cut -d'"' -f4)
    CHANNEL=$(echo "$INFO" | grep -o '"channel": *"[^"]*"' | head -1 | cut -d'"' -f4)
    DURATION=$(echo "$INFO" | grep -o '"duration_string": *"[^"]*"' | head -1 | cut -d'"' -f4)
    VIEWS=$(echo "$INFO" | grep -o '"view_count": *[0-9]*' | head -1 | awk '{print $2}')

    [ -z "$TITLE" ] && TITLE="Unknown Title"

    TEXT="$TITLE|$CHANNEL | $DURATION|$VIEWS views"

    ./show_message "$TEXT" -l ab -b "Back" -a "Download"
    return $?
}

###############################################################################
search_video() {

    ./show_message "Search Video|Enter keyword" -t 2
    query=$(./keyboard minui.ttf)
    [ -z "$query" ] && return

    check_connectivity || {
        ./show_message "No Internet Connection" -l a
        return
    }

    ./show_message "Searching...|$query" -t 1

    "$YTDLP_PATH" "ytsearch5:$query" \
        --skip-download \
        --print "%(title)s|%(webpage_url)s|video" \
        --no-warnings \
        > /tmp/search_results.txt

    [ ! -s /tmp/search_results.txt ] && {
        ./show_message "No Results" -l a
        return
    }

    while true; do

        picker_output=$(./picker /tmp/search_results.txt -a "SELECT" -x "STREAM" -b "BACK")
        picker_status=$?

        [ $picker_status -eq 2 ] && break
        [ -z "$picker_output" ] && break

        title=$(echo "$picker_output" | cut -d'|' -f1)
        url=$(echo "$picker_output" | cut -d'|' -f2)

        if [ $picker_status -eq 3 ]; then
            stream_video "$url"
            continue
        fi

        show_video_info_screen "$url"
        choice=$?

        [ "$choice" -eq 0 ] && download_with_progress "$url" "$title"
    done
}

###############################################################################
create_channels_menu() {

    > /tmp/channels_menu.txt
    echo "🔎 Search Video|search|action" >> /tmp/channels_menu.txt

    [ ! -s "$CHANNELS_FILE" ] && return

    while read -r channel; do
        [ -z "$channel" ] && continue
        display=$(echo "$channel" | sed 's/@//' | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g')
        echo "📺 $display|$channel|channel" >> /tmp/channels_menu.txt
    done < "$CHANNELS_FILE"
}

###############################################################################
main() {

    while true; do

        create_channels_menu

        picker_output=$(./picker /tmp/channels_menu.txt -y "TOOLS" -b "EXIT" -a "SELECT")
        status=$?

        [ $status -eq 4 ] && { open_tools_menu; continue; }
        [ $status -eq 2 ] && exit 0
        [ $status -ne 0 ] && continue

        type=$(echo "$picker_output" | cut -d'|' -f3)

        [ "$type" = "action" ] && search_video
    done
}

main
