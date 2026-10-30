import QtQuick 2.0
import com.hasselblad.settings 1.0
import "qrc:///scripts/Keys.js" as MKeys

MouseArea {
    objectName: "popupContainer"
    id: popupContainer

    property alias popupAnchor: popup.anchors

    // This is the item that shall have focus when popup is closed
    property Item returnToItem
    visible: false

    property var theProxy
    property var thePropertyName

    // returnItem is the calling item that shall receive focus when closed
    function open(returnItem, proxy, propertyName) {
        theProxy = proxy
        thePropertyName = propertyName
        popupContainer.enabled = true;
        popupContainer.returnToItem = returnItem;

        if (popupContainer.visible)
            return;

        visible = true;

        list.focus = true;

        // Set focus on currently selected value
        // We do not want it to slowly "roll" to position, so we set duration
        // temporarily to 0
        var oldHighlightMoveDuration = list.highlightMoveDuration;
        list.highlightMoveDuration = 0;
        var currentValue = Settings.getUntranslatedDisplayValue(propertyName, proxy[propertyName]);
        console.log("currentValue", currentValue)
        list.currentIndex = list.model.indexOf(currentValue);
        list.highlightMoveDuration = oldHighlightMoveDuration;
    }

    function close() {
        if (visible) {
            popupContainer.enabled = false;
            list.focus = false;
            visible = false;
            popupContainer.focus = false;
            // Set focus to caller
            if(popupContainer.returnToItem !== undefined)
                popupContainer.returnToItem.focus = true;
        }
    }

    // Called when the user clicked in the list, not necessarily on the selected item,
    // then the clicked item will be set
    function itemSelected(dataValue)
    {
        // This test can be removed whan all items has a proxy in MenuItemSpecifications.js
        if(typeof theProxy !== 'undefined')
        {
            console.log("selected", dataValue)
            Settings.setSettingValue(theProxy, thePropertyName, dataValue);
        }
        close();
    }

    // Called from parent to set selected value when the user clicked outside of the list,
    // then the selected (highlighted) item will be set
    function setSelected()
    {
        // This test can be removed whan all items has a proxy in MenuItemSpecifications.js
        if(typeof theProxy !== 'undefined')
        {
            console.log("selected", list.model[list.currentIndex])
            Settings.setSettingValue(theProxy, thePropertyName, list.model[list.currentIndex]);
        }
    }

    Keys.onPressed: {
        event.accepted = true
        if(MKeys.pressedFn("LISTUP", event.key))
            list.decrementCurrentIndex()
        else if(MKeys.pressedFn("SELECT", event.key))
        {
            setSelected()
            close()
        }
        else if(MKeys.pressedFn("LISTDOWN", event.key))
            list.incrementCurrentIndex()
        else if(MKeys.pressedFn("ESCAPE", event.key))
            close()
        else
            event.accepted = false
    }

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

    /* @return  true, when a string begins with a non-ascii (extended) char, implying a non-ascii language (e.g. korean, chinese etc)
     *          false, when it does not contain a non-ascii (extended) char, implying a latin-based language (e.g. english, french etc)
     *          null, when the input is empty or not a string
    */
    function hasNonAsciiChars(str)
    {
        if (str.length < 1 || typeof str !== 'string') return null
        if (str.charCodeAt(0) > 255) return true;
        return false
    }

    Rectangle {
        id: popup
        color: constants.popupBackgroundColor
        anchors.left: popupContainer.left
        anchors.right: popupContainer.right
        anchors.top: popupContainer.top
        anchors.bottom: popupContainer.bottom
        anchors.topMargin: 30
        anchors.leftMargin: 30
        anchors.rightMargin: 30
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
                    objectName: "ListSelectorSettings_list"
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

                    highlight: Rectangle{
                        color: constants.popupBackgroundColor
                        height: list.height / constants.numberOfItemsVisibleInList
                        Rectangle {
                            color: constants.highlightColor
                            anchors.fill: parent
                        }
                    }

                    model: Settings.getVariableListModel(popupContainer.thePropertyName)
                    delegate: Item {
                        id: theItem
                        height: list.height / constants.numberOfItemsVisibleInList
                        width: list.width
                        property real addSize : (Math.max(height - Math.abs(theItem.y - list.contentY - list.preferredHighlightBegin), 0) / height) * constants.listViewSizeIncreaseFactor
                        Text {
                            text: Settings.stringTranslated(popupContainer.thePropertyName, modelData) + guiconfig.emptyString
                            anchors.verticalCenter: theItem.verticalCenter
                            anchors.verticalCenterOffset: hasNonAsciiChars(text) ? constants.listSelectorYOffsetUnicode : constants.listSelectorYOffsetAscii
                            font.family: constants.menuItemFontName
                            color: theItem.ListView.isCurrentItem ? constants.highlightItemColor: constants.itemColor
                            font.pixelSize: parent.height * 0.6 * (1 + addSize)
                            width: parent.width
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            fontSizeMode: Text.HorizontalFit
                        }
                        Keys.onReturnPressed: itemSelected(modelData)
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            onClicked: itemSelected(modelData)
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

        }

        // Border
        Rectangle{
            color: "transparent"
            anchors.fill: childContent
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
        },
        State {
            name: "SHOWING"
            when: popupContainer.visible
            PropertyChanges { target: fadeOutParentRect; opacity: constants.fadeOutOpacity }
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

}
