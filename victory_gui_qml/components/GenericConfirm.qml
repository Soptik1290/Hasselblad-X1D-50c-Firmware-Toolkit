import QtQuick 2.0
import "qrc:///scripts/Keys.js" as MKeys

Item {
    objectName: "GenericConfirm_root"
    id: root
    focus: true
    property bool largeHeaderText: false
    property bool largeInfoText: true
    property bool sideOriented: guiconfig.isWedge
    property alias headerText: header.text
    property alias infoText: info.text
    property int infoMarginSide: 0
    property int bgHeaderTopMargin: 128
    property alias leftText: buttons.firstText
    property alias middleText: buttons.middleText
    property alias rightText: buttons.lastText
    property alias transparentBackground: buttons.transparentBackground


    property alias leftAvailable: buttons.firstAvailable
    property alias middleAvailable: buttons.middleAvailable
    property alias rightAvailable: buttons.lastAvailable

    // Client code should listen to these signals using Connections {}. If this Dialog is in a
    // loader, the Connections:target can be specified using the loaderId.item property.
    signal leftSelected()
    signal middleSelected()
    signal rightSelected()

    Keys.onPressed: {
        if (leftAvailable && MKeys.pressedFnAcc("ABORT", event)) {
            leftSelected()
            if (parent.active) {
                parent.active = false
            }
        } else if (middleAvailable && MKeys.pressedFnAcc("STAR", event)) {
            middleSelected()
            if (parent.active) {
                parent.active = false
            }
        } else if (rightAvailable && MKeys.pressedFnAcc("DLGACCEPT", event)) {
            rightSelected()
            if (parent.active) {
                parent.active = false
            }
        } else if(MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("EXPOSURE", event.key) || MKeys.pressedFn("TOGGLESLEEP", event.key)) {
            // Just let through these.
        }
        else
            event.accepted = true // block everything else.
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {}
        z: 200
    }

    Rectangle {
        id: bg
        color: "black"
        anchors.fill: parent
    }

    Rectangle {
        id: bgHeader
        height: constants.dialogButtonBackgroundHeight
        width: bg.width
        anchors.top: bg.top
        anchors.topMargin: largeHeaderText ? bgHeaderTopMargin : 0
        color: bg.color
        opacity: 1.0

        Text {
            id: header
            text: "<header>" + guiconfig.emptyString
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: constants.dialogButtonVerticalOffset
                left: parent.left
                right: parent.right
                leftMargin: 10
                rightMargin: 10
            }
            color: constants.dialogHeaderColor
            font.pixelSize: largeHeaderText ? 60 : 20
            fontSizeMode: Text.HorizontalFit
            horizontalAlignment: Text.AlignHCenter
            //font.capitalization: Font.AllUppercase
        }
    }

    Image {
        id: imgExclamationMark
        source: "qrc:///icons/exclamationMark.png"
        anchors {
            horizontalCenter: bg.horizontalCenter
        }
    }

    Text {
        id: info
        text: ""
        color: "white"
        font.pixelSize: largeInfoText ? 60 : 40
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        fontSizeMode: Text.Fit
        width: parent.width * .8
        anchors {
            top: bgHeader.bottom
            horizontalCenter: parent.horizontalCenter
        }
    }

    ConfirmationButtons {
        id: buttons
        color: bg.color
        sideOriented: parent.sideOriented
        middleAvailable: false
    }

    states: [
        State {
            when: sideOriented
            PropertyChanges { target: imgExclamationMark; anchors { top: bg.top; topMargin: 98 } }
            PropertyChanges { target: bgHeader; anchors { topMargin: largeHeaderText ? 196 : 110; } }
            PropertyChanges { target: info; anchors { top: bgHeader.bottom; topMargin: infoMarginSide } }
        },
        State {
            when: !sideOriented
            PropertyChanges { target: imgExclamationMark; anchors { top: bgHeader.bottom; topMargin: 10 } }
            PropertyChanges { target: info; anchors { top: imgExclamationMark.bottom; topMargin: 20 } }
        }
    ]
} // root Item
