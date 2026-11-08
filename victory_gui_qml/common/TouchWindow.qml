import QtQuick 2.2
import QtQuick.Window 2.1

import com.hasselblad.storage 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.video 1.0
import com.hasselblad.upgrade 1.0
import com.hasselblad.power 1.0
import com.hasselblad.backlight 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.error 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.sound 1.0
import com.hasselblad.spiritlevel 1.0

import "qrc:///common"
import "qrc:/components"
import "qrc:///settings"
import "qrc:///liveview"

import "qrc:///settings/scripts/MenuItemImporter.js" as MenuItems
import "qrc:///scripts/Keys.js" as MKeys

Window {
    id: root
    objectName: "TouchWindow_root"
    title: "main"
    visible: true
    width: 640
    height: 480
    color: "transparent"
    visibility: fullscreen ? Window.FullScreen : Window.Windowed
    property bool simulation: width > 640 || height > 480
    property bool browseIn9View: false
    readonly property bool allowControlScreenWhileTethered: true
    property real controlScreenSwipeAreaHeight: browseIn9View && isBrowsing ? constants.swipeHeightShort : constants.swipeHeightNormal
    property Item previouslyActiveItem: null
    property alias sleeping: idle_detect.off
    property alias idleDetect: idle_detect //Needed by unittests since findChild() doesn't work for IdleDetect
    property bool disabled: false
    onDisabledChanged: console.log("Touch disabled:", disabled)
    property bool showContent: false
    onShowContentChanged: console.log("Touch showContent:", showContent)
    // Consider us ready when the loading of camera view is loaded
    property bool isReady: camera_view_loader.status === Loader.Ready
    property bool allowCameraView: !ContentModel.isFormatting && ErrorControl.code === Errors.ErrorNone && System.system_state !== System.StateUpgrade
    property bool isInstantPreview: false
    property bool isBrowsing: false
    property bool isInHDMI: false
    // Prohibit unnecessary state change (for instance when turning off live view)
    property bool prohibitStateChange: false
    property bool wasExposingWedge: false //True from full press until exposure canceled or leaving LV/insession.
    property bool wasExposing: false //Valid after leaving Camera.exposing and 1 second forward
    property bool wasExposingInEvf: false
    property bool evfExitTimeoutActive: false
    property int photosAddedInSession: 0
    property alias subloader_dialmode_active: dial_loader.active
    property bool mediaBrowseDeleteOnLoad: false
    property bool haveHalfPress: false
    property alias formatLoaderActive: format_card_loader.active

    GlobalNotification {
        showPopup: VideoControl.videoMode === VideoControl.Off || isInHDMI
    }

    onIsInHDMIChanged: console.log("IsInHDMI changed to", isInHDMI)

    // === START Properties triggering state changes
    Connections {
        target: root
        onDisabledChanged: { checkStateChange() }
    }
    Connections {
        target: root
        onIsInHDMIChanged: { checkStateChange() }
    }
    Connections {
        target: ErrorControl
        onCodeChanged: { checkStateChange() }
        onIsAckableChanged: { checkStateChange() }
    }
    Connections {
        target: System
        onSystem_stateChanged: { checkStateChange() }
    }
    Connections {
        target: Upgrader
        onIsProcessingChanged:  { checkStateChange() }
    }
    Connections {
        target: GlobalStateInfo
        onWaitingForExposeChanged: {
            //Only check activation since checking deactivation results in race condition with Camera.exposing
            if (GlobalStateInfo.waitingForExpose) { checkStateChange() }
        }
        onWaitingForLiveViewChanged: { checkStateChange() }
    }
    Connections {
        target: Camera
        onExposingChanged: { checkStateChange() }
        onSelfTimerCountDownChanged: { checkStateChange() }
        onIntervalTimerCountDownChanged: { checkStateChange() }
        onPendingLiveViewChanged: { checkStateChange() }
    }
    Connections {
        target: configstore
        onSelfTimerActiveChanged: { checkStateChange() }
        onIntervalActiveChanged: { checkStateChange() }
        onBracketingActiveChanged: { checkStateChange() }
        onFocusBracketingActiveChanged: { checkStateChange() }
    }
    Connections {
        target: BodySync
        onHdmiCableConnectedChanged: { checkStateChange() }
        onCurrentDialModeChanged: { checkStateChange() }
    }
    Connections {
        target: idle_detect
        onOffChanged: { checkStateChange() }
    }
    Connections {
        target: VideoControl
        onPipelineStateChanged: {
            checkStateChange()
        }
        onVideoModeChanged: {
            checkStateChange()
        }
    }

    // === END Properties triggering state changes

    //     Note! If adding any new properties to this function you also need to add them to the
    //       "Properties triggering state changes" section above in order for this function to be
    //       called on changes for these properties.

    // Helper function which returns true if self timer/interval/bracketing is ongoing
    function timerSessionActive() {
        return (configstore.selfTimerActive && Camera.selfTimerCountDown > 0) ||
               (configstore.intervalActive && Camera.intervalTimerCountDown > 0)
    }

    function checkStateChange() {
        var next = "-"
        if (root.disabled && !Camera.inSession) {
            next = "disabled"
        } else if ((ErrorControl.code === Errors.ErrorBatteryExhausted) && !root.disabled) {
            next = "batteryexhausted"
        } else if (ErrorControl.code !== Errors.ErrorNone && !ErrorControl.isAckable && !root.disabled) {
            next = "error"
        } else if ((System.system_state === System.StateUpgrade && Upgrader.isProcessing) || Upgrader.isProcessing && !root.disabled) {
            next = "updating"
        } else if (System.system_state === System.StateUpgrade && !Upgrader.isProcessing && !root.disabled) {
            next = "update_finished"
        } else if ((System.system_state === System.StateShutdown || System.system_state === System.StatePrepareShutdown) && !root.disabled) {
            next = "shutdown"
        } else if ((!guiconfig.isWedge || (guiconfig.isWedge && (isInHDMI || timerSessionActive()))) &&
                   (GlobalStateInfo.waitingForExpose || Camera.exposing || timerSessionActive())) {

            // Don't go from browse_view or camera_view to in_session during interval
            if (!guiconfig.isWedge || !configstore.intervalActive ||
                states.state != "browse_view" && states.state != "camera_view")
                next = "in_session"

        } else if (!root.disabled && !BodySync.hdmiCableConnected &&
                   // On wedge, zap liveview if we go to standby, we can not do
                   // that on H6 since that might interfere with exposing since
                   // half press results in shutting the GUI
                   (!guiconfig.isWedge || !idle_detect.off) &&
                   VideoControl.pipelineState === VideoControl.PipelineLocal &&
                   VideoControl.videoMode !== VideoControl.Off && VideoControl.videoMode !== VideoControl.Playback) {
            if (configstore.CustomOption_LiveViewEVFOnly && System.camera_mode === System.CameraModeImage)
            {
                next = "camera_view"
            }
            else
            next = "liveview"
        } else if (isInHDMI && (Camera.pendingLiveView === Camera.PendNone && VideoControl.videoMode !== VideoControl.Off) && (VideoControl.videoMode !== VideoControl.Playback)) {
            next = "hdmi"
        } else if (states.state === "hdmi" && Camera.pendingLiveView !== Camera.PendOn && VideoControl.pipelineState !== VideoControl.PipelineLocal && VideoControl.videoMode === VideoControl.Off) {
            // Goto camera_view leaving hdmi live view, but not during exposure.
            next = "camera_view"
        } else if (states.state === "liveview" && Camera.pendingLiveView !== Camera.PendOn && VideoControl.pipelineState !== VideoControl.PipelineLocal && VideoControl.videoMode === VideoControl.Off) {
            // Goto camera_view when liveview times out but not during exposure.
            next = "camera_view"
        } else if (BodySync.currentDialMode === BodySync.DmManualQuick && states.state === "liveview") {
            next = "camera_view"
        } else if (BodySync.currentDialMode === BodySync.DmManualQuick && states.state === "in_session" &&
                   !GlobalStateInfo.waitingForExpose && !Camera.exposing && !Camera.inSession) {
            next = "camera_view"
        } else { //No match
            //Keep current state
        }
        if (next !== "-" && states.state !== next) {
            console.log("TouchWindow.qml automatic state change", states.state, "->", next)
            states.state = next
        } else {
            console.log("keeping state", states.state)
        }
    }

    function setState(state) {
        console.log("TouchWindow.qml manual state change", states.state, "->", state)
        states.state = state
    }

    onPhotosAddedInSessionChanged: {
        console.log("TouchWindow: Number photos in session changed:", photosAddedInSession)
        if (states.state !== "disabled" &&
            photosAddedInSession > 0 &&
            configstore.CustomOption_ShowPreview &&
            !configstore.bracketingActive &&
            !configstore.focusBracketingActive &&
            ErrorControl.code === Errors.ErrorNone)
        {
            if ((guiconfig.isWedge && !System.isTethered) ||
                (isInHDMI && configstore.CameraType !== Config.CameraTypeHsystem)) {
                setState("browse_view")
            } else {
                setState("instant_preview")
            }
        }
        else
            console.log("Not going to browse_view")
    }

    Timer {
        id: dumpActiveFocusTimer
        interval: 2000
        repeat: false
        running:  false
        onTriggered: {
            console.log("dumping the hierarchy")
            guiconfig.dumpObjectHierarchy(activeFocusItem, "/media/icons/QmlDump.txt", null)
        }
    }

    onActiveFocusItemChanged: {
        if(null != activeFocusItem) {
            console.log("ActiveFocusItem changed:", activeFocusItem, guiconfig.itemProperties(activeFocusItem, false, true, 0))
//            guiconfig.printItemProperties(activeFocusItem)
            // DEBUG: Enable this timer to get full dump of QML object-hierarchy.
            // dumpActiveFocusTimer.restart()

            var itemStr = activeFocusItem.toString()
            //Key presses are ignored if QQuickRootItem has focus. We should not end up in this state, but add a failsafe just in case.
            if (itemStr.search(/QQuickRootItem/) === 0) { //String starts with ...
                focusRestoreTimer.restart()
            }
        }
    }

    Timer {
        id: focusRestoreTimer
        interval: 500
        onTriggered: {
            var itemStr = activeFocusItem.toString()
            if (itemStr.search(/QQuickRootItem/) >= 0) { //String starts with ..
                console.log("Restoring focus to TouchWindow viewArea")
                viewArea.focus = true
            }
        }
    }

    function deactivate() {
        console.log("TouchWindow: Deactivate")
        root.disabled = true
    }

    function firstActivate() {
        // first timer we want no animation, since system is too busy in order to make it smooth.
        camera_view_loader.y = 0
        activate(false, states.state === "disabled" || states.state === "main")
    }

    // activate was called when errorPopupLoader got active, which it was when root.disabled was set.
    // That caused a binding loop, with erroneous behaviour. To prevent that, activate is split in two parts
    function activate(showPreview, showCamera) {
        console.log("TouchWindow: Activate", showPreview, showCamera, Camera.inSession)
        root.disabled = false
        activateImpl(showPreview, showCamera)
    }

    function activateImpl(showPreview, showCamera) {
        if(errorPopupLoader.active && null !== errorPopupLoader.item && ErrorControl.code !== Errors.ErrorNone)
        {
            setState("camera_view")
            errorPopupLoader.item.forceActiveFocus()
            previouslyActiveItem = camera_view_loader.item
        }
        else
        {
            if (showPreview && !shouldShowBracketing())
            {
                Camera.setLiveViewState(false)
                // show preview of last taken image.
                setState("browse_view")
            }
            else if (showCamera)
            {
                Camera.setLiveViewState(false)

                if (shouldShowBracketing()) {
                    setState("in_session")
                } else {
                    setState("camera_view")
                }
            }
            else if (Camera.inSession && !BodySync.hdmiCableConnected &&
                     ((VideoControl.videoMode === VideoControl.Off) ||
                      (VideoControl.pipelineState !== VideoControl.PipelineLocal)) &&
                     root.photosAddedInSession === 0)
            {
                if((configstore.ExpMode === Config.ExpMode_ManualQuick) &&
                   !shouldShowSelfTimer() && !shouldShowIntervalTimer() && !shouldShowBracketing())
                {
                    setState("in_session_camera_view")
                }
                else {
                    if (evfExitTimeoutActive && !shouldShowSelfTimer() && !shouldShowIntervalTimer() && !shouldShowBracketing()) {
                        setState("browse_view")
                    } else {
                        setState("in_session")
                    }
                }
            }
        }

        requestActivate()
        // If none of the above matched, the when clauses will choose state

        // Make sure to wake us up...
        if (showPreview || showCamera || Camera.inSession ||
                (VideoControl.pipelineState === VideoControl.PipelineLocal &&
                 VideoControl.videoMode !== VideoControl.Off))
            idle_detect.notifyActivity()
    }

    function setPreviouslyActiveItem()
    {
        previouslyActiveItem = activeFocusItem
        console.log("Previously active item set to: ", previouslyActiveItem)
    }

    function setToBrowse(set_delete)
    {
        if (set_delete === undefined)
            set_delete = false

        if (media_browse_loader.active && set_delete) {
            media_browse_loader.item.deleteImage()
        } else {
            mediaBrowseDeleteOnLoad = set_delete
        }

        if(!(states.state === "liveview" && VideoControl.videoMode === VideoControl.Record))
        {
            // Must turn off video control here, otherwise the videoMode-changed signal will set state to camera_view
            if (VideoControl.videoMode !== VideoControl.Off) {
                prohibitStateChange = true
            }
            Camera.setLiveViewState(false)
            setState("browse_view")
        }
    }

    function setToMain()
    {
        media_browse_loader.active = false;
        // Must turn off video control here, otherwise the videoMode-changed signal will set state to camera_view
        if (VideoControl.videoMode !== VideoControl.Off) {
            prohibitStateChange = true
        }
        Camera.setLiveViewState(false)
        setState("main")
    }

    function setToControl()
    {
        Camera.setLiveViewState(false)
        setState("camera_view")
    }

    function gotoCameraMenuItem(subMenu, menuItem)
    {
        setToMain()
        main_screen.item.loadCameraMenuItem(subMenu, menuItem)
    }

    function loadProfilesMenu()
    {
        setToMain()
        main_screen.item.loadProfilesMenu()
    }

    function loadGreyBalanceMenu()
    {
        setToMain()
        main_screen.item.loadGreyBalanceMenu()
    }

    Loader {
        objectName: "TouchWindow_CameraMockup"
        anchors.centerIn: parent
        source: guiconfig.isWedge ? "qrc:///CameraMockupWedge.qml" : "qrc:///CameraMockup.qml"
        active: root.simulation
        width: 800
        height: guiconfig.isWedge ? 800 : 640
    }

    Item {
        objectName: "TouchWindow_viewArea"
        id: viewArea
        anchors.centerIn: parent
        width: 640
        height: 480
        Keys.onPressed: {
            if(event.isAutoRepeat || states.state === "updating")
                return

            event.accepted = true

            if (MKeys.pressedFn("PLAY", event.key)) {
                if (prodinfo.isNewH6DisplayQml()) {
                    shutdownLongPressTimer.start()
                } else {
                    if(!System.isTethered)
                        setToBrowse()
                }
            } else if (MKeys.pressedFn("MENU", event.key)) {
                console.log("touchwindow menukey")

                if (shouldShowIntervalTimer() && (states.state === "in_session" || states.state === "browse_view")) {
                    setToControl()
                }
                else if (shouldShowIntervalTimer())
                    setState("in_session")
                else if (System.isTethered) {
                    if(states.state === "liveview")
                    {
                        setToControl()
                    }
                } else {//Not tethered
                    if(states.state === "main")
                    {
                        setToControl()
                    }
                    else
                    {
                        setToMain()
                    }
                }
            } else if (MKeys.pressedFn("FORMAT", event.key)) {
                // Must not be in Video Recording Mode
                if(!(states.state === "liveview" && VideoControl.videoMode === VideoControl.Record) && !System.isTethered) {
                    // Turn of Live View. Since we must set active focus to something else if live view is running
                    // we check that first
                    if(VideoControl.videoMode === VideoControl.Playback)
                    {
                        // Remember last item that had focus
                        previouslyActiveItem = root.activeFocusItem
                        // Stop playback
                        VideoControl.setVideoPlaybackState(false, "", 0)
                    }
                    else if(VideoControl.videoMode !== VideoControl.Off)
                    {
                        // Remember last item that had focus
                        setState("camera_view")
                        camera_view_loader.item.forceActiveFocus()
                        previouslyActiveItem = camera_view_loader.item
                        if (VideoControl.videoMode === VideoControl.Zoom) {
                            BodySync.currentState = BodySync.MAIN //Will end up in control screen after closing format popup
                        }
                        // Stop live view
                        Camera.setLiveViewState(false);
                    }
                    else
                    {
                        // Remember last item that had focus
                        previouslyActiveItem = root.activeFocusItem
                    }
                    console.log("Showing Format Dialog")
                    format_card_loader.active = true
                    format_card_loader.focus = true
                }
            }
            else if (guiconfig.isWedge && MKeys.pressedFnAcc("ISO_WB", event))
            {
                // Go to control screen if not in live view
                if(states.state !== "liveview") {
                    // Not in live view
                    setState("camera_view")
                    camera_view_loader.item.isoWbHandler()
                }
            }
            else if (MKeys.pressedFnAcc("SPIRITLEVEL", event))
            {
                if (states.state !== "spirit_level")
                {
                    spiritLevelView.previousState = states.state
                    setState("spirit_level")
                }
                else
                {
                    spiritLevelView.active = false
                    setState(spiritLevelView.previousState)
                }
            }
            else if (MKeys.pressedFnAcc("INTERVAL", event))
            {
                if (states.state === "main" || states.state === "camera_view" || states.state === "liveview") {
                    configstore.intervalActive = !configstore.intervalActive
                }
                event.accepted = true
            }
            else if (MKeys.pressedFnAcc("BRACKETING", event))
            {
                if (states.state === "main" || states.state === "camera_view" || states.state === "liveview") {
                    configstore.bracketingActive = !configstore.bracketingActive
                }
                event.accepted = true
            }
            else if (MKeys.pressedFnAcc("GREYBALANCE", event))
            {
                if (configstore.ExpMode !== Config.ExpMode_FullAuto) {
                    setState("grey_balance_tool")
                }
                event.accepted = true
            }
            else if (MKeys.pressedFnAcc("ISO", event))
            {
                if(states.state !== "liveview") {
                    // Not in live view
                    setState("camera_view")
                    camera_view_loader.item.isoHandler()
                }
            }
            else if (MKeys.pressedFnAcc("WB", event))
            {
                if(states.state !== "liveview") {
                    // Not in live view
                    setState("camera_view")
                    camera_view_loader.item.wbHandler()
                }
            }
            else
            {
                console.log("TouchWindow: key event accepted, ended up in else clause")
                if((configstore.ExpMode !== Config.ExpMode_FullAuto) && MKeys.pressedFn("AF_MF", event.key))
                {
                    // Go to control screen if not in live view
                    if(states.state !== "liveview")
                        // Not in live view
                    {
                        setState("camera_view")
                    }

                    // Toggle AF/MF is handled in parent level
                    event.accepted = false
                }
                if(commonKeyHandle(event))
                {
                    // Do nothing
                }
                else
                {
                    event.accepted = false
                }
            }

        }

        Keys.onReleased: {
            if (MKeys.pressedFn("PLAY", event.key)) {
                if (prodinfo.isNewH6DisplayQml()) {
                    shutdownLongPressTimer.stop()

                    if(!System.isTethered)
                        setToBrowse()
                }
                return
            }

            if (event.isAutoRepeat || System.tethered_mode === System.TetheredModeUSBLiveView)
                return

            commonKeyHandleReleased(event)
        }

        Loader {
            objectName: "main_screen_loader"

            id: main_screen
            property bool show: false
            visible: show && status === Loader.Ready
            source: guiconfig.mainMenuName
            anchors.fill: parent
            focus: true
            asynchronous: true
            active: root.isReady
            enabled: !camera_view_loader.visible
            onLoaded: {
                console.log("Mainscreen loaded")
                item.simulation = root.simulation
            }
            Binding {
                when: main_screen.item != null && camera_view_loader.item !== null
                target: main_screen.item
                property: "childOpacity"
                value: main_screen.item != null ? (-camera_view_loader.y - main_screen.item.y) / main_screen.item.height : 0
            }
            Binding {
                when: main_screen.visible
                target: main_screen.item
                property: "focus"
                value: main_screen.focus
            }
            Connections {
                target: main_screen.item ? main_screen.item : null
                onCloseMain: {
                    root.setToControl()
                }
            }
        }

        Loader {
            objectName: "selfTimerScreenLoader"
            id: selfTimerScreen
            anchors.fill: parent
            active: false
            visible: active
            asynchronous: true
            focus: active
            source: "qrc:///common/SelfTimerScreen.qml"
            onActiveChanged: {
                if(!active)
                {
                    //If we already have started to show preview then don't interfere
                    if (states.state !== "browse_view") {
                        // Just make sure we have something listening to button events when this is deactivated
                        // The loader we call forceActiveFocus for must be enabled to avoid QQuickRootItem from getting focus since keypresses don't arrive then!
                        if (camera_view_loader.enabled) {
                            if (!configstore.CustomOption_ShowPreview || guiconfig.isWedge) {
                                camera_view_loader.forceActiveFocus()
                            }
                        } else {
                            //This should be safe since main_screen.enabled == !camera_view_loader.visible
                            main_screen.forceActiveFocus()
                        }
                    }
                }
            }
        }

        Loader {
            objectName: "intervalTimerScreenLoader"
            id: intervalTimerScreen
            anchors.fill: parent
            active: false
            visible: active
            asynchronous: true
            focus: active
            source: "qrc:///common/IntervalTimerScreen.qml"
            onActiveChanged: {
                if(!active)
                {
                    //If we already have started to show preview then don't interfere
                    if (states.state !== "browse_view") {
                        // Just make sure we have something listening to button events when this is deactivated
                        // The loader we call forceActiveFocus for must be enabled to avoid QQuickRootItem from getting focus since keypresses don't arrive then!
                        if (camera_view_loader.enabled) {
                            if (!configstore.CustomOption_ShowPreview || guiconfig.isWedge) {
                                camera_view_loader.forceActiveFocus()
                            }
                        } else {
                            //This should be safe since main_screen.enabled == !camera_view_loader.visible
                            main_screen.forceActiveFocus()
                        }
                    }
                }
            }
        }
        Loader {
            objectName: "bracketingScreenLoader"
            id: bracketingScreen
            anchors.fill: parent
            active: false
            visible: active
            asynchronous: true
            focus: active
            source: "qrc:///common/BracketingScreen.qml"
            onActiveChanged: {
                if(!active)
                {
                    //If we already have started to show preview then don't interfere
                    if (states.state !== "browse_view") {
                        // Just make sure we have something listening to button events when this is deactivated
                        // The loader we call forceActiveFocus for must be enabled to avoid QQuickRootItem from getting focus since keypresses don't arrive then!
                        if (camera_view_loader.enabled) {
                            if (!configstore.CustomOption_ShowPreview || guiconfig.isWedge) {
                                camera_view_loader.forceActiveFocus()
                            }
                        } else {
                            //This should be safe since main_screen.enabled == !camera_view_loader.visible
                            main_screen.forceActiveFocus()
                        }
                    }
                }
            }
        }


        Loader {
            objectName: "media_browse_loader"
            id: media_browse_loader
            anchors.fill: parent
            asynchronous: true
            active:false
            visible: active
            property bool isInstantPreview: false
            source: "qrc:///components/MediaBrowseView.qml"
            function browse9ViewChanged(browseIsIn9View)
            {
                root.browseIn9View = browseIsIn9View
            }
            property bool preventControlScreenSwipe: false

            onStatusChanged: {
                if (status === Loader.Ready)
                {
                    root.browseIn9View = item.is9ViewActive
                    item.isInstantPreview = isInstantPreview
                    item.isIn9View.connect(browse9ViewChanged)
                    console.log("browse9view connected now")
                    if (root.simulation)
                    {
                        item.simulation = true
                    }
                    // In case the notify signal fired before the complete object got loaded...
                    if (item.hasLoadedCurrent)
                        root.notifyCurrentImageLoaded()

                    if (mediaBrowseDeleteOnLoad) {
                        mediaBrowseDeleteOnLoad = false
                        item.deleteImage()
                    }


                    idle_detect.onTouchEvent.connect(item.hideInstantAVTV)
                }
            }
        }

        //Used to handle changes to aspectRatio from the menu
        AFCalc {
            id: afc
            screenWidth: root.width
            screenHeight: root.height
            isActive: VideoControl.videoMode !== VideoControl.View
            idText: "In TouchWindow"
        }

        Loader {
            objectName: "live_view_loader"
            id: live_view_loader
            anchors.fill: parent
            asynchronous: true
            visible: active
            active: false
            source: "qrc:///liveview/LiveView.qml"
            Connections {
                target: live_view_loader.item
                onRequestMainScreen: {
                    setState("main")
                }
            }
            onLoaded: {
                item.inActiveWindow = true
            }

            //Need an extra overlay here to crop the liveview until the LiveViewOverlay has been loaded
            CropOverlay {
                anchors.fill: parent
                visible: live_view_loader.active && live_view_loader.status === Loader.Loading &&
                         VideoControl.videoMode !== VideoControl.Zoom && System.camera_mode === System.CameraModeImage
                onVisibleChanged: {
                    if (visible) {
                        calcCropping(configstore.aspectRatio)
                    }
                }
            }

            // the following connection is for taking all kinds of video recording stops back to camera view.
            Connections {
                target: VideoControl
                onVideoModeChanged: {
                    console.log("VideoModeChange from", target.previousVideoMode, "to", target.videoMode)
                    if (target.videoMode === VideoControl.View) {
                        GlobalStateInfo.waitingForLiveView = false
                    }
                    if((((System.camera_mode === System.CameraModeVideo) && (target.videoMode !== VideoControl.Record && target.previousVideoMode === VideoControl.Record)) ||
                            ((System.camera_mode === System.CameraModeImage) && (target.videoMode === VideoControl.Off && target.previousVideoMode === VideoControl.View)) ) &&
                            !root.prohibitStateChange && !GlobalStateInfo.evfInPreview && states.state !== "grey_balance_tool")
                    {
                        if (!(evfExitTimeoutActive && wasExposingInEvf && configstore.CustomOption_ShowPreview)) {
                            setState(Camera.inSession ? "in_session" : "camera_view")
                        }
                    }
                    if (target.videoMode === VideoControl.Off)
                    {
                        if (target.previousVideoMode !== VideoControl.Playback)
                        {
                            cambody.doStopDown(false)
                        }
                    }
                    else
                    {
                        // Make sure we can see video streams (there are some cases where camera is in sleep mode,
                        // for instance if half press was previously pressed, and live view started by custom button)
                        idle_detect.notifyActivity()
                    }
                    root.prohibitStateChange = false
                }
            }
        }

        Loader {
            objectName: "spiritLevelView"
            id: spiritLevelView
            anchors.fill: parent
            active: false
            visible: active
            asynchronous: true
            focus: active
            source: "qrc:///settings/SpiritLevelView.qml"

            property string previousState: ""

            onLoaded: console.log("SpiritLevelView loaded")
            onActiveChanged: console.log("SpiritLevelVIew activated")
        }

        Loader {
            objectName: "greyBalanceToolView"
            id: greyBalanceToolView
            anchors.fill: parent
            active: false
            visible: active
            asynchronous: true
            focus: active

            onLoaded: console.log("greyBalanceToolView loaded")
            onActiveChanged: {
                console.log("greyBalanceToolView active", active)
                if (active) {
                    setSource("qrc:///components/GreyBalanceTool.qml", {"startedFromMenu": false, "startIndex": (isBrowsing ? GlobalStateInfo.greyBalanceIndex : -1)})
                }
            }
            Connections {
                target: greyBalanceToolView.item ? greyBalanceToolView.item : null
                onShowControl: setState("camera_view")
            }
        }

        // Put the swipe so only the top edges will be active
        MouseArea {
            objectName: "swipe_area"
            id: swipe_area
            enabled: !root.disabled &&
                     ((camera_view_loader.sourceItem === null) || (!camera_view_loader.sourceItem.preventSwipe)) &&
                     !(states.state === "liveview" && VideoControl.videoMode === VideoControl.Record) &&
                     !media_browse_loader.preventControlScreenSwipe &&
                     !format_card_loader.active &&
                     (allowControlScreenWhileTethered || !System.isTethered) &&
                     !selfTimerScreen.active && !GlobalStateInfo.evfActive && !GlobalStateInfo.preventTopSwipe
            anchors {
                top: main_screen.top
                bottom: main_screen.bottom
                right: main_screen.right
                left: main_screen.left
                bottomMargin: main_screen.height - controlScreenSwipeAreaHeight
                onBottomMarginChanged: console.log ("Camera View Swipe Area changed bottom margin:", swipe_area.anchors.bottomMargin)
            }
            drag {
                target: camera_view_loader
                axis: Drag.YAxis
                minimumY: main_screen.y - camera_view_loader.height
                maximumY: main_screen.y
                threshold: constants.dragThreshold
                filterChildren: true
            }
            propagateComposedEvents: true
            property int changeThreshold: (main_screen.y - main_screen.height * (constants.swipeLengthDividor - 1) / constants.swipeLengthDividor)
            drag.onActiveChanged: {
                if (!drag.active) {
                    // Its visible make sure it flies in or out
                    if (drag.target.y > changeThreshold)
                    {
                        // In order for state changes to really take effect, we "land" in a temporary state first
                        // (in case we already were at "camera_view")
                        // If we don't do that, CameraView might be "hanging" in the middle of the screen if we swipe it up
                        // and then regret and swipe almost down again
                        if (states.state !== "camera_view")
                        {
                            setState("camera_view")
                        }
                        else
                            drag.target.y = 0
                    } else {
                        if (states.state == "camera_view") {
                            if(System.isTethered)
                                setState("instant_preview")
                            else
                            {
                                setState("main")
                            }
                        } else {
                            // Make sure the curtain flies up
                            drag.target.y = -drag.target.height
                        }
                    }
                } else {
                    if (states.state == "camera_view") {
                        if(System.isTethered)
                            setState("instant_preview")
                    }
                    //console.log("Drag Active")
                }
            }
            // Put camera_view_loader as a child to the Mouse Area, otherwise swipe will not work correctly
            Loader {
                objectName: "camera_view_loader"
                id: camera_view_loader
                width: main_screen.width
                height: main_screen.height + constants.viewEndLineWidth
                y: main_screen.y - height
                anchors.horizontalCenter: swipe_area.horizontalCenter
                asynchronous: true
                source: guiconfig.controlScreenName
                readonly property Item sourceItem: item
                // We want this not to load at startup, but once loaded should always be in memory
                // to preserve focus state,
                active: false
                visible: y > main_screen.y - height

                onLoaded: {
                    console.log("Control screen loaded", guiconfig.controlScreenName)
                    camera_view_loader.sourceItem.focusChanged();
                }
                onVisibleChanged: {
                    if(!visible && item !== null) {
                        if(item.allowHighligtBracket !== undefined)
                        {
                            console.log("C")
                            item.allowHighligtBracket = false;
                        }
                        item.focus = false;
                    }
                }
            }
        }

        Loader {
            objectName: "evfTouchpadLoader"
            id: evfTouchpadLoader
            anchors.fill: parent
            active: root.disabled && guiconfig.isWedge && GlobalStateInfo.evfActive && !GlobalStateInfo.evfInPreview &&
                    ((!haveHalfPress && !Camera.inSession) || (Camera.FocusMode === Config.Focus_AFC && !Camera.exposing)) &&
                    !timerSessionActive() &&
                    configstore.ExpMode !== Config.ExpMode_ManualQuick
            visible: active
            asynchronous: true
            focus: active
            source: "qrc:///liveview/Touchpad.qml"
            onActiveChanged: console.log("EVF touchpad activate", active)
            onLoaded: {
                item.initValues()
            }
        }

        Loader {
            objectName: "evfBrowseTouchpadLoader"
            id: evfBrowseTouchpadLoader
            anchors.fill: parent
            active: root.disabled && guiconfig.isWedge && GlobalStateInfo.evfActive && GlobalStateInfo.evfInPreview &&
                    !haveHalfPress && !Camera.inSession && configstore.evf_tp_image_browse &&
                    !timerSessionActive() &&
                    configstore.ExpMode !== Config.ExpMode_ManualQuick
            visible: active
            asynchronous: true
            focus: active
            source: "qrc:///browseview/BrowseTouchpad.qml"
            onActiveChanged: console.log("EVF browse touchpad activate", active)
            onLoaded: {
                item.initValues()
            }
        }

        Loader {
            objectName: "format_card_loader"
            id: format_card_loader
            anchors.fill: parent
            visible: active
            source: "qrc:///common/CardFormat.qml"
            onLoaded: console.log("Loaded CardFormat")
            active: false
            onActiveChanged: {
                if(!active)
                {
                    if(previouslyActiveItem != null)
                    {
                        previouslyActiveItem.forceActiveFocus()
                        // For some unknown reason the active focus is set to previous active item, but then immediately
                        // set to something else. In order to get correct active item we set it again. QML Magic:
                        previouslyActiveItem.forceActiveFocus()
                        previouslyActiveItem = null
                    }
                }
            }
        }

        Loader {
            id: hdmi_loader
            objectName: "HDMIView_loader"
            source: "qrc:///liveview/HDMIView.qml"
            anchors.fill: viewArea
            visible: active
            focus: true
            active: false
            onActiveChanged: {
                if(!active)
                {
                    // Just make sure we have something listening to button events when this is deactivated
                    //main_screen.forceActiveFocus()
                    camera_view_loader.item.forceActiveFocus()
                }
            }
        }
    }

    // Error popup for ackable errors....
    Loader {
        objectName: "errorAckPopupLoader"
        id: errorPopupLoader
        anchors.fill: parent
        active: (ErrorControl.code !== Errors.ErrorNone) && ErrorControl.isAckable && !root.disabled
        source: "qrc:///components/popups/ErrorPopup.qml"
        focus: active
        property int previousBodyState: BodySync.MAIN

        onActiveFocusChanged: {
            //For some reason the popup item does not always get focus
            if (activeFocus) {
                item.focus = true
            }
        }

        onActiveChanged: {
            if (active)
            {
                if (GlobalStateInfo.errorPopupOwner === "" && BodySync.focusSurface === "main") {
                    GlobalStateInfo.errorPopupOwner = BodySync.focusSurface
                    root.previouslyActiveItem = root.activeFocusItem
                    item.forceActiveFocus()

                    //If we get an error in state "in_session" then we will return to control screen afterwards
                    if(states.state === "in_session" && BodySync.currentState === BodySync.DISABLE_WHEELS) {
                        previousBodyState = BodySync.MAIN
                    } else {
                        previousBodyState = BodySync.currentState
                    }

                    // Prevent things to change due to scroll wheels
                    body_conn.isChanging
                    BodySync.currentState = BodySync.MENU;
                }

                idle_detect.notifyActivity()
            }
            else
            {
                // To check if currentState is changed in the following code
                BodySync.clearIsStateSet()

                //Should only set bodysync state if this popup is handling the cleanup (or we have special case with HDMI below)
                var allowSetBodySyncState = false

                //Only do cleanup if this popup is the owner (i.e. was the first popup to show the error)
                if (GlobalStateInfo.errorPopupOwner === "main" && ErrorControl.code === Errors.ErrorNone) {
                    GlobalStateInfo.errorPopupOwner = ""
                    allowSetBodySyncState = true
                    // Can end up in a state where buttons don't work for a few seconds unless we restore focus
                    // If no valid focus is available restore to main_screen
                    if (previouslyActiveItem == null) {
                        previouslyActiveItem = main_screen
                    }

                    console.log("Resetting active item to: ", previouslyActiveItem)
                    previouslyActiveItem.forceActiveFocus()
                    previouslyActiveItem = null
                    console.log("current state is", states.state)
                    //Don't return to controlscreen if we get error in browseview
                    if (states.state !== "browse_view") {
                        activateImpl(false, true)
                    }
                } else { //We didn't have focus when popup was started.
                    //For most cases do some cleanup to prevent ending up with black screen and no key detection
                    if (states.state !== "hdmi") {
                        activateImpl(false, true)
                        allowSetBodySyncState = true
                    }
                }

                // If currentstate has not been set above, restore to previously set state
                if (allowSetBodySyncState && !BodySync.isStateSet() && !root.disabled)
                {
                    body_conn.isChanging
                    BodySync.currentState = previousBodyState;
                }

            }
        }
    }

    Connections {
        id: content_conn
        property alias theTarget: content_conn.target
        target: ContentModel
        onImageAdded: {
            console.log("TouchWindow: Image Added:")
            if(configstore.CustomOption_ShowPreview && !GlobalStateInfo.evfActive && !configstore.bracketingActive && !configstore.focusBracketingActive) {
                Camera.setLiveViewState(false)
                if((ErrorControl.code === Errors.ErrorNone))
                {
                    if ((guiconfig.isWedge && !System.isTethered) ||
                        (isInHDMI && configstore.CameraType !== Config.CameraTypeHsystem)) {
                        setState("browse_view")
                    } else {
                        setState("instant_preview")
                    }
                }
            }
            //Cannot check isInHDMI here since it is false in state "sleeping"
            if (BodySync.hdmiCableConnected && configstore.CameraType === Config.CameraTypeHsystem && !configstore.CustomOption_ShowPreview) {
                idle_detect.notifyActivity()
                setToControl()
            }
        }
        // When a card is inserted/remove light up the UI...if we are to be shown
        onCard0AvailableChanged: {
            if (root.showContent)
                idle_detect.notifyActivity()
            refreshErrorPopup()
        }
        onCard1AvailableChanged: {
            if (root.showContent)
                idle_detect.notifyActivity()
            refreshErrorPopup()
        }
    }

    function refreshErrorPopup() {
        if ((ContentModel.card0Available || ContentModel.card1Available) && ErrorControl.code === Errors.ErrorMediaMissing) {
            ErrorControl.ack()
        }
    }

    Connections {
        // This is used to detect new updates..
        id: upgrade_conn_detect
        property alias theTarget: upgrade_conn.target

        target: Upgrader
        onRecommendedUpgradesChanged: {
            console.log("Change of recommended upgrades")
            if (states.state !== "update_finished" && states.state !== "updating" &&
                    !target.inUse && (target.recommendedUpgrades.length > 0))
                setState("updates_detected")
        }
    }

    Connections {
        id: upgrade_conn
        property alias theTarget: upgrade_conn.target

        target: Upgrader
        onUpgradeProgressChanged: {
            if(Upgrader.upgradeProgress < 100 && 0 === ~~(Upgrader.UpgradeProgress % 20) && states.state === "updating") {
               fakeProgressTimer.progress = 0
               fakeProgressTimer.start()
            } else {
                // we do not expect to modify a progress that is not a modulus of 20 %, higher or equal to 100 or in the wrong state.
                fakeProgressTimer.stop()
                fakeProgressTimer.progress = 0
            }
        }
    }

    Connections {
        id: system_conn
        property alias theTarget: system_conn.target
        target: System
        onCamera_modeChanged: {
            if(!guiconfig.isWedge && root.allowCameraView)
            {
                setState("camera_view")
            }
        }
        onTethered_modeChanged: {
            setState("camera_view") // start animation here
            //If we are in video mode when starting tethered then change to camera mode
            if (System.tethered_mode !== System.Off && System.camera_mode === System.CameraModeVideo) {
                System.camera_mode = System.CameraModeImage;
            }
        }

        // Move to control screen to display ackable error message
        // On H6D always stay in update_finished as we require reboot due to viewfinder
        onSystem_stateChanged: {
            if (guiconfig.isWedge && states.state === "update_finished" && System.system_state == System.StateUp) {
                console.log("Leave update_finished to display ackable error messages")
                setToControl()
            }
        }

    }

    Connections {
        id: camera_conn
        property alias theTarget: camera_conn.target
        target: Camera
        // Sadly we can not use a when clause in the "in_session" state
        // since when that evaluates to false we will go to the default state
        // which might "hide" any new photos
        onInSessionChanged: {
            if(!Camera.inSession)
            {
                GlobalStateInfo.waitingForExpose = false
            }
            updateSessionState()
        }

        onExposingChanged: {
            if (Camera.exposing)
            {
                GlobalStateInfo.waitingForExpose = false
            }
            else if (!guiconfig.isWedge && (states.state === "in_session") && !configstore.CustomOption_ShowPreview)
            {
                setToControl()
            }
        }

        function updateSessionState() {
            if (isInHDMI) return // Maybe we should be allowed to reach in_session* reset in HDMI also

            if (Camera.inSession) {
                //if (isInHDMI) return
                if (root.photosAddedInSession !== 0) return
                if (VideoControl.videoMode !== VideoControl.Off) return
                if (VideoControl.pipelineState === VideoControl.PipelineLocal) return

                if((configstore.ExpMode === Config.ExpMode_ManualQuick) &&
                   !shouldShowSelfTimer() && !shouldShowIntervalTimer() && !shouldShowBracketing()) {
                    setState("in_session_camera_view")
                    return
                }

                // "default" catch all
                setState("in_session")
                return
            }

            if((ErrorControl.code !== Errors.ErrorNone)) return
            // Errors none were a prerequisit to enter folliwing section. Maybe it can be removed.
            if (root.photosAddedInSession !== 0) {
                //if (isInHDMI) return

                var showControlAfterEvf = evfExitTimeoutActive && wasExposingInEvf && GlobalStateInfo.evfLiveViewWasAutostarted
                if (evfExitTimeoutActive && !evfExitTimer.running) {
                    //We were exposing in B/T mode or long exposure when evfExitTimer triggered so the evfExitTimeoutActive was prolonged until session ended (i.e. until now)
                    evfExitTimeoutActive = false
                    wasExposingInEvf = false
                }

                if (GlobalStateInfo.evfActive) {
                    setState("disabled")
                    return
                }

                if (configstore.CustomOption_ShowPreview) {
                    setState("browse_view")
                    return
                }

                if (configstore.ExpMode === Config.ExpMode_ManualQuick || showControlAfterEvf ||
                    (configstore.CustomOption_LiveViewEVFOnly && System.camera_mode === System.CameraModeImage) ||
                     ((configstore.selfTimerActive || configstore.intervalActive || configstore.bracketingActive || configstore.focusBracketingActive) && GlobalStateInfo.photosAddedCount != 0)) {
                    setState("camera_view")
                    return
                }

                // "default" catch all
                setState("liveview")
                if (VideoControl.videoMode === VideoControl.Off) {
                    Camera.setLiveViewState(true);
                }
                return
            }

            if (states.state === "in_session" || states.state === "in_session_camera_view") {
                //With wedge eshutter we sometimes get Camera.inSession false before photosAddedInSession is updated, resulting in camera view being shown shortly before preview is shown
                if (!wasExposingWedge) {
                    setState("camera_view")
                }
                return
            }
        }
    }

    Connections {
        id: video_conn
        property alias theTarget: video_conn.target
        target: VideoControl
        // In case we are in a session and liveview disappears, check which state we should enter
        // when evaluation cant be used for in in_session
        onPipelineStateChanged: {
            console.log("pipeline changed to:", VideoControl.pipelineState)
            if (Camera.inSession)
                camera_conn.updateSessionState()
        }
        onVideoModeChanged: {
            console.log("video mode changed to:", VideoControl.videoMode)
            if (Camera.inSession)
                camera_conn.updateSessionState()
        }
    }

    Connections {
        id: globalStateInfo_conn
        target: GlobalStateInfo
        onSelfTimerAbortedChanged: {
            if (GlobalStateInfo.selfTimerAborted) {
                GlobalStateInfo.selfTimerAborted = false
                wasExposingWedge = false
                GlobalStateInfo.waitingForExpose = false
                fastBeepTimer.stop()
                if (configstore.CameraType === Config.CameraTypePinhole) {
                    setToControl()
                }
                if (guiconfig.isWedge && isInHDMI) {
                    setToControl()
                }
            }
        }
    }

    Connections {
        id: cambody_conn
        target: cambody
        onExposeFailed: {
            wasExposingWedge = false
        }
    }

    Connections {
        target: farm
        onReadyForExposureChanged: {
            if (configstore.readyAfterExposureSound) {
                SoundControl.play(SoundControl.SndReady)
            }
        }
    }

    Connections {
        target: ErrorControl
        onCodeChanged: {
            if (ErrorControl.code !== Errors.ErrorNone && ErrorControl.code !== Errors.ErrorUpgradeFinished) {
                GlobalStateInfo.waitingForExpose = false
                SoundControl.play(SoundControl.SndError)
            }
        }
    }

    function startEvfTimer() {
        evfExitTimeoutActive = true
        evfExitTimer.restart()
        console.log("evfExitTimer started")
    }

    Timer {
        id: evfExitTimer
        interval: 1000
        repeat: false
        onTriggered: {
            console.log("evfExitTimer stopped")
            //In case of B/T mode or long exposure then wait with resetting parameters to keep track of which state to change to after exposure
            if (!Camera.inSession) {
                evfExitTimeoutActive = false
                wasExposingInEvf = false
            }
        }
    }

    Timer {
        id: dialToCameraTimer
        property int prevDialMode: BodySync.currentDialMode
        interval: 1000
        repeat: false
        onTriggered: {
            if((BodySync.DmVideo === BodySync.currentDialMode || BodySync.DmVideo === prevDialMode)
                    && BodySync.currentDialMode !== prevDialMode
                    && root.allowCameraView)
            {
                setState("camera_view")
            }
            prevDialMode = BodySync.currentDialMode
        }
    }

    function shouldShowSelfTimer()
    {
        // selftimer / interval counting?
        if(configstore.selfTimerActive && Camera.selfTimerCountDown > 0)
            return true
        var isBOrT = cambody.isBMode || cambody.isTMode;
        // Started exposing in B or T mode?
        if(isBOrT && Camera.exposing)
            return true
        // long exposure ongoing? (wedge or tech cam)
        if((guiconfig.isWedge || (cambody.capabilities & Cambody.CapabilityGuiExposure) !== 0) && !isBOrT && Camera.exposureTimerCount > 0
            && !(configstore.intervalActive || configstore.bracketingActive || configstore.focusBracketingActive)) // don't load self timer screen during long exposures in interval mode
            return true
        // Tech cam in exposure?
        if(!guiconfig.isWedge && Camera.exposing && ((cambody.capabilities & Cambody.CapabilityGuiExposure) !== 0))
            return true
        // then, NOPE!
        return false
    }

    function shouldShowIntervalTimer()
    {
        if (configstore.intervalActive && Camera.intervalTimerCountDown > 0)
            return true
        if (configstore.intervalActive &&
           (guiconfig.isWedge || (cambody.capabilities & Cambody.CapabilityGuiExposure) !== 0) && Camera.exposureTimerCount > 0)
            return true
        return false
    }

    function shouldShowBracketing()
    {
        //if (!guiconfig.wedge)
//            return false
        if ((configstore.bracketingActive || configstore.focusBracketingActive) && Camera.inSession)
            return true;
        if ((configstore.bracketingActive || configstore.focusBracketingActive) && Camera.exposureTimerCount > 0)
            return true
        return false
    }


    // WEDGE handling of mode dial for video mode activation/inactivation.
    Connections {
        id: body_conn
        property alias theTarget: body_conn.target
        target: BodySync
        onCurrentDialModeChanged: {
            idle_detect.notifyActivity();
            if(BodySync.DmVideo === BodySync.currentDialMode || BodySync.DmVideo === dialToCameraTimer.prevDialMode)
                dialToCameraTimer.restart()
            else {
                if(!dialToCameraTimer.running)
                    dialToCameraTimer.prevDialMode = BodySync.currentDialMode
                else
                    dialToCameraTimer.restart()
            }

            // Remove text blocking screen if active
            removeTimedText()
        }
        onProximityDetectNearChanged: {
            if (guiconfig.isWedge && BodySync.proximityDetectNear && idle_detect.off) {
                idle_detect.notifyActivity()
            }
        }
        onKeepAlive: {
            if(!sleeping) idle_detect.notifyActivity()
            else console.log("not notifying: already sleeping")
        }

        // For some reason, BodySync currentState is changed AFTER it is set in errorPopupLoader, ruining the
        // purpose of setting it there. The following is a workaround until a "better" solution is found
        property bool isChanging: false
        onCurrentStateChanged: {
            if(body_conn.isChanging)
            {
                body_conn.isChanging = false

            }
            else if(errorPopupLoader.active && ((BodySync.currentState !== BodySync.MENU) && (BodySync.currentState !== BodySync.DISABLE_WHEELS)))
            {
                body_conn.isChanging = true
                errorPopupLoader.previousBodyState = BodySync.currentState
                BodySync.currentState = BodySync.MENU
            }
        }
    }

    // This Timer and Connection to Upgrader below is ONLY used to produce a faked visual experience of the upgrade ProgressBar
    // since the feeling can make the user slightly nervous if the increment goes to slow, especially in the beginning.
    // This "feature" can be removed when the upgrade process has a more fine grained increment of the progress.
    Timer {
        id: fakeProgressTimer
        property int progress: 0
        property int modifyInterval: 20
        repeat: false
        running: false
        onTriggered: {
            progress += modifyInterval / 4
            console.log("fakeincrement to", progress)
            if(progress >= modifyInterval * 0.75)
               stop() // faked part of interval done.
            else
               start()
        }

        // Note: These values are completely related to the upgrade process time, and if that changes these number must change too.
        interval: {
            var ival = 0
            switch(Upgrader.upgradeProgress) {
            case 0:
                if(0 === progress) // the very first increment we do pretty early!
                    ival = 12;
                else
                    ival = 74;
                break;
            case 20: ival = 37; break;
            case 40: ival = 12; break;

            case 60: ival = 11; break;
            case 80: ival = 19; break;
            default: ival = 1000; break;
            }
            return ival * 1000;
        }
    }

    Item {
        id: states
        objectName: "TouchWindow_states"

        property string previousState: "main"

        // vvv DO NOT REMOVE THIS!!! vvv
        // When leaving main menu we must call the closeMenu() function. It does NOT work to call the "closeMenu" function in the
        // transitions below, since then it is to late. The gui has then already crashed...
        onStateChanged: {
            // This is instead of a "Transition", since they don't work well with default states
            // This is a good thing, if this is removed and the gui starts to crash look here.
            if((previousState === "main") && main_screen.item)
            {
                main_screen.item.closeMenu()
            }

            previousState = state
            if (state !== "liveview" && state !== "in_session") {
                wasExposingWedge = false
            }
        }

        // In the case we are updating, no flickering, just go to updating...
        state: Upgrader.isProcessing ? "updating" : System.system_state === System.StateUpgrade ? "update_finished" : Upgrader.recommendedUpgrades.length > 0 ? "updates_detected" : "disabled"
        states: [
            State {
                // A state only for inheritence, for all states that are not showing the camera view
                name: "none_camera_view"
                PropertyChanges { target: camera_view_loader; y: main_screen.y - camera_view_loader.height; restoreEntryValues: false }

                StateChangeScript {
                    script: {
                        if (camera_view_loader.item)
                        {
                            camera_view_loader.item.closePopup()
                            camera_view_loader.item.stopWheelTimeout()
                            camera_view_loader.item.allowHighlightBracket = false
                        }
                    }
                }
            },

            State {
                // A state only for inheritence, for all states that are not showing the camera view
                // and requires the menumode of bodysync
                name: "none_camera_view_menu"
                extend: "none_camera_view"
                StateChangeScript {
                    script: {
                        if(guiconfig.isWedge && (BodySync.focusSurface === root.title))
                        {
                            BodySync.currentState = BodySync.MENU
                        }
                    }
                }

            },
            // About the name "":
            // The following state has the name "" meaning it is a default state
            // When "when" properties are evaluated, and there is no fitting "where" clause,
            // the default state is set.
            // The problem with that is that we cannot have a "transition" with "to" or "from" using
            // that name, it will not work as expected.
            State {
                name: ""
            },
            State {
                name: "main"
                extend: "none_camera_view_menu"

                // Do not set state to "", it will lead to that liveview will be erroneously exited if a swipe is made but regretted
                // Hopefully all other functionality will remain intact...
                // Let the following commented row be here for a while, until sure all ok
                PropertyChanges { target: main_screen; focus: true; restoreEntryValues: false }
                PropertyChanges { target: main_screen; show: true }
                PropertyChanges { target: idle_detect; config: ContentModel.isFormatting ? IdleDetect.FilterAll : (System.camera_mode === System.CameraModeVideo ? 0 : IdleDetect.FilterGripHalfPress) | IdleDetect.FilterIdleDetect }
                StateChangeScript {
                    script: {
                        if((configstore.CameraType === Config.CameraTypeHsystem) && !isInHDMI)
                        {
                            BodySync.currentState = BodySync.MAIN
                        }
                    }
                }
            },
            State {
                name: "disabled"
                extend: "none_camera_view"
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: content_conn; theTarget: null }
                PropertyChanges { target: upgrade_conn; theTarget: null }
                PropertyChanges { target: upgrade_conn_detect; theTarget: null }
                PropertyChanges { target: system_conn; theTarget: null }
                PropertyChanges { target: body_conn; theTarget: null }
                PropertyChanges { target: camera_conn; theTarget: null }
                PropertyChanges { target: video_conn; theTarget: null }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterNone }
                PropertyChanges { target: idle_detect; prevMenuMode: -1; restoreEntryValues: false }
                //Failsafe to always be able to receive keypresses after leaving EVF. In most cases some other component will request focus.
                PropertyChanges { target: viewArea; focus: true; restoreEntryValues: false }
            },
            State {
                name: "batteryexhausted"
                extend: "none_camera_view_menu"
                // Battery is exhausted. Special treatment
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: popover_loader; active: true; source: "qrc:///components/popups/BatteryExhausted.qml"  }
                PropertyChanges { target: popover_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterNone }
                StateChangeScript {
                    script: {
                        idle_detect.notifyActivity()
                    }
                }
            },
            State {
                name: "error"
                extend: "none_camera_view_menu"
                // An error which is not ackable -> serious...
                PropertyChanges { target: main_screen; show: false }
                StateChangeScript {
                    script: {
                        popover_loader.setSource("qrc:///components/popups/PopoverError.qml",
                                                 {
                                                     "errcodeText" : ErrorControl.code,
                                                     "subText" : ErrorControl.message,
                                                     //"bottomText":,
                                                     "icon": "qrc:///icons/exclamationMark.png"
                                                 });
                        idle_detect.notifyActivity()
                    }
                }
                PropertyChanges { target: popover_loader; active: true }
                PropertyChanges { target: popover_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterNone }
            },
            State {
                name: "updating"
                extend: "none_camera_view_menu"
                PropertyChanges { target: main_screen; show: false }
                // When updating, disable detection of new updates...
                PropertyChanges { target: upgrade_conn_detect; theTarget: null }
                StateChangeScript {
                    script: {
                        console.log("type is:", Upgrader.upgradeType, "Type camera=", Upgrader.TypeCameraFirmware)
                        fakeProgressTimer = 0
                        if(Upgrader.upgradeType === Upgrader.TypeCameraFirmware)
                            fakeProgressTimer.start()
                        var headingText = "<font color=\"" + constants.menuHighlightColor + "\">" + qsTr("GENERAL SETTINGS") + ":</font> " + qsTr("FIRMWARE UPDATE")
                        popover_loader.setSource("qrc:///components/popups/PopoverBusy.qml",
                                                 {
                                                     "heading": headingText,
                                                     "centerText": qsTr("Update in progress"), "bottomText": qsTr("Do not turn off!"),
                                                     "icon": "qrc:///icons/exclamationMark.png",
                                                     "showPercentage": Upgrader.upgradeType === Upgrader.TypeCameraFirmware,
                                                     "animDelay": 10,
                                                     "percentage": Qt.binding(function() { return Upgrader.upgradeProgress + fakeProgressTimer.progress })
                                                     // , "statusText": Qt.binding(function() { return Upgrader.upgradeStatusText })
                                                 });
                        idle_detect.notifyActivity()
                    }
                }
                PropertyChanges { target: popover_loader; active: true }
                PropertyChanges { target: popover_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: root; color: "black" }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterAll }
            },
            State {
                name: "update_finished"
                extend: "none_camera_view_menu"
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: upgrade_conn_detect; theTarget: null }
                StateChangeScript {
                    script: {
                        var headingText = "<font color=\"" + constants.menuHighlightColor + "\">" + qsTr("GENERAL SETTINGS") + ":</font> " + qsTr("FIRMWARE UPDATE") + guiconfig.emptyString
                        popover_loader.setSource("qrc:///components/popups/PopoverError.qml",
                                                 {
                                                     "showEmergencyButtons": false,
                                                     "heading": headingText,
                                                     "subText": qsTr("Update finished"),
                                                     "bottomText": qsTr("Please remove and reinsert battery!"),
                                                     "showIcon": false
                                                 });
                        idle_detect.notifyActivity()
                        //Temporary sound until the correct one is available
                        SoundControl.play(SoundControl.SndTetheredConnect)
                    }
                }
                PropertyChanges { target: popover_loader; active: true }
                PropertyChanges { target: popover_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: root; color: "black" }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterAll}
            },
            State {
                name: "shutdown"
                extend: "none_camera_view_menu"
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterAll }
                PropertyChanges { target: popover_loader; active: true }
                PropertyChanges { target: popover_loader; focus: true; restoreEntryValues: false }
                StateChangeScript {
                    script: {
                        popover_loader.setSource("qrc:///components/ShutdownScreen.qml");
                    }
                }
            },
            State {
                name: "updates_detected"
                extend: "none_camera_view_menu"
                StateChangeScript {
                    script: {
                        popover_loader.setSource("qrc:///components/popups/UpgradeCheck.qml", { "initialState": "ask", "model" : Upgrader.recommendedUpgrades });
                    }
                }
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: popover_loader; active: true }
                PropertyChanges { target: popover_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: root; color: "black" }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterGripHalfPress | IdleDetect.FilterIdleDetect }
            },
            State {
                name: "camera_view"
                PropertyChanges { target: swipe_area; anchors.bottomMargin: 0; restoreEntryValues: false }
                PropertyChanges { target: camera_view_loader; y: main_screen.y; restoreEntryValues: false }
                PropertyChanges { target: camera_view_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: swipe_area; changeThreshold: (main_screen.y - main_screen.height / constants.swipeLengthDividor) }
                PropertyChanges { target: main_screen; show: true }
                PropertyChanges { target: idle_detect; config: (System.camera_mode === System.CameraModeVideo ? 0 : IdleDetect.FilterGripHalfPress) | IdleDetect.FilterIdleDetect }
                StateChangeScript {
                    script: {
                        if(camera_view_loader.item !== null)
                            camera_view_loader.item.forceActiveFocus()

                        // BodySync.currentState could not be set correctly as PropertyChanges, was erroneous
                        // when in Browse view and then pressing ISO/WB button (wedge)
                        if((configstore.CameraType === Config.CameraTypeHsystem) ||
                           (guiconfig.isWedge && BodySync.focusSurface === root.title) ||
                           BodySync.currentState === BodySync.PLAY)
                        {
                            BodySync.currentState = BodySync.MAIN
                        }

                    }
                }
            },
            State {
                name: "in_session_camera_view"
                extend: "camera_view"
                StateChangeScript {
                    script: {
                        if(BodySync.focusSurface === root.title)
                        {
                            BodySync.currentState = BodySync.DISABLE_WHEELS
                        }
                    }
                }

            },
            State {
                name: "instant_preview"
                extend: "none_camera_view"
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterGripHalfPress | IdleDetect.FilterIdleDetect }
                PropertyChanges { target: media_browse_loader; isInstantPreview: true; active: true  }
                PropertyChanges { target: root; isInstantPreview: true }
                PropertyChanges { target: media_browse_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: main_screen; show: false }
                StateChangeScript {
                    script: {
                        if(BodySync.focusSurface === root.title)
                        {
                            BodySync.currentState = BodySync.MAIN
                        }
                    }
                }

                //                PropertyChanges { target: VideoControl; videoMode: VideoControl.Off; restoreEntryValues: false }
            },
            State {
                name: "browse_view"
                extend: "none_camera_view"
                PropertyChanges { target: idle_detect; config: (System.camera_mode === System.CameraModeVideo ? 0 : IdleDetect.FilterGripHalfPress) | IdleDetect.FilterIdleDetect }
                PropertyChanges { target: media_browse_loader; active: !GlobalStateInfo.evfActive }
                PropertyChanges { target: media_browse_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: root; isBrowsing: true }
                StateChangeScript {
                    script: {
                        if(!GlobalStateInfo.evfActive)
                        {
                            BodySync.currentState = BodySync.PLAY
                        }
                    }
                }
            },
            State {
                name: "in_session"
                extend: "none_camera_view"
                // We are in an exposing session, but not with liveview...and no exposures so far
                PropertyChanges { target: selfTimerScreen; active: shouldShowSelfTimer() }
                PropertyChanges { target: intervalTimerScreen; active: shouldShowIntervalTimer()}
                PropertyChanges { target: bracketingScreen; active: shouldShowBracketing()}
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterGripHalfPress | IdleDetect.FilterIdleDetect }
                PropertyChanges { target: root; allowCameraView: false }
                StateChangeScript {
                    script: {
                        if(guiconfig.isWedge && (BodySync.focusSurface === root.title))
                        {
                            BodySync.currentState = BodySync.DISABLE_WHEELS
                        }
//                        console.log("configstore.selfTimerActive", configstore.selfTimerActive)
//                        console.log("cambody.isBMode", cambody.isBMode)
//                        console.log("cambody.isTMode", cambody.isTMode)
//                        console.log("Camera.exposing", Camera.exposing)
//                        console.log("Camera.exposureTimerCount", Camera.exposureTimerCount)
//                        console.log("Camera.selfTimerCountDown", Camera.selfTimerCountDown)
                    }
                }
            },
            State {
                name: "liveview"
                extend: "none_camera_view"
                // Liveview state when this window is active and there is a liveview stream active

                PropertyChanges { target: live_view_loader; active: true }
                PropertyChanges { target: live_view_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterNone }
                StateChangeScript {
                    script: {
                        // It worked very bad to set BodySync.currentState in PropertyChanges, so we set it in this script instead
                        if (guiconfig.isWedge)
                        {
                            BodySync.currentState = GlobalStateInfo.afSelectionActive ? BodySync.MENU : BodySync.MAIN
                        }
                        else if (configstore.CameraType === Config.CameraTypeHsystem)
                        {
                            BodySync.currentState = BodySync.MAIN
                        }
                    }
                }
            },
            State {
                name: "hdmi"
                extend: "none_camera_view"
                // HDMI when hdmi cable attached and live view showing
                PropertyChanges { target: hdmi_loader; active: true }
                PropertyChanges { target: hdmi_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterNone }
                StateChangeScript {
                    script: {
                        if (BodySync.currentState === BodySync.PLAY) {
                            BodySync.currentState = BodySync.MAIN
                        }
                    }
                }
            },
            State {
                name: "spirit_level"
                extend: "none_camera_view"
                PropertyChanges { target: spiritLevelView; active: true }
                PropertyChanges { target: spiritLevelView; focus: true; restoreEntryValues: false }
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: idle_detect; config: (System.camera_mode === System.CameraModeVideo ? 0 : IdleDetect.FilterGripHalfPress) | IdleDetect.FilterIdleDetect }
            },
            State {
                name: "grey_balance_tool"
                extend: "none_camera_view"
                PropertyChanges { target: greyBalanceToolView; active: true }
                PropertyChanges { target: greyBalanceToolView; focus: true; restoreEntryValues: false }
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: idle_detect; config: (System.camera_mode === System.CameraModeVideo ? 0 : IdleDetect.FilterGripHalfPress) | IdleDetect.FilterIdleDetect }
                StateChangeScript {
                    script: {
                        BodySync.currentState = BodySync.MENU
                    }
                }
            }

        ]

        transitions: [
            Transition {
                from: "main"
                // This applies a default NumberAnimation to any changes a state change makes to x or y properties
                NumberAnimation { properties: "x,y"; easing.type: Easing.InOutQuad; duration: 100 }
                ScriptAction{
                    script: {
                        if (main_screen.item) {
                            main_screen.item.stopMainWheelTimeout()
                            main_screen.item.closeMenu()
                        }
                    }
                }
            },
            // Do nothing when disabled or to liveview/session from liveview/session
            Transition {
                from: "liveview,in_session"
                to: "disabled,liveview,in_session"
            },
            Transition {
                from: "liveview,in_session"
                // To all but disable, which is catched above
                ScriptAction {
                    script: {
                        // Check if we are in charge...
                        if (!BodySync.hdmiCableConnected && !GlobalStateInfo.evfActive &&
                                (!guiconfig.isWedge || //No extra restrictions for H6D
                                 (wasExposingInEvf && configstore.CustomOption_ShowPreview) || //x1d: we have exited evf shortly after exposure
                                 (!evfExitTimeoutActive && !(wasExposingWedge && !configstore.CustomOption_ShowPreview)))) { //normal case x1d: (have not exited evf recently)
                            Camera.setLiveViewState(false)
                            VideoControl.setVideoRecordState(false)
                        }
                    }
                }
            },
            Transition {
                from: "browse_view"
                // This applies a default NumberAnimation to any changes a state change makes to x or y properties
                NumberAnimation { properties: "x,y"; easing.type: Easing.InOutQuad; duration: 100 }
                ScriptAction {
                    script: {
                        if (idlePreventTimer.running) {
                            idlePreventTimer.stop()
                        }
                    }
                }
                // TODO: Check if this is necessary or not
                //ScriptAction {
                //    script: {
                //        if(!guiconfig.isWedge)
                //            BodySync.currentState = BodySync.MAIN
                //    }
                //}
            },
            Transition {
                from: "camera_view"
                to: "liveview,in_session"
                ScriptAction {
                    script: {
                        // Workaround! We noticed that swipe_area.anchors.bottomMargin was not always reset to its previous binding
                        // in the "PropertyChanges" in the "camera_view" state above (when estoreEntryValues was set to true)
                        // so we reset the binding explicitly here instead
                        swipe_area.anchors.bottomMargin = Qt.binding(function() { return main_screen.height - controlScreenSwipeAreaHeight })
                    }
                }
            },
            Transition {
                from: "camera_view,in_session_camera_view"
                // This applies a default NumberAnimation to any changes a state change makes to x or y properties
                NumberAnimation { properties: "x,y"; easing.type: Easing.InOutQuad; duration: 100 }
                ScriptAction {
                    script: {
                        // Workaround! We noticed that swipe_area.anchors.bottomMargin was not always reset to its previous binding
                        // in the "PropertyChanges" in the "camera_view" state above (when estoreEntryValues was set to true)
                        // so we reset the binding explicitly here instead
                        swipe_area.anchors.bottomMargin = Qt.binding(function() { return main_screen.height - controlScreenSwipeAreaHeight })
                    }
                }
            },
            // This adds a transition that defaults to applying to all state changes
            Transition {
                // This applies a default NumberAnimation to any changes a state change makes to x or y properties
                NumberAnimation { properties: "x,y"; easing.type: Easing.InOutQuad; duration: 100 }
            }
        ]
    }

    Loader {
        objectName: "popover_loader"
        id: popover_loader
        active: false
        width: 640
        height: 480
        anchors.centerIn: parent
        Connections {
            target: popover_loader.item
            onVisibleChanged: {
                if (!target.visible) {
                    console.log("Changing state back")
                    // To avoid glitches if active is set to true shortly
                    popover_loader.source = ""
                    setState("main")
                }
            }
        }
    }

    Loader {
        objectName: "dial_Loader"
        id: dial_loader
        source: "qrc:///components/DialModeOverlay.qml"
        asynchronous: true
        active: false
        anchors.fill: parent
        onLoaded: console.log("Dial is loaded")
        Binding {
            target: dial_loader.item
            property: "allowVisible"
            value: !root.disabled
                   && System.system_state !== System.StateUpgrade
                   && ErrorControl.code === Errors.ErrorNone
                   && !ContentModel.isFormatting
        }
    }

    function notifyCurrentImageLoaded() {
        if (configstore.CustomOption_ShowPreview && !root.disabled) {
            console.log("Notify image loaded...")

            idle_detect.notifyActivity()
        }
    }
    function idleWakeupOrForceOff(doWake) {
        if(doWake)
            idle_detect.notifyActivity()
        else
        {
            // If live view is running, make sure to close ISO/WB first to not confuse Bodysync.currentState
            if(live_view_loader.active)
            {
                live_view_loader.item.closeIsoWb()
            }
            if (VideoControl.videoMode === VideoControl.Zoom) {
                BodySync.currentState = BodySync.MAIN
            }
            Camera.setLiveViewState(false)
            console.log("Forcing idle off")
            idle_detect.setForcedOff()
        }
    }
    function preventIdle(prevent)
    {
        console.info("preventIdle", prevent)
        idlePreventTimer.running = prevent
    }

    Connections {
        target: media_browse_loader.item
        onPreventIdleTimeout: idlePreventTimer.running = prevent
        onCurrentItemLoaded: root.notifyCurrentImageLoaded()
    }

    Timer {
        id: fastBeepTimer
        interval: 150
        repeat: true
        onTriggered: {
            SoundControl.play(SoundControl.SndSelfTimerCount)
        }
    }

    Connections {
        target: Camera
        onSelfTimerCountDownChanged: {
            preventIdle(Camera.selfTimerCountDown > 0)
            if (Camera.selfTimerCountDown > 0) {
                if (Camera.selfTimerCountDown > 2) {
                    SoundControl.play(SoundControl.SndSelfTimerCount)
                }
                if (Camera.selfTimerCountDown === 2) {
                    fastBeepTimer.start()
                }
            } else {
                fastBeepTimer.stop()
            }

        }
        onIntervalTimerCountDownChanged: {
            preventIdle((Camera.intervalTimerCountDown > 0) || configstore.bracketingActive || configstore.focusBracketingActive)
        }
        onInSessionChanged: {
            if((Camera.selfTimerCountDown > 0) || (Camera.intervalTimerCountDown > 0) || configstore.bracketingActive || configstore.focusBracketingActive)
            {
                preventIdle(Camera.inSession)
            }
        }
        onExposingChanged: {
            if(Camera.exposing)
            {
                // Make sure format dialog is closed
                format_card_loader.active = false

                //Avoid short flick between in_session->hdmi state
                if (guiconfig.isWedge && isInHDMI && states.state === "in_session" && !configstore.CustomOption_ShowPreview && BodySync.currentDialMode !== BodySync.DmManualQuick) {
                    GlobalStateInfo.waitingForLiveView = true
                }
            }
        }
        onExposureTimerCountChanged: {
            if (states.state === "in_session_camera_view" && shouldShowSelfTimer()) {
                setState("in_session")
            }
        }

        //onExposureTimerCountChanged: preventIdle(Camera.exposureTimerCount > 0 && Camera.exposureTimerCount <= 10)
    }

    Connections {
        target: GlobalStateInfo
        onAfSelectionActiveChanged: {
            BodySync.currentState = GlobalStateInfo.afSelectionActive ? BodySync.MENU : BodySync.MAIN
            VideoControl.prohibitZoom = GlobalStateInfo.afSelectionActive
        }
        onEvfActiveChanged: {
            if (!GlobalStateInfo.evfActive && states.state === "browse_view") {
                BodySync.currentState = BodySync.PLAY
            }
        }
    }

    Connections {
        property int oldState: System.StateBoot
        target: System
        onIsTetheredChanged: {
            if (System.isTethered && configstore.aspectRatio !== Config.RatioNoCrop) {
                configstore.aspectRatio = Config.RatioNoCrop
            }
        }
        onSystem_stateChanged: {
            if (oldState === System.StateBoot && System.system_state === System.StateUp) {
                SoundControl.play(SoundControl.SndOn)
            } else if (System.system_state === System.StatePrepareShutdown) {
                SoundControl.play(SoundControl.SndOff)
            }
            oldState =  System.system_state
        }
        onBatteryStatusChanged: {
            if (System.batteryStatus === System.BatteryExhausted && System.camera_mode !== System.CameraModeVideo) {
                SoundControl.play(SoundControl.SndBatteryLow)
            }
        }
    }

    Connections {
        property int  lastTetheredMode: System.TetheredModeOff
        target: System
        onTethered_modeChanged: {
            if (System.tethered_mode === System.TetheredModeOff) {
                SoundControl.play(SoundControl.SndTetheredDisconnect)
            } else if (lastTetheredMode === System.TetheredModeOff) {
                SoundControl.play(SoundControl.SndTetheredConnect)
            }
            lastTetheredMode = System.tethered_mode
        }
    }

    Connections {
        target: ContentModel
        onLastExposureStatus: {
            if (wasExposing || Camera.exposing) {

                if (configstore.exposureWarningSound) {
                    if (status === ContentModel.EXPOSURE_OVER) {
                        SoundControl.play(SoundControl.SndOverExp)
                    } else if (status === ContentModel.EXPOSURE_UNDER) {
                        SoundControl.play(SoundControl.SndUnderExp)
                    }
                }
                if (System.tethered_mode === System.TetheredModeOff) {
                    if (ContentModel.exposuresLeft === 0) {
                        SoundControl.play(SoundControl.SndMediaFull)
                    } else if (ContentModel.exposuresLeft === 1) {
                        SoundControl.play(SoundControl.Snd1Left)
                    } else if (ContentModel.exposuresLeft <= 5) {
                        SoundControl.play(SoundControl.Snd5Left)
                    }
                }
            }
        }
    }

    Connections {
        target: Camera
        onWbModeChanged: {
            if (Camera.WBMode !== 6) { //WB manual
                //Restore to even step size if changed by white balance tool
                var diff = configstore.WBManualTemp % 100
                if (diff !== 0) {
                    configstore.WBManualTemp = configstore.WBManualTemp + ((diff < 50) ? -diff : 100-diff)
                    configstore.WBManualTint = 0
                }
            }
        }
        onExposingChanged: {
            if (!Camera.exposing) { //Leaving state "exposing"
                wasExposing = true
                wasExposingTimer.restart()
            }
        }
    }

    Timer {
        id: wasExposingTimer
        interval: 1000
        onTriggered: {
            wasExposing = false
        }
    }

    Timer {
        id: idlePreventTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: { idleWakeupOrForceOff(true); console.log("prevented idle"); }
    }

    IdleDetect {
        id: idle_detect
        idleTimeout: configstore.BACKLIGHT_idle_timeout
        offTimeout: configstore.GUI_idle_timeout
        property int prevMenuMode: -1
        notifyOnEvent: VideoControl.videoMode === VideoControl.View
        onEvent: VideoControl.restartLiveViewImageTimeout()

        onOffChanged: {
            if (off) {
                if (VideoControl.videoMode === VideoControl.Playback)
                    VideoControl.videoMode = VideoControl.Off
            }
        }
        onActivityDetected: {
            // Notify activity if we dont use the standby timer
            if (configstore.GUI_idle_timeout <= 0)
                PowerClient.notifyActivity()
        }
        onKeyClick: {
            if (VideoControl.videoMode !== VideoControl.Record) {
                SoundControl.play(SoundControl.SndKey)
            }
        }
    }

    BacklightControl {
        id: backlight
        power: root.showContent && !idle_detect.off // && !root.disabled seems to never change
        buttonBacklight: power
        brightness: black_rect.visible ? 0 :
                      idle_detect.idle ? configstore.BACKLIGHT_idle_brightness :
                                         configstore.BACKLIGHT_brightness
        onPowerChanged: {
            console.log("Power changed to: ", power)
            console.log("root.showContent: ", root.showContent)
            console.log("root.disabled: ", root.disabled)
            console.log("idle_detect.off: ", idle_detect.off)
            if (!power) {
                delay_black_rect.running = false
                black_rect.visible = true
            } else {
                delay_black_rect.start()
            }
        }
        onBrightnessChanged: {
            console.log("Brightness changed to: ", brightness)

        }
    }

    // Backlight power-off faking when running in simulation on desktop.
    // but it also used on the device to trigger a redraw, of some reason
    // something in the display pipeline needs a redraw after the display is
    // turned on
    Rectangle {
        objectName: "black_rect"
        id: black_rect
        visible: false
        onVisibleChanged: console.log("Black rect visible", visible)
        focus: false
        anchors.fill: parent
        color: "black"
        opacity: 0.94
        z: 400
        Timer {
            id: delay_black_rect
            interval: 10
            running: false
            onTriggered: black_rect.visible = false
        }

    }

    function setTextTimer(t) {
        timed_text_loader.active = true
        timed_text_loader.text = t
        delay_timed_text.restart()
    }

    function removeTimedText() {
        timed_text_loader.active = false
        if(previouslyActiveItem !== null)
        {
            previouslyActiveItem.forceActiveFocus()
        }
    }

    Loader {
        source: "qrc:///components/blackScreenText.qml"
        id: timed_text_loader
        objectName: "timed_text_loader"
        asynchronous: true
        anchors.fill: parent
        active: false
        property string text: ""

        onLoaded: {
            item.text = text
            item.visible = true
            setPreviouslyActiveItem()
            item.forceActiveFocus()
        }

        Connections {
            target: timed_text_loader.item
            onVisibleChanged: {
                if (!timed_text_loader.item.visible)
                    removeTimedText()
            }
        }
    }

    Timer {
        id: delay_timed_text
        interval: 3000
        running: false
        onTriggered: { removeTimedText() }
    }

    Timer {
        id: shutdownLongPressTimer
        running: false
        interval: 1000
        repeat: false
        onTriggered: {
            System.onOffPressed(true)
        }
    }

    Component.onCompleted: {
        console.log("TouchWindow completed")
        camera_view_loader.active = true
    }

    onClosing:Qt.quit()
}
