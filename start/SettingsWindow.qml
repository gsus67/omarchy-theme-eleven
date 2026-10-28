import QtQuick
import QtQuick.Window
import Quickshell
import "." as Local

Item {
    id: root
    readonly property string pluginId: "io.github.gsus67.omarchy-theme-eleven"
    property var shell: null
    property var targetScreen: null
    property bool returningToStart: false

    readonly property bool windowVisible: window.visible

    function openFor(screen) {
        targetScreen = screen
        window.minimized = false
        window.visible = true
        floatWindowTimer.restart()
    }

    function close() {
        window.visible = false
    }

    function backToStart() {
        returningToStart = true
        window.visible = false
        returnTimer.start()
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
            sizeWindowTimer.restart()
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
        }
    }

    Timer {
        id: returnTimer
        interval: 200
        repeat: false
        onTriggered: {
            var target = Local.Session.returnStart
            Local.Session.returnStart = null
            root.returningToStart = false
            if (target && typeof target.open === "function") target.open()
            else if (root.shell && typeof root.shell.summon === "function") root.shell.summon(root.pluginId, "{}")
        }
    }

    FloatingWindow {
        id: window
        title: Qt.locale().name.indexOf("es") === 0 ? "Configuración" : "Settings"
        color: Local.Appearance.color("#f4f7fa")
        screen: root.targetScreen
        visible: false
        implicitWidth: 1080
        implicitHeight: 840
        minimumSize: Qt.size(880, 620)

        onVisibleChanged: {
            if (!visible && !root.returningToStart) Local.Session.returnStart = null
        }

        Local.SettingsContent {
            anchors.fill: parent
            userName: Quickshell.env("USER")
            deviceName: Quickshell.env("HOSTNAME")
            onCloseRequested: root.close()
            onBackRequested: root.backToStart()
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
