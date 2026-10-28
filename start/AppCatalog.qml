import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "file:///usr/share/omarchy/shell/services/AppSearch.js" as AppSearch

// Keep the shared DesktopEntries registry usable if Omarchy revokes a scoped
// menu facade during registry refresh. Reuse its search and hide-list helper;
// do not construct another AppLibrary or icon scanner.
Item {
    id: catalog
    property var nativeLibrary: null
    property var configuredHidden: ({})
    property var desktopHidden: ({})
    readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"
    signal appsChanged

    function hiddenMap(text) {
        var result = {};
        String(text || "").split(/\n/).forEach(function (line) {
            var id = line.trim().replace(/\.desktop$/, "");
            if (id)
                result["$" + id] = true;
        });
        return result;
    }
    function isHidden(entry) {
        return configuredHidden["$" + entry.id] === true || desktopHidden["$" + entry.id] === true;
    }
    function sortedEntries(query) {
        if (nativeLibrary)
            return nativeLibrary.sortedEntries(query);
        return AppSearch.sortedEntries(DesktopEntries.applications.values || [], query, function (entry) {
            return catalog.isHidden(entry);
        });
    }
    function entryName(entry) {
        return AppSearch.entryName(entry);
    }
    function iconSource(icon) {
        if (nativeLibrary)
            return nativeLibrary.iconSource(icon);
        var value = String(icon || "");
        if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0)
            return value;
        if (value.charAt(0) === "/")
            return Util.fileUrl(value);
        return Quickshell.iconPath(value || "application-x-executable", true) || Quickshell.iconPath("application-x-executable", true);
    }
    function refreshIcons() {
        if (nativeLibrary)
            nativeLibrary.refreshIcons();
    }
    function launch(id, name) {
        if (nativeLibrary) {
            nativeLibrary.launch(id, name);
            return;
        }
        var entry = DesktopEntries.byId(String(id));
        if (!entry || entry.noDisplay || isHidden(entry))
            return;
        Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", String(entry.id) + ".desktop"]);
    }
    function scanHidden() {
        if (!nativeLibrary && !hiddenScan.running)
            hiddenScan.running = true;
    }
    onNativeLibraryChanged: {
        scanHidden();
        appsChanged();
    }
    onConfiguredHiddenChanged: appsChanged()
    onDesktopHiddenChanged: appsChanged()

    FileView {
        path: catalog.omarchyPath + "/default/omarchy/launcher.hides"
        watchChanges: true
        printErrors: false
        onLoaded: catalog.configuredHidden = catalog.hiddenMap(text())
        onFileChanged: reload()
    }
    Process {
        id: hiddenScan
        command: [catalog.omarchyPath + "/shell/services/hidden-entries.sh", [Quickshell.env("XDG_CURRENT_DESKTOP"), Quickshell.env("XDG_SESSION_DESKTOP"), Quickshell.env("DESKTOP_SESSION")].join(":")]
        stdout: StdioCollector {
            onStreamFinished: catalog.desktopHidden = catalog.hiddenMap(text)
        }
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            catalog.scanHidden();
            catalog.appsChanged();
        }
    }
    Connections {
        target: catalog.nativeLibrary
        ignoreUnknownSignals: true
        function onAppsChanged() {
            catalog.appsChanged();
        }
    }
    Component.onCompleted: scanHidden()
}
