# Rollback

## Undo the crash patch
- `python revert-patch.py Matrix.exe` (restores `Matrix.exe.v12-orig` or writes the original 17 bytes back), or
- copy your own backup of `Matrix.exe` back into the game folder.

Original v1.2 MD5: `b819db196030d06484465151c4a3e683`. Patched MD5: `9bc208b7beabe438e95ee548f546f01f`.
Original bytes at file offset 0x1F5A00: `55 8B EC 51 89 4D FC 8B 45 FC 8B 40 20 8B E5 5D C3`.

## Optional extras used during testing (Linux)
- WidescreenFix: remove `d3d9.dll` and `scripts/` from the game folder, drop `WINEDLLOVERRIDES="d3d9=n,b"` from your launcher and set `RESOLUTION` back to a numeric preset in `MatrixConfig.ini`.
- DXVK: restore the WineD3D `d3d9.dll` you backed up into `syswow64/` and remove `DXVK_CONFIG` (see config/DXVK-NOTES.md).
- `MatrixConfig.ini` test values: `RESOLUTION =1920x1080`, `FRAMERATE_BEHAVIOR =2` (60 Hz cap; recommended).
- If you changed the Wine AeDebug debugger for crash capture, set it back to `winedbg --auto %ld %ld`.

## Leftover processes
If a Wine run leaves `winedevice.exe` processes behind, stop them: `WINEPREFIX=<your prefix> wineserver -k -w`, then kill any remaining `winedevice.exe` / `wine*` processes from that prefix (harness/cleanup.sh automates this).
