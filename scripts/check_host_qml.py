#!/usr/bin/env python3
"""Compile entry points against installed Omarchy; construct no plugin objects."""
from pathlib import Path
import os
import json
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    native = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "shell"
    display = os.environ.get("WAYLAND_DISPLAY", "")
    if not display:
        raise SystemExit("A running Wayland session is needed to load the PanelWindow backend")
    if not display.startswith("/"):
        display = str(Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / display)
    with tempfile.TemporaryDirectory(prefix="eleven-compile-") as directory:
        base = Path(directory)
        for name in ("Commons", "Ui", "services"):
            (base / name).symlink_to(native / name, target_is_directory=True)
        (base / "plugin").symlink_to(ROOT, target_is_directory=True)
        (base / "runtime").mkdir(mode=0o700)
        (base / "shell.qml").write_text('''import QtQuick
import Quickshell
ShellRoot {
    id: root
    property var widget: null
    property var catalog: null
    Timer {
        interval: 25
        running: true
        onTriggered: {
            for (var path of ENTRYPOINTS) {
                var component = Qt.createComponent(Qt.resolvedUrl(path));
                if (component.status !== Component.Ready) {
                    console.error(component.errorString());
                    Qt.exit(1);
                    return;
                }
            }
            var start = Qt.createComponent(ENTRYPOINTS[0]);
            root.widget = start.createObject(null);
            if (!root.widget || root.widget.implicitWidth <= 0 || root.widget.implicitHeight <= 0) {
                console.error("Start must occupy a visible, clickable bar slot");
                Qt.exit(1);
                return;
            }
            console.log("ELEVEN_START_SIZE", root.widget.implicitWidth, root.widget.implicitHeight);
            root.widget.destroy();
            var catalogComponent = Qt.createComponent(CATALOG_ENTRY_URL);
            root.catalog = catalogComponent.createObject(null);
            if (!root.catalog) { console.error(catalogComponent.errorString()); Qt.exit(1); return; }
            verifyCatalog.start();
        }
    }
    Timer {
        id: verifyCatalog
        interval: 800
        onTriggered: {
            if (root.catalog.sortedEntries("").length === 0) {
                console.error("Catalog must remain available without a scoped facade");
                Qt.exit(1);
                return;
            }
            console.log("ELEVEN_CATALOG_FALLBACK_OK", root.catalog.sortedEntries("").length);
            root.catalog.destroy();
            console.log("ELEVEN_HOST_COMPILE_OK");
            Qt.quit();
        }
    }
}
'''.replace('ENTRYPOINTS', json.dumps([(ROOT / 'start/Start.qml').as_uri(), (ROOT / 'Lifecycle.qml').as_uri(), (ROOT / 'start/MenuBridge.qml').as_uri()])).replace('CATALOG_ENTRY_URL', json.dumps((ROOT / 'start/AppCatalog.qml').as_uri())))
        env = dict(os.environ, QT_QPA_PLATFORM="wayland", WAYLAND_DISPLAY=display,
                   XDG_RUNTIME_DIR=str(base / "runtime"), QT_QUICK_CONTROLS_STYLE="Basic")
        result = subprocess.run(["quickshell", "--no-color", "-p", str(base)], env=env,
                                text=True, capture_output=True, timeout=15)
        if result.returncode or "ELEVEN_HOST_COMPILE_OK" not in result.stdout + result.stderr:
            raise SystemExit(result.stdout + result.stderr)
        print("OK: entry points compile and Start has nonzero bar dimensions; lifecycle was not instantiated")


if __name__ == "__main__":
    main()
