import QtQuick 2.0
import com.hasselblad.video 1.0
Rectangle {
    id: recording
    visible: VideoControl.videoMode === VideoControl.Record
    height: 46 * sizeFactor
    width: height
    radius: height / 2
    color: constants.videoRecordingColor
    Timer {
        interval: 500
        running: parent.visible
        repeat: true
        onTriggered: {
            parent.opacity = 1 - parent.opacity
            label.opacity = 1 - label.opacity
        }
    }
    Text {
        id: label
        anchors {
            left: parent.left
            leftMargin: 75 * sizeFactor
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: (height - baselineOffset) / 2
        }
        text: "REC"
        color: "white"
        font.pixelSize: 64 * sizeFactor
        font.family: constants.cameraControlTextFontName
        style: Text.Outline
        styleColor: "black"
    }
}
