import QtQuick 2.0

Rectangle {
    height: guiconfig.isWedge ? 113.3 : 40
    width: guiconfig.isWedge ? 40       :
           guiconfig.isCFV   ? 109.7436 :
                               109
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
