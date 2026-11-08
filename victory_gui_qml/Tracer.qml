import QtQuick 2.0

// This object can be used as a debug-marker for invisible objects, such as FocusScope or MouseArea's.
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
