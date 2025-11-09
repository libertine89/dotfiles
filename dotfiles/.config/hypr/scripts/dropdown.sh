#!/usr/bin/env bash

APP_CLASS="kitty-dropdown"
TOGGLE="/tmp/droptoggle"

window_info=$(hyprctl clients -j | jq -r --arg CLASS "$APP_CLASS" '.[] | select(.class == $CLASS) | {address} | @json' | head -n1)

if [ -z "$window_info" ]; then
    
    kitty --class "$APP_CLASS" &
    sleep 0.3
    hyprctl dispatch movewindowpixel 0 585 ,class:^$APP_CLASS$
    rm "$TOGGLE"
else
    if [ ! -f "$TOGGLE" ]; then
        hyprctl dispatch movewindowpixel 0 -585 ,class:^$APP_CLASS$
        touch "$TOGGLE"
    else
        hyprctl dispatch movewindowpixel 0 585 ,class:^$APP_CLASS$
        rm "$TOGGLE"
    fi
    hyprctl dispatch focuswindow class:^$APP_CLASS$
fi
