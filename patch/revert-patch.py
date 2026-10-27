#!/usr/bin/env python3
"""Revert: restore Matrix.exe from Matrix.exe.v12-orig (or write the original 17 bytes back)."""
import hashlib, shutil, sys, os
V12 = "b819db196030d06484465151c4a3e683"; PATCHED = "9bc208b7beabe438e95ee548f546f01f"
OFF = 0x1F5A00; OLD = bytes.fromhex("558BEC51894DFC8B45FC8B40208BE55DC3"); NEW = bytes.fromhex("89C885C074048B4020C3B808000000C3CC")
md5 = lambda p: hashlib.md5(open(p, "rb").read()).hexdigest()
exe = sys.argv[1] if len(sys.argv) > 1 else "Matrix.exe"; bak = exe + ".v12-orig"
if md5(exe) == V12: sys.exit("already original v1.2")
if os.path.exists(bak) and md5(bak) == V12: shutil.copy2(bak, exe)
elif md5(exe) == PATCHED:
    with open(exe, "r+b") as f: f.seek(OFF); f.write(OLD)
else: sys.exit("unknown MD5 and no valid backup; refusing")
assert md5(exe) == V12; print("reverted OK", V12)
