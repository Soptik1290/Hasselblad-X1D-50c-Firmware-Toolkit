import com.hasselblad.settings 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.camera 1.0
import "qrc:///scripts/Keys.js" as MKeys
import QtQuick 2.0
FocusScope
{
    id: popupContainer
    property Item returnToItem: null
    property int listItemHeight: 126 + 12
    function open(returnItem) {
        popupContainer.returnToItem = returnItem
        returnItem.focus = false
        visible = true
    }
    function close() {
        visible = false;
    }
    anchors.fill: parent
    MouseArea {
        preventStealing: true
        z: 100
        anchors.fill: parent
        onClicked: close()
        Keys.onPressed: {
            event.accepted = true
            if(MKeys.pressedFn("SELECT", event.key)) {
                event.accepted = true
                if(list.currentIndex  < (list.count - 1))
                {
                    list.incrementCurrentIndex()
                }
                else
                {
                    close();
                }
            }
            else if(MKeys.pressedFn("MENU", event.key) || MKeys.pressedFn("BROWSE", event.key) || MKeys.pressedFn("ESCAPE", event.key)) {
                event.accepted = true
                close();
            }
            else if(MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("FORMAT", event.key)) {
                event.accepted = false
            }
        }
        Rectangle {
            id: fadeOutParentRect
            color: constants.popupFadeoutColor
            anchors.fill: parent
            opacity: 0.5
        }
        Rectangle {
            id: popup
            color: constants.popupBackgroundColor
            radius: constants.outerBoxRadius
            border.width: 2
            border.color: constants.popupBorderColor
            anchors {
                leftMargin: 69
                rightMargin: 69
                topMargin: 69
                bottomMargin: 69
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                top: parent.top
            }
            Text {
                id: heading
                text: qsTr("EXPOSURE ADJUST") + guiconfig.emptyString
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 21
                color: constants.popupTextColor
                anchors {
                    top: parent.top
                    topMargin: 33
                    horizontalCenter: parent.horizontalCenter
                }
                font.capitalization: Font.AllUppercase
            }
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: { }
            }
            ListView {
                id: list
                clip: true
                focus: true
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                anchors {
                    top: parent.top
                    topMargin: 48 + 12
                    left: parent.left
                    leftMargin: popup.border.width
                    right: parent.right
                    rightMargin: popup.border.width
                    bottom: parent.bottom
                    bottomMargin: popup.border.width
                }
                orientation: ListView.Vertical
                highlightMoveDuration: constants.highlightMoveDuration
                model: (Camera.canChange & Camera.PropEVADJ && Camera.canChange & Camera.PropFlashEVADJ) ?
                        list_model :
                           Camera.canChange & Camera.PropEVADJ ?
                               no_flash_list_model :
                               no_evadj_list_model
                highlight: Item {
                    anchors.left: list.currentIndex >= 0 ? parent.left : undefined
                    anchors.right: list.currentIndex >= 0 ? parent.right : undefined
                    height: listItemHeight
                    Rectangle{
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                            topMargin: 38 + 12
                            bottomMargin: 12
                        }
                        color: constants.highlightColor
                    }
                }
                delegate: Slider {
                    height: listItemHeight
                    anchors.left: parent.left
                    anchors.right: parent.right
                    lineColor: "white"
                    markerColor: index == list.currentIndex ? constants.highlightColor : "black"
                    iconSource: icon
                    value: Camera[propertyName] / sliderMultiplier
                    originalValue: Camera[propertyName] / sliderMultiplier
                    tickCount: sliderTickCount
                    maxValue: sliderMaxValue
                    minValue: sliderMinValue
                    stepSize: list.model.getValueStep(index)
                    onChangedNewValue: {
                        Camera[propertyName] = newValue * sliderMultiplier
                    }
                    onOriginalValueChanged: {
                        if(!changeInProcess)
                        {
                            value = originalValue
                        }
                        if(Math.abs(originalValue - latestValue) < 0.01)
                        {
                            changeInProcess = false
                        }
                    }
                }
                Keys.onReturnPressed: close()
                Keys.onPressed: {
                    var newValue
                    if(MKeys.pressedFnAcc("LEFT", event)) {
                        if(contentItem.children.length > 0)
                        {
                            contentItem.children[0].stepDown()
                        }
                    }
                    else if(MKeys.pressedFnAcc("RIGHT", event)) {
                        if(contentItem.children.length > 0)
                        {
                            contentItem.children[0].stepUp()
                        }
                    }
                    else if(MKeys.pressedFnAcc("UP", event)) {
                        if(contentItem.children.length > 1)
                        {
                            contentItem.children[1].stepDown()
                        }
                    }
                    else if(MKeys.pressedFnAcc("DOWN", event)) {
                        if(contentItem.children.length > 1)
                        {
                            contentItem.children[1].stepUp()
                        }
                    }
                    else if(MKeys.pressedFnAcc("NAVLEFT", event)) {
                        if(currentIndex >= 0)
                        {
                            contentItem.children[currentIndex].stepDown()
                        }
                    }
                    else if(MKeys.pressedFnAcc("NAVRIGHT", event)) {
                        if(currentIndex >= 0)
                        {
                            contentItem.children[currentIndex].stepUp()
                        }
                    }
                }
            }
        }
        ListModel {
            id: list_model
            ListElement {
                icon: "qrc:///icons/Flash_adjust_for_popup.png"
                sliderTickCount: 7
                sliderMaxValue: 3
                sliderMinValue: -3
                sliderMultiplier: 12
                propertyName: "FLASH_EVADJ"
            }
            ListElement {
                icon: "qrc:///icons/Exposure_adjust_for_popup.png"
                sliderTickCount: 11
                sliderMaxValue: 5
                sliderMinValue: -5
                sliderMultiplier: 12
                propertyName: "EVADJ"
            }
            function getValueStep(index)
            {
                switch(index)
                {
                case 0:
                    return 1.0 / 3.0;
                case 1:
                    return configstore.CustomOption_AdjStepsInc / 12;
                default:
                    return 1.0 / 3.0;
                }
            }
        }
        ListModel {
            id: no_flash_list_model
            ListElement {
                icon: "qrc:///icons/Exposure_adjust_for_popup.png"
                sliderTickCount: 11
                sliderMaxValue: 5
                sliderMinValue: -5
                multiplier: 12
                propertyName: "EVADJ"
            }
            function getValueStep(index)
            {
                return configstore.CustomOption_AdjStepsInc / 12;
            }
        }
        ListModel {
            id: no_evadj_list_model
            ListElement {
                icon: "qrc:///icons/Flash_adjust_for_popup.png"
                sliderTickCount: 7
                sliderMaxValue: 3
                sliderMinValue: -3
                multiplier: 12
                propertyName: "FLASH_EVADJ"
            }
            function getValueStep(index)
            {
                return 1.0 / 3.0;
            }
        }
        states: [
            State {
                name: "NOTSHOWING"
                when: !popupContainer.visible
                PropertyChanges { target: fadeOutParentRect; opacity: 0.0 }
                StateChangeScript {
                    script: {
                        popupContainer.focus = false;
                        BodySync.currentState = BodySync.MAIN
                        if (popupContainer.returnToItem !== null)
                            popupContainer.returnToItem.forceActiveFocus()
                    }
                }
            },
            State {
                name: "SHOWING"
                when: popupContainer.visible
                PropertyChanges { target: fadeOutParentRect; opacity: constants.fadeOutOpacity }
                StateChangeScript {
                    script: {
                        popupContainer.focus = true;
                        BodySync.currentState = BodySync.MENU
                        var oldHighlightMoveDuration = list.highlightMoveDuration;
                        list.highlightMoveDuration = 0;
                        list.currentIndex = -1;
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
                    duration: 500
                }
            }
        ]
    }
}
