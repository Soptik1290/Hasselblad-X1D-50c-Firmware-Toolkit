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
    property alias idleDetect: idle_detect
    property bool disabled: false
    onDisabledChanged: console.log("Touch disabled:", disabled)
    property bool showContent: false
    onShowContentChanged: console.log("Touch showContent:", showContent)
    property bool isReady: camera_view_loader.status === Loader.Ready
    property bool allowCameraView: !ContentModel.isFormatting && ErrorControl.code === Errors.ErrorNone && System.system_state !== System.StateUpgrade
    property bool isInstantPreview: false
    property bool isBrowsing: false
    property bool isInHDMI: false
    property bool prohibitStateChange: false
    property bool wasExposingWedge: false
    property bool wasExposing: false
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
            if (!guiconfig.isWedge || !configstore.intervalActive ||
                states.state != "browse_view" && states.state != "camera_view")
                next = "in_session"
        } else if (!root.disabled && !BodySync.hdmiCableConnected &&
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
            next = "camera_view"
        } else if (states.state === "liveview" && Camera.pendingLiveView !== Camera.PendOn && VideoControl.pipelineState !== VideoControl.PipelineLocal && VideoControl.videoMode === VideoControl.Off) {
            next = "camera_view"
        } else if (BodySync.currentDialMode === BodySync.DmManualQuick && states.state === "liveview") {
            next = "camera_view"
        } else if (BodySync.currentDialMode === BodySync.DmManualQuick && states.state === "in_session" &&
                   !GlobalStateInfo.waitingForExpose && !Camera.exposing && !Camera.inSession) {
            next = "camera_view"
        } else {
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
            var itemStr = activeFocusItem.toString()
            if (itemStr.search(/QQuickRootItem/) === 0) {
                focusRestoreTimer.restart()
            }
        }
    }
    Timer {
        id: focusRestoreTimer
        interval: 500
        onTriggered: {
            var itemStr = activeFocusItem.toString()
            if (itemStr.search(/QQuickRootItem/) >= 0) {
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
        camera_view_loader.y = 0
        activate(false, states.state === "disabled" || states.state === "main")
    }
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
        source: "qrc:///CameraMockupWedge.qml"
        active: root.simulation
        width: 800
        height: 800
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
                } else {
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
                if(!(states.state === "liveview" && VideoControl.videoMode === VideoControl.Record) && !System.isTethered) {
                    if(VideoControl.videoMode === VideoControl.Playback)
                    {
                        previouslyActiveItem = root.activeFocusItem
                        VideoControl.setVideoPlaybackState(false, "", 0)
                    }
                    else if(VideoControl.videoMode !== VideoControl.Off)
                    {
                        setState("camera_view")
                        camera_view_loader.item.forceActiveFocus()
                        previouslyActiveItem = camera_view_loader.item
                        if (VideoControl.videoMode === VideoControl.Zoom) {
                            BodySync.currentState = BodySync.MAIN
                        }
                        Camera.setLiveViewState(false);
                    }
                    else
                    {
                        previouslyActiveItem = root.activeFocusItem
                    }
                    console.log("Showing Format Dialog")
                    format_card_loader.active = true
                    format_card_loader.focus = true
                }
            }
            else if (guiconfig.isWedge && MKeys.pressedFnAcc("ISO_WB", event))
            {
                if(states.state !== "liveview") {
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
                    setState("camera_view")
                    camera_view_loader.item.isoHandler()
                }
            }
            else if (MKeys.pressedFnAcc("WB", event))
            {
                if(states.state !== "liveview") {
                    setState("camera_view")
                    camera_view_loader.item.wbHandler()
                }
            }
            else
            {
                console.log("TouchWindow: key event accepted, ended up in else clause")
                if((configstore.ExpMode !== Config.ExpMode_FullAuto) && MKeys.pressedFn("AF_MF", event.key))
                {
                    if(states.state !== "liveview")
                    {
                        setState("camera_view")
                    }
                    event.accepted = false
                }
                if(commonKeyHandle(event))
                {
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
                    if (states.state !== "browse_view") {
                        if (camera_view_loader.enabled) {
                            if (!configstore.CustomOption_ShowPreview || guiconfig.isWedge) {
                                camera_view_loader.forceActiveFocus()
                            }
                        } else {
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
                    if (states.state !== "browse_view") {
                        if (camera_view_loader.enabled) {
                            if (!configstore.CustomOption_ShowPreview || guiconfig.isWedge) {
                                camera_view_loader.forceActiveFocus()
                            }
                        } else {
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
                    if (states.state !== "browse_view") {
                        if (camera_view_loader.enabled) {
                            if (!configstore.CustomOption_ShowPreview || guiconfig.isWedge) {
                                camera_view_loader.forceActiveFocus()
                            }
                        } else {
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
                    if (drag.target.y > changeThreshold)
                    {
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
                            drag.target.y = -drag.target.height
                        }
                    }
                } else {
                    if (states.state == "camera_view") {
                        if(System.isTethered)
                            setState("instant_preview")
                    }
                }
            }
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
                    !haveHalfPress && !Camera.inSession &&
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
                    camera_view_loader.item.forceActiveFocus()
                }
            }
        }
    }
    Loader {
        objectName: "errorAckPopupLoader"
        id: errorPopupLoader
        anchors.fill: parent
        active: (ErrorControl.code !== Errors.ErrorNone) && ErrorControl.isAckable && !root.disabled
        source: "qrc:///components/popups/ErrorPopup.qml"
        focus: active
        property int previousBodyState: BodySync.MAIN
        onActiveFocusChanged: {
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
                    if(states.state === "in_session" && BodySync.currentState === BodySync.DISABLE_WHEELS) {
                        previousBodyState = BodySync.MAIN
                    } else {
                        previousBodyState = BodySync.currentState
                    }
                    body_conn.isChanging
                    BodySync.currentState = BodySync.MENU;
                }
                idle_detect.notifyActivity()
            }
            else
            {
                BodySync.clearIsStateSet()
                var allowSetBodySyncState = false
                if (GlobalStateInfo.errorPopupOwner === "main" && ErrorControl.code === Errors.ErrorNone) {
                    GlobalStateInfo.errorPopupOwner = ""
                    allowSetBodySyncState = true
                    if (previouslyActiveItem == null) {
                        previouslyActiveItem = main_screen
                    }
                    console.log("Resetting active item to: ", previouslyActiveItem)
                    previouslyActiveItem.forceActiveFocus()
                    previouslyActiveItem = null
                    console.log("current state is", states.state)
                    if (states.state !== "browse_view") {
                        activateImpl(false, true)
                    }
                } else {
                    if (states.state !== "hdmi") {
                        activateImpl(false, true)
                        allowSetBodySyncState = true
                    }
                }
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
            if (BodySync.hdmiCableConnected && configstore.CameraType === Config.CameraTypeHsystem && !configstore.CustomOption_ShowPreview) {
                idle_detect.notifyActivity()
                setToControl()
            }
        }
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
                fakeProgressTimer.stop()
                fakeProgressTimer.progress = 0
            }
        }
    }
    Connections {
        id: system_conn
        property alias theTarget: system_conn.target
        target: System
        onTethered_modeChanged: {
            setState("camera_view")
            if (System.tethered_mode !== System.Off && System.camera_mode === System.CameraModeVideo) {
                System.camera_mode = System.CameraModeImage;
            }
        }
        onSystem_stateChanged: {
            if (states.state === "update_finished" && System.system_state == System.StateUp) {
                console.log("Leave update_finished to display ackable error messages")
                setToControl()
            }
        }
    }
    Connections {
        id: camera_conn
        property alias theTarget: camera_conn.target
        target: Camera
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
        }
        function updateSessionState() {
            if (isInHDMI) return
            if (Camera.inSession) {
                if (root.photosAddedInSession !== 0) return
                if (VideoControl.videoMode !== VideoControl.Off) return
                if (VideoControl.pipelineState === VideoControl.PipelineLocal) return
                if((configstore.ExpMode === Config.ExpMode_ManualQuick) &&
                   !shouldShowSelfTimer() && !shouldShowIntervalTimer() && !shouldShowBracketing()) {
                    setState("in_session_camera_view")
                    return
                }
                setState("in_session")
                return
            }
            if((ErrorControl.code !== Errors.ErrorNone)) return
            if (root.photosAddedInSession !== 0) {
                var showControlAfterEvf = evfExitTimeoutActive && wasExposingInEvf && GlobalStateInfo.evfLiveViewWasAutostarted
                if (evfExitTimeoutActive && !evfExitTimer.running) {
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
                setState("liveview")
                if (VideoControl.videoMode === VideoControl.Off) {
                    Camera.setLiveViewState(true);
                }
                return
            }
            if (states.state === "in_session" || states.state === "in_session_camera_view") {
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
        if(configstore.selfTimerActive && Camera.selfTimerCountDown > 0)
            return true
        var isBOrT = cambody.isBMode || cambody.isTMode;
        if(isBOrT && Camera.exposing)
            return true
        if(!isBOrT && Camera.exposureTimerCount > 0
            && !(configstore.intervalActive || configstore.bracketingActive || configstore.focusBracketingActive))
            return true
        return false
    }
    function shouldShowIntervalTimer()
    {
        if (configstore.intervalActive && Camera.intervalTimerCountDown > 0)
            return true
        if (configstore.intervalActive && Camera.exposureTimerCount > 0)
            return true
        return false
    }
    function shouldShowBracketing()
    {
        if ((configstore.bracketingActive || configstore.focusBracketingActive) && Camera.inSession)
            return true;
        if ((configstore.bracketingActive || configstore.focusBracketingActive) && Camera.exposureTimerCount > 0)
            return true
        return false
    }
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
               stop()
            else
               start()
        }
        interval: {
            var ival = 0
            switch(Upgrader.upgradeProgress) {
            case 0:
                if(0 === progress)
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
        onStateChanged: {
            if((previousState === "main") && main_screen.item)
            {
                main_screen.item.closeMenu()
            }
            previousState = state
            if (state !== "liveview" && state !== "in_session") {
                wasExposingWedge = false
            }
        }
        state: Upgrader.isProcessing ? "updating" : System.system_state === System.StateUpgrade ? "update_finished" : Upgrader.recommendedUpgrades.length > 0 ? "updates_detected" : "disabled"
        states: [
            State {
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
            State {
                name: ""
            },
            State {
                name: "main"
                extend: "none_camera_view_menu"
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
                PropertyChanges { target: viewArea; focus: true; restoreEntryValues: false }
            },
            State {
                name: "batteryexhausted"
                extend: "none_camera_view_menu"
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
                PropertyChanges { target: main_screen; show: false }
                StateChangeScript {
                    script: {
                        popover_loader.setSource("qrc:///components/popups/PopoverError.qml",
                                                 {
                                                     "errcodeText" : ErrorControl.code,
                                                     "subText" : ErrorControl.message,
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
                    }
                }
            },
            State {
                name: "liveview"
                extend: "none_camera_view"
                PropertyChanges { target: live_view_loader; active: true }
                PropertyChanges { target: live_view_loader; focus: true; restoreEntryValues: false }
                PropertyChanges { target: main_screen; show: false }
                PropertyChanges { target: idle_detect; config: IdleDetect.FilterNone }
                StateChangeScript {
                    script: {
                        BodySync.currentState = GlobalStateInfo.afSelectionActive ? BodySync.MENU : BodySync.MAIN
                    }
                }
            },
            State {
                name: "hdmi"
                extend: "none_camera_view"
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
            Transition {
                from: "liveview,in_session"
                to: "disabled,liveview,in_session"
            },
            Transition {
                from: "liveview,in_session"
                ScriptAction {
                    script: {
                        if (!BodySync.hdmiCableConnected && !GlobalStateInfo.evfActive &&
                                (!guiconfig.isWedge ||
                                 (wasExposingInEvf && configstore.CustomOption_ShowPreview) ||
                                 (!evfExitTimeoutActive && !(wasExposingWedge && !configstore.CustomOption_ShowPreview)))) {
                            Camera.setLiveViewState(false)
                            VideoControl.setVideoRecordState(false)
                        }
                    }
                }
            },
            Transition {
                from: "browse_view"
                NumberAnimation { properties: "x,y"; easing.type: Easing.InOutQuad; duration: 100 }
                ScriptAction {
                    script: {
                        if (idlePreventTimer.running) {
                            idlePreventTimer.stop()
                        }
                    }
                }
            },
            Transition {
                from: "camera_view"
                to: "liveview,in_session"
                ScriptAction {
                    script: {
                        swipe_area.anchors.bottomMargin = Qt.binding(function() { return main_screen.height - controlScreenSwipeAreaHeight })
                    }
                }
            },
            Transition {
                from: "camera_view,in_session_camera_view"
                NumberAnimation { properties: "x,y"; easing.type: Easing.InOutQuad; duration: 100 }
                ScriptAction {
                    script: {
                        swipe_area.anchors.bottomMargin = Qt.binding(function() { return main_screen.height - controlScreenSwipeAreaHeight })
                    }
                }
            },
            Transition {
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
                format_card_loader.active = false
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
            if (Camera.WBMode !== 6) {
                var diff = configstore.WBManualTemp % 100
                if (diff !== 0) {
                    configstore.WBManualTemp = configstore.WBManualTemp + ((diff < 50) ? -diff : 100-diff)
                    configstore.WBManualTint = 0
                }
            }
        }
        onExposingChanged: {
            if (!Camera.exposing) {
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
        power: root.showContent && !idle_detect.off
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
