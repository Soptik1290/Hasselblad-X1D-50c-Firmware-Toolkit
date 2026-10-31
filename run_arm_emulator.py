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

import sys
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


def cleanup_stale_containers(port: int, container_name: str = "x1d-armv7-emulator"):
    """Stops and removes any container using the target port or the container name."""
    try:
        # Check if container named container_name exists
        inspect = subprocess.run(
            ["docker", "ps", "-a", "-q", "--filter", f"name=^/{container_name}$"],
            capture_output=True, text=True, timeout=5
        )
        if inspect.stdout.strip():
            print(f"[*] Removing previous container '{container_name}'...")
            subprocess.run(["docker", "rm", "-f", container_name], capture_output=True, check=False)

        # Check if any container is publishing on the port
        port_check = subprocess.run(
            ["docker", "ps", "-a", "-q", "--filter", f"publish={port}"],
            capture_output=True, text=True, timeout=5
        )
        if port_check.stdout.strip():
            for cid in port_check.stdout.split():
                cid = cid.strip()
                if cid:
                    print(f"[*] Stopping stale container {cid} occupying port {port}...")
                    subprocess.run(["docker", "rm", "-f", cid], capture_output=True, check=False)
    except Exception as exc:
        print(f"[!] Warning cleaning stale containers: {exc}")


def main():
    parser = argparse.ArgumentParser(description="Build & launch the full ARMv7 X1D-50c rootfs emulator via Docker.")
    parser.add_argument("--check", action="store_true", help="Only check Docker availability")
    parser.add_argument("--port", type=int, default=6080, help="noVNC web port (default: 6080)")
    parser.add_argument(
        "--cim",
        type=str,
        default="firmware/X1D_v1_25_0.cim",
        help="Path to .cim firmware container to boot (default: firmware/X1D_v1_25_0.cim)",
    )
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

    cim_file = Path(args.cim)
    if not cim_file.is_absolute():
        cim_file = (ROOT_DIR / cim_file).resolve()

    extracted_dir = ROOT_DIR / f"{cim_file.stem}_extracted"
    rootfs_tar = extracted_dir / "rootfs"

    if not rootfs_tar.exists():
        if not cim_file.exists():
            print(f"[!] Error: Firmware file '{cim_file}' does not exist.")
            return
        print(f"[*] Extracting firmware {cim_file.name} to {extracted_dir.name}...")
        subprocess.run(
            ["python", str(ROOT_DIR / "hasselblad_extract.py"), str(cim_file), "-o", str(extracted_dir)],
            check=True,
        )

    print(f"[*] Using firmware rootfs from: {extracted_dir.name}/rootfs")

    container_name = "x1d-armv7-emulator"
    cleanup_stale_containers(args.port, container_name)

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
    tty_flags = ["-it"] if sys.stdin.isatty() else []
    subprocess.run(
        [
            "docker", "run", "--rm", *tty_flags,
            "--name", container_name,
            "--platform=linux/arm/v7",
            "--privileged",
            "-e", f"X1D_ROOTFS_TAR=/workspace/{extracted_dir.name}/rootfs",
            "-e", f"X1D_EXTRACTED_DIR=/workspace/{extracted_dir.name}",
            "-p", f"{args.port}:6080",
            "-v", f"{ROOT_DIR}:/workspace",
            "x1d-armv7-emulator",
        ],
        check=False,
    )


if __name__ == "__main__":
    main()
