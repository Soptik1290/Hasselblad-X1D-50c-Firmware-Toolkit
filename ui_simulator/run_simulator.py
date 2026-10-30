#!/usr/bin/env python3
"""
Hasselblad X1D-50c (v1.25.0) – Lokální PC UI Simulátor & QML/JS Inspektor
Spouští lokální server na http://127.0.0.1:8125, který přímo načítá rozbalené
QML/JS soubory, ikony a fonty ze složky ../victory_gui_qml/ a kontroluje
zlib velikosti pro in-place patchování do victory-gui.
"""

import argparse
import http.server
import json
import os
import socketserver
import sys
import webbrowser
import zlib
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
QML_DIR = BASE_DIR / "victory_gui_qml"
SIM_DIR = Path(__file__).resolve().parent

if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from verify_firmware_safety import run_preflight_sweep, compute_memory_and_slot_stats
from patch_victory_qrc_file import strip_qml_js_comments


def get_zlib_status():
    """Spočítá aktuální velikost klíčových QML/JS souborů v QRC slotu pro in-place patchování do victory-gui."""
    tracked = [
        ("settings/scripts/MenuItemSpecificationsWedge.js", 6052, 1),
        ("settings/SettingsGeneric.qml", 9968, 1),
        ("mainmenu/MainScreen.qml", 9128, 1),
        ("mainmenu/Menu.qml", 4583, 1),
        ("controlscreen/ControlScreen.qml", 8157, 1),
        ("common/TouchWindow.qml", 18120, 1),
        ("main.qml", 8676, 1),
        ("components/popups/PopoverFocusMode.qml", 1184, 1),
        ("scripts/KeyMapsWedge.js", 6684, 0),
        ("DemoState.qml", 86, 0),
        ("DemoMarker.qml", 346, 0),
    ]
    results = []
    for rel_path, slot_cap, flags in tracked:
        fp = QML_DIR / rel_path
        if fp.exists():
            raw = fp.read_bytes()
            stripped = strip_qml_js_comments(raw) if rel_path.endswith((".qml", ".js")) else raw
            if flags & 1:
                needed = 8 + len(zlib.compress(raw, 9))
                needed_stripped = 8 + len(zlib.compress(stripped, 9))
            else:
                needed = 4 + len(raw)
                needed_stripped = 4 + len(stripped)
            results.append({
                "file": rel_path,
                "compressed": bool(flags & 1),
                "raw_size": len(raw),
                "needed_bytes": needed,
                "needed_stripped_bytes": needed_stripped,
                "slot_capacity": slot_cap,
                "slack_bytes": slot_cap - needed,
                "slack_stripped_bytes": slot_cap - needed_stripped,
                "fits_in_slot": needed <= slot_cap or needed_stripped <= slot_cap,
            })
    return results


class X1DSimulatorHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Vypnutí cache, aby úpravy v victory_gui_qml/ byly okamžitě vidět po obnovení
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        super().end_headers()

    def do_GET(self):
        path = self.path.split("?")[0]

        if path == "/api/zlib-status":
            data = json.dumps(get_zlib_status(), ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return

        if path == "/api/memory-stats":
            data = json.dumps(compute_memory_and_slot_stats(), ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return

        if path == "/api/preflight-sweep":
            deep = "deep=1" in self.path
            data = json.dumps(run_preflight_sweep(fast_mode=not deep), ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return

        if path.startswith("/qml/"):
            rel = path[len("/qml/"):]
            target = (QML_DIR / rel).resolve()
            if target.is_file() and str(target).startswith(str(QML_DIR.resolve())):
                ext = target.suffix.lower()
                ctype = {
                    ".js": "application/javascript; charset=utf-8",
                    ".qml": "text/plain; charset=utf-8",
                    ".png": "image/png",
                    ".ttf": "font/ttf",
                }.get(ext, "application/octet-stream")
                content = target.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(content)))
                self.end_headers()
                self.wfile.write(content)
                return
            self.send_error(404, f"QML resource not found: {rel}")
            return

        # Výchozí servírování ze složky ui_simulator/
        if path == "/" or path == "":
            self.path = "/index.html"
        return super().do_GET()

    def translate_path(self, path):
        rel = path.split("?")[0].lstrip("/")
        return str((SIM_DIR / rel).resolve())

    def log_message(self, fmt, *args):
        # Tichý výpis pouze při chybách
        pass


def main():
    parser = argparse.ArgumentParser(description="Spustí lokální PC simulátor UI Hasselblad X1D-50c")
    parser.add_argument("--port", type=int, default=8125, help="Port lokálního HTTP serveru (výchozí: 8125)")
    parser.add_argument("--no-browser", action="store_true", help="Nespouštět automaticky webový prohlížeč")
    args = parser.parse_args()

    if not QML_DIR.exists():
        print(f"[!] Chyba: Složka {QML_DIR} neexistuje. Nejprve rozbal QRC zdroje pomocí extract_victory_qrc.py.")
        sys.exit(1)

    socketserver.TCPServer.allow_reuse_address = True
    url = f"http://127.0.0.1:{args.port}/"
    with socketserver.TCPServer(("127.0.0.1", args.port), X1DSimulatorHandler) as httpd:
        print("=" * 72)
        print("  Hasselblad X1D-50c (Wedge) – Lokální PC UI Simulátor & QML Inspektor")
        print("=" * 72)
        print(f"  [*] Načítám živé QML/JS a ikony ze složky: {QML_DIR}")
        print(f"  [*] Simulátor běží na adrese:              {url}")
        print("  [*] Ukončení:                              Stiskni Ctrl+C")
        print("=" * 72)

        if not args.no_browser:
            webbrowser.open(url)

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[*] Simulátor ukončen.")


if __name__ == "__main__":
    main()
