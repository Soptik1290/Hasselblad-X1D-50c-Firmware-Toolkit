import QtQuick 2.0
Item {
    id: root
    property real progressPercent: 0
    property real percentageAnimDelay: 0
    property alias backColor: background.color
    property alias borderColor: frame.color
    property alias textColor: progressText.color
    property alias nonProgressedColor: progressIndicator.color
    property bool showText: false
    property int decimals: 0
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.height / 2
        color: "white"
    }
    Behavior on progressPercent {
        enabled: progressPercent < 1
        NumberAnimation {
            easing.type: Easing.Linear;
            duration: percentageAnimDelay * 1000
        }
    }
    Rectangle {
        id: progressIndicator
        anchors.fill: parent
        anchors.leftMargin: root.width * progressPercent
        color: "black"
    }
    Rectangle {
        id: frame
        anchors.fill: parent
        radius: background.radius
        border.color: "white"
        border.width: 2
        color: "transparent"
    }
    Text {
        id: progressText
        visible: showText
        height: background.height
        anchors.centerIn: background
        anchors.verticalCenterOffset: guiconfig.isLatin(text) ? (height - baselineOffset) * 0.5 : 0
        color: "white"
        font.pixelSize: 18
        fontSizeMode: Text.Fit
        font.bold: true
        text: (progressPercent * 100).toFixed(decimals) + " %"
    }
}
