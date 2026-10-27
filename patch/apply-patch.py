#!/usr/bin/env python3
"""Fix Enter The Matrix v1.2 crash at Matrix.exe+0x1F5A0A (null deref of the 0x98d08c front-end pointer).
Usage: apply-patch.py /path/to/Matrix.exe   (backs up to Matrix.exe.v12-orig if absent)"""
import hashlib, shutil, sys, os
V12 = "b819db196030d06484465151c4a3e683"; PATCHED = "9bc208b7beabe438e95ee548f546f01f"
OFF = 0x1F5A00
OLD = bytes.fromhex("558BEC51894DFC8B45FC8B40208BE55DC3")
NEW = bytes.fromhex("89C885C074048B4020C3B808000000C3CC")
md5 = lambda p: hashlib.md5(open(p, "rb").read()).hexdigest()
exe = sys.argv[1] if len(sys.argv) > 1 else "Matrix.exe"
cur = md5(exe)
if cur == PATCHED: sys.exit(f"already patched ({cur})")
if cur != V12: sys.exit(f"MD5 {cur} is not v1.2 {V12}; refusing")
bak = exe + ".v12-orig"
if not os.path.exists(bak): shutil.copy2(exe, bak); print("backup:", bak)
elif md5(bak) != V12: sys.exit(f"{bak} exists but is not v1.2; refusing")
with open(exe, "r+b") as f:
    f.seek(OFF); assert f.read(len(OLD)) == OLD, "unexpected bytes at 0x1F5A00"
    f.seek(OFF); f.write(NEW)
new = md5(exe)
if new != PATCHED: shutil.copy2(bak, exe); sys.exit(f"result MD5 {new} != {PATCHED}; restored original")
print("patched OK", new)
