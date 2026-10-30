import QtQuick 2.0

import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0

import "qrc:///components/buttons"

import "qrc:///scripts/Keys.js" as MKeys

// FIXME/TODO: implement support for additional settings when using peripherals: Near, ...

Popover {
    id: popFocusMode

    property int gridspacing: constants.popupGridSpacing
    onFocusChanged: if (focus) grid.focus = true

    heading: qsTr("FOCUS MODE") + guiconfig.emptyString

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

            keyNavigationWraps: false
            boundsBehavior: Flickable.StopAtBounds


            cellWidth: width / 2
            cellHeight: height / 2
            Component.onCompleted: updateFocus()
            onCountChanged: updateFocus()
            function updateFocus() {
                /* select item as set in configstore */
                for (var i = 0; i < model.count; i++) {
                    if (model.get(i).focusmode === Camera.FocusMode)
                        currentIndex = i;
                }

            }

            function setSelected()
            {
                Camera.FocusMode = model.get(grid.currentIndex).focusmode
                popFocusMode.close();
            }


            // OBS!!!! Temporarily remove items from wedge for demo. Remove "grid_model_wedge" and expression below when done
            model: guiconfig.isWedge ? grid_model_wedge : grid_model
            delegate: Item {
                id: grid_delegate

                width: grid.cellWidth - gridspacing
                height: grid.cellHeight - gridspacing

                FramedImage {
                    text: qsTr(model.text) + guiconfig.emptyString
                    textColor: constants.popupTextColor
                    //                        bottomMargin: constants.popupBottomTextMargin
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
                Keys.onPressed: {
                    if(MKeys.pressedFnAcc("AF_MF", event))
                    {
                        grid.setSelected()
                    }
                    else
                    {
                        event.accepted = false
                    }
                }

            }

        }

        ListModel {
            id: grid_model
            ListElement {
                icon: "qrc:///icons/AF_Manual.png"
                text: QT_TR_NOOP("Manual Focus")
                focusmode: Config.Focus_MAN
            }
            ListElement {
                icon: "qrc:///icons/AF_Single.png"
                text: QT_TR_NOOP("Single Focus")
                focusmode: Config.Focus_AFS
            }
            ListElement {
                icon: "qrc:///icons/AF_Cont.png"
                text: QT_TR_NOOP("Continuous Focus")
                focusmode: Config.Focus_AFC
            }
            ListElement {
                icon: "qrc:///icons/AF_TrueFocus.png"
                text: QT_TR_NOOP("True Focus")
                focusmode: Config.Focus_AFT
            }
        }

        ListModel {
            id: grid_model_wedge
            ListElement {
                icon: "qrc:///icons/AF_Manual.png"
                text: QT_TR_NOOP("Manual Focus")
                focusmode: Config.Focus_MAN
            }
            ListElement {
                icon: "qrc:///icons/AF_Single.png"
                text: QT_TR_NOOP("Single Focus")
                focusmode: Config.Focus_AFS
            }
        }
    }
}
