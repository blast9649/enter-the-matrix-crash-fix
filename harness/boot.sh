#!/bin/bash
# boot.sh SAVEFILE : install save, start headless, get to main menu
G="$HOME/.local/share/wineprefixes/enter-the-matrix/drive_c/Program Files (x86)/Atari/Enter The Matrix"
~/etm-work/guard.sh || exit 1; ~/etm-work/cleanup.sh >/dev/null
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/nonexistent WINEPREFIX=~/.local/share/wineprefixes/enter-the-matrix WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-d3d9=n,b}"

rm -f "$WINEPREFIX/drive_c/etm-bt.txt"
[ -n "$1" ] && cp "$1" "$G/saved/Save"
WD=${WD:-+seh,+loaddll,+tid} ~/etm-work/start.sh
sleep 22; S=1 ~/etm-work/k.sh boot Escape sleep:3 Escape sleep:3 Escape sleep:4 >/dev/null
