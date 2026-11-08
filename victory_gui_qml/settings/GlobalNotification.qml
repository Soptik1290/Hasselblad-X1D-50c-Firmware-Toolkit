import QtQuick 2.0

import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.camera 1.0

Item {
    objectName: "GlobalNotification"
    id: root
    visible: allow && allowMode
    anchors.fill: parent
    z: 1000
    property bool allow: true
    property bool showPopup: true
    property string mode: ""

    // "Internal" properties

    property real sizeFactor: Math.min(width / 640.0, height / 480.0)
    property bool isErrorPopup: (mode === "no_crop_in_video")
    property bool allowMode : (mode === "crop_mode" && !Camera.exposing) ||
                              (mode === "no_crop_in_video") ||
                              (mode === "show_global_note" && !Camera.exposing)

    //The popup, used when not showing the overlay text
    Rectangle {
        id: frame
        visible: showPopup || isErrorPopup
        anchors.centerIn: parent
        width: parent.width*26/32
        height: parent.height*5/6
        color: "black"
        border {
            color: constants.popupBorderColor
            width: 3
        }
        Text {
            id: headerText
            visible: !root.isErrorPopup
            text: qsTr(GlobalStateInfo.overlayHeader) + guiconfig.emptyString
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: constants.headerVerticalOffset
            font.pixelSize : constants.headerTextSize
            color: constants.menuHeaderColor
            font.capitalization: Font.AllUppercase
            font.family: constants.menuItemFontName
        }
        // The text message. Display when not used as error popup
        Text {
            id: infoText
            visible: !root.isErrorPopup
            width: frame.width*0.9
            anchors.centerIn: parent
            text: qsTr(GlobalStateInfo.overlayText) + guiconfig.emptyString
            font.pixelSize: constants.mediaBrowseInfoFontSize
            fontSizeMode: Text.HorizontalFit
            horizontalAlignment: Text.AlignHCenter
            color: "white"
        }

        // The icon
        Image {
            id: errorIcon
            anchors {
                top: parent.top
                topMargin: (parent.height/2 - subTextItem.height/2 - height/2)/2
                horizontalCenter: parent.horizontalCenter
            }
            source: "qrc:///icons/infoDialogIcon.png"
            visible: root.isErrorPopup
            scale: sizeFactor
        }

        //The error popup text
        Text {
            id: subTextItem
            visible: root.isErrorPopup
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: 20*scale
                left: parent.left
                leftMargin: 15 * sizeFactor
                right: parent.right
                rightMargin: 15 * sizeFactor
            }
            text: qsTr(GlobalStateInfo.overlayText) + guiconfig.emptyString
            color: "white"
            font.pixelSize: constants.errorDialogSubTextSize * sizeFactor
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
    }

    //The overlay text. Used mainly in liveview and not when showing an error.
    Text {
        id: overlayText
        visible: !(showPopup || isErrorPopup) && (mode !== "show_global_note")
        anchors.left: parent.left
        anchors.leftMargin: 0.05*width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height*0.25
        text: qsTr(GlobalStateInfo.overlayText) + guiconfig.emptyString
        color: "white"
        font.pixelSize: constants.evfTextSize * sizeFactor/1.6
        font.family: constants.dialogTextFontName
        style: Text.Outline;
        styleColor: "black"
    }

    Connections {
        target: GlobalStateInfo
        onOverlayModeChanged: {
            //Use connection instead of binding since we reset the mode locally
            mode = GlobalStateInfo.overlayMode
        }
        onEvfActiveChanged: {
            closePopup()
        }
    }

    Timer {
        id: timer
        interval: 2000
        onTriggered: {
            root.mode = ""
        }
    }

    onAllowChanged: {
        if (!allow) {
            closePopup()
        }
    }

    onAllowModeChanged: {
        if (allowMode) {
            timer.restart()
        } else {
            closePopup()
        }
    }

    onShowPopupChanged: {
        closePopup()
    }

    function closePopup() {
        timer.stop()
        root.mode = ""
    }
}
