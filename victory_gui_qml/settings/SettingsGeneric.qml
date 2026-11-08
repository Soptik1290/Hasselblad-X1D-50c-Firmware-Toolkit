import QtQuick 2.0
import com.hasselblad.settings 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.upgrade 1.0
import com.hasselblad.config 1.0
import com.hasselblad.storage 1.0
import com.hasselblad.video 1.0
import com.hasselblad.suc 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.lens 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.bodysync 1.0
import "qrc:///"
import "qrc:///components"
import "qrc:///components/buttons"
import "qrc:///settings/components"
import "qrc:///settings/scripts/MenuItemImporter.js" as MenuItems
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    objectName: "SettingsGeneric_root"
    id: root
    color: constants.menuBackgroundColor
    property string upperMenuLabel
    property string menuLabel
    property int itemTextSize: constants.itemTextSize
    property int itemSpacing: 20
    property int textOffsetToLeft: 100
    property int leftMarginForItems: constants.leftMarginForItems
    property int heightForItemList: listViewArea.height
    property real maxVisibleItems: 4.5
    property int heightForItem: listViewArea.height / maxVisibleItems
    property int headerVerticalOffset: constants.headerVerticalOffset
    property bool preventSwipe: subDialog.active || dropDownSelector.visible
    property var itemValues
    function populateModel(newItemValues)
    {
        listModel.clear();
        itemValues = newItemValues
        var sectionName = ""
        var settingsList = MenuItems.getSettingsList(newItemValues);
        var numberOfItems = 0;
        settingsList.forEach(function(v) {
            if(v.editType === MenuItems.SettingType.SUBHEADER) {
                sectionName = v.text1
                numberOfItems++
            }
            else
            {
                var isDemo = (typeof v.demo !== 'undefined') && (v.demo !== undefined) && v.demo;
                var isValid = (typeof v.validCheck === 'undefined') || (v.validCheck === undefined) || (v.validCheck === "") || eval(v.validCheck)
                var isEnabled = (v.editType !== MenuItems.SettingType.TEXT) || (typeof v.enableCond === 'undefined') || (v.enableCond === undefined) || (v.enableCond === "") || eval(v.enableCond)
                if (isValid && isEnabled && (!isDemo || !guiconfig.hideDemoItems)) {
                    listModel.append({ "editType": v.editType, "name": v.name, "text1": v.text1, "text2": v.text2, "suppressUnitOn": v.suppressUnitOn, "enableCond": v.enableCond, "proxy": v.proxy, "demo": v.demo, "sectionName": sectionName, "validCheck": v.validCheck })
                    if ((newItemValues === "generalSettingsPowerTimeouts") &&
                            ((configstore.GUI_idle_timeout === 0) && (v.text2 === qsTranslate("MENUS", "s")) ||
                             (configstore.SYS_standby_idle_timeout === 0) && (v.text2 === qsTranslate("MENUS", "m")))) {
                        listModel.setProperty(listModel.count-1, "text2", "")
                    }
                    if ((newItemValues === "generalSettingsDisplay") &&
                            ((configstore.EVFPreviewTimeout === 0 || configstore.EVFPreviewTimeout === -1))) {
                        listModel.setProperty(listModel.count-1, "text2", "")
                    }
                    if ((newItemValues === "cameraSettingsInterval") && (v.name === "IntervalDelayTime") &&
                            ((configstore.IntervalDelayTime === 0 || configstore.IntervalDelayTime === 255))) {
                        listModel.setProperty(listModel.count-1, "text2", "")
                    }
                    numberOfItems++
                }
            }
        });
        if(sectionName !== "") {
            list.section.property = "sectionName"
        }
        root.heightForItemList = root.heightForItem * Math.min(numberOfItems, maxVisibleItems);
    }
    Rectangle {
        id: viewEndLine
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: constants.viewEndLineWidth
    }
    Item {
        id: listViewArea
        anchors {
            top: header.bottom
            left: viewEndLine.right
            right: root.right
            bottom: root.bottom
        }
        MouseArea {
            anchors.fill: parent
        }
    }
    Timer {
        id: listTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: list.highlightAllow = false
    }
    function startMenuWheelTimeout()
    {
        listTimer.restart();
    }
    function stopMenuWheelTimeout()
    {
        listTimer.stop();
    }
    function scrollToItem(itemName)
    {
        var index = 0
        for (var i = 0; i < listModel.count; i++) {
            if (listModel.get(i).name === itemName) {
                index = i
                break
            }
        }
        list.currentIndex = index
        list.positionViewAtIndex(index, ListView.Beginning)
    }
    ListView {
        objectName: "SettingsGeneric_list"
        id: list
        clip: true
        interactive: contentHeight > height
        boundsBehavior: guiconfig.isRunningSimulation() ? Flickable.StopAtBounds : (Flickable.DragOverBounds | Flickable.CustomBounds)
        BoundsEffectGradient {
            parent: list
            fadeColor: constants.hblOrange
        }
        height: root.heightForItemList
        anchors {
            verticalCenter: listViewArea.verticalCenter
            left: listViewArea.left
            right: listViewArea.right
        }
        focus: true
        model: listModel
        currentIndex: -1
        property int lastIndex: -1
        Keys.onPressed: {
            if(MKeys.pressedFnAcc("NAVUP", event) || (guiconfig.isWedge && MKeys.pressedFn("LEFT", event.key))) {
                startMenuWheelTimeout()
                list.highlightAllow = true
                if(-1 != currentIndex || -1 == lastIndex)
                    decrementCurrentIndex()
                else
                    currentIndex = lastIndex
                lastIndex = currentIndex
            } else if(MKeys.pressedFnAcc("NAVDOWN", event) || (guiconfig.isWedge && MKeys.pressedFn("RIGHT", event.key))) {
                startMenuWheelTimeout();
                list.highlightAllow = true
                if(-1 != currentIndex || -1 == lastIndex)
                    incrementCurrentIndex()
                else
                    currentIndex = lastIndex
                lastIndex = currentIndex
            } else if(MKeys.pressedFnAcc("SELECT", event)) {
                if(list.highlightAllow)
                {
                    stopMenuWheelTimeout();
                }
                else
                {
                    list.highlightAllow = true
                    if(lastIndex == -1)
                    {
                        lastIndex = 0
                    }
                    currentIndex = lastIndex
                    startMenuWheelTimeout();
                }
            } else {
                event.accepted = false
            }
        }
        section.delegate:
            Item {
            width: list.width
            height: root.heightForItem
            Rectangle {
                id: line
                color: "white"
                height: 2
                anchors {
                    verticalCenter: subHeaderText.verticalCenter
                    left: parent.left
                    right: parent.right
                }
            }
            Rectangle {
                color: "black"
                height: line.height
                width: subHeaderText.contentWidth + 30
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: line.bottom
                }
            }
            Text {
                id: subHeaderText
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    leftMargin: leftMarginForItems
                    rightMargin: leftMarginForItems
                }
                text: section
                font.family: constants.menuSubHeaderFontName
                font.pixelSize: constants.sectionHeaderTextSize
                fontSizeMode: Text.HorizontalFit
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: constants.menuSubMenuColor
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if(typeof index != 'undefined')
                    {
                        list.currentIndex = index
                    }
                }
            }
        }
        delegate: baseDelegate
        property bool highlightAllow: false
        highlightMoveDuration: constants.highlightMoveDuration
        highlight: Rectangle {
            color: constants.popupBackgroundColor
            Rectangle {
                color: list.highlightAllow ? constants.highlightColor : constants.popupBackgroundColor
                anchors.fill: parent
            }
        }
        Component {
            id: baseDelegate
            Item {
                objectName: "baseItem"
                id: baseItem
                DemoMarker {
                    anchors.fill: parent
                    showMarker: (typeof demo !== 'undefined') && (demo !== null) && (demo === true)
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: list.currentIndex = index
                }
                width: list.width
                height: root.heightForItem
                Loader {
                    objectName: "specialItem"
                    id: specialItem
                    asynchronous: true
                    visible: status == Loader.Ready
                    Keys.onReturnPressed: {
                        console.log("Return pressed in loader");
                        event.accepted = true
                    }
                    anchors {
                        left: baseItem.left
                        right: baseItem.right
                        top: baseItem.top
                        bottom: baseItem.bottom
                        leftMargin: leftMarginForItems
                    }
                    sourceComponent: {
                        switch(editType) {
                        case MenuItems.SettingType.DROPDOWN:     return dropdDownDelegate
                        case MenuItems.SettingType.CHECKBOX:     return checkboxDelegate
                        case MenuItems.SettingType.BUTTON:       return buttonDelegate
                        case MenuItems.SettingType.BOOL:         return boolDelegate
                        case MenuItems.SettingType.SLIDER:       return sliderDelegate
                        case MenuItems.SettingType.EDITTEXT:     return editTextDelegate
                        case MenuItems.SettingType.TEXT:         return textDelegate
                        case MenuItems.SettingType.TEXTBUTTON:   return textButtonDelegate
                        }
                    }
                    onLoaded: item.focus = baseItem.ListView.isCurrentItem
                }
                Keys.onPressed: {
                    event.accepted = false
                    if(MKeys.pressedFn("SELECT", event.key)) {
                        if(list.highlightAllow)
                        {
                            specialItem.item.gotSelected();
                        }
                    }
                }
                Component {
                    id: dropdDownDelegate
                    Item {
                        objectName: "dropDownItem"
                        id:dropdDownItem
                        property bool isEnabled: {
                            if((typeof enableCond !== 'undefined'))
                            {
                                return eval(enableCond) !== false
                            }
                            else
                            {
                                return true
                            }
                        }
                        function gotSelected()
                        {
                            if (!isEnabled)
                                return
                            dropDownSelector.open(list, proxy, name)
                        }
                        Text {
                            id: dropDownText
                            anchors {
                                right: parent.horizontalCenter
                                rightMargin: constants.subSettingDropDownXMargin
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: guiconfig.isLatin(text) ? (dropDownText.contentHeight - baselineOffset * dropDownText.contentHeight / implicitHeight) * 0.5 : 0
                            }
                            text: qsTranslate("MENUS", text1) + ":" + guiconfig.emptyString
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            font.family: constants.menuItemFontName
                            font.pixelSize: itemTextSize
                            color: dropdDownItem.isEnabled ? constants.menuItemColor : "grey"
                            fontSizeMode: Text.HorizontalFit
                        }
                        Rectangle {
                            id: dropDownBox
                            color: comboText.text == "" ? "red" : "transparent"
                            width: constants.comboBoxWidth
                            height: constants.dropDownBoxHeight
                            anchors {
                                left: dropDownText.right
                                leftMargin: constants.subSettingDropDownSpacing
                                verticalCenter: parent.verticalCenter
                            }
                            Text {
                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                    verticalCenterOffset: guiconfig.isLatin(text) ? (comboText.contentHeight - baselineOffset * comboText.contentHeight / implicitHeight) * 0.5 : 0
                                }
                                id: comboText
                                font.family: constants.menuItemFontName
                                font.pixelSize: itemTextSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                color: dropdDownItem.isEnabled ? "white" : "grey"
                                text: Settings.getDisplayValue(name, proxy[name]) + guiconfig.emptyString
                                width: dropDownText2.visible ? implicitWidth : dropdDownItem.width - (dropDownBox.x - dropdDownItem.x) - constants.subSettingDropDownSpacing
                                fontSizeMode: dropDownText2.visible ? Text.FixedSize : Text.HorizontalFit
                            }
                            Text {
                                id: dropDownText2
                                anchors {
                                    left: comboText.right
                                    leftMargin: constants.subSettingDropDownSecondTextSpacing
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    verticalCenterOffset: guiconfig.isLatin(text) ? (dropDownText2.contentHeight - baselineOffset * dropDownText2.contentHeight / implicitHeight) * 0.5 : 0
                                }
                                visible: (typeof text2 != 'undefined') && (text2 != null) && (text2 != "")
                                text: (typeof suppressUnitOn != 'undefined' && suppressUnitOn === Settings.getUntranslatedDisplayValue(name, proxy[name])) ? "" : (typeof text2 != 'undefined') && (text2 != null) ? text2 : "Should not see this"
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                font.family: constants.menuItemFontName
                                font.pixelSize: itemTextSize
                                fontSizeMode: Text.HorizontalFit
                                color: dropdDownItem.isEnabled ? constants.menuItemColor : "grey"
                            }
                        }
                        MouseArea {
                            anchors.left: dropDownText.left
                            anchors.right: dropDownBox.right
                            anchors.top: dropDownBox.top
                            anchors.bottom: dropDownBox.bottom
                            enabled: dropdDownItem.isEnabled
                            onPressAndHold: {}
                            onClicked: gotSelected()
                            onPressed: {
                                list.highlightMoveDuration = 0
                                list.currentIndex = index
                                list.highlightAllow = true
                            }
                            onReleased: {
                                list.highlightMoveDuration = constants.highlightMoveDuration
                                if(!containsMouse)
                                    list.highlightAllow = false
                            }
                            onExited: { list.highlightAllow = dropDownSelector.visible || containsMouse }
                            onEntered: list.highlightAllow = true
                            onCanceled: {
                                list.highlightMoveDuration = constants.highlightMoveDuration
                                if(list.focus) {
                                    list.highlightAllow = false
                                }
                            }
                        }
                    }
                }
                Component {
                    id: checkboxDelegate
                    Item {
                        objectName: "checkBoxDelegate"
                        property bool isEnabled: {
                            if((typeof enableCond !== 'undefined'))
                            {
                                return eval(enableCond) !== false
                            }
                            else
                            {
                                return true
                            }
                        }
                        function gotSelected()
                        {
                            if (!isEnabled)
                                return
                            switch(name) {
                            case "ram_only_mode":
                                if(!proxy[name]) {
                                    subDialog.setSource("qrc:///components/GenericConfirm.qml", { "largeHeaderText" : true, "headerText" : text1 + '?'  , "infoText" : text2, "rightText" : qsTr("Deactivate") })
                                    subDialog.active = true
                                    subDialogMA.allowSubDialogSwipe = false
                                }
                                else
                                    proxy[name] = false
                                break;
                            default:
                                proxy[name] = !proxy[name];
                                break;
                            }
                        }
                        SettingCheckBox {
                            width: parent.width
                            height: parent.height
                            boxSize: constants.checkBoxSize
                            id: checkBox
                            anchors.verticalCenter: parent.verticalCenter
                            checkboxText: text1
                            itemSpacing: root.itemSpacing
                            value: proxy[name]
                            onCheckChange: parent.gotSelected()
                            isEnabled: parent.isEnabled
                        }
                        Connections {
                            target: subDialog.item
                            onLeftSelected: proxy[name] = false
                            onRightSelected: proxy[name] = true
                        }
                    }
                }
                Component {
                    id: buttonDelegate
                    Item {
                        objectName: "buttonDelegate"
                        id: delegate_item
                        property string customProfile : ""
                        property bool fwRetryPressed : false
                        property bool isEnabled: {
                            if((typeof enableCond !== 'undefined'))
                            {
                                return eval(enableCond) !== false
                            }
                            else
                            {
                                return true
                            }
                        }
                        function gotSelected()
                        {
                            if (!isEnabled)
                                return
                            switch(name)
                            {
                            case "liveViewStart":
                                Camera.setLiveViewState(true)
                                break;
                            case "saveLogData":
                                if((ContentModel.card0Status !== ContentModel.STORAGE_ABSENT) || (ContentModel.card1Status !== ContentModel.STORAGE_ABSENT))
                                {
                                    System.collectLogs()
                                    subDialog.setSource("qrc:///components/popups/PopoverBusy.qml", {"heading": "<font color=\"" + constants.menuHighlightColor + "\">" + qsTranslate("MENUS", "GENERAL SETTINGS") + ":</font> &nbsp;" + qsTranslate("MENUS", "SERVICE"),
                                                            "centerText": qsTr("Saving log"),
                                                            "icon": "qrc:///icons/exclamationMark.png",
                                                            "bottomText": qsTr("Do not remove card!")})
                                    subDialog.active = Qt.binding(function() { return System.collecting_logs !== 0 })
                                    subDialogMA.allowSubDialogSwipe = false
                                }
                                else
                                {
                                    subDialog.setSource("qrc:///settings/NotificationMessage.qml", { "headingText": qsTr("No card available.<br\> Can not save log file."), "showtime" : 4000 })
                                    subDialog.active = true
                                    subDialogMA.allowSubDialogSwipe = true
                                }
                                break;
                            case "fwUpdateRetry":
                                fwRetryPressed = true
                                subDialog.setSource("qrc:///components/GenericConfirm.qml", { "largeHeaderText" : true, "headerText" : text1 + '?' , "rightText" : qsTr("Retry") })
                                subDialog.active = true
                                subDialogMA.allowSubDialogSwipe = false
                                break;
                            case "cardFormatCard0":
                                if(ContentModel.card0Status !== ContentModel.STORAGE_ABSENT)
                                {
                                    subDialog.setSource("qrc:///common/CardFormat.qml", {"cardToFormat": Config.Card0,  "subText": text2})
                                    subDialog.active = true
                                }
                                else
                                {
                                    subDialog.setSource("qrc:///settings/NotificationMessage.qml", { "headingText": qsTr("No card available.<br\> Can not format card."), "showtime" : 4000 })
                                    subDialog.active = true
                                }
                                subDialogMA.allowSubDialogSwipe = false
                                break;
                            case "cardFormatCard1":
                                if(ContentModel.card1Status !== ContentModel.STORAGE_ABSENT)
                                {
                                    subDialog.setSource("qrc:///common/CardFormat.qml", {"cardToFormat": Config.Card1,  "subText": text2})
                                    subDialog.active = true
                                }
                                else
                                {
                                    subDialog.setSource("qrc:///settings/NotificationMessage.qml", { "headingText": qsTr("No card available.<br\> Can not format card."), "showtime" : 4000 })
                                    subDialog.active = true
                                }
                                subDialogMA.allowSubDialogSwipe = false
                                break;
                            case "checkForUpdate":
                                subDialog.setSource("qrc:///components/popups/UpgradeCheck.qml")
                                subDialog.active = true
                                subDialogMA.allowSubDialogSwipe = false
                                break;
                            case "defaultSettings":
                                confirmDialog.setSource("qrc:///settings/ConfirmDefaultSettings.qml", { })
                                confirmDialog.active = true
                                break;
                            case "resetFileCounter":
                                confirmDialog.setSource("qrc:///settings/ConfirmResetImageCounter.qml", { })
                                confirmDialog.active = true
                                break;
                            case "saveCustomMode1":
                            case "saveCustomMode2":
                            case "saveCustomMode3":
                                customProfile = "c" + String(name).substring(String(name).length - 1)
                                subDialog.setSource("qrc:///components/GenericConfirm.qml", { "largeHeaderText" : true, "headerText" : qsTr("Save to ") + customProfile.toUpperCase() + "?", "infoText" : qsTr("Previous settings will be overwritten!"), "rightText" : qsTr("Save") })
                                subDialog.active = true
                                subDialogMA.allowSubDialogSwipe = false
                                break;
                            case "License":
                                subDialog.setSource("qrc:///settings/LicenseViewer.qml", {"headingText": "<font color=\"" + constants.menuHighlightColor + "\">" + qsTranslate("MENUS", "GENERAL SETTINGS") + ":</font> &nbsp;" + qsTranslate("MENUS", "LICENSES") })
                                subDialog.active = true
                                subDialogMA.allowSubDialogSwipe = true
                                break;
                            case "Certification":
                                subDialog.setSource("qrc:///settings/CertificationScreen.qml", {"headingText": "<font color=\"" + constants.menuHighlightColor + "\">" + qsTranslate("MENUS", "GENERAL SETTINGS") + ":</font> &nbsp;" + qsTranslate("MENUS", "CERTIFICATION"),
                                                        "contentText1": qsTranslate("MENUS", "CONTAINS FCC ID: 2AEFAX1311<br>CONTAINS IC: 20193-X1311"),
                                                        "contentText2": qsTranslate("MENUS", "CONTAINS"),
                                                        "contentText3": qsTranslate("MENUS", "007-AE0260"),
                                                        "contentText4": qsTranslate("MENUS", "TA-2016/2340"),
                                                        "image1Source": "qrc:///icons/Cert_Korea.png", "image2Source": "qrc:///icons/Cert_ICASA.png"})
                                subDialog.active = true
                                break;
                            case "Usage":
                                activateSettingsSubMenu("generalSettingsUsage", "SettingsGeneric.qml", "Usage")
                                break;
                            default:
                                console.log("You Rang???")
                                break;
                            }
                        }
                        MenuButton {
                            objectName: "buttonDelegate_menuButton"
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                            }
                            maxWidth: parent.width
                            text: text1
                            isEnabled: { return (typeof enableCond === 'undefined') ? true : eval(enableCond) }
                            fontPixelSize: itemTextSize
                            spacing: leftMarginForItems
                            borderColor: (index === list.currentIndex && list.highlightAllow) ? (mousePressed ? constants.buttonBorderPressedHighlightColor : constants.buttonBorderHighlightColor) : constants.buttonBorderColor
                            onClicked: {
                                list.currentIndex = index
                                gotSelected()
                            }
                        }
                        Connections {
                            target: farm
                            onResetGlobalImageSequenceCounterSucceeded: {
                                informDialog.timeVisible = 0
                                informDialog.title = qsTr("Image Sequence Reset")
                                informDialog.info = qsTr("The image sequence number was reset.") +
                                        (newDir !== "" ? (qsTr("<br><br>New folder is:<br>") + newDir) : "")
                                informDialog.buttonText = qsTr("OK")
                                informDialog.visible = true
                            }
                        }
                        Connections {
                            target: delegate_item.customProfile.length > 0 ? subDialog.item : null
                            onRightSelected: {
                                console.log("triggering save of " + delegate_item.customProfile + " profile")
                                configstore.saveDbTemplateFromCurrent(delegate_item.customProfile)
                                informDialog.timeVisible = 4000
                                informDialog.title = qsTr("Custom mode saved")
                                informDialog.info = qsTr("Saved to Mode %1").arg(delegate_item.customProfile.toUpperCase())
                                informDialog.buttonText = qsTr("OK")
                                informDialog.visible = true
                                delegate_item.customProfile = ""
                            }
                        }
                        Connections {
                            target: delegate_item.fwRetryPressed ? subDialog.item : null
                            onRightSelected: Upgrader.upgradeNodes()
                        }
                    }
                }
                Component {
                    id: boolDelegate
                    Item {
                        objectName: "boolDelegate"
                        property bool isEnabled: {
                            if((typeof enableCond !== 'undefined'))
                            {
                                return eval(enableCond) !== false
                            }
                            else
                            {
                                return true
                            }
                        }
                        function gotSelected()
                        {
                            if (!isEnabled)
                                return
                            if(toggleControl.value)
                            {
                                indicator.x = toggleControl.minXForIndicator
                                proxy[name] = false
                            }
                            else
                            {
                                indicator.x  = toggleControl.maxXForIndicator
                                proxy[name] = true
                            }
                        }
                        Text {
                            id: boolText
                            anchors {
                                right: parent.horizontalCenter
                                rightMargin: constants.subSettingDropDownXMargin
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: guiconfig.isLatin(text) ? (implicitHeight - baselineOffset) * 0.4 : 0
                            }
                            text: text1 + ":"
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            font.family: constants.menuItemFontName
                            font.pixelSize: itemTextSize
                            color: constants.menuItemColor
                            fontSizeMode: Text.HorizontalFit
                        }
                        Rectangle {
                            id: toggleControl
                            property bool value: proxy[name]
                            property int maxXForIndicator: width - indicator.width - border.width
                            property int minXForIndicator: toggleControl.border.width
                            anchors {
                                left: boolText.right
                                leftMargin: constants.subSettingDropDownSpacing
                                verticalCenter: parent.verticalCenter
                            }
                            radius: height / 2
                            height: 48
                            width: 90
                            color: value ? constants.boolSwitchOnColor : constants.boolSwitchOffColor
                            border.color: constants.boolSwitchBorderColor
                            border.width: 4
                            Rectangle {
                                id: indicator
                                height: parent.height - parent.border.width * 2
                                width: height
                                radius: height / 2
                                color: constants.boolSwitchButtonColor
                                border.color: parent.color
                                border.width: parent.border.width
                                anchors.verticalCenter: parent.verticalCenter
                                x: parent.value ? toggleControl.maxXForIndicator : toggleControl.minXForIndicator
                            }
                            MouseArea {
                                anchors.fill: toggleControl
                                drag {
                                    target: indicator
                                    axis: Drag.XAxis
                                    minimumX: toggleControl.minXForIndicator
                                    maximumX: toggleControl.maxXForIndicator
                                    threshold: constants.dragThreshold
                                }
                                drag.onActiveChanged: {
                                    if (!drag.active) {
                                        if(indicator.x < (toggleControl.maxXForIndicator / 2))
                                        {
                                            indicator.x = toggleControl.minXForIndicator
                                            proxy[name] = false
                                        }
                                        else
                                        {
                                            indicator.x  = toggleControl.maxXForIndicator
                                            proxy[name] = true
                                        }
                                    }
                                }
                                onClicked: {
                                    console.log("Toggle button clicked")
                                    if(indicator.x < (toggleControl.maxXForIndicator / 2))
                                    {
                                        indicator.x = toggleControl.maxXForIndicator
                                        proxy[name] = true
                                    }
                                    else
                                    {
                                        indicator.x  = toggleControl.minXForIndicator
                                        proxy[name] = false
                                    }
                                }
                            }
                        }
                    }
                }
                Component {
                    id: sliderDelegate
                    Item {
                        id: sliderItem
                        objectName: "sliderDelegate"
                        function gotSelected()
                        {
                        }
                        property bool isEnabled: {
                            if((typeof enableCond !== 'undefined'))
                            {
                                return eval(enableCond) !== false
                            }
                            else
                            {
                                return true
                            }
                        }
                        anchors.fill: parent
                        Text {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: constants.subSettingYOffset
                                left: parent.left
                                right: parent.horizontalCenter
                                rightMargin: itemSpacing / 2 + textOffsetToLeft
                            }
                            text: text1 + ":"
                            verticalAlignment: Text.AlignVCenter
                            font.family: constants.menuItemFontName
                            font.pixelSize: itemTextSize
                            fontSizeMode: Text.HorizontalFit
                            color: sliderItem.isEnabled ? constants.menuItemColor : "grey"
                        }
                        SettingSlider {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.horizontalCenter
                                leftMargin: itemSpacing / 2 - textOffsetToLeft
                                right: parent.right
                                rightMargin: leftMarginForItems
                            }
                            enabled:  sliderItem.isEnabled
                            value: proxy[name]
                            minValue: Settings.getMinValue(name);
                            maxValue: Settings.getMaxValue(name);
                            stepValue: Settings.getStepsForValue(name)
                            onValueChanged: proxy[name] = value
                        }
                    }
                }
                Component {
                    id: editTextDelegate
                    Row{
                        objectName: "editTextDelegate"
                        function gotSelected()
                        {
                        }
                        spacing: itemSpacing
                        Text {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: constants.subSettingYOffset
                            }
                            text: text1 + ":"
                            verticalAlignment: Text.AlignVCenter
                            font.family: constants.menuItemFontName
                            font.pixelSize: itemTextSize
                            fontSizeMode: Text.HorizontalFit
                            color: constants.menuItemColor
                        }
                    }
                }
                Component {
                    id: textDelegate
                    Item {
                        objectName: "textDelegate"
                        function gotSelected()
                        {
                        }
                        anchors.left: parent.left
                        Text {
                            id: constantText
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: guiconfig.isLatin(text) ? (implicitHeight - baselineOffset) * 0.4 : 0
                            }
                            text: text1.trim() + " "
                            font.pixelSize: itemTextSize
                            fontSizeMode: Text.HorizontalFit
                            color: constants.menuItemColor
                        }
                        Text {
                            anchors {
                                left: constantText.right
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: guiconfig.isLatin(text) ? (implicitHeight - baselineOffset) * 0.4 : 0
                            }
                            text: Settings.getDisplayValue(name, proxy[name]) + guiconfig.emptyString
                            font.pixelSize: itemTextSize
                            fontSizeMode: Text.HorizontalFit
                            color: constants.menuItemColor
                        }
                    }
                }
                Component {
                    id: textButtonDelegate
                    Item {
                        objectName: "textButtonDelegate"
                        function gotSelected()
                        {
                            switch(name)
                            {
                            case "versionID":
                                guiconfig.wantToSeeFWUpdateRetryClicked();
                                break;
                            default:
                                console.log("You Rang???")
                                break;
                            }
                        }
                        anchors.left: parent.left
                        Text {
                            id: constantText
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: guiconfig.isLatin(text) ? (implicitHeight - baselineOffset) * 0.4 : 0
                            }
                            text: text1.trim() + " "
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: itemTextSize
                            fontSizeMode: Text.HorizontalFit
                            color: constants.menuItemColor
                        }
                        Text {
                            id: constantValue
                            anchors {
                                left: constantText.right
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: guiconfig.isLatin(text) ? (implicitHeight - baselineOffset) * 0.4 : 0
                            }
                            text: proxy[name]
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: itemTextSize
                            fontSizeMode: Text.HorizontalFit
                            color: constants.menuItemColor
                        }
                        MouseArea {
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: constantText.left
                                right: constantValue.right
                            }
                            onClicked: parent.gotSelected()
                        }
                    }
                }
            }
        }
    }
    Connections {
        target: guiconfig
        onShowSecretMenuItemsChanged: {
            if(guiconfig.showSecretMenuItems)
            {
                subDialog.setSource("qrc:///settings/NotificationMessage.qml", { "headingText": qsTr("Additional functions now<br>available in Service Menu"), "showtime" : 4500, "capitalization": Font.MixedCase })
                subDialog.active = true
            }
        }
    }
    Rectangle {
        id: topGradient
        visible: !list.highlightAllow || list.currentIndex === -1 || list.currentItem.mapToItem(null, 0, 0).y > 80
        anchors {
            top: parent.top
            left: viewEndLine.right
            right: parent.right
        }
        height: header.height + constants.headerVerticalOffset + 30
        gradient: Gradient {
            GradientStop { position: 0.0; color: "black" }
            GradientStop { position: (header.height + constants.headerVerticalOffset) / topGradient.height; color: "black" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    Rectangle {
        visible: !list.highlightAllow || list.currentIndex === -1 || list.currentItem.mapToItem(null, 0, 0).y < 340
        anchors {
            bottom: parent.bottom
            left: viewEndLine.right
            right: parent.right
        }
        height: 30
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "black" }
        }
    }
    Text {
        id: header
        anchors {
            left: viewEndLine.right
            right: parent.right
            top: parent.top
            topMargin: headerVerticalOffset
        }
        text: "<font color=\"" + constants.menuHighlightColor + "\">"
              + qsTranslate("MainScreen", upperMenuLabel).toLocaleUpperCase()
              + ":</font> &nbsp;"
              + qsTranslate("MENUS", menuLabel).toLocaleUpperCase()
              + guiconfig.emptyString
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        font.capitalization: Font.AllUppercase
    }
    ListSelectorSettings {
        anchors.left: viewEndLine.right
        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.right: root.right
        popupAnchor {
            topMargin: 82
            leftMargin: 113
            rightMargin: 113
            bottomMargin: 82
        }
        id: dropDownSelector
        onVisibleChanged: {
            console.log("dropDownSelector visible changed:", visible)
            if (!visible) {
                list.highlightAllow = false
                var oldCurrentIndex = list.currentIndex
                var oldY = list.contentY - list.originY
                list.contentY = list.originY
                root.populateModel(itemValues)
                for (var i = 0; i < 10; i++) {
                    if (list.contentY === list.originY + oldY) {
                        break;
                    }
                    list.contentY = list.originY + oldY
                }
                list.currentIndex = oldCurrentIndex
                oldY = list.contentY
                list.contentY--
                list.contentY = oldY
                list.contentY++
                list.contentY = oldY
            }
        }
        Connections {
            target: configstore
            onExpModeChanged: {
                dropDownSelector.close()
            }
        }
        Connections {
            target: Lens
            onLens_familyChanged: {
                dropDownSelector.close()
                root.populateModel(itemValues)
            }
        }
    }
    GenericInform {
        objectName: "informDialog"
        id: informDialog
        visible: false
        onVisibleChanged: {
            if(visible)
            {
                informDialog.forceActiveFocus()
            }
            else
            {
                list.forceActiveFocus()
            }
        }
    }
    function activateSettingsSubMenu(settingsList, itemFile, label)
    {
        subDialog.itemValues = settingsList
        subDialog.source = itemFile
        subDialog.upperMenuLabel = header.text
        subDialog.menuLabel = label
        subDialog.active = true
    }
    MouseArea {
        id: subDialogMA
        anchors {
            top: root.top
            bottom: root.bottom
            right: root.right
            left: root.left
        }
        enabled: subDialog.active && allowSubDialogSwipe
        z: 1
        drag {
            target: subDialog
            axis: Drag.XAxis
            minimumX: root.x
            maximumX: root.x + root.width
            threshold: constants.dragThreshold
            filterChildren: true
        }
        drag.onActiveChanged: {
            if (!drag.active) {
                if (drag.target.x > (root.x - root.width / constants.swipeLengthDividor))
                {
                    subDialog.closeSubDialog()
                    subDialog.x = root.x + root.width
                }
                else
                    subDialog.x = root.x
            }
        }
        property bool allowSubDialogSwipe: true
        Loader {
            id: subDialog
            objectName: "subDialogLoader"
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            x: parent.x + parent.width
            width: parent.width
            active: false
            visible: active
            asynchronous: true
            focus: active
            enabled: active
            property var itemValues
            property string upperMenuLabel: ""
            property string menuLabel: ""
            Behavior on x {
                NumberAnimation { easing.type: Easing.InOutQuad; duration: constants.menuSwipeDuration }
            }
            onActiveChanged: {
                if(!active)
                {
                    closeSubDialog()
                }
                else
                    x = root.x
            }
            function closeSubDialog()
            {
                console.log("subdialog was closed")
                subDialog.active = false
                subDialog.x = parent.x + parent.width
                list.forceActiveFocus()
                subDialogMA.allowSubDialogSwipe = true
            }
            onLoaded: {
                if(item.hasOwnProperty("populateModel") && typeof item.populateModel == 'function')
                    item.populateModel(itemValues);
                if(item.hasOwnProperty("upperMenuLabel"))
                    item.upperMenuLabel = upperMenuLabel;
                if(item.hasOwnProperty("menuLabel"))
                    item.menuLabel = menuLabel;
            }
        }
    }
    Loader {
        objectName: "confirmDialogLoader"
        anchors.fill: parent
        id: confirmDialog
        active: false
        visible: active
        asynchronous: true
        focus: active
        onActiveChanged: {
            if(!active)
            {
                confirmDialog.active = false
                list.forceActiveFocus()
                anchors.left = viewEndLine.right
            }
        }
        function closeConfirmDialog()
        {
            confirmDialog.active = false
        }
    }
    ListModel {
        id: listModel
    }
    Connections {
        target: configstore
        onFocusSizeChanged: {
            var currentSizeIndex = getSizeIndex()
            var xCount = constants.focusSizeXCount[currentSizeIndex]
            var yCount = constants.focusSizeYCount[currentSizeIndex]
            var afItemWidth = (1 - 2 * constants.focusGridXMarginPercent) / xCount
            var afItemHeight =  (1 - 2 * constants.focusGridYMarginPercent) / yCount
            var selectedXIndex = Math.floor((Camera.firstComponent(Camera.focus_point) - constants.focusGridXMarginPercent) / afItemWidth)
            var selectedYIndex = Math.floor((Camera.secondComponent(Camera.focus_point) - constants.focusGridYMarginPercent) / afItemHeight)
            if(selectedXIndex >= xCount) selectedXIndex = xCount - 1
            if(selectedYIndex >= yCount) selectedYIndex = yCount - 1
            GlobalStateInfo.afSselectedIndex =  selectedXIndex + selectedYIndex * xCount
            var xPoint = constants.focusGridXMarginPercent + (selectedXIndex + 0.5) * afItemWidth
            var yPoint = constants.focusGridYMarginPercent + (selectedYIndex + 0.5) * afItemHeight
            var focusPoint = Camera.combine(xPoint, yPoint)
            Camera.focus_point = focusPoint
        }
        function getSizeIndex() {
            for (var i = 0; i < constants.focusSize.length; i++)
            {
                if (configstore.focus_size === constants.focusSize[i])
                {
                    return i
                }
            }
            return 0
        }
    }
}
