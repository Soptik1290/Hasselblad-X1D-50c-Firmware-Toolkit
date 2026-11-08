import QtQuick 2.0
import com.hasselblad.mockup 1.0
Item {
    Rectangle {
        color: "darkgray"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.leftMargin: parent.height / 20
        radius: width / 100
        Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 86
            anchors.right: parent.right
            anchors.rightMargin: parent.width / 40
            spacing: 22.4
            MockupButton {
                button: "f5"
            }
            MockupButton {
                button: "f4"
            }
            MockupButton {
                button: "f3"
            }
            MockupButton {
                button: "f2"
            }
            MockupButton {
                button: "f1"
            }
        }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 640
        height: 480
        color: "black"
    }
    KeyInject {
        id: inject
    }
}
