# DXVK notes (Linux / Wine only, optional)
- Tested with DXVK 3.1.1, vendor release from https://github.com/doitsujin/dxvk/releases.
- Install: copy dxvk-3.1.1/x32/d3d9.dll to the prefix's drive_c/windows/syswow64/d3d9.dll (MD5 093943dbadc00725ed39bb25b22c9dfa). Back up the original WineD3D d3d9.dll first.
- Load chain: game-folder d3d9.dll (WidescreenFix / Ultimate ASI Loader, WINEDLLOVERRIDES=d3d9=n,b) -> C:\windows\system32\d3d9.dll (= DXVK). The Wine log shows "DXVK: v3.1.1".
- Config: export DXVK_CONFIG="d3d9.deferSurfaceCreation = True".
- Revert to WineD3D: restore your backed-up d3d9.dll and drop the DXVK_CONFIG line.
- DXVK is not required for the crash fix; the patch works the same on WineD3D and on Windows.
