import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "start" as StartUI

Item {
    id: root
    property var shell: null
    property var manifest: null
    property alias catalog: appCatalog
    readonly property var appLibrary: shell ? shell.appLibrary : null
    StartUI.AppCatalog {
        id: appCatalog
        nativeLibrary: root.appLibrary
    }
    readonly property string sourceDirectory: decodeURIComponent(String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")).replace(/\/$/, "")
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"
    readonly property string cleanupPath: stateHome + "/omarchy-theme-eleven/cleanup.py"
    Component.onCompleted: {
        StartUI.Session.owner = root;
        StartUI.Session.library = appCatalog;
        apply.running = true;
    }
    Component.onDestruction: {
        if (StartUI.Session.owner === root) {
            StartUI.Session.library = null;
            StartUI.Session.owner = null;
        }
        Quickshell.execDetached(["python3", root.cleanupPath, "cleanup", root.sourceDirectory]);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && !shortcutSync.running)
                shortcutSync.running = true;
        }
    }
    Process {
        id: shortcutSync
        command: ["python3", root.sourceDirectory + "/scripts/lifecycle.py", "shortcuts"]
    }

    Process {
        id: apply
        command: ["python3", root.sourceDirectory + "/scripts/lifecycle.py", "activate", root.sourceDirectory]
        stdout: StdioCollector {
            id: result
        }
        onExited: function (code) {
            if (code !== 0) {
                console.error("Eleven activation failed:", result.text);
            }
        }
    }
}
