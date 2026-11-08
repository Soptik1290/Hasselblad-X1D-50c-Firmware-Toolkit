import QtQuick 2.0

import com.hasselblad.settings 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.camera 1.0

import "qrc:///scripts/Keys.js" as MKeys

Item {
    property alias showIsoList: isoList.visible
    property alias showWbList: wbList.visible
    enabled: isoList.visible || wbList.visible
    id: root

    // Show either nothing, ISO selector, or WB selector

    // Arrows indicating if it is possible to use left/right keys
    Image {
        id: leftArrow
        source: "qrc:///icons/EVF_ArrowLeft.png"
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: (isoList.visible && (isoList.count > 0) && (isoList.currentIndex > 0)) ||
                 (wbList.visible && (wbList.count > 0) && (wbList.currentIndex > 0))
        width: implicitWidth * sizeFactor
        height: implicitHeight * sizeFactor
    }
    Image {
        id: rightArrow
        source: "qrc:///icons/EVF_ArrowRight.png"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: (isoList.visible && (isoList.count > 0) && (isoList.currentIndex < (isoList.count - 1))) ||
                 (wbList.visible && (wbList.count > 0) && (wbList.currentIndex < (wbList.count - 1)))
        width: implicitWidth * sizeFactor
        height: implicitHeight * sizeFactor
    }

    // ISO selector
    ListView {
        id: isoList
        visible: false
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftArrow.right
        anchors.right: rightArrow.left
        orientation: ListView.Horizontal
        clip: true
        interactive: false
        model: Settings.isoValues
        highlightMoveVelocity: 800

        function updateFocus()
        {
            if (visible) {
                isoList.focus = true;

                // Set focus on currently selected iso value in configstore
                // We do not want it to slowly "roll" to position, so we set duration
                // temporarily to 0
                var oldHighlightMoveDuration = isoList.highlightMoveDuration;
                isoList.highlightMoveDuration = 0;
                isoList.currentIndex = isoList.model.indexOf(guiconfig.fromIsoVal(Camera.iso));
                isoList.highlightMoveDuration = oldHighlightMoveDuration;
            }
        }

        onVisibleChanged: updateFocus()
        onCountChanged: updateFocus()

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: isoList.width / 3
        preferredHighlightEnd: isoList.width * 2 / 3
        highlight: Item {
            Rectangle {
                color: constants.highlightColor
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 114 * sizeFactor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        delegate: Item {
            width: isoList.width / 3
            height: isoList.height
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 7 * sizeFactor
                text: modelData
                font.pixelSize: textSize
                color: constants.cameraViewNormalTextColor
                style: Text.Outline
                styleColor: "black"
                font.family: constants.cameraControlTextFontName
            }
        }

        Connections {
            target: isoList.visible ? Camera : null
            onIsoChanged: {
                isoList.currentIndex = isoList.model.indexOf(guiconfig.fromIsoVal(Camera.iso))
            }
        }

        Keys.onPressed: {
            if(isoList.visible)
            {
                if (MKeys.pressedFnAcc("LEFT", event) || MKeys.pressedFnAcc("UP", event) || MKeys.pressedFnAcc("SQUARE", event))
                {
                    if (currentIndex > 0) {
                        Camera.iso = guiconfig.toIsoVal(model[currentIndex-1])
                    }
                }
                else if (MKeys.pressedFnAcc("RIGHT", event) || MKeys.pressedFnAcc("DOWN", event) || MKeys.pressedFnAcc("CROSS", event))
                {
                    if (currentIndex < count-1) {
                        Camera.iso = guiconfig.toIsoVal(model[currentIndex+1])
                    }
                }
                else
                {
                    event.accepted = false
                }
            }
        }

    }

    // WB Selector
    ListView {
        id: wbList
        visible: false
        property bool isSettingModel: false
        interactive: false
        highlightMoveVelocity: 800
        onVisibleChanged: {
            if(visible)
            {
                isSettingModel = true
                forceActiveFocus()
                wbList.setNewIndex()
                isSettingModel = false
            }
        }

        function setNewIndex()
        {
            var oldHighlightMoveDuration = wbList.highlightMoveDuration;
            wbList.highlightMoveDuration = 0;
            wbList.currentIndex = getCurrentModelIndex()
            wbList.highlightMoveDuration = oldHighlightMoveDuration;
        }

        function getCurrentModelIndex()
        {
            for (var iModel = 0; iModel < wbList.count; iModel++)
            {
                if (wbList.model.get(iModel).whitemode === Camera.WBMode)
                {
                    return iModel
                }
            }
            return -1
        }

        onCurrentIndexChanged: {
            if((currentIndex >= 0) && !isSettingModel && wbList.visible)
            {
                Camera.WBMode = wbList.model.get(wbList.currentIndex).whitemode;
            }
        }

        Connections {
            target: wbList.visible ? Camera : null
            onWbModeChanged: {
                wbList.isSettingModel = true
                wbList.setNewIndex()
                wbList.isSettingModel = false
            }
        }

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: leftArrow.right
        anchors.right: rightArrow.left
        orientation: ListView.Horizontal
        clip: true
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: wbList.width / 3
        preferredHighlightEnd: wbList.width * 2 / 3
        highlight: Item{
            Rectangle {
                color: constants.highlightColor
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 114 * sizeFactor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        delegate: Item {
            width: wbList.width / 3
            height: wbList.height
            // Workaround since QML does not let us easily access model data roles outside a delegate:
            property var itemModel: model
            Image {
                anchors.centerIn: parent
                source: icon
                width: implicitWidth * sizeFactor
                height: implicitHeight * sizeFactor
            }
        }

        Keys.onPressed: {
            if(wbList.visible)
            {
                if (MKeys.pressedFnAcc("LEFT", event) || MKeys.pressedFnAcc("UP", event) || MKeys.pressedFnAcc("SQUARE", event))
                {
                    decrementCurrentIndex()
                }
                else if (MKeys.pressedFnAcc("RIGHT", event) || MKeys.pressedFnAcc("DOWN", event) || MKeys.pressedFnAcc("CROSS", event))
                {
                    incrementCurrentIndex()
                }
                else
                {
                    event.accepted = false
                }
            }
        }

        model: wbModel

        ListModel {
            id: wbModel

            ListElement {
                icon: "qrc:///icons/EVF_WB_Auto.png"
                text: QT_TR_NOOP("Auto")
                whitemode: 1
                isManual: false
            }
            ListElement {
                icon: "qrc:///icons/EVF_WB_Cloudy.png"
                text: QT_TR_NOOP("Cloudy")
                whitemode: 10
                isManual: false
            }
            ListElement {
                icon: "qrc:///icons/EVF_WB_Shade.png"
                text: QT_TR_NOOP("Shade")
                whitemode: 11
                isManual: false
            }
            ListElement {
                icon: "qrc:///icons/EVF_WB_Daylight.png"
                text: QT_TR_NOOP("Daylight")
                whitemode: 2
                isManual: false
            }
            ListElement {
                icon: "qrc:///icons/EVF_WB_Tungsten.png"
                text: QT_TR_NOOP("Tungsten")
                whitemode: 3
                isManual: false
            }
            ListElement {
                icon: "qrc:///icons/EVF_WB_Fluor.png"
                text: QT_TR_NOOP("Fluorescent")
                whitemode: 4
                isManual: false
            }
            ListElement {
                icon: "qrc:///icons/EVF_WB_Flash.png"
                text: QT_TR_NOOP("Flash")
                whitemode: 5
                isManual: false
            }
            ListElement {
                icon: "qrc:///icons/EVF_WB_Manual.png"
                text: QT_TR_NOOP("Manual")
                whitemode: 6
                isManual: true
            }
        }

    }
    ListView {
        id: manualWbList
        visible: wbList.visible && wbList.currentItem && wbList.currentItem.itemModel.isManual
        clip: true
        anchors.top: wbList.bottom
        anchors.right: root.right
        anchors.left: root.left
        interactive: false

        height: 58 *sizeFactor
        property int itemWidth: 100 * sizeFactor
        property int highlightWidth: 114 * sizeFactor

        orientation: ListView.Horizontal
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - itemWidth / 2
        preferredHighlightEnd: width / 2 + itemWidth / 2
        boundsBehavior: Flickable.StopAtBounds
        property bool isSettingModel: false
        highlightMoveVelocity: 800

        onVisibleChanged: {
            console.log("manual list visible:", visible)
            if(visible)
            {
                isSettingModel = true
                manualWbList.forceActiveFocus();
                fillModel()

                // Set focus on currently selected value
                // We do not want it to slowly "roll" to position, so we set duration
                // temporarily to 0
                var oldHighlightMoveDuration = manualWbList.highlightMoveDuration;
                manualWbList.highlightMoveDuration = 0;
                manualWbList.currentIndex = findCurrentIndex()
                manualWbList.highlightMoveDuration = oldHighlightMoveDuration;
                isSettingModel = false

            }
            if(!visible)
            {
                wbManualListModel.clear()
                wbList.forceActiveFocus();
            }
        }

        onCurrentIndexChanged: {
            if((currentIndex >= 0) && !isSettingModel && manualWbList.visible)
            {
                var newVal = manualWbList.model.get(manualWbList.currentIndex).modelData
                if (configstore.WBManualTemp !== newVal && configstore.WBManualTemp % 100 !== 0) {
                    //When leaving white balance tool we should round manual WB and clear tint
                    configstore.WBManualTint = 0
                }
                configstore.WBManualTemp = manualWbList.model.get(manualWbList.currentIndex).modelData;
            }
        }


        model: wbManualListModel
        highlight: Item {
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: manualWbList.highlightWidth
                anchors.horizontalCenter: parent.horizontalCenter
                color: constants.highlightColor
            }
        }
        delegate: Item {
            height: manualWbList.height
            width: manualWbList.itemWidth
            id: wbManualItem
            Text {
                anchors.horizontalCenter: wbManualItem.horizontalCenter
                anchors.verticalCenter: wbManualItem.verticalCenter
                anchors.verticalCenterOffset: 6 * sizeFactor
                text: modelData
//                font.weight: Font.Normal
                color: wbManualItem.ListView.isCurrentItem ? constants.highlightItemColor: constants.itemColor
                font.pixelSize: 33 * sizeFactor
                style: Text.Outline
                styleColor: "black"
                font.family: constants.cameraControlTextFontName
            }
        }

        Keys.onPressed: {
            if(visible)
            {
                if (MKeys.pressedFnAcc("LEFT", event) || MKeys.pressedFnAcc("SQUARE", event))
                {
                    wbList.decrementCurrentIndex()
                }
                else if (MKeys.pressedFnAcc("RIGHT", event) || MKeys.pressedFnAcc("CROSS", event))
                {
                    wbList.incrementCurrentIndex()
                }
                else if (MKeys.pressedFnAcc("UP", event))
                {
                    decrementCurrentIndex()
                }
                else if (MKeys.pressedFnAcc("DOWN", event))
                {
                    incrementCurrentIndex()
                }
                else
                {
                    event.accepted = false
                }
            }
            else
            {
                event.accepted = false
            }
        }




        ListModel {
            id: wbManualListModel
        }
        function fillModel()
        {
            if(manualWbList.count === 0)
            {
                var manualTemp = configstore.WBManualTemp
                var step = 100;
                var whiteBalanceMin = 2000;
                var whiteBalanceMax = 10000;
                // Add values
                for (var whiteBalance = whiteBalanceMin; whiteBalance <= whiteBalanceMax; whiteBalance += step)
                {
                    wbManualListModel.append({"modelData": whiteBalance});
                    //If the manual value was set by White Balance Tool it will not follow even step size
                    if (manualTemp > whiteBalance && manualTemp < whiteBalance+step) {
                        wbManualListModel.append({"modelData": manualTemp});
                    }
                }
            }
        }
        function findCurrentIndex()
        {
            var manualTemp = configstore.WBManualTemp
            for (var currentIndex = 0; currentIndex < manualWbList.count; currentIndex ++)
            {
                var currentTemp = wbManualListModel.get(currentIndex).modelData
                if(currentTemp === manualTemp)
                {
                    return currentIndex
                }
            }
            return 0
        }

    }

}

