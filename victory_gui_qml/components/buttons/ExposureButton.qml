import QtQuick 2.5
import com.hasselblad.config 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.video 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.error 1.0
Rectangle {
    id: root
    property bool canDrag: false
    property bool isVisible: true
    property bool isDragging: false
    property real minDragX: parent.x
    property real minDragY: parent.y
    property real maxDragX: parent.x + parent.width
    property real maxDragY: parent.y + parent.height
    signal mouseEvent()
    signal dragCompleted()
    visible: (cambody.capabilities & Cambody.CapabilityGuiExposure) !== 0 && isVisible
    opacity: canDrag ? 0.85 : 1
    height: 110
    width: height
    radius: height / 2
    color: Camera.exposing ? "lightgrey" : (mouseArea.dragInitiated ? "steelblue" : constants.hblOrange)
    border {
        color: Camera.exposing ? "darkgray" : (root.focus ? constants.hblOrangeDark : "white")
        width: root.focus ? 4 : 3
    }
    function startExposure(allowLive)
    {
        stopDelayedLiveView()
        if (System.camera_mode === System.CameraModeVideo) {
            var start = (VideoControl.videoMode !== VideoControl.Record);
            VideoControl.setVideoRecordState(start)
        }
        else
        {
            VideoControl.setZoomState(false)
            Camera.startSession(configstore.ExpMode !== Config.ExpMode_ManualQuick)
            Camera.startExposing(!configstore.CustomOption_ShowPreview && (configstore.ExpMode !== Config.ExpMode_ManualQuick))
            Camera.stopExposing()
            Camera.stopSession()
        }
        if((ErrorControl.code !== Errors.ErrorNone) && ErrorControl.isAckable)
        {
            ErrorControl.ack()
        }
    }
    function stopExposure()
    {
        cambody.forceFinishExposure()
        preventIdle(false)
    }
    MouseArea {
        id: mouseArea
        property bool dragInitiated: false
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: false
        onClicked: if(containsPress || canDrag) {
           mouseEvent()
           if(cambody.exposing)
               root.stopExposure()
           else
               root.startExposure(false)
        }
        onPressAndHold: {
            if(!root.canDrag) {
                mouseEvent()
                Camera.setLiveViewState(true)
            }
            else
                dragInitiated = true
        }
        onReleased: mouseArea.dragInitiated = false
        drag {
            target: root.canDrag && dragInitiated ? root : null
            axis: Drag.XAndYAxis
            minimumX: root.minDragX
            maximumX: root.maxDragX - width
            minimumY: root.minDragY
            maximumY: root.maxDragY - height
            filterChildren: true
            onActiveChanged: {
                root.isDragging = drag.active
                if(drag.active)
                    mouseEvent()
                else {
                    dragCompleted()
                }
            }
        }
    }
}
