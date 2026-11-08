import QtQuick 2.0
Rectangle {
    id: root
    objectName: "ShutdownScreen"
    color: constants.menuBackgroundColor
    anchors.fill: parent
    Image {
        id: icon
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -70
        source: "qrc:///icons/shutdown.png"
    }
    Text {
        text: qsTr("Shutting Down") + guiconfig.emptyString
        color: constants.dialogButtonTextColor
        font.family: constants.dialogTextFontName
        font.pixelSize: 50
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 70
    }
}
