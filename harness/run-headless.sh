#!/bin/bash
# usage: run-headless.sh [extra env...]  -> starts gamescope headless + ETM, logs to ~/etm-work/run.log
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/nonexistent
export PATH=${GS_PREFIX:-/usr}/bin:$PATH
export
export WINEPREFIX=$HOME/.local/share/wineprefixes/enter-the-matrix
export WINEDEBUG=${WINEDEBUG:--all}
G="$WINEPREFIX/drive_c/Program Files (x86)/Atari/Enter The Matrix"
cd "$G"
unset WAYLAND_DISPLAY
exec ${GS_PREFIX:-/usr}/bin/gamescope --backend headless -W ${GW:-1920} -H ${GH:-1080} -w ${GW:-1920} -h ${GH:-1080} -r 60 -- ${PRE} wine Matrix.exe "$@" > $HOME/etm-work/run.log 2>&1
