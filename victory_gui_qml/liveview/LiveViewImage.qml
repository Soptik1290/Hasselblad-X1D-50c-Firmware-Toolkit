import QtQuick 2.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0
import com.hasselblad.lens 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.bodysync 1.0
import "qrc:///components/"
import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys
import "qrc:///scripts/commonfunc.js" as Cmn
FocusScope {
    objectName: "LiveViewImage_root"
    id: root
    focus: true
    property alias preventSwipe: info.zoomIndicatorVisible
    property alias enableDrag: dragArea.enabled
    property bool isInHDMI: false
    property bool inActiveWindow: false
    function findFocusWasStopped()
    {
        info.findFocusWasStopped()
    }
    function resetOverlay()
    {
        info.resetOverlay()
    }
    function closeIsoWb()
    {
        info.closeIsoWb()
    }
    onEnabledChanged: {
        if(enabled)
        {
            info.checkOverlay()
        }
    }
    onFocusChanged: console.log("LiveViewImage has focusChange to: ", focus)
    function liveViewSwitch(mouse) {
        info.zoom(mouse.x, mouse.y)
        VideoControl.restartLiveViewImageTimeout()
    }
    MouseArea {
        id: dragArea
        onPressAndHold: if(!exposureButton.isDragging) liveViewSwitch(mouse)
        onDoubleClicked: liveViewSwitch(mouse)
        anchors.fill: parent
        onPressed: info.startZoomTimer()
        onReleased: info.startZoomTimer()
        enabled: true
    }
    ExposureButton {
        id: exposureButton
        z: 1
        isVisible: info.infoVisible && !GlobalStateInfo.evfActive && !root.isInHDMI
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
        minDragY: 90
        maxDragY: parent.height - 55
    }
    ZoomCalc {
        id: zoomCalc
    }
    Flickable{
        id: zoomFlick
        visible: info.zoomIndicatorVisible
        anchors.fill: parent
        contentWidth: flickItem.width
        contentHeight: flickItem.height
        boundsBehavior: Flickable.StopAtBounds
        property bool updateAllowed: true
        onVisibleChanged: {
            if(visible) {
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
                info.startZoomTimer()
            }
        }
        onContentYChanged: {
            if(updateAllowed && !GlobalStateInfo.touchpadZoomActive)
            {
                var newY = contentY / (contentHeight - zoomFlick.height)
                var newX = contentX / (contentWidth - zoomFlick.width)
                zoomCalc.setZoomPoint(Qt.point(newX, newY))
                info.startZoomTimer()
            }
        }
        Connections {
            target: VideoControl
            onZoomPointChanged: {
                if (GlobalStateInfo.touchpadZoomActive) {
                    zoomFlick.updateContentFromZoomPoint()
                }
            }
        }
        Item{
            id: flickItem
            width: guiconfig.maxImageXSize
            height: guiconfig.maxImageYSize
            CropOverlay {
                anchors.fill: parent
                onVisibleChanged: {
                    if (visible) {
                        calcCropping(configstore.aspectRatio)
                    }
                }
            }
        }
        MouseArea {
            id: flickClickArea
            onPressAndHold: liveViewSwitch(mouse)
            onDoubleClicked: liveViewSwitch(mouse)
            anchors.fill: parent
        }
    }
    Item {
        id: liveViewArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: parent.x
        width: parent.width
        focus: true
        LiveViewOverlay {
            id: info
            anchors.fill: parent
            dragAreaPressed: dragArea.pressed
            isInHDMI: root.isInHDMI
            inActiveWindow: root.inActiveWindow
            focus: true
        }
    }
    onActiveFocusChanged: {
        if (activeFocus && VideoControl.videoMode === VideoControl.Zoom) {
            BodySync.currentState = BodySync.MENU
        }
    }
    Keys.onPressed: {
        if (event.isAutoRepeat) {
            event.accepted = false
        } else if (VideoControl.videoMode === VideoControl.Zoom){
            var stepSize = 600
            if (MKeys.pressedFnAcc("UP", event)) {
                zoomFlick.contentY = (zoomFlick.contentY >= stepSize) ? zoomFlick.contentY - stepSize : 0
            } else if (MKeys.pressedFnAcc("DOWN", event)) {
                zoomFlick.contentY = (zoomFlick.contentY <= (zoomFlick.contentHeight - zoomFlick.height - stepSize)) ? zoomFlick.contentY + stepSize : (zoomFlick.contentHeight - zoomFlick.height)
            } else if (MKeys.pressedFnAcc("LEFT", event)) {
                zoomFlick.contentX = (zoomFlick.contentX >= stepSize) ? zoomFlick.contentX - stepSize : 0
            } else if (MKeys.pressedFnAcc("RIGHT", event)) {
                zoomFlick.contentX = (zoomFlick.contentX <= (zoomFlick.contentWidth - zoomFlick.width - stepSize)) ? zoomFlick.contentX + stepSize : (zoomFlick.contentWidth - zoomFlick.width)
            }
        }
    }
}
