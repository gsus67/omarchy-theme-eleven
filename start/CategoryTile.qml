import QtQuick

ElevenButton {
    id: tile
    property var group: ({
            preview: []
        })
    property var library: null
    implicitHeight: width + 28
    subtle: true
    background: Item {}
    contentItem: Item {
        Rectangle {
            width: parent.width
            height: width
            radius: 9
            color: tile.down ? Appearance.color("#dce5ef") : tile.hovered || tile.activeFocus ? Appearance.color("#f2f6fb") : Appearance.color("#ffffff")
            opacity: tile.hovered || tile.activeFocus ? 1 : 0.22
        }
        Rectangle {
            width: parent.width
            height: width
            radius: 9
            color: "transparent"
            border.width: tile.activeFocus ? 2 : 1
            border.color: tile.activeFocus ? Appearance.color("#0078d4") : Appearance.color("#d5dce3")
        }
        Repeater {
            model: tile.group.preview
            Image {
                required property var modelData
                required property int index
                width: 32
                height: 32
                x: (index % 2 === 0 ? 0.28 : 0.72) * tile.width - 16
                y: (index < 2 ? 0.28 : 0.72) * tile.width - 16
                source: String(modelData.id || "").replace(/\.desktop$/, "") === "org.gnome.Nautilus"
                    ? Qt.resolvedUrl("../assets/fluent/files.svg")
                    : tile.library ? tile.library.iconSource(modelData.icon || "") : ""
                sourceSize.width: 48
                sourceSize.height: 48
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
        }
        Text {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 28
            text: tile.text
            textFormat: Text.PlainText
            color: Appearance.color("#1b1b1b")
            font.family: "sans-serif"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
