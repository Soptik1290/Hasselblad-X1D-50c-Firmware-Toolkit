import QtQuick 2.0

Item {
    id: root
    property color color: "black"
    objectName: "ConfirmationButtons"
//    opacity: 1.0

    property bool transparentBackground: false
    // bottomTextCenterMarginBase and sideOffset are used to calculate button positions to keep text inside screen
    property int bottomTextCenterMarginBase: guiconfig.isCFV || prodinfo.isNewH6DisplayQml() ? constants.bottomTextCenterMarginCFV : constants.bottomTextCenterMargin
    property int sideOffset: {
        var rightmostPos = width / 2 + bottomTextCenterMarginBase + lastButton.labelWidth / 2 + 1
        var leftmostPos = width / 2 + bottomTextCenterMarginBase + firstButton.labelWidth / 2 + 1
        var largestSidePos = Math.max(rightmostPos, leftmostPos)
        return largestSidePos > root.width ? largestSidePos - root.width : 0
    }
    property int bottomTextCenterMargin: bottomTextCenterMarginBase - sideOffset
    property int sideTextCenterMarginFirst: constants.sideTextCenterMarginFirst
    property int sideTextCenterMarginMiddle: constants.sideTextCenterMarginMiddle
    property int sideTextCenterMarginLast: constants.sideTextCenterMarginLast

    property alias firstText: firstButton.labelText
    property alias firstImage: firstButton.imageSource
    property alias firstTextBold: firstButton.bold
    property alias lastText: lastButton.labelText
    property alias lastImage: lastButton.imageSource
    property alias lastTextBold: lastButton.bold
    property alias middleText: middleButton.labelText
    property alias middleImage: middleButton.imageSource
    property alias middleTextBold: middleButton.bold

    // This was supposed to be an alias, but PropertiesChanged did not properly reset when leaving state so we turned the binding upside down.
    property bool firstAvailable: (firstButton.labelText != "")
    property bool middleAvailable: (middleButton.labelText != "")
    property bool lastAvailable: (lastButton.labelText != "")
    property bool sideOriented: false

    ConfirmationButton {
        id: firstButton
        objectName: "firstButton"
        color: transparentBackground ? "transparent" : root.color
        labelText: qsTr("Exit")
        sideOriented: parent.sideOriented
        visible: parent.firstAvailable
    }

    ConfirmationButton {
        id: middleButton
        objectName: "middleButton"
        color: transparentBackground ? "transparent" : root.color
        labelText: ""
        sideOriented: parent.sideOriented
        visible: parent.middleAvailable
        moveLabelUp: {
            var firstButtonLabelx = root.mapFromItem(firstButton, firstButton.labelX, 0).x
            var midButtonLabelx = root.mapFromItem(middleButton, labelX, 0).x
            var lastButtonLabelx = root.mapFromItem(lastButton, lastButton.labelX, 0).x
            return (((midButtonLabelx - firstButtonLabelx - firstButton.labelWidth) < constants.buttonTextMinDistance) && firstButton.visible) ||
                     (((lastButtonLabelx - midButtonLabelx - labelWidth) < constants.buttonTextMinDistance) && lastButton.visible)
        }
    }

    ConfirmationButton {
        id: lastButton
        objectName: "lastButton"
        color: transparentBackground ? "transparent" : root.color
        labelText: ""
        sideOriented: parent.sideOriented
        visible: parent.lastAvailable
    }

    states: [
        State {
            when: !sideOriented
            name: "bottomOriented"
            PropertyChanges {
                target: root
                height: constants.dialogButtonBackgroundHeight
                width: parent.width
                anchors.bottom: parent.bottom
            }
            PropertyChanges {
                target: firstButton
            }
            PropertyChanges {
                target: middleButton
                centerOffset: 0
            }
            PropertyChanges {
                target: lastButton
                centerOffset: bottomTextCenterMargin
            }
        },

        State {
            when: sideOriented
            name: "sideOriented"
            PropertyChanges {
                target: root
                height: parent.height
                width: 140 //constants.dialogButtonBackgroundHeight
                anchors.right: parent.right
            }
            PropertyChanges {
                target: firstButton
                centerOffset: sideTextCenterMarginLast
            }
            PropertyChanges {
                target: middleButton
                centerOffset: sideTextCenterMarginMiddle
            }
            PropertyChanges {
                target: lastButton
                //                centerOffset: sideTextCenterMarginFirst
            }
        }
    ] // states
} // root Rectangle
