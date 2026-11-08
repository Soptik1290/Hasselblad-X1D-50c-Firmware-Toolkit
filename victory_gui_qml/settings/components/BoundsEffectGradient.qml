import QtQuick 2.0
import QtGraphicalEffects 1.0
LinearGradient {
    id: fader
    property color fadeColor: "black"
    property bool isHorz: parent.orientation === ListView.Horizontal
    property real sizeFactor: 0.5
    property int overShoot: {
        if(guiconfig.isRunningSimulation())
            return 0
        if (!parent.dragging)
            return 0
        if (!isHorz && !parentVerticalOvershootValid)
            return 0
        var value = ~~(isHorz ? parent.horizontalOvershoot : parent.verticalOvershoot)
        var limit = isHorz ? width : height
        value = value < 0 ? Math.max(value, -limit) : Math.min(value, limit)
        return value
    }
    property bool parentVerticalOvershootValid: parent.contentY <= 0 ? true : (parent.contentY + parent.height - parent.originY) >= parent.contentHeight
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
}
