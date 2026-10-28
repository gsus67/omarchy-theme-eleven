import QtQuick
import QtQuick.Controls

AbstractButton {
    id: control
    property bool subtle: false
    signal contextRequested
    implicitWidth: Math.max(40, label.implicitWidth + 24)
    implicitHeight: 34
    hoverEnabled: true
    activeFocusOnTab: true
    Accessible.name: text
    font.family: "sans-serif"
    font.pixelSize: 13
    background: Rectangle {
        radius: 5
        color: control.down ? "#d6eaff" : control.hovered || control.activeFocus ? "#e6edf6" : control.subtle ? "transparent" : "#ffffff"
        border.color: control.activeFocus ? "#0067c0" : control.subtle ? "transparent" : "#d9e0e8"
        border.width: control.activeFocus ? 2 : 1
    }
    contentItem: Text {
        id: label
        text: control.text
        textFormat: Text.PlainText
        color: control.enabled ? "#1b1b1b" : "#626c78"
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: control.contextRequested()
    }
}
