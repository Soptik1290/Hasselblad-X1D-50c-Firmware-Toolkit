import QtQuick 2.0
Rectangle {
    id: root
    property real sizeFactor: Math.min(width / 640.0, height / 480.0)
    color: "black"
    focus: true
    onActiveFocusChanged: {
        if(!activeFocus)
        {
            setPreviouslyActiveItem()
            forceActiveFocus()
        }
    }
    Keys.onPressed: {
        event.accepted = true
    }
    Keys.onReleased: {
        event.accepted = true
    }
    Image {
        source: "qrc:///icons/battery_exhausted.png"
        anchors.centerIn: parent
        scale: sizeFactor
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {}
        onDoubleClicked: {}
        propagateComposedEvents: false
    }
}
