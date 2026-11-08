import QtQuick 2.0
Item {
    id: root
    width: 8*cross.width
    height: 8*cross.height
    property real minDragX: parent.x - (width - cross.width)/2 + crossBorderWidth
    property real minDragY: parent.y - (height - cross.height)/2
    property real maxDragX: parent.x + parent.width - (width - cross.width)/2 - cross.width
    property real maxDragY: parent.y + parent.height - (height - cross.height)/2 - cross.height
    property int crossX: x + width/2
    property int crossY: y + height/2
    property int crossWidth: 30
    property int crossHeight: 30
    property int crossBorderWidth: 3
    property real topOverlayHeight: 0
    property real bottomOverlayHeight: 0
    property bool dragAtTop: y === minDragY + topOverlayHeight
    signal toolReleased()
    Rectangle {
        id: circleOutline
        anchors.fill: parent
        color: "transparent"
        radius: width/2
        border.width: 5
        border.color: "black"
        Rectangle {
            id: circle
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            radius: width/2
            border.width: 3
            border.color: "white"
        }
        Rectangle {
            id: crossOutline
            anchors.centerIn: cross
            width: crossWidth+2
            height: crossHeight+2
            border.width: crossBorderWidth+2
            border.color: "black"
            color: "transparent"
        }
        Rectangle {
            id: cross
            anchors.centerIn: parent
            width: crossWidth
            height: crossHeight
            border.width: crossBorderWidth
            border.color: "white"
            color: "transparent"
        }
        Image {
            id: eyeDropper
            anchors.bottom: cross.top
            anchors.left: cross.right
            source: "qrc:///icons/LargeIconGreyBalanceTool_outline.png"
        }
    }
    MouseArea {
        id: dragArea
        anchors.fill: parent
        propagateComposedEvents: true
        drag {
            target: dragArea.pressed ? root : null
            axis: Drag.XAndYAxis
            minimumX: root.minDragX
            maximumX: root.maxDragX
            minimumY: root.minDragY + topOverlayHeight
            maximumY: root.maxDragY - bottomOverlayHeight
        }
        onPressedChanged: {
            if (!pressed) {
                toolReleased()
            }
        }
    }
}
