import QtQuick 2.0

Rectangle {
    id: root
    property real sizeFactor: Math.min(width / 640.0, height / 480.0)
    color: "black"
    focus: true

    // Prevent stealing of active focus
    onActiveFocusChanged: {
        if(!activeFocus)
        {
            setPreviouslyActiveItem()
            forceActiveFocus()
        }
    }

    // End station. Do not let anything through
    Keys.onPressed: {
        event.accepted = true
    }
    Keys.onReleased: {
        event.accepted = true
    }

    // Show the battery icon in the middle, scaled
    Image {
        source: "qrc:///icons/battery_exhausted.png"
        anchors.centerIn: parent
        scale: sizeFactor
    }

    // Capture all mouse events. Do not let anything through
    MouseArea {
        anchors.fill: parent
        onClicked: {}
        onDoubleClicked: {}
        propagateComposedEvents: false
    }

}
