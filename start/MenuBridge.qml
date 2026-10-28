import QtQuick
import Quickshell

// The declared menu kind gives the widget Omarchy's scoped AppLibrary API.
// Keep native summon support without replacing Omarchy's utility menus.
Item {
    property var shell: null
    property var manifest: null
    function open(payload) {
        Quickshell.execDetached(["omarchy-shell", "eleven-start", "open"]);
    }
    function close() {
        Quickshell.execDetached(["omarchy-shell", "eleven-start", "close"]);
    }
}
