import QtQuick

ElevenButton {
    id: tile
    property string detail: ""
    property url iconSource: ""
    property bool blueCenter: false
    implicitHeight: 56
    subtle: true
    contentItem: Item {
        Rectangle {
            visible: tile.blueCenter
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: "#0078d4"
        }
        Image {
            id: symbol
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            source: tile.iconSource
            sourceSize.width: 40
            sourceSize.height: 40
            fillMode: Image.PreserveAspectFit
        }
        Column {
            x: 52
            width: parent.width - x - 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                width: parent.width
                text: tile.text
                textFormat: Text.PlainText
                color: "#1b1b1b"
                font.family: "sans-serif"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: tile.detail
                textFormat: Text.PlainText
                color: "#64696e"
                font.family: "sans-serif"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }
}
