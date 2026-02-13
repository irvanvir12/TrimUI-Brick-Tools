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
            add)
                add_channel
                [ $? -eq 0 ] && return
            ;;
            remove)
                remove_channel
            ;;
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

        # 🔥 B EXIT → balik ke tools menu
        [ $kb_status -ne 0 ] && return 1

        [ -z "$channel" ] && continue

        channel=$(normalize_channel "$channel")

        # 🚫 Anti duplicate
        grep -iq "^$channel$" "$CHANNELS_FILE" 2>/dev/null && {
            ./show_message "Channel Already Exists" -l a
            continue
        }

        display=$(echo "$channel" | sed 's/@//' | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g')

        echo "$channel" >> "$CHANNELS_FILE"

        ./show_message "Channel Added|$display" -l a

        return 0
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
    status=$?

    [ $status -ne 0 ] && return

    remove=$(echo "$choice")

    grep -iv "^$remove$" "$CHANNELS_FILE" > /tmp/ch_tmp.txt
    mv /tmp/ch_tmp.txt "$CHANNELS_FILE"

    ./show_message "Channel Removed" -l a
}

###############################################################################
download_simple() {
    URL="$1"
    TITLE="$2"
    DOWNLOAD_DIR="/mnt/SDCARD/Roms/Media Player (MPV)"

    mkdir -p "$DOWNLOAD_DIR"

    ./show_message "Downloading|$TITLE" -t 1

    "$YTDLP_PATH" "$URL" \
        -f "bestvideo[vcodec^=avc1][height<=1080]+bestaudio[acodec^=mp4a]/best[vcodec^=avc1][height<=1080]/best[height<=1080]" \
        --merge-output-format mp4 \
        -o "$DOWNLOAD_DIR/%(title)s.%(ext)s" \
        --no-warnings --no-progress

    ./show_message "Download Finished|$TITLE" -l a
}

###############################################################################
stream_video() {

    URL="$1"

    ./show_message "Preparing Stream..." -t 1

    STREAM_URL=$("$YTDLP_PATH" -g \
        -f "best[vcodec^=avc1][height<=1080]/best[height<=720]" \
        "$URL" 2>/dev/null | head -n 1)

    [ -z "$STREAM_URL" ] && {
        ./show_message "Stream Not Available" -l a
        return
    }

    /mnt/SDCARD/Emus/$PLATFORM/MPV.pak/launch.sh "$STREAM_URL"
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

        [ "$choice" -eq 0 ] && download_simple "$url" "$title"
    done
}

###############################################################################
create_channels_menu() {

    > /tmp/channels_menu.txt
    echo "Search Video|search|action" >> /tmp/channels_menu.txt

    [ ! -s "$CHANNELS_FILE" ] && return

    while read -r channel; do

        [ -z "$channel" ] && continue

        # 🔥 Remove @ untuk tampilan
        display=$(echo "$channel" | sed 's/@//' | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g')

        # tampilkan nama cantik tapi simpan handle asli
        echo "$display|$channel|channel" >> /tmp/channels_menu.txt

    done < "$CHANNELS_FILE"
}

###############################################################################
main() {

    while true; do

        create_channels_menu

        picker_output=$(./picker /tmp/channels_menu.txt -y "TOOLS" -b "EXIT" -a "SELECT")
        status=$?

        # 🔥 Y button → Tools Menu
        [ $status -eq 4 ] && {
            open_tools_menu
            continue
        }

        [ $status -eq 2 ] && exit 0
        [ $status -ne 0 ] && continue

        value=$(echo "$picker_output" | cut -d'|' -f2)
        type=$(echo "$picker_output" | cut -d'|' -f3)

        [ "$type" = "action" ] && {
            search_video
            continue
        }

        if [ "$type" = "channel" ]; then
            > /tmp/channel_options.txt
            echo "Get Last Five Videos|five|action" >> /tmp/channel_options.txt
            echo "Download Latest Video|latest|action" >> /tmp/channel_options.txt

            opt=$(./picker /tmp/channel_options.txt)
            [ $? -ne 0 ] && continue

            mode=$(echo "$opt" | cut -d'|' -f2)
            ./select_channel.sh "$value" "$mode"
        fi
    done
}

main