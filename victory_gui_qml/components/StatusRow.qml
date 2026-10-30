import QtQuick 2.0
import com.hasselblad.cambody 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0

Item {
    anchors {
        top: parent.top
        topMargin: 4
        left: parent.left
        leftMargin: 4
        right: parent.right
        rightMargin: 10
    }
    height: childrenRect.height
    visible: VideoControl.videoMode === VideoControl.Off
    property bool hideStatusIcons: false
    property bool hideTopBatteryIcon: false

    BatteryIndicatorScaled {
        showOnWarningOnly: true
        batteryWidth: 19
        height: 45
        canShowBattery: !hideTopBatteryIcon
        anchors {
            top: parent.top
            right: parent.right
        }
    }

    Row {
        id: frame
        anchors {
            left: parent.left
            top: parent.top
        }
        visible: !hideStatusIcons
        spacing: 4

        Image {
            id: icon
            readonly property bool showVideoMode: System.camera_mode === System.CameraModeVideo
            visible: (configstore.selfTimerActive || configstore.intervalActive || configstore.bracketingActive || configstore.focusBracketingActive || showVideoMode)
//            anchors.left: parent.left
            anchors.top: parent.top
            source: showVideoMode ? "qrc:///icons/statusRowVideoMode.png"
                                : configstore.selfTimerActive ? "qrc:///icons/statusRowSelfTimer.png"
                                : configstore.intervalActive ? "qrc:///icons/statusRowInterval.png"
                                : configstore.bracketingActive ? "qrc:///icons/statusRowBracketing.png"
                                : configstore.focusBracketingActive ? "qrc:///icons/statusRowFocusBracketing.png"
                                : ""
        }

        Image {
            id: wifiIcon
            anchors {
//                left: icon.right
                top: parent.top
//                leftMargin: 4
            }
            visible: configstore.WIFI_power
            source: "qrc:///icons/statusRowWiFi.png"
        }

        FlashStatus {
            id: flashStatus
            source: "qrc:///icons/statusRowFlashStatus.png"
            anchors {
//                left: wifiIcon.right
                top: parent.top
//                leftMargin: 4
            }
        }
        GPSStatus {
            id: gpsImage
            iconSource: "qrc:///icons/statusRowGPS.png"
//            anchors.left: flashStatus.right
            anchors.verticalCenter: flashStatus.verticalCenter
        }


    }
} // Item
