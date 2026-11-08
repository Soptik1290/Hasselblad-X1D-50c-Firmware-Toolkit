import QtQuick 2.0

import com.hasselblad.config 1.0
import com.hasselblad.spiritlevel 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.bodysync 1.0

import "qrc:///scripts/Keys.js" as MKeys

Item {
    id: root
    property alias popupOpen: spiritModePopup.visible
    property real sizeFactor: 640 / 1024
    focus: visible
    property real xDegrees: SpiritLevel.horizontalLevel
    property real yDegrees: -SpiritLevel.verticalLevel
    property int orientation: SpiritLevel.cameraOrientation
    property bool keepEnabled: true // specifies whether spiritlevel should be kept alive even if it times out.
    property bool highlight: false
    property bool allowSquare: false
    property bool allowCross: false
    property bool compactMode: false //When displaying spiritlevel together with other info
    property Item previouslyActiveItem: null
    property bool userLevelEnabled: BodySync.currentDialMode !== BodySync.DmFullauto &&
                                    !(BodySync.hdmiCableConnected && VideoControl.videoMode !== VideoControl.Off)
    property int bottomY: spiritModeBracketLeft.y + spiritModeBracketLeft.height

    onUserLevelEnabledChanged: {
        highlight = false
        spiritModePopup.close()
    }

    function openSpiritPopup()
    {
        highlightTimer.stop()
        highlight = false
        VideoControl.restartLiveViewImageTimeout()
        spiritModePopup.open(root)
    }

    Timer {
        id: highlightTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: {
            highlight = false
        }
    }

    Keys.onPressed: {
        //Let all keypresses through if we aren't allowed to modify spirit level
        if (!userLevelEnabled) {
            event.accepted = false
            return
        }
        if(allowCross && MKeys.pressedFnAcc("CROSS", event) || (allowSquare && MKeys.pressedFnAcc("SQUARE", event)))
        {
            highlight = !highlight
            if(highlight)
            {
                highlightTimer.restart()
            }
            else
            {
                highlightTimer.stop()
            }
        }
        else if(highlight && MKeys.pressedFnAcc("STAR", event))
        {
            // Open popup
            openSpiritPopup()
        }
        else
        {
            event.accepted = false
        }
    }

    // Dummy mouse area. Without it, sweep away does not work properly. QML Magic...
    MouseArea {
        propagateComposedEvents: true
        anchors.fill: parent
    }

    Rectangle {
        enabled: userLevelEnabled
        anchors.fill: spiritMode
        color: (spiritModeMouseArea.pressed || root.highlight) ? constants.hblOrange : "transparent"
        MouseArea{
            id: spiritModeMouseArea
            anchors.fill: parent
            onClicked: openSpiritPopup()
        }
    }

    Image {
        id: spiritMode
        anchors.left: parent.left
        anchors.leftMargin: 18 * sizeFactor
        anchors.top: parent.top
        anchors.topMargin: 11 * sizeFactor
        source: SpiritLevel.usingUserLevel ? "qrc:///icons/SpiritUserMode.png" : "qrc:///icons/SpiritNormalMode.png"
    }

    Image {
        id: spiritModeBracketLeft
        visible: userLevelEnabled
        anchors.left: spiritMode.left
        anchors.top: spiritMode.top
        source: "qrc:///icons/SpiritModeBracketLeft.png"
    }

    Image {
        id: spiritModeBracketRight
        visible: userLevelEnabled
        anchors.right: spiritMode.right
        anchors.top: spiritMode.top
        source: "qrc:///icons/SpiritModeBracketRight.png"
    }

    SpiritBar {
        id: yAxis
        anchors.right: parent.right
        anchors.rightMargin: 32 * sizeFactor
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: compactMode ? 40 * sizeFactor : 0
        width: constants.spiritBarWidth * sizeFactor
        height: Math.round((compactMode ? 0.55 : 0.75)*root.height)
        degrees: yDegrees
        sizeFactor: root.sizeFactor

        Behavior on degrees {
            NumberAnimation {
                duration: 100
                easing.type: Easing.Linear
            }
        }
    }

    SpiritBar {
        id: xAxis
        rotation: 90
        height: yAxis.height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.bottom
        anchors.verticalCenterOffset: (-81.6 + (compactMode ? -90 : 0)) * sizeFactor
        width: yAxis.width
        degrees: xDegrees
        sizeFactor: root.sizeFactor

        Behavior on degrees {
            NumberAnimation {
                duration: 100
                easing.type: Easing.Linear
            }
        }
    }

    SpiritModePopup {
        objectName: "SpiritLevel_spiritModePopup"
        id: spiritModePopup
        visible: false
        anchors.fill: parent
        sizeFactor: root.sizeFactor
    }

    // States for orientation
    states: [
        State {
            name: "LandscapeVFDownwards"
            when: SpiritLevel.cameraOrientation === SpiritLevel.PosLandscapeVFDownwards
            PropertyChanges { target: root; xDegrees: SpiritLevel.horizontalLevel; yDegrees: -SpiritLevel.verticalLevel }
        },
        State {
            name: "LandscapeVFUpwards"
            when: SpiritLevel.cameraOrientation === SpiritLevel.PosLandscapeVFUpwards
            PropertyChanges { target: root; xDegrees: SpiritLevel.horizontalLevel; yDegrees: -SpiritLevel.verticalLevel }
        },
        State {
            name: "PortraitGripDownwards"
            when: SpiritLevel.cameraOrientation === SpiritLevel.PosPortraitGripDownwards
            PropertyChanges { target: root; xDegrees: SpiritLevel.horizontalLevel; yDegrees: SpiritLevel.verticalLevel }
        },
        State {
            name: "PortraitGripUpwards"
            when: SpiritLevel.cameraOrientation === SpiritLevel.PosPortraitGripUpwards
            PropertyChanges { target: root; xDegrees: SpiritLevel.horizontalLevel; yDegrees: -SpiritLevel.verticalLevel }
        },
        State {
            name: "PortraitLensDownwards"
            when: SpiritLevel.cameraOrientation === SpiritLevel.PosPortraitLensDownwards
            PropertyChanges { target: root; xDegrees: SpiritLevel.horizontalLevel; yDegrees: -SpiritLevel.verticalLevel }
        },
        State {
            name: "PortraitLensUpwards"
            when: SpiritLevel.cameraOrientation === SpiritLevel.PosPortraitLensUpwards
            PropertyChanges { target: root; xDegrees: SpiritLevel.horizontalLevel; yDegrees: -SpiritLevel.verticalLevel }
        },
        State {
            name: ""
            PropertyChanges { target: root; xDegrees: SpiritLevel.horizontalLevel; yDegrees: -SpiritLevel.verticalLevel }
        }
    ]


    Connections {
        target: SpiritLevel
        onRunningChanged: {
            if(!SpiritLevel.running
            && visible && keepEnabled
            && (System.system_state === System.StateUp))
                SpiritLevel.enabled(visible)
        }
    }

    Connections {
        target: System
        onSystem_stateChanged: if(System.system_state === System.StateUp) SpiritLevel.enabled(visible)
    }

    Binding {
        target: SpiritLevel
        property: "usingUserLevel"
        value: configstore.Spiritlevel_UserCalibration
    }

    function setSpiritLevel()
    {
        SpiritLevel.enabled(visible)
    }

    onVisibleChanged: {
        setSpiritLevel()

        if(visible)
        {
            forceActiveFocus()
        }
        else
        {
            // If we leave spirit level, highlight should be no more
            highlightTimer.stop()
            highlight = false
        }
    }

    Component.onCompleted: {
        if(typeof hideStatusIcons !== "undefined")
        {
            hideStatusIcons = true
        }
    }
    Component.onDestruction: {
        if(typeof hideStatusIcons !== "undefined")
        {
            hideStatusIcons = false
        }
    }
}
