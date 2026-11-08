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
        mainWheelTimer.restart();
    }
    function stopMainWheelTimeout()
    {
        mainWheelTimer.stop();
    }
    function closeMenu()
    {
        var r = menu_loader.item
        if((r !== 'undefined') && (r !== null) && (typeof r.closeSubMenus === 'function'))
        {
            r.closeSubMenus()
        }
        root.state = ""
        GlobalStateInfo.preventTopSwipe = false
    }
    function closeMainScreen()
    {
        closeMain()
    }
    function loadCameraMenuItem(subMenu, menuItem)
    {
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
            if (root.state === "")
                event.accepted = false
            else
                root.closeMenu()
        } else if (MKeys.pressedFn("F2", event.key))
        {
            camera_icon_wedge.forceShowHighlite = true
            root.state = "camera_menu"
        }
        else if (MKeys.pressedFn("STAR", event.key))
        {
            video_icon_wedge.forceShowHighlite = true
            root.state = "video_menu"
        }
        else if (MKeys.pressedFn("F4", event.key))
        {
            settings_icon_wedge.forceShowHighlite = true
            root.state = "settings_menu"
        }
        else if(MKeys.pressedFn("RIGHT", event.key) || MKeys.pressedFn("DOWN", event.key)) {
            if(!(grid.focus || camera_icon_wedge.focus || settings_icon_wedge.focus || video_icon_wedge.focus))
                settings_icon_wedge.focus = true
        }
        else if(MKeys.pressedFn("LEFT", event.key)) {
            grid.focus = true
        }
        else if(MKeys.pressedFn("UP", event.key)) {
            if(!(grid.focus || camera_icon_wedge.focus || settings_icon_wedge.focus || video_icon_wedge.focus))
                camera_icon_wedge.focus = true
        }
        else if ((root.state === "") && MKeys.pressedFnAcc("AE_L", event))
        {
        }
        else
            event.accepted = false
    }
    Keys.onReleased: {
        event.accepted = false
        if (MKeys.pressedFnAcc("F2", event))
        {
            camera_icon_wedge.forceShowHighlite = false
        }
        else if (MKeys.pressedFnAcc("STAR", event))
        {
            video_icon_wedge.forceShowHighlite = false
        }
        else if (MKeys.pressedFnAcc("F4", event))
        {
            settings_icon_wedge.forceShowHighlite = false
        }
    }
    StatusRow {
        anchors.right: root.state === "" ? iconsBackWedge.left : parent.right
        hideStatusIcons: root.hideStatusIcons
        hideTopBatteryIcon: root.hideTopBatteryIcon
        z: 1
    }
    Text {
        id: header
        text: qsTr("MAIN MENU") + guiconfig.emptyString
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -iconsBackWedge.width / 2
        anchors.top: parent.top
        anchors.topMargin: constants.headerVerticalOffset
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        font.capitalization: Font.AllUppercase
        font.family: constants.menuItemFontName
    }
    Rectangle {
        id: iconsBackWedge
        color: constants.iconsBackWedgeColor
        visible: true
        width: constants.iconsBackWedgeWidth
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }
        Column {
            id: big_icons_wedge
            anchors {
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -9-5
                rightMargin: 5
                right: parent.right
                topMargin: parent.margin
            }
            spacing: 31
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
        }
    }
    MouseArea {
        anchors.fill: root
        enabled: grid.remove
        onClicked: {
            grid.remove = false
        }
    }
    function bestFirstPosition(lastIcon, limit)
    {
        var startIndex = lastIcon * 3 + 2;
        while(startIndex >= limit)
            --startIndex
        return startIndex
    }
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
        cellWidth: width / 3
        cellHeight: 149
        opacity: root.childOpacity
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        visible: true
        model: favoriteModel
        anchors.left: parent.left
        anchors.leftMargin: gridSideMargin
        anchors.right: iconsBackWedge.left
        anchors.rightMargin: gridSideMargin
        height: cellHeight * 3
        anchors.top: parent.top
        anchors.topMargin: 50
        keyNavigationWraps: true
        highlightFollowsCurrentItem: false
        currentIndex: -1
        property bool remove: false
        property int removeIndex: -1
        property int lastIndex: -1
        property int fromCtrl: -1
        onFocusChanged: {
            if (!focus) {
                lastIndex = currentIndex
                currentIndex = -1
            }
            else {
                startMainWheelTimeout()
                if (currentIndex < 0 || currentIndex >= count) {
                    if (-1 === lastIndex) {
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
            }
            else if(MKeys.pressedFn("LEFT", event.key)) {
                if(-1 == grid.currentIndex && -1 != grid.lastIndex)
                    grid.currentIndex = grid.lastIndex
                else
                    keyLeftFromGridWedge(grid.currentIndex)
            }
            else if(MKeys.pressedFn("UP", event.key)) {
                if(-1 == grid.currentIndex && -1 != grid.lastIndex)
                    grid.currentIndex = grid.lastIndex
                else
                    keyUpFromGridWedge(grid.currentIndex)
            }
            else if(MKeys.pressedFn("DOWN", event.key)) {
                if(-1 == grid.currentIndex && -1 != grid.lastIndex)
                    grid.currentIndex = grid.lastIndex
                else {
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
                    grid.currentIndex = -1
                }
                function gotClick()
                {
                    if (grid.remove && (grid.removeIndex === index))
                    {
                        grid.model.remove(index)
                        grid.remove = false
                        grid.currentIndex = -1
                    }
                    else if (selectable && settingsList === "cameraSettingsLiveView")
                    {
                        Camera.setLiveViewState(true)
                    }
                    else if(selectable && menu_loader.visible && (root.state === ""))
                    {
                        stopMainWheelTimeout()
                        grid.remove = false
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
                if(gridPositionItem !== null)
                {
                    fakeImage.x = gridPositionItem.x
                    fakeImage.y = gridPositionItem.y + fakeImage.height/2
                }
            }
            else if ((dragIndex === grid.removeIndex) && (newIndex !== -1) )
            {
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
            if("generalSettingsAbout" === menuName) {
                suc.requestLensFirmwareVersion()
                suc.requestLensCounter()
            }
        }
    }
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
                if (drag.target.x > (root.x + root.width / constants.swipeLengthDividor))
                {
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
            property string subItem: ""
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
            Keys.onPressed: {
                if(MKeys.pressedFnAcc("ESCAPE", event))
                {
                    active = false;
                    root.closeMenu()
                }
                if(!MKeys.pressedFnAcc("LEFT", event))
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
    function addImplementedItems(sectionItems)
    {
        sectionItems.forEach(function(v)
        {
            var isDemo = (typeof v.demo !== 'undefined') && (v.demo !== undefined && v.demo);
            var isEnabled = (typeof v.enableCond === 'undefined') || v.enableCond === undefined || v.enableCond === "" || eval(v.enableCond)
            if((v.settingsList !== "")  && (!isDemo || !guiconfig.hideDemoItems))
            {
                favoriteModel.addImplementedMenuItem(v.settingsList, isEnabled)
            }
        });
    }
    function setAvailableFavoriteItems()
    {
        favoriteModel.clearImplementedMenuItemList()
        addImplementedItems(MenuItems.cameraMenuItems)
        addImplementedItems(MenuItems.videoMenuItems)
        addImplementedItems(MenuItems.getSettingsMenuItems(prodinfo.wifiAvailable))
        favoriteModel.reReadModel();
    }
    Component.onCompleted: {
        setAvailableFavoriteItems()
    }
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
        onCapabilitiesChanged: setAvailableFavoriteItems()
        onHts_attachedChanged: setAvailableFavoriteItems()
    }
    Connections {
        target: suc
        onCambody_attachedChanged: setAvailableFavoriteItems()
    }
    Connections {
        target: BodySync
        onCurrentDialModeChanged: setAvailableFavoriteItems()
    }
    Loader {
        objectName: "settingsGeneric_Loader"
        visible: false
        active: true
        source: "qrc:///settings/SettingsGeneric.qml"
        focus: false
        asynchronous: true
        onLoaded: {
            source = ""
            active = false
            console.log("Settings generic is loaded")
        }
    }
}
