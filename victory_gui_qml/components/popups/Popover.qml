import QtQuick 2.0

import com.hasselblad.guiconfig 1.0
import com.hasselblad.bodysync 1.0

import "qrc:///scripts/Keys.js" as MKeys

MouseArea {
    id: popupContainer
    objectName: "popupContainer"

    property alias heading: popoverHeading.text
    property alias headingSize: popoverHeading.font.pixelSize
    property alias content: childContent.children
    property int headingTopMargin: 29
    property int contentWidth: 502
    property int contentHeight: 382 - 21
    property bool updateBodySyncState: true
    property Item contentItem

    // Override this function if initialization needed
    function openProcessing() {
    }

    function close() {
        state = "finish"
        // Now the state changes...
    }

    function popupHeight() {
        return popoverHeading.height + contentHeight;
    }
    function popupWidth() {
        return contentWidth;
    }

    Keys.onPressed: {
        if(MKeys.pressedFnAcc("NAVLEFT", event))
        {
            contentItem.moveCurrentIndexLeft()
        }
        else if(MKeys.pressedFnAcc("POPACCEPT", event))
        {
            contentItem.setSelected()
        }
        else if(MKeys.pressedFnAcc("NAVRIGHT", event))
        {
            contentItem.moveCurrentIndexRight()
        }
        else if(MKeys.pressedFnAcc("ESCAPE", event) || MKeys.pressedFnAcc("MENU", event) ||  MKeys.pressedFnAcc("BROWSE", event))
        {
            popupContainer.state = "finish"
        }
        else if(MKeys.pressedFnAcc("UP", event))
        {
            if(guiconfig.isWedge)
            {
                contentItem.moveCurrentIndexLeft()
            }
            else
            {
                contentItem.moveCurrentIndexUp()
            }
        }
        else if(MKeys.pressedFnAcc("DOWN", event))
        {
            if(guiconfig.isWedge)
            {
                contentItem.moveCurrentIndexRight()
            }
            else
            {
                contentItem.moveCurrentIndexDown()
            }
        }
        else if(MKeys.pressedFnAcc("AF_MF", event))
        {
            // Prevent key from being processed further down the line
        }
        else
        {
            event.accepted = false
        }
    }


    anchors.fill: parent
    z: 100

    onClicked: popupContainer.state = "finish"

    Rectangle {
        // opacity is inherited to all children, so we avoid it on the popupContainer-parent by creating this rectangle instead.
        id: fadeOutParentRect
        color: constants.popupFadeoutColor
        anchors.fill: parent
        opacity: 0
    }

    Rectangle {
        id: popup
        color: constants.popupBackgroundColor
        radius: constants.outerBoxRadius
        border.width: constants.popupBorderWidth
        border.color: constants.popupBorderColor

        height: popupHeight()
        width: popupWidth()

        Item {
            id: popoverHeadingContainer
            width: popoverHeading.width
            height: popoverHeading.height * 1.2

            Text {
                id: popoverHeading
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: constants.popupHeaderTextSize
                color: constants.popupTextColor

                anchors.centerIn: parent
                font.capitalization: Font.AllUppercase
            }

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: popupContainer.headingTopMargin
        }

        Item {
            id: childContent
            anchors.top: popoverHeadingContainer.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }

        anchors.centerIn: parent

        MouseArea {
            // This mouse-area is to prevent closing the dialog when clicking on it. We only want close outside the popup.
            anchors.fill: parent
            z: -1

            onClicked: { }
        }

    }

    onStateChanged: console.log("popup state", state)
    states: [
        State {
            name: "finish"
            PropertyChanges { target: popupContainer; opacity: 0 }
            PropertyChanges { target: popupContainer; visible: false }
            StateChangeScript {
                script: {
                    popupContainer.focus = false
                    if (updateBodySyncState) {
                        // It worked very bad to set BodySync.currentState in PropertyChanges, so we set it in this script instead
                        BodySync.currentState = BodySync.MAIN
                    }
                }
            }
        },
        State {
            name: "active"
            PropertyChanges { target: fadeOutParentRect; opacity: constants.fadeOutOpacity }
            PropertyChanges { target: popupContainer; visible: true }
            StateChangeScript {
                script: {
                    openProcessing()
                    if (updateBodySyncState) {
                        // It worked very bad to set BodySync.currentState in PropertyChanges, so we set it in this script instead
                        BodySync.currentState = BodySync.MENU
                    }
                }
            }
        }
    ]
    Component.onCompleted: state = "active"
    transitions: [
        Transition {
            PropertyAnimation {
                properties: "opacity"
                easing.type: Easing.OutCubic
                duration: constants.fadeOutDuration
            }
        }
    ]
}
