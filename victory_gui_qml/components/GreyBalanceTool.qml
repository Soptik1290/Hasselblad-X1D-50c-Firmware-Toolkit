import QtQuick 2.5
import com.hasselblad.storage 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.farm 1.0
import com.hasselblad.settings 1.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.globalstateinfo 1.0
import "qrc:///components"
import "qrc:///components/popups"
import "qrc:///settings"
import "qrc:///settings/components"
import "qrc:///components/buttons"
import "qrc:///common"
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    objectName: "GreyBalanceTool_root"
    color: "black"
    id: root
    focus: true
    property real sizeFactor: Math.min(width / 640.0, height / 480.0)
    property int currentTemp: 0xffff
    property int currentTint: 0xffff
    property int displayedTemp: 0xffff
    property int displayedTint: 0xffff
    property bool exitButtonHighlighted: false
    property bool setButtonHighlighted: false
    property bool setButtonEnabled: false
    property string progressStr: ""
    property int workingCounter: -1
    property bool isQueued: false
    property bool discardRequest: false
    property string nextPath: ""
    property int nextPoint: 0
    property int nextSize: 0
    property bool loadLastImage: false
    property int startIndex: -1
    property bool startedFromMenu: true
    property bool waitForBrowseFinished: false
    property bool dataInitialized: false
    property bool delegateCompleted: false
    signal showControl()
    readonly property int exit_BUTTON_INDEX: 0
    readonly property int set_BUTTON_INDEX: 1
    onCurrentTempChanged: updateSetButtonEnabled()
    onCurrentTintChanged: updateSetButtonEnabled()
    Connections {
        target: displayTimer
        onRunningChanged: root.updateSetButtonEnabled()
    }
    function updateSetButtonEnabled() {
        if (!displayTimer.running) {
            setButtonEnabled = (currentTemp != 0xffff && currentTint != 0xffff)
        }
    }
    Keys.onPressed: {
        highlightTimer.restart()
        event.accepted = true
        if (event.isAutoRepeat) {
            return
        } else if(MKeys.pressedFn("LEFT", event.key)) {
            media_list.decrementCurrentIndex()
        } else if(MKeys.pressedFn("RIGHT", event.key)) {
            media_list.incrementCurrentIndex()
        } else if (MKeys.pressedFn("STAR", event.key)) {
            if (exitButtonHighlighted) {
                closeTool(false)
            } else if (setButtonHighlighted) {
                setManualWB()
                closeTool(true)
            }
            event.accepted = true
            return
        } else if (MKeys.pressedFn("AF_D", event.key) && setButtonEnabled) {
            setManualWB()
            closeTool(true)
        } else if (MKeys.pressedFn("NAVUP", event.key) || MKeys.pressedFn("NAVDOWN", event.key)) {
            var selectedIndex = exit_BUTTON_INDEX
            if (!setButtonEnabled || setButtonHighlighted) {
                selectedIndex = exit_BUTTON_INDEX
            } else if (exitButtonHighlighted) {
                selectedIndex = set_BUTTON_INDEX
            }
            exitButtonHighlighted = (selectedIndex === exit_BUTTON_INDEX)
            setButtonHighlighted = (selectedIndex === set_BUTTON_INDEX)
        } else if (MKeys.pressedFnAcc("INTERVAL", event) || MKeys.pressedFnAcc("BRACKETING", event)) {
            event.accepted = true
        } else {
            event.accepted = false
        }
    }
    function clearHighlight() {
        exitButtonHighlighted = false
        setButtonHighlighted = false
    }
    function closeTool(showCtrl) {
        if (startedFromMenu) {
            if (showCtrl) {
                closeMainScreen()
            } else {
                closeMenu()
            }
        } else {
            showControl()
        }
    }
    Timer {
        id: highlightTimer
        interval: constants.wheelTimeoutTimeMs
        onTriggered: {
            clearHighlight()
        }
    }
    ListView {
        id: media_list
        model: (ContentModel.isBrowsing || waitForBrowseFinished) ? null : SortedContentModel
        anchors.fill: parent
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightFollowsCurrentItem: true
        preferredHighlightBegin: root.x
        preferredHighlightEnd: root.x + root.width
        highlightMoveVelocity: -1
        highlightRangeMode: ListView.StrictlyEnforceRange
        layoutDirection: Qt.LeftToRight
        spacing: 20
        boundsBehavior: Flickable.DragOverBounds | Flickable.CustomBounds
        BoundsEffectGradient {
            parent: media_list
        }
        delegate: Component {
            FocusScope {
                width: media_list.width
                height: media_list.height
                focus: true
                Rectangle{
                    color: "black"
                    visible: !ListView.atXEnd
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: list_img.left
                    }
                }
                Photo {
                    id: list_img
                    anchors.fill: parent
                    source: image
                    onStatusChanged: {
                        if (status === Image.Ready) {
                            console.log("fileType:", fileType)
                            console.log("fileName", image)
                            if (media_list.currentIndex === index) {
                                if (!dataInitialized) {
                                    delegateUpdateCustomWB()
                                }
                            }
                        }
                    }
                    GreyBalanceOverlay {
                        id: overlay
                        anchors.fill: parent
                        Binding on metaImgName {
                            when: display !== undefined
                            value: display
                        }
                        greyBalanceTemp: (media_list.currentIndex !== index) ? 0xffff : displayedTemp
                        tint: (media_list.currentIndex !== index) ? 0xffff : displayedTint
                        progressDots: displayTimer.running ? "" : progressStr
                        metaVolumeType: ContentModel.browseVolume
                    }
                    MouseArea {
                        id: clickArea
                        anchors.fill: parent
                        onClicked: {
                            var minY = eyeDropper.topOverlayHeight + eyeDropper.crossHeight/2
                            var limitY = list_img.height - eyeDropper.bottomOverlayHeight
                            var maxY = limitY - eyeDropper.crossHeight/2
                            var minX = eyeDropper.crossWidth/2
                            var maxX = list_img.width - eyeDropper.crossWidth/2
                            var xPos = mouse.x < minX ? minX + eyeDropper.crossBorderWidth :
                                       mouse.x > maxX ? maxX :
                                                        mouse.x
                            var yPos = mouse.y < minY ? minY :
                                       mouse.y > maxY ? maxY :
                                                        mouse.y
                            if (mouse.y > limitY) {
                                return
                            }
                            eyeDropper.x = xPos - eyeDropper.width/2
                            eyeDropper.y = yPos - eyeDropper.height/2
                            list_img.delegateUpdateCustomWB()
                        }
                        onPressedChanged: {
                            if (eyeDropper.crossY === eyeDropper.topOverlayHeight + eyeDropper.crossHeight/2) {
                                eyeDropper.y = eyeDropper.y+1
                            }
                        }
                    }
                    EyeDropper {
                        id: eyeDropper
                        x: parent.width/2 - width/2
                        y: parent.height/2 - height/2
                        function reset() {
                            eyeDropper.x = parent.width/2 - eyeDropper.width/2
                            eyeDropper.y = parent.height/2 - eyeDropper.height/2
                            list_img.delegateUpdateCustomWB()
                        }
                        onToolReleased: {
                            clearHighlight()
                            list_img.delegateUpdateCustomWB()
                        }
                        topOverlayHeight: constants.topMetaHeight
                        bottomOverlayHeight: buttonRect.height
                        onDragAtTopChanged: {
                            GlobalStateInfo.preventTopSwipe = dragAtTop
                        }
                    }
                    function delegateUpdateCustomWB() {
                        nextPath = ContentModel.path + "/" + display
                        nextPoint = farm.combine((1.0*eyeDropper.crossX)/width, (1.0*eyeDropper.crossY)/height)
                        nextSize = farm.combine((1.0*eyeDropper.crossWidth)/width, (1.0*eyeDropper.crossHeight)/height)
                        updateCustomWB()
                    }
                    Rectangle {
                        id: buttonRect
                        color: "black"
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: exitButton.height + 2*exitButton.anchors.bottomMargin
                        MenuButton {
                            id: exitButton
                            anchors {
                                bottom: parent.bottom
                                bottomMargin: 10
                                left: parent.left
                                leftMargin: 10
                            }
                            maxWidth: parent.width * .5 - anchors.leftMargin * 2
                            minWidth: maxWidth
                            height: constants.buttonHeight
                            highlight: exitButtonHighlighted
                            borderColorHighLight: constants.buttonBorderHighlightColor
                            onClicked: closeTool(false)
                            text: qsTr("Exit") + guiconfig.emptyString
                        }
                        MenuButton{
                            id: setButton
                            anchors {
                                bottom: parent.bottom
                                bottomMargin: 10
                                right: parent.right
                                rightMargin: 10
                            }
                            maxWidth: parent.width * .5 - anchors.rightMargin * 2
                            minWidth: maxWidth
                            height: constants.buttonHeight
                            highlight: setButtonHighlighted
                            borderColorHighLight: constants.buttonBorderHighlightColor
                            isEnabled: setButtonEnabled
                            onClicked: {
                                setManualWB()
                                closeTool(true)
                            }
                            text: qsTr("Set") + guiconfig.emptyString
                        }
                    }
                }
                Connections {
                    target: media_list
                    onCurrentIndexChanged: {
                        if (media_list.currentIndex === index) {
                            if (workingTimer.running) {
                                discardRequest = true
                            }
                            eyeDropper.reset()
                            GlobalStateInfo.preventTopSwipe = false
                            clearHighlight()
                            highlightTimer.stop()
                        }
                    }
                }
                Component.onCompleted: {
                    delegateCompleted = true
                    if (loadLastImage) {
                        loadLastImageFunc()
                    }
                }
            }
        }
    }
    onNoCardAvailableChanged: {
        if (!noCardAvailable) {
            waitForBrowseFinished = true
        }
    }
    property bool noCardAvailable: (ContentModel.card0Status === ContentModel.STORAGE_ABSENT) && (ContentModel.card1Status === ContentModel.STORAGE_ABSENT)
    property bool isInImageFolder: ContentModel.path.search(/HASBL/) > 0 && !noCardAvailable
    NotificationPopup {
        objectName: "GreyBalanceTool_emptyFolder"
        id: emptyFolder
        visible: noCardAvailable || (SortedContentModel.listSize === 0 && isInImageFolder && !ContentModel.isBrowsing)
        text:  guiconfig.emptyString + ((!System.isTethered && noCardAvailable) ? qsTr("No Card") : qsTr("No images"))
        subText: guiconfig.emptyString + ((!System.isTethered && noCardAvailable) ? "" : qsTr("At least one image is<br>required to use the tool."))
    }
    Connections {
        target: ContentModel
        onIsBrowsingChanged: {
            if (!ContentModel.isBrowsing && waitForBrowseFinished) {
                waitForBrowseFinished = false
                loadLastImageFunc()
                if (media_list.count === 1) {
                    media_list.contentX = 50
                }
            }
        }
        onCard0StatusChanged: {
            root.closeTool(true)
        }
        onCard1StatusChanged: {
            root.closeTool(true)
        }
    }
    BatteryIndicatorScaled {
        id: battIcon
        showOnWarningOnly: true
        batteryWidth: 19
        height: 45
        isOutlined: true
        anchors {
            right: parent.right
            rightMargin: 30
            top:parent.top
            topMargin: 50
        }
        z:1
    }
    Connections {
        target: configstore
        onExpModeChanged: {
            if(configstore.ExpMode === Config.ExpMode_FullAuto) {
                closeTool(false)
            }
        }
    }
    Connections {
        target: farm
        onCustomWBDataChanged: {
            if (discardRequest) {
                discardRequest = false
                workingCounter = 0
                isQueued = false
                farm.updateCustomWB(nextPath, nextPoint, nextSize)
                return
            }
            workingTimer.stop()
            displayTimer.stop()
            workingCounter = -1
            if (isQueued) {
                isQueued = false
                root.updateCustomWB()
            } else {
                if (farm.customWBStatus) {
                    root.currentTemp = farm.customWBTemp
                    root.currentTint = farm.customWBTint
                }
                root.displayedTemp = root.currentTemp
                root.displayedTint = root.currentTint
            }
        }
    }
    Timer {
        id: workingTimer
        interval: 500
        onTriggered: {
            if (workingCounter >= 0) {
                workingCounter++
                workingTimer.start()
            }
        }
    }
    onWorkingCounterChanged: {
        if (workingCounter > 10) {
            workingTimer.stop()
            workingCounter = -1
            progressStr = ""
            return
        }
        if (workingCounter >= 0) {
            var ix = workingCounter % 3
            progressStr = ((ix === 0) ? " .  " :
                           (ix === 1) ? " .. " :
                                        " ...")
        } else {
            progressStr = ""
        }
    }
    Timer {
        id: displayTimer
        interval: 100
        onTriggered: {
            displayedTemp = currentTemp
            displayedTint = currentTint
        }
    }
    function setManualWB() {
        if (currentTemp !== 0xffff) {
            Camera.WBMode = 6
            configstore.WBManualTemp = currentTemp
        }
        if (currentTint !== 0xffff) {
            configstore.WBManualTint = currentTint
        }
    }
    function updateCustomWB() {
        dataInitialized = true
        displayTimer.restart()
        var ongoing = workingCounter >= 0
        workingCounter = 0
        currentTemp = 0xffff
        currentTint = 0xffff
        workingTimer.restart()
        if (ongoing) {
            isQueued = true
        } else {
            farm.updateCustomWB(nextPath, nextPoint, nextSize)
        }
    }
    function loadLastImageFunc() {
        if (media_list.count > 0 && isInImageFolder) {
            loadLastImage = false
            media_list.currentIndex = media_list.count -1
            media_list.positionViewAtIndex(media_list.count -1, ListView.End)
        }
    }
    Component.onCompleted: {
        if(configstore.ExpMode === Config.ExpMode_FullAuto) {
            closeTool(false)
            return
        }
        SortedContentModel.showOnlyImages(true)
        if (noCardAvailable) {
            return
        }
        if (!isInImageFolder) {
            ContentModel.changeToActiveDir()
            waitForBrowseFinished = true
        } else if (startIndex !== -1) {
            var proxyIndex = SortedContentModel.srcToProxyIndex(startIndex)
            media_list.currentIndex = proxyIndex
            media_list.positionViewAtIndex(proxyIndex, ListView.Center)
        } else {
            if (!delegateCompleted) {
                loadLastImage = true
            } else {
                media_list.currentIndex = media_list.count -1
                media_list.positionViewAtIndex(media_list.count -1, ListView.End)
            }
        }
        if(typeof hideStatusIcons !== "undefined")
        {
            hideStatusIcons = true
        }
        if(typeof hideTopBatteryIcon !== "undefined")
        {
            hideTopBatteryIcon = true
        }
    }
    Component.onDestruction: {
        SortedContentModel.showOnlyImages(false)
        GlobalStateInfo.preventTopSwipe = false
        if(typeof hideStatusIcons !== "undefined")
        {
            hideStatusIcons = false
        }
        if(typeof hideTopBatteryIcon !== "undefined")
        {
            hideTopBatteryIcon = false
        }
    }
}
