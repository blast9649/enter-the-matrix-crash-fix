#!/bin/bash
# start.sh tag : kill old, launch headless with WINEDEBUG, log to ~/etm-work/logs/tag.log
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/nonexistent
pkill -f 'gamescope --backend headless'; pkill -f Matrix.exe; sleep 3; wineserver -k 2>/dev/null; sleep 1
mkdir -p ~/etm-work/logs
WINEDEBUG=${WD:-+seh,+loaddll} nohup ~/etm-work/run-headless.sh >/dev/null 2>&1 &
sleep 4; for i in $(seq 1 30); do grep -o 'Xwayland on :[0-9]*' ~/etm-work/run.log >/dev/null && break; sleep 1; done
grep -o 'Xwayland on :[0-9]*' ~/etm-work/run.log | sed 's/.*://' > ~/etm-work/display
