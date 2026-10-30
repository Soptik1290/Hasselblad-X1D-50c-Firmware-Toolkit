#!/bin/bash
set -e

echo "========================================================================"
echo " Hasselblad X1D-50c ARMv7 Linux Rootfs Emulator (QEMU armhf + Mesa)"
echo "========================================================================"

ROOTFS_TAR="/workspace/X1D_v1_25_0_extracted/rootfs"
X1D_ROOT="/x1d_root"

if [ ! -f "$ROOTFS_TAR" ]; then
    echo "[!] Error: $ROOTFS_TAR not found. Extract a .cim firmware first!"
    exit 1
fi

if [ ! -d "$X1D_ROOT/usr/bin" ]; then
    echo "[*] Extracting X1D-50c ARMv7 rootfs.tar.bz2 into $X1D_ROOT ..."
    mkdir -p "$X1D_ROOT"
    tar -xjf "$ROOTFS_TAR" -C "$X1D_ROOT"
fi

# If a patched victory-gui exists in workspace, overlay it into the ARMv7 rootfs
if [ -f "/workspace/X1D_v1_25_0_extracted/victory-gui" ]; then
    echo "[*] Injecting /workspace/X1D_v1_25_0_extracted/victory-gui into $X1D_ROOT/usr/bin/victory-gui"
    cp -f "/workspace/X1D_v1_25_0_extracted/victory-gui" "$X1D_ROOT/usr/bin/victory-gui"
    chmod 0755 "$X1D_ROOT/usr/bin/victory-gui"
fi

# Replace proprietary Freescale Vivante /dev/galcore libEGL & libGLESv2 with software Mesa armhf
echo "[*] Overlaying ARMv7 Mesa Software OpenGL ES 2.0 (llvmpipe/swrast) over Vivante GPU libs..."
cp -f /usr/lib/arm-linux-gnueabihf/mesa-egl/libEGL.so.1* "$X1D_ROOT/usr/lib/" 2>/dev/null || cp -f /usr/lib/arm-linux-gnueabihf/libEGL.so.1* "$X1D_ROOT/usr/lib/" 2>/dev/null || true
cp -f /usr/lib/arm-linux-gnueabihf/mesa-egl/libGLESv2.so.2* "$X1D_ROOT/usr/lib/" 2>/dev/null || cp -f /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2* "$X1D_ROOT/usr/lib/" 2>/dev/null || true

# Bind system directories
mkdir -p "$X1D_ROOT/tmp" "$X1D_ROOT/var/run/dbus"
mount --bind /proc "$X1D_ROOT/proc" 2>/dev/null || true
mount --bind /sys "$X1D_ROOT/sys" 2>/dev/null || true
mount --bind /dev "$X1D_ROOT/dev" 2>/dev/null || true
mount --bind /tmp "$X1D_ROOT/tmp" 2>/dev/null || true

# Start system D-Bus
mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid
dbus-daemon --system --fork
mount --bind /var/run/dbus "$X1D_ROOT/var/run/dbus" 2>/dev/null || true

# Start Mock Hardware D-Bus services (cambody, farm, suc, storage)
python3 /emu/mock_hardware_dbus.py &

# Start real ARMv7 configstore from X1D-50c rootfs
echo "[*] Starting real ARMv7 /usr/bin/configstore daemon..."
chroot "$X1D_ROOT" /usr/bin/configstore &
sleep 1

# Start 640x480 virtual X11 + Weston Wayland compositor + VNC + noVNC
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp
export LIBGL_ALWAYS_SOFTWARE=1
export QT_QUICK_BACKEND=software
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

echo "[*] Starting 640x480 Virtual Framebuffer (Xvfb) + Weston + noVNC on port 6080..."
Xvfb :0 -screen 0 640x480x24 &
sleep 1
weston --backend=x11-backend.so --width=640 --height=480 --idle-time=0 &
sleep 2
x11vnc -display :0 -forever -shared -nopw -quiet &
websockify --web=/usr/share/novnc/ 6080 localhost:5900 &

echo "========================================================================"
echo " [+] ARMv7 Emulator Running! Open http://127.0.0.1:6080/vnc.html"
echo "========================================================================"

# Launch the real ARMv7 victory-gui binary inside the X1D rootfs
chroot "$X1D_ROOT" /usr/bin/env \
    XDG_RUNTIME_DIR=/tmp \
    WAYLAND_DISPLAY=wayland-0 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    QT_WAYLAND_DISABLE_WINDOWDECORATION=1 \
    /usr/bin/victory-gui -platform wayland --wedge --main || tail -f /dev/null
