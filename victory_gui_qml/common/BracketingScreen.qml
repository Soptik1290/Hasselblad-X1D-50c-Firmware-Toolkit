import QtQuick 2.2

import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.settings 1.0

import "qrc:/components"

import "qrc:///scripts/commonfunc.js" as Cmn
import "qrc:///scripts/Keys.js" as MKeys

Item {
    objectName: "BracketingScreen_root"
    id: root
    focus: true
    property int bottomTextCenterMargin: constants.bottomTextCenterMargin
    property int sideTextCenterMarginFirst: constants.sideTextCenterMarginFirst
    property int sideTextCenterMarginMiddle: constants.sideTextCenterMarginMiddle
    property int sideTextCenterMarginLast: constants.sideTextCenterMarginLast
    property bool isBracketing: Camera.inSession
    property bool isLongExposure: Camera.exposureTimerCount > 0
    property bool overlay: false
    property int numberOfFrames: configstore.bracketingActive ?
                                     Settings.getDisplayValue("BracketingNumberOfFrames", configstore.BracketingNumberOfFrames) :
                                     Settings.getDisplayValue("FocusBracketingNumberOfFrames", configstore.FocusBracketingNumberOfFrames)
    property string bracketingAdjustText: configstore.bracketingActive ?
                                              (Camera.AEB_EVADJ/12.0).toFixed(1) + " EV" :
                                              Settings.getDisplayValue("FocusBracketingStepSize", configstore.FocusBracketingStepSize)

    Keys.onPressed: {
        // If no session is ongoing let someone else handle the keys
        if (!Camera.inSession)
            return

        if(MKeys.pressedFnAcc("ABORT", event)) {
            Camera.stopIntervalTimer()
            GlobalStateInfo.selfTimerAborted = true
            if (Camera.exposureTimerCount > 0)
                Camera.finishExposure()
        }
        else if (MKeys.pressedFn("EXPOSURE", event.key)) {
            // EXPOSURE press is allowed to stop, but only if exposure has started (ongoing)
            if(Camera.exposureTimerCount > 0) {
                Camera.finishExposure()
                event.accepted = true
            }
        }
        else
            event.accepted = true
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
        text: isBracketing && configstore.bracketingActive ? qsTr("Exposure Bracketing") :
                             isBracketing && configstore.focusBracketingActive ? qsTr("Focus Bracketing") :
                             isLongExposure ? qsTr("Exposing") :
                             ""
        font.capitalization: Font.AllUppercase
    }


    Image {
        id: bracketingIcon
        source: configstore.bracketingActive ? "qrc:///icons/LargeIconBracketing.png" : "qrc:///icons/LargeIconFocusBracketing.png"
        scale: 1.3
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -20
        anchors.left: bg.left
        anchors.leftMargin: 60
    }

    Row {
        id: countRow
        anchors {
            verticalCenter: bg.verticalCenter
            verticalCenterOffset: -60
            left: bracketingIcon.right
            leftMargin: 50
        }
        spacing: 30

        Text {
            id: bracketingCounter
            text: {
                // Special value if focus bracketing and symmetric method
                if(configstore.focusBracketingActive &&
                   (configstore.FocusBracketingStrategy === Config.FocusBracketingToNearToInf))
                {
                    return Math.min(numberOfFrames - GlobalStateInfo.photosAddedCount + 1, numberOfFrames)
                }
                else
                {
                    return numberOfFrames - GlobalStateInfo.photosAddedCount
                }
            }
            color: "white"
            font.pixelSize: constants.bracketingFontSize
            style: Text.Outline
            styleColor: "black"
            fontSizeMode: Text.HorizontalFit
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: (implicitHeight - baselineOffset) * 0.5
        }

        Row {
            id: frameCounter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Image {
                id: frameLeftBracket
                height: framesLbl.height
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/icons/left_bracket.png"
            }

            Text {
                id: framesLbl
                text: numberOfFrames
                color: "white"
                font.pixelSize: constants.bracketingFontSize
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
                source: "qrc:/icons/right_bracket.png"
            }
        }
    }

    Text {
        id: bracketingAdjust
        text: bracketingAdjustText
        color: "white"
        font.pixelSize: configstore.bracketingActive ? constants.bracketingFontSize : constants.focusBracketingFontSize
        style: Text.Outline
        styleColor: "black"
        fontSizeMode: Text.HorizontalFit
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight

        anchors {
            top: countRow.bottom
            topMargin: guiconfig.isLatin(buttons.firstText) ? 20 : 0
            left: bracketingIcon.right
            leftMargin: 50
        }
    }

    Text {
        id: longExposure
        visible: isLongExposure
        text: qsTr("Exposing") + ": "  + Cmn.tdur(Camera.exposureTimerCount)
        color: "white"
        font.pixelSize: 45
        style: Text.Outline
        styleColor: "black"
        fontSizeMode: Text.HorizontalFit
        verticalAlignment: Text.AlignVCenter
        anchors {
            bottom: parent.bottom
            bottomMargin: 10
            left: bracketingIcon.left
        }
    }

    Text {
        id: initialDelay
        visible: Camera.intervalTimerCountDown > 0
        // NOTE: If in the future intervalTimerCountDown gets larger than 60 seconds, call the Cmn.tdur function to format the text:
        text: Camera.intervalTimerCountDown + " " + qsTr("s")
        color: "white"
        font.pixelSize: 45
        style: Text.Outline
        styleColor: "black"
        fontSizeMode: Text.HorizontalFit
        verticalAlignment: Text.AlignVCenter
        anchors {
            bottom: longExposure.bottom
            left: longExposure.left
        }
    }

    ConfirmationButtons {
        id: buttons
        color: bg.color
        sideOriented: true
        firstText: qsTr("Exit")
    }
} // root Item
