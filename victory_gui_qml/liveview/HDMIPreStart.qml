import QtQuick 2.0
import com.hasselblad.config 1.0
import com.hasselblad.lens 1.0
Rectangle {
    id: root
    color: "black"
    property real sizeFactor: Math.min(width / 1024.0, height / 728.0)
    Text {
        id: subTextItem
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: constants.hdmiStartLiveViewTextSize * root.sizeFactor
        text: guiconfig.emptyString + ((configstore.ExpMode === Config.ExpMode_ManualQuick) ? qsTr("No Live View in MQ mode") :
              (!configstore.eshutter && Lens.lens_family === Lens.NoLens) ? qsTr("No lens detected") + guiconfig.emptyString :
                                                                                              qsTr("Start Live View"))
    }
}
