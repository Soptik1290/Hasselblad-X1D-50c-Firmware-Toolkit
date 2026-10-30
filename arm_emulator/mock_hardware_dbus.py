#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Hasselblad X1D-50c Mock Hardware D-Bus Daemon for ARMv7 Rootfs Emulation
========================================================================
Registers stub D-Bus services (`se.hasselblad.cambody`, `se.hasselblad.farm`,
`se.hasselblad.suc`, `se.hasselblad.storage`) on the system bus so that the
real ARMv7 `/usr/bin/victory-gui` and `/usr/bin/configstore` binaries can run
inside QEMU/Docker without physical FPGA (FARM) or MCU (SUC) hardware.
"""

import time
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib


class GenericHasselbladObject(dbus.service.Object):
    def __init__(self, bus, obj_path):
        super().__init__(bus, obj_path)

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v")
    def Get(self, interface_name, property_name):
        defaults = {
            "capabilities": dbus.UInt32(3),
            "lensVersion": dbus.String("0.5.3 (XCD 45mm)"),
            "SuSerial": dbus.String("US160107042"),
            "versionID": dbus.String("1.25.0"),
            "ram_only_mode": dbus.Int32(0),
            "wifiAvailable": dbus.Boolean(True),
        }
        return defaults.get(property_name, dbus.Int32(0))

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface_name):
        return {
            "capabilities": dbus.UInt32(3),
            "lensVersion": dbus.String("0.5.3 (XCD 45mm)"),
            "SuSerial": dbus.String("US160107042"),
            "versionID": dbus.String("1.25.0"),
            "ram_only_mode": dbus.Int32(0),
        }

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="ssv", out_signature="")
    def Set(self, interface_name, property_name, value):
        print(f"[mock-dbus] Set {interface_name}.{property_name} = {value}")


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    bus_names = []
    objects = []
    services = [
        ("com.hasselblad.cambody", "/cambody"),
        ("com.hasselblad.camera", "/"),
        ("com.hasselblad.lens", "/lens"),
        ("com.hasselblad.systemmanager", "/"),
        ("com.hasselblad.storage", "/"),
        ("com.hasselblad.power", "/power"),
        ("com.hasselblad.video", "/"),
        ("com.hasselblad.suc", "/suc"),
        ("com.hasselblad.farm", "/farm"),
        ("com.hasselblad.error", "/error"),
        ("com.hasselblad.upgrade", "/"),
        ("com.hasselblad.bodysync", "/bodysync"),
    ]
    for srv_name, obj_path in services:
        try:
            name = dbus.service.BusName(srv_name, bus)
            obj = GenericHasselbladObject(bus, obj_path)
            bus_names.append(name)
            objects.append(obj)
            print(f"[mock-dbus] Registered {srv_name} at {obj_path}")
        except Exception as exc:
            print(f"[mock-dbus] Warning registering {srv_name}: {exc}")

    loop = GLib.MainLoop()
    loop.run()


if __name__ == "__main__":
    main()
