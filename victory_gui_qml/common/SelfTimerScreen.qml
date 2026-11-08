import QtQuick 2.2
import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0
import com.hasselblad.globalstateinfo 1.0
import "qrc:/components"
import "qrc:///scripts/commonfunc.js" as Cmn
import "qrc:///scripts/Keys.js" as MKeys
Item {
    objectName: "SelfTimerScreen_root"
    id: root
    focus: true
    property alias selfTimerText: selfTimer.text
    property int bottomTextCenterMargin: constants.bottomTextCenterMargin
    property int sideTextCenterMarginFirst: constants.sideTextCenterMarginFirst
    property int sideTextCenterMarginMiddle: constants.sideTextCenterMarginMiddle
    property int sideTextCenterMarginLast: constants.sideTextCenterMarginLast
    property bool sideOriented: guiconfig.isWedge
    property bool isSelfTimer: Camera.selfTimerCountDown > 0
    property bool isLongExposure: Camera.exposureTimerCount > 0
    Keys.onPressed: {
        if(buttons.firstAvailable && MKeys.pressedFnAcc("ABORT", event)) {
            if (Camera.selfTimerCountDown > 0) {
                Camera.stopSelfTimer()
                GlobalStateInfo.selfTimerAborted = true
            }
            else if ((Camera.exposureTimerCount > 0) && !cambody.isBMode)
                Camera.finishExposure()
        } else if(buttons.firstAvailable && MKeys.pressedFn("EXPOSURE", event.key)) {
            if(0 === Camera.selfTimerCountDown && Camera.exposureTimerCount > 0) {
                if(!cambody.isTMode)
                {
                    Camera.finishExposure()
                    event.accepted = true
                }
            }
            else
                event.accepted = true
        } else {
            event.accepted = true
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {}
        z: 200
    }
    Rectangle {
        id: bg
        color: "black"
        anchors.fill: parent
    }
    Row {
        id: statusRow
        layoutDirection: Qt.RightToLeft
        anchors {
            top: parent.top
            topMargin: constants.cameraViewMargin
            right: parent.right
            rightMargin: constants.cameraViewMargin
        }
        height: constants.cameraViewLineTopBottomMargin - constants.cameraViewMargin
        spacing: constants.cameraViewMargin + 20
        BatteryIndicatorScaled {
            id: batteryIndicator
            visible: guiconfig.isWedge && (isLongExposure || cambody.isBMode || cambody.isTMode)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -8
            batteryWidth: 23
            height: 59
        }
    }
    Text {
        id: header_text
        anchors {
            left: parent.left
            right: statusRow.left
            top: parent.top
            topMargin: constants.headerVerticalOffset
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        text: isSelfTimer ? qsTr("Self Timer") :
                            isLongExposure ? qsTr("Exposing") + (cambody.isBMode ? " B-Mode" : cambody.isTMode ? " T-Mode" : "") : ""
        font.capitalization: Font.AllUppercase
    }
    Row {
        anchors {
            verticalCenter: bg.verticalCenter
            horizontalCenter: bg.horizontalCenter
        }
        spacing: 50
        Image {
            id: selfTimerIcon
            visible: isSelfTimer
            source: "qrc:///icons/Selftimer_Running.png"
            scale: 0.8
        }
        Text {
            function counterText()
            {
                if(isSelfTimer)
                    return Cmn.tdur(Camera.selfTimerCountDown)
                if(Camera.exposing) {
                    var prepend = ""
                    if(cambody.isBMode)
                        prepend = "B "
                    if(cambody.isTMode)
                        prepend = "T "
                    if(!Camera.exposureTimerCount)
                        return prepend
                    return prepend + Cmn.tdur(Camera.exposureTimerCount)
                }
                return ""
            }
            id: selfTimer
            visible: true
            text: counterText()
            color: "white"
            font.pixelSize: constants.selfTimerCountDownFontSize
            fontSizeMode: Text.HorizontalFit
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: selfTimerIcon.verticalCenter
            anchors.verticalCenterOffset: isSelfTimer ? (implicitHeight - baselineOffset) * 0.5 : 0
        }
    }
    ConfirmationButtons {
        id: buttons
        visible: (guiconfig.isWedge || configstore.CameraType !== Config.CameraTypeHsystem) && (Camera.selfTimerCountDown > 0 || cambody.exposure_abortable) && !cambody.isBMode
        color: bg.color
        sideOriented: parent.sideOriented
        middleAvailable: false
        firstText: isSelfTimer ? qsTr("Exit") : qsTr("Finish Exposure")
    }
}
