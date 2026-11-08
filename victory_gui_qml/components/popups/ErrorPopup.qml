import QtQuick 2.0
import com.hasselblad.error 1.0
import com.hasselblad.bodysync 1.0
import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys
MouseArea {
    objectName: "ErrorPopup"
    anchors.fill: parent
    z: 100
    property alias popupAnchor : popup.anchors
    property bool showAckButton: true
    property real sizeFactor: Math.min(width / 640.0, height / 480.0)
    Keys.onPressed: {
        if(MKeys.pressedFnAcc("STAR", event) ||
                MKeys.pressedFnAcc("AE_L", event) ||
                MKeys.pressedFnAcc("AF_D", event) ||
                MKeys.pressedFnAcc("HALFPRESS", event) ||
                MKeys.pressedFnAcc("TRUEFOCUS", event) ||
                MKeys.pressedFnAcc("ESCAPE", event))
        {
            ErrorControl.ack()
        }
        else if(MKeys.pressedFn("EXPOSURE", event.key))
        {
            event.accepted = false
            if(ErrorControl.code === Errors.ErrorExposureModePreventsLiveview)
            {
                ErrorControl.ack()
                event.accepted = false
                commonKeyHandle(event)
            }
        }
        else if(MKeys.pressedFn("TOGGLESLEEP", event.key))
        {
            event.accepted = false
        }
        else
        {
            event.accepted = true
        }
    }
    Keys.onReleased: {
        if(MKeys.pressedFn("HALFPRESS", event.key)) {
            if(ErrorControl.code === Errors.ErrorExposureModePreventsLiveview)
                ErrorControl.ack()
            else
                commonKeyHandleReleased(event)
        }
        else if(MKeys.pressedFn("EXPOSURE", event.key))
            commonKeyHandleReleased(event)
    }
    Timer {
        id: ackTimer
        repeat: false
        interval: ErrorControl.timeoutMs
        onTriggered: ErrorControl.ack()
    }
    Component.onCompleted: {
        if(ErrorControl.timeoutMs > 0)
            ackTimer.restart()
    }
    onActiveFocusChanged: {
        if(visible && !activeFocus && (ErrorControl.code !== Errors.ErrorNone))
        {
            setPreviouslyActiveItem()
            forceActiveFocus()
        }
    }
    Connections {
        target: configstore
        onExpModeChanged: ErrorControl.ack();
    }
    Rectangle {
        id: fadeOutParentRect
        color: constants.popupFadeoutColor
        anchors.fill: parent
        opacity: 0.5
    }
    Rectangle {
        id: popup
        anchors {
            fill: parent
            bottomMargin: 40 * sizeFactor
            topMargin: 40 * sizeFactor
            leftMargin: 60 * sizeFactor
            rightMargin: 60 * sizeFactor
        }
        color: "black"
        border {
            color: constants.popupBorderColor
            width: 3
        }
        Image {
            id: iconItem
            source: "qrc:///icons/infoDialogIcon.png"
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 40 * sizeFactor + height / 2 * (sizeFactor - 1)
            }
            scale: sizeFactor
        }
        Text {
            id: infoText
            text: ErrorControl.message
            visible: text != ""
            color: "white"
            font.pixelSize: 40 * sizeFactor
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            width: parent.width * .8
            anchors {
                top: iconItem.bottom
                left: parent.left
                right: parent.right
                bottom: acceptButton.top
            }
        }
        MenuButton {
            id: acceptButton
            visible: (text != "") && (0 === ErrorControl.timeoutMs) && (showAckButton)
            text: qsTr("OK")
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 20 * sizeFactor
            }
            onClicked: ErrorControl.ack()
        }
    }
}
