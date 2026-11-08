import QtQuick 2.0
import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys
Item {
    id: root
    z: 100
    anchors.fill: parent
    property alias timeVisible: fadeWaitTimer.interval
    property alias title: titleText.text
    property alias info: infoText.text
    property alias buttonText: acceptButton.text
    property bool closeDialog: false
    property int headingTopMargin: 29
    onVisibleChanged: if(visible && 0 != fadeWaitTimer.interval)
                          fadeWaitTimer.start()
    function close()
    {
        fadeWaitTimer.stop();
        root.closeDialog = true
    }
    Rectangle {
        id: bg
        color: "black"
        opacity: 0.5
        anchors.fill: parent
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {}
        onDoubleClicked: {}
    }
    Keys.onPressed: {
        if (MKeys.pressedFnAcc("ESCAPE", event) || MKeys.pressedFnAcc("ENTER", event)) {
            acceptButton.buttonPressed = true
            close()
        }
        else if(MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("EXPOSURE", event.key) || MKeys.pressedFn("TOGGLESLEEP", event.key)) {
        }
        else
            event.accepted = true
    }
    Keys.onReleased: acceptButton.buttonPressed = false
    Rectangle {
        color: "black"
        anchors.centerIn: parent
        width: parent.width * .8
        height: parent.height * .8
        visible: true
        border {
            color: constants.popupBorderColor
            width: constants.popupBorderWidth
        }
        Text {
            id: titleText
            text: ""
            visible: text != ""
            color: constants.dialogHeaderColor
            font.pixelSize: constants.popupHeaderTextSize
            font.capitalization: Font.AllUppercase
            fontSizeMode: Text.HorizontalFit
            horizontalAlignment: Text.AlignHCenter
            width: parent.width * .8
            anchors {
                top: parent.top
                topMargin: root.headingTopMargin
                left: parent.left
                leftMargin: 10
                right: parent.right
                rightMargin: 10
            }
        }
        Text {
            id: infoText
            text: ""
            visible: text != ""
            color: "white"
            font.pixelSize: 40
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
            width: parent.width * .8
            height: (parent.height - titleText.height - (acceptButton.visible ? acceptButton.height : 0) - titleText.anchors.topMargin) * .8
            anchors {
                left: parent.left
                leftMargin: 10
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
        }
        MenuButton {
            id: acceptButton
            visible: text != ""
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 10
            }
            text: ""
            onClicked: close()
        }
        Timer {
            id: fadeWaitTimer
            repeat: false
            interval: 0
            onTriggered: root.closeDialog = true
        }
        state: "closed"
        states: [
            State {
                name: "closed"
                when: !root.visible
                PropertyChanges { target: root; opacity: 0 }
            },
            State {
                name: "visible"
                when: root.visible && !root.closeDialog
                PropertyChanges { target: root; opacity: 1 }
            },
            State {
                name: "closing"
                when: root.visible && root.closeDialog
                PropertyChanges { target: root; opacity: 0 }
            }
        ]
        transitions: [
            Transition {
                from: "closed"
                to: "visible"
                PropertyAnimation {
                    properties: "opacity"
                    duration: 250
                    easing.type: Easing.Linear
                }
            },
            Transition {
                from: "visible"
                to: "closing"
                PropertyAnimation {
                    properties: "opacity"
                    duration: 500
                    easing.type: Easing.Linear
                }
                onRunningChanged: if(!running) { root.visible = false; root.closeDialog = false }
            }
        ]
    }
}
