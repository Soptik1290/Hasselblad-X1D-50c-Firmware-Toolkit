import QtQuick 2.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.camera 1.0
import "qrc:///scripts/Keys.js" as MKeys
FocusScope {
    objectName: "LiveView_root"
    id: root
    focus: true
    anchors.fill: parent
    signal requestMainScreen()
    property bool preventLiveViewSwipe: false
    property bool isInHDMI: false
    property bool inActiveWindow: false
    function closeIsoWb()
    {
        liveViewImage.closeIsoWb()
    }
    Keys.onPressed: {
        if(MKeys.pressedFnAcc("LEFT", event) ||
                MKeys.pressedFnAcc("RIGHT", event) ||
                MKeys.pressedFnAcc("UP", event) ||
                MKeys.pressedFnAcc("DOWN", event) ||
                MKeys.pressedFnAcc("CROSS", event) ||
                MKeys.pressedFnAcc("STAR", event) ||
                MKeys.pressedFnAcc("SQUARE", event))
        {
            return
        }
        else if(VideoControl.videoMode === VideoControl.Record && MKeys.pressedFnAcc("MENU", event)) {
        }
        else
            event.accepted = false
    }
    MouseArea {
        id: dragArea
        enabled: false
        propagateComposedEvents: false
        anchors.fill: parent
        drag {
            target: liveViewArea
            axis: Drag.XAxis
            minimumX: root.x
            maximumX: root.x + root.width
            threshold: constants.dragThreshold
            filterChildren: true
        }
        drag.onActiveChanged: {
            if (!drag.active) {
                if (liveViewArea.x > (root.x + root.width / constants.swipeLengthDividor))
                    root.requestMainScreen()
                liveViewArea.x = root.x
            }
        }
        FocusScope {
            id: liveViewArea
            objectName: "liveViewArea"
            x: parent.x
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            focus: true
            LiveViewImage {
                id: liveViewImage
                anchors.fill: parent
                visible: enabled
                enabled: false
                enableDrag: true
                isInHDMI: root.isInHDMI
                inActiveWindow: root.inActiveWindow
                focus: enabled
            }
            LiveViewVideo {
                id: liveViewVideo
                anchors.fill: parent
                visible: enabled
                enabled: false
                isInHDMI: root.isInHDMI
                iconsVisible: true
                focus: enabled
            }
        }
    }
    states: [
        State {
            name: "Video"
            when: System.camera_mode === System.CameraModeVideo
            PropertyChanges { target: liveViewVideo; visible: true; enabled: true; focus: true}
        },
        State {
            name: "Image"
            when: System.camera_mode === System.CameraModeImage
            PropertyChanges { target: liveViewImage; visible: true; enabled: true; focus: true}
        }
    ]
    transitions: [
        Transition {
            from: "Video"
            ScriptAction {
                script: {
                    if (VideoControl.videoMode === VideoControl.Record)
                    {
                        VideoControl.setVideoRecordState(false)
                    }
                }
            }
        }
    ]
}
