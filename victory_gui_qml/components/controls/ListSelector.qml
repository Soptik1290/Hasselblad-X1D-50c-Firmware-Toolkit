import QtQuick 2.0
import com.hasselblad.bodysync 1.0
import "qrc:///scripts/Keys.js" as MKeys
MouseArea {
    id: popupContainer
    property alias popupAnchor: popup.anchors
    property alias content: childContent.children
    property int contentWidth: 540
    property int contentHeight: 340
    property Item returnToItem
    property bool isToLeft: true
    property Item contentItem
    property bool setValueWhenOutsideClick: true
    property bool preventAFMFPropagation: true
    property bool preventPLAYPropagation: true
    property int finalBodyState: BodySync.MAIN
    Keys.onPressed: {
        event.accepted = true
        if(MKeys.pressedFn("LISTUP", event.key))
        {
            contentItem.decrementCurrentIndex()
        }
        else if(MKeys.pressedFn("ESCAPE", event.key) || MKeys.pressedFnAcc("MENU", event) || (preventPLAYPropagation && MKeys.pressedFnAcc("PLAY", event)))
        {
            close()
        }
        else if(MKeys.pressedFn("POPACCEPT", event.key))
        {
            contentItem.setSelectedClose()
        }
        else if(MKeys.pressedFn("LISTDOWN", event.key))
        {
            contentItem.incrementCurrentIndex()
        }
        else if(preventAFMFPropagation && MKeys.pressedFnAcc("AF_MF", event))
        {
        }
        else
            event.accepted = false
    }
    function open(returnItem) {
        if(typeof returnItem !== 'undefined')
        {
            popupContainer.returnToItem = returnItem;
        }
        if (popupContainer.visible)
            return;
        popupContainer.visible = true;
        BodySync.currentState = BodySync.MENU;
    }
    function close() {
        state = "finish"
    }
    function postClose()
    {
    }
    function popupHeight() {
        return contentHeight;
    }
    function popupWidth() {
        return contentWidth;
    }
    anchors.fill: parent
    z: 100
    onClicked: {
        if(setValueWhenOutsideClick)
        {
            setSelected();
        }
        close()
    }
    Rectangle {
        id: fadeOutParentRect
        color: constants.popupFadeoutColor
        anchors.fill: parent
        opacity: 0
    }
    Rectangle {
        id: popup
        color: "transparent"
        anchors {
            left: popupContainer.left
            right: popupContainer.right
            top: popupContainer.top
            bottom: popupContainer.bottom
            leftMargin: popupContainer.isToLeft ? 30 : 0
            rightMargin: popupContainer.isToLeft ? 0 : 30
        }
        Rectangle {
            id: childContent
            color: constants.popupBackgroundColor
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: 30
                bottomMargin: 30
            }
            radius: constants.outerBoxRadius
        }
        Rectangle{
            color: "transparent"
            anchors.fill: childContent
            radius: constants.outerBoxRadius
            border.width: 2
            border.color: constants.popupBorderColor
        }
        MouseArea {
            anchors.fill: childContent
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
                    postClose()
                    BodySync.currentState = finalBodyState
                }
            }
        },
        State {
            name: "active"
            PropertyChanges { target: fadeOutParentRect; opacity: constants.fadeOutOpacity }
            PropertyChanges { target: popupContainer; visible: true }
            StateChangeScript {
                script: {
                    BodySync.currentState = BodySync.MENU
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
