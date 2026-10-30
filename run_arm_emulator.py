#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Hasselblad X1D-50c Windows ARMv7 Emulator Launcher (Docker + QEMU armhf)
========================================================================
Builds and runs the real ARMv7 (`linux/arm/v7`) X1D-50c rootfs environment
inside Docker on Windows, executing the actual `/usr/bin/configstore` and
`/usr/bin/victory-gui` ARM binaries and streaming the 640×480 display to
http://127.0.0.1:6080/vnc.html via noVNC.
"""

import subprocess
import argparse
import webbrowser
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
ARM_DIR = ROOT_DIR / "arm_emulator"


def check_docker_status() -> dict:
    """Checks if Docker CLI is installed and if the Docker Desktop daemon is running."""
    try:
        ver = subprocess.run(["docker", "--version"], capture_output=True, text=True, timeout=5)
        if ver.returncode != 0:
            return {"installed": False, "running": False, "detail": "Docker CLI not found"}
        info = subprocess.run(["docker", "info"], capture_output=True, text=True, timeout=6)
        running = info.returncode == 0
        return {
            "installed": True,
            "running": running,
            "version": ver.stdout.strip(),
            "detail": "Docker Desktop is running and ready" if running else "Docker Desktop is installed but daemon is currently stopped (Start Docker Desktop to run ARMv7 container)",
        }
    except Exception as exc:
        return {"installed": False, "running": False, "detail": str(exc)}


def main():
    parser = argparse.ArgumentParser(description="Build & launch the full ARMv7 X1D-50c rootfs emulator via Docker.")
    parser.add_argument("--check", action="store_true", help="Only check Docker availability")
    parser.add_argument("--port", type=int, default=6080, help="noVNC web port (default: 6080)")
    args = parser.parse_args()

    status = check_docker_status()
    if args.check:
        print(status)
        return

    print("=" * 76)
    print(" Hasselblad X1D-50c – Real ARMv7 Rootfs Emulator (Docker + QEMU armhf)")
    print("=" * 76)
    if not status["installed"]:
        print("[!] Docker is not installed. Use `python ui_simulator/run_simulator.py` for native Windows .cim emulation.")
        return
    if not status["running"]:
        print(f"[!] {status['detail']}")
        print("    1. Start Docker Desktop on Windows.")
        print("    2. Re-run: python run_arm_emulator.py")
        return

    print("[*] Registering QEMU binfmt_misc for ARMv7 (linux/arm/v7)...")
    subprocess.run(
        ["docker", "run", "--rm", "--privileged", "multiarch/qemu-user-static", "--reset", "-p", "yes"],
        check=False,
    )

    print("[*] Building ARMv7 container image 'x1d-armv7-emulator'...")
    subprocess.run(
        ["docker", "build", "--platform=linux/arm/v7", "-t", "x1d-armv7-emulator", str(ARM_DIR)],
        check=True,
    )

    url = f"http://127.0.0.1:{args.port}/vnc.html?autoconnect=true&resize=scale"
    print(f"[*] Starting ARMv7 X1D-50c container on {url} ...")
    webbrowser.open(url)
    subprocess.run(
        [
            "docker", "run", "--rm", "-it",
            "--platform=linux/arm/v7",
            "--privileged",
            "-p", f"{args.port}:6080",
            "-v", f"{ROOT_DIR}:/workspace",
            "x1d-armv7-emulator",
        ],
        check=False,
    )


if __name__ == "__main__":
    main()
