#!/bin/bash
# Kill every process belonging to the ETM test prefix / headless harness.
[ -n "$WINEPREFIX$WINEDEBUG" ] && exec env -u WINEPREFIX -u WINEDEBUG "$0" "$@"  # never self-match
P=$HOME/.local/share/wineprefixes/enter-the-matrix
WINEPREFIX=$P timeout 20 wineserver -k -w 2>/dev/null
find_pids(){ for d in /proc/[0-9]*; do p=${d#/proc/}; [ "$p" = $$ ] && continue
  [ -O $d ] || continue; c=$(cat $d/comm 2>/dev/null); e=$( { tr "\0" "\n" <$d/environ; } 2>/dev/null)
  if grep -qx "WINEPREFIX=$P" <<<"$e"; then echo $p; continue; fi
  case $c in gamescope*) grep -q gamescope $d/cmdline 2>/dev/null && echo $p;; esac
  case "$c" in winedevice.exe|wine*) grep -q "$P" <<<"$e$(tr '\0' ' ' <$d/cmdline 2>/dev/null)" && echo $p;; esac
done | sort -u; }
for i in 1 2 3; do L=$(find_pids); [ -z "$L" ] && break; kill -9 $L 2>/dev/null; sleep 1; done
L=$(find_pids); S=$(ss -xp 2>/dev/null | grep -E 'wine|winedevice|gamescope')
echo "cleanup: remaining_pids=[${L}] wine_sockets=$(grep -c . <<<"$S" | sed 's/^1$/&/')"; [ -n "$S" ] && echo "$S"
[ -z "$L" ] && [ -z "$S" ]
