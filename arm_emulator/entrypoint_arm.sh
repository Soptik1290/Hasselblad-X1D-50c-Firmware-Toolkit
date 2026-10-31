#!/bin/bash
set -e

cleanup() {
    echo "[*] Interrupted: terminating ARMv7 emulator processes..."
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "========================================================================"
echo " Hasselblad X1D-50c ARMv7 Linux Rootfs Emulator (QEMU armhf + Mesa)"
echo "========================================================================"

ROOTFS_TAR="${X1D_ROOTFS_TAR:-/workspace/X1D_v1_25_0_extracted/rootfs}"
EXTRACTED_DIR="${X1D_EXTRACTED_DIR:-/workspace/X1D_v1_25_0_extracted}"
X1D_ROOT="/x1d_root"

if [ ! -f "$ROOTFS_TAR" ]; then
    echo "[!] Error: $ROOTFS_TAR not found. Extract a .cim firmware first!"
    exit 1
fi

if [ ! -d "$X1D_ROOT/usr/bin" ]; then
    echo "[*] Extracting X1D-50c ARMv7 rootfs.tar.bz2 ($ROOTFS_TAR) into $X1D_ROOT ..."
    mkdir -p "$X1D_ROOT"
    tar -xjf "$ROOTFS_TAR" -C "$X1D_ROOT"
fi

# If a patched victory-gui exists in workspace, overlay it into the ARMv7 rootfs
if [ -f "$EXTRACTED_DIR/victory-gui" ]; then
    echo "[*] Injecting $EXTRACTED_DIR/victory-gui into $X1D_ROOT/usr/bin/victory-gui"
    cp -f "$EXTRACTED_DIR/victory-gui" "$X1D_ROOT/usr/bin/victory-gui"
    chmod 0755 "$X1D_ROOT/usr/bin/victory-gui"
fi

# Patch Yocto libm.so.6 so that Mesa 18+ swrast / LLVM can load GLIBC_2.27 math functions
echo "[*] Patching Yocto libm.so.6 for Mesa SWRAST / LLVM GLIBC_2.27 compatibility..."
python3 /emu/patch_libm.py "$X1D_ROOT/lib/libm.so.6"

# Replace proprietary Freescale Vivante /dev/galcore libEGL & libGLESv2 with software Mesa armhf
echo "[*] Overlaying ARMv7 Mesa Software OpenGL ES 2.0 (llvmpipe/swrast) over Vivante GPU libs..."
mkdir -p "$X1D_ROOT/usr/lib"
cp -f /emu/compat/libxshmfence.so.1 "$X1D_ROOT/usr/lib/" 2>/dev/null || true
cp -f /emu/compat/libbsd.so.0 "$X1D_ROOT/usr/lib/" 2>/dev/null || true

# Copy modern Mesa GLVND dispatcher and backends
cp -f /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0 "$X1D_ROOT/usr/lib/" 2>/dev/null || true
ln -sf libEGL.so.1.0.0 "$X1D_ROOT/usr/lib/libEGL.so.1" 2>/dev/null || true
ln -sf libEGL.so.1.0.0 "$X1D_ROOT/usr/lib/libEGL.so" 2>/dev/null || true
cp -f /usr/lib/arm-linux-gnueabihf/libGLdispatch.so.0* "$X1D_ROOT/usr/lib/" 2>/dev/null || true
cp -f /usr/lib/arm-linux-gnueabihf/libEGL_mesa.so.0* "$X1D_ROOT/usr/lib/" 2>/dev/null || true
cp -f /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2* "$X1D_ROOT/usr/lib/" 2>/dev/null || true

# Copy modern Wayland client/server/cursor/egl libraries
cp -f /usr/lib/arm-linux-gnueabihf/libwayland-client.so.0* "$X1D_ROOT/usr/lib/" 2>/dev/null || true
cp -f /usr/lib/arm-linux-gnueabihf/libwayland-server.so.0* "$X1D_ROOT/usr/lib/" 2>/dev/null || true
cp -f /usr/lib/arm-linux-gnueabihf/libwayland-cursor.so.0* "$X1D_ROOT/usr/lib/" 2>/dev/null || true
cp -f /usr/lib/arm-linux-gnueabihf/libwayland-egl.so.1* "$X1D_ROOT/usr/lib/" 2>/dev/null || true
ln -sf libwayland-egl.so.1 "$X1D_ROOT/usr/lib/libwayland-egl.so" 2>/dev/null || true

# Copy modern libdrm & GCC 7 libstdc++ (needed by Mesa/LLVM)
cp -f /usr/lib/arm-linux-gnueabihf/libdrm.so.2* "$X1D_ROOT/usr/lib/" 2>/dev/null || true
cp -f /usr/lib/arm-linux-gnueabihf/libstdc++.so.6.0.25 "$X1D_ROOT/usr/lib/" 2>/dev/null || true
ln -sf libstdc++.so.6.0.25 "$X1D_ROOT/usr/lib/libstdc++.so.6" 2>/dev/null || true

# Symlink DRI drivers folder
ln -sf /usr/lib/arm-linux-gnueabihf/dri "$X1D_ROOT/usr/lib/dri" 2>/dev/null || true

# Bind system directories
mkdir -p "$X1D_ROOT/tmp" "$X1D_ROOT/var/run/dbus" "$X1D_ROOT/usr/lib/arm-linux-gnueabihf" "$X1D_ROOT/lib/arm-linux-gnueabihf" "$X1D_ROOT/usr/share/glvnd"
mount --bind /proc "$X1D_ROOT/proc" 2>/dev/null || true
mount --bind /sys "$X1D_ROOT/sys" 2>/dev/null || true
mount --bind /dev "$X1D_ROOT/dev" 2>/dev/null || true
mount --bind /tmp "$X1D_ROOT/tmp" 2>/dev/null || true
mount --bind /usr/lib/arm-linux-gnueabihf "$X1D_ROOT/usr/lib/arm-linux-gnueabihf" 2>/dev/null || true
mount --bind /lib/arm-linux-gnueabihf "$X1D_ROOT/lib/arm-linux-gnueabihf" 2>/dev/null || true
mount --bind /usr/share/glvnd "$X1D_ROOT/usr/share/glvnd" 2>/dev/null || true

# Copy Hasselblad D-Bus system policies and grant permissions for all mock services
cp -f "$X1D_ROOT/etc/dbus-1/system.d/"*.conf /etc/dbus-1/system.d/ 2>/dev/null || true
cat << 'EOF' > /etc/dbus-1/system.d/allow-all-hasselblad.conf
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy user="root">
    <allow own_prefix="com.hasselblad"/>
    <allow own="org.freedesktop.systemd1"/>
    <allow send_destination="*"/>
    <allow receive_sender="*"/>
  </policy>
  <policy context="default">
    <allow send_destination="*"/>
    <allow receive_sender="*"/>
  </policy>
</busconfig>
EOF

mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid
dbus-daemon --system --fork
mount --bind /var/run/dbus "$X1D_ROOT/var/run/dbus" 2>/dev/null || true

# Start Mock Hardware D-Bus services (com.hasselblad.*)
python3 /emu/mock_hardware_dbus.py &

# Start real ARMv7 configstore from X1D-50c rootfs
echo "[*] Starting real ARMv7 /usr/bin/configstore daemon..."
chroot "$X1D_ROOT" /usr/bin/env \
    LD_LIBRARY_PATH=/usr/lib:/lib:/usr/lib/arm-linux-gnueabihf:/lib/arm-linux-gnueabihf \
    /usr/bin/configstore &
sleep 1

# Prevent premature camera display sleep/dimming during emulator sessions
dbus-send --system --print-reply --dest=com.hasselblad.config /config \
    org.freedesktop.DBus.Properties.Set string:com.hasselblad.config string:GUI_idle_timeout variant:int32:0 2>/dev/null || true
dbus-send --system --print-reply --dest=com.hasselblad.config /config \
    org.freedesktop.DBus.Properties.Set string:com.hasselblad.config string:BACKLIGHT_idle_timeout variant:int32:0 2>/dev/null || true
dbus-send --system --print-reply --dest=com.hasselblad.config /config \
    org.freedesktop.DBus.Properties.Set string:com.hasselblad.config string:BACKLIGHT_brightness variant:int32:100 2>/dev/null || true

# Start 640x480 virtual X11 + Weston Wayland compositor + VNC + noVNC
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp
export LIBGL_ALWAYS_SOFTWARE=1
export QT_QUICK_BACKEND=software
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Configure Weston without desktop panels for authentic 640x480 fullscreen camera display
mkdir -p /etc/xdg/weston
cat << 'EOF' > /etc/xdg/weston/weston.ini
[core]
idle-time=0

[shell]
panel-position=none
locking=false
background-color=0xff000000
EOF

echo "[*] Starting 640x480 Virtual Framebuffer (Xvfb) + Weston + noVNC on port 6080..."
Xvfb :0 -screen 0 640x480x24 &
sleep 1
weston --backend=x11-backend.so -c /etc/xdg/weston/weston.ini --width=640 --height=480 --idle-time=0 &
sleep 2
x11vnc -display :0 -forever -shared -nopw -quiet &
websockify --web=/usr/share/novnc/ 6080 localhost:5900 &

echo "========================================================================"
echo " [+] ARMv7 Emulator Running! Open http://127.0.0.1:6080/vnc.html?autoconnect=true"
echo "========================================================================"

# Launch the real ARMv7 victory-gui binary inside the X1D rootfs
chroot "$X1D_ROOT" /usr/bin/env \
    XDG_RUNTIME_DIR=/tmp \
    WAYLAND_DISPLAY=wayland-0 \
    LD_PRELOAD=/usr/lib/libwayland-egl.so \
    LD_LIBRARY_PATH=/usr/lib:/lib:/usr/lib/arm-linux-gnueabihf:/lib/arm-linux-gnueabihf \
    LIBGL_ALWAYS_SOFTWARE=1 \
    QT_WAYLAND_DISABLE_WINDOWDECORATION=1 \
    /usr/bin/victory-gui -platform wayland-egl --wedge || true

# Keep container alive
tail -f /dev/null
