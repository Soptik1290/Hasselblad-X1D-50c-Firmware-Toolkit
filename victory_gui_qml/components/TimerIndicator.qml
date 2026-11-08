import QtQuick 2.0
import com.hasselblad.settings 1.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.globalstateinfo 1.0
import "qrc:/components"
Item {
    width: childrenRect.width;
    height: childrenRect.height;
        Image {
            id: timerIndicatorIcon
            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            source: configstore.selfTimerActive  ? "qrc:/icons/cameraSettingsSelfTimer.png" :
                    configstore.intervalActive   ? "qrc:/icons/ControlScreen_Interval.png" :
                    configstore.bracketingActive ? "qrc:/icons/ControlScreen_Bracketing.png" :
                    configstore.focusBracketingActive ? "qrc:/icons/ControlScreen_FocusBracketing.png" : ""
        }
        Text {
            id: lblSeconds
            anchors {
                left: timerIndicatorIcon.right
                leftMargin: 15
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: (height - baselineOffset) / 2
            }
            text: {
                if(configstore.selfTimerActive)
                {
                    return (Camera.inSession && !GlobalStateInfo.haveHalfPress) ?
                            Camera.selfTimerCountDown : Settings.getDisplayValue("SelftimerDelay", configstore.SelftimerDelay)
                }
                else if(configstore.intervalActive)
                {
                    return (Camera.inSession && !GlobalStateInfo.haveHalfPress) ?
                            Camera.intervalTimerCountDown : configstore.IntervalTime
                }
                else
                {
                    return "";
                }
            }
            color: "white"
            font.bold: true
            font.pixelSize: constants.cameraViewSettingEVTextSize
            font.family: constants.cameraControlTextFontName
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: (configstore.bracketingActive || configstore.focusBracketingActive) ? timerIndicatorIcon.right : lblSeconds.right
            anchors.leftMargin: 15
            spacing: 5
            Bracket {
                id: frame_left_bracket
                visible: configstore.intervalActive
                leftBracket: true
                height: lblFrames.height
                width: 10
                borderWidth: 1
                lineWidth: 4
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: lblFrames
                anchors {
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: (height - baselineOffset) / 2
                }
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
                    else if(configstore.focusBracketingActive)
                    {
                        return Camera.inSession ? Settings.getDisplayValue("FocusBracketingNumberOfFrames", configstore.FocusBracketingNumberOfFrames) - GlobalStateInfo.photosAddedCount :
                                                  Settings.getDisplayValue("FocusBracketingNumberOfFrames", configstore.FocusBracketingNumberOfFrames)
                    }
                    else
                    {
                        return "";
                    }
                }
                color: "white"
                font.bold: true
                font.pixelSize: constants.cameraViewSettingEVTextSize
                font.family: constants.cameraControlTextFontName
            }
            Bracket {
                id: frame_right_bracket
                visible: configstore.intervalActive
                leftBracket: false
                width: 10
                height: lblFrames.height
                borderWidth: 1
                lineWidth: 4
                anchors.verticalCenter: parent.verticalCenter
            }
        }
}
