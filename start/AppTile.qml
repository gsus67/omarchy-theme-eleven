import QtQuick

ElevenButton {
    id: tile
    property bool wide: false
    property bool selected: false
    property bool keyboardSelected: false
    property url iconSource: ""
    subtle: true
    background: Rectangle {
        radius: 5
        color: tile.down ? Appearance.color("#d9e3ef") : tile.hovered || tile.selected ? Appearance.color("#f5f8fc") : "transparent"
        border.color: tile.keyboardSelected ? Appearance.color("#0078d4") : "transparent"
        border.width: 2
    }
    contentItem: Item {
        Image {
            width: tile.wide ? 28 : 32
            height: width
            x: tile.wide ? 12 : (parent.width - width) / 2
            y: tile.wide ? (parent.height - height) / 2 : 12
            source: tile.iconSource
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        Text {
            x: tile.wide ? 54 : 4
            y: tile.wide ? 0 : 50
            width: parent.width - x - 4
            height: tile.wide ? parent.height : 32
            text: tile.text
            textFormat: Text.PlainText
            color: Appearance.color("#1b1b1b")
            font.family: "sans-serif"
            font.pixelSize: 12
            horizontalAlignment: tile.wide ? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            maximumLineCount: tile.wide ? 1 : 2
            elide: Text.ElideRight
        }
    }
}
