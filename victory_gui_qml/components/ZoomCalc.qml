import QtQuick 2.5

import com.hasselblad.video 1.0
import com.hasselblad.globalstateinfo 1.0

/* Object for sharing zoom related functionality used by:
  - LiveViewImage
  - EVFTouchpad
*/

Item {
    id: root
    // Don't change var to int below, it will cause multiple setZoomPoint signals
    // due to re-evaluation
    property var previousUpdateTime: 0
    property point lastPos: VideoControl.zoomPoint
    property int minInterval: 100

    function setZoomPoint(setPoint)
    {
        // Setting zoomPoint too often results in white flimmer at top/bottom parts of screen.
        // Check if enough time has passed since last position update.
        var periodTime = minInterval
        var now = new Date().valueOf()
        var diff = now - previousUpdateTime

        if(diff >= periodTime)
        {
            // Enough time has passed, send pos
            previousUpdateTime = now
            VideoControl.zoomPoint = setPoint
            console.log("Set new zoom point: ", setPoint.x, setPoint.y)
        }
        else
        {
            // Not enough time, start timer to send update
            startUpdateTimer(periodTime - diff)
        }
        lastPos = setPoint
    }

    Connections {
        target: VideoControl
        onZoomPointChanged: {
            console.log
            //Moved zoom point with scroll wheels while in zoom mode
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
