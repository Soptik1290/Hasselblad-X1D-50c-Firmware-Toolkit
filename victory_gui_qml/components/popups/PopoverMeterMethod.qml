import QtQuick 2.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0

import "qrc:///components/buttons"

Popover {
    id: popMeterMethod

    property int gridspacing: constants.popupGridSpacing

    function isLMModeValid(mode) {
        var ret = ((cambody.LMModeListAsInt & (1 << mode)) != 0);
        //console.log("isLMModeValid: " + mode + " -> " + ret);
        return ret;
    }

    function openProcessing()
    {
        var i = 0
        grid_model.clear()
        for(i = 0; i < gridModelAllItems.count; i++)
        {
            if(isLMModeValid(gridModelAllItems.get(i).lmmode))
            {
                grid_model.append(gridModelAllItems.get(i))
            }
        }
        /* set current value based on configstore setting */
        for (i = 0; i < grid_model.count; i++) {
            if (grid_model.get(i).lmmode === Camera.LMMode) {
                grid.currentIndex = i;
                break;
            }
        }
    }

    onFocusChanged: if (visible) grid.focus = true;

    heading: qsTr("METER METHOD") + guiconfig.emptyString

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

            model: grid_model
            function setSelected()
            {
                Camera.LMMode = grid_model.get(grid.currentIndex).lmmode
                popMeterMethod.close();
            }
            delegate: Item {
                id: grid_delegate

                width: grid.cellWidth - gridspacing
                height: grid.cellHeight - gridspacing

//                visible: popMeterMethod.isLMModeValid(model.lmmode)

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
            }

        }


        ListModel {
            id: grid_model
        }

        ListModel {
            id: gridModelAllItems
            ListElement {
                icon: "qrc:///icons/Metering_Centre.png"
                text: QT_TR_NOOP("Centre Weighted")
                lmmode: Config.LMM_CenterWeighted
            }
            ListElement {
                icon: "qrc:///icons/Metering_Spot.png"
                text: QT_TR_NOOP("Spot")
                lmmode: Config.LMM_Spot
            }
            ListElement {
                icon: "qrc:///icons/Metering_Multi.png"
                text: QT_TR_NOOP("Centre Spot")
                lmmode: Config.LMM_CentreSpot
            }
            /* FIXME: the real proper order of the below ones are unknown, should likely be resorted! Just available here to be selectable. */
            ListElement {
                icon: "qrc:///icons/Metering_None.png" // FIXME
                text: QT_TR_NOOP("Matrix")
                lmmode: Config.LMM_Matrix
            }
            ListElement {
                icon: "qrc:///icons/Metering_None.png" // FIXME
                text: QT_TR_NOOP("Average")
                lmmode: Config.LMM_Average
            }
            ListElement {
                icon: "qrc:///icons/Metering_None.png" // FIXME
                text: QT_TR_NOOP("Incident")
                lmmode: Config.LMM_Incident
            }
            ListElement {
                icon: "qrc:///icons/Metering_None.png" // FIXME
                text: QT_TR_NOOP("Extern")
                lmmode: Config.LMM_Extern
            }
        }
    }
} // PopOver
