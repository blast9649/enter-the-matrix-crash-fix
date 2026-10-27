#!/bin/bash
# pre-run guard: system bus responsive (leftover winedevice.exe processes can wedge it)
env -u DBUS_SYSTEM_BUS_ADDRESS timeout 5 busctl --system list >/dev/null 2>&1 || { echo "GUARD FAIL: system bus wedged"; exit 1; }
echo GUARD OK
