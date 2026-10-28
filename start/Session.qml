pragma Singleton
import QtQuick

// Shared scoped capability supplied by our lifecycle host. No app scanning,
// global shell references or new processes; the catalog remains Omarchy's.
QtObject {
    property string mode: "light"
    property var owner: null
    property var library: null
}
