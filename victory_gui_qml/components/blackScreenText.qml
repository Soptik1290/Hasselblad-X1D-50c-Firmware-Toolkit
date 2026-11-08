import QtQuick 2.0
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    id: bg_rect
    objectName: "BlackScreenText"
    color: constants.menuBackgroundColor
    anchors.fill: parent
    visible: false
    property string text: ""
    property real sizeFactor: Math.min(width / 640.0, height / 480.0)
    property int textSize: constants.evfTextSize * sizeFactor
    property int iconTopMargin: 60 * sizeFactor
    property int textWidth: root.width - 20 * sizeFactor
    Keys.onPressed: {
        if (!(MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("EXPOSURE", event.key))) {
            bg_rect.visible = false
            event.accepted = true
        } else {
            commonKeyHandle(event)
        }
    }
    Keys.onReleased: {
        commonKeyHandleReleased(event)
    }
    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: 40 * sizeFactor
        }
        border.color: constants.popupBorderColor
        border.width: 2
        color: constants.menuBackgroundColor
        Image {
            id: icon
            anchors {
                top: parent.top
                topMargin: iconTopMargin * sizeFactor + height / 2 * (sizeFactor - 1)
                horizontalCenter: parent.horizontalCenter
            }
            visible: true
            scale: sizeFactor
            source: "qrc:///icons/infoDialogIcon.png"
        }
        Text {
            anchors {
                top: icon.bottom
                topMargin: iconTopMargin + icon.height / 2 * (sizeFactor - 1)
                left: parent.left
                right: parent.right
                leftMargin: 10 * sizeFactor
                rightMargin: 10 * sizeFactor
            }
            width: textWidth
            color: constants.cameraViewNormalTextColor
            text: bg_rect.text
            style: Text.Outline
            styleColor: "black"
            fontSizeMode: Text.HorizontalFit
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: constants.errorDialogSubTextSize * sizeFactor
        }
    }
    MouseArea {
        anchors.fill: bg_rect
        onClicked: { bg_rect.visible = false }
    }
}
