#!/bin/bash
# rofi script-mode backend for the now-playing control popup.
# Not meant to be run directly — invoked by rofi via -modes, see media-popup.sh

CACHE_DIR="$HOME/.cache/polybar-mediaplayer"
mkdir -p "$CACHE_DIR"

current_player() {
    playerctl -l 2> /dev/null | head -n1
}

escape_markup() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<< "$1"
}

fmt_time() {
    s=${1%.*}
    [ -z "$s" ] && s=0
    printf '%02d:%02d' $((s / 60)) $((s % 60))
}

art_path() {
    p="$1"
    url=$(playerctl -p "$p" metadata mpris:artUrl 2> /dev/null)
    [ -z "$url" ] && return

    case "$url" in
        file://*)
            printf '%s' "${url#file://}"
            ;;
        http://*|https://*)
            hash=$(printf '%s' "$url" | md5sum | cut -d' ' -f1)
            ext="${url##*.}"
            case "$ext" in
                jpg|jpeg|png|webp) ;;
                *) ext="jpg" ;;
            esac
            cached="$CACHE_DIR/$hash.$ext"
            [ -s "$cached" ] || curl -s -m 3 -o "$cached" "$url" 2> /dev/null
            [ -s "$cached" ] && printf '%s' "$cached"
            ;;
    esac
}

DESKTOP_DIRS="$HOME/.local/share/applications /usr/local/share/applications /usr/share/applications"

# DesktopEntry (e.g. "zen") is a .desktop basename, not an icon-theme name -
# rofi's icon lookup won't match it directly, so resolve the file's own
# Icon= value (which may itself be an icon-theme name or an absolute path).
desktop_icon() {
    de="$1"
    for dir in $DESKTOP_DIRS; do
        f="$dir/$de.desktop"
        [ -f "$f" ] || continue
        sed -n 's/^Icon=//p' "$f" | head -n1
        return
    done
}

player_icon() {
    p="$1"
    de=$(busctl --user get-property "org.mpris.MediaPlayer2.$p" \
        /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2 DesktopEntry 2> /dev/null |
        sed -n 's/^s "\(.*\)"$/\1/p')
    if [ -n "$de" ]; then
        icon=$(desktop_icon "$de")
        printf '%s' "${icon:-$de}"
        return
    fi
    # No DesktopEntry (some browser tabs) - fall back to the MPRIS instance
    # name with its ".instanceN" suffix stripped (e.g. chromium.instance1 -> chromium)
    # so the icon theme still resolves a generic app icon.
    printf '%s' "${p%%.*}"
}

CAVA_STATE="/tmp/polybar_cava_state"

# Reads the current frame written by cava.sh (module/cava is expected
# to already be running and keeping this file fresh) instead of
# duplicating cava's own config/sink-detection/glyph-mapping logic.
cava_frame() {
    line=$(cat "$CAVA_STATE" 2> /dev/null)
    [ -z "$line" ] && { printf '%s' "·······"; return; }
    printf '%s' "$line"
}

progress_bar() {
    pos="$1"; len="$2"; width=10

    if [ -z "$len" ] || [ "$len" -le 0 ]; then
        printf '%s' "$(fmt_time "$pos")"
        return
    fi

    filled=$(( pos * width / len ))
    [ "$filled" -gt "$width" ] && filled=$width
    [ "$filled" -lt 0 ] && filled=0

    bar=$(printf '━%.0s' $(seq 1 "$filled") 2> /dev/null)
    rest=$(printf '─%.0s' $(seq 1 $((width - filled))) 2> /dev/null)
    printf '%s %s%s %s' "$(fmt_time "$pos")" "$bar" "$rest" "$(fmt_time "$len")"
}

render() {
    printf '\0prompt\x1fNow Playing\n'
    printf '\0no-custom\x1ftrue\n'
    printf '\0markup-rows\x1ftrue\n'
    printf '\0keep-selection\x1ftrue\n'
    # Alt+1 (rofi's default kb-custom-1) is used purely as a "tick": a
    # background loop in media-popup.sh sends it on a timer so the list
    # re-renders with a fresh position, without the user pressing anything.
    printf '\0use-hot-keys\x1ftrue\n'

    p=$(current_player)
    if [ -z "$p" ]; then
        printf '%s\0nonselectable\x1ftrue\n' "No media player running"
        return
    fi

    status=$(playerctl -p "$p" status 2> /dev/null)
    artist=$(playerctl -p "$p" metadata artist 2> /dev/null)
    title=$(playerctl -p "$p" metadata title 2> /dev/null)
    pos=$(playerctl -p "$p" position 2> /dev/null)
    pos=${pos%.*}
    len_us=$(playerctl -p "$p" metadata mpris:length 2> /dev/null)
    len=$(( ${len_us:-0} / 1000000 ))
    art=$(art_path "$p")
    icon=$(player_icon "$p")

    artist_label="<b>$(escape_markup "${artist:-Unknown Artist}")</b>"
    title_label="$(escape_markup "${title:-Unknown Title}")"
    bar=$(progress_bar "${pos:-0}" "$len")

    if [ "$status" = "Playing" ]; then
        toggle="󰏤"
    else
        toggle="󰐊"
    fi

    # media-popup.rasi sets listview { columns: 3; lines: 3; }. Rofi fills
    # a grid column-major (down column 1, then column 2, then column 3),
    # so printing in this order:
    #   artist    cava       title+art
    #   seekback  bar        seekfwd
    #   previous  toggle     next
    # lands as:
    #   row1:  artist     cava       title (icon = track art, if any)
    #   row2:  seekback   bar        seekfwd
    #   row3:  previous   toggle     next
    # rofi list cells are single-line widgets (no wrapping/stacking), so
    # artist and title get their own cells. Both are selectable
    # (info=focus) so either raises the playing tab/window.
    printf '%s\0info\x1ffocus\n' "$artist_label"
    printf '%s\0info\x1fseekback\n' "◀◀ (-5s)"
    printf '%s\0info\x1fprevious\n' "󰒮"

    printf '%s\0info\x1ffocus' "$(cava_frame)"
    [ -n "$icon" ] && printf '\x1ficon\x1f%s' "$icon"
    printf '\n'
    printf '%s\0nonselectable\x1ftrue\n' "$bar"
    printf '%s\0info\x1ftoggle\n' "$toggle"

    printf '%s\0info\x1ffocus' "$title_label"
    [ -n "$art" ] && printf '\x1ficon\x1f%s' "$art"
    printf '\n'
    printf '%s\0info\x1fseekfwd\n' "▶▶ (+5s)"
    printf '%s\0info\x1fnext\n' "󰒭"
}

# Raise the window/tab of the app currently playing media. MPRIS's own
# Raise method is preferred over a wmctrl/xdotool title match: browsers
# like Firefox/Zen implement it to switch to the exact playing tab.
focus_player() {
    p="$1"
    busctl --user call "org.mpris.MediaPlayer2.$p" /org/mpris/MediaPlayer2 \
        org.mpris.MediaPlayer2 Raise 2> /dev/null
}

if [ "$ROFI_RETV" = "1" ]; then
    p=$(current_player)
    case "$ROFI_INFO" in
        focus)
            focus_player "$p"
            exit 0
            ;;
        previous) playerctl -p "$p" previous 2> /dev/null ;;
        toggle) playerctl -p "$p" play-pause 2> /dev/null ;;
        next) playerctl -p "$p" next 2> /dev/null ;;
        seekback) playerctl -p "$p" position 5- 2> /dev/null ;;
        seekfwd) playerctl -p "$p" position 5+ 2> /dev/null ;;
    esac
    sleep 0.2
fi

render
