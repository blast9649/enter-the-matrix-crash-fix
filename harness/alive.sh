#!/bin/bash
# alive.sh [--end] : status; cleans up when the game is dead, on --end, and on INT/TERM
trap '~/etm-work/cleanup.sh; exit 130' INT TERM
if pgrep -f '^C:.*Matrix.exe' >/dev/null; then echo ALIVE; [ "$1" = --end ] && ~/etm-work/cleanup.sh
else echo DEAD; grep -m3 -E 'Unhandled|EXCEPTION_ACCESS' ~/etm-work/run.log | cut -c1-160; ~/etm-work/cleanup.sh; fi
