import QtQuick 2.0
import com.hasselblad.suc 1.0

Item{
    id: root
    visible: false
    property bool allowVisible: true
    property alias sizeFactor: flashImage.scale
    property alias source: flashImage.source
    width: childrenRect.width
    height: childrenRect.height
    Image {
        id: flashImage
        source: "qrc:///icons/FlashStatus.png"
        scale: 1
        visible: true

        Timer {
            id: flash_timer
            running: false
            repeat: true
            interval: 750
            triggeredOnStart: false
            onTriggered: flashImage.visible = !flashImage.visible
        }

        states: [
            State {
                name: "visible"
                when: guiconfig.isWedge && root.allowVisible && (Suc.FsReady === suc.flash_status || Suc.FsReadyIttl === suc.flash_status)
                PropertyChanges { target: root; visible: true }
                PropertyChanges { target: flashImage; visible: true }
            },
            State {
                name: "flashing"
                when: guiconfig.isWedge && root.allowVisible && (Suc.FsCharging === suc.flash_status || Suc.FsChargingIttl === suc.flash_status)
                PropertyChanges { target: root; visible: true }
                PropertyChanges { target: flashImage; visible: true }
                PropertyChanges { target: flash_timer; running: true }
            }
        ]
    }
}
