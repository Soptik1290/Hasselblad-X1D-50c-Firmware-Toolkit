import QtQuick 2.0
import com.hasselblad.config 1.0

import "qrc:///components/buttons"
import "qrc:///settings/components"
import "qrc:///scripts/Keys.js" as MKeys

Popover {
    id: popFilterImages

    heading: qsTr("FILTER IMAGES") + guiconfig.emptyString
    contentItem: list
    onFocusChanged: if (focus) list.forceActiveFocus()
    updateBodySyncState: false

    onVisibleChanged: {
        //Save filter when closing
        if (!visible && list.filter !== configstore.imageRateFilter) {
            configstore.imageRateFilter = list.filter
        }
    }

    function openProcessing() {}

    content: Item {
        anchors.fill: parent
        anchors.topMargin: 20

        Column {
            id: list
            focus: true
            spacing: 15
            property int currentIndex: -1
            property int lastIndex: -1
            property int filter: configstore.imageRateFilter
            readonly property var masks: [Config.MaskRating1, Config.MaskRating2, Config.MaskRating3, Config.MaskRating4, Config.MaskRating5, Config.MaskUnrated]
            readonly property var clearMasks: [Config.MaskRatingAll ^ Config.MaskRating1, Config.MaskRatingAll ^ Config.MaskRating2, Config.MaskRatingAll ^ Config.MaskRating3,
                                               Config.MaskRatingAll ^ Config.MaskRating4, Config.MaskRatingAll ^ Config.MaskRating5, Config.MaskRatingAll ^ Config.MaskUnrated]

            anchors {
                fill: parent
                topMargin: 10
                leftMargin: constants.popupSideMargins
                rightMargin: constants.popupSideMargins
                bottomMargin: 10
            }

            function setSelected()
            {
                if (currentIndex >= 0 && currentIndex < 6) {
                    toggleItem()
                } else if (currentIndex === 6) { //Button
                    filter = Config.MaskRatingAll
                }
                stopWheelTimeout()
            }

            function toggleItem() {
                if ((filter & masks[currentIndex]) > 0) {
                    filter = filter & clearMasks[currentIndex]
                } else {
                    filter = filter | masks[currentIndex]
                }
            }

            function moveCurrentIndexLeft() {
                if (currentIndex < 0) {
                    currentIndex = (lastIndex >= 0) ? lastIndex : 0
                } else {
                    currentIndex = (currentIndex === 0) ? 6 : currentIndex - 1
                }
                startWheelTimeout()
            }
            function moveCurrentIndexUp() {
                moveCurrentIndexLeft()
            }
            function moveCurrentIndexRight() {
                if (currentIndex < 0) {
                    currentIndex = (lastIndex >= 0) ? lastIndex : 0
                } else {
                    currentIndex = (currentIndex === 6) ? 0 : currentIndex + 1
                }
                startWheelTimeout()
            }
            function moveCurrentIndexDown() {
                moveCurrentIndexRight()
            }

            Row {
                id: starRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                Repeater {
                    model: 5
                    Rectangle {
                        id: border
                        color: "transparent"
                        border.width: 2
                        border.color: image.highlighted ? constants.buttonBorderColor : "transparent"
                        width: image.width+10
                        height: image.height+10

                        Image {
                            id: image
                            property bool selected: (list.filter & list.masks[index]) > 0
                            property int highlighted: list.currentIndex === index
                            anchors.centerIn: parent
                            source: selected ? "qrc:///icons/RatingStar_Large_selected_75.png" : "qrc:///icons/RatingStar_Large_unselected_75.png"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    list.currentIndex = index
                                    list.setSelected()
                                }
                            }
                        }
                    }
                }
            }
            Rectangle {
                color: (list.currentIndex === 5) ? constants.highlightColor : "transparent"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: -constants.popupSideMargins+constants.popupBorderWidth+1
                anchors.rightMargin: -constants.popupSideMargins+constants.popupBorderWidth+1
                width: popFilterImages.width
                height: checkBox.boxSize * 2

                SettingCheckBox {
                    id: checkBox
                    width: list.width
                    height: constants.buttonHeight
                    boxSize: constants.checkBoxSize
                    //Want to align checkbox with reset button but the 'V' in the checkbox goes outside of the box so we need manual padding
                    checkBoxTextRightMargin: -resetButton.width/2 - constants.subSettingDropDownSpacing - 6
                    checkboxText: qsTr("Show unrated") + guiconfig.emptyString
                    itemSpacing: 20
                    value: (list.filter & Config.MaskUnrated) > 0
                    onCheckChange: {
                        list.currentIndex = 5
                        list.setSelected()
                    }
                }
            }

            MenuButton {
                id: resetButton
                maxWidth: list.width
                minWidth: maxWidth/2
                height: constants.buttonHeight
                highlight: list.currentIndex === 6
                anchors.horizontalCenter: parent.horizontalCenter
                borderColorHighLight: constants.buttonBorderHighlightColor
                onClicked: {
                    list.currentIndex = 6
                    list.setSelected()
                }
                text: qsTr("Reset") + guiconfig.emptyString
            }
        }
    }

    function startWheelTimeout()
    {
        wheelTimer.restart();
    }

    function stopWheelTimeout()
    {
        wheelTimer.stop();
        list.lastIndex = list.currentIndex
        list.currentIndex = -1
    }

    Timer {
        id: wheelTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: {
            list.lastIndex = list.currentIndex
            list.currentIndex = -1
            popFilterImages.focus = true
        }
    }
}
