import QtQuick 2.0

import com.hasselblad.config 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.video 1.0
import com.hasselblad.upgrade 1.0
import com.hasselblad.favoritemodel 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.globalstateinfo 1.0

import "qrc:///components"
import "qrc:///components/buttons"
import "qrc:///components/controls"
import "qrc:///mainmenu"
import "qrc:///settings"

import "qrc:///settings/scripts/MenuItemImporter.js" as MenuItems
import "qrc:///scripts/Keys.js" as MKeys


Rectangle {
    objectName: "MainScreen_root"
    id: root
    property real margin: (width - (camera_icon.width * big_icons.children.length)) / 4
    property int gridSideMargin: 9
    property bool simulation
    property bool acceptKeys: true
    color: "black"
    property real childOpacity
    property bool hideStatusIcons: false
    property bool hideTopBatteryIcon: false
    signal closeMain()
    focus: true

    Timer {
        id: mainWheelTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: {
            grid.lastIndex = grid.currentIndex
            root.focus = true
        }
    }

    function startMainWheelTimeout()
    {
//        console.log("started mainwheel timeout")
        mainWheelTimer.restart();
    }

    function stopMainWheelTimeout()
    {
//        console.log("stopped mainwheel timeout")
        mainWheelTimer.stop();
    }

    function closeMenu()
    {
        // Must deactivate sub menus, otherwise -> crash
        var r = menu_loader.item
        if((r !== 'undefined') && (r !== null) && (typeof r.closeSubMenus === 'function'))
        {
            r.closeSubMenus()
        }

        // Always land in start state before going to new state, to avoid being out of sync.
        // Strange things will happen in that case
        root.state = ""
        GlobalStateInfo.preventTopSwipe = false
    }

    function closeMainScreen()
    {
        closeMain()
    }

    function loadCameraMenuItem(subMenu, menuItem)
    {
        /* Load specific item in camera submenu */
        menu_loader.subItem = "cameraSettingsConfiguration"
        menu_loader.subItemLoader = "qrc:///settings/SettingsGeneric.qml"
        menu_loader.label = subMenu
        menu_loader.scrollToSubmenuItem = menuItem
        root.state = "camera_menu"
    }

    function loadProfilesMenu() {
        if (root.state !== "") {
            closeMenu()
        }
        menu_loader.subItem = "generalSettingsProfiles"
        menu_loader.subItemLoader = "qrc:///settings/ProfilesView.qml"
        menu_loader.label = "Profiles"
        root.state = "settings_menu"
    }

    onFocusChanged: {
        if(focus)
        {
        }
        else
        {
            // unless it is the grid or the lower view icons taking focus, we stop the wheel timer in order not to steal it from some other view.
            if(!(grid.focus || settings_icon.focus || camera_icon.focus || video_icon.focus))
                stopMainWheelTimeout()
            grid.remove = false
        }

    }

    Keys.onPressed: {
        if (!acceptKeys)
            return

        event.accepted = true
        MKeys.log(event.key)
        if(MKeys.pressedFn("MENU", event.key)) {
            //console.log("MainScreen captured", MKeys.CAMKEYS.MENU.name)
            if (root.state === "")
                event.accepted = false
            else
                root.closeMenu()
        } else if (MKeys.pressedFn("F2", event.key))
        {
            if(guiconfig.isWedge)
            {
                camera_icon_wedge.forceShowHighlite = true
            }
            else
            {
                camera_icon.forceShowHighlite = true
            }
            root.state = "camera_menu"
        }
        else if (MKeys.pressedFn("STAR", event.key))
        {
            if(guiconfig.isWedge)
            {
                video_icon_wedge.forceShowHighlite = true
            }
            else
            {
                video_icon.forceShowHighlite = true
            }
            root.state = "video_menu"
        }
        else if (MKeys.pressedFn("F4", event.key))
        {
            if(guiconfig.isWedge)
            {
                settings_icon_wedge.forceShowHighlite = true
            }
            else
            {
                settings_icon.forceShowHighlite = true
            }
            root.state = "settings_menu"
        }
        else if(MKeys.pressedFn("RIGHT", event.key) || MKeys.pressedFn("DOWN", event.key)) {
            if(!guiconfig.isWedge) {
                if(!(grid.focus || camera_icon.focus || settings_icon.focus || video_icon.focus))
                    camera_icon.focus = true
            }
            else {
                if(!(grid.focus || camera_icon_wedge.focus || settings_icon_wedge.focus || video_icon_wedge.focus))
                    settings_icon_wedge.focus = true
            }
        }
        else if(MKeys.pressedFn("LEFT", event.key)) {
            if(!guiconfig.isWedge) {
                if(!(grid.focus || camera_icon.focus || settings_icon.focus || video_icon.focus))
                    settings_icon.focus = true
            }
            else
                grid.focus = true
        }
        else if(MKeys.pressedFn("UP", event.key)) {
            if(!guiconfig.isWedge)
                grid.focus = true
            else {
               if(!(grid.focus || camera_icon_wedge.focus || settings_icon_wedge.focus || video_icon_wedge.focus))
                   camera_icon_wedge.focus = true
            }
        }
        else if ((root.state === "") && MKeys.pressedFnAcc("AE_L", event))
        {
            // Prevent from propagating
        }
        else
            event.accepted = false
    }

    Keys.onReleased: {
        event.accepted = false
        if (MKeys.pressedFnAcc("F2", event))
        {
            camera_icon_wedge.forceShowHighlite = false
            camera_icon.forceShowHighlite = false
        }
        else if (MKeys.pressedFnAcc("STAR", event))
        {
            video_icon_wedge.forceShowHighlite = false
            video_icon.forceShowHighlite = false
        }
        else if (MKeys.pressedFnAcc("F4", event))
        {
            settings_icon_wedge.forceShowHighlite = false
            settings_icon.forceShowHighlite = false
        }
    }
    StatusRow {
        anchors.right: guiconfig.isWedge && root.state === "" ? iconsBackWedge.left : parent.right
        hideStatusIcons: root.hideStatusIcons
        hideTopBatteryIcon: root.hideTopBatteryIcon
        z: 1
    }

    Text {
        id: header
        text: qsTr("MAIN MENU") + guiconfig.emptyString
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: guiconfig.isWedge ? -iconsBackWedge.width  / 2 : 0
        anchors.top: parent.top
        anchors.topMargin: constants.headerVerticalOffset
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        font.capitalization: Font.AllUppercase
        font.family: constants.menuItemFontName
    }

    Row {
        // Victory horizontal bottom buttons
        id: big_icons
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 5
        anchors.bottom: root.bottom
        anchors.leftMargin: root.margin
        spacing: prodinfo.isNewH6DisplayQml() ? 5 : 20
        opacity: root.childOpacity
        visible: !guiconfig.isWedge

        Icon {
            id: camera_icon
            showInvertedFocus: true
            source: "qrc:///icons/camera_icon.png"
            // We need to downscale icons to fit the new display physical button layout.
            scaleIcon: prodinfo.isNewH6DisplayQml() ? true : false
            width: prodinfo.isNewH6DisplayQml() ? 130 : 145
            height: 105
            onClicked: if(root.state === "") root.state = "camera_menu"
            KeyNavigation.right: video_icon
            Keys.onLeftPressed: {
                grid.currentIndex = grid.count - 1
                grid.focus = true
            }
            Keys.onUpPressed: {
                keyUpGridVictory(4)
            }
            Keys.onDownPressed: {
                keyDownGridVictory(1)
            }

            showFrameAtFocus: true
            onFocusChanged: if(focus) {
                grid.fromCtrl = 0;
                startMainWheelTimeout()
            }
        }

        Icon {
            id: video_icon
            showInvertedFocus: true
            source: "qrc:///icons/video_icon.png"
            width: camera_icon.width
            height: camera_icon.height
            scaleIcon: camera_icon.scaleIcon
            onClicked: if(root.state === "") root.state = "video_menu"
            KeyNavigation.right: settings_icon
            KeyNavigation.left: camera_icon
            Keys.onUpPressed: {
                keyUpGridVictory(5)
            }
            Keys.onDownPressed: {
                keyDownGridVictory(2)
            }
            showFrameAtFocus: true
            onFocusChanged: if(focus) {
                grid.fromCtrl = 1
                startMainWheelTimeout()
            }
        }

        Icon {
            id: settings_icon
            showInvertedFocus: true
            source: "qrc:///icons/settings_icon.png"
            width: camera_icon.width
            height: camera_icon.height
            scaleIcon: camera_icon.scaleIcon
            onClicked: if(root.state === "") root.state = "settings_menu"
            KeyNavigation.left: video_icon
            Keys.onUpPressed: {
                keyUpGridVictory(6)
            }
            Keys.onRightPressed: {
                grid.currentIndex = 0
                grid.focus = true
            }
            Keys.onDownPressed: {
                keyDownGridVictory(3)
            }

            showFrameAtFocus: true
            onFocusChanged: if(focus) {
               grid.fromCtrl = 3
               startMainWheelTimeout()
            }
        }
    }

    Rectangle {
        id: iconsBackWedge
        color: constants.iconsBackWedgeColor
        visible: guiconfig.isWedge
        width: constants.iconsBackWedgeWidth

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }

        Column {
            // Wedge right buttons bar
            id: big_icons_wedge
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -9-5 //-16
                rightMargin: 5
                right: parent.right
                topMargin: parent.margin
            }
            spacing: 31 //36
            opacity: root.childOpacity

            Icon {
                id: camera_icon_wedge
                showInvertedFocus: true
                source: "qrc:///icons/camera_icon_wedge.png"
                width: 145
                height: 105
                onClicked: if(root.state === "") root.state = "camera_menu"
                Keys.onPressed: {
                    if(MKeys.pressedFnAcc("DOWN", event))
                    {
                        video_icon_wedge.forceActiveFocus()
                    }
                    else if (MKeys.pressedFnAcc("UP", event))
                    {
                        keyUpGridWedge(8)
                    }
                    else if (MKeys.pressedFnAcc("LEFT", event))
                    {
                        grid.currentIndex = bestFirstPosition(0, grid.count)
                        grid.focus = true
                    }
                    else if (MKeys.pressedFnAcc("RIGHT", event))
                    {
                        setNextPositionToRightWedge(3, video_icon_wedge)
                    }
                    else if(MKeys.pressedFnAcc("ENTER", event)) {
                        if(root.state === "") root.state = "camera_menu"
                    }
                    else
                    {
                        event.accepted = false
                    }
                }

                showFrameAtFocus: true
                onFocusChanged: if(focus) {
                                    grid.fromCtrl = 0;
                                    startMainWheelTimeout()
                                }
            }
            Icon {
                id: video_icon_wedge
                showInvertedFocus: true
                source: "qrc:///icons/video_icon_wedge.png"
                width: camera_icon_wedge.width
                height: camera_icon_wedge.height
                onClicked: if(root.state === "") root.state = "video_menu"
                Keys.onPressed: {
                    if(MKeys.pressedFnAcc("DOWN", event))
                    {
                        settings_icon_wedge.forceActiveFocus()
                    }
                    else if (MKeys.pressedFnAcc("UP", event))
                    {
                        camera_icon_wedge.forceActiveFocus()
                    }
                    else if (MKeys.pressedFnAcc("LEFT", event))
                    {
                        grid.currentIndex = bestFirstPosition(1, grid.count)
                        grid.focus = true
                    }
                    else if (MKeys.pressedFnAcc("RIGHT", event))
                    {
                        setNextPositionToRightWedge(6, settings_icon_wedge)
                    }
                    else if(MKeys.pressedFnAcc("ENTER", event)) {
                        if(root.state === "") root.state = "video_menu"
                    }
                    else
                    {
                        event.accepted = false
                    }
                }
                showFrameAtFocus: true
                onFocusChanged: if(focus) {
                                    grid.fromCtrl = 1
                                    startMainWheelTimeout()
                                }
            }
            Icon {
                id: settings_icon_wedge
                showInvertedFocus: true
                source: "qrc:///icons/settings_icon_wedge.png"
                width: camera_icon_wedge.width
                height: camera_icon_wedge.height
                onClicked: if(root.state === "") root.state = "settings_menu"
                Keys.onPressed: {
                    if(MKeys.pressedFnAcc("DOWN", event))
                    {
                        grid.currentIndex = 0
                        grid.focus = true
                    }
                    else if (MKeys.pressedFnAcc("UP", event))
                    {
                        video_icon_wedge.forceActiveFocus()
                    }
                    else if (MKeys.pressedFnAcc("LEFT", event))
                    {
                        grid.currentIndex = bestFirstPosition(2, grid.count)
                        grid.focus = true
                    }
                    else if (MKeys.pressedFnAcc("RIGHT", event))
                    {
                        setNextPositionToRightWedge(0, settings_icon_wedge)
                    }
                    else if(MKeys.pressedFnAcc("ENTER", event)) {
                        if(root.state === "") root.state = "settings_menu"
                    }
                    else
                    {
                        event.accepted = false
                    }
                }

                showFrameAtFocus: true
                onFocusChanged: if(focus) {
                                    grid.fromCtrl = 2
                                    startMainWheelTimeout()
                                }
            }
        } // Column
    } // Rectangle



    MouseArea {
        anchors.fill: root
        enabled: grid.remove
        onClicked: {
            grid.remove = false
        }
    }

    // When we move up from the bottom icon row (camera/video/settings) the very first time (using key up), we need to know
    // the best item in the GridView to set as the current item. For this we need to know the last bottom icon that had focus,
    // "lastIcon" as an offset on the row, the total number of items in
    // the GridView as "limit". The function returns the new index position to set on grid's currentIndex.
    function bestFirstPosition(lastIcon, limit)
    {
        var ITEMS_PER_ROW = guiconfig.isWedge ? 3 : 4
        if(guiconfig.isWedge) {
            var startIndex = lastIcon * ITEMS_PER_ROW + ITEMS_PER_ROW - 1;
            while(startIndex >= limit)
                --startIndex
            return startIndex
        }

        var pos = ~~(limit / ITEMS_PER_ROW)
        if(pos > 0 && 0 === (limit % ITEMS_PER_ROW))
            --pos
        pos *= ITEMS_PER_ROW
        pos += lastIcon
        while(pos >= limit)
            --pos;
        if(pos < 0)
            pos = 0
        return pos
    }
    // startIcon
    function setNextPositionToRightWedge(wantedPos, fallbackIcon)
    {
        if(wantedPos < grid.count)
        {
            grid.currentIndex = wantedPos
            grid.focus = true
        }
        else
        {
            fallbackIcon.forceActiveFocus()
        }
    }

    function keyUpFromGridVictory(startPos)
    {
        switch(startPos)
        {
        case 0:
            keyUpGridVictory(7)
            break;
        case 1:
            camera_icon.focus = true
            break;
        case 2:
            video_icon.focus = true
            break;
        case 3:
            settings_icon.focus = true
            break;
        default:
            keyUpGridVictory(startPos - 4)
            break;
        }
    }


    function keyUpGridVictory(wantedPos)
    {
        if(wantedPos < grid.count)
        {
            grid.currentIndex = wantedPos
            grid.focus = true
        }
        else
        {
            keyUpFromGridVictory(wantedPos)
        }
    }


    function keyDownFromGridVictory(startPos)
    {
        switch(startPos)
        {
        case 4:
            camera_icon.focus = true
            break;
        case 5:
            video_icon.focus = true
            break;
        case 6:
            settings_icon.focus = true
            break;
        case 7:
            keyDownGridVictory(0)
            break;
        default:
            keyDownGridVictory(startPos + 4)
            break;
        }
    }


    function keyDownGridVictory(wantedPos)
    {
        if(wantedPos < grid.count)
        {
            grid.currentIndex = wantedPos
            grid.focus = true
        }
        else
        {
            keyDownFromGridVictory(wantedPos)
        }
    }

    function keyLeftFromGridWedge(startPos)
    {
        switch(startPos)
        {
        case 0:
            settings_icon_wedge.focus = true
            break;
        case 3:
            camera_icon_wedge.focus = true
            break;
        case 6:
            video_icon_wedge.focus = true
            break;
        default:
            keyLeftGridWedge(startPos - 1)
            break;
        }
    }


    function keyLeftGridWedge(wantedPos)
    {
        if(wantedPos < grid.count)
        {
            grid.currentIndex = wantedPos
            grid.focus = true
        }
        else
        {
            keyLeftFromGridWedge(wantedPos)
        }
    }

    function keyUpFromGridWedge(startPos)
    {
        switch(startPos)
        {
        case 0:
            settings_icon_wedge.focus = true
            break;
        case 1:
            keyUpGridWedge(6)
            break;
        case 2:
            keyUpGridWedge(7)
            break;
        default:
            keyLeftGridWedge(startPos - 3)
            break;
        }
    }


    function keyUpGridWedge(wantedPos)
    {
        if(wantedPos < grid.count)
        {
            grid.currentIndex = wantedPos
            grid.focus = true
        }
        else
        {
            keyUpFromGridWedge(wantedPos)
        }
    }
    GridView {
        objectName: "MainScreen_grid"
        id: grid
        cellWidth: guiconfig.isWedge ? width / 3 : width / 4
        cellHeight: 149
        opacity: root.childOpacity
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        visible: true
        model: favoriteModel
        anchors.left: parent.left
        anchors.leftMargin: gridSideMargin
        anchors.right: guiconfig.isWedge ? iconsBackWedge.left : parent.right
        anchors.rightMargin: gridSideMargin
        height: guiconfig.isWedge ? cellHeight * 3 : cellHeight * 2
        anchors.top: parent.top
        anchors.topMargin: guiconfig.isWedge ? 50 : 79
        keyNavigationWraps: true
        highlightFollowsCurrentItem: false
        /* Keyboard navigation only works on PC when interactive is true.
         * Hook it up to simulation so it works when window has been resized
         * and show the simulation F1-F5 buttons atleast....
         */
        currentIndex: -1

        property bool remove: false
        property int removeIndex: -1
        property int lastIndex: -1
        property int fromCtrl: -1

        onFocusChanged: {
            if (!focus) {
                lastIndex = currentIndex
                currentIndex = -1 // Deselect to get rid of selection indication
            }
            else {
                startMainWheelTimeout()
                // If we get focus due to a mouse press, we just keep the index,
                // but if we get focus by key navigation we restore the last index.
                if (currentIndex < 0 || currentIndex >= count) {
                    if (-1 === lastIndex) { // first time.
                        if(fromCtrl >= 0)
                            lastIndex = bestFirstPosition(fromCtrl, grid.count)
                        else
                            lastIndex = 0
                    }
                    currentIndex = lastIndex
                }
                else if(-1 === lastIndex)
                    lastIndex = currentIndex
            }
        }

        Keys.onPressed: {
            event.accepted = true;
            if(MKeys.pressedFn("RIGHT", event.key)) {
                if(-1 == grid.currentIndex && -1 != grid.lastIndex)
                    grid.currentIndex = grid.lastIndex
                else {
                    if(guiconfig.isWedge) {
                        if(grid.currentIndex % 3 === 2 || grid.currentIndex === grid.count - 1) {
                            var row = ~~(grid.currentIndex / 3)
                            switch(row) {
                            case 0:
                                camera_icon_wedge.focus = true
                                break
                            case 1:
                                video_icon_wedge.focus = true
                                break;
                            case 2:
                                settings_icon_wedge.focus = true
                                break;
                            }
                        }
                        else
                            moveCurrentIndexRight();

                    }
                    else {
                        if(grid.currentIndex === grid.count - 1)
                            camera_icon.focus = true
                        else
                            moveCurrentIndexRight()
                    }
                }
            }
            else if(MKeys.pressedFn("LEFT", event.key)) {
                if(-1 == grid.currentIndex && -1 != grid.lastIndex)
                    grid.currentIndex = grid.lastIndex
                else
                {
                    if(guiconfig.isWedge)
                    {
                        keyLeftFromGridWedge(grid.currentIndex)
                    }
                    else if(!guiconfig.isWedge)
                    {
                        if(grid.currentIndex == 0)
                        {
                            settings_icon.focus = true
                        }
                        else
                        {
                            moveCurrentIndexLeft()
                        }
                    }
                }
            }
            else if(MKeys.pressedFn("UP", event.key)) {
                if(-1 == grid.currentIndex && -1 != grid.lastIndex)
                    grid.currentIndex = grid.lastIndex
                else {
                    if(guiconfig.isWedge)
                    {
                        keyUpFromGridWedge(grid.currentIndex)
                    }
                    else
                    {
                        keyUpFromGridVictory(grid.currentIndex)
                    }
                }
            }
            else if(MKeys.pressedFn("DOWN", event.key)) {
                if(-1 == grid.currentIndex && -1 != grid.lastIndex)
                    grid.currentIndex = grid.lastIndex
                else {
                    if(guiconfig.isWedge) {
                        if(currentIndex < grid.count - 3)
                            moveCurrentIndexDown()
                        else if(grid.currentIndex % 3 < 2){
                            var newIdx = (grid.currentIndex % 3) + 1;
                            if(newIdx >= grid.count -1)
                                newIdx = 0
                            grid.currentIndex = newIdx
                        }
                        else
                            camera_icon_wedge.focus = true
                    }
                    else
                    {
                        keyDownFromGridVictory( grid.currentIndex)
                    }
                }
            }
            else
                event.accepted = false
            if(event.accepted) {
                startMainWheelTimeout()
                grid.removeIndex = -1
                grid.remove = false
            }
        }

        removeDisplaced: Transition {
            NumberAnimation { easing.type: Easing.InOutQuad; properties: "x,y"; duration: 300 }
        }

        moveDisplaced: Transition {
            NumberAnimation { easing.type: Easing.InOutQuad; properties: "x,y"; duration: 300 }
        }

        delegate: Item {
            id: delegateRoot
            width: grid.cellWidth
            height: grid.cellHeight

            FramedImage {
                id: frameImage
                text: qsTranslate("MENUS", model.text) + guiconfig.emptyString
                textColor: constants.popupTextColor
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                focus: parent.GridView.isCurrentItem
                source: "qrc:///icons/" + icon + ".png"
                showInvertedFocus: true
                selectable: itemEnabled

                onPressed: {
                    if (selectable) {
                        grid.focus = true
                        grid.currentIndex = index
                    }
                }
                onReleased: { grid.lastIndex = index; grid.currentIndex = -1 }

                onPressAndHold: {
                    if(!isstatic)
                    {
                        grid.remove = true
                        grid.removeIndex = index
                        loc.setImage(this, delegateRoot)
                    }
                    /* Here we the invert the focus immediatly because
                       the deleteCandidateIcon already indicates the press.
                       We also both drop the focus indication because we don't
                       want it to be kept selected after the release. */
                    grid.currentIndex = -1
                }

                function gotClick()
                {
                    if (grid.remove && (grid.removeIndex === index))
                    {
                        grid.model.remove(index)
                        grid.remove = false
                        // After removal, the grid control will by design indicate the next selected item,
                        // which we don't want, force no selection.
                        grid.currentIndex = -1
                    }
                    // AARRGGHH! There must ALWAYS be an exception to the golden rule, mustn't it?
                    else if (selectable && settingsList === "cameraSettingsLiveView")
                    {
                        Camera.setLiveViewState(true)
                    }
                    // We have the following check to make sure we cannot double click on the favorites
                    else if(selectable && menu_loader.visible && (root.state === ""))
                    {
                        stopMainWheelTimeout()
                        grid.remove = false

                        // Since menu will be visible for a short time until sub menu is totally loaded,
                        // we make it temporarily invisible
                        menu_loader.visible = false
                        menu_loader.subItem = settingsList
                        menu_loader.subItemLoader = itemFile
                        menu_loader.label = model.text
                        root.state = clicked_state
                    }
                }


                onClicked: {
                    gotClick()
                }
                Keys.onPressed: {
                    event.accepted = false;
                    if(MKeys.pressedFnAcc("ENTER", event))
                        gotClick()
                    else if(event.accepted) {
                        startMainWheelTimeout()
                        grid.removeIndex = -1
                        grid.remove = false
                    }
                }
            }
            Image {
                visible: grid.remove && loc.dragImage === frameImage && frameImage.visible
                source: "qrc:///icons/DeleteCandidateIcon.png"
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 22
            }
        }
    }

    Timer {
        id: pressAndHoldTimer
        interval: 250
        running: false
        repeat: false
    }

    MouseArea {
        id: loc
        enabled: grid.remove

        property int dragIndex: grid.indexAt(mouseX, mouseY)
        property int newIndex: -1
        property bool changed: false
        property var dragImage
        property var gridPositionItem

        anchors.fill: root

        onReleased: {
            if (changed)
            {
                behavior_x.enabled = true
                behavior_y.enabled = true
                // For some extremely strange reason, gridPositionItem might be null...
                // Have not found the reason, but as noted before, QML is a reeeeeeeeeeally buggy environment...
                if(gridPositionItem !== null)
                {
                    fakeImage.x = gridPositionItem.x
                    fakeImage.y = gridPositionItem.y + fakeImage.height/2
                }
            }
            else if ((dragIndex === grid.removeIndex) && (newIndex !== -1) )
            {
                // Just a click or similar, remove item
                grid.model.remove(dragIndex)
                grid.currentIndex = -1
                fakeImage.visible = false
            }

            grid.remove = false
            grid.removeIndex = -1
            changed = false
            newIndex = -1
            pressAndHoldTimer.stop()
        }

        onPressed: {
            // Check that position is on the marked icon
            if(grid.indexAt(mouseX, mouseY) === grid.removeIndex)
            {
                newIndex = grid.removeIndex
            }
            pressAndHoldTimer.restart()
        }
        onPositionChanged: {
            if (pressAndHoldTimer.running)
            {
                return
            }
            if(newIndex !== -1)
            {
                fakeImage.visible = true
                changed = true
                if (newIndex !== - 1 && dragIndex !== -1 && dragIndex !== newIndex) {
                    if (favoriteModel.move(newIndex, dragIndex)) {
                        newIndex = dragIndex
                        grid.removeIndex = dragIndex
                    }
                }
            }
        }

        onEnabledChanged: {
            if (!enabled)
                fakeImageVisible()
        }

        function fakeImageVisible() {
            fakeImage.visible = animate_x.running || animate_y.running
        }

        function setImage(img, pos) {
            loc.dragImage = img
            loc.gridPositionItem = pos

            fakeImage.text = img.text
            fakeImage.textColor = img.textColor
            fakeImage.source = img.source
            fakeImage.width = img.width
            fakeImage.height = img.height

            behavior_x.enabled = false
            behavior_y.enabled = false
        }

        FramedImage {
            id: fakeImage

            visible: false

            states: State {
                name: "active"
                when: fakeImage.visible
                PropertyChanges {
                    target: fakeImage
                    x: loc.mouseX - width/2
                    y: loc.mouseY - height/2
                    restoreEntryValues: false
                }
            }

            onVisibleChanged: {
                loc.dragImage.visible = !visible
            }

            Behavior on x {
                id: behavior_x
                enabled: false
                NumberAnimation {
                    id: animate_x
                    duration: 400
                    easing.type: Easing.InOutQuad

                    onRunningChanged: loc.fakeImageVisible()
                }
            }

            Behavior on y {
                id: behavior_y
                enabled: false
                NumberAnimation {
                    id: animate_y
                    duration: 400
                    easing.type: Easing.InOutQuad

                    onRunningChanged: loc.fakeImageVisible()
                }
            }


            // Show the little '+' icon also.
            Image {
                visible: parent.visible
                source: "qrc:///icons/DeleteCandidateIcon.png"
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 22
            }
        }
    }


    Connections {
        target: (menu_loader.status === Loader.Ready) ? menu_loader.item : null
        onSubMenuAboutToShow: {
            // If we're going to about screen, update (read) the firmware versions from the suc.
            if("generalSettingsAbout" === menuName) {
                suc.requestLensFirmwareVersion()
                suc.requestLensCounter()

                if(!guiconfig.isWedge) {
                    suc.requestViewFinderFirmwareVersion()
                    suc.requestBodyCounter()
                }
            }
        }
    }


    // To be able to swipe the menu to the right to get rid of it
    MouseArea {
        objectName: "MainScreen_swipe_area"
        enabled: menu_loader.active && !menu_loader.preventSwipe

        id: swipe_area
        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.right: root.right
        anchors.left: root.left
        drag {
            target: menu_loader
            axis: Drag.XAxis
            minimumX: root.x
            maximumX: root.x + root.width
            threshold: constants.dragThreshold
        }
        drag.filterChildren: true
        drag.onActiveChanged: {
            if (!drag.active) {
                // Its visible make sure it flies in or out
                if (drag.target.x > (root.x + root.width / constants.swipeLengthDividor))
                {
                    // Make sure eventual loading is finished before killing it
                    menu_loader.asynchronous = false
                    menu_loader.asynchronous = true
                    menu_loader.active = false;
                    root.closeMenu()
                    menu_loader.x = root.x + root.width
                }
                else
                {
                    menu_loader.x = root.x - constants.viewEndLineWidth
                }
            }
            else
            {
            }
        }
        // Note that mouse area must be parent of loader in order to allow sweeping away of settings
        Loader {
            id: menu_loader
            objectName: "menu_Loader"
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            x: root.x + root.width
            width: parent.width
            active: false
            asynchronous: true
            focus: active
            property var itemValues: []
            property bool preventSwipe: (item !== null) && item.preventSwipe !== undefined && item.preventSwipe
            property bool populate: true

            // To directly activate a sub list
            property string subItem: "" // settingsList
            property string subItemLoader: ""
            property string label: ""
            property string scrollToSubmenuItem: ""

            Behavior on x {
                enabled: root.state !== "add_favorite"
                NumberAnimation { easing.type: Easing.InOutQuad; duration: constants.menuSwipeDuration }
            }

            onLoaded: {
                if (menu_loader.populate)
                    menu_loader.item.populateModel(menu_loader.itemValues);
                menu_loader.item.forceActiveFocus()
                // Shall we load sub menu?
                if(menu_loader.subItem != "")
                {
                    menu_loader.item.activateSubMenu(subItem, subItemLoader, label)
                }
                subItem = ""
                label = ""

                if (scrollToSubmenuItem != "")
                {
                    menu_loader.item.setScrollToSubmenuItem(scrollToSubmenuItem)
                    scrollToSubmenuItem = ""
                }
            }

            // NOTE: Closes Menu.qml (since this loader is the parent).
            Keys.onPressed: {
                if((MKeys.pressedFnAcc("ESCAPE", event)) || (!guiconfig.isWedge && MKeys.pressedFnAcc("LEFT", event)))
                {
                    active = false;
                    root.closeMenu()
                }
                if(guiconfig.isWedge && MKeys.pressedFnAcc("LEFT", event))
                {
                    // Prevent key from propagating
                }
                else
                {
                    event.accepted = false
                }
            }
            Component.onDestruction: active = false
        }

    }

    Text {
        visible: !guiconfig.hideDemoItems
        anchors.top: parent.top
        anchors.horizontalCenter: header.horizontalCenter
        color: "white"
        text: qsTr("Build:" ) + System.versionID + guiconfig.emptyString
    }

    onStateChanged: console.log("Main state", state)
    states: [
        State {
            name: ""
            // NOTE: the "!menu_loader.active" part causes a (dismissed) auto state change when another state is set
            // hence a warning message in the log:
            // "Can't apply a state change as part of a state definition"
            /* Warning: here be dragons.
             * This is disabled because it catches everything making it impossible for any other state to have a when.
             * Possibly the inverse is wanted in another state, but unknown which that would be.
             * According to ludwig this was added as a workaround to avoid a crash when/after using the
             * "FW Update Retry" function under service menu. Now seems to work without this, so disabled!
             * If you uncomment this you'll break the other states "when", eg. "liveview"!!!!!!!
             * Also, noone knows why && !menu_loader.active which causes the warning as noted above. Disabled as well.
             */
            /*
            when: !(System.system_state === System.StateUpgrade || Upgrader.isProcessing)
                  && !menu_loader.active
            */

            PropertyChanges { target: root; focus: true; restoreEntryValues: false }
            PropertyChanges { target: grid; visible: true }
            PropertyChanges { target: menu_loader; x: root.x + root.width; visible: true; restoreEntryValues: false }
            PropertyChanges {
                target: root; acceptKeys: true
            }
        },
        State {
            name: "camera_menu"
            StateChangeScript { script:
                {
                    menu_loader.setSource("qrc:///mainmenu/Menu.qml", { "text": QT_TR_NOOP("CAMERA SETTINGS"), "anchors.fill": "parent", "focus": true })
                }
            }
            PropertyChanges { target: menu_loader; itemValues: MenuItems.cameraMenuItems; active: true; x: root.x - constants.viewEndLineWidth; width: root.width + constants.viewEndLineWidth }
            PropertyChanges { target: swipe_area; drag.minimumX: root.x - constants.viewEndLineWidth}
            PropertyChanges { target: BodySync; currentState: BodySync.MENU; restoreEntryValues: false }

        },
        State {
            name: "add_favorite"
            PropertyChanges { target: menu_loader; populate: true}
            StateChangeScript { script:
                {
                    menu_loader.itemValues = MenuItems.developmentMenuItems;
                    menu_loader.setSource("qrc:///components/controls/FavoriteAddSelector.qml", { "anchors.fill": "parent", "targetModel": grid.model, "favoriteModel": favoriteModel })
                }
            }
            PropertyChanges { target: menu_loader; active: true; x: root.x }
            PropertyChanges { target: menu_loader; visible: true; restoreEntryValues: false }
            PropertyChanges { target: BodySync; currentState: BodySync.MENU; restoreEntryValues: false }
        },

        State {
            name: "settings_menu"
            StateChangeScript { script: {
                    menu_loader.setSource("qrc:///mainmenu/Menu.qml", { "text": QT_TR_NOOP("GENERAL SETTINGS"), "anchors.fill": "parent" });
                }
            }
            PropertyChanges { target: menu_loader; itemValues: MenuItems.getSettingsMenuItems(prodinfo.wifiAvailable); active: true; x: root.x - constants.viewEndLineWidth; width: root.width + constants.viewEndLineWidth }
            PropertyChanges { target: swipe_area; drag.minimumX: root.x - constants.viewEndLineWidth}
            PropertyChanges { target: BodySync; currentState: BodySync.MENU; restoreEntryValues: false }
        },
        State {
            name: "video_menu"
            StateChangeScript { script: {
                    menu_loader.setSource("qrc:///mainmenu/Menu.qml", { "text": QT_TR_NOOP("VIDEO SETTINGS"), "anchors.fill": "parent" })
                }
            }
            PropertyChanges { target: menu_loader; itemValues: MenuItems.videoMenuItems; active: true; x: root.x - constants.viewEndLineWidth; width: root.width + constants.viewEndLineWidth }
            PropertyChanges { target: swipe_area; drag.minimumX: root.x - constants.viewEndLineWidth}
            PropertyChanges { target: BodySync; currentState: BodySync.MENU; restoreEntryValues: false }
        }
    ]
    transitions: [
        Transition {
            to: "camera_menu,video_menu,settings_menu,add_favorite"
            ScriptAction {
                script: {
                    stopMainWheelTimeout()
                }
            }
        },
        Transition {
            from: ""
            ScriptAction {
                script: {
                    stopMainWheelTimeout()
                }
            }
        }
    ]

    FavoriteModel {
        id: favoriteModel
        wifiAvailable: prodinfo.wifiAvailable
    }

    // This is to make sure that any favorites in the stored configuration from en earlier software version has any
    // items that is not available or implemented anymore. This populates a list of the available items that then
    // is compared with the favorites list stored in the configuration.
    function addImplementedItems(sectionItems)
    {
        sectionItems.forEach(function(v)
        {
            var isDemo = (typeof v.demo !== 'undefined') && (v.demo !== undefined && v.demo);
            var isEnabled = (typeof v.enableCond === 'undefined') || v.enableCond === undefined || v.enableCond === "" || eval(v.enableCond)
            if((v.settingsList !== "") /*&& !FavoriteModel.isInList(v.settingsList)*/ && (!isDemo || !guiconfig.hideDemoItems))
            {
                favoriteModel.addImplementedMenuItem(v.settingsList, isEnabled)
            }
        });
    }

    function setAvailableFavoriteItems()
    {
        // Populate the various implemented menus to the "available" list.
        favoriteModel.clearImplementedMenuItemList()
        addImplementedItems(MenuItems.cameraMenuItems)
        addImplementedItems(MenuItems.videoMenuItems)
        addImplementedItems(MenuItems.getSettingsMenuItems(prodinfo.wifiAvailable))

        // Construct the favorites from configuration, can only be done after this point.
        favoriteModel.reReadModel();
    }

    Component.onCompleted: {
        setAvailableFavoriteItems()
    }

    // Let the favorite list be dynamically changed
    Connections{
        target: prodinfo
        onWifiRegionChanged: setAvailableFavoriteItems()
    }
    Connections {
        target: configstore
        onCameraTypeChanged: setAvailableFavoriteItems()
    }
    Connections {
        target: cambody
        // Changing camera system may enable or disable some favorite items.
        onCapabilitiesChanged: setAvailableFavoriteItems()
        onHts_attachedChanged: setAvailableFavoriteItems()
    }
    Connections {
        target: suc
        // Changing camera system may enable or disable some favorite items.
        onCambody_attachedChanged: setAvailableFavoriteItems()
    }
    Connections {
        target: BodySync
        // Changing Dial mode may enable or disable some favorite items.
        onCurrentDialModeChanged: setAvailableFavoriteItems()
    }

    // This loader pre-load SettingsGeneric
    // in order to reduce load time when menu is activated.
    // Hopefully it will not be garbage collected and thrown away before that
    Loader {
        objectName: "settingsGeneric_Loader"
        visible: false
        active: true
        source: "qrc:///settings/SettingsGeneric.qml"
        focus: false
        asynchronous: true
        // Let the QML stay in memory
        onLoaded: {
            source = ""
            active = false
            console.log("Settings generic is loaded")
        }
    }
}
