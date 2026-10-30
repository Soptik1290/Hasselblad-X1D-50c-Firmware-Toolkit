import QtQuick 2.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.config 1.0
import com.hasselblad.systemmanager 1.0

import "qrc:///components/buttons"

Popover {
    id: popExposureMode

    property int gridspacing: constants.popupGridSpacing

    function isExpModeValid(mode) {
        var ret = ((cambody.ExpModeList & (1 << mode)) != 0);
        console.log("isExpModeValid: " + mode + " -> " + ret);
        return ret;
    }

    function openProcessing()
    {
        grid_model.clear()
        for(var i = 0; i < gridModelAllItems.count; i++)
        {
            //Do not allow change to video mode when in tethered mode
            //Allow on A6D
            if(!guiconfig.isA6D && !guiconfig.isWedge && System.isTethered && (gridModelAllItems.get(i).expMode === Config.ExpModes_Video)) {
                continue;
            }

            if(isExpModeValid(gridModelAllItems.get(i).expMode))
            {
                grid_model.append(gridModelAllItems.get(i))
            }
            else if(!guiconfig.isWedge && (gridModelAllItems.get(i).expMode === Config.ExpModes_Video) && ((cambody.capabilities & Cambody.CapabilityVideoMode) !== 0))
            {
                grid_model.append(gridModelAllItems.get(i))
            }
        }
        /* set current value based on configstore setting */
        if(!guiconfig.isWedge && (System.camera_mode === System.CameraModeVideo))
        {
            for (i = 0; i < grid_model.count; i++) {
                if (grid_model.get(i).expMode === Config.ExpModes_Video) {
                    grid.currentIndex = i;
                    break;
                }
            }
        }
        else
        {
            for (i = 0; i < grid_model.count; i++) {
                if (grid_model.get(i).expMode === configstore.ExpMode) {
                    grid.currentIndex = i;
                    break;
                }
            }
        }
    }

    onFocusChanged: if (focus) grid.focus = true

    heading: qsTr("EXPOSURE MODE") + guiconfig.emptyString

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

            cellWidth: width / 3
            cellHeight: height / 2

            function setSelected()
            {
                if(popExposureMode.visible)
                {
                    // Special case for Video
                    if((grid_model.get(grid.currentIndex).expMode === Config.ExpModes_Video) && !guiconfig.isWedge)
                    {
                        System.camera_mode = System.CameraModeVideo
                    }
                    else
                    {
                        // Make sure we are in image mode
                        if(!guiconfig.isWedge)
                        {
                            System.camera_mode = System.CameraModeImage
                        }
                        configstore.ExpMode = grid_model.get(grid.currentIndex).expMode
                    }
                    popExposureMode.close();
                }
            }

            model: grid_model
            delegate: Item {
                id: grid_delegate

                width: grid.cellWidth - gridspacing
                height: grid.cellHeight - gridspacing

                FramedImage {
                    text: qsTr(model.text) + guiconfig.emptyString
                    textColor: constants.popupTextColor
                    textWrapping: Text.WordWrap
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
            Keys.onUpPressed: moveCurrentIndexUp()
            Keys.onDownPressed: moveCurrentIndexDown()
            Keys.onLeftPressed: moveCurrentIndexLeft()
            Keys.onRightPressed: moveCurrentIndexRight()

        }

        ListModel {
            id: grid_model
        }

        ListModel {
            id: gridModelAllItems
            ListElement {
                // M
                icon: "qrc:///icons/ExpMode_Manual.png"
                text: QT_TR_NOOP("Manual")
                expMode: Config.ExpMode_Manual
            }
            ListElement {
                // A
                icon: "qrc:///icons/ExpMode_Aperture.png"
                text: QT_TR_NOOP("Aperture")
                expMode: Config.ExpMode_Aperture
            }
            ListElement {
                // S
                icon: "qrc:///icons/ExpMode_Shutter.png"
                text: QT_TR_NOOP("Shutter")
                expMode: Config.ExpMode_ShutterSpeed
            }
            ListElement {
                // P
                icon: "qrc:///icons/ExpMode_Program.png"
                text: QT_TR_NOOP("Program")
                expMode: Config.ExpMode_Program
            }
            ListElement {
                // Pv
                icon: "qrc:///icons/ExpMode_ProgramV.png"
                text: QT_TR_NOOP("Program Variable")
                expMode: Config.ExpMode_ProgramVariable
            }
            ListElement {
                // V
                icon: "qrc:///icons/ExpMode_Video.png"
                text: QT_TR_NOOP("Video")
                expMode: Config.ExpModes_Video
            }
        }
    }
}
