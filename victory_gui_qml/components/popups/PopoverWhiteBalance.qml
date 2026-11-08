import QtQuick 2.0
import com.hasselblad.settings 1.0
import com.hasselblad.camera 1.0
import "qrc:///components/buttons"
import "qrc:///components/controls"
import "qrc:///scripts/Keys.js" as MKeys
Popover {
    id: popWhiteBalance
    property int gridspacing: constants.popupGridSpacing
    heading: qsTr("WHITE BALANCE") + guiconfig.emptyString
    contentItem: grid
    onFocusChanged: if (focus) grid.forceActiveFocus()
    function setSelected()
    {
        grid.setSelected()
    }
    function openProcessing()
    {
        grid_model.clear()
        for(var i = 0; i < grid_model_all.count; i++)
        {
            grid_model.append(grid_model_all.get(i))
        }
    }
    content: Item {
        anchors.fill: parent
        GridView {
            id: grid
            focus: true
            interactive: false
            anchors {
                fill: parent
                leftMargin: constants.popupSideMargins
                rightMargin: constants.popupSideMargins
                bottomMargin: 10
            }
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationWraps: false
            Component.onCompleted: updateFocus()
            onCountChanged: updateFocus()
            function updateFocus() {
                for (var i = 0; i < model.count; i++) {
                    if (model.get(i).whitemode === Camera.WBMode)
                        currentIndex = i;
                }
            }
            cellWidth: width / 3
            cellHeight: height / 3
            model: grid_model
            function setSelected()
            {
                Camera.WBMode = grid_model.get(grid.currentIndex).whitemode;
                popWhiteBalance.close();
            }
            delegate: Item {
                id: grid_delegate
                width: grid.cellWidth - gridspacing
                height: grid.cellHeight - gridspacing
                property bool manualTempFocus: false
                FramedImage {
                    id: delegateIcon
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
                    textWrapping: Text.WordWrap
                    acceptKeys: !manualTempFocus
                    onPressed: {
                        grid.focus = true
                    }
                    onClicked: {
                        if(whitemode === 6)
                        {
                            if(grid.currentIndex == index)
                            {
                                grid.setSelected()
                            }
                            else
                            {
                                grid.currentIndex = index
                                Camera.WBMode = grid_model.get(grid.currentIndex).whitemode;
                            }
                        }
                        else
                        {
                            grid.currentIndex = index
                            grid.setSelected()
                        }
                    }
                }
                Rectangle {
                    id: manualWbItem
                    visible: (index == grid.currentIndex) && (whitemode === 6)
                    onVisibleChanged: manualTempFocus = false
                    color: "transparent"
                    border.color: manualTempFocus ? constants.highlightColor : "transparent"
                    border.width: 2
                    anchors.left: grid_delegate.right
                    anchors.top: grid_delegate.top
                    anchors.bottom: delegateIcon.bottom
                    width: grid.cellWidth
                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 6
                        color: constants.popupTextColor
                        text: configstore.WBManualTemp + (configstore.WBManualTemp < 10000 ? " " : "") + "K"
                        font.pixelSize: 30
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.visible
                        onClicked: popManual.open(grid)
                    }
                }
                Canvas {
                    id: arrow
                    visible: manualWbItem.visible && manualTempFocus
                    anchors.right: manualWbItem.left
                    anchors.rightMargin: -manualWbItem.border.width
                    anchors.top: manualWbItem.top
                    anchors.bottom: manualWbItem.bottom
                    width: 20
                    onVisibleChanged: if(visible) requestPaint()
                    onPaint: {
                        var context = arrow.getContext("2d")
                        context.fillStyle = Qt.rgba(0, 0, 0, 1)
                        context.beginPath();
                        context.moveTo(arrow.width, manualWbItem.border.width);
                        context.lineTo(0, arrow.height / 2)
                        context.lineTo(arrow.width, arrow.height - manualWbItem.border.width)
                        context.closePath()
                        context.fill();
                    }
                }
                Keys.onPressed: {
                    if((index == grid.currentIndex) && (whitemode === 6))
                    {
                        if(MKeys.pressedFnAcc("NAVRIGHT", event))
                            manualTempFocus = true
                        else if(manualTempFocus)
                        {
                            if(MKeys.pressedFnAcc("SELECT", event))
                                popManual.open(grid)
                            else if (MKeys.pressedFnAcc("NAVLEFT", event))
                                manualTempFocus = false
                        }
                    }
                }
            }
            onCurrentIndexChanged: {
                if(grid_model.get(currentIndex).whitemode === 6)
                {
                }
            }
        }
        ListModel {
            id: grid_model
        }
        ListModel {
            id: grid_model_all
            ListElement {
                 wedge_only: true
                 icon: "qrc:///icons/WBal_Auto.png"
                 text: QT_TR_NOOP("Auto")
                 whitemode: 1
            }
            ListElement {
                icon: "qrc:///icons/WBal_Cloudy.png"
                text: QT_TR_NOOP("Cloudy")
                whitemode: 10
            }
            ListElement {
                icon: "qrc:///icons/WBal_Shade.png"
                text: QT_TR_NOOP("Shade")
                whitemode: 11
            }
            ListElement {
                icon: "qrc:///icons/WBal_Daylight.png"
                text: QT_TR_NOOP("Daylight")
                whitemode: 2
            }
            ListElement {
                icon: "qrc:///icons/WBal_Tungsten.png"
                text: QT_TR_NOOP("Tungsten")
                whitemode: 3
            }
            ListElement {
                icon: "qrc:///icons/WBal_Fluor.png"
                text: QT_TR_NOOP("Fluorescent")
                whitemode: 4
            }
            ListElement {
                icon: "qrc:///icons/WBal_Flash.png"
                text: QT_TR_NOOP("Flash")
                whitemode: 5
            }
            ListElement {
                icon: "qrc:///icons/WBal_Manual.png"
                text: QT_TR_NOOP("Manual")
                whitemode: 6
            }
        }
    }
    PopoverManualWhiteBalance {
        id: popManual
        visible: false
        anchors {
            fill: parent
        }
    }
}
