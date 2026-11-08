import QtQuick 2.0
import com.hasselblad.upgrade 1.0
import com.hasselblad.systemmanager 1.0
import "qrc:///components"
import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    objectName: "UpgradeCheck_root"
    id: root
    color: "black"
    z:200
    focus: true
    property alias initialState: content_root.state
    property int textOffset: 60
    property int sideMargin: 50
    property int numberOfItemsVisibleInList: constants.numberOfItemsVisibleInList
    property alias model: listView.model
    function exitDialog()
    {
        parent.active = false
        Upgrader.inUse = false
    }
    Text {
        id: header
        anchors {
            top: parent.top
            topMargin: textOffset
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }
        color: "white"
        font.pixelSize: 60
        text: qsTr("Firmware Update") + guiconfig.emptyString
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
    }
    Text {
        id: subText
        anchors {
            top: parent.top
            topMargin: textOffset + 184
            bottom: parent.bottom
        }
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        color: "white"
        wrapMode: Text.Wrap
        font.pixelSize: 45
    }
    Image {
        id: imgExclamationMark
        source: "qrc:///icons/exclamationMark.png"
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: textOffset + 85
        }
    }
    MenuButton {
        id: leftButton
        objectName: "UpgradeCheck_leftButton"
        anchors {
            bottom: parent.bottom
            bottomMargin: 10
            left: parent.left
            leftMargin: 10
        }
        maxWidth: parent.width * .5 - anchors.leftMargin * 2
        minWidth: maxWidth
        height: constants.buttonHeight
        visible: false
        enabled: false
        onClicked: exitDialog()
        text: qsTr("Cancel") + guiconfig.emptyString
    }
    MenuButton{
        id: rightButton
        objectName: "UpgradeCheck_rightButton"
        anchors {
            bottom: parent.bottom
            bottomMargin: 10
            right: parent.right
            rightMargin: 10
        }
        maxWidth: parent.width * .5 - anchors.rightMargin * 2
        minWidth: maxWidth
        height: constants.buttonHeight
        visible: false
        enabled: false
        onClicked: rightClick()
        text: qsTr("Update") + guiconfig.emptyString
    }
    function rightClick()
    {
        if (content_root.state == "ask" && listView.count > 0) {
            content_root.state = "list"
        } else if (content_root.state == "ask") {
            content_root.state = "no_upgrades"
        } else if (content_root.state == "list") {
            confirmDialog.currentUpgradeIndex = listView.currentIndex
            content_root.state = "confirm"
        }
    }
    Component.onCompleted: {
        Upgrader.inUse = true
    }
    Component.onDestruction: {
        Upgrader.inUse = false
    }
    Item {
        id: content_root
        anchors {
            top: header.bottom
            bottom: leftButton.top
            left: parent.left
            right: parent.right
            leftMargin: sideMargin
            rightMargin: sideMargin
            topMargin: 10
            bottomMargin: 20
        }
        ListView {
            objectName: "UpgradeCheck_listview"
            id: listView
            visible: false
            focus: visible
            anchors.fill: parent
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: listView.height / 2 - listView.height / numberOfItemsVisibleInList / 2
            preferredHighlightEnd: listView.height / 2 + listView.height / numberOfItemsVisibleInList / 2
            model: Upgrader.allUpgrades
            onCountChanged: {
                if (count === 0 && content_root.state == "list")
                    content_root.state = "no_upgrades"
            }
            Keys.onPressed: {
                event.accepted = true
                if(MKeys.pressedFn("LISTUP", event.key))
                    listView.decrementCurrentIndex()
                else if(MKeys.pressedFn("LISTDOWN", event.key))
                    listView.incrementCurrentIndex()
                else if(MKeys.pressedFn("ESCAPE", event.key))
                    exitDialog()
                else
                    event.accepted = false
            }
            Keys.onReturnPressed: {
                cancel_button.focus = true
            }
            highlight: Rectangle {
                color: constants.popupBackgroundColor
                height: listView.height / numberOfItemsVisibleInList
                Rectangle {
                    color: constants.highlightColor
                    anchors.fill: parent
                }
            }
            delegate: Item {
                objectName: "UpgradeCheck_listview_delegate"
                id: theItem
                height: listView.height / numberOfItemsVisibleInList
                width: listView.width
                property real addSize : (Math.max(height - Math.abs(theItem.y - listView.contentY - listView.preferredHighlightBegin), 0) / height) * constants.listViewSizeIncreaseFactor
                Text {
                    id: delegateText
                    width: parent.width
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2
                    text: listView.model[index].readable
                    color: "white"
                    font.pixelSize: constants.itemTextSizeMenuLevel1 * (1 + addSize) * .7
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    fontSizeMode: Text.HorizontalFit
                    font.family: constants.menuItemFontName
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: listView.currentIndex = index
                }
            }
            Rectangle{
                color: "transparent"
                anchors.fill: parent
                radius: constants.outerBoxRadius
                border.width: 2
                border.color: constants.popupBorderColor
            }
        }
        Connections {
            target: Upgrader
            onSearchDone: content_root.state = listView.count > 0 ? "list" : "no_upgrades"
        }
        state: "search"
        states: [
            State {
                name: "batteryLow"
                when: suc.cambody_attached && (System.batteryStatus !== System.BatteryNormal &&
                                               System.batteryStatus !== System.BatteryUnknown &&
                                               System.batteryStatus !== System.BatteryAux)
                PropertyChanges { target: subText; text: qsTr("Battery level too low.<br/>Please charge it before upgrade.") + guiconfig.emptyString }
                PropertyChanges { target: leftButton; focus: true; visible: true; enabled: true; text: qsTr("Exit") + guiconfig.emptyString }
            },
            State {
                name: "usbConnected"
                when: suc.usb_vbus_present
                PropertyChanges { target: subText; text: qsTr("USB connection is not allowed during Firmware Update.<br/>Please disconnect and retry!") + guiconfig.emptyString }
                PropertyChanges { target: leftButton; focus: true; visible: true; enabled: true; text: qsTr("Exit") + guiconfig.emptyString }
            },
            State {
                name: "search"
                PropertyChanges { target: subText; text: qsTr("Searching...") + guiconfig.emptyString }
                PropertyChanges { target: leftButton; focus: true; visible: true; enabled: true }
                StateChangeScript { script: Upgrader.startSearch() }
            },
            State {
                name: "ask"
                PropertyChanges { target: subText; text: qsTr("There are important updates. Press Continue to select update.") + guiconfig.emptyString }
                PropertyChanges { target: leftButton; focus: true; visible: true; enabled: true; text: qsTr("Exit") + guiconfig.emptyString }
                PropertyChanges { target: rightButton; focus: true; visible: true; enabled: true; text: qsTr("Continue") + guiconfig.emptyString }
            },
            State {
                name: "list"
                PropertyChanges { target: listView; visible: true }
                PropertyChanges { target: leftButton; visible: true; enabled: true; }
                PropertyChanges { target: rightButton; visible: true; enabled: true }
                PropertyChanges { target: imgExclamationMark; visible: false }
            },
            State {
                name: "no_upgrades"
                PropertyChanges { target: subText; text: qsTr("No updates available") + guiconfig.emptyString }
                PropertyChanges { target: leftButton; focus: true; visible: true; enabled: true; text: qsTr("Exit") + guiconfig.emptyString }
            },
            State {
                name: "confirm"
                PropertyChanges { target: confirmDialog; active: true; focus: true }
            }
        ]
        transitions: [
            Transition {
                from: "usbConnected"
                ScriptAction { script: { restoreStateTimer.start() } }
            }
        ]
        Timer {
            id: restoreStateTimer
            interval: 0
            repeat: false
            onTriggered: content_root.state = "search"
        }
    }
    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: {}
    }
    Loader {
        id: confirmDialog
        objectName: "UpgradeCheck_confirmDialog"
        anchors.fill: parent
        source: "qrc:///components/GenericConfirm.qml"
        active: false
        asynchronous: true
        onLoaded: {
            item.headerText = qsTr("Firmware Update")
            item.infoText = qsTr("Update can take up to 15 minutes. Do you want to continue?")
            item.leftText = qsTr("Exit")
            item.rightText = qsTr("Update")
            item.middleAvailable = ""
            item.largeHeaderText = true
            item.transparentBackground = true
        }
        property int currentUpgradeIndex: 0
        onActiveChanged: {
            if(!active)
            {
                content_root.state = "list"
            }
        }
        Connections {
            target: confirmDialog.item
            onRightSelected : {
                Upgrader.startUpgrade(listView.model[confirmDialog.currentUpgradeIndex].uuid)
                root.visible = false
            }
        }
    }
}
