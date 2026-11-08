import QtQuick 2.5

import com.hasselblad.storage 1.0
import com.hasselblad.settings 1.0
import com.hasselblad.config 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.farm 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.video 1.0
import com.hasselblad.guiconfig 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.gps 1.0
import com.hasselblad.usbif 1.0
import com.hasselblad.globalstateinfo 1.0

import "qrc:/"
import "qrc:/components"
import "qrc:/components/buttons"
import "qrc:/components/controls"
import "qrc:/components/popups"
import "qrc:/controlscreen"
import "qrc:/scripts/Keys.js" as MKeys

FocusScope {
    objectName: "ControlScreen_focusScope"
    id: scope
    // When we have popup, prevent parent to swipe
    property bool popupOpen: popup.status !== Loader.Null
    property bool preventSwipe: popupOpen || Camera.inSession
    property bool allowHighlightBracket: false

    // ViewModel
    ControlScreenViewModel {
        id: viewModel
    }

    // Dummy mouse area. Without it, swipe away does not work properly. QML Magic...
    MouseArea {
        anchors.fill: parent
    }

    // TODO: Check if this is really needed
    Connections {
        target: viewModel
        onVideoModeChanged: {
            states.state = ""
        }
    }

    function isHidden(element) {
        if (!element.visible || element.opacity === 0)
            return true;
        return false;
    }

    function testAndSetFocusRight(testValue, testItem, startItem)
    {
        console.log("Camera.canShow", Camera.canShow)
        console.log("Camera.canChange", Camera.canChange)
        // Prevent runaway...
        if(testItem !== startItem)
        {
            if(testValue)
            {
                testItem.forceActiveFocus()
            }
            else
            {
                setFocusOnNextRightImpl(testItem, startItem)
            }
        }
    }

    function setFocusOnNextRight(currentItem)
    {
        setFocusOnNextRightImpl(currentItem, currentItem)
    }

    function setFocusOnNextRightImpl(currentItem, startItem)
    {
        switch(currentItem)
        {
        case apertureSetting:
            testAndSetFocusRight(exposureButton.visible, exposureButton, startItem)
            break;
        case exposureButton:
            testAndSetFocusRight(!shutterSpeedSetting.outlineText && shutterSpeedSetting.visible, shutterSpeedSetting, startItem)
            break;
        case shutterSpeedSetting:
            testAndSetFocusRight(!isHidden(exposureAdjustSetting) && !root.isFullAuto && (exposureAdjustRow.visible || flashAdjustRow.visible), exposureAdjustSetting, startItem)
            break;
        case exposureAdjustSetting:
            testAndSetFocusRight(exposureControl.allowChange, exposureControl, startItem)
            break;
        case exposureControl:
            testAndSetFocusRight(viewModel.videoMode, videoRecord, startItem)
            break;
        case videoRecord:
            testAndSetFocusRight(viewModel.liveViewVisible, liveView, startItem)
            break;
        case liveView:
            testAndSetFocusRight(meterControl.visible && meterControl.showBracket, meterControl, startItem)
            break;
        case meterControl:
            testAndSetFocusRight(driveControl.visible && driveControl.showBracket, driveControl, startItem)
            break;
        case driveControl:
            testAndSetFocusRight(whitebalance_control.showBracket, whitebalance_control, startItem)
            break;
        case whitebalance_control:
            testAndSetFocusRight(!isHidden(af_control) && af_control.showBracket, af_control, startItem)
            break;
        case af_control:
            testAndSetFocusRight(!isoSetting.outlineText, isoSetting, startItem)
            break;
        case isoSetting:
            testAndSetFocusRight(!apertureSetting.outlineText && apertureSetting.visible, apertureSetting, startItem)
            break;
        }
    }

    function testAndSetFocusLeft(testValue, testItem, startItem)
    {
        // Prevent runaway...
        if(testItem !== startItem)
        {
            if(testValue)
            {
                testItem.forceActiveFocus()
            }
            else
            {
                setFocusOnNextLeftImpl(testItem, startItem)
            }
        }
    }

    function setFocusOnNextLeft(currentItem)
    {
        setFocusOnNextLeftImpl(currentItem, currentItem)
    }

    function setFocusOnNextLeftImpl(currentItem, startItem)
    {
        switch(currentItem)
        {
        case apertureSetting:
            testAndSetFocusLeft(!isoSetting.outlineText, isoSetting, startItem)
            break;
        case exposureButton:
            testAndSetFocusLeft(!apertureSetting.outlineText && apertureSetting.visible, apertureSetting, startItem)
            break;
        case shutterSpeedSetting:
            testAndSetFocusLeft(exposureButton.visible, exposureButton, startItem)
            break;
        case exposureAdjustSetting:
            testAndSetFocusLeft(!shutterSpeedSetting.outlineText && shutterSpeedSetting.visible, shutterSpeedSetting, startItem)
            break;
        case exposureControl:
            testAndSetFocusLeft(!isHidden(exposureAdjustSetting) && !root.isFullAuto && (exposureAdjustRow.visible || flashAdjustRow.visible), exposureAdjustSetting, startItem)
            break;
        case videoRecord:
            testAndSetFocusLeft(viewModel.liveViewVisible, liveView, startItem)
            break;
        case liveView:
            testAndSetFocusLeft(exposureControl.allowChange, exposureControl, startItem)
            break;
        case meterControl:
            testAndSetFocusLeft(viewModel.videoMode, videoRecord, startItem)
            break;
        case driveControl:
            testAndSetFocusLeft(meterControl.visible && meterControl.showBracket, meterControl, startItem)
            break;
        case whitebalance_control:
            testAndSetFocusLeft(driveControl.visible && driveControl.showBracket, driveControl, startItem)
            break;
        case af_control:
            testAndSetFocusLeft(whitebalance_control.showBracket, whitebalance_control, startItem)
            break;
        case isoSetting:
            testAndSetFocusLeft(!isHidden(af_control) && af_control.showBracket, af_control, startItem)
            break;
        }
    }

    function isoWbHandler()
    {

        if (!popupOpen) {
            if (System.isTethered) {
                // Do nothing
            } else if (Camera.canChange & Camera.PropSV)
                states.state = "iso"
            else if (Camera.canChange & Camera.PropWBMode)
                states.state = "whitebalance"
        } else if(states.state === "iso") {
            // Save selected value
            popup.item.setSelected()
            states.state = ""
            // Don't allow wb to be selectable if in tethered mode (phocus control wb)
            if (!System.isTethered && Camera.canChange & Camera.PropWBMode) {
                states.state = "whitebalance"
                whitebalance_control.popupShowed = true
            }
        } else if(states.state === "whitebalance") {
            // Save selected value
            popup.item.setSelected()
            states.state = ""
        }
    }

    function isoHandler()
    {
        if (!popupOpen) {
            if (!System.isTethered && Camera.canChange & Camera.PropSV)
                states.state = "iso"
        } else {
            popup.item.setSelected()
            states.state = ""
        }
    }

    function wbHandler()
    {
        if (!popupOpen) {
            // Don't allow wb to be selectable if in tethered mode (phocus control wb)
            if (!System.isTethered && Camera.canChange & Camera.PropWBMode) {
                states.state = "whitebalance"
                whitebalance_control.popupShowed = true
            }
        } else {
            popup.item.setSelected()
            states.state = ""
        }
    }

    function startCameraLiveView()
    {
        stopWheelTimeout();
        scope.allowHighlightBracket = false;
        var start = (VideoControl.videoMode === VideoControl.Off);
        Camera.setLiveViewState(start);
    }

    // Close popups if Dial mode changes
    Connections {
        target: BodySync
        onCurrentDialModeChanged: states.state = ""
    }

    Connections {
        target: configstore
        onExpModeChanged: {
            scope.stopWheelTimeout()
            scope.allowHighlightBracket = false;
        }
    }

    Timer {
        id: wheelTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: {
            allowHighlightBracket = false
            //            console.log("Camera Screen forcing focus")
            root.forceActiveFocus();
        }
    }

    function startWheelTimeout()
    {
        //        console.log("starting control screen wheel timer")
        wheelTimer.restart();
    }

    function stopWheelTimeout()
    {
        //        console.log("stopping control screen wheel timer")
        wheelTimer.stop();
    }

    function closePopup()
    {
        states.state = ""
    }

    onFocusChanged: {
        if(!focus)
            stopWheelTimeout() // always when we loose focus, drop the wheel timer so that we don't steal focus from some other view.
    }

    Rectangle {
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: constants.viewEndLineWidth
    }

    Rectangle {
        id: root
        objectName: "ControlScreen_root"
        anchors.fill: parent
        anchors.bottomMargin: constants.viewEndLineWidth
        // convenience bool, it's tested on so many places.
        property bool isFullAuto: configstore.ExpMode === Config.ExpMode_FullAuto
        color: constants.cameraViewBackgroundColor
        focus: true
        property Item lastFocused

        Keys.onPressed: {
            console.log("CameraView got key pressed")

            if((MKeys.pressedFnAcc("NAVRIGHT", event) || MKeys.pressedFnAcc("AF_D", event)) && !allowHighlightBracket)
            {
                setFocusOnNextRight(isoSetting)
                allowHighlightBracket = true
                startWheelTimeout();
            }
            else if(MKeys.pressedFnAcc("NAVLEFT", event) && !allowHighlightBracket)
            {
                allowHighlightBracket = true
                startWheelTimeout();
                setFocusOnNextLeft(exposureAdjustSetting)
            }
            else if(MKeys.pressedFnAcc("UP", event) && !allowHighlightBracket)
            {
                allowHighlightBracket = true
                startWheelTimeout();
                if(meterControl.visible && (cambody.LMModeListAsInt !== 0))
                {
                    meterControl.forceActiveFocus()
                }
                else
                {
                    driveControl.forceActiveFocus()
                }
            }
            else if(MKeys.pressedFnAcc("DOWN", event) && !allowHighlightBracket)
            {
                af_control.focus = true
                allowHighlightBracket = true
                startWheelTimeout();
            }
            else if(MKeys.pressedFnAcc("ISO_WB", event) && guiconfig.isWedge)
            {
                stopWheelTimeout()

                // First time, show isoSetting
                // Second time, show WB
                // Third time, show none
                isoWbHandler()
            }
            else if(MKeys.pressedFnAcc("AE_L", event) && guiconfig.isWedge)
            {
                stopWheelTimeout()
                if(configstore.ExpMode === Config.ExpMode_Manual ||
                   configstore.ExpMode === Config.ExpMode_ManualQuick)
                {
                    event.accepted = false
                }
            }
        }

        Item {
            objectName: "ControlScreen_states"
            id: states
            onStateChanged: console.log("Control screen state:", state)
            states: [
                State {
                    name: "popup"
                    StateChangeScript {
                        script: {
                            scope.stopWheelTimeout()
                            scope.allowHighlightBracket = false;
                            popup.forceActiveFocus()
                        }
                    }
                },
                State {
                    name: "exposure_mode"
                    extend: "popup"
                    PropertyChanges { target: popup; source: "qrc:/components/popups/PopoverExposureMode.qml"; active: true; }
                },
                State {
                    name: "whitebalance"
                    extend: "popup"
                    PropertyChanges { target: popup; source: "qrc:/components/popups/PopoverWhiteBalance.qml"; active: !System.isTethered; restoreEntryValues: false}
                },
                State {
                    name: "focus_mode"
                    extend: "popup"
                    PropertyChanges { target: popup; source: "qrc:/components/popups/PopoverFocusMode.qml"; active: true; }
                },
                State {
                    name: "meter_method"
                    extend: "popup"
                    PropertyChanges { target: popup; source: "qrc:/components/popups/PopoverMeterMethod.qml"; active: true; }
                },
                State {
                    name: "drive_mode"
                    extend: "popup"
                    PropertyChanges { target: popup; source: "qrc:/components/popups/PopoverDriveMode.qml"; active: true; }
                },
                State {
                    name: "iso"
                    extend: "popup"
                    PropertyChanges { target: popup; sourceComponent: popupISO; active: true; }
                },
                State {
                    name: "aperture"
                    extend: "popup"
                    PropertyChanges { target: popup; sourceComponent: popupApertureSettings; active: true; }
                },
                State {
                    name: "shutterspeed"
                    extend: "popup"
                    PropertyChanges { target: popup; sourceComponent: popupShutterSpeedSettings; active: true; }
                },
                State {
                    name: "exposure_adjust"
                    extend: "popup"
                    PropertyChanges { target: popup; source: "qrc:/components/popups/PopupExposureAdjust.qml"; active: true; }
                },
                State {
                    name: ""
                    StateChangeScript {
                        script: {
                            console.log("root is active")
                            root.forceActiveFocus()
                        }
                    }
                }

            ]
            transitions: [
                Transition {
                    from: "iso,aperture,shutterspeed,whitebalance"
                    ScriptAction {
                        script: {
                            popup.item.close()
                            popup.active = false
                            popup.source = ""
                        }
                    }
                }
            ]

        }

        Item {
            anchors {
                top: parent.top
                topMargin: constants.cameraViewMargin
                bottom: first_line.top
                left: first_line.left
                leftMargin: constants.cameraViewMargin
                right: first_line.right
                rightMargin: constants.cameraViewMargin
            }
            Row {
                anchors {
                    left: parent.left
                    leftMargin: whitebalance_control.visible ? 0 : whitebalance_control.width + spacing
                    top: parent.top
                    right: parent.right
                }
                spacing: constants.cameraViewMargin

                BracketedCameraControl {
                    id: whitebalance_control
                    visible: viewModel.whiteBalanceControlVisible
                    allowHighligtBracket: scope.allowHighlightBracket
                    symbol: root.isFullAuto ? "qrc:/icons/WBal_Auto_inactive.png" :
                                                Camera.WBMode === 1  ? "qrc:/icons/WBal_Auto.png"
                                              : Camera.WBMode === 2  ? "qrc:/icons/WBal_Daylight.png"
                                              : Camera.WBMode === 10 ? "qrc:/icons/WBal_Cloudy.png"
                                              : Camera.WBMode === 3  ? "qrc:/icons/WBal_Tungsten.png"
                                              : Camera.WBMode === 5  ? "qrc:/icons/WBal_Flash.png"
                                              : Camera.WBMode === 11 ? "qrc:/icons/WBal_Shade.png"
                                              : Camera.WBMode === 4  ? "qrc:/icons/WBal_Fluor.png"
                                              : Camera.WBMode === 6  ? "qrc:/icons/WBal_Empty.png"
                                              : "qrc:/icons/WBal_Unknown.png";

                    showBracket: Camera.canChange & Camera.PropWBMode
                    onClicked: {
                        if(showBracket)
                        {
                            states.state = "whitebalance"
                            popupShowed = true
                        }
                    }
                    Keys.onPressed: {
                        if(scope.allowHighlightBracket) {
                            if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                                startWheelTimeout()
                                setFocusOnNextRight(whitebalance_control)
                            }
                            else if(MKeys.pressedFnAcc("SELECT", event)) {
                                states.state = "whitebalance"
                                popupShowed = true
                            }
                            else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                                startWheelTimeout()
                                setFocusOnNextLeft(whitebalance_control)
                            }
                            else if(MKeys.pressedFnAcc("DOWN", event)) {
                                startWheelTimeout()
                                if(Camera.canChange & Camera.PropAV)
                                {
                                    apertureSetting.forceActiveFocus()
                                }
                                else if (!isHidden(exposureAdjustSetting))
                                {
                                    exposureAdjustSetting.forceActiveFocus()
                                }
                                else
                                {
                                    driveControl.forceActiveFocus()
                                }
                            }
                        }
                    }
                    Text{
                        visible: Camera.WBMode === 6
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 16
                        opacity: whitebalance_control.symbolOpacity
                        color: constants.popupTextColor
                        text: configstore.WBManualTemp// + (configstore.WBManualTemp < 10000 ? " " : "") + "K"
                        font.pixelSize: 32
                        font.bold: false
                    }

                }

                Connections {
                    target: configstore
                    onWBManualTintChanged: {
                        whitebalance_control.startBlink()
                    }
                }

                BracketedCameraControl {
                    id: af_control
                    allowHighligtBracket: scope.allowHighlightBracket
                    // Show manual in the case that wedge has no contrast AF compatible lens
                    symbol: !showBracket ?
                                ((Camera.FocusMode === Config.Focus_AFS || Camera.FocusMode === Config.Focus_AFC) ? "qrc:/icons/AF-Single_inactive.png" : "qrc:/icons/AF-Manual_inactive.png") :
                                Camera.FocusMode === Config.Focus_AFS ? "qrc:/icons/AF_Single.png" :
                                Camera.FocusMode === Config.Focus_AFC ? "qrc:/icons/AF_Cont.png" :
                                Camera.FocusMode === Config.Focus_AFT ? "qrc:/icons/AF_TrueFocus.png" :
                                Camera.FocusMode === Config.Focus_MAN ? "qrc:/icons/AF_Manual.png" :
                                "qrc:/icons/AF_Single.png";

                    visible: viewModel.afControlVisible
                    showBracket: Camera.canChange & Camera.PropFocusMode
                    onClicked: {
                        if(showBracket)
                        {
                            states.state = "focus_mode"
                            popupShowed = true
                        }
                    }
                    Keys.onPressed: {
                        if(scope.allowHighlightBracket)
                        {
                            if (MKeys.pressedFnAcc("NAVRIGHT", event)) {
                                startWheelTimeout()
                                setFocusOnNextRight(af_control)
                            }
                            else if(MKeys.pressedFnAcc("SELECT", event)) {
                                states.state = "focus_mode"
                                popupShowed = true
                            }
                            else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                                startWheelTimeout()
                                setFocusOnNextLeft(af_control)
                            }
                            else if(MKeys.pressedFnAcc("DOWN", event)) {
                                startWheelTimeout()
                                if(Camera.canChange & Camera.PropAV)
                                {
                                    apertureSetting.forceActiveFocus()
                                }
                                else if (!isHidden(exposureAdjustSetting))
                                {
                                    exposureAdjustSetting.forceActiveFocus()
                                }
                                else
                                {
                                    driveControl.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }

            Row {
                visible: Camera.canShow & Camera.PropSV
                layoutDirection: Qt.RightToLeft
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: -8
                    right: parent.right
                }
                spacing: constants.cameraViewMargin + 20
                BatteryIndicatorScaled {
                    anchors.verticalCenter: parent.verticalCenter
                    batteryWidth: 23
                    height: 59
                }

                TextCameraControl {
                    id: isoSetting
                    allowHighlightBracket: scope.allowHighlightBracket
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 12
                    label: "ISO"
                    labelSize: constants.cameraSettingSmallLabelSize
                    value: (guiconfig.fromIsoVal(Camera.iso) === "Auto" ? cambody.autoIso : guiconfig.fromIsoVal(Camera.iso))
                    toplabel: guiconfig.fromIsoVal(Camera.iso) === "Auto" ? "AUTO" : ""
                    valueSize: constants.cameraSettingSmallTextSize
                    labelLow: true
                    spacing: 6
                    outlineText: !(Camera.canChange & Camera.PropSV)
                    forceHighlight: isoMouseArea.containsPress

                    Keys.onPressed: {
                        if(scope.allowHighlightBracket)
                        {
                            if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                                startWheelTimeout()
                                setFocusOnNextRight(isoSetting)
                            }
                            else if(MKeys.pressedFnAcc("SELECT", event)) {
                                stopWheelTimeout()
                                if(!isoSetting.outlineText)
                                {
                                    states.state = "iso"
                                }
                                else
                                    event.accepted = false

                            }
                            else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                                startWheelTimeout()
                                setFocusOnNextLeft(isoSetting)
                            }
                            else if(MKeys.pressedFnAcc("DOWN", event)) {
                                startWheelTimeout()
                                if(Camera.canChange & Camera.PropTV)
                                {
                                    shutterSpeedSetting.forceActiveFocus()
                                }
                                else if (!isHidden(exposureAdjustSetting))
                                {
                                    exposureAdjustSetting.forceActiveFocus()
                                }
                                else if(!isHidden(driveControl))
                                {
                                    driveControl.forceActiveFocus()
                                }
                            }
                        }
                    }

                    MouseArea {
                        enabled: !isoSetting.outlineText
                        id: isoMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: states.state = "iso"
                    }
                }
            }

        }
        Rectangle {
            id: first_line
            color: constants.cameraViewLineColor
            anchors.top: parent.top
            anchors.topMargin: constants.cameraViewLineTopBottomMargin
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
        }


        TextCameraControl {
            visible: viewModel.apertureSettingVisible
            id: apertureSetting
            allowHighlightBracket: scope.allowHighlightBracket
            forceHighlight: apertureMouseArea.containsPress
            label: cambody.AV_out_of_range ? "" : "f/"
            labelSize: constants.cameraSettingLargeLabelSize
            value: cambody.AV_out_of_range ? "--" : cambody.aperture;
            valueSize: constants.cameraSettingLargeTextSize
            spacing: 2
            outlineText: ((Camera.canChange & Camera.PropAV) === 0) && viewModel.selectedExposureModeValid

            MouseArea {
                id: apertureMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    // Only do this if allowed
                    if (!apertureSetting.outlineText)
                    {
                        states.state = "aperture"
                    }
                    else
                    {
                        stopWheelTimeout()
                        scope.allowHighlightBracket = false;
                    }
                }
            }

            anchors.top: first_line.bottom
            anchors.topMargin: 23
            anchors.left: first_line.left
            anchors.leftMargin: constants.cameraViewMargin

            Keys.onPressed: {
                if(scope.allowHighlightBracket) {
                    if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                        startWheelTimeout()
                        setFocusOnNextRight(apertureSetting)
                    }
                    else if(MKeys.pressedFnAcc("SELECT", event)) {
                        if (!apertureSetting.outlineText) {
                            states.state = "aperture"
                        }
                        else {
                            stopWheelTimeout()
                            scope.allowHighlightBracket = false;
                            // TODO: Call this when properties connected
                            //                            popApertureQuickAdjust.toggle(root)
                        }

                    }
                    else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                        startWheelTimeout()
                        setFocusOnNextLeft(apertureSetting)
                    }
                    else if(MKeys.pressedFnAcc("DOWN", event)) {
                        startWheelTimeout()
                        if  (!isHidden(exposureAdjustSetting))
                            exposureAdjustSetting.forceActiveFocus()
                    }
                    else if(MKeys.pressedFnAcc("UP", event)) {
                        startWheelTimeout()
                        whitebalance_control.forceActiveFocus()
                    }
                }
            }
        }


        ShutterSpeedControl {
            id: shutterSpeedSetting
            objectName: "ControlScreen_shutterSpeedSetting"
            visible: viewModel.shutterSpeedSettingVisible
            allowHighlightBracket: scope.allowHighlightBracket
            forceHighlight: shutterSpeedMouseArea.containsPress
            outlineText: ((Camera.canChange & Camera.PropTV) === 0) && viewModel.selectedExposureModeValid
            showIcon: configstore.eshutter && !viewModel.videoMode
            shutterSpeedValue: cambody.TV_out_of_range ? "--" : cambody.shutterSpeed

            anchors.top: first_line.bottom
            anchors.topMargin: 23
            anchors.right: first_line.right
            anchors.rightMargin: constants.cameraViewMargin
            Keys.onPressed: {
                if(scope.allowHighlightBracket) {
                    if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                        startWheelTimeout()
                        setFocusOnNextRight(shutterSpeedSetting)
                    }
                    else if(MKeys.pressedFnAcc("SELECT", event)) {
                        scope.allowHighlightBracket = false;
                        if (!shutterSpeedSetting.outlineText) {
                            states.state = "shutterspeed"
                        }
                        else {
                            stopWheelTimeout()
                            // TODO: Call this when properties connected
                            //                            popShutterSpeedQuickAdjust.toggle(root)
                        }
                    }
                    else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                        startWheelTimeout()
                        setFocusOnNextLeft(shutterSpeedSetting)
                    }
                    else if(MKeys.pressedFnAcc("DOWN", event)) {
                        startWheelTimeout()
                        if  (!isHidden(exposureAdjustSetting))
                        {
                            exposureAdjustSetting.forceActiveFocus()
                        }
                        else if(!isHidden(driveControl))
                        {
                            driveControl.forceActiveFocus()
                        }

                    }
                    else if(MKeys.pressedFnAcc("UP", event)) {
                        startWheelTimeout()
                        isoSetting.forceActiveFocus()
                    }
                }
            }


            MouseArea {
                id: shutterSpeedMouseArea
                anchors.fill: parent
                onClicked: {
                    stopWheelTimeout()
                    scope.allowHighlightBracket = false;
                    if (!shutterSpeedSetting.outlineText) {
                        states.state = "shutterspeed"
                    }
                    else {
                        // TODO: Call this when properties connected
                        //                        popShutterSpeedQuickAdjust.toggle(root)
                    }
                }
            }
        }

        ExposureButton {
            id: exposureButton
            anchors {
                top: first_line.bottom
                topMargin: constants.exposureButtonMargin
                left: first_line.left
                leftMargin: anchors.topMargin
            }
            onMouseEvent: stopWheelTimeout()
            Keys.onPressed: {
                if(scope.allowHighlightBracket) {
                    if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                        startWheelTimeout()
                        setFocusOnNextRight(exposureButton)
                    }
                    else if(MKeys.pressedFnAcc("SELECT", event)) {
                        scope.allowHighlightBracket = false;
                        stopWheelTimeout()
                        // Expose
                        startExposure()
                    }
                    else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                        startWheelTimeout()
                        setFocusOnNextLeft(exposureButton)
                    }
                }
            }
            Keys.onReleased: {
                if(MKeys.pressedFnAcc("SELECT", event)) {
                    scope.allowHighlightBracket = true;
                    stopWheelTimeout()
                    // Stop Expose
                    stopExposure()
                }
            }

        }

        Item {
            anchors.left: evSetting.left
            anchors.right: parent.right
            anchors.bottom: evSetting.top
            anchors.bottomMargin: 16
            anchors.top: apertureSetting.bottom
            id: aelockItem
            Image {
                id: aelock
                asynchronous: true
                source: "qrc:/icons/AE-Lock.png"
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                visible: cambody.AEL
            }
            Image {
                asynchronous: true
                source: !guiconfig.isWedge ? "qrc:/icons/MirrorUp.png" : ""
                anchors.bottom: parent.bottom
                anchors.left: aelock.right
                anchors.leftMargin: 10
                visible: !guiconfig.isWedge && (cambody.current_body_mode === Cambody.BodyModeSRelease)
            }
        }

        Text {
            id: camBodyText
            anchors.bottom: second_line.top
            anchors.bottomMargin: 8
            anchors.left: second_line.left
            anchors.leftMargin: constants.cameraViewMargin
            color: "white"
            font.pixelSize: 24
            font.family: constants.cameraControlTextFontName

            text: Settings.stringTranslated("CameraType", configstore.cameraTypeAsString) + guiconfig.emptyString
            visible: ((configstore.CameraType === Config.CameraTypeFlashsync) ||
                      (configstore.CameraType === Config.CameraTypePinhole) ||
                       guiconfig.isCFV)
        }

        TextCameraControl {
            id: evSetting
            label: "EV"
            labelSize: constants.cameraViewSettingEVLabelSize
            spacing: 2
            value: {
                // Sanity check
                if((cambody.AV >= 0) && (cambody.AV <= 156) && (cambody.TV >= -192) && (cambody.TV <= 168))
                {
                    // Good
                    return ((cambody.AV + cambody.TV)/12).toFixed(1) // EV = Ev/12 ... according to Exposure Control System coding document.
                }
                else
                {
                    return "---";
                }
            }
            valueSize: constants.cameraViewSettingEVTextSize
            labelLow: true
            labelMargin: 4

            anchors {
                bottom: second_line.top
                left: second_line.left
                leftMargin: constants.cameraViewMargin
            }

            visible: !(cambody.isBMode || cambody.isTMode) &&
                     (((cambody.capabilities & Cambody.CapabilityGetAV) !== 0) &&
                     ((cambody.capabilities & Cambody.CapabilityGetTV) !== 0))
        }

        Item {
            id: exposureAdjustSetting
            visible: viewModel.exposureAdjustSettingVisible
            anchors {
                bottom: second_line.top
                bottomMargin: constants.cameraViewMargin - 13
                right: second_line.right
                rightMargin: constants.cameraViewMargin
            }


            Row {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                layoutDirection: Qt.RightToLeft
                visible: Camera.canShow & Camera.PropEVADJ
                property bool isEnabled: Camera.canChange & Camera.PropEVADJ

                id: exposureAdjustRow
                spacing: 9
                Image {
                    source: !exposureAdjustRow.isEnabled ? "qrc:/icons/Correction_Icon_inactive.png" : exposureAdjustMouseArea.containsPress || (exposureAdjustSetting.focus && scope.allowHighlightBracket) ? "qrc:/icons/Correction_Icon_highlighted.png" : "qrc:/icons/Correction_Icon.png"
                    anchors {
                        verticalCenter: exposureAdjustText.verticalCenter
                        verticalCenterOffset: -8
                    }
                }
                Text {
                    width: 120
                    font.bold: true
                    id: exposureAdjustText
                    text: (Camera.EVADJ > 0 ? "+" : "") + (Camera.EVADJ / 12.0).toFixed(1)
                    color: {
                        if((exposureAdjustSetting.focus && scope.allowHighlightBracket) || (exposureAdjustMouseArea.containsPress && exposureAdjustRow.isEnabled))
                            return constants.highlightColor;
                        return exposureAdjustRow.isEnabled ? constants.cameraViewNormalTextColor : "grey"
                    }
                    style: exposureAdjustRow.isEnabled ? Text.Normal : Text.Outline
                    styleColor: "white"
                    font.pixelSize: constants.cameraViewSettingEVTextSize
                    font.family: constants.cameraControlTextFontName
                    horizontalAlignment: Text.AlignRight
                }

            }
            Row {
                anchors {
                    left: exposureAdjustRow.left
                    bottom: exposureAdjustRow.top
                    bottomMargin: constants.cameraViewMargin - 14
                }
                id: flashAdjustRow
                property bool isEnabled: Camera.canChange & Camera.PropFlashEVADJ

                layoutDirection: Qt.RightToLeft
                // Only show flashAdj if it's set to compensate the value in any direction.
                visible: ((Camera.FLASH_EVADJ !== 0) || (Camera.canShow & Camera.PropEVADJ != Camera.PropEVADJ)) &&
                         (Camera.canShow & Camera.PropEVADJ)

                spacing: 9
                Image {
                    asynchronous: true
                    id: flashAdjustIcon
                    source: !flashAdjustRow.isEnabled ? "qrc:/icons/flash_adjust_inactive.png" : exposureAdjustMouseArea.containsPress || (exposureAdjustSetting.focus && scope.allowHighlightBracket) ? "qrc:/icons/flash_adjust_highlighted.png" : "qrc:/icons/flash_adjust.png"
                    anchors {
                        verticalCenter: flashAdjustText.verticalCenter
                        verticalCenterOffset: -8
                    }
                }
                Text {
                    width: 120
                    font.bold: true
                    id: flashAdjustText
                    text: (Camera.FLASH_EVADJ > 0 ? "+" : "") +  (Camera.FLASH_EVADJ / 12.0).toFixed(1)
                    color: {
                        if((exposureAdjustSetting.focus && scope.allowHighlightBracket) || (exposureAdjustMouseArea.containsPress && flashAdjustRow.isEnabled))
                            return constants.highlightColor;
                        return flashAdjustRow.isEnabled ? constants.cameraViewNormalTextColor : "grey"
                    }
                    style: flashAdjustRow.isEnabled ? Text.Normal : Text.Outline
                    styleColor: "white"

                    font.pixelSize: constants.cameraViewSettingEVTextSize
                    font.family: constants.cameraControlTextFontName
                    horizontalAlignment: Text.AlignRight
                }
            }

            MouseArea {
                enabled: exposureAdjustRow.isEnabled || flashAdjustRow.isEnabled
                id: exposureAdjustMouseArea
                hoverEnabled: true
                anchors {
                    bottom: exposureAdjustRow.bottom
                    left: exposureAdjustRow.left
                    right: exposureAdjustRow.right
                    top: flashAdjustRow.top
                }
                onClicked: states.state = "exposure_adjust"
            }
            Keys.onPressed: {
                if(scope.allowHighlightBracket) {
                    if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                        startWheelTimeout()
                        setFocusOnNextRight(exposureAdjustSetting)
                    }
                    else if(MKeys.pressedFnAcc("SELECT", event)) {
                        stopWheelTimeout()
                        if(!root.isFullAuto)
                        {
                            states.state = "exposure_adjust"
                        }
                    }
                    else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                        startWheelTimeout()
                        setFocusOnNextLeft(exposureAdjustSetting)
                    }
                    else if(MKeys.pressedFnAcc("DOWN", event)) {
                        startWheelTimeout()
                        if(!isHidden(driveControl))
                        {
                            driveControl.forceActiveFocus()
                        }
                    }
                    else if(MKeys.pressedFnAcc("UP", event)) {
                        startWheelTimeout()
                        if(Camera.canChange & Camera.PropTV)
                        {
                            shutterSpeedSetting.forceActiveFocus()
                        }
                        else
                        {
                            isoSetting.forceActiveFocus()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: second_line
            color: constants.cameraViewLineColor
            anchors {
                bottom: parent.bottom
                bottomMargin: first_line.anchors.topMargin
                left: first_line.left
                right: first_line.right
            }
            height: first_line.height
        }

        Row {
            anchors.bottom: aelockItem.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            // Embed in Items that are always visible, otherwise icons move around when some icon is not visible...
            Item {
                visible: true
                width: childrenRect.width
                height: childrenRect.height
                Image {
                    id: wifiIcon
                    visible: configstore.WIFI_power
                    source: "qrc:/icons/ControlScreen_WiFi.png"
                }
            }
            Item {
                visible: true
                width: childrenRect.width
                height: childrenRect.height
                FlashStatus {
                    id: flashStatus
                }
            }
            Item {
                visible: true
                width: childrenRect.width
                height: childrenRect.height
                GPSStatus {
                    id: gpsImage
                    iconSource: "qrc:/icons/ControlScreen_GPS.png"
                }
            }

        }

        TimerIndicator {
            id: timerIndicator
            visible: (configstore.selfTimerActive || configstore.intervalActive || configstore.bracketingActive  || configstore.focusBracketingActive) && !viewModel.videoMode
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: second_line.top
                bottomMargin: constants.cameraViewMargin - 10
            }
        }

        Item {
            id: bottom_controls
            anchors {
                bottom: parent.bottom
                bottomMargin: constants.cameraViewMargin
                top: second_line.top
                left: first_line.left
                leftMargin: constants.cameraViewMargin
                right: first_line.right
                rightMargin: constants.cameraViewMargin
            }

            // Row from left
            Row {
                id: bottom_row
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                spacing: constants.cameraViewMargin

                BracketedCameraControl {
                    id: exposureControl
                    anchors.verticalCenter: parent.verticalCenter
                    property bool allowChange: viewModel.exposureControlAllowedToChange

                    allowHighligtBracket: scope.allowHighlightBracket && allowChange
                    showBracket: allowChange
                    forceBackground: (configstore.ExpMode === Config.ExpMode_ManualQuick) && (GlobalStateInfo.haveHalfPress || GlobalStateInfo.haveLiveViewPress)
                    symbol: viewModel.exposureControlSymbol

                    onClicked: {
                        if(showBracket) {
                            states.state =  "exposure_mode"
                            popupShowed = true
                        }
                    }

                    Keys.onPressed: {
                        if(scope.allowHighlightBracket) {
                            if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                                startWheelTimeout()
                                setFocusOnNextRight(exposureControl)
                            }
                            else if(MKeys.pressedFnAcc("SELECT", event)) {
                                states.state =  "exposure_mode"
                                popupShowed = true
                            }
                            else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                                startWheelTimeout()
                                setFocusOnNextLeft(exposureControl)
                            }
                            else if(MKeys.pressedFnAcc("UP", event)) {
                                startWheelTimeout()
                                if(Camera.canChange & Camera.PropAV)
                                {
                                    apertureSetting.forceActiveFocus()
                                }
                                else
                                {
                                    af_control.forceActiveFocus()
                                }
                            }
                        }
                    }

                }

                MenuButton {
                    id: videoRecord
                    isImageButton: true

                    buttonData: viewModel.videoRecordMode ? "qrc:/icons/RecordingStopLarge.png"
                                : (focus && scope.allowHighlightBracket && !mousePressed)
                                                            ? "qrc:/icons/StartVideoLiveViewOrange.png"
                                                            : "qrc:/icons/StartVideoLiveView.png"
                    borderColor: mousePressed ? constants.buttonBorderHighlightColor : "black"
                    buttonColor: mousePressed ? constants.buttonBorderColor : root.color
                    height: exposureControl.height
                    maxWidth: 120
                    visible: viewModel.videoMode

                    onClicked: {
                        startCameraLiveView()
                    }

                    Keys.onPressed: {
                        if(scope.allowHighlightBracket) {
                            if(MKeys.pressedFnAcc("SELECT", event)) {
                                startCameraLiveView()
                            }
                            else if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                                startWheelTimeout()
                                setFocusOnNextRight(videoRecord)
                            }
                            else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                                startWheelTimeout()
                                setFocusOnNextLeft(videoRecord)
                            }
                            else if(MKeys.pressedFnAcc("NAVUP", event)) {
                                startWheelTimeout()
                                apertureSetting.forceActiveFocus()
                            }
                        }
                    }
                }

                MenuButton {
                    id: liveView
                    width: 108
                    height: 84
                    anchors.verticalCenter: bottom_row.verticalCenter
                    isImageButton: true
                    borderColor: mousePressed ? constants.buttonBorderHighlightColor : "black"
                    buttonColor: mousePressed ? constants.buttonBorderColor : root.color
                    buttonData: (focus && scope.allowHighlightBracket && !mousePressed) ? "qrc:/icons/CS-LV-Orange.png"
                                                                                        : "qrc:/icons/CS-LV.png"
                    visible: viewModel.liveViewVisible

                    onClicked: {
                        startCameraLiveView()
                    }

                    Keys.onPressed: {
                        if(scope.allowHighlightBracket) {
                            if(MKeys.pressedFnAcc("SELECT", event)) {
                                startCameraLiveView()
                            }
                            else if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                                startWheelTimeout()
                                setFocusOnNextRight(liveView)
                            }
                            else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                                startWheelTimeout()
                                setFocusOnNextLeft(liveView)
                            }
                        }
                    }
                }

                BracketedCameraControl {
                    id: meterControl
                    allowHighligtBracket: scope.allowHighlightBracket
                    symbol: viewModel.meterControlSymbol

                    opacity: (viewModel.selectedLightMeterModeValid  && (Camera.canShow & Camera.PropLMMode)) ? 100 : 0
                    showBracket: Camera.canChange & Camera.PropLMMode
                    // This control must be set to visible to allow next control to be in right position.
                    // If it should not be shown, opacity takes care of that...
                    visible: (Camera.canShow & Camera.PropLMMode) || (Camera.canShow & Camera.PropDriveMode)
                    onClicked: {
                        if (showBracket)
                        {
                            states.state = "meter_method"
                            popupShowed = true
                        }
                    }

                    Keys.onPressed: {
                        if(scope.allowHighlightBracket)
                        {
                            if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                                startWheelTimeout()
                                setFocusOnNextRight(meterControl)
                            }
                            else if(MKeys.pressedFnAcc("SELECT", event)) {
                                stopWheelTimeout()
                                if(!root.isFullAuto)
                                {
                                    states.state = "meter_method"
                                    popupShowed = true
                                }
                            }
                            else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                                startWheelTimeout()
                                setFocusOnNextLeft(meterControl)
                            }
                            else if(MKeys.pressedFnAcc("UP", event)) {
                                startWheelTimeout()
                                if(Camera.canChange & Camera.PropAV)
                                {
                                    apertureSetting.forceActiveFocus()
                                }
                                else
                                {
                                    af_control.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
                BracketedCameraControl {
                    id: driveControl
                    allowHighligtBracket: scope.allowHighlightBracket
                    symbol: viewModel.driveControlSymbol

                    visible: Camera.canShow & Camera.PropDriveMode
                    showBracket: Camera.canChange & Camera.PropDriveMode

                    onClicked: {
                        if(showBracket)
                        {
                            states.state = "drive_mode"
                            popupShowed = true
                        }
                    }

                    Keys.onPressed: {
                        if(scope.allowHighlightBracket) {
                            if (MKeys.pressedFnAcc("NAVRIGHT", event)) {
                                startWheelTimeout()
                                setFocusOnNextRight(driveControl)
                            }
                            else if(MKeys.pressedFnAcc("SELECT", event)) {
                                states.state = "drive_mode"
                                popupShowed = true
                            }
                            else if (MKeys.pressedFnAcc("NAVLEFT", event))
                            {
                                startWheelTimeout()
                                setFocusOnNextLeft(driveControl)
                            }
                            else if(MKeys.pressedFnAcc("UP", event))
                            {
                                startWheelTimeout()
                                if (!isHidden(exposureAdjustSetting))
                                {
                                    exposureAdjustSetting.forceActiveFocus()
                                }
                                else if(Camera.canChange & Camera.PropTV)
                                {
                                    shutterSpeedSetting.forceActiveFocus()
                                }
                                else
                                {
                                    isoSetting.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }

            // Row from right
            Row {
                id: bottom_row_right
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                spacing: 7
                layoutDirection: Qt.RightToLeft
                // CFast:
                Grid {
                    id: cardStatus
                    anchors.top: bottom_row_right.top
                    anchors.bottom: bottom_row_right.bottom
                    columns: 2
                    rows: 2
                    rowSpacing: 20
                    columnSpacing: 5
                    visible: (farm.ram_only_mode !== Farm.RamModeRamOnly) && (System.tethered_mode === System.TetheredModeOff || !Usbif.usbLink)

                    // Top row
                    CardStatusRectangle {
                        text: GuiConfig.SlDualSD === guiconfig.storageSlots ? guiconfig.storageSlotLetter(Config.Card0) : guiconfig.storageSlotLetter(Config.Card1)
                        status: GuiConfig.SlDualSD === guiconfig.storageSlots ? ContentModel.card0Status : ContentModel.card1Status
                    }

                    CardStatusImage {
                        status: GuiConfig.SlDualSD === guiconfig.storageSlots ? ContentModel.card0Status : ContentModel.card1Status
                    }

                    // Bottom row
                    CardStatusRectangle {
                        text: GuiConfig.SlDualSD === guiconfig.storageSlots ? guiconfig.storageSlotLetter(Config.Card1) : guiconfig.storageSlotLetter(Config.Card0)
                        status: GuiConfig.SlDualSD === guiconfig.storageSlots ? ContentModel.card1Status : ContentModel.card0Status
                    }

                    CardStatusImage {
                        status: GuiConfig.SlDualSD === guiconfig.storageSlots ? ContentModel.card1Status : ContentModel.card0Status
                    }
                }

                DemoModeIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                }

                USBIndicator {
                    id: usbIndicator
                    anchors.verticalCenter: parent.verticalCenter
                    visible: inTethered
                    superspeed: Usbif.usbSuperSpeed
                    property bool inTethered: System.tethered_mode !== System.TetheredModeOff && Usbif.usbLink
                    onInTetheredChanged: if(inTethered) startBlink();
                }

                Row {
                    Image {
                        id: left_bracket
                        anchors.top: parent.top
                        source: "qrc:/icons/left_bracket.png"
                    }

                    ExposuresAvailCounter {
                        id: availCounter
                        anchors.top: left_bracket.top
                        height: left_bracket.height
                        font.bold: true
                        allowTwoLineText: true
                        width: (farm.ram_only_mode === Farm.RamModeRamOnly) || (System.tethered_mode !== System.TetheredModeOff) ? 100 : 153 + 10
                    }

                    Image {
                        id: right_bracket
                        anchors.top: parent.top
                        source: "qrc:/icons/right_bracket.png"
                    }
                }
            }
        }

        Component {
            id: popupApertureSettings
            PopupListSelector {
                objectName: "popupAperture"
                popupAnchor.rightMargin: root.width / 2
                isToLeft: true
                model: Settings.apertureValues
                currentlySelectedValue: cambody.aperture

                onSelectedValueChanged: {
                    cambody.aperture = value
                }
            }
        }

        Component {
            id: popupShutterSpeedSettings
            PopupListSelector {
                objectName: "popupShutterSpeed"
                popupAnchor.leftMargin: root.width * 0.4
                isToLeft: false
                model: Settings.shutterspeedValues
                currentlySelectedValue: cambody.shutterSpeed

                onSelectedValueChanged: {
                    cambody.shutterSpeed = value
                }
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

        Loader {
            id: popup
            objectName: "ControlScreen_popupLoader"
            asynchronous: false
            anchors.fill: parent
            onLoaded: popup.item.forceActiveFocus()

            Connections {
                target: popup.item
                onVisibleChanged: {
                    if ((popup.item != null) && !popup.item.visible) {
                        //Need to set both state and forceActiveFocus() since we sometimes are called here when already in state ""
                        states.state = ""
                        root.forceActiveFocus()
                    }
                }
            }
        }
    }
    function focusChanged() {
        if(!allowHighlightBracket)
        {
            root.forceActiveFocus();
        }
    }

    Component.onCompleted: console.log("ControlScreen completed")
}
