import "qrc:///scripts/Keys.js" as MKeys
import QtQuick 2.0
import com.hasselblad.settings 1.0

MouseArea {
    id: popupContainer

    property alias popupAnchor: popup.anchors
    property int contentWidth: 540
    property int contentHeight: 340
    // This is the item that shall have focus when popup is closed
    property Item returnToItem: null
    property alias popupY: popup.y
    enabled: false
    visible: false

    // returnItem is the calling item that shall receive focus when closed
    function open(returnItem) {
        returnToItem = returnItem;

        list.forceActiveFocus();

        visible = true
    }

    function close() {
        visible = false
    }

    function popupHeight() {
        return contentHeight;
    }
    function popupWidth() {
        return contentWidth;
    }

    function fillModel()
    {
        if(listModel.count === 0)
        {
            var manualTemp = configstore.WBManualTemp
            var step = 100;
            var whiteBalanceMin = 2000;
            var whiteBalanceMax = 10000;
            // Add values
            for (var whiteBalance = whiteBalanceMin; whiteBalance <= whiteBalanceMax; whiteBalance += step)
            {
                listModel.append({"modelData": whiteBalance});
                //If the manual value was set by White Balance Tool it will not follow even step size
                if (manualTemp > whiteBalance && manualTemp < whiteBalance+step) {
                    listModel.append({"modelData": manualTemp});
                }
            }
        }
    }

    function findCurrentIndex()
    {
        var manualTemp = configstore.WBManualTemp
        for (var currentIndex = 0; currentIndex < listModel.count; currentIndex ++)
        {
            var currentTemp = list.model.get(currentIndex).modelData
            if(currentTemp === manualTemp)
            {
                return currentIndex
            }
        }
        return 0
    }

    // Called when the user clicked in the list, not necessarily on the selected item,
    // then the clicked item will be set
    function itemSelected(dataValue)
    {
        //When leaving white balance tool we should round manual WB and clear tint
        if (configstore.WBManualTemp !== dataValue && configstore.WBManualTemp % 100 !== 0) {
            configstore.WBManualTint = 0
            listModel.clear()
        }
        configstore.WBManualTemp = dataValue
        close();
    }

    // Called from parent to set selected value when the user clicked outside of the list,
    // then the selected (highlighted) item will be set
    function setSelected()
    {
        configstore.WBManualTemp = list.model.get(list.currentIndex).modelData
    }

//    Keys.onPressed: {
//        event.accepted = true
//        if(MKeys.pressedFn("POPACCEPT", event.key))
//        {
//            setSelected()
//            close()
//        }
//        else
//        {
//            event.accepted = false
//        }
//    }

    z: 100

    onClicked: {
        setSelected();
        close()
    }

    Rectangle {
        // opacity is inherited to all children, so we avoid it on the popupContainer-parent by creating this rectangle instead.
        id: fadeOutParentRect
        color: constants.popupFadeoutColor
        anchors.fill: parent
        opacity: constants.fadeOutOpacity
    }

    Rectangle {
        id: popup
        color: constants.popupBackgroundColor
        anchors.left: popupContainer.horizontalCenter
        anchors.right: popupContainer.right
        anchors.top: popupContainer.top
        anchors.bottom: popupContainer.bottom
        anchors.topMargin: 30
        anchors.leftMargin: -30
        anchors.rightMargin: 90
        anchors.bottomMargin: 30

        Item {
            id: childContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            property int gridspacing: 10

            Item {
                id: listWrapper
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                ListView {
                    id: list
                    clip: true
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    orientation: ListView.Vertical
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: list.height / 2 - list.height / constants.numberOfItemsVisibleInList / 2
                    preferredHighlightEnd: list.height / 2 + list.height / constants.numberOfItemsVisibleInList / 2
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveVelocity: 800

                    model: listModel
                    highlight: Rectangle{
                        color: constants.popupBackgroundColor
                        height: list.height / constants.numberOfItemsVisibleInList
                        Rectangle {
                            color: constants.highlightColor
                            anchors.fill: parent
                        }
                    }
                    delegate: Item {
                        id: theItem
                        height: list.height / constants.numberOfItemsVisibleInList
                        width: list.width
                        property real addSize: (Math.max(height - Math.abs(theItem.y - list.contentY - list.preferredHighlightBegin), 0) / height) * constants.listViewSizeIncreaseFactor
                        Text {
                            anchors.horizontalCenter: theItem.horizontalCenter
                            anchors.verticalCenter: theItem.verticalCenter
                            anchors.verticalCenterOffset: 10 // TO-DO: Find a better solution for centering the text inside the highlight rectangle
                            text: modelData
                            color: theItem.ListView.isCurrentItem ? constants.highlightItemColor : constants.itemColor
                            font.pixelSize: (parent.height * 0.6) * (1 + addSize)
                        }
                        Keys.onPressed: {
                            event.accepted = false
                            if(MKeys.pressedFnAcc("SELECT", event))
                            {
                                itemSelected(modelData)
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            onClicked: itemSelected(modelData)
                        }
                    }

                    Keys.onPressed: {
                        event.accepted = false
                        if(MKeys.pressedFnAcc("NAVDOWN", event))
                        {
                            incrementCurrentIndex()
                        }
                        else if(MKeys.pressedFnAcc("NAVUP", event))
                        {
                            decrementCurrentIndex()
                        }
                        else if(MKeys.pressedFnAcc("POPACCEPT", event) || MKeys.pressedFnAcc("LEFT", event) || MKeys.pressedFnAcc("RIGHT", event))
                        {
                            setSelected()
                            close()
                        }
                        else if(MKeys.pressedFnAcc("ESCAPE", event))
                        {
                            close()
                        }
                    }
                }
                Rectangle {
                    anchors.left: list.left
                    anchors.right: list.right
                    anchors.top: list.top
                    height: 140
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: constants.popoverListViewShadingStartColor }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Rectangle {
                    anchors.left: list.left
                    anchors.right: list.right
                    anchors.bottom: list.bottom
                    height: 140
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: constants.popoverListViewShadingStartColor }
                    }
                }
            }
        }

        // Border
        Rectangle{
            color: "transparent"
            anchors.fill: childContent
            radius: constants.outerBoxRadius
            border.width: 2
            border.color: constants.popupBorderColor

        }

        MouseArea {
            // This mouse-area is to prevent closing the dialog when clicking on it. We only want close outside the popup.
            anchors.fill: parent
            z: -1

            onClicked: { }
        }

    }

    states: [
        State {
            name: "NOTSHOWING"
            when: !popupContainer.visible
            PropertyChanges { target: fadeOutParentRect; opacity: 0.0 }
            StateChangeScript {
                script: {
                    list.focus = false;
                    popupContainer.focus = false;
                    // Set focus to caller
                    if(popupContainer.returnToItem !== null)
                        popupContainer.returnToItem.focus = true;
                }
            }
        },
        State {
            name: "SHOWING"
            when: popupContainer.visible;
            PropertyChanges { target: fadeOutParentRect; opacity: constants.fadeOutOpacity }
            PropertyChanges { target: popupContainer; enabled: true }
            StateChangeScript {
                script: {
                    popupContainer.fillModel()

                    // Set focus on currently selected value
                    // We do not want it to slowly "roll" to position, so we set duration
                    // temporarily to 0
                    var oldHighlightMoveDuration = list.highlightMoveDuration;
                    list.highlightMoveDuration = 0;
                    list.currentIndex = findCurrentIndex()
                    list.highlightMoveDuration = oldHighlightMoveDuration;
                }
            }
        }
    ]

    transitions: [
        Transition {
            PropertyAnimation {
                target: fadeOutParentRect
                properties: "opacity"
                easing.type: Easing.OutCubic
                duration: constants.fadeOutDuration
            }
        }
    ]

    ListModel {
        id: listModel
    }
}
