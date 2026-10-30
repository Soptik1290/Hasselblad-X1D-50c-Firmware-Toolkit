import QtQuick 2.0
import com.hasselblad.mockup 1.0

Item {
    Rectangle {
        color: "darkgray"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.topMargin: parent.height / 20
        radius: width / 100

        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height / 30
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: guiconfig.isCFV ? (parent.width - camBg.width) / 2 : parent.width / 40
            anchors.rightMargin: anchors.leftMargin
            spacing: guiconfig.isCFV ? 22.8205 : parent.width / 15

            MockupButton {
                button: "f1"
            }
            MockupButton {
                button: "f2"
            }
            MockupButton {
                button: "f3"
            }
            MockupButton {
                button: "f4"
            }
            MockupButton {
                button: "f5"
            }
        }
    }
    Rectangle {
        id: camBg
        anchors.centerIn: parent
        width: 640
        height: 480
        color: "black"
    }

    KeyInject {
        id: inject
    }
}
