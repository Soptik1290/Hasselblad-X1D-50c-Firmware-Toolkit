import QtQuick 2.0
import "qrc:///liveview"
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    color: "black"
    Keys.onPressed: {
        if (MKeys.pressedFnAcc("CROSS", event) || MKeys.pressedFnAcc("SQUARE", event) || MKeys.pressedFnAcc("STAR", event))
        {
            event.accepted = true
        }
        else if (MKeys.pressedFnAcc("INTERVAL", event) || MKeys.pressedFnAcc("BRACKETING", event)) {
            event.accepted = true
        }
    }
    SpiritLevel {
        id: spiritLevel
        anchors.fill: parent
        allowSquare: true
        allowCross: true
    }
    Rectangle {
        id: viewEndLine
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: constants.viewEndLineWidth
    }
    Component.onCompleted: spiritLevel.setSpiritLevel()
}
