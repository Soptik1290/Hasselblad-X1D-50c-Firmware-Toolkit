import QtQuick 2.2
import com.hasselblad.config 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.power 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.upgrade 1.0
import com.hasselblad.storage 1.0
import com.hasselblad.error 1.0
import com.hasselblad.systemd 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.settings 1.0
import com.hasselblad.lens 1.0
import com.hasselblad.sound 1.0
import "qrc:///common"
import "qrc:///scripts/Keys.js" as MKeys
Item {
    objectName: "mainRoot"
    id: mainRoot
    property int wegde_bodystate: -1
    GlobalConstants {
        id: constants
    }
    property int liveViewImageTimeoutSU: ((configstore.GUI_idle_timeout > constants.liveViewImageMaxTimeoutSU) || (configstore.GUI_idle_timeout <= 0)) ?
                                             constants.liveViewImageMaxTimeoutSU : configstore.GUI_idle_timeout
    property bool isSleeping: false
    signal nextOverlay()
    Loader {
        objectName: "TouchWindow_loader"
        id: mainWindow
        property bool isReady: false
        source: "qrc:///common/TouchWindow.qml"
        asynchronous: true
        onLoaded: {
            console.log("MainWindow loaded")
            isReady = item.isReady
        }
        Connections {
            target: mainWindow.item
            onIsReadyChanged: mainWindow.isReady = mainWindow.item.isReady
        }
        Binding {
            target: mainWindow.item
            property: "haveHalfPress"
            value: GlobalStateInfo.haveHalfPress
            when: mainWindow.item !== null
        }
    }
    Loader {
        objectName: "EVFWindow_Loader"
        id: evfWindow
        visible: active
        source: "qrc:///liveview/EVFWindow.qml"
        asynchronous: true
        active: mainWindow.isReady
        onLoaded: console.log("EvfWindow loaded")
    }
    property bool allLoaded: (mainWindow.status === Loader.Ready) && (evfWindow.status === Loader.Ready)
    onAllLoadedChanged: {
        if(allLoaded)
        {
            evfWindow.item.setToBrowse.connect(mainWindow.item.setToBrowse)
            evfWindow.item.setToMain.connect(mainWindow.item.setToMain)
            evfWindow.item.setToControl.connect(mainWindow.item.setToControl)
            var cmv = System.camera_mode === System.CameraModeVideo
            evfWindow.item.subloader_lv_active = !cmv
            evfWindow.item.subloader_video_active = cmv
            mainWindow.item.subloader_dialmode_active = guiconfig.isWedge
        }
    }
    Item {
        id: control
        objectName: "mainControl"
        property bool evfWasActive: false
        property bool sessionStopped: false
        property int contentAddedDuringEvfActive: 0
        Connections {
            id: content_conn
            property alias theTarget: content_conn.target
            target: ContentModel
            onImageAdded: {
                if (GlobalStateInfo.evfActive) {
                    control.contentAddedDuringEvfActive++
                    if (configstore.EVFPreviewTimeout !== 0) {
                        evfWindow.item.openPreView(true, configstore.EVFPreviewTimeout > 0)
                    }
                }
                mainWindow.item.photosAddedInSession++
                GlobalStateInfo.photosAddedCount++;
                ContentModel.setLastExposureFocusPoint(Camera.firstComponent(Camera.focus_point), Camera.secondComponent(Camera.focus_point))
            }
        }
        Connections {
            id: camera_conn
            target: Camera
            onInSessionChanged: {
                if (Camera.inSession) {
                    mainWindow.item.photosAddedInSession = 0
                }
                GlobalStateInfo.photosAddedCount = 0
            }
        }
        Connections {
            id: mainSleepingConn
            ignoreUnknownSignals: true
            property alias theTarget: mainSleepingConn.target
            onSleepingChanged: updatePowerClient(target.sleeping)
            function updatePowerClient(sleeping) {
                console.log("Power client will change state, sleeping:", sleeping)
                if (sleeping)
                    PowerClient.setState(PowerClient.PowerStateIdle)
                else
                {
                    PowerClient.setState(PowerClient.PowerStateActive)
                }
            }
        }
        Connections {
            target: VideoControl
            onVideoModeChanged: {
                if ((control.state === "hdmi") && (evfWindow.item !== null) && (VideoControl.videoMode !== VideoControl.Off))
                {
                    evfWindow.item.requestActivate()
                }
                if(VideoControl.videoMode !== VideoControl.View)
                {
                    GlobalStateInfo.afSelectionActive = false
                    prohibitZoomTimer.start()
                }
            }
        }
        Timer {
            id: prohibitZoomTimer
            interval: 0
            onTriggered: {
                VideoControl.prohibitZoom = false
            }
        }
        Timer {
            objectName: "mainActivateTimer"
            id: mainActivateTimer
            interval: 2000
            onTriggered: {
                console.log("Main Window requested to be active again")
                mainWindow.item.requestActivate()
            }
        }
        Timer {
            id: sleepStateTimer
            interval: 0
            onTriggered: {
                isSleeping = mainWindow.item.sleeping
            }
        }
        Connections {
            target: mainWindow.item
            onSleepingChanged: sleepStateTimer.start()
        }
        onStateChanged: {
            console.log("Control state:", state)
            if (state !== "evf") {
                GlobalStateInfo.evfActive = false
            }
        }
        states: [
            State {
                name: "sleeping"
                when: isSleeping && mainWindow.isReady
                PropertyChanges { target: mainSleepingConn; theTarget: mainWindow.item }
                PropertyChanges { target: VideoControl; liveViewImageTimeout: liveViewImageTimeoutSU; restoreEntryValues: false }
                PropertyChanges { target: BodySync; focusSurface: mainWindow.item.title }
                StateChangeScript {
                    script: {
                        mainWindow.item.requestActivate()
                        if (guiconfig.isWedge) {
                            wegde_bodystate = BodySync.currentState
                            BodySync.currentState = BodySync.DISABLE_WHEELS
                        }
                    }
                }
            },
            State {
                name: "evf"
                when: (evfWindow.status === Loader.Ready) &&
                      (BodySync.proximityDetectNear !== 0) &&
                      (System.system_state !== System.StateUpgrade) &&
                      (System.tethered_mode !== System.TetheredModeUSBLiveView) &&
                      !ContentModel.isFormatting
                PropertyChanges { target: control; evfWasActive: true; restoreEntryValues: false }
                PropertyChanges { target: VideoControl; liveViewImageTimeout: constants.liveViewImageTimeoutDefault; restoreEntryValues: false }
                PropertyChanges { target: BodySync; focusSurface: evfWindow.item.title }
                PropertyChanges { target: BodySync; currentState: cambody.exposing ? BodySync.DISABLE_WHEELS : GlobalStateInfo.afSelectionActive ? BodySync.MENU : (evfWindow.item.showPreview ? BodySync.PLAY : BodySync.MAIN); restoreEntryValues: false }
                PropertyChanges { target: mainWindow.item; formatLoaderActive: false; restoreEntryValues: false }
            },
            State {
                name: "evf_exit_stopping_session"
                when: evfWindow.status === Loader.Ready && control.evfWasActive && BodySync.proximityDetectNear === 0 &&
                      ((!Camera.exposing && Camera.selfTimerCountDown === 0 && Camera.intervalTimerCountDown === 0)
                       || (Camera.exposing && VideoControl.videoMode !== VideoControl.Off)) &&
                      Camera.inSession &&
                      control.sessionStopped &&
                      System.system_state !== System.StateUpgrade
            },
            State {
                name: "hdmi"
                extend: "main"
                when: evfWindow.status === Loader.Ready && mainWindow.isReady && BodySync.hdmiCableConnected && System.system_state !== System.StateUpgrade && System.tethered_mode !== System.TetheredModeUSBLiveView
                PropertyChanges { target: VideoControl; liveViewImageTimeout: constants.liveViewImageTimeoutDefault; restoreEntryValues: false }
                PropertyChanges { target: mainWindow.item; isInHDMI: true }
                PropertyChanges { target: evfWindow.item; isInHDMI: true }
                PropertyChanges { target: BodySync; focusSurface: (VideoControl.videoMode !== VideoControl.Off) ? evfWindow.item.title : mainWindow.item.title }
                PropertyChanges { target: BodySync; currentState: cambody.exposing ? BodySync.DISABLE_WHEELS : GlobalStateInfo.afSelectionActive ? BodySync.MENU : BodySync.MAIN; restoreEntryValues: false }
            },
            State {
                name: "main"
                when: mainWindow.isReady
                PropertyChanges { target: mainSleepingConn; theTarget: mainWindow.item }
                PropertyChanges { target: VideoControl; liveViewImageTimeout: liveViewImageTimeoutSU; restoreEntryValues: false }
                PropertyChanges { target: BodySync; focusSurface: mainWindow.item.title }
                StateChangeScript {
                    script: {
                        if (GlobalStateInfo.errorPopupOwner === "overlay") {
                            GlobalStateInfo.errorPopupOwner = "main"
                        }
                    }
                }
            }
        ]
        transitions: [
            Transition {
                to: "evf"
                ScriptAction {
                    script: {
                        if(VideoControl.videoMode === VideoControl.Playback)
                        {
                            mainWindow.item.preventIdle(false)
                        }
                        if((ErrorControl.code === Errors.ErrorNone) || ErrorControl.isAckable)
                        {
                            var wasInInstantPreview = mainWindow.item.isInstantPreview
                            var wasInBrowsing = mainWindow.item.isBrowsing
                            mainWindow.item.showContent = false
                            GlobalStateInfo.evfActive = true
                            GlobalStateInfo.evfLiveViewWasAutostarted = false
                            console.log("Starting transition to EVF")
                            if(wasInInstantPreview)
                            {
                                evfWindow.item.openPreView(false, false)
                            }
                            else
                            {
                                if ((!mainWindow.item.sleeping || GlobalStateInfo.evfLiveViewWasAutostarted)
                                        && (VideoControl.videoMode === VideoControl.Off)
                                        && (configstore.ExpMode !== Config.ExpMode_ManualQuick)
                                        && !(Camera.inSession && Camera.showLiveViewWhenFinished))
                                {
                                    evfWindow.item.closePreView()
                                    Camera.setLiveViewState(true)
                                    GlobalStateInfo.evfLiveViewWasAutostarted = true
                                }
                            }
                            Camera.setShowLiveViewWhenFinished((configstore.EVFPreviewTimeout == 0), true)
                            mainWindow.item.deactivate()
                            if (evfWindow.item !== null)
                            {
                                evfWindow.item.requestActivate()
                            }
                            PowerClient.setState(PowerClient.PowerStateActive)
                            if((VideoControl.videoMode === VideoControl.View))
                            {
                                VideoControl.restartLiveViewImageTimeout();
                            }
                        }
                        else
                        {
                            if (evfWindow.item !== null)
                            {
                                evfWindow.item.requestActivate()
                                evfWindow.item.focusErrorView()
                            }
                        }
                    }
                }
                SequentialAnimation {
                    PauseAnimation { duration: 50 }
                    ScriptAction {
                        script: {
                            evfWindow.item.showContent = true
                            console.log("Finished transition to EVF")
                        }
                    }
                }
            },
            Transition {
                to: "hdmi"
                ScriptAction {
                    script: {
                        mainWindow.item.activate(false, false)
                        mainSleepingConn.updatePowerClient(mainWindow.item.sleeping)
                        mainWindow.item.showContent = true
                        if ((evfWindow.item !== null) && (VideoControl.videoMode !== VideoControl.Off))
                        {
                            evfWindow.item.requestActivate()
                        }
                        else if(mainWindow.item != null)
                        {
                            console.log("Main Window requested to be Active")
                            mainWindow.item.requestActivate()
                            mainActivateTimer.start()
                        }
                        mainSleepingConn.updatePowerClient(mainWindow.item.sleeping)
                        evfWindow.item.closePreView()
                        if((VideoControl.videoMode === VideoControl.View))
                        {
                            VideoControl.restartLiveViewImageTimeout();
                        }
                    }
                }
                SequentialAnimation {
                    PauseAnimation { duration: (GlobalStateInfo.testMode ? 10 : 50) }
                    ScriptAction {
                        script: {
                            evfWindow.item.showContent = true
                            console.log("Finished transition to HDMI")
                        }
                    }
                }
            },
            Transition {
                from: "main"
                to: "sleeping"
                ScriptAction {
                    script: {
                        console.log("running transition from main to sleeping")
                    }
                }
            },
            Transition {
                from: "evf,evf_exit_stopping_session"
                to: "sleeping"
                ScriptAction {
                    script: {
                        console.log("running transition from evf to sleeping")
                        evfWindow.item.showContent = false
                        evfWindow.item.showPreview = false
                        if (GlobalStateInfo.evfLiveViewWasAutostarted && VideoControl.videoMode !== VideoControl.Record)
                        {
                            Camera.setLiveViewState(false)
                        }
                        Camera.setShowLiveViewWhenFinished(false, true)
                        if(VideoControl.videoMode === VideoControl.Record) {
                            Camera.setLiveViewState(false)
                            VideoControl.setVideoRecordState(false)
                        }
                        GlobalStateInfo.evfLiveViewWasAutostarted = false
                        control.evfWasActive = false
                        control.contentAddedDuringEvfActive = 0
                        mainWindow.item.showContent = true
                        mainWindow.item.disabled = false
                        mainWindow.item.requestActivate()
                        mainSleepingConn.updatePowerClient(mainWindow.item.sleeping)
                    }
                }
            },
            Transition {
                from: ""
                to: "main"
                ScriptAction {
                    script: {
                        console.log("running initial transition to main")
                        PowerClient.setState(PowerClient.PowerStateIdle)
                        PowerClient.setState(PowerClient.PowerStateActive)
                        BodySync.currentState = BodySync.MAIN
                        mainWindow.item.firstActivate()
                        mainWindow.item.showContent = true
                        if(!guiconfig.isRunningSimulation())
                        {
                            SystemD.startUnitNoWait("gui-visible.target")
                        }
                    }
                }
            },
            Transition {
                from: "evf,evf_exit_stopping_session"
                to: "main"
                ScriptAction {
                    script: {
                        console.log("running transition from evf to main")
                        evfWindow.item.showContent = false
                        evfWindow.item.showPreview = false
                        mainWindow.item.startEvfTimer()
                        console.log("Exiting EVF,",
                                    "pictures taken:", control.contentAddedDuringEvfActive,
                                    "exposing state:", Camera.exposing,
                                    "session state:", Camera.inSession,
                                    "Autostart of liveview:", GlobalStateInfo.evfLiveViewWasAutostarted,
                                    "Session stopped requested:", control.sessionStopped,
                                    "added during session:", mainWindow.item.photosAddedInSession,
                                    "video stream:", VideoControl.videoMode)
                        if(ErrorControl.code === Errors.ErrorExposureModePreventsLiveview)
                            ErrorControl.ack()
                        if (GlobalStateInfo.evfLiveViewWasAutostarted && VideoControl.videoMode !== VideoControl.Record)
                        {
                            Camera.setLiveViewState(false)
                        }
                        Camera.setShowLiveViewWhenFinished(false, !mainWindow.item.wasExposingInEvf)
                        if (configstore.CustomOption_ShowPreview && mainWindow.item.wasExposingInEvf) {
                            console.log("starting override of video mode")
                            VideoControl.overrideVideoMode(0, 1000)
                        }
                        if (Camera.inSession && GlobalStateInfo.haveHalfPress) {
                            mainWindow.item.activate(false, false)
                        } else {
                            var showPreview = ((mainWindow.item.wasExposingInEvf && configstore.CustomOption_ShowPreview) || evfWindow.item.isInPreview) &&
                                              !mainWindow.item.shouldShowSelfTimer() && !mainWindow.item.shouldShowIntervalTimer()
                            var showControl = ((GlobalStateInfo.evfLiveViewWasAutostarted && VideoControl.videoMode !== VideoControl.Record) || (VideoControl.videoMode === VideoControl.Off)) &&
                                    !mainWindow.item.shouldShowSelfTimer() && !mainWindow.item.shouldShowIntervalTimer()
                            mainWindow.item.activate(showPreview, showControl)
                        }
                        control.evfWasActive = false
                        control.contentAddedDuringEvfActive = 0
                        mainSleepingConn.updatePowerClient(mainWindow.item.sleeping)
                        if((VideoControl.videoMode === VideoControl.View))
                        {
                            VideoControl.restartLiveViewImageTimeout();
                        }
                    }
                }
                SequentialAnimation {
                    PauseAnimation { duration: 50 }
                    ScriptAction {
                        script: {
                            mainWindow.item.showContent = true
                            console.log("Finished transition to Main")
                        }
                    }
                }
            },
            Transition {
                to: "evf_exit_stopping_session"
                ScriptAction {
                    script: {
                        console.log("Entering", control.state,
                                    "pictures taken:", control.contentAddedDuringEvfActive,
                                    "exposing state:", Camera.exposing,
                                    "session state:", Camera.inSession,
                                    "Autostart of liveview:", GlobalStateInfo.evfLiveViewWasAutostarted,
                                    "Session stopped requested:", control.sessionStoped,
                                    "added during session:", mainWindow.item.photosAddedInSession)
                        if (GlobalStateInfo.evfLiveViewWasAutostarted && !GlobalStateInfo.haveHalfPress &&
                            VideoControl.videoMode !== VideoControl.Record)
                        {
                            Camera.setLiveViewState(false)
                        }
                        else if (!GlobalStateInfo.haveHalfPress)
                            Camera.setShowLiveViewWhenFinished(false, !mainWindow.item.wasExposingInEvf)
                    }
                }
            },
            Transition {
                ScriptAction {
                    script: {
                        console.log("running transition to", control.state)
                        evfWindow.item.showContent = false
                        control.evfWasActive = false
                        if (control.state !== "sleeping") {
                            mainWindow.item.activate(false, false)
                        }
                        mainSleepingConn.updatePowerClient(mainWindow.item.sleeping)
                        mainWindow.item.showContent = true
                        if (wegde_bodystate !== -1) {
                            BodySync.currentState = wegde_bodystate
                            wegde_bodystate = -1
                        }
                    }
                }
            }
        ]
    }
    Keys.onPressed: {
        event.accepted = false
        console.log("Unhandled key reached main:", event.key)
    }
    Timer {
        id: delayed_liveview
        interval: 200
        running: false
        repeat: false
        onTriggered: {
            console.log("Delayed liveview...")
            if (VideoControl.videoMode === VideoControl.Off || VideoControl.videoMode === VideoControl.Playback)
                Camera.setLiveViewState(true)
        }
    }
    function stopDelayedLiveView()
    {
        delayed_liveview.stop()
    }
    function commonKeyHandleReleased(event)
    {
        if (System.tethered_mode !== System.TetheredModeUSBLiveView) {
            if(MKeys.pressedFnAcc("HALFPRESS", event) || MKeys.pressedFnAcc("AF_D", event)) {
                console.log("Got half release")
                GlobalStateInfo.haveHalfPress = false
                Camera.stopSession()
                control.sessionStopped = true
            }
            else if (MKeys.pressedFnAcc("EXPOSURE", event)) {
                console.log("Got full release")
                Camera.stopExposing()
                if(mainWindow.item && (!configstore.selfTimerActive && !configstore.intervalActive && !configstore.bracketingActive && !configstore.focusBracketingActive))
                {
                    mainWindow.item.preventIdle(false)
                }
            }
            else if (MKeys.pressedFnAcc("EXP_CUSTOM", event))
            {
                stopExposure()
            }
            else if (MKeys.pressedFnAcc("CROPMODENEXT", event) || MKeys.pressedFnAcc("CROPMODEPREV", event))
            {
                if(cropModeLongPressTimer.running)
                {
                    cropModeLongPressTimer.stop()
                    cycleCropMode(MKeys.pressedFnAcc("CROPMODENEXT", event))
                }
            }
            else if (MKeys.pressedFnAcc("LIVEVIEW", event))
            {
                GlobalStateInfo.haveLiveViewPress = false
            }
        }
        else if (guiconfig.isWedge && MKeys.pressedFnAcc("STOPDOWN", event))
        {
            cambody.doStopDown(false)
        }
    }
    function commonKeyHandle(event)
    {
        console.log("common key")
        cropModeLongPressTimer.stop()
        if(control.state === "sleeping" || mainWindow.item.sleeping) {
            if(MKeys.pressedFnAcc("WAKEUP", event)) {
                console.log("wakeup power reached main, waking...")
                mainWindow.item.idleWakeupOrForceOff(true)
            }
            else if (MKeys.pressedFnAcc("CTRLSCREEN", event))
            {
                controlScreen()
            }
            return true
        }
        else if(MKeys.pressedFnAcc("TOGGLESLEEP", event)) {
             if(!(ContentModel.isFormatting || Upgrader.isProcessing)) {
                mainWindow.item.idleWakeupOrForceOff(false)
            }
            return true
        }
        else if (System.tethered_mode !== System.TetheredModeUSBLiveView && (MKeys.pressedFnAcc("HALFPRESS", event)))
        {
            console.log("Got half press")
            GlobalStateInfo.haveHalfPress = true
            if(guiconfig.isWedge && evfWindow.status === Loader.Ready && mainWindow.status === Loader.Ready)
            {
                if (configstore.CustomOption_LiveViewEVFOnly && System.camera_mode === System.CameraModeImage && control.state === "main")
                {
                    mainWindow.item.setTextTimer(qsTr("Live View in EVF Only") + guiconfig.emptyString)
                }
                else if ((VideoControl.videoMode === VideoControl.Off) || (VideoControl.videoMode === VideoControl.Playback))
                {
                    if(configstore.ExpMode === Config.ExpMode_ManualQuick)
                    {
                        if(!Camera.inSession)
                        {
                            Camera.startSession(false)
                            control.sessionStopped = false
                        }
                    }
                    else
                    {
                        delayed_liveview.restart()
                    }
                }
                else if (System.camera_mode === System.CameraModeVideo)
                {
                }
                else if (!Camera.inSession)
                {
                    var showLiveView = configstore.ExpMode !== Config.ExpMode_ManualQuick
                    Camera.startSession(showLiveView)
                    control.sessionStopped = false
                }
            }
            return true
        }
        else if(MKeys.pressedFnAcc("AF_D", event))
        {
            if(guiconfig.isWedge)
            {
                if (!(VideoControl.videoMode === VideoControl.Off || VideoControl.videoMode === VideoControl.Playback) &&
                    !(System.camera_mode === System.CameraModeVideo))
                {
                    var restartLiveViewAfterAFD = (VideoControl.videoMode !== VideoControl.Off);
                    var forceFindFocus = true;
                    Camera.startSession(restartLiveViewAfterAFD, forceFindFocus)
                }
            }
            return true
        }
        else if (System.tethered_mode !== System.TetheredModeUSBLiveView && MKeys.pressedFnAcc("EXPOSURE", event) && evfWindow.status === Loader.Ready && mainWindow.status === Loader.Ready)
        {
            console.log("Got full press")
            delayed_liveview.stop()
            GlobalStateInfo.haveHalfPress = false
            if (System.camera_mode === System.CameraModeVideo)
            {
                var start = (VideoControl.videoMode !== VideoControl.Record);
                VideoControl.setVideoRecordState(start)
            }
            else
            {
                var preventExposure = guiconfig.isWedge && configstore.CustomOption_RangeExpLock &&
                                      ((configstore.ExpMode === Config.ExpMode_ShutterSpeed && cambody.AV_out_of_range) ||
                                       (configstore.ExpMode === Config.ExpMode_Aperture && cambody.TV_out_of_range) ||
                                       (configstore.ExpMode === Config.ExpMode_Program && (cambody.TV_out_of_range || cambody.AV_out_of_range)))
                if (preventExposure) {
                    SoundControl.play(SoundControl.SndOutOfRangeMulti)
                } else {
                    var liveviewAfterExposure = ((control.state === "evf" && configstore.EVFPreviewTimeout === 0) ||
                                                 (control.state !== "evf" && !configstore.CustomOption_ShowPreview)) &&
                                                 configstore.ExpMode !== Config.ExpMode_ManualQuick &&
                                                 !configstore.intervalActive && !configstore.selfTimerActive && !configstore.bracketingActive && !configstore.focusBracketingActive
                    if (!Camera.inSession)
                    {
                        Camera.startSession(liveviewAfterExposure)
                    }
                    Camera.startExposing(liveviewAfterExposure)
                    if (!Camera.exposing) {
                        GlobalStateInfo.waitingForExpose = true
                    }
                    mainWindow.item.wasExposingWedge = true
                    if (GlobalStateInfo.evfActive) {
                        mainWindow.item.wasExposingInEvf = true
                    }
                }
                if(mainWindow.item && (!configstore.selfTimerActive && !configstore.intervalActive && !configstore.bracketingActive && !configstore.focusBracketingActive))
                    mainWindow.item.preventIdle(true)
            }
            if((ErrorControl.code !== Errors.ErrorNone) && ErrorControl.isAckable)
            {
                ErrorControl.ack()
            }
            return true
        }
        else if (MKeys.pressedFnAcc("AF_MF", event))
        {
            console.log("TouchWindow: got F key press.")
            if (Camera.canChange & Camera.PropFocusMode)
                Camera.FocusMode = (Camera.FocusMode === Config.Focus_MAN) ? Config.Focus_AFS : Config.Focus_MAN;
            return true
        }
        else if (System.tethered_mode !== System.TetheredModeUSBLiveView && MKeys.pressedFnAcc("EXP_CUSTOM", event) && evfWindow.status === Loader.Ready && mainWindow.status === Loader.Ready)
        {
            startExposure()
            return true
        }
        else if (guiconfig.isWedge && MKeys.pressedFnAcc("AE_L", event))
        {
            console.log("TouchWindow: got L key press.")
            cambody.onToggleAEL()
            return true
        }
        else if (MKeys.pressedFnAcc("WIFI", event))
        {
            if (!System.isTethered) {
                configstore.WIFI_power = !configstore.WIFI_power
            }
            return true
        }
        else if (guiconfig.isWedge && MKeys.pressedFnAcc("SELFTIMER", event))
        {
            configstore.selfTimerActive = !configstore.selfTimerActive
            return true
        }
        else if (guiconfig.isWedge && MKeys.pressedFnAcc("ESHUTTER", event))
        {
            configstore.eshutter = !configstore.eshutter
            return true
        }
        else if (MKeys.pressedFnAcc("DELETE", event))
        {
            if (!System.isTethered) {
                mainWindow.item.setToBrowse(true)
            }
            return true
        }
        else if (MKeys.pressedFnAcc("AFPOINTSEL", event))
        {
            if (VideoControl.videoMode !== VideoControl.Off)
                GlobalStateInfo.afSelectionActive = !GlobalStateInfo.afSelectionActive;
            return true
        }
        else if (MKeys.pressedFnAcc("CROPMODENEXT", event) || MKeys.pressedFnAcc("CROPMODEPREV", event))
        {
            if (!System.isTethered) {
                cropModeLongPressTimer.restart()
            }
            return true
        }
        else if (MKeys.pressedFnAcc("BROWSEMODE", event))
        {
            if (!System.isTethered) {
                if (GlobalStateInfo.evfActive) {
                    evfWindow.item.openPreView(true, false)
                } else {
                    mainWindow.item.setToBrowse()
                }
            }
            return true
        }
        else if (MKeys.pressedFnAcc("PROFILES", event))
        {
            mainWindow.item.loadProfilesMenu()
            return true
        }
        else if (MKeys.pressedFnAcc("RECORD", event))
        {
            customRecordVideo()
            return true
        }
        else if (MKeys.pressedFnAcc("AFPCYCLE", event))
        {
            GlobalStateInfo.afSselectedIndex = -1
            configstore.cycleAfPointSize()
            return true
        }
        else if (MKeys.pressedFnAcc("AUTOISO", event))
        {
            if (!System.isTethered) {
                mainWindow.item.gotoCameraMenuItem("Configuration", "SV_auto_max")
            }
            return true
        }
        else if (MKeys.pressedFnAcc("CTRLSCREEN", event))
        {
            console.log("ctrlscreen")
            controlScreen()
            return true
        }
        else if (MKeys.pressedFnAcc("LIVEVIEW", event))
        {
            GlobalStateInfo.haveLiveViewPress = true
            if (configstore.CustomOption_LiveViewEVFOnly && System.camera_mode === System.CameraModeImage && control.state === "main")
            {
                mainWindow.item.setTextTimer(qsTr("Live View in EVF Only") + guiconfig.emptyString)
            }
            else if(configstore.ExpMode !== Config.ExpMode_ManualQuick)
            {
                if (VideoControl.videoMode === VideoControl.Off || VideoControl.videoMode === VideoControl.Playback)
                {
                    delayed_liveview.start()
                }
                else
                {
                    stopDelayedLiveView()
                    Camera.setLiveViewState(false)
                }
            }
            return true
        }
        else if (MKeys.pressedFnAcc("FOCUSBRACKETING", event))
        {
            configstore.focusBracketingActive = !configstore.focusBracketingActive
            return true
        }
        else if (MKeys.pressedFnAcc("DRIVETONEAR", event))
        {
            lensToNear()
            return true
        }
        else if (MKeys.pressedFnAcc("CYCLEFOCUSSCANRANGE", event))
        {
            configstore.FocusScanRange = (configstore.FocusScanRange + 1) % 3
            GlobalStateInfo.overlayText = Settings.getDisplayValue("FocusScanRange", configstore.FocusScanRange)
            GlobalStateInfo.overlayHeader = qsTr("Autofocus Scan Range")
            GlobalStateInfo.overlayMode = ""
            GlobalStateInfo.overlayMode = "show_global_note"
            return true
        }
        else
        {
            return false
        }
    }
    function customRecordVideo()
    {
        if (guiconfig.isWedge)
        {
            if (BodySync.currentDialMode !== BodySync.DmVideo)
            return false
        }
        else
        {
            if (System.camera_mode !== System.CameraModeVideo)
            {
                System.camera_mode = System.CameraModeVideo
                startVideoTimer.start()
            }
        }
        var start = (VideoControl.videoMode !== VideoControl.Record);
        VideoControl.setVideoRecordState(start)
    }
    function controlScreen()
    {
            mainWindow.item.idleWakeupOrForceOff(true)
            mainWindow.item.setToControl()
    }
    function startExposure()
    {
        stopDelayedLiveView()
        if (System.camera_mode === System.CameraModeVideo) {
            var start = (VideoControl.videoMode !== VideoControl.Record);
            VideoControl.setVideoRecordState(start)
        }
        else
        {
            VideoControl.setZoomState(false)
            if (!Camera.exposing)
            {
                Camera.startSession(configstore.ExpMode !== Config.ExpMode_ManualQuick)
                control.sessionStopped = false
            }
            Camera.startExposing((control.state === "evf" || !configstore.CustomOption_ShowPreview) && (configstore.ExpMode !== Config.ExpMode_ManualQuick))
            if (!Camera.exposing) {
                GlobalStateInfo.waitingForExpose = true
            }
            mainWindow.item.wasExposingWedge = true
            if (GlobalStateInfo.evfActive) {
                mainWindow.item.wasExposingInEvf = true
            }
            if(mainWindow.item && (!configstore.selfTimerActive && !configstore.intervalActive && !configstore.bracketingActive && !configstore.focusBracketingActive))
                mainWindow.item.preventIdle(true)
        }
        if((ErrorControl.code !== Errors.ErrorNone) && ErrorControl.isAckable)
        {
            ErrorControl.ack()
        }
    }
    function stopExposure()
    {
        Camera.stopExposing()
        Camera.stopSession()
        control.sessionStopped = true
        cambody.forceFinishExposure()
        if (!configstore.selfTimerActive && !configstore.intervalActive && !configstore.bracketingActive && !configstore.focusBracketingActive)
            preventIdle(false)
    }
    Timer {
        id: startVideoTimer
        interval: 5
        onTriggered: {
            if (System.camera_mode !== System.CameraModeVideo)
            {
                startVideoTimer.restart()
            }
            else
            {
                var start = (VideoControl.videoMode !== VideoControl.Record);
                VideoControl.setVideoRecordState(start)
            }
        }
    }
    function cycleCropMode(forward) {
        GlobalStateInfo.overlayHeader = qsTr("CROP MODE")
        if (System.camera_mode === System.CameraModeImage) {
            var cropMode = configstore.aspectRatio
            if (forward) {
                cropMode = (cropMode === Config.RatioNoCrop) ? Config.Ratio1to1 :
                           (cropMode === Config.Ratio65to24) ? Config.RatioNoCrop :
                           (cropMode === Config.Ratio11to8p5) ? Config.Ratio297to210 : cropMode+1
            } else {
                cropMode = (cropMode === Config.Ratio1to1) ? Config.RatioNoCrop :
                           (cropMode === Config.RatioNoCrop) ? Config.Ratio65to24 :
                           (cropMode === Config.Ratio297to210) ? Config.Ratio11to8p5 : cropMode-1
            }
            if (cropMode === Config.Ratio3to2Crop &&
                (Lens.lens_family === Lens.HCLens || Lens.lens_family === Lens.HCCLens ||
                 Lens.lens_family === Lens.XCLens || Lens.lens_family === Lens.VLens)) {
                cropMode = cropMode+(forward ? 1 : -1)
            }
            configstore.aspectRatio = cropMode
            GlobalStateInfo.overlayText = Settings.getDisplayValue("aspectRatio", cropMode)
        } else {
            GlobalStateInfo.overlayText = qsTr("Crop Modes not available<br\>in Video Mode")
        }
        GlobalStateInfo.overlayMode = ""
        GlobalStateInfo.overlayMode = (System.camera_mode === System.CameraModeImage) ? "crop_mode" : "no_crop_in_video"
    }
    Timer {
        id: cropModeLongPressTimer
        running: false
        interval: 350
        repeat: false
        onTriggered: {
            if (System.camera_mode === System.CameraModeImage) {
                configstore.aspectRatio = Config.RatioNoCrop
                GlobalStateInfo.overlayText = Settings.getDisplayValue("aspectRatio", Config.RatioNoCrop)
            } else {
                GlobalStateInfo.overlayText = qsTr("Crop Modes not available<br\>in Video Mode")
            }
            GlobalStateInfo.overlayHeader = qsTr("CROP MODE")
            GlobalStateInfo.overlayMode = ""
            GlobalStateInfo.overlayMode = (System.camera_mode === System.CameraModeImage) ? "crop_mode" : "no_crop_in_video"
        }
    }
    function lensToNear()
    {
        lens.scanLens(Lens.ScanDirNear)
    }
}
