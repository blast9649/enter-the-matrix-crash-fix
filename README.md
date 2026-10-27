# Enter the Matrix (PC) v1.2 crash fix

A tiny binary patch for **Enter the Matrix (PC, official v1.2)** that fixes a crash when you quit, reload, or switch levels from the in-game **pause** or **GAME OVER** menu.

> **The game is not included.** You need your own legal copy of Enter the Matrix, updated to the official v1.2 patch. This repository contains no game files, only a patch for `Matrix.exe`.

## Symptom
The game sometimes crashes to the desktop when you:
- choose Quit from the pause menu (especially just as you die) and answer the GAME OVER screen,
- quit and reload a save, or
- switch levels or locations.

It happens with old or fresh saves, with or without cheats, on Windows and on Linux/Wine. Under Wine it shows up as:
```
wine: Unhandled page fault on read access to 00000020 at address 005F5A0A
```
On Windows it is an access violation (0xC0000005) in `Matrix.exe` at offset `0x1F5A0A`.

## Affected build
| File | MD5 |
|---|---|
| `Matrix.exe` official v1.2 (input) | `b819db196030d06484465151c4a3e683` |
| `Matrix.exe` after this patch | `9bc208b7beabe438e95ee548f546f01f` |

Other versions (v1.0, other patches, no-CD exes) are not supported; the script refuses to touch them.

## Apply
Back up your game folder first. The patch changes 17 bytes at file offset `0x1F5A00`.

**Python 3 (Windows or Linux)**: copy `patch/apply-patch.py` into the game folder (next to `Matrix.exe`) and run:
```
python apply-patch.py Matrix.exe      # Windows (use python3 on Linux)
```
It checks the MD5, saves the original as `Matrix.exe.v12-orig`, writes the patch, and verifies the result.

**IPS patcher**: apply `patch/patch.ips` to `Matrix.exe` with [Lunar IPS](https://fusoya.eludevisibility.org/lips/) or [Floating IPS (Flips)](https://github.com/Alcaro/Flips). Make a copy of `Matrix.exe` first, then check the MD5 of the result against the table above.

**By hand**: `patch/patch.hex.txt` lists the old and new bytes.

## Revert
```
python revert-patch.py Matrix.exe
```
It restores `Matrix.exe.v12-orig` if present, otherwise writes the original 17 bytes back. Or just copy your backup over `Matrix.exe`.

## Root cause (short version)
The function at `0x5F5A00` is a tiny getter that returns a field (`this+0x20`) of a front-end menu object. That object only exists while the main menu is up; during gameplay the global pointer to it is NULL. Eight callers check for NULL, but two (a menu input handler at `0x663C20` and a menu builder at `0x66773B`) don't. When the in-game pause or game-over menu runs those paths, the getter reads through the NULL pointer and the game crashes. Because it depends on the timing of the menu teardown, it is intermittent.

The patch rewrites the getter, in place, to return `8` when `this` is NULL. `8` sends both unchecked callers down the "skip" branch they already take outside the in-level mode. With a valid object the getter behaves exactly as before.

```
OLD 55 8B EC 51 89 4D FC 8B 45 FC 8B 40 20 8B E5 5D C3
NEW 89 C8 85 C0 74 04 8B 40 20 C3 B8 08 00 00 00 C3 CC
```
Full details, disassembly and test matrix: [WRITEUP.md](WRITEUP.md).

## Repository layout
- `patch/`: `apply-patch.py`, `revert-patch.py`, `patch.ips`, `patch.hex.txt`
- `WRITEUP.md`: technical write-up
- `ROLLBACK.md`: undoing the patch and the optional Linux setup
- `logs/`: crash log excerpts (Wine `+seh` traces)
- `config/`: example Linux launcher, `MatrixConfig.ini`, DXVK notes (optional)
- `harness/`: headless Linux test scripts (gamescope + xdotool) used to reproduce and verify
- `screenshots/`: test screenshots

## Linux notes
Tested on Wine (staging 11.20) with ThirteenAG's WidescreenFix and with both WineD3D and DXVK 3.1.1. Neither is needed for the fix. If you script lots of headless runs, see the note about leftover `winedevice.exe` processes in WRITEUP.md section 11.

## Credits
Crash investigation and patch by **[blast9649](https://github.com/blast9649)**.
Enter the Matrix is © Shiny Entertainment / Atari / Warner Bros. This project is not affiliated with them.

## License
MIT. See [LICENSE](LICENSE). The license covers the scripts, patch files and documents in this repository, not the game.
