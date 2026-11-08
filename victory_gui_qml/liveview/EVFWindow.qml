import QtQuick 2.2
import QtQuick.Window 2.1

import com.hasselblad.camera 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.config 1.0
import com.hasselblad.storage 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.error 1.0
import com.hasselblad.globalstateinfo 1.0

import "qrc:/settings"
import "qrc:///scripts/Keys.js" as MKeys

Window {
    id: root
    objectName: "EVFWindow_root"
    title: "overlay"
    visible: showContent
    width: 1024
    height: 768
    color: "transparent"
    visibility: showContent ? Window.FullScreen : Window.Hidden
    property alias showContent: scope.visible
    onShowContentChanged: console.log("EVF: showContent:", showContent)
    property bool isInPreview: scope.state === "PreView"
    property bool showPreview: false
    property real sizeFactor: Math.min(width / 1024.0, height / 728.0)
    property bool isInHDMI: false
    property Item previouslyActiveItem: null
    property alias subloader_lv_active: wedgeliveview.active
    property alias subloader_video_active: wedgeLiveViewVideo.active

    signal setToBrowse()
    signal setToMain()
    signal setToControl()

    onShowPreviewChanged: {
        GlobalStateInfo.evfInPreview = showPreview
    }

    function closePreView()
    {
        showPreview = false;
    }
    function openPreView(showLastItem, startTimer)
    {
        showPreview = false;
        preView.startIndex = showLastItem ? -1 : GlobalStateInfo.mediaIndex
        preView.startTimer = startTimer
        showPreview = true;
        // QUICK HACK!!!
        // Under some circumstances this binding can be destroyed, so we correct it here
        // Should be done in a better way, but since it is just a few hours until release, this will do
        // This could be destroyed if zooming in and out in EVF, or using ISO settings (ISO/WB button) in EVF
        BodySync.currentState = Qt.binding(function() { return cambody.exposing ? BodySync.DISABLE_WHEELS : GlobalStateInfo.afSelectionActive ? BodySync.MENU : (evfWindow.item.showPreview ? BodySync.PLAY : BodySync.MAIN) })
        // END OF QUICK HACK

        if (VideoControl.videoMode !== VideoControl.Off) {
            Camera.setLiveViewState(false)
            VideoControl.setVideoRecordState(false)
        }
    }

    function focusErrorView()
    {
        fatalError.focus = true
    }

    function setPreviouslyActiveItem()
    {
        if(activeFocusItem !== null)
        {
            previouslyActiveItem = activeFocusItem
        }
        console.log("Previously active item set to: ", previouslyActiveItem)
    }

    onActiveFocusItemChanged: {
        if(null != activeFocusItem) {
            console.log("ActiveFocusItem changed:", activeFocusItem, guiconfig.itemProperties(activeFocusItem, false, true, 0))
            // DEBUG: Enable this timer to get full dump of QML object-hierarchy.
            //dumpActiveFocusTimer.restart()
        }
    }

    GlobalNotification {
        allow: scope.state === "Image" || scope.state === "Video" || scope.state === "PreView"
        showPopup: VideoControl.videoMode === VideoControl.Off
    }

    //Need an extra overlay here to crop the liveview until the correct state is set and the LiveViewOverlay has been loaded
    CropOverlay {
        anchors.fill: parent
        visible: scope.state === "" && VideoControl.videoMode !== VideoControl.Zoom && System.camera_mode === System.CameraModeImage
        onVisibleChanged: {
            if (visible) {
                calcCropping(configstore.aspectRatio)
            }
        }
    }


    Connections {
        target: BodySync
        onHdmiCableConnectedChanged: {
            if(BodySync.hdmiCableConnected)
            {
                if(guiconfig.isRunningSimulation())
                {
                    root.width = 1364
                }
            }
            else
            {
                if(VideoControl.videoMode !== VideoControl.Record)
                    Camera.setLiveViewState(false)
                if(guiconfig.isRunningSimulation())
                {
                    root.width = 1024
                }
            }
        }
    }

    FocusScope {
        objectName: "EVFWindow_focusScope"
        id: scope
        // Avoid update if the window is not visible...
        visible: false
        anchors.fill: parent
        focus: true

        Keys.onPressed: {
            if (event.isAutoRepeat) {
                return
            }

            var doBrowse = MKeys.pressedFnAcc("PLAY", event)
            var doMain = false
            if(!doBrowse)
                doMain = MKeys.pressedFnAcc("MENU", event)
            if (doBrowse && !isInHDMI && states.state !== "PreView") {
                openPreView(true, false)//showLastItem, startTimer
            } else if (doBrowse || doMain) {
                if(!System.isTethered && isInHDMI) {
                    Camera.setLiveViewState(false)
                    VideoControl.setVideoRecordState(false)
                    if(doBrowse)
                        setToBrowse()
                    else if(doMain)
                        setToMain()
                }
            }
            else if (state === "Image" && isInHDMI && (configstore.CameraType !== Config.CameraTypeHsystem) && MKeys.pressedFnAcc("CROSS", event)) {
                setToControl()
            }
            else if (commonKeyHandle(event))
            {
                return
            }
            else
            {
                event.accepted = false
                console.log("Unhandled key:", event.key)
            }
        }

        Keys.onReleased: {
            if (event.isAutoRepeat)
                return

            commonKeyHandleReleased(event)
        }

        // Temporarily have a grey background to see things
        Rectangle {
            objectName: "EVFWindow_GreyRectangle"
            anchors.fill: parent
            color: "grey"
            visible: guiconfig.isRunningSimulation()
        }

        Loader {
            source: "qrc:///liveview/LiveViewImage.qml"
            objectName: "EVFImageLiveView"
            id: wedgeliveview
            anchors.fill:parent
            asynchronous: true
            active: false
            property bool show_overlay: false

            onLoaded: {
                item.isInHDMI = root.isInHDMI
                item.enabled = true
                item.visible = show_overlay
                item.focus = show_overlay
                item.forceActiveFocus()
            }

            onShow_overlayChanged: {
                active = true
                if (item !== null) {
                    item.visible = show_overlay
                    item.focus = show_overlay
                    item.inActiveWindow = show_overlay
                }
                wedgeliveview.focus = show_overlay
            }

            onActiveFocusChanged: if(!activeFocus) scope.forceActiveFocus()
        }

        Loader {
            source: "qrc:///liveview/LiveViewVideo.qml"
            objectName: "EVFWindow_LiveViewVideo"
            id: wedgeLiveViewVideo
            anchors.fill: parent
            asynchronous: true
            active: false
            property bool show_overlay: false

            onLoaded: {
                item.enabled = true
                item.isInHDMI = root.isInHDMI
                item.visible = show_overlay
                item.focus = show_overlay
                item.forceActiveFocus()
            }

            onShow_overlayChanged: {
                active = true
                if (item !== null) {
                    item.visible = show_overlay
                    item.focus = show_overlay
                }
                wedgeLiveViewVideo.focus = show_overlay
            }
            onActiveFocusChanged: if(!activeFocus) scope.forceActiveFocus()
        }

        Loader {
            property int startIndex: -1
            property bool startTimer: false
            objectName: "Preview_loader"
            id: preView
            active: false
            anchors.fill: parent
            visible: active
            asynchronous: true
            onActiveChanged: {
                console.log("preview active", active)
                if (active) {
                    focus = true
                    setSource("qrc:///components/MediaBrowseView.qml", {"usedInEVF": true, "initIndex": startIndex})
                } else {
                    showPreview = false
                    evfPreviewTimer.stop()
                    // Just make sure we have something listening to button events when this is deactivated
                    scope.forceActiveFocus()
                }
            }
            onLoaded: {
                if (preView.startTimer) {
                    preView.startTimer = false
                    evfPreviewTimer.restart()
                }
            }
            Connections {
                target: preView.item
//                onCurrentItemLoaded: {
//                    if (preView.startTimer) {
//                        preView.startTimer = false
//                        evfPreviewTimer.restart()
//                    }
//                }
                onKeyPressed: {
                    if (scope.state === "PreView") {
                        evfPreviewTimer.stop()
                    }
                }
            }
        }

        Timer {
            id: evfPreviewTimer
            interval: (configstore.EVFPreviewTimeout > 0) ? configstore.EVFPreviewTimeout : 0
            onTriggered: {
                //Check inSession to not start LV in continuous drive mode
                if (!Camera.inSession) {
                    Camera.setLiveViewState(true)
                }
            }
        }

        Loader {
            objectName: "PreStart_loader"
            id: hdmiPreLiveView
            active: true
            source: "qrc:///liveview/HDMIPreStart.qml"
            anchors.fill: parent
            visible: false
            asynchronous: true
            enabled: false
            onEnabledChanged: {
                if(!enabled)
                {
                    // Just make sure we have something listening to button events when this is deactivated
                    scope.forceActiveFocus()
                }
            }
            onActiveFocusChanged: {
                if(!activeFocus)
                {
                    // Just make sure we have something listening to button events when this is deactivated
                    scope.forceActiveFocus()
                }
            }
        }
        Loader {
            objectName: "HDMIExposing_loader"
            id: hdmiExposing
            active: true
            source: "qrc:///liveview/HDMIExposing.qml"
            anchors.fill: parent
            visible: false
            asynchronous: true
            enabled: false
            onEnabledChanged: {
                if(!enabled) {
                    // Just make sure we have something listening to button events when this is deactivated
                    scope.forceActiveFocus()
                }
            }
            onActiveFocusChanged: {
                if(!activeFocus) {
                    // Just make sure we have something listening to button events when this is deactivated
                    scope.forceActiveFocus()
                }
            }
        }

        // Error popup for ackable errors....
        Loader {
            objectName: "errorAckPopupLoader"
            id: errorPopupLoader
            anchors.fill: parent
            active: ErrorControl.code !== Errors.ErrorNone && ErrorControl.isAckable
            source: "qrc:///components/popups/ErrorPopup.qml"
            focus: active
            property int previousBodyState: BodySync.MAIN

            onActiveFocusChanged: {
                //For some reason the item does not always get focus
                if (activeFocus) {
                    item.focus = true
                }
            }

            onActiveChanged: {
                if (active)
                {
                    if (GlobalStateInfo.errorPopupOwner === "" && BodySync.focusSurface === "overlay") {
                        GlobalStateInfo.errorPopupOwner = BodySync.focusSurface
                        previouslyActiveItem = root.activeFocusItem
                        item.forceActiveFocus()

                        previousBodyState = BodySync.currentState
                        if(guiconfig.isWedge)
                        {
                            // Prevent things to change due to scroll wheels
                            BodySync.currentState = BodySync.MENU;
                        }
                    }
                }
                else
                {
                    //Only do cleanup if this popup is the owner (i.e. was the first popup to show the error)
                    if (GlobalStateInfo.errorPopupOwner === "overlay" && ErrorControl.code === Errors.ErrorNone) {
                        GlobalStateInfo.errorPopupOwner = ""
                        if (previouslyActiveItem == null) {
                            previouslyActiveItem = scope
                        }
                        console.log("Resetting active item to: ", previouslyActiveItem)
                        previouslyActiveItem.forceActiveFocus()
                        previouslyActiveItem = null

                        if(guiconfig.isWedge)
                        {
                            BodySync.currentState = previousBodyState;
                        }
                    }
                }
            }
            onLoaded: item.showAckButton = false
        }

        Loader {
            objectName: "EVF_DialModeOverlay_Loader"
            id: dialMode
            source: "qrc:///components/DialModeOverlay.qml"
            asynchronous: true
            active: guiconfig.isWedge
            anchors.fill: parent
            onLoaded: {
                console.log("EVF Dial is loaded")
            }
            // Somehow the width is not yet already updated when onLoaded is emitted.
            onVisibleChanged: if(visible && (item !== null)) item.sizeFactor = width / 1024
        }

        Loader {
            id: fatalError
            objectName: "fatalError"
            asynchronous: true
            active: false
            anchors.fill: parent
        }

        onStateChanged: console.log("New EVF state: ", state)
        states: [
            State {
                name: "batteryexhausted"
                // Battery is exhausted. Special treatment
                when: (ErrorControl.code === Errors.ErrorBatteryExhausted) && !root.disabled
                PropertyChanges { target: fatalError; active: true; source: "qrc:///components/popups/BatteryExhausted.qml"  }
                PropertyChanges { target: fatalError; focus: true; restoreEntryValues: false }
            },
            State {
                name: "Error"
                // An error which is not ackable -> serious...
                when: ErrorControl.code !== Errors.ErrorNone && !ErrorControl.isAckable && !root.disabled
                StateChangeScript {
                    script: {
                        fatalError.setSource("qrc:///components/popups/PopoverError.qml",
                                                 {
                                                     "errcodeText" : ErrorControl.code,
                                                     "subText" : ErrorControl.message,
                                                     /*"bottomText":,*/
                                                     "icon": "qrc:///icons/exclamationMark.png",
                                                     "showButtons": false
                                                 });
                    }
                }
                PropertyChanges { target: fatalError; active: true }
                PropertyChanges { target: fatalError; focus: true; restoreEntryValues: false }
            },
            State {
                name: "PreView"
                when: guiconfig.isWedge && showPreview && !isInHDMI && (VideoControl.videoMode === VideoControl.Off || VideoControl.videoMode === VideoControl.Playback)
                PropertyChanges { target: preView; active: true}
            },
            State {
                name: "HDMIExposing"
                when: isInHDMI && Camera.exposing
                PropertyChanges { target: hdmiExposing; visible: true; enabled: true; focus: true}
            },
            State {
                name: "HDMIPreLiveView"
                when: isInHDMI && (VideoControl.videoMode === VideoControl.Off) && !GlobalStateInfo.waitingForLiveView
                PropertyChanges { target: hdmiPreLiveView; visible: true; enabled: true; focus: true}
            },
            State {
                name: "hdmiPlayback"
                when: (VideoControl.videoMode === VideoControl.Playback && isInHDMI)
                //Do not activate any overlays for HDMI. Is this correct?
            },
            State {
                name: "Video"
                when: (System.camera_mode === System.CameraModeVideo) && (root.active || isInHDMI) && ErrorControl.code === Errors.ErrorNone
                PropertyChanges { target: wedgeLiveViewVideo; show_overlay: true }
            },
            State {
                name: "Image"
                when: (System.camera_mode === System.CameraModeImage) && (root.active || isInHDMI) && ErrorControl.code === Errors.ErrorNone
                PropertyChanges { target: wedgeliveview; show_overlay: true }
            }
        ]

    }

    onClosing:Qt.quit()
}

