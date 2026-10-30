import QtQuick 2.0

import com.hasselblad.storage 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.video 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.settings 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.lens 1.0

import "qrc:///"
import "qrc:///components"
import "qrc:///components/controls"

import "qrc:///scripts/Keys.js" as MKeys
import "qrc:///scripts/commonfunc.js" as Cmn

FocusScope {
    objectName: "LiveViewOverlay_root"
    id: root
    // Dependent on height
    property real sizeFactor: Math.min(width / 1024.0, height / 728.0)
    property int textSize: constants.evfTextSize * sizeFactor
    property bool inActiveWindow: false //If this instance used in active window. Workaround for always being loaded in EVFWindow.
    focus: true
    // Show info or not (ISO/WB and focus will always be visible):
    property bool infoVisible: false
    property bool manualFocusIndicatorVisible: true
    property alias zoomIndicatorVisible: zoomIndicator.visible
    property bool dragAreaPressed: false
    property bool isInHDMI: false
    property bool isBTMode: cambody.isBMode || cambody.isTMode
    property bool showTimer: 0 !== Camera.selfTimerCountDown ||  0 !== Camera.intervalTimerCountDown || (cambody.exposing && (isBTMode || (!isBTMode && Camera.exposureTimerCount)))
    property bool overlayOff: GlobalStateInfo.afSelectionActive || showTimer || VideoControl.videoMode === VideoControl.Zoom || configstore.ExpMode === Config.ExpMode_ManualQuick || (guiconfig.isA6D && isInHDMI)
    property bool spiritLevelToggle: false
    property bool allowSpiritLevel: guiconfig.isCFV || guiconfig.isWedge || ((suc.cambody_attached && configstore.CameraType === Config.CameraTypeHsystem) && !guiconfig.isA6D)

    function closeIsoWb()
    {
        isoWbState.closeIsoWb()
    }

    function startZoomTimer()
    {
        zoomIndicator.startZoomTimer()
    }


    function stopZoomTimer()
    {
        zoomIndicator.stopZoomTimer()
    }


    function zoom(zoomX, zoomY)
    {
        if (System.camera_mode === System.CameraModeImage) {
            if (VideoControl.videoMode === VideoControl.View) {
                VideoControl.zoomPoint = Qt.point(zoomX / root.width, zoomY / root.height)
                console.log("Switching to zoom mode, at:", VideoControl.zoomPoint)
                VideoControl.setZoomState(true)
                BodySync.currentState = "MENU"
            } else if (VideoControl.videoMode === VideoControl.Zoom) {
                console.log("Switching to liveview mode")
                VideoControl.setZoomState(false)
                BodySync.currentState = "MAIN"
            }
        }
    }

    Timer {
        id: mfTimer
        running: false
        interval: constants.afSelectionLongPressThreshold
        repeat: false
        onTriggered: {
            // Timer timed out, thus this is a long press
            //
            if (VideoControl.videoMode === VideoControl.Zoom)
            {
                VideoControl.setZoomState(false)
                BodySync.currentState = "MAIN"
            }
            GlobalStateInfo.afSelectionActive = true
        }
    }


    // Representing the area where live view will be seen. For other items to anchor to
    // Width and height ratio should always be 4:3
    Item {
        id: liveViewVideoArea
        width: (parent.width / parent.height) > (4 / 3) ? parent.height * 4 / 3 : parent.width
        height: (parent.width / parent.height) > (4 / 3) ? parent.height : parent.width * 3 / 4
        anchors.centerIn: parent

        CropOverlay {
            id: crop
            anchors.fill: parent
            visible: parent.visible && !zoomIndicator.visible
            onVisibleChanged: {
                if (visible) {
                    calcCropping(configstore.aspectRatio)
                }
            }
        }
    }

    GridOverlay {
        anchors.fill: liveViewVideoArea
        id: grid
        visible: false
        property real defaultBottomMargin: ((cambody.capabilities & Cambody.CapabilityGetAV) !== 0) || ((cambody.capabilities & Cambody.CapabilityGetTV) !== 0) ? sizeFactor * 82 : 0
        internalBottomMargin: (defaultBottomMargin > crop.cropHeight) ? (defaultBottomMargin - crop.cropHeight) : 0
        anchors {
            topMargin: crop.cropHeight
            bottomMargin: crop.cropHeight
            leftMargin: crop.cropWidth
            rightMargin: crop.cropWidth
        }
    }

    AFIndicator {
        anchors.fill: liveViewVideoArea
        visible: guiconfig.isWedge &&
                 !GlobalStateInfo.afSelectionActive &&
                 (VideoControl.videoMode === VideoControl.View ||
                  VideoControl.videoMode === VideoControl.AF) &&
                 ((Lens.lens_family === Lens.HCCLens) || (Lens.lens_family === Lens.XCLens))
        sizeFactor: root.sizeFactor

    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: sizeFactor * constants.liveViewBorderNormalMargin
        anchors.topMargin: sizeFactor * constants.liveViewBorderNormalMargin
        visible: root.infoVisible && liveViewOverlayState.state !== "SpiritLevel"

        spacing: sizeFactor * 10

        Image {
            id: wifiIcon
            visible: configstore.WIFI_power
            source: root.sizeFactor < 1 ? "qrc:///icons/LCD_LV_WiFi.png" : "qrc:///icons/EVF_LV_WiFi.png"
        }

        FlashStatus {
            id: flashStatus
            sizeFactor: root.sizeFactor < 1 ? 1 : root.sizeFactor
            source: root.sizeFactor < 1 ? "qrc:///icons/LCD_LV_Flash.png" : "qrc:///icons/EVF_LV_Flash.png"
        }

        GPSStatus {
            iconSource: root.sizeFactor < 1 ? "qrc:///icons/LCD_LV_GPS.png" : "qrc:///icons/EVF_LV_GPS.png"
            sizeFactor: root.sizeFactor < 1 ? 1 : root.sizeFactor
            id: gpsImage
        }

    }


    // Small Self Timer Active indicator
    Item {
        id: smallSelfTimerIndicator
        visible: root.infoVisible &&
                 ((configstore.selfTimerActive && Camera.selfTimerCountDown === 0) || configstore.bracketingActive || configstore.focusBracketingActive  || configstore.intervalActive) &&
                 !cambody.exposing
        anchors {
            top: root.top
            topMargin: spiritLevel.bottomY + 15*sizeFactor
            left: parent.left
            leftMargin: sizeFactor * constants.liveViewBorderNormalMargin
        }
        width: smallSelfTimerIndicatorIcon.width * smallSelfTimerIndicatorIcon.scale + 10 * sizeFactor +
               smallLblSeconds.width + smallLblFrames.width + frame_left_bracket.width + frame_right_bracket.width
        height: smallSelfTimerIndicatorIcon.height * smallSelfTimerIndicatorIcon.scale

        Image {
            id: smallSelfTimerIndicatorIcon
            visible: (configstore.selfTimerActive || configstore.bracketingActive || configstore.focusBracketingActive  || configstore.intervalActive) && !cambody.exposing
            anchors.left: smallSelfTimerIndicator.left
            anchors.verticalCenter: smallSelfTimerIndicator.verticalCenter
            transformOrigin: Item.Left
            scale: sizeFactor < 1 ? 1 : sizeFactor
            source: {
                if(sizeFactor < 1)
                {
                    if(configstore.selfTimerActive)
                    {
                        return "qrc:///icons/LCD_LV_SelfTimer.png"
                    }
                    if(configstore.bracketingActive)
                    {
                        return "qrc:///icons/LCD_LV_Bracketing.png"
                    }
                    if(configstore.focusBracketingActive)
                    {
                        return "qrc:///icons/LCD_LV_FocusBracketing.png"
                    }
                    if(configstore.intervalActive)
                    {
                        return "qrc:///icons/LCD_LV_Interval.png"
                    }
                    else
                    {
                        return ""
                    }
                }
                else
                {
                    if(configstore.selfTimerActive)
                    {
                        return "qrc:///icons/EVF_LV_SelfTimer.png"
                    }
                    if(configstore.bracketingActive)
                    {
                        return "qrc:///icons/EVF_LV_Bracketing.png"
                    }
                    if(configstore.focusBracketingActive)
                    {
                        return "qrc:///icons/EVF_LV_FocusBracketing.png"
                    }
                    if(configstore.intervalActive)
                    {
                        return "qrc:///icons/EVF_LV_Interval.png"
                    }
                    else
                    {
                        return ""
                    }
                }
            }
        }
        Text {
            id: smallLblSeconds
            visible: !(configstore.bracketingActive || configstore.focusBracketingActive)
            anchors {
                left: smallSelfTimerIndicatorIcon.right
                leftMargin: 15*sizeFactor
                verticalCenter: smallSelfTimerIndicator.verticalCenter
                verticalCenterOffset: (height - baselineOffset) / 2
            }
            text: {
                if(configstore.selfTimerActive)
                {
                    return Settings.getDisplayValue("SelftimerDelay", configstore.SelftimerDelay)
                }
                else if(configstore.intervalActive)
                {
                    return configstore.IntervalTime
                }
                else
                {
                    return "";
                }
            }

            color: constants.cameraViewNormalTextColor
            font {
                pixelSize: textSize
                family: constants.cameraControlTextFontName
            }
            style: Text.Outline
            styleColor: "black"
        }

        Row {
            anchors.left: smallLblSeconds.right
            anchors.leftMargin: 15*sizeFactor
            anchors.verticalCenter: smallSelfTimerIndicator.verticalCenter
            spacing: 5*sizeFactor
            Bracket {
                id: frame_left_bracket
                visible: configstore.intervalActive
                width: 10 * sizeFactor
                height: 47 * sizeFactor
                borderWidth: Math.round(Math.max(1 * sizeFactor, 1))
                lineWidth: Math.round(Math.max(3 * sizeFactor, 2) + borderWidth)
            }
            Text {
                id: smallLblFrames
                anchors {
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: (height - baselineOffset) / 2
                }
                text: {
                    if(configstore.intervalActive)
                    {
                        return 255 === configstore.IntervalNumberOfShots ? '\u221e' :
                                                                           Settings.getDisplayValue("IntervalNumberOfShots", configstore.IntervalNumberOfShots)
                    }
                    else if(configstore.bracketingActive)
                    {
                        return Settings.getDisplayValue("BracketingNumberOfFrames", configstore.BracketingNumberOfFrames) - GlobalStateInfo.photosAddedCount
                    }
                    else if(configstore.focusBracketingActive)
                    {
                        if(configstore.FocusBracketingStrategy === Config.FocusBracketingToNearToInf)
                        {
                            return Math.min(Settings.getDisplayValue("FocusBracketingNumberOfFrames", configstore.FocusBracketingNumberOfFrames) - GlobalStateInfo.photosAddedCount + 1, Settings.getDisplayValue("FocusBracketingNumberOfFrames", configstore.FocusBracketingNumberOfFrames))
                        }
                        else
                        {
                            return Settings.getDisplayValue("FocusBracketingNumberOfFrames", configstore.FocusBracketingNumberOfFrames) - GlobalStateInfo.photosAddedCount
                        }
                    }
                    else
                    {
                        return "";
                    }
                }

                color: constants.cameraViewNormalTextColor
                font {
                    pixelSize: textSize
                    family: constants.cameraControlTextFontName
                }

                style: Text.Outline
                styleColor: "black"
            }
            Bracket {
                id: frame_right_bracket
                leftBracket: false
                visible: configstore.intervalActive
                width: 10 * sizeFactor
                height: 47 * sizeFactor
                borderWidth: Math.round(Math.max(1 * sizeFactor, 1))
                lineWidth: Math.round(Math.max(3 * sizeFactor, 2) + borderWidth)
            }
        }
    }

    // Large Self Timer counting and B/T counting indicator
    Row {
        anchors {
            verticalCenter: liveViewVideoArea.verticalCenter
            horizontalCenter: liveViewVideoArea.horizontalCenter
        }
        spacing: 50
        id: selfTimerIndicator
        visible: showTimer

        Image {
            id: selfTimerIndicatorIcon
            visible: 0 !== Camera.selfTimerCountDown
            scale: 0.8
            source: "qrc:///icons/Selftimer_Running.png"
        }
        Image {
            id: intervalTimerIndicatorIcon
            visible: (0 !== Camera.intervalTimerCountDown) && configstore.intervalActive
            scale: 0.8
            source: "qrc:///icons/Interval_Icon_90.png"
        }
        Image {
            id: bracketingTimerIndicatorIcon
            visible: (0 !== Camera.intervalTimerCountDown) && (configstore.bracketingActive || configstore.focusBracketingActive)
            width: selfTimerIndicatorIcon.width
            height: selfTimerIndicatorIcon.height
            source: configstore.bracketingActive ? "qrc:///icons/LargeIconBracketing.png" : "qrc:///icons/LargeIconFocusBracketing.png"
        }
        Text {
            id: lblSeconds
            anchors {
                verticalCenter: selfTimerIndicator.verticalCenter
                verticalCenterOffset: (height - baselineOffset) / 2
            }
            text: {
                if(Camera.selfTimerCountDown !== 0)
                    return Camera.selfTimerCountDown
                if(Camera.intervalTimerCountDown !== 0)
                    return Camera.intervalTimerCountDown
                if(cambody.exposing) {
                    var prepend = ""
                    if(cambody.isBMode)
                        prepend = "B "
                    if(cambody.isTMode)
                        prepend = "T "
                    return prepend + Cmn.tdur(Camera.exposureTimerCount)
                }
                return ""
            }
            color: "white"
            font.pixelSize: constants.selfTimerCountDownFontSize * sizeFactor
            font.family: constants.cameraControlTextFontName
            style: Text.Outline
            styleColor: "black"
            fontSizeMode: Text.HorizontalFit
            verticalAlignment: Text.AlignVCenter
        }
    }


    Text {
        id: noLiveViewText
        visible: guiconfig.isWedge && (VideoControl.videoMode === VideoControl.Off && Camera.pendingLiveView === Camera.PendNone) && !Camera.inSession
        anchors.centerIn: parent
        width: parent.width - 2 * 16
        color: constants.cameraViewNormalTextColor
        text: (configstore.ExpMode === Config.ExpMode_ManualQuick) ? qsTr("No Live View in MQ mode") + guiconfig.emptyString :
                                                                     (!configstore.eshutter && Lens.lens_family === Lens.NoLens) ? qsTr("No lens detected") + guiconfig.emptyString :
                                                                                                                                   qsTr("Half-press for Live View") + guiconfig.emptyString
        style: Text.Outline
        styleColor: "black"
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: textSize
    }


    // Auto ISO indicator
    RoundedTextIndicator {
        visible: root.infoVisible && guiconfig.fromIsoVal(Camera.iso) === "Auto"
        width: 110 * sizeFactor
        sizeFactor: root.sizeFactor
        anchors {
            right: iso.left
            rightMargin: sizeFactor * 7
            top: iso.top
            topMargin: -3 * sizeFactor
        }
        text: "AUTO"
    }

    Text {
        id: iso
        visible: root.infoVisible
        anchors {
            verticalCenter: battery.verticalCenter
            verticalCenterOffset: sizeFactor * 8
            right: battery.left
            rightMargin: sizeFactor * 21
        }
        text: "ISO " + (guiconfig.fromIsoVal(Camera.iso) === "Auto" ? cambody.autoIso : guiconfig.fromIsoVal(Camera.iso))
        font.pixelSize: textSize
        color: constants.cameraViewNormalTextColor
        style: Text.Outline
        styleColor: "black"
        font.family: constants.cameraControlTextFontName
    }

    BatteryIndicatorScaled {
        id: battery
        canShowBattery: root.infoVisible
        anchors {
            top: parent.top
            topMargin: sizeFactor * constants.liveViewBorderNormalMargin
            right: parent.right
            rightMargin: sizeFactor * constants.liveViewBorderNormalMargin
        }
        topHeight: 3
        topWidth: (5/23) * batteryWidth
        isOutlined: true
        batteryWidth: 20 * sizeFactor
        height: 50 * sizeFactor
        sizeFactor: root.sizeFactor
    }

    RoundedTextIndicator {
        id: manualFocusIndicator
        text: "MF"
        // Manual focus if its enabled or on wedge if a non AF capable lens is connected
        visible: root.manualFocusIndicatorVisible  && !overlayOff &&
                 (Camera.FocusMode === Config.Focus_MAN) && !guiconfig.isCFV
        sizeFactor: root.sizeFactor
        width: 64 * sizeFactor
        anchors {
            right: battery.right
            top: battery.bottom
            topMargin: 26 * sizeFactor
        }
        opacity: autoFocusIndicatorDividedScan.opacity
    }

    RoundedTextIndicator {
        id: autoFocusIndicatorDividedScan
        text: "AF"
        // Auto focus if its enabled and divided scan range is active
        visible: root.manualFocusIndicatorVisible  &&
                 !overlayOff &&
                 (Camera.FocusMode === Config.Focus_AFS) &&
                 !guiconfig.isCFV &&
                 (configstore.FocusScanRange !== 0) &&
                 Lens.has_divided_scan_range
        sizeFactor: root.sizeFactor
        width: 64 * sizeFactor
        anchors {
            right: battery.right
            top: battery.bottom
            topMargin: 26 * sizeFactor
        }
    }

    //    "Near" == 1
    //    "Far"  == 2
    Image {
        id: nearFarIndicator
        visible: root.manualFocusIndicatorVisible  &&
                         !overlayOff &&
                         !guiconfig.isCFV &&
                         (configstore.FocusScanRange !== 0) &&
                         Lens.has_divided_scan_range

        anchors {
            verticalCenter: autoFocusIndicatorDividedScan.verticalCenter
            right: autoFocusIndicatorDividedScan.left
            rightMargin: sizeFactor * 16
        }
        source:  root.sizeFactor < 1 ? (configstore.FocusScanRange === 1 ? "qrc:///icons/LCD_LV_Near.png" : "qrc:///icons/LCD_LV_Far.png") :
                                       (configstore.FocusScanRange === 1 ? "qrc:///icons/EVF_LV_Near.png" : "qrc:///icons/EVF_LV_Far.png")

        opacity: autoFocusIndicatorDividedScan.opacity
    }

    // Blink indicator when autofocus fails
    Connections {
        target: Camera

        onFindOngoingChanged: {
            if(!Camera.findOngoing &&
                    (Camera.lastAfResult !== Camera.LastAfResultFound) &&
                    (Camera.lastAfReturnStatus !== Camera.LastAfReturnStatusCanceled) &&
                    nearFarIndicator.visible)
            {
                autofocusBlinkLoop.start();
            }
        }
    }

    SequentialAnimation {
        id: autofocusBlinkLoop

        loops: constants.animationErrorBlinkLoops
        NumberAnimation {
            target: autoFocusIndicatorDividedScan
            property: "opacity"
            to: 0
            duration: constants.animationDurationBlink
            easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: constants.animationDurationBlink }
        NumberAnimation {
            target: autoFocusIndicatorDividedScan
            property: "opacity"
            to: 1
            duration: constants.animationDurationBlink
            easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: constants.animationDurationBlink }
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

    BalanceScale {
        id: balanceScale
        visible: guiconfig.isWedge && root.infoVisible && (configstore.ExpMode !== Config.ExpMode_ManualQuick) && validScale && !cambody.current_stop_down
        anchors {
            left: parent.left
            bottom: parent.bottom
            bottomMargin: 25 * sizeFactor
            leftMargin: 60 * sizeFactor
        }
        sizeFactor: root.sizeFactor
    }

    // AE-L Lock indicator
    RoundedTextIndicator {
        id: aeLock
        anchors {
            right: aperture.left
            rightMargin: 20 * sizeFactor
            verticalCenter: aperture.verticalCenter
            verticalCenterOffset: -(aperture.font.pixelSize - aperture.baselineOffset) / 2
        }
        visible: cambody.AEL && root.infoVisible
        text: "AE-L"
        width: 93 * sizeFactor
        sizeFactor: root.sizeFactor
    }

    Text {
        id: aperture
        width: 97 * root.sizeFactor
        visible: root.infoVisible && ((cambody.capabilities & Cambody.CapabilityGetAV) !== 0) && ((aperture.x + aperture.width) < imageLeftIndicator.x)
        anchors {
            right: evadjIcon.left
            rightMargin: 20 * sizeFactor
            bottom: root.bottom
            bottomMargin: 18 * sizeFactor
        }
        horizontalAlignment: Text.AlignLeft
        text: "f/" + (cambody.AV_out_of_range ? "--" : cambody.aperture)
        font.pixelSize: textSize
        color: constants.cameraViewNormalTextColor
        style: Text.Outline
        styleColor: "black"
        font.family: constants.cameraControlTextFontName
        // Workaround:
        // Just setting font.bold to true when current_stop_down is active does not work, since when font.bold is false
        // the font is shown as bold anyway... font.bold thus have to be undefined to be shown as non bold. QML does not allow
        // us to set any bool property to be set to undefined...
        // The state machine below works though:
        states: [
            State {
                name: ""
                when: !cambody.current_stop_down
            },
            State {
                when: cambody.current_stop_down
                PropertyChanges { target: aperture; font.weight: 75 }
            }
        ]
    }

    Rectangle {
        anchors.verticalCenter: aperture.verticalCenter
        anchors.verticalCenterOffset: -(aperture.font.pixelSize - aperture.baselineOffset) / 2
        anchors.horizontalCenter: root.horizontalCenter
        anchors.horizontalCenterOffset: 78 * sizeFactor
        id: evadjIcon
        width: height //41 * sizeFactor
        height: aeLock.height //41 * sizeFactor
        visible: (Camera.EVADJ !== 0) && root.infoVisible && ((evadjIcon.x + evadjIcon.width) < imageLeftIndicator.x)
        color: "white"
        radius: 4 * sizeFactor
        border.color: "black"
        border.width: 1 * sizeFactor
        Canvas {
            id: evadjIconCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext('2d')
                var lineWidth = Math.max(4 * sizeFactor, 1)
                ctx.save()
                ctx.clearRect(0, 0, width, height)
                ctx.lineWidth = lineWidth
                var styleBlack = Qt.rgba(0, 0, 0, 1)
                ctx.beginPath()
                ctx.strokeStyle = styleBlack

                ctx.moveTo(12 * sizeFactor, 7 * sizeFactor)
                ctx.lineTo(12 * sizeFactor, 19 * sizeFactor)

                ctx.moveTo(6 * sizeFactor, 13 * sizeFactor)
                ctx.lineTo(18 * sizeFactor, 13 * sizeFactor)

                ctx.moveTo(9 * sizeFactor, 34 * sizeFactor)
                ctx.lineTo(34 * sizeFactor, 9 * sizeFactor)

                ctx.moveTo(25 * sizeFactor, 30 * sizeFactor)
                ctx.lineTo(36 * sizeFactor, 30 * sizeFactor)

                ctx.stroke()
                ctx.restore()
            }

        }
        onVisibleChanged: if(visible) evadjIconCanvas.requestPaint()

    }
    RoundedTextIndicator {
        id: eShutterIcon
        anchors.top: aeLock.top
        anchors.bottom: aeLock.bottom
        anchors.left: evadjIcon.right
        anchors.leftMargin: 20 * sizeFactor
        visible: configstore.eshutter && root.infoVisible && ((eShutterIcon.x + eShutterIcon.width) < imageLeftIndicator.x)
        text: "E"
        width: height
        sizeFactor: root.sizeFactor
    }

    Text {
        id: shutterspeed
        visible: root.infoVisible && ((cambody.capabilities & Cambody.CapabilityGetTV) !== 0) && ((shutterspeed.x + shutterspeed.width) < imageLeftIndicator.x)
        anchors.verticalCenter: aperture.verticalCenter
        anchors.left: eShutterIcon.right
        anchors.leftMargin: 10 * sizeFactor
        text: getShutterSpeed()
        font.pixelSize: textSize
        color: constants.cameraViewNormalTextColor
        style: Text.Outline
        styleColor: "black"
        font.family: constants.cameraControlTextFontName
    }

    DemoModeIndicator {
        anchors {
            bottom: root.infoVisible ? imageLeftIndicator.top : parent.bottom
            right: imageLeftIndicator.right
            bottomMargin: sizeFactor * 23
        }
    }

    // Images left indicator
    Row {
        id: imageLeftIndicator
        visible: root.infoVisible
        spacing: sizeFactor * 7
        anchors {
            bottom: parent.bottom
            right: parent.right
            rightMargin: sizeFactor * 30
            bottomMargin: sizeFactor * 24
        }

        Bracket {
            id: left_bracket
            leftBracket: true
            anchors.top: parent.top
            width: 10 * sizeFactor
            height: 47 * sizeFactor
            borderWidth: Math.round(Math.max(1 * sizeFactor, 1))
            lineWidth: Math.round(Math.max(3 * sizeFactor, 2) + borderWidth)
        }

        ExposuresAvailCounter {
            id: availCounter
            // The subtraction with 0.000001 is a workaround for a bug in QML. If no such subtraction, the texts position
            // will be erroneous
            width: !showCounter ? implicitWidth - 0.000001 : Math.min(implicitWidth - 0.000001, availMaxWidth.implicitWidth)
            anchors.top: left_bracket.top
            anchors.topMargin: (font.pixelSize - baselineOffset) / 2 - 1
            enableHalfPressWarning: true
            font.pixelSize: textSize
            style: Text.Outline
            styleColor: "black"
            // The following is to get the max width for the counter
            Text {
                visible: false
                id: availMaxWidth
                text: "999"
                font.pixelSize: textSize
                style: Text.Outline
            }
        }

        Bracket {
            id: right_bracket
            leftBracket: false
            anchors.top: parent.top
            width: 10 * sizeFactor
            height: 47 * sizeFactor
            borderWidth: Math.round(Math.max(1 * sizeFactor, 1))
            lineWidth: Math.round(Math.max(3 * sizeFactor, 2) + borderWidth)
        }

    }

    function getShutterSpeed()
    {
        // Split at space
        //        console.log("speed: '" + speed + "'");
        if(cambody.TV_out_of_range)
        {
            return "--";
        }
        else
        {
            var speed = cambody.shutterSpeed
            var splitPos = speed.search(/[mh]\d/)
            if(splitPos > 0)
            {
                return speed.slice(0, splitPos + 1) + " " + speed.slice(splitPos + 1, speed.length)

            }
            else
            {
                return speed
            }
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
            if(configstore.ExpMode === Config.ExpMode_FullAuto)
            {
                if(stateNames[newState] === "iso")
                {
                    newState++
                }
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
        function nextIsoState()
        {
            var noneState = stateNames.indexOf("none")
            var isoState = stateNames.indexOf("iso")
            currentState = currentState !== noneState ? noneState : isoState
        }
        function nextWBState()
        {
            var noneState = stateNames.indexOf("none")
            var wbState = stateNames.indexOf("wb")
            currentState = currentState !== noneState ? noneState : wbState
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
                            BodySync.currentState = GlobalStateInfo.afSelectionActive ? BodySync.MENU : BodySync.MAIN
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

    SpiritLevel {
        id: spiritLevel
        visible: false
        anchors.fill: parent
        sizeFactor: root.sizeFactor
        allowCross: !(guiconfig.isWedge && isInHDMI) //Wedge hdmi use cross for "exit" button
        compactMode: true
    }

    HTS {
        id: hts
        visible: false
        anchors.fill: parent
        sizeFactor: root.sizeFactor
        onHts_attachedChanged: checkOverlay()
    }

    Rectangle {
        id: spotMeterIndicator
        property bool show: false
        anchors.centerIn: parent
        visible: guiconfig.isWedge &&
                 (Camera.canShow & Camera.PropLMMode) &&
                 (Camera.LMMode === Config.LMM_Spot) &&
                 show &&
                 !noLiveViewText.visible &&
                 !isoWbState.isoWbActive() &&
                 ((VideoControl.videoMode === VideoControl.View) || (VideoControl.videoMode === VideoControl.AF))
        color: "transparent"
        border.color: "black"
        border.width: 1
        width: 144 * sizeFactor
        height: width
        radius: width / 2
        Rectangle {
            anchors.fill: parent
            anchors.margins: parent.border.width
            color: "transparent"
            border.color: "white"
            border.width: 1.5
            radius: width / 2
            Rectangle {
                anchors.fill: parent
                anchors.margins: parent.border.width
                color: "transparent"
                border.color: "black"
                border.width: 1
                radius: width / 2
            }
        }
    }

    Loader {
        source: "qrc:///liveview/AFPointSelection.qml"
        id: aFPointSelection
        anchors.fill: liveViewVideoArea
        asynchronous: true
        active: GlobalStateInfo.afSelectionActive && root.activeFocus
        onLoaded: {
            item.forceActiveFocus()
        }

        Connections {
            target: aFPointSelection.item
            onCloseAFPointSelection: {
                GlobalStateInfo.afSelectionActive = false
                root.forceActiveFocus()
            }
        }
    }

    Item {
        id: liveViewOverlayState
        // Histogram not shown for now
        property var stateNames: [ "Natural", "Info", "Grid", "SpiritLevel" /*, "Histogram"*/, "HTS" ];
        property int startIndex: 2
        state: stateNames[configstore.LiveViewOverlayIndex]


        states: [
            State {
                name: "Natural"
            },
            State {
                name: "Grid"
                PropertyChanges { target: root; infoVisible: !overlayOff}
                PropertyChanges { target: grid; visible: (isoWbState.state === "none") && (VideoControl.videoMode !== VideoControl.Zoom) && !overlayOff}
                PropertyChanges { target: spotMeterIndicator; show: !overlayOff && (VideoControl.videoMode !== VideoControl.Zoom)}

            },
            State {
                name: "Info"
                //Note! If changing something here then add the same changes to state spiritlevel since this info should be a shown there too (#6574)
                PropertyChanges { target: root; infoVisible: !overlayOff}
                PropertyChanges { target: spotMeterIndicator; show: !overlayOff && (VideoControl.videoMode !== VideoControl.Zoom)}
            },
            State {
                name: "SpiritLevel"
                PropertyChanges { target: spiritLevel; visible: (VideoControl.videoMode !== VideoControl.Zoom) && !overlayOff}
                PropertyChanges { target: root; infoVisible: !overlayOff}
                PropertyChanges { target: spotMeterIndicator; show: !overlayOff && (VideoControl.videoMode !== VideoControl.Zoom) && !spiritLevel.popupOpen}
            },
            State {
                name: "Histogram"
                PropertyChanges { target: root; infoVisible: !overlayOff}
                PropertyChanges { target: histogram; visible: !overlayOff}
            },
            State {
                name: "HTS"
                PropertyChanges { target: root; infoVisible: !overlayOff}
                PropertyChanges { target: hts; visible: !overlayOff}
            }
        ]

        function toggleSpiritLevel() {
            if (spiritLevelToggle) {
                spiritLevelToggle = false
                state = Qt.binding(function() { return stateNames[configstore.LiveViewOverlayIndex]})
            } else {
                spiritLevelToggle = true
                liveViewOverlayState.state = "SpiritLevel"
            }
        }

    }

    // Zoom indicator
    Item{
        id: zoomIndicator
        anchors.right: liveViewVideoArea.right
        anchors.rightMargin: 30 * sizeFactor
        anchors.bottom: liveViewVideoArea.bottom
        anchors.bottomMargin: 80 * sizeFactor
        width: liveViewVideoArea.width * constants.zoomIndicatorSizeFactor
        height: liveViewVideoArea.height * constants.zoomIndicatorSizeFactor
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

        CropOverlay {
            anchors.fill: parent
            onVisibleChanged: {
                if (visible) {
                    calcCropping(configstore.aspectRatio)
                }
            }
        }

        Timer {
            id: zoomTimer
            interval: constants.zoomIndicatorTimeout
            onTriggered: if(!dragAreaPressed && !GlobalStateInfo.touchpadZoomActive) zoomIndicator.opacity = 0
        }

        Connections {
            target: GlobalStateInfo
            onTouchpadZoomActiveChanged: {
                if (System.camera_mode === System.CameraModeImage) {
                    startZoomTimer()
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
            property real zoomIndicatorFraction : Math.min(guiconfig.fullZoomXSize / guiconfig.maxImageXSize, guiconfig.fullZoomYSize / guiconfig.maxImageYSize)
            height: (configstore.ZoomLevel === Config.LiveViewZoomLevelHalf ? 2 : 1)  * zoomIndicatorFraction * zoomIndicator.height
            x: VideoControl.zoomPoint.x * (zoomIndicator.width - width)
            width: (configstore.ZoomLevel === Config.LiveViewZoomLevelHalf ? 2 : 1) * zoomIndicatorFraction * zoomIndicator.width
            Connections {
                target: VideoControl
                onZoom_pointChanged:{
                    zoomedImageIndicator.y = VideoControl.zoomPoint.y * (zoomIndicator.height - zoomedImageIndicator.height)
                    zoomedImageIndicator.x = VideoControl.zoomPoint.x * (zoomIndicator.width - zoomedImageIndicator.width)
                }
            }
        }
    }

    function resetOverlay()
    {
        if(isValidOverlay(liveViewOverlayState.startIndex))
        {
            configstore.LiveViewOverlayIndex = liveViewOverlayState.startIndex
        }
        else
        {
            setNextOverlayImpl(liveViewOverlayState.startIndex)
        }
    }

    function setNextOverlay()
    {
        setNextOverlayImpl(configstore.LiveViewOverlayIndex)
    }

    function setNextOverlayImpl(nextIndex)
    {
        if (overlayOff) {
            return
        }

        if (nextIndex >= (liveViewOverlayState.stateNames.length - 1))
        {
            nextIndex = 0;
        }
        else
        {
            nextIndex++
        }
        if(isValidOverlay(nextIndex))
        {
            configstore.LiveViewOverlayIndex = nextIndex
        }
        else
        {
            setNextOverlayImpl(nextIndex)
        }
    }

    function setPrevOverlay()
    {
        setPrevOverlayImpl(configstore.LiveViewOverlayIndex)
    }

    function setPrevOverlayImpl(nextIndex)
    {
        if (0 === nextIndex)
        {
            nextIndex = liveViewOverlayState.stateNames.length - 1;
        }
        else
        {
            nextIndex--;
        }
        if(isValidOverlay(nextIndex))
        {
            configstore.LiveViewOverlayIndex = nextIndex
        }
        else
        {
            setPrevOverlayImpl(nextIndex)
        }
    }

    function isValidOverlay(testIndex)
    {
        var testState = liveViewOverlayState.stateNames[testIndex]

        if (testState === "HTS")
            return cambody.hts_attached

        if(!allowSpiritLevel && (testState === "SpiritLevel"))
        {
            return false
        }
        return true
    }

    function checkOverlay()
    {
        if(!isValidOverlay(configstore.LiveViewOverlayIndex))
        {
            resetOverlay()
        }
    }

    Keys.onPressed: {
        if (event.isAutoRepeat)
        {
            event.accepted = false
        }
        else
        {
            mfTimer.stop()

            if(Camera.inSession && !(MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("EXPOSURE", event.key))) {
                // swallow mosts keys if we're inside a session.
                event.accepted = true
                return
            }
            if((MKeys.pressedFnAcc("ISO_WB", event) || (isoWbState.isoWbActive() && MKeys.pressedFnAcc("STAR", event))) && (configstore.ExpMode !== Config.ExpMode_FullAuto))
            {
                isoWbState.nextIsoWbState()
            }
            else if(MKeys.pressedFnAcc("SQUARE", event) || MKeys.pressedFnAcc("OVERLAY", event)) {
                if (!overlayOff) {
                    if(spiritLevelToggle)
                        liveViewOverlayState.toggleSpiritLevel()
                    else
                        setNextOverlay()
                }
            }
            else if (guiconfig.isWedge && !isoWbState.isoWbActive() && MKeys.pressedFnAcc("STOPDOWN", event))
            {
                // Activate stopdown (only) while holding the button
                cambody.doStopDown(true)
            }
            else if(!System.isTethered && (MKeys.pressedFnAcc("STAR", event) || MKeys.pressedFnAcc("ZOOM_IN", event)))
            {
                // Zoom in to focus point. Special handling for HC lens with Wedge
                if(guiconfig.isWedge && ((Lens.lens_family !== Lens.HCCLens) && (Lens.lens_family !== Lens.XCLens)))
                {
                    zoom(0.5 * root.width, 0.5 * root.height)
                }
                else
                {
                    zoom(Camera.firstComponent(Camera.focus_point) * root.width, Camera.secondComponent(Camera.focus_point) * root.height)
                }
            }
            else if(!System.isTethered && (VideoControl.videoMode === VideoControl.Zoom) && MKeys.pressedFnAcc("HALFPRESS", event))
            {
                VideoControl.setZoomState(false)
                BodySync.currentState = "MAIN"
            }
            else if(isoWbState.isoWbActive() && (MKeys.pressedFnAcc("AE_L", event) || MKeys.pressedFnAcc("AF_D", event) || MKeys.pressedFnAcc("HALFPRESS", event)))
            {
                isoWbState.closeIsoWb()
            }
            else if(MKeys.pressedFn("HALFPRESS", event.key)) {
                availCounter.startBlinking()
            }
            else if (isoWbState.isoWbActive() && MKeys.pressedFnAcc("AF_MF", event))
            {
                // Prevent key to progress further down the line
            }
            else if (guiconfig.isWedge && MKeys.pressedFnAcc("AF_MF", event) && (Camera.canChange & Camera.PropFocusMode))
            {
                // We do not know yet if this is a short or long press, we start a timer to find out
                mfTimer.restart()
            }
            else if (MKeys.pressedFnAcc("SPIRITLEVEL", event))
            {
                liveViewOverlayState.toggleSpiritLevel()
            }
            else if (MKeys.pressedFnAcc("ISO", event))
            {
                isoWbState.nextIsoState()
            }
            else if (MKeys.pressedFnAcc("WB", event))
            {
                isoWbState.nextWBState()
            }
            else if(MKeys.pressedFnAcc("CROSS", event) && guiconfig.isWedge && !isInHDMI && liveViewOverlayState.state !== "SpiritLevel")
            {
                //Reset AF point
                afc.resetPosition()
                afc.selectAndSave()
            }
            else
            {
                event.accepted = false
            }
        }

    }

    Keys.onReleased: {
        if (event.isAutoRepeat)
        {
            event.accepted = false
        }
        else if (guiconfig.isWedge && MKeys.pressedFnAcc("STOPDOWN", event)) {
            cambody.doStopDown(false)
        }
        else if (guiconfig.isWedge &&
                 MKeys.pressedFnAcc("AF_MF", event) &&
                 (configstore.ExpMode !== Config.ExpMode_ManualQuick) &&
                 ((VideoControl.videoMode === VideoControl.View) || (VideoControl.videoMode === VideoControl.Zoom)) &&
                 (System.camera_mode !== System.CameraModeVideo))
        {
            if(mfTimer.running)
            {
                mfTimer.stop()
                // Short press of AF/MF. We better handle that...
                if (Camera.canChange & Camera.PropFocusMode)
                    Camera.FocusMode = (Camera.FocusMode === Config.Focus_MAN) ? Config.Focus_AFS : Config.Focus_MAN;
            }
        }
    }

    AFCalc {
        id: afc
        screenWidth: root.width
        screenHeight: root.height
        isActive: !GlobalStateInfo.afSelectionActive && root.inActiveWindow
        idText: "In LiveViewOverlay"
    }

    Connections {
        target: BodySync
        onProximityDetectNearChanged: {
            isoWbState.closeIsoWb()
        }
    }
    Connections {
        property int lastMode: 0
        target: VideoControl
        onVideoModeChanged: {
            //Handle specific case where zoom mode was started by ring rotation and is controlled by a timer
            if (inActiveWindow && lastMode === VideoControl.Zoom && !GlobalStateInfo.afSelectionActive && isoWbState.state === "none" &&
                    BodySync.currentState === BodySync.MENU) {
                BodySync.currentState = BodySync.MAIN
            }
            lastMode = VideoControl.videoMode
        }
    }

    Item {
        id: mainRoot
        signal nextOverlay()
    }

    Component.onCompleted: {
        mainRoot.nextOverlay.connect(setNextOverlay)
    }

    onVisibleChanged: {
        // Remove toggled spiritlevel when leaving EVF
        if (!visible && spiritLevelToggle)
            liveViewOverlayState.toggleSpiritLevel()
    }
}
