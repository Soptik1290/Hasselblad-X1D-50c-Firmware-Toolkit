import QtQuick 2.5
import com.hasselblad.video 1.0
Item {
    id: root
    width: recordingIcon.width
    height: recordingIcon.height
    Image {
        id: recordingIcon
        visible: root.visible && !stopIcon.visible
        source: "qrc:///icons/RecordingStart.png"
        anchors.centerIn: parent
        MouseArea {
            enabled: parent.visible
            anchors {
                left: parent.left
                leftMargin: -root.anchors.leftMargin
                bottom: parent.bottom
                bottomMargin: -root.anchors.bottomMargin
            }
            width: parent.width * 2
            height: parent.height * 2
            onClicked: VideoControl.setVideoRecordState(true)
        }
    }
    Image {
        id: stopIcon
        visible: root.visible && VideoControl.videoMode === VideoControl.Record
        source: "qrc:///icons/RecordingStop.png"
        anchors.centerIn: recordingIcon
        MouseArea {
            enabled: parent.visible
            anchors {
                left: parent.left
                leftMargin: -root.anchors.leftMargin
                bottom: parent.bottom
                bottomMargin: -root.anchors.bottomMargin
            }
            width: parent.width * 2
            height: parent.height * 2
            onClicked: VideoControl.setVideoRecordState(false)
        }
    }
}
