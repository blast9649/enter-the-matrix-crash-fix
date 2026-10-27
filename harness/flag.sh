#!/bin/bash
# flag.sh : one winedbg session, attach -> read cheat flags & mgr ptr -> detach
export WINEPREFIX=~/.local/share/wineprefixes/enter-the-matrix DBUS_SYSTEM_BUS_ADDRESS=unix:path=/nonexistent WINEDEBUG=-all
W=$(winedbg --command "info proc" 2>/dev/null | awk '/Matrix.exe/{print $1}' | head -1)
printf 'attach 0x%s\nx/x 0x97f720\nx/x *(int*)0x97f720 + 0x1e4\nx/x 0x98d08c\ndetach\nquit\n' $W | timeout 30 winedbg 2>&1 | grep -v '^$' | tail -6
