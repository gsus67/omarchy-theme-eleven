import QtQuick
import QtQuick.Window
import Quickshell
import "." as Local

Item {
    id: root
    readonly property string pluginId: "io.github.gsus67.omarchy-theme-eleven"
    property var shell: null
    property bool closingFromHost: false
    property bool initializedGeometry: false
    property bool needsInitialPlacement: false

    function open(payloadJson) {
        var view = "start"
        try {
            let payload = JSON.parse(String(payloadJson || "{}"))
            if (payload && payload.view === "settings") view = "settings"
        } catch (error) {
        }

        if (view === "settings") {
            if (!initializedGeometry) {
                window.width = 1080
                window.height = 840
                initializedGeometry = true
                needsInitialPlacement = true
            }
            window.visible = true
            window.minimized = false
            floatWindowTimer.restart()
        } else {
            Quickshell.execDetached(["omarchy-shell", "eleven-start", "open"])
        }
    }

    function close() {
        closingFromHost = true
        window.visible = false
        closingFromHost = false
    }

    function requestClose() {
        if (shell && typeof shell.hide === "function") shell.hide(pluginId)
        else window.visible = false
    }

    function runSettingsRoute(route) {
        var home = Quickshell.env("HOME")
        var commands = {
            "config.monitors": ["omarchy-launch-config-editor", home + "/.config/hypr/monitors.lua"],
            "config.input": ["omarchy-launch-config-editor", home + "/.config/hypr/input.lua"],
            "config.bindings": ["omarchy-launch-config-editor", home + "/.config/hypr/bindings.lua"],
            "config.hyprland": ["omarchy-launch-config-editor", home + "/.config/hypr/hyprland.lua"],
            "config.ssh": ["omarchy-launch-config-editor", home + "/.ssh/config"],
            "about": ["omarchy-launch-about"],
            "style.theme": ["bash", "-lc", "theme=$(omarchy-theme-switcher); [[ -n $theme ]] && omarchy-theme-set \"$theme\""],
            "style.background": ["bash", "-lc", "background=$(omarchy-theme-bg-switcher); [[ -n $background ]] && omarchy-theme-bg-set \"$background\""],
            "style.bar": ["omarchy-launch-config-editor", home + "/.config/omarchy/shell.json"],
            "style.screensaver": ["omarchy-branding-screensaver", "text"],
            "apps.defaults": ["omarchy-launch-config-editor", home + "/.config/xdg-terminals.list"]
        }
        if (commands[route]) Quickshell.execDetached(commands[route])
    }

    Timer {
        id: floatWindowTimer
        interval: 150
        repeat: false
        onTriggered: {
            var selector = "title:" + window.title
            console.info("Eleven Settings: floating window", selector)
            Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.window.float({action="set",window="' + selector + '"})'])
            if (root.needsInitialPlacement) sizeWindowTimer.start()
        }
    }

    Timer {
        id: sizeWindowTimer
        interval: 100
        repeat: false
        onTriggered: {
            var selector = "title:" + window.title
            Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.window.resize({x=1080,y=840,window="' + selector + '"})'])
            Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.window.center({window="' + selector + '"})'])
            root.needsInitialPlacement = false
        }
    }

    FloatingWindow {
        id: window
        title: Qt.locale().name.indexOf("es") === 0 ? "Configuración" : "Settings"
        color: Local.Appearance.color("#f4f7fa")
        visible: false
        implicitWidth: 1080
        implicitHeight: 840
        minimumSize: Qt.size(880, 620)

        onVisibleChanged: {
            if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
                root.shell.hide(root.pluginId)
        }

        Local.SettingsContent {
            anchors.fill: parent
            userName: Quickshell.env("USER")
            deviceName: Quickshell.env("HOSTNAME")
            onCloseRequested: root.requestClose()
            onBackRequested: {
                root.requestClose()
                Quickshell.execDetached(["omarchy-shell", "eleven-start", "open"])
            }
            onMinimizeRequested: window.minimized = true
            onMaximizeRequested: window.maximized = !window.maximized
            onOpenRequested: function(kind, route) {
                if (kind === "panel")
                    Quickshell.execDetached(["omarchy-shell", "shell", "summon", route, "{}"])
                else if (kind === "command")
                    root.runSettingsRoute(route)
                else
                    Quickshell.execDetached(["omarchy-shell", "shell", "summon", "omarchy.menu", JSON.stringify({ menu: route })])
            }
        }
    }
}
