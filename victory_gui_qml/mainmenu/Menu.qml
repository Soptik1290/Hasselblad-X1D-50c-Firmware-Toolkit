import QtQuick 2.0
import QtGraphicalEffects 1.0

// Config is needed by Keys.js...
import com.hasselblad.config 1.0
//----------------------------------------------
import "qrc:///scripts/Keys.js" as MKeys
//----------------------------------------------
import com.hasselblad.cambody 1.0
import com.hasselblad.bodysync 1.0

import "qrc:///"
import "qrc:///settings/components" // TODO: This is needed for BoundsEffectGradient. Maybe that should be moved to components in the root.

Rectangle {
    objectName: "Menu_root"
    id: root
    color: constants.menuBackgroundColor
    property string text
    property bool preventSwipe: entry_loader.active
    signal subMenuAboutToShow(var menuName)
    property variant lastItems;

    function populateModel(menuItemValues)
    {
        lastItems = menuItemValues // remember, in case we need to repopulate due to capability changes.

        menu_model.clear();
        menuItemValues.forEach(function(v) {
            var isDemo = (typeof v.demo !== 'undefined') && (v.demo !== undefined && v.demo);
            var isEnabled = (typeof v.enableCond === 'undefined') || v.enableCond === undefined || v.enableCond === "" || eval(v.enableCond)

            if (!isDemo || !guiconfig.hideDemoItems) {
                menu_model.append({ "label" : v.itemText, "settingsList": v.settingsList, "itemFile" : v.itemFile, "demo" : v.demo, "icon" : v.icon, "itemEnabled" : isEnabled })
            }
        });
    }

    onFocusChanged: {
        if(focus)
            list.forceActiveFocus()
    }


    function activateSubMenu(settingsList, itemFile, label)
    {
        subMenuAboutToShow(settingsList)

        entry_loader.itemValues = settingsList
        entry_loader.source = itemFile
        entry_loader.active = true
        entry_loader.upperMenuLabel = root.text
        entry_loader.menuLabel = label
        entry_loader.x = root.x
    }

    function setScrollToSubmenuItem(itemName)
    {
        entry_loader.scrollToSubmenuItem = itemName
    }

    // Prevent mouse clicks to propagate to parent views
    MouseArea {
        objectName: "Menu_root_MouseArea"
        anchors.fill: parent
        // Note that onClicked MUST be here, otherwise click will be propagated to parent and
        // a button on the parent might accidentally be clicked on with unwanted side effects
        onClicked: {
            console.log("Menu Clicked")
        }
        onPressAndHold: {
            console.log("Menu Press And Hold")
        }
    }

    function closeSubMenus()
    {
        // Make sure eventual loading is finished before killing it
        entry_loader.asynchronous = false
        entry_loader.asynchronous = true

        entry_loader.active = false
    }


    Timer {
        id: listMenuTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: list.highlightAllow = false
    }

    function startMenuWheelTimeout()
    {
        listMenuTimer.restart();
    }

    function stopMenuWheelTimeout()
    {
        listMenuTimer.stop();
    }

    Rectangle {
        id: viewEndLine
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: constants.viewEndLineWidth
    }

    ListView {
        objectName: "Menu_list"
        interactive: count > constants.itemCountInListView
        id: list
        clip: true
        pressDelay: 300
        focus: !entry_loader.active
        boundsBehavior: guiconfig.isRunningSimulation() ? Flickable.StopAtBounds : (Flickable.DragOverBounds | Flickable.CustomBounds)
        BoundsEffectGradient {
            parent: list
            fadeColor: constants.hblOrange
        }
        anchors {
            top: header_text.bottom
            left: viewEndLine.right
            right: parent.right
            bottom: parent.bottom
        }
        onFocusChanged: {
            // Only when we get focus back from something else we set the index selection to none.
            // Otherwise the reflection of a click doesn't show up.
            if(focus)
                currentIndex = -1
        }

        model: menu_model
        currentIndex: -1
        property int lastIndex: -1
        highlightMoveDuration: constants.highlightMoveDuration

        Keys.onPressed: {
            event.accepted = true // assume we trig on something
            if (MKeys.pressedFn("NAVUP", event.key) || (guiconfig.isWedge && MKeys.pressedFn("LEFT", event.key))) {
                startMenuWheelTimeout();
                list.highlightAllow = true
                if(-1 != currentIndex || -1 == lastIndex)
                    decrementCurrentIndex()
                else
                    currentIndex = lastIndex
                lastIndex = currentIndex // This may look peculiar, but its in order!
            }
            else if(MKeys.pressedFn("NAVDOWN", event.key) || (guiconfig.isWedge && MKeys.pressedFn("RIGHT", event.key))) {
                startMenuWheelTimeout();
                list.highlightAllow = true
                if(-1 != currentIndex || -1 == lastIndex)
                    incrementCurrentIndex()
                else
                    currentIndex = lastIndex
                lastIndex = currentIndex // This may look peculiar, but its in order!
            }
            else if((MKeys.pressedFn("SELECT", event.key) || (!guiconfig.isWedge && MKeys.pressedFn("RIGHT", event.key)))) {
                if(currentItem.enabled)
                {
                    if(list.highlightAllow)
                    {
                        stopMenuWheelTimeout();
                        list.highlightAllow = false
                        if(-1 != currentIndex)
                            currentItem.gotClicked()
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
                }
            }
            else if(MKeys.pressedFn("ESCAPE", event.key) || (!guiconfig.isWedge && MKeys.pressedFn("LEFT", event.key)))
            {
                stopMenuWheelTimeout();
                closeMenu()
            }
            else
                event.accepted = false
        }

        property bool highlightAllow: false
        highlight: Rectangle {
            opacity: list.currentItem !== null ? (list.currentItem.enabled ? 1 : 0.5) : 1
            color: list.highlightAllow ? constants.highlightColor : constants.popupBackgroundColor
        }

        delegate: Item {
            id: listDelegate
            objectName: "listDelegate"
            width: root.width
            height: list.height / constants.itemCountInListView
            enabled: itemEnabled

            DemoMarker {
                anchors.fill: parent
                showMarker: (typeof demo !== 'undefined') && (demo !== null) && (demo === true)
            }

            function gotClicked()
            {
                if(listDelegate.enabled)
                {
                    if (typeof settingsList == 'undefined')
                        root.visible = false
                    else {
                        activateSubMenu(settingsList, itemFile, label)
                    }
                }
            }

            Image {
                id: itemIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: constants.menuItemIconLeftMargin
                source: settingsList !== "" ? "qrc:///icons/" + settingsList + ".png" : "qrc:///icons/" + icon
                opacity: itemEnabled ? 1 : 0.5
            }

            Text {
                anchors {
                    left: itemIcon.right
                    right: parent.right
                    verticalCenter: itemIcon.verticalCenter
                    verticalCenterOffset: guiconfig.usingUnicodeLanguage ? 0 : (height - baselineOffset) / 2
                    leftMargin: 11
                }
                text: qsTranslate("MENUS", label) + guiconfig.emptyString
                color: itemEnabled ? constants.menuItemColor : "gray"
                fontSizeMode: Text.HorizontalFit
                font.family: constants.menuItemFontName
                font.pixelSize: constants.itemTextSizeMenuLevel1
            }

            MouseArea {
                objectName: "listDelegate_MouseArea"
                anchors.fill: parent
                property bool pressAndHoldTriggered: false
                onClicked: { if(containsMouse) gotClicked(); }
                onPressAndHold: pressAndHoldTriggered = true
                onPressed: {
                    list.highlightMoveDuration = 0
                    list.currentIndex = index
                    list.highlightAllow = true
                }
                onReleased: {
                    list.highlightMoveDuration = constants.highlightMoveDuration
                    if(!containsMouse)
                        list.highlightAllow = false
                    else if(pressAndHoldTriggered)
                        gotClicked()
                    pressAndHoldTriggered = false
                }
                onExited: pressAndHoldTriggered = containsMouse
                onEntered: list.highlightAllow = true
                onCanceled: {
                    list.highlightMoveDuration = constants.highlightMoveDuration
                    pressAndHoldTriggered = list.highlightAllow = false
                }
            }
        }
    }
    ListModel {
        id: menu_model
    }

    // Fading on top and bottom. Must be after listview, since it will be on top of it
    Rectangle {
        id: topGradient
        // NOTE: We hide the top transparency gradient if we are navigating with keys and the selected item is the first visible (top) one.
        visible: !list.highlightAllow || list.currentIndex === -1 || list.currentItem.mapToItem(null, 0, 0).y > 80

        anchors.top: parent.top
        anchors.left: viewEndLine.right
        anchors.right: parent.right
        height: header_text.height + constants.headerVerticalOffset + 30
        gradient: Gradient {
            GradientStop { position: 0.0; color: "black" }
            GradientStop { position: (header_text.height + constants.headerVerticalOffset) / topGradient.height; color: "black" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        // NOTE: We hide the bottom transparency gradient if we are navigating with keys and the selected item is the last visible (bottom) one.
        visible: !list.highlightAllow || list.currentIndex === -1 || list.currentItem.mapToItem(null, 0, 0).y < 340
        anchors.bottom: parent.bottom
        anchors.left: viewEndLine.right
        anchors.right: parent.right
        height: 30
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "black" }
        }
    }

     // Header text

    Text {
        id: header_text
        anchors {
            left: viewEndLine.right
            right: parent.right
            top: parent.top
            topMargin: constants.headerVerticalOffset
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        text: qsTranslate("MainScreen", root.text) + guiconfig.emptyString
        font.capitalization: Font.AllUppercase
    }

    /*
    ScrollBar {
        flickable: list;
        anchors.top: parent.top
        color: constants.highlightColor
        basicWidth: 15
        enabled: !entry_loader.active
        visible: enabled
    }
*/
    // To be able to swipe the menu to the right to get rid of it
    MouseArea {
        objectName: "Menu_swipe_area"
        enabled: entry_loader.active && !entry_loader.preventSwipe
        id: swipe_area
        anchors {
            top: root.top
            bottom: root.bottom
            right: root.right
            left: root.left
        }
        drag.filterChildren: true

        drag {
            target: entry_loader
            axis: Drag.XAxis
            minimumX: root.x
            maximumX: root.x + root.width
            threshold: constants.dragThreshold
        }
        drag.onActiveChanged: {
            if (!drag.active) {
                // Its visible make sure it flies in or out
                if (drag.target.x > (root.x + root.width / constants.swipeLengthDividor))
                {
                    entry_loader.active = false;
                    entry_loader.x = root.x + root.width
                }
                else
                {
                    entry_loader.x = root.x
                }

            }
        }
        Loader {
            id: entry_loader
            objectName: "entry_loader"
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            x: parent.x + parent.width
            width: parent.width
            asynchronous: true
            focus: active
            active: false
            property var itemValues: []
            property string upperMenuLabel: ""
            property string menuLabel: ""
            property bool preventSwipe: (item !== null) && item.preventSwipe !== undefined && item.preventSwipe
            property string scrollToSubmenuItem: ""

            Behavior on x {
                NumberAnimation { easing.type: Easing.InOutQuad; duration: constants.menuSwipeDuration }
            }

            Connections {
                target: entry_loader.item
                onVisibleChanged: {
                    if (!target.visible)
                    {
                        // Make sure eventual loading is finished before killing it
                        entry_loader.asynchronous = false
                        entry_loader.asynchronous = true
                        entry_loader.active = false
                    }
                }
            }
            onLoaded: {
                if(typeof entry_loader.item.populateModel == 'function')
                    entry_loader.item.populateModel(entry_loader.itemValues);

                if(entry_loader.item.hasOwnProperty("upperMenuLabel"))
                    entry_loader.item.upperMenuLabel = entry_loader.upperMenuLabel;
                if(entry_loader.item.hasOwnProperty("menuLabel"))
                    entry_loader.item.menuLabel = entry_loader.menuLabel;
                // We set visible here, because if we load a sub item from favorites, we
                // set visible to false to avoid flicker, and want to restore it here
                root.parent.visible = true
                if (scrollToSubmenuItem != "")
                {
                    entry_loader.item.scrollToItem(scrollToSubmenuItem)
                    scrollToSubmenuItem = ""
                }
            }

            // NOTE: Will close submenu for SettingsGeneric.qml (since this loader is the parent)
            Keys.onPressed: {
                if(MKeys.pressedFnAcc("ESCAPE", event) || (!guiconfig.isWedge && MKeys.pressedFnAcc("LEFT", event)))
                    active = false;

                // Below are keys that shall progress to next level (i.e. TouchWindow)
                else if(MKeys.pressedFn("MENU", event.key) ||
                        MKeys.pressedFn("BROWSE", event.key) ||
                        MKeys.pressedFn("BROWSEMODE", event.key) ||
                        MKeys.pressedFn("CROPMODENEXT", event.key) ||
                        MKeys.pressedFn("CROPMODEPREV", event.key) ||
                        MKeys.pressedFn("INTERVAL", event.key) ||
                        MKeys.pressedFn("BRACKETING", event.key) ||
                        MKeys.pressedFn("GREYBALANCE", event.key) ||
                        MKeys.pressedFn("PROFILES", event.key) ||
                        MKeys.pressedFn("HALFPRESS", event.key) ||
                        MKeys.pressedFn("EXPOSURE", event.key) ||
                        MKeys.pressedFn("AF_MF", event.key) ||
                        MKeys.pressedFn("ISO_WB", event.key) ||
                        MKeys.pressedFn("FORMAT", event.key) ||
                        MKeys.pressedFn("TOGGLESLEEP", event.key) ||
                        MKeys.pressedFn("EXP_CUSTOM", event.key) ||
                        MKeys.pressedFn("WAKEUP", event.key) ||
                        MKeys.pressedFn("WIFI", event.key) ||
                        MKeys.pressedFn("RECORD", event.key) ||
                        MKeys.pressedFn("AFPCYCLE", event.key) ||
                        MKeys.pressedFn("AUTOISO", event.key) ||
                        MKeys.pressedFn("LIVEVIEW", event.key) ||
                        MKeys.pressedFn("DELETE", event.key) ||
                        MKeys.pressedFn("ESHUTTER", event.key) ||
                        MKeys.pressedFn("SELFTIMER", event.key) ||
                        MKeys.pressedFn("CTRLSCREEN", event.key) ||
                        MKeys.pressedFn("SPIRITLEVEL", event.key))
                    event.accepted = false
                else
                    // All other keys are filtered out here
                    event.accepted = true;
            }
        }
    }

    Connections {
        target: cambody
        onCapabilitiesChanged: populateModel(lastItems)
        onHts_attachedChanged: forceEnabledUpdate()
    }
    Connections {
        target: suc
        onCambody_attachedChanged: forceEnabledUpdate()
    }

    Connections {
        target: configstore
        onExpModeChanged: {
            var foundGreyBalance = false
            lastItems.forEach(function(v) {
                if (v.settingsList === "cameraSettingsGreyBalanceTool") {
                    foundGreyBalance = true
                    //break doesn't work with forEach
                }
            });
            if (foundGreyBalance) {
                var topPos = list.indexAt(10,10)
                populateModel(lastItems)
                list.positionViewAtIndex(topPos, ListView.Beginning)
            }
        }
    }

    function forceEnabledUpdate() {
        var oldY = list.contentY
        list.contentY = 0
        populateModel(lastItems)
        // Due to some strange QML bug, it just does not work to set the old value back. We have to set it several times to get it to stick...
        list.contentY = oldY
        list.contentY--
        list.contentY = oldY
        list.contentY++
        list.contentY = oldY
    }
}
