import QtQuick 2.0
Item {
    id: root
    anchors.fill: parent
    property color color: "red"
    Rectangle {
        id: rect
        anchors.fill: parent
        color: "transparent"
        border { color: root.color; width: 2 }
    }
}
