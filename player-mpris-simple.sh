#!/bin/sh

NC='%{F-}'
NC_BGM='%{B-}'
ARTIST_FG='%{F#1f1f1f}'
ARTIST_BG='%{B#cfd8ff}'
SONG_FG='%{F#1f1f1f}'
SONG_BG='%{B#1a2e1a}'

# Raise the window/tab of the app currently playing media.
focus_player() {
    player=$(playerctl -l 2> /dev/null | head -n1)
    [ -z "$player" ] && exit 0

    # MPRIS's own Raise method is preferred: browsers like Firefox/Zen
    # implement it to switch to the exact playing tab, not just the
    # window, which a wmctrl/xdotool title match can't do.
    if busctl --user call "org.mpris.MediaPlayer2.$player" /org/mpris/MediaPlayer2 \
        org.mpris.MediaPlayer2 Raise 2> /dev/null; then
        exit 0
    fi

    base=${player%%.*}
    title=$(playerctl metadata title 2> /dev/null)

    win=$(wmctrl -lx | grep -i "$base" | head -n1 | awk '{print $1}')

    # MPRIS webextensions on Firefox-family browsers (Firefox, Zen,
    # LibreWolf, Waterfox, Floorp, ...) all report the player as
    # "firefox" regardless of the actual browser, so the class match
    # above misses forks. Fall back to a known class list, then to
    # matching the window whose (active) tab title mentions the track.
    if [ -z "$win" ] && [ "$base" = "firefox" ]; then
        win=$(wmctrl -lx | grep -iE "firefox|zen|librewolf|waterfox|floorp" | head -n1 | awk '{print $1}')
    fi

    if [ -z "$win" ] && [ -n "$title" ]; then
        win=$(wmctrl -lx | grep -iF "$title" | head -n1 | awk '{print $1}')
    fi

    [ -n "$win" ] && wmctrl -i -a "$win"
    exit 0
}

[ "$1" = "--focus" ] && focus_player

player_status=$(playerctl status 2> /dev/null)

if [ "$player_status" = "Playing" ]; then
    echo "${ARTIST_BG}${ARTIST_FG}  $(playerctl metadata artist) ${NC}${NC_BGM} ${SONG_BG} $(playerctl metadata title)"
elif [ "$player_status" = "Paused" ]; then
    echo "${ARTIST_BG}${ARTIST_FG} 󰽺 $(playerctl metadata artist) ${NC}${NC_BGM} ${SONG_BG} $(playerctl metadata title)"
else
    echo  "Iterate!"
fi