import QtQuick 2.0
import com.hasselblad.bodysync 1.0

Item {
    objectName: "DialModeOverlay_root"
    id: root
    property bool dialMoving: false
    property bool allowVisible: true
    anchors.centerIn: parent
    visible: dialMoving
    property real sizeFactor: 1
    z:300
    opacity: 1

    Image {
        id: dialModeShadow
        width: implicitWidth * sizeFactor
        height: implicitHeight * sizeFactor
        anchors.centerIn: dialModeImage
        source: "qrc:///icons/modeDialOverlayShadow.png"
    }

    Image {
        id: dialModeImage
        width: implicitWidth * sizeFactor
        height: implicitHeight * sizeFactor
        anchors.centerIn: root
        source: "qrc:///icons/modeDialOverlay.png"
        // This offset rotation angle by four could be skipped if the original image is rotated right at index 0.
        rotation: ~~(360 - ~~((~~360 / 10) * ((BodySync.currentDialMode) % 10)))

        Behavior on rotation {
            SpringAnimation {
                modulus: 360
                spring: 5
                damping: 5
                epsilon: 0.25
                mass:5
            }
        }
    }

    Image {
        id: smallArrow
        width: implicitWidth * sizeFactor
        height: implicitHeight * sizeFactor
        source: "qrc:///icons/modeDialArrow.png"
        anchors {
            right: dialModeImage.left
            verticalCenter: dialModeImage.verticalCenter
        }
    }

    PropertyAnimation {
        id: dialAnim
        target: root
        property: "opacity"
        from: 1
        to: 0
        duration: 800
        onRunningChanged: if(!running) root.dialMoving = false
        easing.type: Easing.InOutQuad
    }

    Timer {
        id: fadeDial
        interval: 1500
        repeat: false
        onTriggered: dialAnim.start()
    }

    Connections {
        target: BodySync
        onCurrentDialModeChanged: {
            // Show the overlayed dialMode and start fading timer.
            if(allowVisible) {
                dialAnim.stop()
                root.dialMoving = true
                root.opacity = 1
                // delay the fadeout
                fadeDial.restart()
            }
        }
    }
}
