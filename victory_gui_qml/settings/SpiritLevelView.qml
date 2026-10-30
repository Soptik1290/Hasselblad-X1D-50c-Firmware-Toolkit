import QtQuick 2.0

import "qrc:///liveview"

import "qrc:///scripts/Keys.js" as MKeys

Rectangle {
    color: "black"

    Keys.onPressed: {
        if (MKeys.pressedFnAcc("CROSS", event) || MKeys.pressedFnAcc("SQUARE", event) || MKeys.pressedFnAcc("STAR", event))
        {
            //Block keys cross, square and star to not trigger other stuff (in menues etc)
            event.accepted = true
        }
        else if (MKeys.pressedFnAcc("INTERVAL", event) || MKeys.pressedFnAcc("BRACKETING", event)) {
            event.accepted = true //Prevent toggle interval/bracketing in this view
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

