import QtQuick 2.5
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import "qrc:/components"
MultiPointTouchArea {
    id: root
    property int xLastPos: 0
    property int yLastPos: 0
    property int padWidth: isInHDMI ? width: 300
    property int padHeight: configstore.touchpad_position === Config.TouchpadLeft ||
                            configstore.touchpad_position === Config.TouchpadRight || isInHDMI ? root.height : 225
    property int xStart: configstore.touchpad_position === Config.TouchpadTopLeft ||
                         configstore.touchpad_position === Config.TouchpadLeft ||
                         configstore.touchpad_position === Config.TouchpadBottomLeft || isInHDMI ? 0 : width - padWidth
    property int yStart: (configstore.touchpad_position === Config.TouchpadBottomLeft ||
                         configstore.touchpad_position === Config.TouchpadBottomRight) && !isInHDMI ? height - padHeight : 0
    property int relativeStepSize: (padWidth < padHeight) ? afc.afItemWidth*padWidth/width :
                                                            afc.afItemHeight*padHeight/height
    property bool inZoomMode: VideoControl.videoMode === VideoControl.Zoom
    property bool inFocusMode: !inZoomMode && System.camera_mode === System.CameraModeImage && configstore.ExpMode !== Config.ExpMode_FullAuto &&
                               (isInHDMI ? configstore.hdmi_tp_move_focus : configstore.evf_tp_move_focus)
    property int zoomStepSize: 2
    property real zoomStepFinal: 0.003
    property bool wasInTouchArea: false
    property bool isInHDMI: false
    onInZoomModeChanged: {
        if (inZoomMode) {
            zoomCalc.lastPos = VideoControl.zoomPoint
        }
    }
    AFCalc {
        id: afc
        screenWidth: root.width
        screenHeight: root.height
        idText: "In Touchpad"
    }
    ZoomCalc {
        id: zoomCalc
        minInterval: 50
    }
    onPressed: {
        GlobalStateInfo.touchpadZoomActive = inZoomMode
        for (var i = 0; i < touchPoints.length; i++) {
            if (isInTouchArea(touchPoints[i].x, touchPoints[i].y)) {
                wasInTouchArea = true
                xLastPos = touchPoints[i].x
                yLastPos = touchPoints[i].y
                return
            }
        }
        wasInTouchArea = false
    }
    onReleased: {
        GlobalStateInfo.touchpadZoomActive = false
    }
    onTouchUpdated: {
        if (enabled) {
            var i = 0
            for ( i = 0; i < touchPoints.length; i++) {
                var x = touchPoints[i].x
                var y = touchPoints[i].y
                if (isInTouchArea(x, y)) {
                    if (!wasInTouchArea) {
                        xLastPos = x
                        yLastPos = y
                    }
                    wasInTouchArea = true
                    if (inZoomMode && GlobalStateInfo.touchpadZoomActive) {
                        updateZoomPosition(x,y)
                    } else if (inFocusMode && !GlobalStateInfo.touchpadZoomActive){
                        updateAfIndexRelativePosition(x,y)
                    }
                    return
                }
            }
            wasInTouchArea = false
        }
    }
    function isInTouchArea(x,y) {
        return x >= xStart && x < xStart+padWidth &&
               y >= yStart && y < yStart+padHeight
    }
    function updateAfIndexRelativePosition(x,y) {
        var xDiff = x-xLastPos
        var yDiff = y-yLastPos
        if (Math.abs(xDiff) >= relativeStepSize) {
            var modulo = GlobalStateInfo.afSselectedIndex % afc.xCount
            if ((xDiff < 0 && modulo > 0) ||
                (xDiff > 0 && modulo < afc.xCount-1)) {
                GlobalStateInfo.afSselectedIndex = GlobalStateInfo.afSselectedIndex + (xDiff < 0 ? -1 : 1)
                xLastPos = x
                afc.selectAndSave()
            }
        }
        if (Math.abs(yDiff) >= relativeStepSize) {
            if ((yDiff < 0 && GlobalStateInfo.afSselectedIndex >= afc.xCount) ||
                (yDiff > 0 && GlobalStateInfo.afSselectedIndex < afc.xCount*(afc.yCount-1))) {
                GlobalStateInfo.afSselectedIndex = GlobalStateInfo.afSselectedIndex + (yDiff < 0 ? -1 : 1)*afc.xCount
                yLastPos = y
                afc.selectAndSave()
            }
        }
    }
    function updateZoomPosition(x,y) {
        var xDiff = x-xLastPos
        var yDiff = y-yLastPos
        var newX = zoomCalc.lastPos.x
        var newY = zoomCalc.lastPos.y
        var changed = false
        if (Math.abs(xDiff) >= zoomStepSize) {
            newX = newX + (xDiff > 0 ? -1 : 1)*zoomStepFinal
            newX = (newX > 1) ? 1 : (newX < 0) ? 0 : newX
            xLastPos = x
            changed = true
        }
        if (Math.abs(yDiff) >= zoomStepSize) {
            newY = newY + (yDiff > 0 ? -1 : 1)*zoomStepFinal
            newY = (newY > 1) ? 1 : (newY < 0) ? 0 : newY
            yLastPos = y
            changed = true
        }
        if (changed) {
            zoomCalc.setZoomPoint(Qt.point(newX, newY))
        }
        VideoControl.restartLiveViewImageTimeout()
    }
    function initValues() {
        afc.updateSizeIndex()
        if (GlobalStateInfo.afSselectedIndex < 0) {
            afc.setStartPoint()
        }
    }
}
