#!/bin/sh

NC='%{F-}'
NC_BGM='%{B-}'
ARTIST_FG='%{F#1f1f1f}'
ARTIST_BG='%{B#cfd8ff}'
SONG_FG='%{F#1f1f1f}'
SONG_BG='%{B#1a2e1a}'



player_status=$(playerctl status 2> /dev/null)

if [ "$player_status" = "Playing" ]; then
    echo "${ARTIST_BG}${ARTIST_FG}  $(playerctl metadata artist) ${NC}${NC_BGM} ${SONG_BG} $(playerctl metadata title)"
elif [ "$player_status" = "Paused" ]; then
    echo "${ARTIST_BG}${ARTIST_FG} 󰽺 $(playerctl metadata artist) ${NC}${NC_BGM} ${SONG_BG} $(playerctl metadata title)"
else
    echo  "Iterate!"
fi