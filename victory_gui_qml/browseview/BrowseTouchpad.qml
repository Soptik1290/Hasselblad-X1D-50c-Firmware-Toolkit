import QtQuick 2.5
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.mockup 1.0
import "qrc:/components"
MultiPointTouchArea {
    id: root
    property int xLastPos: 0
    property int yLastPos: 0
    property int lastPinchDistance: 0
    property int padWidth: isInHDMI ? width: 300
    property int padHeight: configstore.touchpad_position === Config.TouchpadLeft ||
                            configstore.touchpad_position === Config.TouchpadRight || isInHDMI ? root.height : 225
    property int xStart: configstore.touchpad_position === Config.TouchpadTopLeft ||
                         configstore.touchpad_position === Config.TouchpadLeft ||
                         configstore.touchpad_position === Config.TouchpadBottomLeft || isInHDMI ? 0 : width - padWidth
    property int yStart: (configstore.touchpad_position === Config.TouchpadBottomLeft ||
                         configstore.touchpad_position === Config.TouchpadBottomRight) && !isInHDMI ? height - padHeight : 0
    property bool inZoomMode: GlobalStateInfo.evfBrowseViewState === "zooming"
    property bool inNormalMode: !inZoomMode
    property int zoomPanStepSize: 10
    property int navigateStepSize: 50
    property int pinchDistanceStepSize: 20
    property int swipeStepSize: 2
    property bool navigateDone: false
    property bool wasInTouchArea: false
    property bool isInHDMI: false
    property string clickState: "none"
    property bool pinchEnabled: false
    KeyInject {
        id: keyComp
    }
    onPressed: {
        var validPoints = getValidPoints(touchPoints)
        if (validPoints.length > 1) {
            lastPinchDistance = Math.abs(validPoints[0].x - validPoints[1].x) + Math.abs(validPoints[0].y - validPoints[1].y)
        } else if (validPoints.length === 1) {
            xLastPos = validPoints[0].x
            yLastPos = validPoints[0].y
            if (clickState === "none") {
                clickTimer.start()
            } else if (clickState === "single") {
                clickTimer.restart()
            }
        }
        wasInTouchArea = validPoints.length > 0
        if (pinchEnabled) {
            updatePinchActive(validPoints.length)
        }
    }
    onReleased: {
        navigateDone = false
        GlobalStateInfo.imgPinchActive = false
        GlobalStateInfo.imgSwipeDir = 0
        if (clickTimer.running) {
            clickTimer.stop()
            if (clickState === "none") {
                clickState = "single"
                clickTimer.restart()
            } else {
                keyComp.inject("double_click", true)
                keyComp.inject("double_click", false)
                clickState = "none"
            }
        }
    }
    onTouchUpdated: {
        if (enabled) {
            var validPoints = getValidPoints(touchPoints)
            if (validPoints.length > 1) {
                if (pinchEnabled) {
                    updatePinchDistance(validPoints)
                }
            } else if (validPoints.length === 1) {
                var x = validPoints[0].x
                var y = validPoints[0].y
                if (!wasInTouchArea) {
                    xLastPos = x
                    yLastPos = y
                }
                if (inZoomMode) {
                    updateZoomPosition(x,y)
                } else if (inNormalMode){
                    updateNormalPosition(x,y)
                }
            }
            wasInTouchArea = validPoints.length > 0
            if (pinchEnabled) {
                updatePinchActive(validPoints.length)
            }
        }
    }
    function updatePinchActive(numValidPoints) {
        GlobalStateInfo.imgPinchActive = numValidPoints > 1 && (GlobalStateInfo.evfBrowseViewState === "list" || GlobalStateInfo.evfBrowseViewState === "zooming")
    }
    function getValidPoints(touchPoints) {
        var i = 0
        var validPoints = []
        for ( i = 0; i < touchPoints.length; i++) {
            var xPos = touchPoints[i].x
            var yPos = touchPoints[i].y
            if (isInTouchArea(xPos, yPos)) {
                validPoints.push(Qt.point(xPos, yPos))
            }
        }
        return validPoints
    }
    function isInTouchArea(x,y) {
        return x >= xStart && x < xStart+padWidth &&
               y >= yStart && y < yStart+padHeight
    }
    function updateNormalPosition(x,y) {
        var xDiff = x-xLastPos
        var yDiff = y-yLastPos
        var is9View = GlobalStateInfo.evfBrowseViewState === "grid"
        var key = ""
        if (is9View) {
            if (Math.abs(xDiff) >= navigateStepSize && !navigateDone) {
                xLastPos = x
                navigateDone = true
                key =  xDiff < 0 ? "left" : "right"
                keyComp.inject(key, true)
                keyComp.inject(key, false)
            }
            if (Math.abs(yDiff) >= navigateStepSize && !navigateDone) {
                yLastPos = y
                navigateDone = true
                key =  yDiff < 0 ? "up" : "down"
                keyComp.inject(key, true)
                keyComp.inject(key, false)
            }
        } else {
            if (Math.abs(xDiff) >= swipeStepSize) {
                xLastPos = x
                GlobalStateInfo.imgSwipeDir = (GlobalStateInfo.imgZoomPanXDir !== xDiff) ? xDiff : 2*xDiff
            }
        }
    }
    function updateZoomPosition(x,y) {
        var xDiff = x-xLastPos
        var yDiff = y-yLastPos
        var direction = 0
        if (Math.abs(xDiff) >= zoomPanStepSize) {
            direction = xDiff < 0 ? 1 : -1
            xLastPos = x
            GlobalStateInfo.imgZoomPanXDir = (GlobalStateInfo.imgZoomPanXDir !== direction) ? direction : 2*direction
        }
        if (Math.abs(yDiff) >= zoomPanStepSize) {
            direction = yDiff < 0 ? 1 : -1
            yLastPos = y
            GlobalStateInfo.imgZoomPanYDir = (GlobalStateInfo.imgZoomPanYDir !== direction) ? direction : 2*direction
        }
    }
    function updatePinchDistance(points) {
        var distance = Math.abs(points[0].x - points[1].x) + Math.abs(points[0].y - points[1].y)
        var distanceDiff = lastPinchDistance - distance
        if (Math.abs(distanceDiff) >= pinchDistanceStepSize) {
            var pinchDirection = distanceDiff < 0 ? -1 : 1
            lastPinchDistance = distance
            GlobalStateInfo.imgPinchDir = (GlobalStateInfo.imgPinchDir !== pinchDirection) ? pinchDirection : 2*pinchDirection
        }
    }
    function initValues() {
    }
    Timer {
        id: clickTimer
        running: false
        interval: 200
        repeat: false
        onTriggered: {
            clickState = "none"
        }
    }
}
