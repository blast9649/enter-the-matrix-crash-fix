# Enter The Matrix v1.2: menu-teardown null-dereference crash. Technical write-up

## 1. Symptoms
Players report crashes that happen with old or fresh saves, around cheats and when switching levels and locations, on real Windows as well as Linux.
Reproduced on Linux as a hard crash: `wine: Unhandled page fault on read access to 00000020 at address 005F5A0A`.

## 2. Environment
- Host: Arch Linux. wine-staging 11.20. Prefix `~/.local/share/wineprefixes/enter-the-matrix`.
- Game: Atari retail, upgraded with the **official Atari v1.2 patch** (no crack/no-CD).
  v1.2 removes the disc check and is the last official build. `Matrix.exe` v1.2 MD5 `b819db196030d06484465151c4a3e683`.
  Image base 0x400000; .text at VA 0x401000 = file 0x1000, so file offset = VA − 0x400000. Not large-address-aware.
- WidescreenFix (ThirteenAG, Ultimate ASI Loader as game-folder `d3d9.dll` + `scripts/`), loaded with `WINEDLLOVERRIDES=d3d9=n,b`.
  `d3d9_Proxy.dll` left in place.
- `MatrixConfig.ini`: `RESOLUTION =1920x1080`, `FRAMERATE_BEHAVIOR =2` (0 = free run, 1 = monitor refresh, 2 = 60 Hz).
  The 60 Hz cap matters: the engine's physics/driving misbehaves uncapped.
- Renderer: tested WineD3D and DXVK 3.1.1; final is DXVK (section 8).

## 3. Method
- Headless: gamescope 1920x1080 with nested Xwayland (:4), input via xdotool, screenshots via gamescopectl (harness/).
- Logging: `WINEDEBUG=+seh,+loaddll,+tid`. AeDebug was temporarily pointed at a bat that redirected `winedbg --auto` output (since restored).
- Disassembly: objdump -M intel over .text (0x401000–0x8fa000), Ghidra for xrefs.
- Cheats were entered via Hacking > `cheat <code>`, singly and combined. Load paths exercised: in-level location switches (lobby elevator, `f`),
  full level loads via the post-load **Select Level** screen (Post Office ↔ the bonus "Sparks' Training Construct"),
  pause > Quit > Yes > Load cycles, and death / game-over. Both characters (Ghost, Niobe).

## 4. Reproductions (unpatched v1.2, WineD3D)
### Crash 1: Ghost, All Weapons save, quit from the pause menu while being killed, then answering GAME OVER
```
wine: Unhandled page fault on read access to 00000020 at address 005F5A0A (thread 012c), starting debugger...
dispatch_exception code=c0000005 (EXCEPTION_ACCESS_VIOLATION) flags=0 addr=00000000005F5A0A
 info[0]=0 info[1]=0x20
rax=0 rcx=0 rdx=8 rsi=0x97f800 rdi=0x31b1814 rbp=0x26fc5c
```
### Crash 2: Niobe, Infinite Health save, loop of pause > Quit > Yes > Load > Select Level > walk to elevator > `f`. Crashed in cycle 3, no death involved
```
wine: Unhandled page fault on read access to 00000020 at address 005F5A0A (thread 012c), starting debugger...
```
Full logs: logs/*.log.gz, excerpts in logs/*-excerpt.txt. winedbg captured no stack (attach only).

## 5. Root cause
Faulting function (thunk `0x40154b: jmp 0x5f5a00`):
```
5f5a00: 55              push ebp
5f5a01: 8b ec           mov  ebp,esp
5f5a03: 51              push ecx
5f5a04: 89 4d fc        mov  [ebp-4],ecx
5f5a07: 8b 45 fc        mov  eax,[ebp-4]
5f5a0a: 8b 40 20        mov  eax,[eax+0x20]     ; <- fault, this == NULL
5f5a0d: 8b e5           mov  esp,ebp
5f5a0f: 5d              pop  ebp
5f5a10: c3              ret
```
A thiscall getter returning `this->+0x20` (a mode/type value compared against 2, 7 and 8).
Unchecked callers, both guarded only by `cmp [0x97ed80],1`:
```
663c11: cmp  dword [0x97ed80],1 ; jne 663c6d
663c1a: mov  ecx,[0x98d08c]
663c20: call 0x40154b            ; getter
663c25: cmp  eax,8 ; je 663c6d
663c2a: mov  ecx,[0x98d08c] ; call 0x40154b ; cmp eax,2 ...
66772c: cmp  dword [0x97ed80],1 ; jne 66779c
667735: mov  ecx,[0x98d08c]
66773b: call 0x40154b
667740: cmp  eax,8 ; je 66779c
667745: mov  ecx,[0x98d08c] ; call 0x40154b ; cmp eax,2 ...
```
`0x663c20` is a menu input handler (plays UI sound 0x35d); `0x66773b` is a menu builder (picks text id 0x2f vs 0xb).
The global `0x98d08c` is created at 0x65bf8a/0x65c038 and freed and NULLed by the teardown at 0x65c863 (store at 0x65c8b2).
Live reads (winedbg) showed `[0x98d08c] = 0x031e41a0` at the main menu and **0 during gameplay**. It is a front-end object.
The other eight callers null-check it; these two don't. When the in-game pause / game-over menu runs these paths, the getter dereferences NULL+0x20.
Timing (teardown vs. menu frame) explains why it's intermittent and why it shows up around quit/reload/level switches. It's a game bug, consistent with crashes on real Windows.

## 6. The patch
Fix the getter once rather than patching both call sites (no code cave needed; it fits in the original 17 bytes):
```
file 0x1F5A00 / VA 0x5F5A00, 17 bytes
OLD 55 8B EC 51 89 4D FC 8B 45 FC 8B 40 20 8B E5 5D C3
NEW 89 C8 85 C0 74 04 8B 40 20 C3 B8 08 00 00 00 C3 CC

5f5a00: 89 c8          mov  eax,ecx
5f5a02: 85 c0          test eax,eax
5f5a04: 74 04          je   5f5a0a
5f5a06: 8b 40 20       mov  eax,[eax+0x20]
5f5a09: c3             ret
5f5a0a: b8 08 00 00 00 mov  eax,8
5f5a0f: c3             ret
5f5a10: cc             int3
```
Reasoning:
- Non-null `this` gives identical results (same load, same calling convention; thiscall with no stack args, so a plain `ret`; ebp-frame removal is harmless).
- NULL returns 8, which makes both unchecked callers take their `je` skip branch, the same path they take when not in the in-level mode. The other callers null-check before calling, so the change never reaches them.
- Any other user of the thunk would have crashed on NULL anyway.

MD5 v1.2 `b819db196030d06484465151c4a3e683` → patched `9bc208b7beabe438e95ee548f546f01f`. Tools: patch/apply-patch.py, revert-patch.py, patch.ips, patch.hex.txt.

## 7. Test matrix
| Exe | Renderer / CPU | Save | Test | Result |
|---|---|---|---|---|
| v1.2 | WineD3D | Ghost, All Weapons | quit from pause while dying | **crash 0x5F5A0A** |
| v1.2 | WineD3D | Niobe, Infinite Health | quit/reload + elevator loop | **crash 0x5F5A0A** (cycle 3) |
| v1.2 | WineD3D | Ghost, combined cheats | 5 level switches + doors | OK |
| patched | WineD3D | Niobe | quit/reload + elevator ×6 | OK |
| patched | WineD3D | Ghost, All Weapons | quit while dying at 30 s and 45 s | OK |
| patched | DXVK 3.1.1 | Ghost, combined cheats | 4 level switches | OK |
| patched | DXVK + `taskset -c 0` | Niobe | 4 quit/reload + elevator cycles | OK |

Cheats accepted by v1.2: 7F4DF451 infinite health, 69E5D9E4 infinite focus, 0034AFFF all weapons, 1DDF2556 infinite ammo, 4516DF45 enemies deaf,
FFF0020A fast focus, 13D2C77F bonus level ("Unlocked bonus test level"), 7867F443 faster Logos. FFFFFFF1 invisible: entered but not confirmed.
Rejected ("Invalid cheat code"): D5C55D1E multiplayer, 312MF451 taxi (contains a non-hex "M").

## 8. Renderer: DXVK
DXVK 3.1.1 (vendor release) in the prefix's syswow64, chained behind the WidescreenFix ASI loader; `DXVK_CONFIG="d3d9.deferSurfaceCreation = True"`.
As stable as WineD3D in all cycles, with correct rendering and none of WineD3D's "W buffer is not well handled" fixme spam. Details: config/DXVK-NOTES.md.
Single-core affinity (`taskset -c 0`) made no difference, so no affinity is set.

## 9. Cheat persistence
The cheat dword is `[*0x97f720 + 0x1e4]` (toggle function 0x68f54f, jump table 0x68f79e). A live read in gameplay after loading the All Weapons save gave **0**, and the HUD showed only the default pistol.
Cheats do not survive save/load. They apply to the session in which they're entered.
Readers of that dword include 0x6b4943 / 0x6da901 (bit 0x8, AI/weapon logic), 0x5d5a18 (0x20), 0x6f2287 / 0x77b064 (0x800) and 0x777682 (0x1000); full list in project notes.

## 10. Save-file notes (65,536 bytes)
- Bytes 2–3: checksum; 0x188–0x18B and 0x39C–0x39F change on every write (timestamps/counters).
- **0x1C0**: `21 04 00 00` (0x0421) in every save that has been through Hacking, 0 otherwise. It's a "hacked" marker, **not** the cheat flags. (An earlier reading of 0x0429 for All Weapons was a misread.)
- **0xA00**: `F0 41 00 00` only in the save where 13D2C77F (bonus level) was entered; it then lists "SECRET / Sparks' Training Construct". Probably the unlocked-level bitmap; not confirmed.
- Re-entering infinite health on a save that already had it changed only checksum/timestamp bytes.

## 11. Note: leftover winedevice.exe processes (Linux/Wine)
After many headless runs, `winedevice.exe` processes from the test prefix can survive `wineserver -k`, get reparented to init, and hold system D-Bus sockets with full send queues, which can make dbus-broker drop other clients.
If you script test runs, set `DBUS_SYSTEM_BUS_ADDRESS=unix:path=/nonexistent` for the test runs and clean up afterwards: `WINEPREFIX=<prefix> wineserver -k -w`, then check for and kill any remaining `winedevice.exe`/`wine*` processes that belong to that prefix (harness/cleanup.sh does this).
Note: attaching winedbg to read memory kills the game on detach under the Wine version tested, so live reads are one per run.

## 12. Open unknowns
- Whether entering a cheat twice toggles it off. The save doesn't record it and live reads are destructive.
- Exact meaning of 0xA00 (0x41F0).
- Whether every Windows crash report is exactly this fault (very likely; not verified on Windows).
- The Airport level freeze with All Weapons (reported on Nexus) wasn't reached.
- Whether FFFFFFF1 (invisible) applied.
