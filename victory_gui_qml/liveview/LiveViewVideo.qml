import QtQuick 2.5
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.storage 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.lens 1.0
import com.hasselblad.settings 1.0

import "qrc:///components"
import "qrc:///components/controls"
import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys
import "qrc:/components/popups"

// To be able to swipe the menu to the right to get rid of it
FocusScope {
    objectName: "LiveViewVideo_root"
    id: root
    focus: true
    property real sizeFactor: Math.min(width / 1024.0, height / 728.0)

    // TODO: mute should reflect if mute icon should be visible
    property bool mute: false
    signal recordStopped()
    property real screenRatio: width / height
    property int textSize: constants.evfTextSize * sizeFactor
    property bool isInHDMI: false
    property bool isInHDMIonA6D: isInHDMI && guiconfig.isA6D
    property bool iconsVisible: false

    function resetOverlay()
    {
        liveViewOverlayState.resetOverlay()
    }
    function setNextOverlay()
    {
        liveViewOverlayState.setNextOverlay()
    }

    function setPrevOverlay()
    {
        liveViewOverlayState.setPrevOverlay()
    }

    function liveViewSwitch(mouse)
    {
        console.log("liveViewSwitch", lvArea.enabled)
        if (System.camera_mode === System.CameraModeVideo)
        {
            if (VideoControl.videoMode === VideoControl.View)
            {
                VideoControl.zoomPoint = Qt.point(mouse.x / root.width, (mouse.y + topRect.height) / root.height)
                console.log("Switching to zoom mode, at:", VideoControl.zoomPoint)
                VideoControl.setZoomState(true)
            }
            else if (VideoControl.videoMode === VideoControl.Zoom)
            {
                console.log("Switching to liveview mode")
                VideoControl.setZoomState(false)
            }
        }
    }

    Loader {
        id: popup
        objectName: "LiveViewVideo_popupLoader"
        asynchronous: false
        anchors.fill: parent
        onLoaded: popup.item.forceActiveFocus()
        active: false
        z:10

        Connections {
            target: popup.item
            onVisibleChanged: {
                if (popup.item == null || !popup.item.visible)
                {
                    root.forceActiveFocus()
                    popup.active = false
                    popup.source = ""
                }
            }
        }
    }



    MouseArea {
        id: lvArea
        onPressAndHold: liveViewSwitch(mouse)
        onDoubleClicked: liveViewSwitch(mouse)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: (VideoControl.videoMode === VideoControl.Zoom) ? parent.top : topRect.bottom
        anchors.bottom: (VideoControl.videoMode === VideoControl.Zoom) ? parent.bottom : bottomRect.top
        onPressed: zoomIndicator.startZoomTimer()
        onReleased: zoomIndicator.startZoomTimer()
        enabled: true
    }

    // Top and bottom rectangles should only be visible for screen ratio 4:3
    // Top rectangle
    Rectangle {
        id: topRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 96 * sizeFactor
        color: "black"
        visible: (VideoControl.videoMode !== VideoControl.Zoom) && (screenRatio < 1.4)
    }

    // Bottom rectangle
    Rectangle {
        id: bottomRect
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 96 * sizeFactor
        color: "black"
        visible: (VideoControl.videoMode !== VideoControl.Zoom) && (screenRatio < 1.4)
    }

    // AE-L Lock indicator
    RoundedTextIndicator {
        id: aeLock
        visible: cambody.AEL && !isInHDMIonA6D
        text: "AE-L"
        width: 93 * sizeFactor
        sizeFactor: root.sizeFactor
        anchors {
            top: topRect.bottom
            left: parent.left
            leftMargin: sizeFactor * 22
            topMargin: sizeFactor * 22
        }
    }


    BracketedCameraControl {
        id: wb_image_hdmi
        visible: Camera.canShow & Camera.PropWBMode && isInHDMI && !isInHDMIonA6D
        allowHighligtBracket: false
        symbol: Camera.WBMode === 1  ? "qrc:///icons/WBal_Auto.png"
                  : Camera.WBMode === 2  ? "qrc:///icons/WBal_Daylight.png"
                  : Camera.WBMode === 10 ? "qrc:///icons/WBal_Cloudy.png"
                  : Camera.WBMode === 3  ? "qrc:///icons/WBal_Tungsten.png"
                  : Camera.WBMode === 5  ? "qrc:///icons/WBal_Flash.png"
                  : Camera.WBMode === 11 ? "qrc:///icons/WBal_Shade.png"
                  : Camera.WBMode === 4  ? "qrc:///icons/WBal_Fluor.png"
                  : Camera.WBMode === 6  ? "qrc:///icons/WBal_Empty.png"
                  : "qrc:///icons/WBal_Unknown.png";

        showBracket: Camera.canChange & Camera.PropWBMode

        anchors {
            left: parent.left
            leftMargin: 34 * sizeFactor
            verticalCenter: topRect.verticalCenter
        }

        Text{
            visible: (Camera.WBMode === 6) && !isInHDMIonA6D
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 16
            color: constants.popupTextColor
            text: configstore.WBManualTemp// + (configstore.WBManualTemp < 10000 ? " " : "") + "K"
            font.pixelSize: 32
            font.bold: false
        }
    }

    Rectangle {
        id: wb_background
        visible: false
        color: constants.hblOrange
        z: 1
        anchors.fill: wb_image
    }

    SequentialAnimation {
        id: wb_animation
        PauseAnimation { duration: 100 }
        PropertyAction { target: wb_background; property: "visible"; value: false }
    }

    Image {
        id: wb_image
        scale: root.width / 640
        property bool show_text: Camera.WBMode === 6
        visible: Camera.canShow & Camera.PropWBMode &&!isInHDMI
        z:2
        source: Camera.WBMode === 1 ? "qrc:///icons/WB_auto_video.png"
                  : Camera.WBMode === 2  ? "qrc:///icons/WB_daylight_video.png"
                  : Camera.WBMode === 10 ? "qrc:///icons/WB_cloudy_video.png"
                  : Camera.WBMode === 3  ? "qrc:///icons/WB_tungsten_video.png"
                  : Camera.WBMode === 5  ? "qrc:///icons/WB_flash_video.png"
                  : Camera.WBMode === 11 ? "qrc:///icons/WB_shade_video.png"
                  : Camera.WBMode === 4  ? "qrc:///icons/WB_fluor_video.png"
                  : Camera.WBMode === 6  ? "qrc:///icons/WB_empty_video.png"
                  : "qrc:///icons/WB_unknown_video.png"

        anchors {
            left: parent.left
            leftMargin: 5 * sizeFactor + (wb_image.scale - 1) * wb_image.width / 2
            verticalCenter: topRect.verticalCenter
        }

        Text{
            visible: parent.show_text
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 12
            color: constants.popupTextColor
            text: configstore.WBManualTemp
            font.pixelSize: 22
            font.bold: false
        }

        MouseArea {
            id: wb_mousearea
            enabled: parent.visible
            anchors {
                left: parent.left
                leftMargin: -parent.anchors.leftMargin
                top: parent.top
                topMargin: -parent.anchors.topMargin
            }
            width: parent.width * 2
            height: parent.height * 2

            //Use onClicked since touch detection is really bad for containsPress. The downside
            //with onClicked is that the orange background isn't shown when pressed so we use a
            //animation to show the background for a short while instead.
            onClicked: {
                wb_background.visible = true
                wb_animation.start()
                popup.setSource("qrc:///components/popups/PopoverWhiteBalance.qml", { "popupAnchor.leftMargin": root.width * 0.4})
                popup.active = true
                popup.forceActiveFocus()
            }
        }
    }

    RecordingIndicator {
        id: recordInd
        anchors {
            left: isInHDMI ? wb_image_hdmi.right : wb_image.right
            verticalCenter: topRect.verticalCenter
            leftMargin: 21 * sizeFactor
        }
    }

    Text {
        objectName: "LiveViewVideo_iso"
        visible: !isInHDMIonA6D
        text: "ISO " + guiconfig.fromIsoVal(Camera.iso)
        anchors.verticalCenter: recordInd.verticalCenter
        anchors.verticalCenterOffset: (height - baselineOffset) / 2
        anchors.right: battery.left
        anchors.rightMargin: 35 * sizeFactor
        // Until we find out how this can work with all layers of MouseArea, just let the color be white:
        color: "white"
//        color: isoMouseArea.pressed && isoMouseArea.containsMouse ? constants.highlightColor : "white"
        font.pixelSize: 64 * sizeFactor
        font.family: constants.cameraControlTextFontName
        style: Text.Outline
        styleColor: "black"
        MouseArea {
            id: isoMouseArea
            anchors.fill: parent
            anchors.margins: -20 * sizeFactor
            onClicked: {
                popup.sourceComponent = popupISO
                popup.active = true
                popup.forceActiveFocus()
            }
            preventStealing: true
        }
    }

    Component {
        id: popupISO
        PopupListSelector {
            objectName: "popupISO"
            popupAnchor.leftMargin: root.width / 2
            isToLeft: false
            model: Settings.isoValues
            currentlySelectedValue: guiconfig.fromIsoVal(Camera.iso)

            onSelectedValueChanged: {
                Camera.iso = guiconfig.toIsoVal(value)
            }
        }
    }

    BatteryIndicatorScaled {
        id: battery
        visible: !isInHDMIonA6D
        anchors {
            verticalCenter: recordInd.verticalCenter
            right: parent.right
            rightMargin: 34* sizeFactor
        }
        isOutlined: true
        lineWidth: 4 * sizeFactor
        batteryWidth: 31 * sizeFactor
        height: 67 * sizeFactor
        sizeFactor: root.sizeFactor
    }

    RecordingButton {
        id: recordingIcon
        visible: iconsVisible && !no_storage.visible && (VideoControl.videoMode !== VideoControl.Zoom)
        anchors {
            left: parent.left
            leftMargin: 5 * sizeFactor
            verticalCenter: bottomRect.verticalCenter
        }
    }

    Connections {
        target: configstore
        onExpModeChanged: {
            if(VideoControl.videoMode === VideoControl.Record)
            {
                VideoControl.setVideoRecordState(false)
            }
        }
    }

    function mediaMissing() {
        if (configstore.Video_Quality === Config.RawVideo)
            return ContentModel.card0Status !== ContentModel.STORAGE_ACTIVE
        if (configstore.storage_mode !== Config.StorageBackup)
            return (ContentModel.card0Status === ContentModel.STORAGE_ABSENT) && (ContentModel.card1Status === ContentModel.STORAGE_ABSENT)
        else
            return (ContentModel.card0Status === ContentModel.STORAGE_ABSENT) || (ContentModel.card1Status === ContentModel.STORAGE_ABSENT)
    }

    function mediaFull() {
        return (!mediaMissing() && ContentModel.exposuresLeft === 0)
    }

    Text {
        id: no_storage
        visible: mediaMissing() || mediaFull()
        text: mediaFull() ? qsTr("Storage Media Full") : qsTr("Storage Media Missing") + guiconfig.emptyString
        color: "white"
        font.pixelSize: 64 * sizeFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: bottomRect.verticalCenter
        anchors.verticalCenterOffset: (height - baselineOffset) / 2
        style: Text.Outline
        styleColor: "black"
    }

    Text {
        visible: !no_storage.visible && ((cambody.capabilities & Cambody.CapabilityGetAV) !== 0 || (cambody.capabilities & Cambody.CapabilityGetTV) !== 0) && !isInHDMIonA6D
        id: apertureShutterSpeedText
        text: ((cambody.capabilities & Cambody.CapabilityGetAV) !== 0 ?
            ("f/" + (cambody.AV_out_of_range ? "--" : cambody.aperture)) : "")  +
              ((cambody.capabilities & Cambody.CapabilityGetAV) !== 0 && (cambody.capabilities & Cambody.CapabilityGetTV) !== 0 ? " ∙ " : "") +
              ((cambody.capabilities & Cambody.CapabilityGetTV) !== 0 ? (cambody.TV_out_of_range ? "--" : cambody.shutterSpeed) : "")
        color: "white"
        font.pixelSize: 64 * sizeFactor
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: bottomRect.verticalCenter
            verticalCenterOffset: 11 * sizeFactor
        }
        font.family: constants.cameraControlTextFontName
        style: Text.Outline
        styleColor: "black"
    }

    RecordingTime {
        visible: /*recordInd.visible && */ !no_storage.visible
        anchors {
            verticalCenter: isInHDMIonA6D ? undefined : apertureShutterSpeedText.verticalCenter
            left: isInHDMIonA6D ? recordInd.right : undefined
            leftMargin: isInHDMIonA6D ? 29 * sizeFactor : 0
            top: isInHDMIonA6D ? recordInd.bottom : undefined
            topMargin: isInHDMIonA6D ? 29 * sizeFactor : 0
            right: isInHDMIonA6D ? undefined : parent.right
            rightMargin: isInHDMIonA6D ? 0 : 29 * sizeFactor
        }
    }

    Image {
        id: muteImage
        source: "qrc:///icons/Mute.png"
        anchors {
            left: parent.left
            top: topRect.bottom
            leftMargin: 34 * sizeFactor
            topMargin: 34 * sizeFactor
        }
        visible: mute
    }

    IsoWBSelector {
        id: iso_wb_selector
        anchors {
            top: parent.top
            topMargin: 130 * sizeFactor
            horizontalCenter: parent.horizontalCenter
        }
        width: 492 * sizeFactor
        height: 91 * sizeFactor
    }


    // Zoom indicator

    // yOffset in percent
    readonly property real yOffset: 0.125
    Item{
        id: zoomIndicator
        anchors.right: parent.right
        anchors.rightMargin: 48 * sizeFactor
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48 * sizeFactor
        width: parent.width * constants.zoomIndicatorSizeFactor
        height: width * 9 / 16
        visible: VideoControl.videoMode === VideoControl.Zoom
        onVisibleChanged: {
            if(visible)
            {
                startZoomTimer()
            }
            else
            {
                stopZoomTimer()
            }
        }
        Behavior on opacity {
            NumberAnimation{
                from: 1
                duration: constants.fadeOutDuration
            }
        }

        function startZoomTimer()
        {
            VideoControl.restartLiveViewImageTimeout()
            opacity = 1
            if(visible)
            {
                zoomTimer.start()
            }
        }


        function stopZoomTimer()
        {
            zoomTimer.stop()
        }

        Timer {
            id: zoomTimer
            interval: constants.zoomIndicatorTimeout
            onTriggered: if(!lvArea.pressed && !GlobalStateInfo.touchpadZoomActive) zoomIndicator.opacity = 0
        }

        Connections {
            target: GlobalStateInfo
            onTouchpadZoomActiveChanged: {
                if (System.camera_mode === System.CameraModeVideo) {
                    zoomIndicator.startZoomTimer()
                }
            }
        }

        Rectangle {
            anchors.fill: zoomIndicator
            color: "black"
            opacity: 0.4
        }

        Rectangle {
            anchors.fill: zoomIndicator
            border.color: "white"
            border.width: 2
            color: "transparent"
        }

        Rectangle {
            id: zoomedImageIndicator
            color: "white"
            y: VideoControl.zoomPoint.y * (zoomIndicator.height - height)
            height: width * 3 / 4
            x: VideoControl.zoomPoint.x * (zoomIndicator.width - width)
            property real zoomIndicatorFraction : Math.min(guiconfig.fullZoomXSize / guiconfig.maxImageXSize, guiconfig.fullZoomYSize / guiconfig.maxImageYSize)
            width:(configstore.ZoomLevel === Config.LiveViewZoomLevelHalf ? 2 : 1) * zoomIndicatorFraction * zoomIndicator.width
        }
    }

    Connections {
        target: configstore
        onExpModeChanged: {
            isoWbState.closeIsoWb()
        }
    }

    Connections {
        target: System
        onTethered_modeChanged: {
            isoWbState.updateStateNames()
        }
    }

    Connections {
        target: BodySync
        onProximityDetectNearChanged: {
            isoWbState.closeIsoWb()
        }
    }

    Item {
        id: isoWbState
        property var stateNames: updateStateNames();
        property int currentState: 0
        property bool initialized: false
        state: stateNames[currentState]

        function updateStateNames() {
            stateNames = System.isTethered ? [ "none", "iso" ] : [ "none", "iso", "wb" ]
        }

        function nextIsoWbState()
        {
            var newState = currentState + 1
            if (newState >= stateNames.length)
            {
                newState = 0;
            }
            currentState = newState
            console.log("state: ", state)
        }
        function closeIsoWb()
        {
            currentState = 0;
        }
        function isoWbActive()
        {
            return (state === "iso") || (state === "wb")
        }

        states: [
            State {
                name: "none"
                StateChangeScript {
                    script: {
                        //Do not set bodySync state when creating component. (Start state is "none")
                        if (!isoWbState.initialized) {
                            isoWbState.initialized = true
                        } else {
                            // It worked very bad to set BodySync.currentState in PropertyChanges, so we set it in this script instead
                            BodySync.currentState = BodySync.MAIN
                        }
                    }
                }
            },
            State {
                name: "iso"
                PropertyChanges { target: iso_wb_selector; showIsoList: true }
                StateChangeScript {
                    script: {
                        // It worked very bad to set BodySync.currentState in PropertyChanges, so we set it in this script instead
                        BodySync.currentState = BodySync.MENU
                    }
                }
            },
            State {
                name: "wb"
                PropertyChanges { target: iso_wb_selector; showWbList: true }
                StateChangeScript {
                    script: {
                        // It worked very bad to set BodySync.currentState in PropertyChanges, so we set it in this script instead
                        BodySync.currentState = BodySync.MENU
                    }
                }
            }
        ]
    }

    ZoomCalc {
        id: zoomCalc
    }

    // No effect to change VideoControl.zoomPoint when LiveView already running.
    // Let this be here until it works, then uncomment

    Flickable{
        id: zoomFlick

        // NOTE: The following enabler makes it possible to test without obstructing for a normal user.
        // Press 5 times on "Firmware version" in about menu to activate


        visible: zoomIndicator.visible
        anchors.fill: parent
        contentWidth: flickItem.width
        contentHeight: flickItem.height
        boundsBehavior: Flickable.StopAtBounds
        property bool updateAllowed: true
        onVisibleChanged: {
            if(visible)
            {
                updateContentFromZoomPoint()
            }
        }

        function updateContentFromZoomPoint() {
            updateAllowed = false
            contentY = VideoControl.zoomPoint.y * (contentHeight - zoomFlick.height)
            contentX = VideoControl.zoomPoint.x * (contentWidth - zoomFlick.width)
            updateAllowed = true
        }

        onContentXChanged: {
            if(updateAllowed && !GlobalStateInfo.touchpadZoomActive)
            {
                var newY = contentY / (contentHeight - zoomFlick.height)
                var newX = contentX / (contentWidth - zoomFlick.width)
                zoomCalc.setZoomPoint(Qt.point(newX, newY))
                zoomIndicator.startZoomTimer()
            }
        }

        onContentYChanged: {
            if(updateAllowed && !GlobalStateInfo.touchpadZoomActive)
            {
                var newY = contentY / (contentHeight - zoomFlick.height)
                var newX = contentX / (contentWidth - zoomFlick.width)
                zoomCalc.setZoomPoint(Qt.point(newX, newY))
                zoomIndicator.startZoomTimer()
            }
        }
        Item{
            id: flickItem
            width: guiconfig.maxImageXSize
            height: width * 9 / 16
        }

        MouseArea {
            id: flickClickArea
            onPressAndHold: liveViewSwitch(mouse)
            onDoubleClicked: liveViewSwitch(mouse)
            anchors.fill: parent
        }

    }

    // End zoom indicator

    Text {
        visible: guiconfig.isWedge && (VideoControl.videoMode === VideoControl.Off) && !Camera.inSession
        anchors.centerIn: parent
        width: parent.width - 2 * 16 * sizeFactor
        color: constants.cameraViewNormalTextColor
        text: (!configstore.eshutter && Lens.lens_family === Lens.NoLens) ? qsTr("No lens detected") + guiconfig.emptyString :
                                                                            qsTr("Half-press for Live View") + guiconfig.emptyString
        style: Text.Outline
        styleColor: "black"
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: textSize
    }

    ConfirmationButtons {
        visible: !guiconfig.isWedge && !no_storage.visible && !isInHDMI && (configstore.CameraType !== Config.CameraTypeHsystem)
        transparentBackground: true
        lastText: "+"
        firstText: "-"
        sideOriented: false
        firstTextBold: true
        lastTextBold: true
    }

    GridOverlay {
        anchors.fill: isInHDMI ? parent : lvArea
        id: grid
        visible: false
        fadeTopBottom: isInHDMI
    }

    Keys.onPressed: {
        if (event.isAutoRepeat)
        {
            event.accepted = false
        }
        else
        {
            if(MKeys.pressedFnAcc("ISO_WB", event) || (isoWbState.isoWbActive() && MKeys.pressedFnAcc("STAR", event)))
            {
                isoWbState.nextIsoWbState()
            }
            else if(MKeys.pressedFnAcc("STAR", event) || MKeys.pressedFnAcc("ZOOM_IN", event))
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
            else if((VideoControl.videoMode === VideoControl.Zoom) && MKeys.pressedFnAcc("HALFPRESS", event))
            {
                console.log("Switching to liveview mode")
                VideoControl.setZoomState(false)
            }
            else if(isoWbState.isoWbActive() && (MKeys.pressedFnAcc("AE_L", event) || MKeys.pressedFnAcc("AF_D", event) || MKeys.pressedFnAcc("HALFPRESS", event)))
            {
                isoWbState.closeIsoWb()
            }
            else if (isoWbState.isoWbActive() && MKeys.pressedFnAcc("AF_MF", event))
            {
                // Prevent key to progress further down the line
            }
            else if((configstore.CameraType !== Config.CameraTypeHsystem) && !guiconfig.isWedge && MKeys.pressedFnAcc("CROSS", event))
            {
                // Next valid iso value
                var tvup = cambody.TV
                tvup = tvup + configstore.CustomOption_StepsInc
                if(tvup > Lens.TV_max)
                {
                    tvup = Lens.TV_max
                }
                cambody.TV = tvup
            }
            else if((configstore.CameraType !== Config.CameraTypeHsystem) && !guiconfig.isWedge && MKeys.pressedFnAcc("SQUARE", event))
            {
                // Previous valid iso value
                var tvdown = cambody.TV
                tvdown = tvdown - configstore.CustomOption_StepsInc
                var tvmin = Math.max(suc.TV_min, 60)
                if(tvdown < tvmin)
                {
                    tvdown = tvmin
                }
                cambody.TV = tvdown
            }
            else if((VideoControl.videoMode !== VideoControl.Zoom) && MKeys.pressedFnAcc("SQUARE", event))
            {
                // Next overlay
                setNextOverlay()
            }
        }
    }

    Item {

        id: liveViewOverlayState
        property var stateNames: [ "Natural", "Grid" /*, "Info", "Histogram" */];
        property int startIndex: 0
        state: stateNames[configstore.LiveVideoOverlayIndex]


        function resetOverlay()
        {
            configstore.LiveVideoOverlayIndex = startIndex
        }

        function setNextOverlay()
        {
            var nextIndex = configstore.LiveVideoOverlayIndex
            if (nextIndex >= (stateNames.length - 1))
            {
                nextIndex = 0;
            }
            else
            {
                nextIndex++
            }
            configstore.LiveVideoOverlayIndex = nextIndex
        }

        function setPrevOverlay()
        {
            var nextIndex = configstore.LiveVideoOverlayIndex
            if (0 === nextIndex)
            {
                nextIndex = stateNames.length - 1;
            }
            else
            {
                nextIndex--;
            }
            configstore.LiveVideoOverlayIndex = nextIndex
        }

        states: [
            State {
                name: "Natural"
            },
            State {
                name: "Grid"
                PropertyChanges { target: grid; visible: (isoWbState.state === "none") && (VideoControl.videoMode !== VideoControl.Off) && (VideoControl.videoMode !== VideoControl.Zoom)}
            },
            State {
                name: "Info"
            },
            State {
                name: "Histogram"
            }
        ]

    }
}
