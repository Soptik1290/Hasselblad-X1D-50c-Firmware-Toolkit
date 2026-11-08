import QtQuick 2.0

import com.hasselblad.gps 1.0
import com.hasselblad.metadata 1.0

Item {
    id: root
    visible: false
    property string iconSource
    property bool allowVisible: true
    property alias sizeFactor: gpsImage.scale
    width: childrenRect.width
    height: childrenRect.height

    Image {
        id: gpsImage


        source: iconSource
        scale: 1

        Timer {
            id: gps_timer
            running: false
            repeat: true
            interval: 750
            triggeredOnStart: false
            onTriggered: gpsImage.visible = !gpsImage.visible
        }

        states: [
            State {
                name: "visible"
                when: (guiconfig.isWedge && root.allowVisible && (GPS.gpsStatus === GPS.GPSStatusPositionValid)) ||
                      (guiconfig.isA6D && root.allowVisible && Metadata.gpsFixValid)
                PropertyChanges { target: root; visible: true }
                PropertyChanges { target: gpsImage; visible: true }
            },
            State {
                name: "flashing"
                when: (guiconfig.isWedge && root.allowVisible && (GPS.gpsStatus === GPS.GPSStatusNoPosition)) ||
                      (guiconfig.isA6D && root.allowVisible && ((GPS.gpsStatus === GPS.GPSStatusNoPosition) && !Metadata.gpsFixValid))
                PropertyChanges { target: root; visible: true }
                PropertyChanges { target: gpsImage; visible: true }
                PropertyChanges { target: gps_timer; running: true }
            }
        ]
    }
}

