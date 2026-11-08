import QtQuick 2.0
import "qrc:///scripts/Keys.js" as MKeys

Rectangle {
    id: root
    color: constants.menuBackgroundColor
    property string headingText
    property alias longText: longTextItem.text
    focus: true


    Keys.onPressed: {
        event.accepted = true
        if(MKeys.pressedFn("ESCAPE", event.key) || (!guiconfig.isWedge && MKeys.pressedFn("LEFT", event.key))) {
            closeSubDialog()
        }
        else if((guiconfig.isWedge && MKeys.pressedFn("LEFT", event.key)) || MKeys.pressedFn("UP", event.key)) {
            longTextFlick.contentY -= longTextItem.font.pixelSize
            longTextFlick.returnToBounds()
        }
        else if((guiconfig.isWedge && MKeys.pressedFn("RIGHT", event.key)) || MKeys.pressedFn("DOWN", event.key)) {
            longTextFlick.contentY += longTextItem.font.pixelSize
            longTextFlick.returnToBounds()
        }
        else if((guiconfig.isWedge && MKeys.pressedFn("CROSS", event.key))   ||
                (!guiconfig.isWedge && MKeys.pressedFn("SQUARE", event.key))   )
        {
            // Page down
            longTextFlick.contentY += longTextFlick.height
            longTextFlick.returnToBounds()
        }
        else if((guiconfig.isWedge && MKeys.pressedFn("SQUARE", event.key)) ||
                (!guiconfig.isWedge && MKeys.pressedFn("CROSS", event.key))   )
        {
            // Page up
            longTextFlick.contentY -= longTextFlick.height
            longTextFlick.returnToBounds()
        }
        else
            event.accepted = false;
    }


    Rectangle {
        id: viewEndLine
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: constants.viewEndLineWidth
    }

    MouseArea{
        anchors.left: viewEndLine.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        // We must have this here to be able to drag:
        drag {
            target: root
            axis: Drag.XAxis
            minimumX: -constants.viewEndLineWidth
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
                root.x = -constants.viewEndLineWidth
            }
        }
        onClicked: {}
        // Header text
        Text{
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: constants.headerVerticalOffset
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize : constants.headerTextSize
            color: constants.menuHeaderColor
            font.capitalization: Font.AllUppercase
            text: qsTr(headingText) + guiconfig.emptyString
        }
        // Long text
        Item {
            id: longTextHolder
            anchors.left: parent.left
            anchors.leftMargin: constants.leftMarginForItems
            anchors.right: parent.right
            anchors.rightMargin: constants.leftMarginForItems
            anchors.top: header.bottom
            anchors.topMargin: constants.headerVerticalOffset
            anchors.bottom: parent.bottom
            anchors.bottomMargin: constants.leftMarginForItems
            Flickable{
                id: longTextFlick
                clip: true
                anchors.fill: longTextHolder
                contentWidth: longTextItem.width
                contentHeight: longTextItem.height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                Text {
                    id: longTextItem
                    width: longTextHolder.width
                    font.pixelSize : constants.itemTextSize
                    color: constants.menuItemColor
                    wrapMode: Text.Wrap
                }
            }

            Rectangle{
                color: "grey"
                anchors.right: parent.right
                anchors.rightMargin: -10
                width: 2
                radius: width / 2
                y: longTextFlick.visibleArea.yPosition * longTextFlick.height
                height: Math.max(20, longTextFlick.visibleArea.heightRatio * longTextFlick.height)
            }
        } // Item
    } // Rectangle
}
