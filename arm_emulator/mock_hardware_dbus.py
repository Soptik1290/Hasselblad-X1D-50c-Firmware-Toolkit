#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Hasselblad X1D-50c Mock Hardware D-Bus Daemon for ARMv7 Rootfs Emulation
========================================================================
Registers mock D-Bus services (`com.hasselblad.*`) on the system bus so that
the real ARMv7 `/usr/bin/victory-gui` and `/usr/bin/configstore` binaries run
inside QEMU/Docker with fully populated camera parameters:
- Shutter speed, Aperture, ISO, White Balance
- Battery level, Storage card remaining exposures
- Camera body state and lens metadata
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib


class HasselbladService(dbus.service.Object):
    def __init__(self, srv_name, obj_path, default_props=None):
        self.conn = dbus.bus.BusConnection(dbus.Bus.TYPE_SYSTEM)
        self.bus_name = dbus.service.BusName(srv_name, self.conn)
        super().__init__(self.conn, obj_path)
        self.srv_name = srv_name
        self.obj_path = obj_path
        self.props = default_props or {}

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v")
    def Get(self, interface_name, property_name):
        val = self.props.get(property_name)
        if val is None:
            # Fallback for unknown properties
            val = dbus.Int32(0)
        return val

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface_name):
        return self.props

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ssv", out_signature="")
    def Set(self, interface_name, property_name, value):
        print(f"[{self.srv_name}] Set {property_name} = {value}")
        self.props[property_name] = value
        self.PropertiesChanged(interface_name, {property_name: value}, [])

    @dbus.service.signal("org.freedesktop.DBus.Properties", signature="sa{sv}as")
    def PropertiesChanged(self, interface_name, changed_properties, invalidated_properties):
        pass

    # Generic method fallbacks called by victory-gui / libappscommon
    @dbus.service.method("com.hasselblad.camera", in_signature="b", out_signature="")
    def setLiveViewState(self, state):
        print(f"[{self.srv_name}] setLiveViewState({state})")
        self.props["liveViewState"] = dbus.Boolean(state)

    @dbus.service.method("com.hasselblad.camera", in_signature="u", out_signature="")
    def setIso(self, iso):
        print(f"[{self.srv_name}] setIso({iso})")
        self.props["iso"] = dbus.UInt32(iso)

    @dbus.service.method("com.hasselblad.video", in_signature="bsi", out_signature="")
    def setVideoPlaybackState(self, active, filename, pos):
        print(f"[{self.srv_name}] setVideoPlaybackState({active}, {filename}, {pos})")

    @dbus.service.method("org.freedesktop.systemd1.Manager", in_signature="ss", out_signature="o")
    def StartUnit(self, name, mode):
        print(f"[{self.srv_name}] StartUnit({name}, {mode})")
        return dbus.ObjectPath("/org/freedesktop/systemd1/job/1")

    @dbus.service.method("org.freedesktop.systemd1.Manager", in_signature="ss", out_signature="o")
    def StopUnit(self, name, mode):
        print(f"[{self.srv_name}] StopUnit({name}, {mode})")
        return dbus.ObjectPath("/org/freedesktop/systemd1/job/2")


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    services_config = [
        # 1. Camera service (exposure modes, ISO, AF, drive, WB)
        (
            "com.hasselblad.camera",
            "/",
            {
                "canShow": dbus.UInt32(0xFFFFFFFF),
                "canChange": dbus.UInt32(0xFFFFFFFF),
                "iso": dbus.UInt32(100),
                "WBMode": dbus.Int32(2),       # Daylight
                "FocusMode": dbus.Int32(0),    # AF-S Single
                "DriveMode": dbus.Int32(0),    # Single
                "LMMode": dbus.Int32(0),       # Center-weighted
                "EVADJ": dbus.Int32(0),
                "FLASH_EVADJ": dbus.Int32(0),
                "inSession": dbus.Boolean(False),
                "exposing": dbus.Boolean(False),
            },
        ),
        # 2. Camera body service (aperture, shutter speed, battery)
        (
            "com.hasselblad.cambody",
            "/cambody",
            {
                "aperture": dbus.String("2.8"),
                "shutterSpeed": dbus.String("1/125"),
                "autoIso": dbus.String("100"),
                "AV": dbus.Int32(36),          # f/2.8
                "TV": dbus.Int32(84),          # 1/125s
                "AV_out_of_range": dbus.Boolean(False),
                "TV_out_of_range": dbus.Boolean(False),
                "capabilities": dbus.UInt32(0xFFFFFFFD),  # Disable on-screen touch shutter to keep f/2.8 clean
                "ExpModeList": dbus.UInt32(0xFF),
                "LMModeListAsInt": dbus.UInt32(0xFF),
                "current_body_mode": dbus.Int32(0),
                "AEL": dbus.Boolean(False),
                "isBMode": dbus.Boolean(False),
                "isTMode": dbus.Boolean(False),
                "batteryLevel": dbus.Int32(95),
            },
        ),
        # 3. Storage service (SD Card 1 inserted, 1420 shots remaining)
        (
            "com.hasselblad.storage",
            "/",
            {
                "card0Status": dbus.Int32(1),   # STORAGE_ACTIVE
                "card1Status": dbus.Int32(0),   # STORAGE_ABSENT
                "exposuresLeft": dbus.Int32(1420),
                "isFormatting": dbus.Boolean(False),
                "storage_state": dbus.Int32(0),
            },
        ),
        # 4. System manager (battery status, power, system health)
        (
            "com.hasselblad.systemmanager",
            "/",
            {
                "batteryStatus": dbus.Int32(0), # BatteryNormal
                "batteryLevel": dbus.Int32(95),
                "camera_mode": dbus.Int32(0),   # CameraModePhoto
                "system_state": dbus.Int32(0),  # StateNormal
                "isTethered": dbus.Boolean(False),
            },
        ),
        # 5. Lens metadata (XCD 45mm F/2.8)
        (
            "com.hasselblad.lens",
            "/lens",
            {
                "lensVersion": dbus.String("0.5.3 (XCD 45mm)"),
                "focalLength": dbus.Int32(45),
                "maxAperture": dbus.String("2.8"),
                "capabilities": dbus.UInt32(0xFFFFFFFD),  # Disable on-screen touch shutter to keep f/2.8 clean
            },
        ),
        # 6. SUC MCU controller
        (
            "com.hasselblad.suc",
            "/suc",
            {
                "usbChargeLevel": dbus.Int32(0),
                "ext_power": dbus.Boolean(False),
                "SuSerial": dbus.String("US160107042"),
                "versionID": dbus.String("1.25.0"),
            },
        ),
        # 7. Video controller
        (
            "com.hasselblad.video",
            "/",
            {
                "videoMode": dbus.Int32(0),
                "isRecording": dbus.Boolean(False),
                "playbackState": dbus.Int32(0),
            },
        ),
        # 8. Body sync & focus surface
        (
            "com.hasselblad.bodysync",
            "/bodysync",
            {
                "focusSurface": dbus.String("main"),
                "currentState": dbus.Int32(0),
            },
        ),
        # 9. Power controller
        (
            "com.hasselblad.power",
            "/power",
            {
                "powerState": dbus.Int32(1),
                "batteryLevel": dbus.Int32(95),
            },
        ),
        # 10. FPGA FARM daemon
        (
            "com.hasselblad.farm",
            "/farm",
            {
                "capabilities": dbus.UInt32(3),
                "ram_only_mode": dbus.Int32(0),
            },
        ),
        # 11. Error subsystem
        (
            "com.hasselblad.error",
            "/error",
            {
                "code": dbus.Int32(0),
                "active": dbus.Boolean(False),
            },
        ),
        # 12. Upgrade daemon
        (
            "com.hasselblad.upgrade",
            "/",
            {
                "isProcessing": dbus.Boolean(False),
                "recommendedUpgrades": dbus.Array([], signature="s"),
            },
        ),
        # 13. Mock systemd1 Manager so onStartUnitFinished doesn't complain
        (
            "org.freedesktop.systemd1",
            "/org/freedesktop/systemd1",
            {},
        ),
    ]

    objects = []
    for srv_name, obj_path, default_props in services_config:
        try:
            srv_obj = HasselbladService(srv_name, obj_path, default_props)
            objects.append(srv_obj)
            print(f"[mock-dbus] Successfully registered {srv_name} at {obj_path}")
        except Exception as exc:
            print(f"[mock-dbus] Error registering {srv_name}: {exc}")

    loop = GLib.MainLoop()
    loop.run()


if __name__ == "__main__":
    main()
