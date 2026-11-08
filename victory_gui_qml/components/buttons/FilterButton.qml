import QtQuick 2.5
import "qrc:///common"
Rectangle {
    id: root
    signal clicked()
    property alias enabled: ma.enabled
    property bool highlight: false
    width: image.width
    height: image.height
    anchors {
        top: parent.top
        left: parent.left
        margins: 20
    }
    color: (ma.containsPress || highlight) ? constants.hblOrange : "transparent"
    Image {
        id: image
        anchors.centerIn: root
        source: "qrc:///icons/Filter_Icon_60.png"
        MouseArea {
            id: ma
            anchors.fill: parent
            anchors.margins: -parent.width/2
            onClicked: {
                root.clicked()
            }
            Item { anchors.fill: ma }
        }
    }
}
