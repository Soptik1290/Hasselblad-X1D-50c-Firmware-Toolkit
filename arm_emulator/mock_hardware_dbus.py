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

import math
import time
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib


SERVICES_BY_NAME = {}


class OpticalCdafSimulator:
    """
    Simulates the FPGA Brenner Contrast Filter (`../src/fpga/autofocus.c`)
    and a moving 3D subject focal plane for testing Gated CDAF & Peak Drop Rate
    tracking (`../src/services/af_service.c` / `Lens.moveRelativePos4um`).
    """

    def __init__(self):
        self.lens_pos = 1000
        self.subject_pos = 1000.0
        self.session_start_t = time.monotonic()
        self.last_cv = 24000
        self.step_idx = 0

    def reset_lock(self):
        self.lens_pos = 1000
        self.subject_pos = 1000.0
        self.session_start_t = time.monotonic()
        self.last_cv = 24000
        self.step_idx = 0

    def update_subject_position(self) -> float:
        elapsed = time.monotonic() - self.session_start_t
        if elapsed < 0.30:
            # Initial stationary gate window: subject stays still at 1000
            self.subject_pos = 1000.0
        else:
            # Smooth continuous movement between Near (930) and Far (1090)
            phase = (elapsed - 0.30) * 1.35
            self.subject_pos = 1010.0 + 75.0 * math.sin(phase)
        return self.subject_pos

    def compute_cv(self, pos: int, subj: float) -> int:
        # Lorentzian / Brenner contrast response around subject focal plane
        # Half-width at half-maximum sigma_dof = 42 steps (168 um)
        delta = float(pos) - subj
        cv = 1800.0 + 22200.0 / (1.0 + (delta / 42.0) ** 2)
        return max(1000, min(65000, int(round(cv))))

    def step_relative_4um(self, rel_step: int) -> int:
        subj = self.update_subject_position()
        self.lens_pos = max(200, min(2800, self.lens_pos + int(rel_step)))
        cv = self.compute_cv(self.lens_pos, subj)
        der = (cv - self.last_cv) / float(max(1, abs(rel_step))) if rel_step != 0 else 0.0
        self.last_cv = cv
        self.step_idx += 1
        print(
            f"[FARM-CDAF] Pos = {self.lens_pos} SubjPos = {subj:.1f} CV = {cv} "
            f"Step = {rel_step:+d} Der = {der:+.2f} idx = {self.step_idx}"
        )
        # Pack (cv16 << 15) | (pos15 & 0x7FFF) into positive 31-bit signed int32
        return ((cv & 0xFFFF) << 15) | (self.lens_pos & 0x7FFF)


CDAF_SIM = OpticalCdafSimulator()


class HasselbladService(dbus.service.Object):
    def __init__(self, srv_name, obj_path, default_props=None):
        existing = SERVICES_BY_NAME.get(srv_name)
        if existing is not None:
            self.conn = existing.conn
            self.bus_name = existing.bus_name
        else:
            self.conn = dbus.bus.BusConnection(dbus.Bus.TYPE_SYSTEM)
            self.bus_name = dbus.service.BusName(srv_name, self.conn)
            SERVICES_BY_NAME[srv_name] = self
        super().__init__(self.conn, obj_path)
        self.srv_name = srv_name
        self.obj_path = obj_path
        self.props = default_props or {}

    def update_prop(self, iface, key, val):
        self.props[key] = val
        self.PropertiesChanged(iface, {key: val}, [])

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

    # Camera methods called by victory-gui / libappscommon
    @dbus.service.method("com.hasselblad.camera", in_signature="bs", out_signature="")
    def setLiveViewState(self, state, receiver):
        print(f"[{self.srv_name}] setLiveViewState({bool(state)}, '{receiver}')")
        self.props["liveViewState"] = dbus.Boolean(state)
        vid = SERVICES_BY_NAME.get("com.hasselblad.video")
        if vid is not None:
            vid.update_prop("com.hasselblad.video", "videoMode", dbus.Int32(1 if state else 0))

    @dbus.service.method("com.hasselblad.camera", in_signature="bb", out_signature="")
    def SetShowLiveViewWhenFinished(self, after_exp, after_non_exp):
        self.props["showLiveViewWhenFinished"] = dbus.Boolean(after_exp or after_non_exp)

    @dbus.service.method("com.hasselblad.camera", in_signature="bb", out_signature="")
    def StartSession(self, show_lv, force_af):
        fmode = int(self.props.get("FocusMode", 1))
        print(f"[{self.srv_name}] StartSession(showLV={bool(show_lv)}, forceAF={bool(force_af)}, FocusMode={fmode})")
        if show_lv:
            vid = SERVICES_BY_NAME.get("com.hasselblad.video")
            if vid is not None and int(vid.props.get("videoMode", 0)) == 0:
                vid.update_prop("com.hasselblad.video", "videoMode", dbus.Int32(1))
        self.update_prop("com.hasselblad.camera", "inSession", dbus.Boolean(True))
        if fmode != 3 or force_af:
            self.update_prop("com.hasselblad.camera", "findingFocus", dbus.Boolean(True))

            def _finish_af():
                if bool(self.props.get("inSession", False)):
                    CDAF_SIM.reset_lock()
                    self.props["lastAfReturnStatus"] = dbus.UInt32(0)
                    self.props["lastAfResult"] = dbus.UInt32(1)
                    self.props["findingFocus"] = dbus.Boolean(False)
                    self.PropertiesChanged(
                        "com.hasselblad.camera",
                        {
                            "lastAfReturnStatus": dbus.UInt32(0),
                            "lastAfResult": dbus.UInt32(1),
                            "findingFocus": dbus.Boolean(False),
                        },
                        [],
                    )
                return False

            GLib.timeout_add(160, _finish_af)

    @dbus.service.method("com.hasselblad.camera", in_signature="", out_signature="")
    def StopSession(self):
        print(f"[{self.srv_name}] StopSession()")
        self.props["findingFocus"] = dbus.Boolean(False)
        self.props["inSession"] = dbus.Boolean(False)
        self.PropertiesChanged(
            "com.hasselblad.camera",
            {"findingFocus": dbus.Boolean(False), "inSession": dbus.Boolean(False)},
            [],
        )

    @dbus.service.method("com.hasselblad.camera", in_signature="b", out_signature="")
    def StartExposing(self, liveview_after):
        print(f"[{self.srv_name}] StartExposing(liveviewAfter={bool(liveview_after)})")
        self.update_prop("com.hasselblad.camera", "Exposing", dbus.Boolean(True))

        def _finish_exp():
            self.update_prop("com.hasselblad.camera", "Exposing", dbus.Boolean(False))
            self.update_prop("com.hasselblad.camera", "inSession", dbus.Boolean(False))
            return False

        GLib.timeout_add(120, _finish_exp)

    @dbus.service.method("com.hasselblad.camera", in_signature="", out_signature="")
    def StopExposing(self):
        print(f"[{self.srv_name}] StopExposing()")
        self.update_prop("com.hasselblad.camera", "Exposing", dbus.Boolean(False))

    @dbus.service.method("com.hasselblad.camera", in_signature="", out_signature="")
    def FinishExposure(self):
        self.update_prop("com.hasselblad.camera", "Exposing", dbus.Boolean(False))

    @dbus.service.method("com.hasselblad.camera", in_signature="b", out_signature="uu")
    def FindFocus(self, show_video):
        return (dbus.UInt32(0), dbus.UInt32(1))

    @dbus.service.method("com.hasselblad.camera", in_signature="", out_signature="")
    def StopFindFocus(self):
        self.update_prop("com.hasselblad.camera", "findingFocus", dbus.Boolean(False))

    @dbus.service.method("com.hasselblad.camera", in_signature="u", out_signature="")
    def setIso(self, iso):
        print(f"[{self.srv_name}] setIso({iso})")
        self.props["iso"] = dbus.UInt32(iso)

    @dbus.service.method("com.hasselblad.video", in_signature="bsi", out_signature="")
    def setVideoPlaybackState(self, active, filename, pos):
        print(f"[{self.srv_name}] setVideoPlaybackState({active}, {filename}, {pos})")

    @dbus.service.method("com.hasselblad.cambody", in_signature="b", out_signature="")
    def do_hts_polling(self, enable):
        print(f"[{self.srv_name}] do_hts_polling({bool(enable)})")

    @dbus.service.method("com.hasselblad.spiritlevel", in_signature="ib", out_signature="")
    def do_spiritlevel(self, mode, enable):
        print(f"[{self.srv_name}] do_spiritlevel(mode={int(mode)}, enable={bool(enable)})")

    # Lens CDAF & Micro-stepping methods (com.hasselblad.lens -> LensProxy in libappscommon.so)
    @dbus.service.method("com.hasselblad.lens", in_signature="b", out_signature="i")
    def video_focus_pos_state(self, enabled):
        print(f"[{self.srv_name}] video_focus_pos_state({bool(enabled)})")
        return dbus.Int32(0)

    @dbus.service.method("com.hasselblad.lens", in_signature="i", out_signature="i")
    def af_cmd_relative_position_4um(self, relative_pos):
        packed = CDAF_SIM.step_relative_4um(int(relative_pos))
        self.props["video_focus_pos"] = dbus.Int32(CDAF_SIM.lens_pos)
        return dbus.Int32(packed)

    @dbus.service.method("com.hasselblad.lens", in_signature="i", out_signature="i")
    def af_cmd_position(self, pos):
        CDAF_SIM.lens_pos = max(200, min(2800, int(pos)))
        self.props["video_focus_pos"] = dbus.Int32(CDAF_SIM.lens_pos)
        print(f"[{self.srv_name}] af_cmd_position(targetPos={CDAF_SIM.lens_pos})")
        return dbus.Int32(0)

    @dbus.service.method("com.hasselblad.lens", in_signature="i", out_signature="i")
    def af_cmd_speed(self, speed):
        print(f"[{self.srv_name}] af_cmd_speed(speed={int(speed)})")
        return dbus.Int32(0)

    @dbus.service.method("com.hasselblad.lens", in_signature="i", out_signature="i")
    def af_cmd_scan_request(self, scan_type):
        print(f"[{self.srv_name}] af_cmd_scan_request(type={int(scan_type)})")
        return dbus.Int32(0)

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
                "SV": dbus.Int32(18),
                "WBMode": dbus.Int32(2),       # Daylight
                "FocusMode": dbus.Int32(1),    # Config.Focus_AFS (1)
                "DriveMode": dbus.Int32(1),    # Config.Drive_SINGLE (1)
                "LMMode": dbus.Int32(1),       # Config.LM_CENTER (1)
                "EVADJ": dbus.Int32(0),
                "FLASH_EVADJ": dbus.Int32(0),
                "AEB_EVADJ": dbus.Int32(0),
                "focus_point": dbus.UInt32((1920 << 16) | 1440),
                "focus_size": dbus.UInt32(0),
                "findingFocus": dbus.Boolean(False),
                "lastAfResult": dbus.UInt32(1),
                "lastAfReturnStatus": dbus.UInt32(0),
                "inSession": dbus.Boolean(False),
                "Exposing": dbus.Boolean(False),
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
        (
            "com.hasselblad.cambody",
            "/spiritlevel",
            {
                "roll": dbus.Int32(0),
                "pitch": dbus.Int32(0),
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
                "FL": dbus.Int32(45),
                "fl_eff_min": dbus.Int32(45),
                "fl_eff_max": dbus.Int32(45),
                "lens_family": dbus.Int32(3),  # Lens.XCLens (3)
                "video_focus_pos": dbus.Int32(1000),
                "has_divided_scan_range": dbus.Boolean(False),
                "HasMicrofocusAdjust": dbus.Boolean(True),
                "HasLongFocusTime": dbus.Boolean(False),
                "lens_ring_rotation": dbus.Boolean(False),
                "AV_max": dbus.Int32(36),
                "AV_min": dbus.Int32(96),
                "TV_max": dbus.Int32(128),
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
