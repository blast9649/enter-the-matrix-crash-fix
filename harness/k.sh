#!/bin/bash
# usage: k.sh name key... ; keys sent via XTest to ETM in gamescope :4; "sleep:N" waits; "hold:key:sec" holds; screenshot -> ~/etm-shots/name.png
export DISPLAY=${GD:-:$(cat ~/etm-work/display 2>/dev/null || echo 4)}
W=$(xdotool search --name '^Enter The Matrix$' | tail -1)
N=$1; shift
for k in "$@"; do case $k in sleep:*) sleep ${k#sleep:};; hold:*) a=${k#hold:}; xdotool keydown ${a%%:*}; sleep ${a#*:}; xdotool keyup ${a%%:*};; type:*) xdotool type --delay 120 "${k#type:}";; *) xdotool keydown $k; sleep 0.05; xdotool keyup $k; sleep 0.8;; esac; done
sleep ${S:-2}; PATH=${GS_PREFIX:-/usr}/bin:$PATH gamescopectl screenshot ~/etm-shots/$N.png >/dev/null 2>&1; sleep 1.5; echo ~/etm-shots/$N.png
