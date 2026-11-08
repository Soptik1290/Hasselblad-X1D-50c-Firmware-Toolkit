import QtQuick 2.0
import com.hasselblad.video 1.0
Text {
    id: recordingTime
    text: VideoControl.videoMode === VideoControl.Record ? (((VideoControl.position / 60) < 10 ? "0" : "") + Math.floor((VideoControl.position / 60)) + ":" +
          ((VideoControl.position % 60) < 10 ? "0" : "") + Math.round((VideoControl.position % 60))) : "00:00"
    font.pixelSize: 64 * sizeFactor
    color: "white"
    font.family: constants.cameraControlTextFontName
    style: Text.Outline
    styleColor: "black"
}
