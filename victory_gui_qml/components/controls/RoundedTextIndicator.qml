import QtQuick 2.0
Rectangle {
    property alias text: label.text
    property real sizeFactor: 1
    property alias pixelSize: label.font.pixelSize
    property bool outlineText: false
    property color outlineColor: "grey"
    property color outlineTextColor: "white"
    property color nonOutlinedTextColor: "white"
    color: outlineText ? outlineColor : nonOutlinedTextColor
    border.color: outlineText ? outlineStyleColor : "black"
    border.width: Math.max(1, 1 * sizeFactor)
    width: 20 * sizeFactor
    height: 42 * sizeFactor
    radius: 5 * sizeFactor
    Text {
        id: label
        anchors {
            centerIn: parent
            verticalCenterOffset: (height - baselineOffset) / 2
        }
        text: "!"
        font.pixelSize: 33 * sizeFactor
        font.weight: (typeof Font.Medium !== "undefined") ? Font.Medium : 57
        color: outlineText ? outlineTextColor : "black"
        font.family: constants.cameraControlTextFontName
    }
}
