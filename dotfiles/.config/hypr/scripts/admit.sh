#!/bin/bash

CMD="hyprctl dispatch"
DIR="$1"

case "$1" in
    l|left) DIR="l" ;;
    r|right) DIR="r" ;;
    *) echo "Invalid direction: $1" >&2; exit 1 ;;
esac

REV_DIR="l"

if [ "$DIR" == "$REV_DIR" ]; then
    REV_DIR="r"
fi

$CMD scroller:marksadd current_window

$CMD scroller:admitwindow $DIR
$CMD scroller:setheight one
#$CMD scroller:admitwindow $DIR
sleep 0.01
$CMD scroller:fitheight all
sleep 0.01
#$CMD scroller:alignwindow $REV_DIR
#sleep 0.01
$CMD movefocus $REV_DIR
#sleep 0.01
$CMD scroller:fitheight all
sleep 0.01
$CMD scroller:movefocus $DIR
#$CMD scroller:movefocus $DIR

$CMD scroller:marksvisit current_window
$CMD scroller:marksreset
