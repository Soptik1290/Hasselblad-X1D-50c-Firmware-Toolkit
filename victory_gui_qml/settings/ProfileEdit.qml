import QtQuick 2.0

import "qrc:///components/buttons"
import "qrc:///components/popups"
import "qrc:///scripts/Keys.js" as MKeys
import "qrc:///components"

Popover {
    id: root

    property int profileIndex: 0
    property string name: ""
    property int gridspacing: constants.popupGridSpacing

    heading: ""
    updateBodySyncState: false
    contentItem: grid
    onFocusChanged: if (focus) grid.forceActiveFocus()
    property string action: ""

    function setSelected() {}
    function openProcessing() {}

    function startWheelTimeout()
    {
        wheelTimer.restart();
    }

    Timer {
        id: wheelTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: {
            grid.currentIndex = -1
            root.focus = true
        }
    }

    content: Item {
        anchors.fill: parent

        Row {
            id: row
            anchors.top: parent.top
            anchors.topMargin: -30
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: profileIcon
                source: (profileIndex === 0) ? "qrc:///icons/SpiritNormalMode.png" : "qrc:///icons/SpiritUserMode.png"

                Text {
                    visible: profileIndex > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 17
                    color: "white"
                    text: profileIndex.toString()
                    font.bold: true
                }
            }
            Text {
                text: qsTr(name) + guiconfig.emptyString
                color: constants.popupTextColor
                font.pixelSize: 40
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                fontSizeMode: Text.Fit
                height: profileIcon.height
                property int maxWidth: root.popupWidth() - profileIcon.width - 2*(constants.popupSideMargins/2)
                width: Math.min(maxWidth, implicitWidth)
            }
        }

        GridView {
            id: grid
            focus: true
            interactive: false

            anchors {
                fill: parent
                topMargin: model.count === 3 ? 40 : 70
                leftMargin: constants.popupSideMargins
                rightMargin: constants.popupSideMargins
                bottomMargin: 10
            }
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationWraps: false
            currentIndex: -1

            onCurrentIndexChanged: {
                startWheelTimeout()
            }

            function setSelected()
            {
                gotClick(currentIndex)
            }

            function gotClick(ix)
            {
                console.log("index", ix)
                if ((ix > 0 && profileIndex === 0) || ix === 2) {
                    return
                }
                if (ix === 0) {
                    root.action = "load"
                } else if (ix === 1) {
                    root.action = "save"
                } else {
                    console.log("rename profile (not implemented yet)", profileIndex)
                }
            }

            cellWidth: width
            cellHeight: height / (model.count === 3 ? model.count : 2.4)
            model: buttonModel

            delegate: Item {
                id: grid_delegate

                width: grid.cellWidth
                height: grid.cellHeight - gridspacing
                Rectangle {
                    id: selectRect
                    visible: index === grid.currentIndex
                    color: constants.hblOrange
                    anchors.fill: parent
                    anchors.leftMargin: -constants.popupSideMargins
                    anchors.rightMargin: -constants.popupSideMargins
                }

                MenuButton {
                    objectName: "profiles_menuButton"
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    maxWidth: parent.width - 30
                    minWidth: maxWidth
                    text: qsTr(buttonText) + guiconfig.emptyString
                    isEnabled: (!(index > 0 && profileIndex === 0) && index < 2) //Do not allow save/rename for default profile
                    spacing: 10
                    borderColor: isEnabled ? (index === grid.currentIndex ? constants.buttonBorderHighlightColor : constants.buttonBorderColor) : constants.buttonDisabledColor
                    onClicked: {
                        if (isEnabled) {
                            grid.gotClick(index)
                        }
                    }
                }
            }
        }
        ListModel {
            id: buttonModel
            ListElement { buttonText: QT_TR_NOOP("Load") }
            ListElement { buttonText: QT_TR_NOOP("Save") }
            //ListElement { buttonText: QT_TR_NOOP("Rename") }
        }
    }

    GenericConfirm {
        id: confirm
        anchors.fill: parent
        visible: (root.action === "load" || root.action === "save")
        largeHeaderText: true
        headerText: (root.action === "load") ? qsTr("Load Profile?") : qsTr("Save Profile?")
        largeInfoText: true
        infoMarginSide: 20
        bgHeaderTopMargin: 80
        infoText: qsTr(root.name)
        rightText: (root.action === "load") ? qsTr("Load") : qsTr("Save")
        onVisibleChanged: {
            if (visible) {
                forceActiveFocus()
            }
        }
        onRightSelected: {
            if (root.action === "load") {
                console.log("loading profile", profileIndex)
                configstore.loadDbFromProfile(profileIndex)
            } else {
                console.log("saving to profile", profileIndex)
                configstore.saveDbProfileFromCurrent(profileIndex)
            }
            root.close()
        }
        onLeftSelected: root.close()
    }
}
