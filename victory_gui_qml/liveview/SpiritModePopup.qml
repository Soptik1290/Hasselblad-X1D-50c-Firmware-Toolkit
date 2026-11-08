import QtQuick 2.0
import com.hasselblad.guiconfig 1.0
import com.hasselblad.config 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.spiritlevel 1.0
import com.hasselblad.video 1.0
import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys
FocusScope
{
    objectName: "SpiritModePopup_focusScope"
    id: popupContainer
    property real sizeFactor: 640 / 1024
    property Item returnToItem: null
    property int listItemHeight: 220 * sizeFactor
    property bool wasEnabled: false
    property int notShowingBodyState: BodySync.MAIN
    function open(returnItem) {
        notShowingBodyState = BodySync.currentState
        if(typeof returnItem !== "undefined")
        {
            returnToItem = returnItem
        }
        else
        {
            returnToItem = null
        }
        visible = true
        if(typeof preventLiveViewSwipe !== "undefined")
        {
            preventLiveViewSwipe = true
        }
        if(configstore.Spiritlevel_UserCalibration)
        {
            spiritModeUser.focus = true
        }
        else
        {
            spiritModeNormal.focus = true
        }
        VideoControl.prohibitZoom = true
    }
    function close() {
        visible = false;
        if(typeof preventLiveViewSwipe !== "undefined")
        {
            preventLiveViewSwipe = false
        }
        VideoControl.prohibitZoom = false
        userButton.buttonPressed = false
    }
    anchors.fill: parent
    Keys.onPressed: {
        event.accepted = true
        if(MKeys.pressedFnAcc("SELECT", event))
        {
            close();
        }
        else if(MKeys.pressedFnAcc("MENU", event) || MKeys.pressedFnAcc("BROWSE", event) || MKeys.pressedFnAcc("ESCAPE", event))
        {
            close();
        }
        else if(MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("FORMAT", event.key))
        {
            event.accepted = false
        }
    }
    Keys.onReleased: userButton.buttonPressed = false
    MouseArea {
        preventStealing: true
        z: 100
        anchors.fill: parent
        onClicked: close()
        onDoubleClicked: {}
        onPressAndHold: {}
        Rectangle {
            id: fadeOutParentRect
            color: constants.popupFadeoutColor
            anchors.fill: parent
            opacity: 0.5
        }
        Rectangle {
            id: popup
            color: constants.popupBackgroundColor
            radius: constants.outerBoxRadius
            border.width: 2
            border.color: constants.popupBorderColor
            anchors {
                leftMargin: 110 * sizeFactor
                rightMargin: 110 * sizeFactor
                topMargin: 110 * sizeFactor
                bottomMargin: 110 * sizeFactor
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                top: parent.top
            }
            Text {
                id: heading
                text: qsTr("SPIRIT LEVEL") + guiconfig.emptyString
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 34 * sizeFactor
                color: constants.popupTextColor
                anchors {
                    top: parent.top
                    topMargin: 53 * sizeFactor
                    horizontalCenter: parent.horizontalCenter
                }
                font.capitalization: Font.AllUppercase
            }
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: { }
            }
            Rectangle {
                anchors.fill: spiritModeNormal
                color: spiritModeNormalMouseArea.pressed  || !configstore.Spiritlevel_UserCalibration ? constants.hblOrange : "transparent"
                MouseArea{
                    id: spiritModeNormalMouseArea
                    anchors.fill: parent
                    onClicked: {
                        VideoControl.restartLiveViewImageTimeout()
                        if(configstore.Spiritlevel_UserCalibration)
                        {
                            configstore.Spiritlevel_UserCalibration = false
                            spiritModeNormal.focus = true
                        }
                        else
                        {
                            close()
                        }
                    }
                }
            }
            Image {
                id: spiritModeNormal
                anchors {
                    left: parent.left
                    leftMargin:  197 * sizeFactor
                    topMargin: 131 * sizeFactor
                    top: parent.top
                }
                source: "qrc:///icons/SpiritNormalMode.png"
                Keys.onPressed: {
                    event.accepted = false
                    if(MKeys.pressedFnAcc("POPRIGHT", event))
                    {
                        configstore.Spiritlevel_UserCalibration = true
                        spiritModeUser.focus = true
                    }
                    else if(MKeys.pressedFnAcc("POPLEFT", event))
                    {
                        configstore.Spiritlevel_UserCalibration = true
                        userButton.focus = true
                    }
                }
            }
            Rectangle {
                anchors.fill: spiritModeUser
                color: spiritModeUserMouseArea.pressed || (configstore.Spiritlevel_UserCalibration && spiritModeUser.focus) ? constants.hblOrange : "transparent"
                MouseArea{
                    id: spiritModeUserMouseArea
                    anchors.fill: parent
                    onClicked: {
                        VideoControl.restartLiveViewImageTimeout()
                        if(!configstore.Spiritlevel_UserCalibration)
                        {
                            configstore.Spiritlevel_UserCalibration = true
                            spiritModeUser.focus = true
                        }
                        else
                        {
                            close()
                        }
                    }
                }
                border.color: configstore.Spiritlevel_UserCalibration ? constants.hblOrange : "transparent"
                border.width: userButton.buttonBorderWidth
            }
            Image {
                id: spiritModeUser
                anchors.right: parent.right
                anchors.rightMargin: spiritModeNormal.anchors.leftMargin
                anchors.top: spiritModeNormal.top
                source: "qrc:///icons/SpiritUserMode.png"
                Keys.onPressed: {
                    event.accepted = false
                    if(MKeys.pressedFnAcc("POPLEFT", event))
                    {
                        configstore.Spiritlevel_UserCalibration = false
                        spiritModeNormal.focus = true
                    }
                    else if(MKeys.pressedFnAcc("POPRIGHT", event))
                    {
                        userButton.focus = true
                    }
                }
            }
            MenuButton {
                id: userButton
                anchors {
                    top: parent.top
                    topMargin: 370 * sizeFactor
                    horizontalCenter: parent.horizontalCenter
                }
                height: 117 * sizeFactor
                onClicked: {
                    VideoControl.restartLiveViewImageTimeout()
                    SpiritLevel.calibrate()
                    spiritModeUser.focus = true
                }
                maxWidth: parent.width - 20 * 2
                text: qsTr("Calibrate") + guiconfig.emptyString
                fontPixelSize: 88 * sizeFactor
                isEnabled: SpiritLevel.usingUserLevel
                highlight: focus
                borderColorHighLight: "white"
                Keys.onPressed: {
                    event.accepted = false
                    if(MKeys.pressedFnAcc("POPLEFT", event))
                    {
                        spiritModeUser.focus = true
                    }
                    else if(MKeys.pressedFnAcc("POPRIGHT", event))
                    {
                        configstore.Spiritlevel_UserCalibration = false
                        spiritModeNormal.focus = true
                    }
                    else if(MKeys.pressedFnAcc("SELECT", event))
                    {
                        userButton.buttonPressed = true
                        clicked()
                    }
                }
            }
        }
        states: [
            State {
                name: "NOTSHOWING"
                when: !popupContainer.visible && wasEnabled
                PropertyChanges { target: fadeOutParentRect; opacity: 0.0 }
                StateChangeScript {
                    script: {
                        popupContainer.focus = false;
                        wasEnabled = false
                        BodySync.currentState = notShowingBodyState
                        if (popupContainer.returnToItem !== null)
                            popupContainer.returnToItem.forceActiveFocus()
                    }
                }
            },
            State {
                name: "SHOWING"
                when: popupContainer.visible
                PropertyChanges { target: fadeOutParentRect; opacity: constants.fadeOutOpacity }
                StateChangeScript {
                    script: {
                        popupContainer.focus = true;
                        wasEnabled = true
                        BodySync.currentState = BodySync.MENU
                    }
                }
            }
        ]
        transitions: [
            Transition {
                PropertyAnimation {
                    target: fadeOutParentRect
                    properties: "opacity"
                    easing.type: Easing.OutCubic
                    duration: 500
                }
            }
        ]
    }
}
