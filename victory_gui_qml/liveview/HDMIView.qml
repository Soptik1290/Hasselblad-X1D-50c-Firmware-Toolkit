import QtQuick 2.0

import com.hasselblad.systemmanager 1.0
import com.hasselblad.video 1.0
import com.hasselblad.lens 1.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.globalstateinfo 1.0

import "qrc:///components"
import "qrc:///components/buttons"
import "qrc:///components/controls"

import "qrc:/scripts/commonfunc.js" as Cmn
import "qrc:///scripts/Keys.js" as MKeys

Rectangle {
    objectName: "HDMIView_root"
    color: "black"
    focus: true
    property bool isVideo: System.camera_mode === System.CameraModeVideo
    property bool isTechCam: (configstore.CameraType !== Config.CameraTypeHsystem && !guiconfig.isWedge)
    property real sizeFactor: 640 / 1024

    MouseArea {
        anchors.fill: parent
        onClicked: {}
        onDoubleClicked: {}
        onPressAndHold: {}
    }

    Loader {
        id: popup
        objectName: "HDMIView_popupLoader"
        asynchronous: false
        anchors.fill: parent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        onLoaded: popup.item.forceActiveFocus()
        z:10
    }

    ExposureButton {
        id: exposureButton
        z: 1
        isVisible: true
        x: -width
        canDrag: true
        onDragCompleted: {
            Cmn.exposureButtonPos = Qt.point(x,y)
            console.log("saved button position to", x, ":", y)
        }
        Component.onCompleted: {
            if(Cmn.exposureButtonPos.x < 0)
                Cmn.exposureButtonPos = Qt.point(constants.exposureButtonMargin,
                                                 constants.exposureButtonOffset + constants.exposureButtonMargin)
            x = Cmn.exposureButtonPos.x
            y = Cmn.exposureButtonPos.y
        }
        minDragY: 90//manualFocusIndicator.y + manualFocusIndicator.height
        maxDragY: parent.height - 55//imageLeftIndicator.y
    }

    ShutterSpeedControl {
        id: shutterSpeedSetting
        visible: Camera.canShow & Camera.PropTV && (cambody.capabilities & Cambody.CapabilityGuiExposure) !== 0
        forceHighlight: shutterSpeedMouseArea.containsPress
        outlineText: ((Camera.canChange & Camera.PropTV) === 0)
        shutterSpeedValue: cambody.TV_out_of_range ? "--" : cambody.shutterSpeed

        anchors.top: parent.top
        anchors.topMargin: constants.cameraViewLineTopBottomMargin + 23
        anchors.right: parent.right
        anchors.rightMargin: constants.cameraViewMargin

        MouseArea {
            id: shutterSpeedMouseArea
            anchors.fill: parent
            onClicked: {
                popup.setSource("qrc:/components/controls/PopoverShutterSpeed.qml", { "popupAnchor.leftMargin": root.width * 0.4})
                popup.active = true
                popup.forceActiveFocus()
            }
        }
    }

    BatteryIndicatorScaled {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: constants.cameraViewMargin + 8
            rightMargin: constants.cameraViewMargin
        }
        batteryWidth: 19
        height: 43
    }

    Keys.onReleased: commonKeyHandleReleased(event)

    function zoom()
    {
        if (VideoControl.videoMode === VideoControl.View)
        {
            VideoControl.zoomPoint = Qt.point(0.5, 0.5)
            console.log("Switching to zoom mode, at:", VideoControl.zoomPoint)
            VideoControl.setZoomState(true)
        }
        else if (VideoControl.videoMode === VideoControl.Zoom)
        {
            console.log("Switching to liveview mode")
            VideoControl.setZoomState(false)
        }
    }

    /* This view will (for most cases of HDMI) not have focus since since changing HDMI overlays needs to be handled
       in EVFWindow. This means that Keys.onPressed will not be called here. */
    Keys.onPressed: {
        if(!isVideo && (configstore.CameraType !== Config.CameraTypeHsystem) && MKeys.pressedFnAcc("CROSS", event))
        {
            // Exit
            Camera.setLiveViewState(false)
        }
        else if(!isVideo && (VideoControl.videoMode !== VideoControl.Zoom) && MKeys.pressedFnAcc("SQUARE", event))
        {
            // Increase overlay index. Call signal defined in main
            nextOverlay()
        }
        else if(MKeys.pressedFnAcc("STAR", event))
        {
            // 100% Zoom in/out
            zoom()
        }
        else if(isVideo && (configstore.CameraType !== Config.CameraTypeHsystem) && MKeys.pressedFnAcc("CROSS", event))
        {
            // Next valid Shutterspeed value
            var tvup = cambody.TV
            tvup = tvup + configstore.CustomOption_StepsInc
            if(tvup > Lens.TV_max)
            {
                tvup = Lens.TV_max
            }
            cambody.TV = tvup
        }
        else if(isVideo && (configstore.CameraType !== Config.CameraTypeHsystem) && MKeys.pressedFnAcc("SQUARE", event))
        {
            // Previous valid Shutterspeed value
            var tvdown = cambody.TV
            tvdown = tvdown - configstore.CustomOption_StepsInc
            var tvmin = Math.max(suc.TV_min, 60)
            if(tvdown < tvmin)
            {
                tvdown = tvmin
            }
            cambody.TV = tvdown
        }
        else if ((configstore.CameraType !== Config.CameraTypeHsystem) && isVideo &&
                 (MKeys.pressedFnAcc("MENU", event) || MKeys.pressedFnAcc("PLAY", event))) {
            //Let touch window handle these keys in hdmi liveview + video mode
            event.accepted = false
        }
        else
        {
            event.accepted = true
        }
    }

    Text {
        id: topHeader
        text: qsTr("HDMI LIVE VIEW") + guiconfig.emptyString
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: constants.headerVerticalOffset
        }
        color: constants.dialogHeaderColor
        font {
            pixelSize : constants.headerTextSize
            capitalization: Font.AllUppercase
            family: constants.menuItemFontName
        }
    }

    RecordingIndicator {
        id: recIndicator
        anchors {
            left: parent.left
            top: parent.top
            topMargin: 48 * sizeFactor
            leftMargin: 21 * sizeFactor
        }
    }

    RecordingTime {
        visible: recIndicator.visible
        anchors {
            right: parent.right
            rightMargin: 29 * sizeFactor
            bottom: parent.bottom
            bottomMargin: 11 * sizeFactor
        }
    }

    RecordingButton {
        id: recordingButton
        visible: (configstore.CameraType === Config.CameraTypeFlashsync) &&
                 System.camera_mode === System.CameraModeVideo &&
                 (VideoControl.videoMode === VideoControl.View || VideoControl.videoMode === VideoControl.Record)
        anchors {
            left: parent.left
            leftMargin: 5 * sizeFactor
            bottom: parent.bottom
            bottomMargin: 11 * sizeFactor
        }
    }

    ConfirmationButtons {
        id: confirmButtons
        color: root.color
        property bool isZoom: (VideoControl.videoMode === VideoControl.Zoom)
        property string lastTextVideoStr: isTechCam ? "+" : (isZoom ? "" : qsTr("Display") + guiconfig.emptyString)
        property string lastTextCameraStr: isZoom ? "" : (qsTr("Display") + guiconfig.emptyString)
        transparentBackground: true
        sideOriented: guiconfig.isWedge
        firstText: GlobalStateInfo.afSelectionActive ? qsTr("Reset") + guiconfig.emptyString :
                   isVideo && isTechCam ? "-" :
                   (!isVideo && (isTechCam || guiconfig.isWedge)) ? qsTr("Exit") + guiconfig.emptyString:
                                                                                       ""
        middleText: GlobalStateInfo.afSelectionActive ? (qsTr("Select") + guiconfig.emptyString) :
                    VideoControl.videoMode !== VideoControl.Record ? (qsTr("Zoom") + guiconfig.emptyString) : ""
        lastText: GlobalStateInfo.afSelectionActive ? (qsTr("AF Point Size") + guiconfig.emptyString) :
                  isVideo ? lastTextVideoStr : lastTextCameraStr
        // Workaround:
        // Just setting font.bold to true when isVideo does not work, since when font.bold is false
        // the font is shown as bold anyway... font.bold thus have to be undefined to be shown as non bold. QML does not allow
        // us to set any bool property to be set to undefined...
        // The state machine below works though:
        Item {
            states: [
                State {
                    name: ""
                    when: !(isVideo && isTechCam)
                },
                State {
                    when: isVideo && isTechCam
                    PropertyChanges { target: confirmButtons; firstTextBold: true; lastTextBold: true}
                }
            ]
        }
    }

    Image {
        id: touchIcon
        source: "qrc:///icons/generalSettingsTouch.png"
        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: isTechCam ? 40 : 0
            left: parent.left
            leftMargin: 20
        }
        visible: tpLabel.visible
    }
    Text {
        id: tpLabel
        objectName: "tpLabel"
        text: qsTr("Touchpad") + guiconfig.emptyString
        color: constants.dialogButtonTextColor
        font.pixelSize: 45
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: isTechCam ? 40 : 0
        anchors.left: touchIcon.right
        anchors.leftMargin: 10
        visible: tpLoader.active && tpLoader.item !== null &&
                 (tpLoader.item.inZoomMode || (guiconfig.isWedge && configstore.hdmi_tp_move_focus && tpLoader.item.inFocusMode))
    }

    Loader {
        objectName: "hdmiTouchpadLoader"
        id: tpLoader
        anchors.fill: parent
        active: !System.isTethered &&
                !haveHalfPress && !Camera.inSession &&
                !(configstore.selfTimerActive && Camera.selfTimerCountDown > 0) &&
                configstore.ExpMode !== Config.ExpMode_ManualQuick
        visible: active
        asynchronous: true
        focus: active
        source: "qrc:///liveview/Touchpad.qml"
        onActiveChanged: console.log("HDMI touchpad activate", active)
        onLoaded: {
            item.initValues()
            item.isInHDMI = true
        }
    }

}
