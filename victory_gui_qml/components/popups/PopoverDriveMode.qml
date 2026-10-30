import QtQuick 2.0
import com.hasselblad.camera 1.0

import "qrc:///components/buttons"

Popover {
    id: popDriveMode

    property int gridspacing: constants.popupGridSpacing

    onFocusChanged: if (focus) grid.focus = true

    heading: qsTr("DRIVE MODE") + guiconfig.emptyString

    contentItem: grid

    content: Item {
        anchors.fill: parent

        GridView {
            id: grid

            interactive: false
            anchors {
                fill: parent
                leftMargin: constants.popupSideMargins
                rightMargin: constants.popupSideMargins
                topMargin: 29
                bottomMargin: 41
            }
            boundsBehavior: Flickable.StopAtBounds

            keyNavigationWraps: false

            cellWidth: width / 2
            cellHeight: height / 2

            model: grid_model
            Component.onCompleted: updateFocus()
            onCountChanged: updateFocus()

            function updateFocus() {
                for (var i = 0; i < model.count; i++) {
                    if (model.get(i).drivemode === Camera.DriveMode) {
                        currentIndex = i;
                        break;
                    }
                }
            }

            function setSelected()
            {
                Camera.DriveMode = grid_model.get(grid.currentIndex).drivemode
                popDriveMode.close();
            }
            delegate: Item {
                id: grid_delegate

                width: grid.cellWidth - gridspacing
                height: grid.cellHeight - gridspacing

                FramedImage {
                    text: qsTr(model.text) + guiconfig.emptyString
                    textColor: constants.popupTextColor
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    focus: parent.GridView.isCurrentItem
                    source: icon
                    showInvertedFocus: true

                    onPressed: {
                        grid.focus = true
                    }
                    onClicked: {
                        grid.currentIndex = index
                        grid.setSelected()
                    }
                }
            }

        }

        ListModel {
            id: grid_model
            ListElement {
                icon: "qrc:///icons/DriveMode_Single.png"
                text: QT_TR_NOOP("Single")
                drivemode: 0
            }
            ListElement {
                icon: "qrc:///icons/DriveMode_Cont.png"
                text: QT_TR_NOOP("Continuous")
                drivemode: 1
            }
        }
    }
} // PopOver
