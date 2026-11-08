import QtQuick 2.0
Rectangle {
    objectName: "NotificationPopup"
    anchors.fill: parent
    z: 100
    id: root
    property alias text: infoText.text
    property alias subText: subTextItem.text
    property real sizeFactor: Math.min(width / 640.0, height / 480.0)
    property bool openPopup: false
    property bool closeOnInput: false
    property bool openInternal: false
    visible: openInternal
    signal close()
    onOpenPopupChanged: {
        if (openPopup) {
            openPopup = false
            openInternal = true
        }
    }
    color: "black"
    Rectangle {
        id: noImagesFrame
        anchors {
            fill: parent
            bottomMargin: 40
            topMargin: 40
            leftMargin: 60
            rightMargin: 60
        }
        color: "transparent"
        border {
            color: constants.popupBorderColor
            width: 3
        }
    }
    Image {
        id: noImagesIcon
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: noImagesFrame.top
            topMargin: 65
        }
        source: "qrc:///icons/infoDialogIcon.png"
    }
    Text {
        id: infoText
        anchors {
            top: noImagesIcon.bottom
            topMargin: 65
            left: noImagesFrame.left
            leftMargin: 15 * sizeFactor
            right: noImagesFrame.right
            rightMargin: 15 * sizeFactor
        }
        text: ""
        font.pixelSize: constants.mediaBrowseInfoFontSize
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignHCenter
        color: "white"
    }
    Text {
        id: subTextItem
        anchors {
            top: infoText.bottom
            topMargin: 10
            left: noImagesFrame.left
            leftMargin: 15 * sizeFactor
            right: noImagesFrame.right
            rightMargin: 15 * sizeFactor
            bottom: noImagesFrame.bottom
            bottomMargin: 10
        }
        text: ""
        color: "white"
        font.pixelSize: constants.errorDialogSubTextSize * sizeFactor
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    function doClose() {
        if (closeOnInput) {
            root.openInternal = false
            close()
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: doClose()
        onDoubleClicked: doClose()
    }
    Keys.onPressed: {
        if (closeOnInput) {
            event.accepted = true
            doClose()
        }
    }
}
