import QtQuick 2.0
import com.hasselblad.demostate 1.0
Item {
    z: 1000
    anchors.fill: parent
    property bool showMarker: false
    visible: showMarker && DemoState.demoOn
    Rectangle{
        anchors.fill: parent
        color: "red"
        z: 2000
        opacity: 0.3
    }
}
