import QtQuick 2.0
import com.hasselblad.upgrade 1.0
import com.hasselblad.systemmanager 1.0

import "qrc:/components"
import "qrc:/components/buttons"

Rectangle {
    objectName: "PopoverError_root"
    anchors.fill: parent
    id: root

    property real sizeFactor: Math.min(width / 640.0, height / 480.0)
    property bool showButtons: true


    // Set these properties outside this
    property alias heading: headingText.text
    property alias icon: busyIcon.source
    property alias subText: subTextItem.text
    property alias errcodeText: errcodeTextItem.text
    property alias bottomText: bottomTextItem.text

    property int iconTopMargin: 40 * sizeFactor
    property int textWidth: root.width - 20 * sizeFactor
    property int buttonWidth: (root.width - 30 * sizeFactor) / 2
    property bool showEmergencyButtons: true
    property bool showIcon: true

    property int showFWUpdateRetryCounter: 0

    color: "black"

    StatusRow { }

    // Header
    Text {
        id: headingText
        visible: text.length !== 0
        anchors {
            top: parent.top
            topMargin: iconTopMargin
            left: parent.left
            right: parent.right
            leftMargin: 10 * sizeFactor
            rightMargin: 10 * sizeFactor
        }
        horizontalAlignment: Text.AlignHCenter
        color: "white"
        font.pixelSize: constants.popupHeaderTextSize * sizeFactor
        font.capitalization: Font.AllUppercase
    }

    // Firmware version
    Text {
        visible: (showFWUpdateRetryCounter >= 5)
        text: "Firmware " + System.versionID
        color: "white"
        font.pixelSize: constants.errorDialogBottomTextSize * sizeFactor
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignHCenter
        anchors {
            top: parent.top
            topMargin: 10 * sizeFactor
            horizontalCenter: parent.horizontalCenter
        }
    }

    // The icon
    Image {
        id: busyIcon
        anchors {
            top: parent.top
            topMargin: iconTopMargin * sizeFactor + height / 2 * (sizeFactor - 1)
            horizontalCenter: parent.horizontalCenter
        }
        visible: showIcon
        MouseArea{
            anchors.fill: parent
            onClicked: showFWUpdateRetryCounter++
        }
        scale: sizeFactor

    }

    // Error-code
    Text {
        id: errcodeTextItem
        anchors {
            top: busyIcon.bottom
            topMargin: 10 * sizeFactor + busyIcon.height / 2 * (sizeFactor - 1)
            left: parent.left
            right: parent.right
            leftMargin: 10 * sizeFactor
            rightMargin: 10 * sizeFactor
        }
        width: textWidth
        color: "white"
        fontSizeMode: Text.Fit
        font.pixelSize: constants.errorDialogBottomTextSize * sizeFactor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }

    Column {
        id: textLayout
        anchors {
            top: errcodeTextItem.bottom
            topMargin: 20 * sizeFactor
            left: parent.left
            leftMargin: 15 * sizeFactor
            right: parent.right
            rightMargin: 15 * sizeFactor
            bottom: buttonRow.top
            bottomMargin: 10 * sizeFactor
        }
        spacing: 6 * sizeFactor

        // SubText (Describe the issue)
        Text {
            visible: text != ""
            id: subTextItem
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 0.6*parent.height
            color: "white"
            font.pixelSize: constants.errorDialogSubTextSize * sizeFactor
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        // Bottom text (Standard information)
        Text {
            id: bottomTextItem
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 0.4*parent.height
            color: "white"
            fontSizeMode: Text.Fit
            font.pixelSize: constants.errorDialogBottomTextSize * sizeFactor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
    }


    Row {
        id: buttonRow
        anchors {
            left: parent.left
            leftMargin: 10 * sizeFactor
            right: parent.right
            rightMargin: 10 * sizeFactor
            bottom: parent.bottom
            bottomMargin: 10 * sizeFactor
        }
        spacing: 10 * sizeFactor
        height: constants.buttonHeight * sizeFactor
        layoutDirection: Qt.RightToLeft
        visible: showButtons
        enabled: showButtons

        MenuButton {
            id: saveLogsButton
            spacing: constants.menuButtonSpacing / 2 * sizeFactor
            text: qsTr("Save logs") + guiconfig.emptyString
            onClicked: {
                System.collectLogs()
                subDialog.setSource("PopoverBusy.qml", { "heading" : "",
                                        "centerText": qsTr("Saving log"),
                                        "icon": "qrc:///icons/exclamationMark.png",
                                        "showStatusRow": true,
                                        "bottomText": qsTr("Do not remove card!") })
                subDialog.active = Qt.binding(function() { return System.collecting_logs !== 0 })
            }
            visible: showEmergencyButtons
            maxWidth: parent.width * .5 - parent.spacing / 2
            minWidth: maxWidth
        }
        Item {
            width: fwUpdateRetryButton.width
            height: childrenRect.height
            visible: showEmergencyButtons && (showFWUpdateRetryCounter >= 5)
            MenuButton {
                id: fwUpdateRetryButton
                text: qsTr("FW Update Retry") + guiconfig.emptyString
                spacing: constants.menuButtonSpacing / 2 * sizeFactor
                onClicked: Upgrader.upgradeNodes()
                maxWidth: buttonRow.width * .5 - buttonRow.spacing / 2
                minWidth: maxWidth
            }
            MenuButton {
                id: startWiFiButton
                anchors.left: fwUpdateRetryButton.left
                anchors.right: fwUpdateRetryButton.right
                anchors.bottom: fwUpdateRetryButton.top
                spacing: constants.menuButtonSpacing / 2 * sizeFactor
                anchors.bottomMargin: buttonRow.spacing
                text: (configstore.WIFI_power ? qsTr("Turn off WiFi") : qsTr("Turn on WiFi")) + guiconfig.emptyString
                onClicked: {
                    configstore.WIFI_power = !configstore.WIFI_power
                }
                maxWidth: buttonRow.width * .5 - buttonRow.spacing / 2
                minWidth: maxWidth
            }
        }

    }

    // Prevent closing when clicking outside of popup
    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: {}
    }

    Loader {
        objectName: "subDialog_Loader"
        anchors.fill: parent
        id: subDialog
        active: false
        visible: active
        asynchronous: true
        focus: active
        onActiveChanged: {
            // If active becomes false, a dialog was closed, and list must get focus
            if(!active)
            {
                // Make sure to break various bindings that could case this to be active again
                subDialog.active = false
                root.forceActiveFocus()
            }
        }
        function closeSubDialog()
        {
            subDialog.active = false
        }
    }
} // Rectangle
