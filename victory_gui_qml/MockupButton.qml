import QtQuick 2.0
Rectangle {
    height: 113.3
    width: 40
    color: "gray"
    radius: 6
    property string button
    MouseArea {
        anchors.fill: parent
        onPressed: {
            parent.color = "lightgray"
            inject.inject(parent.button, true)
        }
        onReleased: {
            parent.color = "gray"
            inject.inject(parent.button, false)
        }
    }
}
