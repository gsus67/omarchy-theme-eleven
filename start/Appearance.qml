pragma Singleton
import QtQuick

QtObject {
    id: palette
    readonly property bool dark: Session.mode === "dark"
    readonly property var darkColors: {
        "#e9edf1": "#242424",
        "#c1c8cf": "#4b4b4b",
        "#20252b": "#f3f3f3",
        "#7b838b": "#aab2bc",
        "#f8fbfe": "#303030",
        "#cbd7e2": "#64778a",
        "#d4dce4": "#484f57",
        "#64696e": "#b7bec7",
        "#e4e8ed": "#202020",
        "#d5dce3": "#454b53",
        "#f7f9fb": "#383838",
        "#dde5ed": "#414950",
        "#eef2f6": "#353b41",
        "#0078d4": "#60b8ff",
        "#f4f7fa": "#2b2b2b",
        "#d1d8df": "#4a5058",
        "#e5ebf2": "#3a424c",
        "#d6eaff": "#16496d",
        "#e6edf6": "#343e49",
        "#ffffff": "#303030",
        "#0067c0": "#60b8ff",
        "#d9e0e8": "#4b535d",
        "#1b1b1b": "#f3f3f3",
        "#626c78": "#b4bdc9",
        "#dce5ef": "#384756",
        "#f2f6fb": "#353d46",
        "#d9e3ef": "#3c4a58",
        "#f5f8fc": "#343b43",
        "#e1e6eb": "#4b535d"
}
    function color(light) { return dark ? (darkColors[light] || light) : light; }
}
