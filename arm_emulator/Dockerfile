# Hasselblad X1D-50c Real ARMv7 (armhf) Firmware Runner
# Runs the actual unmodified ARMv7 ELF binaries (/usr/bin/configstore, /usr/bin/victory-gui)
# from the X1D-50c rootfs using QEMU armhf + Mesa Software OpenGL ES 2.0 (llvmpipe/swrast) + noVNC.

FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    bzip2 \
    tar \
    dbus \
    dbus-x11 \
    python3 \
    python3-dbus \
    python3-gi \
    weston \
    xvfb \
    x11vnc \
    scrot \
    xdotool \
    novnc \
    websockify \
    libegl1-mesa \
    libgles2-mesa \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libgbm1 \
    libwayland-egl1-mesa \
    procps \
    iproute2 \
    gcc \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /emu
RUN mkdir -p /emu/compat
COPY mock_hardware_dbus.py /emu/mock_hardware_dbus.py
COPY entrypoint_arm.sh /emu/entrypoint_arm.sh
COPY patch_libm.py /emu/patch_libm.py
COPY libxshmfence_compat.c /emu/libxshmfence_compat.c
COPY libbsd_compat.c /emu/libbsd_compat.c

# Compile GLIBC 2.4-compatible shims for Yocto chroot into /emu/compat
RUN gcc -shared -fPIC -O2 /emu/libxshmfence_compat.c -Wl,-soname,libxshmfence.so.1 -o /emu/compat/libxshmfence.so.1 \
    && gcc -shared -fPIC -O2 /emu/libbsd_compat.c -Wl,-soname,libbsd.so.0 -o /emu/compat/libbsd.so.0 \
    && chmod +x /emu/entrypoint_arm.sh /emu/mock_hardware_dbus.py /emu/patch_libm.py

EXPOSE 6080 5900

ENTRYPOINT ["/emu/entrypoint_arm.sh"]
