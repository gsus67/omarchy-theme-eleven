#!/usr/bin/env python3
"""Run only Start's UI, without loading the lifecycle service or changing theme."""
from pathlib import Path
import argparse
import json
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", type=Path, help="Render a PNG offscreen and exit")
    parser.add_argument("--power-menu", action="store_true", help="Show the inert power flyout for visual review")
    parser.add_argument("--dark", action="store_true", help="Preview the dark variant")
    args = parser.parse_args()
    native = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "shell"
    if not native.is_dir() or not shutil.which("quickshell"):
        parser.error("The preview requires an existing Omarchy/Quickshell installation")
    capture = str(args.capture.resolve()) if args.capture else ""
    if capture:
        args.capture.resolve().parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="eleven-preview-") as directory:
        base = Path(directory)
        for name in ("Commons", "Ui", "services"):
            (base / name).symlink_to(native / name, target_is_directory=True)
        (base / "plugin").symlink_to(ROOT, target_is_directory=True)
        qml = '''import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "services" as Services
import "plugin/start"

ShellRoot {
    id: root
    property string output: OUTPUT
    property bool powerPreview: POWER_PREVIEW
    property bool captured: false
    Component.onCompleted: {
        Session.mode = DARK_MODE ? "dark" : "light";
        // Compile the actual host entry points, without constructing their
        // side-effecting lifecycle service or layer-shell popup.
        for (var path of (root.output === "" ? ["plugin/start/Start.qml", "plugin/Lifecycle.qml"] : ["plugin/Lifecycle.qml"])) {
            var component = Qt.createComponent(Qt.resolvedUrl(path));
            if (component.status !== Component.Ready) {
                console.error(component.errorString());
                Qt.exit(1);
            }
        }
    }
    Services.AppLibrary { id: library }
    Window {
        id: window
        title: "Eleven — vista previa de Inicio"
        width: 640
        height: 726
        visible: true
        color: "#f9fbff"
        onClosing: Qt.quit()
        StartContent {
            id: menu
            anchors.fill: parent
            library: library
            userName: Quickshell.env("USER")
            suspendAvailable: root.powerPreview
            hibernateAvailable: root.powerPreview
            Component.onCompleted: reset()
            onCloseRequested: Qt.quit()
            onPinsRequested: function(ids) { requestedPins = ids; }
            onLaunchRequested: function(entry) { library.launch(entry.id, library.entryName(entry)); }
            onPlaceRequested: function(place) { console.log("Preview folder:", place); }
            onSystemActionRequested: function(action) { console.log("Preview session action (not executed):", action); }
            onSettingsRequested: console.log("Preview: settings actions are not executed")
        }
        FileView {
            path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy-taskbar/pinned.json"
            printErrors: false
            onLoaded: { try { menu.inheritedPins = JSON.parse(text()); } catch(error) {} }
        }
    }
    Timer {
        interval: 1100
        running: root.powerPreview
        onTriggered: menu.showPowerMenu()
    }
    Timer {
        interval: 1400
        running: root.output !== ""
        onTriggered: {
            if (menu.allEntries.length === 0) { console.error("Application library did not load"); Qt.exit(1); return; }
            window.contentItem.grabToImage(function(result) {
                var success = result.saveToFile(root.output);
                console.log("START_CAPTURE", success, menu.allEntries.length, "applications");
                Qt.exit(success ? 0 : 1);
            });
        }
    }
    Timer {
        interval: 10000
        running: root.output !== ""
        onTriggered: { console.error("Capture timed out"); Qt.exit(1); }
    }
}
'''.replace("OUTPUT", json.dumps(capture)).replace("POWER_PREVIEW", "true" if args.power_menu else "false").replace("DARK_MODE", "true" if args.dark else "false")
        (base / "shell.qml").write_text(qml)
        env = dict(os.environ, QT_QUICK_CONTROLS_STYLE="Basic")
        if capture:
            runtime = base / "runtime"
            runtime.mkdir(mode=0o700)
            env.update(QT_QPA_PLATFORM="offscreen", QT_QPA_PLATFORMTHEME="", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=str(runtime))
        result = subprocess.run(["quickshell", "--no-color", "-p", str(base)], env=env,
                                timeout=20 if capture else None)
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
