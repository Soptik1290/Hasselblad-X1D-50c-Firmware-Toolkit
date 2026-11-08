import QtQuick 2.2
import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.settings 1.0
import "qrc:/components"
import "qrc:///scripts/commonfunc.js" as Cmn
import "qrc:///scripts/Keys.js" as MKeys
Item {
    objectName: "IntervalTimerScreen_root"
    id: root
    focus: true
    property alias intervalTimerText: intervalTimer.text
    property int bottomTextCenterMargin: constants.bottomTextCenterMargin
    property int sideTextCenterMarginFirst: constants.sideTextCenterMarginFirst
    property int sideTextCenterMarginMiddle: constants.sideTextCenterMarginMiddle
    property int sideTextCenterMarginLast: constants.sideTextCenterMarginLast
    property bool sideOriented: guiconfig.isWedge
    property bool isIntervalTimer: Camera.intervalTimerCountDown > 0
    property bool isLongExposure: Camera.exposureTimerCount > 0
    property bool overlay: false
    Keys.onPressed: {
        if (Camera.intervalTimerCountDown === 0 && Camera.exposureTimerCount == 0)
            return
        if(MKeys.pressedFnAcc("STAR", event)) {
            Camera.stopIntervalTimer()
            GlobalStateInfo.selfTimerAborted = true
            if (Camera.exposureTimerCount > 0)
                Camera.finishExposure()
        }
        if(MKeys.pressedFnAcc("ABORT", event)) {
            if (Camera.exposureTimerCount > 0)
                Camera.finishExposure()
        }
        else if (MKeys.pressedFn("EXPOSURE", event.key)) {
            if(0 === Camera.intervalTimerCountDown && Camera.exposureTimerCount > 0) {
                Camera.finishExposure()
                event.accepted = true
            }
            else
                event.accepted = true
        } else if (!MKeys.pressedFn("MENU", event.key)) {
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
        opacity: overlay ? 0 : 1;
    }
    Row {
        id: statusRow
        visible: !overlay
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
            visible: guiconfig.isWedge && (isLongExposure || isIntervalTimer)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -8
            batteryWidth: 23
            height: 59
        }
    }
    Text {
        id: header_text
        visible: !overlay
        anchors {
            left: parent.left
            right: statusRow.left
            top: parent.top
            topMargin: constants.headerVerticalOffset
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        text: isIntervalTimer ? qsTr("Interval Timer") :
              isLongExposure ? qsTr("Exposing") : ""
        font.capitalization: Font.AllUppercase
    }
    Row {
        id: intervalTimerRow
        anchors {
            verticalCenter: bg.verticalCenter
            verticalCenterOffset: -40
            left: bg.left
            leftMargin: 50
        }
        spacing: 30
        Image {
            id: intervalTimerIcon
            visible: isIntervalTimer || (isLongExposure && configstore.intervalActive)
            source: "qrc:///icons/Interval_Icon_90.png"
            scale: 0.8
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: intervalTimer
            text: Camera.intervalTimerCountDown
            color: "white"
            font.pixelSize: constants.intervalTimerCountDownFontSize
            style: Text.Outline
            styleColor: "black"
            fontSizeMode: Text.HorizontalFit
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: (implicitHeight - baselineOffset) * 0.5
        }
        Row {
            id: frameCounter
            anchors.verticalCenter: intervalTimerIcon.verticalCenter
            spacing: 10
            Image {
                id: frameLeftBracket
                height: framesLbl.height
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/icons/Left_Bracket_outline.png"
            }
            Text {
                id: framesLbl
                text: {
                    if(configstore.intervalActive)
                    {
                        if(255 === configstore.IntervalNumberOfShots)
                        {
                            return '\u221e'
                        }
                        else
                        {
                            return Camera.inSession ? Settings.getDisplayValue("IntervalNumberOfShots", configstore.IntervalNumberOfShots) - GlobalStateInfo.photosAddedCount :
                                                      Settings.getDisplayValue("IntervalNumberOfShots", configstore.IntervalNumberOfShots)
                        }
                    }
                    else if(configstore.bracketingActive)
                    {
                        return Camera.inSession ? Settings.getDisplayValue("BracketingNumberOfFrames", configstore.BracketingNumberOfFrames) - GlobalStateInfo.photosAddedCount :
                                                  Settings.getDisplayValue("BracketingNumberOfFrames", configstore.BracketingNumberOfFrames)
                    }
                    else
                    {
                        return "";
                    }
                }
                color: "white"
                font.pixelSize: constants.intervalTimerCountDownFontSize
                style: Text.Outline
                styleColor: "black"
                fontSizeMode: Text.HorizontalFit
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: (implicitHeight - baselineOffset) * 0.5
            }
            Image {
                id: frameRightBracket
                height: framesLbl.height
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/icons/Right_Bracket_outline.png"
            }
        }
    }
    ConfirmationButtons {
        id: buttons
        visible: (guiconfig.isWedge || configstore.CameraType !== Config.CameraTypeHsystem) && (isIntervalTimer || isLongExposure || cambody.exposure_abortable)
        color: bg.color
        sideOriented: parent.sideOriented
        middleText: isIntervalTimer || isLongExposure ? qsTr("Exit") : ""
        firstText: isLongExposure ? Cmn.tdur(Camera.exposureTimerCount) + "   " + qsTr("Finish Exposure") : ""
    }
}
