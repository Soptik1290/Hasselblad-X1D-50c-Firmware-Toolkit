import QtQuick 2.0
Item {
    width: childrenRect.width
    height: childrenRect.height
    property bool superspeed: true
    Rectangle {
        id: usbLabelRect
        width: 130
        height: constants.cardStatusIconSize * 2 + 18
        color: "transparent"
        border.width: constants.cardStatusIconBorderSize
        border.color: constants.cardStatusNotActiveBorderColor
        Text {
            id: usbLabelText
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: 6
                left: parent.left
                right: parent.right
                leftMargin: 5
                rightMargin: 5
            }
            horizontalAlignment: Text.AlignHCenter
            color: "white"
            text: superspeed ? "USB3" : "USB2"
            font.pixelSize: 42
            font.bold: true
            font.family: constants.cameraControlTextFontName
        }
    }
    function startBlink()
    {
        blinkLoop.start();
    }
    SequentialAnimation {
        id: blinkLoop
        loops: constants.animationBlinkLoops
        NumberAnimation {
            targets: [usbLabelRect, usbLabelText]
            property: "opacity"
            to: 0
            duration: constants.animationDurationBlink
            easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: constants.animationDurationBlink }
        NumberAnimation {
            targets: [usbLabelRect, usbLabelText]
            property: "opacity"
            to: 1
            duration: constants.animationDurationBlink
            easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: constants.animationDurationBlink }
    }
}
