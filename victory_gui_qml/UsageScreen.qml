import QtQuick 2.0
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    objectName: "UsageScreen_root"
    id: root
    property alias headerBgCol: headerBg.color
    property string headingText: ""
    color: constants.menuBackgroundColor
    Rectangle {
        id: headerBg
        color: "black"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: header.bottom
        }
    }
    Text {
        id: header
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: constants.headerVerticalOffset
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        text: qsTr(headingText) + guiconfig.emptyString
        font.capitalization: Font.AllUppercase
    }
    MouseArea {
        anchors.fill: parent
        drag {
            target: root
            axis: Drag.XAxis
            minimumX: 0
            maximumX: root.width
            threshold: constants.dragThreshold
            filterChildren: true
        }
        drag.onActiveChanged: {
            if (!drag.active) {
                if (drag.target.x > (root.width / constants.swipeLengthDividor))
                {
                    closeSubDialog()
                }
                root.x = 0
            }
        }
        onClicked: {}
    }
}
