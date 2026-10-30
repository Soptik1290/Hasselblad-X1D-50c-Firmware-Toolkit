import QtQuick 2.0

Item {
    objectName: "NotificationMessage_root"
    id: root
    property string headingText
    property alias capitalization: label.font.capitalization
    property alias showtime: timer.interval
    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Text {
        id: label
        text: qsTr(headingText) + guiconfig.emptyString
        color: "white"
        width: parent.width
        anchors {
            verticalCenter: parent.verticalCenter
        }
        font.pixelSize: 30
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        font.capitalization: Font.AllUppercase
    }

    Timer {
        id: timer
        running: true
        onTriggered: root.parent.active = false
        interval: 1000
        repeat: false
    }
}

