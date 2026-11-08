import QtQuick 2.5
import com.hasselblad.video 1.0
import com.hasselblad.globalstateinfo 1.0
Item {
    id: root
    property var previousUpdateTime: 0
    property point lastPos: VideoControl.zoomPoint
    property int minInterval: 100
    function setZoomPoint(setPoint)
    {
        var periodTime = minInterval
        var now = new Date().valueOf()
        var diff = now - previousUpdateTime
        if(diff >= periodTime)
        {
            previousUpdateTime = now
            VideoControl.zoomPoint = setPoint
            console.log("Set new zoom point: ", setPoint.x, setPoint.y)
        }
        else
        {
            startUpdateTimer(periodTime - diff)
        }
        lastPos = setPoint
    }
    Connections {
        target: VideoControl
        onZoomPointChanged: {
            console.log
            if (!GlobalStateInfo.touchpadZoomActive) {
                lastPos = VideoControl.zoomPoint
            }
        }
    }
    function startUpdateTimer(timerLength)
    {
        updateTimer.interval = timerLength
        updateTimer.start()
    }
    Timer {
        id: updateTimer
        interval: minInterval
        repeat: false
        onTriggered: {
            if(!root.lastPos.isNull)
            {
                VideoControl.zoomPoint = root.lastPos
                root.previousUpdateTime = new Date().valueOf()
            }
        }
    }
}
