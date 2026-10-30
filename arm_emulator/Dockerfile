# Hasselblad X1D-50c Real ARMv7 (armhf) Firmware Runner
# Runs the actual unmodified ARMv7 ELF binaries (/usr/bin/configstore, /usr/bin/victory-gui)
# from the X1D-50c rootfs using QEMU armhf + Mesa Software OpenGL ES 2.0 (llvmpipe/swrast) + noVNC.

FROM --platform=linux/arm/v7 ubuntu:18.04

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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /emu
COPY mock_hardware_dbus.py /emu/mock_hardware_dbus.py
COPY entrypoint_arm.sh /emu/entrypoint_arm.sh
RUN chmod +x /emu/entrypoint_arm.sh /emu/mock_hardware_dbus.py

EXPOSE 6080 5900

ENTRYPOINT ["/emu/entrypoint_arm.sh"]
