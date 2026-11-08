import QtQuick 2.0
import QtGraphicalEffects 1.0

LinearGradient {
    id: fader
    property color fadeColor: "black"
    // Adapt everything to whether we're located at the left/right or top/bottom
    property bool isHorz: parent.orientation === ListView.Horizontal
    property real sizeFactor: 0.5
    // Unless our desktop-qt qtdeclarative flickable is patched, we can't use this effect in simulation.
    property int overShoot: {
        if(guiconfig.isRunningSimulation())
            return 0 // in simulation we don't have any custom bounds behavior support (yet)
        if (!parent.dragging) //Workaround for bug in flickable which results in overshoot when closing dropdown
            return 0
        if (!isHorz && !parentVerticalOvershootValid) //Workaround for another flickable overshoot bug
            return 0
        var value = ~~(isHorz ? parent.horizontalOvershoot : parent.verticalOvershoot)
        //value *= sizeFactor
        var limit = isHorz ? width : height
        value = value < 0 ? Math.max(value, -limit) : Math.min(value, limit)
        return value
    }
    //Workaround for bug in flickable which is triggered by closing a dropdown item. Results in flickable reporting overshoot when dragging in the list
    property bool parentVerticalOvershootValid: parent.contentY <= 0 ? true : (parent.contentY + parent.height - parent.originY) >= parent.contentHeight

    // Note: Special limitation since overshoot may be reported when listview goes visible from invisible.
    visible: !guiconfig.isRunningSimulation() && (isHorz ? overShoot + 2 < ~~width && overShoot - 2 > -~~width : true) && overShoot !== 0

    x: isHorz ? (overShoot >= 0 ? parent.width - overShoot : -width - overShoot) : 0
    y: !isHorz ? (overShoot >= 0 ? parent.height - overShoot : -height - overShoot) : 0

    width: isHorz ? parent.width * sizeFactor : parent.width
    height: !isHorz ? parent.height * sizeFactor : parent.height

    start: Qt.point(0, 0)
    end: Qt.point(isHorz ? width : 0, !isHorz ? height : 0)
    gradient: Gradient {
        GradientStop { position: overShoot <= 0 ? 0 : 1; color: fader.fadeColor }
        GradientStop { position: overShoot <= 0 ? 1 : 0; color: "transparent" }
    }

//    property int maxOvershoot: -1000
//    property int minOvershoot: 1000
//    onOverShootChanged: {
//        minOvershoot = Math.min(minOvershoot, overShoot)
//        maxOvershoot = Math.max(maxOvershoot, overShoot)
//        console.log("actual:", overShoot, "minOverShoot:", minOvershoot, "maxOvershoot:", maxOvershoot, "width:", width, "height:",height, "x:",x, "y:",y)
//    }
}
