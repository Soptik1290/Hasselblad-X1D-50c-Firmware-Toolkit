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

    // Header text
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
        //enabled: !certificationView.active

        // We must have this here to be able to drag:
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
                // Done dragging
                if (drag.target.x > (root.width / constants.swipeLengthDividor))
                {
                    // Dragged enough to the right. Close the window
                    closeSubDialog()
                }
                root.x = 0
            }
        }
        onClicked: {}
    }
}
