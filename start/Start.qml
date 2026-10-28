import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "." as Local

Panel {
    id: root
    moduleName: "io.github.gsus67.omarchy-theme-eleven"
    ipcTarget: "eleven-start"
    manageIpc: false
    readonly property var shell: bar ? bar.shell : null
    readonly property var ownService: shell && shell.serviceFor ? shell.serviceFor(root.moduleName) : null
    readonly property var library: (ownService ? ownService.catalog : null) || Local.Session.library || (shell ? shell.appLibrary : null)
    property var inheritedPins: []
    property var savedPins: null
    property var powerOptions: ({
            suspend: false,
            hibernate: false
        })
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    implicitWidth: startButton.implicitWidth
    implicitHeight: startButton.implicitHeight

    IpcHandler {
        target: root.ipcTarget
        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function status(): string {
            return JSON.stringify({
                open: root.opened,
                mode: Local.Session.mode,
                libraryReady: root.library !== null,
                applications: root.library ? root.library.sortedEntries("").length : 0,
                contentLoaded: content.item !== null,
                buttonWidth: startButton.width,
                buttonHeight: startButton.height,
                sessionOwnerReady: !!Local.Session.owner,
                serviceReady: !!root.ownService,
                serviceLibraryReady: !!(root.ownService && root.ownService.appLibrary),
                barApiReady: !!root.shell,
                barApiId: root.shell ? String(root.shell.pluginId) : ""
            });
        }
    }

    FileView {
        path: decodeURIComponent(String(Qt.resolvedUrl("../.eleven/preferences.json")).replace(/^file:\/\//, ""))
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.savedPins = JSON.parse(text()).pinnedApps;
            } catch (error) {
                root.savedPins = null;
            }
        }
    }

    FileView {
        path: root.configHome + "/omarchy-taskbar/pinned.json"
        printErrors: false
        // Read only. Start's choices never modify Taskbar's pins.
        onLoaded: {
            try {
                var data = JSON.parse(text());
                root.inheritedPins = Array.isArray(data) ? data : [];
            } catch (error) {
                root.inheritedPins = [];
            }
        }
    }
    onOpenedChanged: if (opened) {
        if (!powerProbe.running)
            powerProbe.running = true;
        if (library)
            library.refreshIcons();
        Qt.callLater(function () {
            if (content.item)
                content.item.reset();
        });
    }

    Process {
        id: powerProbe
        command: ["python3", decodeURIComponent(String(Qt.resolvedUrl("../scripts/lifecycle.py")).replace(/^file:\/\//, "")), "power-options"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.powerOptions = JSON.parse(text);
                } catch (error) {
                    root.powerOptions = ({
                            suspend: false,
                            hibernate: false
                        });
                }
            }
        }
    }

    WidgetButton {
        id: startButton
        objectName: "elevenStartButton"
        anchors.fill: parent
        bar: root.bar
        // Keep Omarchy's glyph with a larger Windows-like button footprint.
        text: "\ue900"
        fontFamily: "omarchy"
        foreground: "#0078d4"
        fontSize: Math.min(28, Math.max(16, barSize - 12))
        fixedWidth: vertical ? barSize : Math.max(44, barSize)
        fixedHeight: vertical ? Math.max(44, barSize) : barSize
        horizontalMargin: 7.5
        tooltipText: Qt.locale().name.indexOf("es") === 0 ? "Inicio" : "Start"
        onPressed: function (button) {
            if (button === Qt.RightButton)
                Quickshell.execDetached(["xdg-terminal-exec"]);
            else if (button === Qt.LeftButton)
                root.toggle();
        }
    }

    KeyboardPanel {
        id: popup
        anchorItem: startButton
        owner: root
        bar: root.bar
        open: root.opened
        padding: 0
        contentWidth: fittedContentWidth(640)
        contentHeight: fittedContentHeight(726)
        focusTarget: content.item

        Loader {
            id: content
            anchors.fill: parent
            active: root.opened || popup.visible
            onLoaded: if (root.opened)
                item.reset()
            sourceComponent: StartContent {
                library: root.library
                inheritedPins: root.inheritedPins
                requestedPins: root.savedPins
                suspendAvailable: root.powerOptions.suspend === true
                hibernateAvailable: root.powerOptions.hibernate === true
                userName: Quickshell.env("USER")
                onCloseRequested: root.close()
                onLaunchRequested: function (entry) {
                    if (!root.library || !entry)
                        return;
                    root.library.launch(entry.id, root.library.entryName(entry));
                    root.close();
                }
                onPinsRequested: function (ids) {
                    root.savedPins = ids;
                    Quickshell.execDetached(["python3", decodeURIComponent(String(Qt.resolvedUrl("../scripts/lifecycle.py")).replace(/^file:\/\//, "")), "pins", JSON.stringify(ids)]);
                }
                onPlaceRequested: function (place) {
                    var location = place === "documents" ? StandardPaths.DocumentsLocation : place === "downloads" ? StandardPaths.DownloadLocation : StandardPaths.HomeLocation;
                    var path = StandardPaths.writableLocation(location);
                    if (path)
                        Quickshell.execDetached(["gio", "open", String(path)]);
                    root.close();
                }
                onSystemActionRequested: function (action) {
                    var commands = {
                        screensaver: ["omarchy", "launch", "screensaver", "force"],
                        lock: ["omarchy", "system", "lock"],
                        suspend: ["systemctl", "suspend"],
                        hibernate: ["systemctl", "hibernate"],
                        logout: ["omarchy", "system", "logout"],
                        reboot: ["omarchy", "system", "reboot"],
                        shutdown: ["omarchy", "system", "shutdown"]
                    };
                    if (!Object.prototype.hasOwnProperty.call(commands, action))
                        return;
                    root.close();
                    Quickshell.execDetached(commands[action]);
                }
                onSettingsRequested: {
                    root.close();
                    Quickshell.execDetached(["omarchy-shell", "shell", "summon", "omarchy.menu", '{"menu":"setup"}']);
                }
            }
        }
    }
}
