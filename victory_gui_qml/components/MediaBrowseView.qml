import QtQuick 2.5
import com.hasselblad.storage 1.0
import com.hasselblad.video 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.error 1.0
import com.hasselblad.farm 1.0
import com.hasselblad.settings 1.0
import com.hasselblad.config 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.sound 1.0
import "qrc:///browseview"
import "qrc:///components"
import "qrc:///components/popups"
import "qrc:///components/buttons"
import "qrc:///settings"
import "qrc:///settings/components"
import "qrc:///scripts/Keys.js" as MKeys
import "qrc:///liveview"
Rectangle {
    objectName: "MediaBrowseView_root"
    color: "black"
    id: root
    focus: true
    state: (model.source.pathType === ContentModel.PATH_TYPE_FILES) && (model.listSize > 0) ? "list" : "grid"
    property alias simulation: media_grid.clip
    property int nextIndex: -1
    property int initIndex: -1
    property alias model: media_grid.model
    property alias mediaListCurrentIndex: media_list.currentIndex
    property alias mediaGridCurrentIndex: media_grid.currentIndex
    property int dividerWidth: 2
    property bool hasLoadedCurrent: false
    signal directoryUpSelected()
    signal isIn9View(bool val)
    property bool usedInEVF: false
    property bool is9ViewActive: false
    property bool isInstantPreview: false
    property bool fromBrowseDir: false
    property bool keepStateGridOnSizeChange: false
    property bool fromVideoPlayback: false
    property bool isInStartState: true
    property bool allowDimming: true
    property bool directoryUpHighLight: false
    property bool addFolderHighLight: false
    property bool filterButtonHighLight: false
    property int clickInterval: 150
    property real touchpadZoomPanStepSize: 0.09
    property bool imageRatingActive: false
    property bool pinching: false
    property real zoomFactor: Math.exp(Math.log(guiconfig.maxImageXSize / root.width) / constants.numberZoomSteps)
    signal preventIdleTimeout(bool prevent)
    signal currentItemLoaded()
    signal hideInstantAVTV()
    signal keyPressed()
    Connections {
        target: ContentModel
        onImageAdded: root.checkNewImage()
        onCard0AvailableChanged: root.resetCurrentIndexOnNoMedia(target.card0Available)
        onCard1AvailableChanged: root.resetCurrentIndexOnNoMedia(target.card1Available)
    }
    Component.onCompleted: {
        console.log("loaded MediaBrowseView, usedInEVF", usedInEVF)
        previousActiveCard = (ContentModel.browseVolume !== 255) ? ContentModel.browseVolume : 0
        SortedContentModel.showOnlyImages(false)
        if (!usedInEVF) {
            checkNewImage()
        }
    }
    function closeAllPopups()
    {
        deletePopupLoader.active = false
    }
    function doDirectoryUp()
    {
        directoryUpHighLight = false
        filterButtonHighLight = false
        media_grid.model.exitDir()
        media_grid.currentIndex = media_list.count - 1
        media_grid.positionViewAtIndex(media_grid.currentIndex, GridView.Center)
        directoryUpSelected()
    }
    function checkNewImage() {
        var index = root.model.getAckAddedImage();
        if (index >= 0) {
            closeAllPopups()
            root.nextIndex = index
            root.state = "list"
            return true
        } else
            return false
    }
    function resetCurrentIndexOnNoMedia(available) {
        if (!available) {
            if('undefined' !== root && null !== root && undefined !== root)
                root.resetCurrentIndex()
        }
    }
    function deleteImage() {
        if (System.isTethered)
            return
        if (((root.state == "list") || (root.state == "zooming")) && (model.listSize > 0))
        {
            root.state = "list"
            console.log("Delete initiated. CurrentIndex:", media_list.currentIndex)
            if(SortedContentModel.getData(media_list.currentIndex, ContentModel.TypeRole) === ContentModel.Image)
            {
                deletePopupLoader.deleteText = qsTr("Delete this image?")
            }
            else
            {
                deletePopupLoader.deleteText = qsTr("Delete this video?")
            }
            deletePopupLoader.deleteFile = false
            deletePopupLoader.active = true
        }
    }
    onFocusChanged: {
        if(!focus)
        {
            closeAllPopups()
        }
    }
    onNextIndexChanged: {
        hasLoadedCurrent = false
        if (nextIndex >= 0 && root.state == "list")
            setNextIndex()
    }
    function setNextIndex() {
        if (initIndex >= 0) {
            media_list.currentIndex = initIndex
            initIndex = -1
        } else if((media_list.count > 0) && (root.nextIndex == -1))
        {
            media_list.currentIndex = media_list.count - 1
        }
        else
        {
            media_list.currentIndex = root.nextIndex
        }
        media_list.positionViewAtIndex(media_list.currentIndex, ListView.Center)
        root.nextIndex = -1
    }
    function resetCurrentIndex() {
        root.nextIndex = -1
        media_grid.currentIndex = -1
        media_list.currentIndex = -1
    }
    Connections {
        target: SortedContentModel
        onListSizeChanged: {
            if(root.state === "list")
                console.log("Model size changed:", media_list.count, media_list.currentIndex)
            if(listSize !== 0)
            {
                console.log("newSize", listSize)
                if(root.state === "grid")
                {
                    if (keepStateGridOnSizeChange) {
                        fromBrowseDir = true
                    }
                    if(media_grid.currentIndex === -1)
                    {
                        media_grid.currentIndex = listSize - 1
                        root.state = "grid"
                    }
                    media_list.positionViewAtIndex(media_grid.currentIndex, ListView.Center)
                }
                else if(root.state === "list")
                {
                    if(media_list.currentIndex === -1)
                    {
                        media_list.currentIndex = listSize - 1
                    }
                    media_list.positionViewAtIndex(media_list.currentIndex, ListView.Center)
                }
            }
            keepStateGridOnSizeChange = false
        }
    }
    Keys.onPressed: {
        if (event.isAutoRepeat)
        {
            event.accepted = true
            return
        }
        root.keyPressed()
        if(MKeys.pressedFnAcc("ESCAPE", event))
        {
            if (root.state === "zooming" || root.state === "video_playback")
                root.state = "list"
            else if (!System.isTethered && root.state === "list")
                root.state = "grid"
            else if (media_grid.model.source.parentAvailable && (root.state === "grid"))
            {
                doDirectoryUp()
            }
        }
        else if (MKeys.pressedFnAcc("OVEREXP", event))
        {
            configstore.OverExposureWarning = !configstore.OverExposureWarning;
        }
        else if (root.state == "grid")
        {
            if(emptyFolder.visible)
            {
                if(MKeys.pressedFnAcc("NAVLEFT", event) || MKeys.pressedFnAcc("UP", event))
                {
                    if (!directoryUpHighLight && !filterButtonHighLight) {
                        directoryUpHighLight = true
                    }
                    else if (directoryUpHighLight) {
                    }
                    else {}
                    media_grid.currentIndex = -1
                }
                else if(MKeys.pressedFnAcc("NAVRIGHT", event) || MKeys.pressedFnAcc("DOWN", event))
                {
                    directoryUpHighLight = false
                }
                else if(MKeys.pressedFnAcc("SELECT", event))
                {
                    if(root.directoryUpHighLight && media_grid.model.source.parentAvailable)
                    {
                        doDirectoryUp()
                    }
                }
            }
            else if(MKeys.pressedFnAcc("F2", event))
            {
                if(media_grid.currentIndex === 0)
                {
                    directoryUpHighLight = true
                    filterButtonHighLight = false
                    media_grid.currentIndex = -1
                }
                else if (media_grid.currentIndex < 0) {
                    if (!directoryUpHighLight && !filterButtonHighLight) {
                        directoryUpHighLight = true
                    }
                    else {}
                }
                else
                {
                    media_grid.moveCurrentIndexLeft()
                }
            }
            else if(MKeys.pressedFnAcc("STAR", event) || MKeys.pressedFnAcc("PLAY", event)
                    || MKeys.pressedFnAcc("ZOOM_IN", event))
            {
                if (model.listSize > 0)
                {
                    root.nextIndex = media_grid.currentIndex
                    root.state = "list"
                }
            }
            else if(MKeys.pressedFnAcc("F4", event))
            {
                if  (emptyFolder.visible)
                {
                    root.directoryUpHighLight = false
                    root.filterButtonHighLight = false
                }
                else if((media_grid.currentIndex < 0))
                {
                     {
                        root.directoryUpHighLight = false
                        if (media_grid.count > 0) {
                            media_grid.currentIndex = 0
                        }
                    }
                }
                else
                {
                    media_grid.moveCurrentIndexRight()
                }
            }
            else if(MKeys.pressedFnAcc("DELETE", event))
            {
                if (model.source.pathType === ContentModel.PATH_TYPE_FILES) {
                    if (root.state === "grid") {
                        keepStateGridOnSizeChange = true
                    }
                    root.state = "delete"
                }
            }
        }
        else
        {
            if(MKeys.pressedFnAcc("CROSS", event) && !ContentModel.isDeleting)
            {
                deleteImage()
            }
            else if((VideoControl.videoMode !== VideoControl.Playback) && (MKeys.pressedFnAcc("STAR", event) || MKeys.pressedFnAcc("ESCAPE", event)) &&
                    !Camera.inSession)
            {
                if (System.isTethered)
                    return
                if (configstore.imageRating) {
                    event.accepted = true
                    var rating = SortedContentModel.getData(media_list.currentIndex, ContentModel.RatingRole)
                    var fileType = SortedContentModel.getData(media_list.currentIndex, ContentModel.TypeRole)
                    if (fileType === ContentModel.Video) {
                        imageRateFailedPopup.error = imageRateFailedPopup.errorRateVideo
                        imageRateFailedPopup.openPopup = true
                    } else if (rating === Config.RatingUnknown) {
                        return
                    } else if (rating === Config.NoRatingTag) {
                        imageRateFailedPopup.error = imageRateFailedPopup.errorRateOldImage
                        imageRateFailedPopup.openPopup = true
                    } else {
                        imageRatingActive = true
                    }
                } else {
                    root.state = "grid"
                }
            }
        }
        if(MKeys.pressedFnAcc("TPDOUBLECLICK", event)) {
            if (usedInEVF && root.state == "zooming") {
                flick.contentWidth = flick.width
                flick.contentHeight = flick.height
                flick.contentX = 0
                flick.contentY = 0
                root.state = "list"
            }
        }
    }
    Binding {
        target: parent
        property: "preventControlScreenSwipe"
        value: media_grid.dragging || media_grid.flicking
    }
    GridView {
        objectName: "MediaBrowseView_media_grid"
        id: media_grid
        model: SortedContentModel
        visible: false
        onVisibleChanged: console.log("grid visible", visible)
        anchors.fill: parent
        cellWidth: root.width / 3
        cellHeight: root.height / 3
        snapMode: GridView.SnapToRow
        cacheBuffer: cellHeight
        boundsBehavior: guiconfig.isRunningSimulation() ? Flickable.StopAtBounds : (Flickable.DragOverBounds | Flickable.CustomBounds)
        BoundsEffectGradient {
            parent: media_grid
        }
        currentIndex: count - 1
        onCurrentIndexChanged: {
            if(currentIndex >= 0)
            {
                directoryUpHighLight = false
                filterButtonHighLight = false
            }
            console.log("media_grid.currentIndex:", currentIndex)
            if (currentIndex < 0 && count == 0) {
                SortedContentModel.updateListSize()
            }
        }
        highlightMoveDuration: 0
        highlight: Rectangle {
            id: highlightDelegate
            width: media_grid.cellWidth
            height: media_grid.cellHeight
            color: "transparent"
            border.color: constants.hblOrange
            border.width: 4
            z: 10
        }
        pressDelay: 200
        Keys.onPressed: {
            if (event.isAutoRepeat)
            {
                event.accepted = true
                return
            }
            root.keyPressed()
            if(MKeys.pressedFnAcc("LEFT", event))
            {
                if(currentIndex == 0)
                {
                    directoryUpHighLight = true
                    filterButtonHighLight = false
                    currentIndex = -1
                }
                else if (media_grid.currentIndex < 0) {
                    if (!directoryUpHighLight && !filterButtonHighLight) {
                        directoryUpHighLight = true
                    }
                    else {}
                }
                else
                {
                    moveCurrentIndexLeft()
                }
            }
            else if(MKeys.pressedFnAcc("UP", event))
            {
                if(currentIndex == 0)
                {
                    directoryUpHighLight = true
                    currentIndex = -1
                }
                else if(currentIndex < 0) {
                    if (!directoryUpHighLight && !filterButtonHighLight) {
                        directoryUpHighLight = true
                    }
                    else {}
                }
                else
                {
                    moveCurrentIndexUp()
                }
            }
            else if(MKeys.pressedFnAcc("DOWN", event))
            {
                if(currentIndex < 0)
                {
                    directoryUpHighLight = false
                    filterButtonHighLight = false
                    currentIndex = 0
                }
                else
                {
                    moveCurrentIndexDown()
                }
            } else if(MKeys.pressedFnAcc("RIGHT", event)) {
                if((currentIndex < 0))
                {
                    if (filterButtonHighLight) {
                        filterButtonHighLight = false
                        directoryUpHighLight = true
                    } else {
                        directoryUpHighLight = false
                        if (count > 0) {
                            currentIndex = 0
                        }
                    }
                }
                else
                {
                    moveCurrentIndexRight()
                }
            }
        }
        delegate: Item {
            id: grid_delegate
            visible: media_grid.visible
            width: media_grid.cellWidth
            height: media_grid.cellHeight
            property var itemModel: model
            Photo {
                id: grid_img
                visible: fileType === ContentModel.Image || (fileType === ContentModel.Video && state !== "failure")
                anchors.fill: parent
                fillMode: fileType === ContentModel.Video ? Image.PreserveAspectFit : Image.Stretch
                source: (media_grid.visible && (fileType === ContentModel.Image || fileType === ContentModel.Video)) ? image : grid_img.source
                showOverExposureMask: overexpose_behaviour.set && fileType === ContentModel.Image
            }
            Rectangle {
                visible: clickTimer.running || view9MouseArea.containsPress
                anchors.fill: parent
                opacity: 0.20
                color: "orange"
                Timer {
                    id: clickTimer
                    running: false
                    repeat: false
                    interval: root.clickInterval
                    onTriggered: grid_delegate.clicked()
                }
            }
            Rectangle {
                visible: !grid_img.visible
                color: "gray"
                anchors.fill: parent
            }
            Image {
                source: grid_img.visible ? "qrc:///icons/Video_play_small.png" : "qrc:///icons/Video_play_large.png"
                visible: fileType === ContentModel.Video
                anchors.centerIn: parent
            }
            Rectangle {
                visible: largeFolderIcon.visible
                anchors.fill: parent
                color: view9MouseArea.containsPress ? constants.hblOrange : "transparent"
            }
            Image {
                id: largeFolderIcon
                source: "qrc:///icons/FolderIconLarge.png"
                visible: fileType === ContentModel.Directory
                anchors.centerIn: parent
            }
            Text {
                visible: fileType !== ContentModel.Video && grid_img.status !== Image.Ready
                anchors.centerIn: largeFolderIcon
                text:  guiconfig.emptyString + display !== undefined ? display : qsTr("Loading...")
                color: "white"
                font.bold: true
                fontSizeMode: Text.Fit
            }
            MouseArea {
                id: view9MouseArea
                anchors.fill: parent
                enabled: true
                onClicked:
                {
                    clickTimer.start()
                    mouse.accepted = true
                }
                onDoubleClicked:
                {
                    grid_delegate.clicked()
                    mouse.accepted = true
                }
                onPressAndHold: {
                    if(!ContentModel.isDeleting)
                    {
                        if(fileType === ContentModel.Image || fileType === ContentModel.Video)
                        {
                            media_grid.currentIndex = index
                            deletePopupLoader.deleteText = fileType === ContentModel.Image ? qsTr("Delete this image?") : qsTr("Delete this video?")
                            root.state = "delete"
                        }
                    }
                }
                onPressed: { mouse.accepted = true; media_grid.currentIndex = index }
                propagateComposedEvents: false
            }
            Keys.onPressed: {
                if (event.isAutoRepeat)
                {
                    event.accepted = true
                    return
                }
                root.keyPressed()
                if(MKeys.pressedFnAcc("SELECT", event) ||
                   MKeys.pressedFn("TPDOUBLECLICK", event.key))
                {
                     if(root.directoryUpHighLight)
                    {
                        if(media_grid.model.source.parentAvailable)
                        {
                            doDirectoryUp()
                        }
                    }
                    else
                    {
                        clickTimer.start()
                    }
                }
                else
                {
                    event.accepted = false
                }
            }
            function clicked() {
                directoryUpHighLight = false
                filterButtonHighLight = false
                if ((fileType === ContentModel.Image) || (fileType === ContentModel.Video))
                {
                    root.nextIndex = index
                    media_list.enableMouseClick = false
                    media_list.currentIndex = index
                    root.state = "list"
                }
                else if (fileType === ContentModel.Directory)
                {
                    media_grid.model.enterDir(display)
                    media_grid.currentIndex = media_list.count - 1
                    media_grid.positionViewAtIndex(media_grid.currentIndex, GridView.Center)
                }
            }
        }
        Rectangle {
            width: 1
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: scrollbar.width / 2 + scrollbar.anchors.rightMargin
            visible: media_list.count > 9
        }
        Rectangle {
            id: scrollbar
            anchors.right: parent.right
            anchors.rightMargin: width / 2
            y: parent.visibleArea.yPosition * parent.height
            width: 10
            height: parent.visibleArea.heightRatio * parent.height
            color: "white"
            visible: media_list.count > 9
        }
    }
    Flickable {
        id: flick
        visible: false
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: parent.height
        property int maxContentWidth: flick_fullimg.status === Image.Ready ?
                                           flick_fullimg.implicitWidth :
                                           knownWidth
        property int maxContentHeight: flick_fullimg.status === Image.Ready ?
                                           flick_fullimg.implicitHeight :
                                           knownHeight
        onMaxContentWidthChanged: console.log("Flickable max width", maxContentWidth)
        signal pinchFinished()
        boundsBehavior: Flickable.StopAtBounds
        property int knownWidth
        property int knownHeight
        property real zoomScale
        property point zoomCenter
        property point zoomCenterOrig
        property int zoomInitialWidth
        property int zoomInitialHeight
        NumberAnimation on contentX {
            id: xAnimation
            duration: constants.zoomAnimateTime
            easing.type: Easing.Linear
        }
        NumberAnimation on contentY {
            id: yAnimation
            duration: constants.zoomAnimateTime
            easing.type: Easing.Linear
        }
        NumberAnimation on zoomScale {
            id: zoomScaleAnimation
            property bool requestOngoing: false
            easing.type: Easing.Linear
        }
        Connections {
            target: GlobalStateInfo
            onImgZoomPanXDirChanged: {
                if (usedInEVF && GlobalStateInfo.imgZoomPanXDir !== 0) {
                    var direction = GlobalStateInfo.imgZoomPanXDir < 0 ? -1 : 1
                    var newPos = 0
                    if(xAnimation.running)
                    {
                        xAnimation.stop()
                    }
                    xAnimation.duration = 100
                    xAnimation.from = flick.contentX
                    var relativeSpeed = (flick.width/2)*(1+flick.contentWidth/flick.maxContentWidth)
                    newPos = flick.contentX + direction*relativeSpeed*touchpadZoomPanStepSize
                    if(newPos < 0) {
                        newPos = 0
                    } else if(newPos + flick.width > flick.contentWidth) {
                        newPos = flick.contentWidth - flick.width
                    }
                    xAnimation.to = newPos
                    xAnimation.start()
                }
            }
            onImgZoomPanYDirChanged: {
                if (usedInEVF && GlobalStateInfo.imgZoomPanYDir !== 0) {
                    var direction = GlobalStateInfo.imgZoomPanYDir < 0 ? -1 : 1
                    var newPos = 0
                    if(yAnimation.running)
                    {
                        yAnimation.stop()
                    }
                    yAnimation.duration = 100
                    yAnimation.from = flick.contentY
                    var relativeSpeed = (flick.width/2)*(1+flick.contentWidth/flick.maxContentWidth)
                    newPos = flick.contentY + direction*relativeSpeed*touchpadZoomPanStepSize
                    if(newPos < 0) {
                        newPos = 0
                    } else if(newPos + flick.height > flick.contentHeight) {
                        newPos = flick.contentHeight - flick.height
                    }
                    yAnimation.to = newPos
                    yAnimation.start()
                }
            }
            onImgPinchDirChanged: {
                if (usedInEVF && GlobalStateInfo.imgPinchDir !== 0) {
                    if (root.state === "list") {
                        media_list.currentItem.initPinching()
                    } else {
                        var scale = GlobalStateInfo.imgPinchDir > 0 ? 0.9 : 1.1
                        flick.zoomFromPinch(scale)
                        zoom_timeout.restart()
                    }
                }
            }
            onImgPinchActiveChanged: {
                if (usedInEVF) {
                    if (!GlobalStateInfo.imgPinchActive) {
                        if (root.state === "zooming") {
                            zoom_timeout.restart()
                        }
                    }
                }
            }
        }
        function adjustContentX() {
            if (flick.contentX < 0)
            {
                flick.contentX = 0
            }
            else if((flick.contentX + flick.width) > flick.contentWidth)
            {
                flick.contentX = flick.contentWidth - flick.width
            }
        }
        function adjustContentY() {
            if (flick.contentY < 0)
            {
                flick.contentY = 0
            }
            else if ((flick.contentY + flick.height) > flick.contentHeight)
            {
                flick.contentY = flick.contentHeight - flick.height
            }
        }
        PinchArea {
            id: pinchArea
            width: Math.max(flick.contentWidth, flick.width)
            height: Math.max(flick.contentHeight, flick.height)
            property real initialWidth
            property real initialHeight
            onPinchStarted: {
                initialWidth = flick.contentWidth
                initialHeight = flick.contentHeight
            }
            onPinchUpdated: {
                if (initialWidth * pinch.scale > flick.maxContentWidth ||
                    initialHeight * pinch.scale > flick.maxContentHeight) {
                    flick.resizeContent(flick.maxContentWidth, flick.maxContentHeight, pinch.center)
                } else if (initialWidth * pinch.scale < flick.width ||
                           initialHeight * pinch.scale < flick.height) {
                    flick.resizeContent(flick.width, flick.height, pinch.center)
                } else {
                    flick.contentX += pinch.previousCenter.x - pinch.center.x
                    flick.contentY += pinch.previousCenter.y - pinch.center.y
                    flick.resizeContent(initialWidth * pinch.scale, initialHeight * pinch.scale, pinch.center)
                }
                flick.returnToBounds()
                flick.adjustContentX()
                flick.adjustContentY()
            }
            onPinchFinished: {
                flick.returnToBounds()
                console.log(flick.contentHeight, flick.contentWidth)
                if (flick.contentHeight == flick.height && flick.contentWidth == flick.width)
                    zoom_timeout.restart()
            }
            Timer {
                id: zoom_timeout
                interval: 200
                onTriggered: {
                    if (flick.contentHeight === flick.height && flick.contentWidth === flick.width)
                    {
                        flick.pinchFinished()
                        root.state = "list"
                    }
                }
            }
            Image {
                id: flick_img
                visible: !flick_fullimg.visible
                width: flick.contentWidth
                height: flick.contentHeight
                fillMode: Image.PreserveAspectFit
                CropOverlay {
                    anchors.fill: parent
                    fixedMode: true
                    onVisibleChanged: {
                        if (visible) {
                            cropx = SortedContentModel.getCropX(media_list.currentIndex)
                            cropy = SortedContentModel.getCropY(media_list.currentIndex)
                        }
                    }
                }
            }
            Image {
                id: flick_fullimg
                visible: status === Image.Ready
                onVisibleChanged: console.log("Fullsize", source, "visible:", visible,
                                              "content pos", flick.contentX, flick.contentY,
                                              "content size", flick.contentWidth, flick.contentHeight)
                width: flick.contentWidth
                height: flick.contentHeight
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                onStatusChanged: console.log("Fullsize", source, "status:", status)
                CropOverlay {
                    anchors.fill: parent
                    fixedMode: true
                    onVisibleChanged: {
                        if (visible) {
                            cropx = SortedContentModel.getCropX(media_list.currentIndex)
                            cropy = SortedContentModel.getCropY(media_list.currentIndex)
                        }
                    }
                }
            }
            MouseArea {
                id: pinchMouseArea
                anchors.fill: parent
                onDoubleClicked: {
                    console.log("Double", mouse.x, mouse.y)
                    var center = Qt.point(mouse.x, mouse.y)
                        console.log("Resize to small size..")
                        flick.contentWidth = flick.width
                        flick.contentHeight = flick.height
                        flick.contentX = 0
                        flick.contentY = 0
                        zoom_timeout.restart()
                }
                onPressed: zoomIndicator.startZoomTimer()
                onReleased: zoomIndicator.startZoomTimer()
            }
        }
        function zoomInImage(scale)
        {
            var startPoint = Qt.point(flick.width / 2.0 + flick.contentX, flick.height / 2.0 + flick.contentY)
            startZoomAnimation(flick.contentWidth, flick.contentHeight, scale, startPoint, -1, Easing.Linear)
        }
        function zoomFromPinch(scale)
        {
            var startPoint = Qt.point(flick.width / 2.0 + flick.contentX, flick.height / 2.0 + flick.contentY)
            var duration = 25
            startZoomAnimation(flick.contentWidth, flick.contentHeight, scale, startPoint, duration, Easing.Linear)
        }
        function startZoomAnimation(startWidth, startHeight, scale, point, duration, easing) {
            if(!zoomScaleAnimation.running)
            {
                if (duration < 0) {
                    duration = (root.usedInEVF ? 1 : 4) * constants.zoomScaleAnimateTime
                }
                zoomInitialWidth = startWidth
                zoomInitialHeight = startHeight
                zoomCenterOrig = point
                zoomCenter = point
                zoomScaleAnimation.duration = duration
                zoomScaleAnimation.easing.type = easing
                zoomScaleAnimation.from = (scale > 1) ? 1.01 : 1.0
                zoomScaleAnimation.to = scale
                zoomScaleAnimation.start()
                zoomScaleAnimation.requestOngoing = true
            }
        }
        onZoomScaleChanged: {
            if (zoomScaleAnimation.running) {
                if (zoomInitialWidth * zoomScale > flick.maxContentWidth ||
                    zoomInitialHeight * zoomScale > flick.maxContentHeight) {
                    flick.resizeContent(flick.maxContentWidth, flick.maxContentHeight, zoomCenter)
                    return
                } else if (zoomInitialWidth * zoomScale < flick.width ||
                           zoomInitialHeight * zoomScale < flick.height) {
                    flick.resizeContent(flick.width, flick.height, zoomCenter)
                    return
                } else {
                    flick.resizeContent(zoomInitialWidth * zoomScale, zoomInitialHeight * zoomScale, zoomCenter)
                }
                if (zoomScale > 1) {
                    var pointx = zoomCenterOrig.x*zoomScale
                    var pointy = zoomCenterOrig.y*zoomScale
                    zoomCenter = Qt.point(pointx, pointy)
                    flick.contentX = zoomCenter.x - flick.width/2
                    flick.contentY = zoomCenter.y - flick.height/2
                } else {
                    zoomCenter = Qt.point(flick.width / 2.0 + flick.contentX, flick.height / 2.0 + flick.contentY)
                }
                flick.returnToBounds()
                flick.adjustContentX()
                flick.adjustContentY()
            }
        }
        Connections {
            target: zoomScaleAnimation
            onRunningChanged: {
                if (zoomScaleAnimation.requestOngoing && !zoomScaleAnimation.running) {
                    if (flick.contentHeight == flick.height && flick.contentWidth == flick.width)
                    {
                        zoom_timeout.restart()
                    }
                    zoomScaleAnimation.requestOngoing = false
                }
            }
        }
        Keys.onPressed: {
            autoZoomLongPressTimer.stop()
            if (event.isAutoRepeat)
            {
                event.accepted = true
                return
            }
            root.keyPressed()
            event.accepted = true
            var newPos
            var startVal
            if(MKeys.pressedFn("LEFT", event.key))
            {
                if(xAnimation.running)
                {
                    startVal = xAnimation.to
                }
                else
                {
                    startVal = flick.contentX
                }
                xAnimation.stop()
                xAnimation.duration = constants.zoomAnimateTime
                xAnimation.from = flick.contentX
                newPos = startVal - flick.width / 3
                if(newPos < 0)
                {
                    newPos = 0
                }
                xAnimation.to = newPos
                xAnimation.start()
            }
            else if(MKeys.pressedFn("RIGHT", event.key))
            {
                if(xAnimation.running)
                {
                    startVal = xAnimation.to
                }
                else
                {
                    startVal = flick.contentX
                }
                xAnimation.stop()
                xAnimation.duration = constants.zoomAnimateTime
                xAnimation.from = flick.contentX
                newPos = startVal + flick.width / 3
                if(newPos > (flick.contentWidth - flick.width))
                {
                    newPos = flick.contentWidth - flick.width
                }
                xAnimation.to = newPos
                xAnimation.start()
            }
            else if(MKeys.pressedFn("UP", event.key))
            {
                if(yAnimation.running)
                {
                    startVal = yAnimation.to
                }
                else
                {
                    startVal = flick.contentY
                }
                yAnimation.stop()
                yAnimation.duration = constants.zoomAnimateTime
                yAnimation.from = flick.contentY
                newPos = startVal - flick.height / 3
                if(newPos < 0)
                {
                    newPos = 0
                }
                yAnimation.to = newPos
                yAnimation.start()
            }
            else if(MKeys.pressedFn("DOWN", event.key))
            {
                if(yAnimation.running)
                {
                    startVal = yAnimation.to
                }
                else
                {
                    startVal = flick.contentY
                }
                yAnimation.stop()
                yAnimation.duration = constants.zoomAnimateTime
                yAnimation.from = flick.contentY
                newPos = startVal + flick.height / 3
                if(newPos > (flick.contentHeight - flick.height))
                {
                    newPos = flick.contentHeight - flick.height
                }
                yAnimation.to = newPos
                yAnimation.start()
            }
            else if(MKeys.pressedFn("TRUEFOCUS", event.key)
                    || MKeys.pressedFn("AF_D", event.key)
                    || MKeys.pressedFn("ZOOM_IN", event.key))
            {
                autoZoomLongPressTimer.zoomIn = true
                autoZoomLongPressTimer.start()
            }
            else if(MKeys.pressedFn("ESCAPE", event.key))
            {
                autoZoomLongPressTimer.zoomIn = false
                autoZoomLongPressTimer.start()
            }
            else
            {
                event.accepted = false
            }
        }
        Keys.onReleased: {
            if (MKeys.pressedFn("TRUEFOCUS", event.key)
                    || MKeys.pressedFn("AF_D", event.key)
                    || MKeys.pressedFn("ZOOM_IN", event.key)
                    || MKeys.pressedFn("ESCAPE", event.key))
            {
                if(autoZoomLongPressTimer.running)
                {
                    autoZoomLongPressTimer.stop()
                    if (autoZoomLongPressTimer.zoomIn) {
                        zoomInImage(zoomFactor)
                    } else {
                        zoomInImage(1.0 / zoomFactor)
                    }
                }
            }
            if(MKeys.pressedFn("AF_D", event.key))
                event.accepted = true
            else
                event.accepted = false
        }
        Timer {
            property bool zoomIn: true
            id: autoZoomLongPressTimer
            running: false
            interval: 350
            repeat: false
            onTriggered: {
                var maxScale = Math.max(flick.maxContentWidth / flick.width, flick.maxContentHeight / flick.height)
                var startPoint = Qt.point(flick.width / 2.0 + flick.contentX, flick.height / 2.0 + flick.contentY)
                var duration = constants.zoomFullAnimateTime
                if (zoomIn) {
                    flick.startZoomAnimation(flick.contentWidth, flick.contentHeight, maxScale, startPoint, duration, Easing.InQuad)
                } else {
                    flick.startZoomAnimation(flick.contentWidth, flick.contentHeight, 0.9/maxScale, startPoint, duration, Easing.OutCubic)
                }
            }
        }
    }
    Item{
        id: zoomIndicator
        anchors.right: parent.right
        anchors.rightMargin: 30
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        width: parent.width * constants.zoomIndicatorSizeFactor
        height: parent.height * constants.zoomIndicatorSizeFactor
        visible: flick.visible
        onVisibleChanged: {
            if(visible)
            {
                startZoomTimer()
            }
            else
            {
                stopZoomTimer()
            }
        }
        Behavior on opacity {
            NumberAnimation{
                from: 1
                duration: constants.fadeOutDuration
            }
        }
        function startZoomTimer()
        {
            opacity = 1
            if(visible)
            {
                zoomTimer.start()
            }
        }
        function stopZoomTimer()
        {
            zoomTimer.stop()
        }
        Timer {
            id: zoomTimer
            interval: constants.zoomIndicatorTimeout
            onTriggered: if(!pinchMouseArea.pressed) zoomIndicator.opacity = 0
        }
        Image {
            anchors.fill: zoomIndicator
            source: flick_img.source
            CropOverlay {
                id: zoomCropOverlay
                anchors.fill: parent
                fixedMode: true
                onVisibleChanged: {
                    if (visible) {
                        cropx = SortedContentModel.getCropX(media_list.currentIndex)
                        cropy = SortedContentModel.getCropY(media_list.currentIndex)
                    }
                }
            }
        }
        Rectangle {
            id: zoomIndicatorOuterRectangle
            anchors.fill: zoomIndicator
            border.color: "black"
            border.width: 1
            color: "transparent"
        }
        Rectangle {
            anchors.fill: zoomIndicator
            anchors.margins: zoomIndicatorOuterRectangle.border.width
            border.color: "white"
            border.width: 2
            color: "transparent"
        }
        Rectangle {
            id: indicatorRectangle
            color: "transparent"
            y: flick.visibleArea.yPosition < 0 ? 0 : flick.visibleArea.yPosition * zoomIndicator.height
            height: flick.visibleArea.heightRatio * zoomIndicator.height
            x: flick.visibleArea.xPosition < 0 ? 0 : flick.visibleArea.xPosition * zoomIndicator.width
            width: flick.visibleArea.widthRatio * zoomIndicator.width
            onXChanged: zoomIndicator.startZoomTimer()
            onYChanged: zoomIndicator.startZoomTimer()
            onWidthChanged: zoomIndicator.startZoomTimer()
            onHeightChanged: zoomIndicator.startZoomTimer()
            border.color: "black"
            border.width: 1
        }
        Rectangle{
            anchors.fill: indicatorRectangle
            anchors.margins: indicatorRectangle.border.width
            color: "transparent"
            border.color: "white"
            border.width: 2
        }
    }
    ListView {
        id: media_list
        visible: false
        enabled: true
        model: media_grid.model
        anchors.fill: parent
        anchors.leftMargin: ListView.atXEnd ? 0 :
                            (count < 2) ? 1 :
                            -dividerWidth
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightFollowsCurrentItem: true
        preferredHighlightBegin: root.x
        preferredHighlightEnd: root.x + root.width
        highlightMoveVelocity: -1
        highlightRangeMode: ListView.StrictlyEnforceRange
        layoutDirection: Qt.LeftToRight
        currentIndex: count - 1
        property bool enableMouseClick: true
        interactive: !System.isTethered
        spacing: 20
        NumberAnimation on contentX {
            id: listviewXAnimation
            duration: 150
            easing.type: Easing.Linear
        }
        Connections {
            target: model
            onRowsAboutToBeInserted : {
                media_list.forceActiveFocus()
            }
        }
        onVisibleChanged: {
            if(visible)
            {
                enableClickTimer.start()
                if(0 === currentIndex) {
                    ++contentX
                    --contentX
                }
            }
        }
        boundsBehavior: Flickable.DragOverBounds | (guiconfig.isRunningSimulation() ? 0 : Flickable.CustomBounds)
        BoundsEffectGradient {
            parent: media_list
        }
        onCurrentIndexChanged: {
            if (!usedInEVF) {
                GlobalStateInfo.mediaIndex = currentIndex
            }
            GlobalStateInfo.greyBalanceIndex = SortedContentModel.proxyToSrcIndex(currentIndex)
            if(currentIndex != count - 1)
            {
                isInStartState = false
                if (SortedContentModel.getData(count-1, ContentModel.RatingRole) === Config.RatingLastExposure) {
                    ContentModel.clearRatingLastExposure()
                }
            }
            if (currentIndex > count-1) {
                currentIndex = count-1
                media_list.contentX = 50
            }
        }
        Timer {
            interval: 1000
            id: enableClickTimer
            repeat: false
            onTriggered: media_list.enableMouseClick = true
        }
        Timer {
            id: flickDblClickTimer
            interval: 500
            repeat: false
        }
        onMovingHorizontallyChanged: flickDblClickTimer.restart()
        Connections {
            property int lastDir: 0
            property int startIndex: 0
            property int startXValue: 0
            target: GlobalStateInfo
            onImgSwipeDirChanged: {
                if (!usedInEVF) {
                    return
                }
                var direction = (GlobalStateInfo.imgSwipeDir === 0) ? 0 : (GlobalStateInfo.imgSwipeDir < 0) ? -1 : 1
                if (lastDir === 0) {
                    startIndex = media_list.currentIndex
                    startXValue = media_list.contentX + media_list.originX
                }
                if (direction === 0) {
                    var diff = media_list.contentX + media_list.originX - startXValue
                    if (Math.abs(diff) > 40) {
                        media_list.animateStepIndex(diff > 0)
                    } else {
                        listviewXAnimation.stop()
                        media_list.positionViewAtIndex(startIndex, ListView.Center)
                    }
                } else {
                    media_list.animateSwipeStep(direction < 0)
                }
                lastDir = direction
            }
        }
        function animateSwipeStep(up) {
            listviewXAnimation.running = false
            listviewXAnimation.duration = 50
            listviewXAnimation.from = media_list.contentX
            var to = media_list.contentX + (up ? 1 : -1)* 20
            if (to < media_list.originX)
            {
                to = media_list.originX
            }
            else if((to + media_list.width) > media_list.contentWidth)
            {
                to = media_list.contentWidth - media_list.width
            }
            listviewXAnimation.to = to
            listviewXAnimation.running = true
        }
        function animateStepIndex(up) {
                listviewXAnimation.running = false
                listviewXAnimation.duration = 150
                listviewXAnimation.from = media_list.contentX
                if (up) {
                    incrementCurrentIndex()
                } else {
                    decrementCurrentIndex()
                }
                listviewXAnimation.to = media_list.contentX
                listviewXAnimation.running = true
            }
        Keys.onRightPressed: {
            incrementCurrentIndex()
            positionViewAtIndex(currentIndex, ListView.Center)
        }
        Keys.onLeftPressed: {
            decrementCurrentIndex()
            positionViewAtIndex(currentIndex, ListView.Center)
        }
        delegate: Component {
            FocusScope {
                width: media_list.width
                height: root.height
                focus: true
                Rectangle{
                    color: "black"
                    visible: !ListView.atXEnd
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: list_delegate_loader.left
                    }
                }
                property bool isLoaded: list_delegate_loader.status === Loader.Ready
                property var itemModel: model
                signal initPinching()
                onInitPinching: {
                    if (isLoaded && list_delegate_loader.item !== null && fileType === ContentModel.Image) {
                        list_delegate_loader.item.initPinching()
                    }
                }
                Loader {
                    objectName: "list_delegate_loader"
                    id: list_delegate_loader
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: media_list.width
                    focus: true
                    asynchronous: true
                    source: fileType === ContentModel.Video ?
                                "qrc:///browseview/MediaListViewVideoDelegate.qml" :
                                "qrc:///browseview/MediaListViewImageDelegate.qml"
                    onStatusChanged: {
                        if(status === Loader.Ready) {
                            console.log("fileType:", fileType)
                            console.log("fileName", image)
                        }
                        if (status === Loader.Ready && (fileType === ContentModel.Image || fileType == ContentModel.Video)) {
                            item.loadImage = (root.nextIndex < 0 || root.nextIndex === index)
                            if(fileType === ContentModel.Image)
                                item.isInstantPreview = root.isInstantPreview
                        }
                    }
                    Binding {
                        target: list_delegate_loader.item
                        property: "showOverExposureMask"
                        value: overexpose_behaviour.set
                        when: media_list.currentIndex == index && list_delegate_loader.status === Loader.Ready && fileType === ContentModel.Image
                    }
                    Connections {
                        target: fileType === ContentModel.Image ? root : null
                        onStateChanged: {
                            if(list_delegate_loader.status === Loader.Ready)
                                list_delegate_loader.item.resetMetaData()
                        }
                        onNextIndexChanged: {
                            list_delegate_loader.item.loadImage = (root.nextIndex < 0 || root.nextIndex === index)
                        }
                    }
                    Connections {
                        target: fileType === ContentModel.Video ? list_delegate_loader.item : null
                        onPlaybackVideo: video_overlay.startPlayback(index, display, fileSize, date)
                        onStopPlaybackVideo: video_overlay.stopPlayback()
                    }
                    Connections {
                        target: fileType === ContentModel.Image ? list_delegate_loader.item : null
                        onLoaded: {
                            if (media_list.currentIndex == index) {
                                root.hasLoadedCurrent = true
                                root.currentItemLoaded()
                            }
                        }
                        onKeyPressed: {
                            root.keyPressed()
                        }
                        onZoomedOut: root.state = "grid"
                        onPrepareScaling: {
                            console.log("Prepare scaling:", fullsizeImage)
                            flick_fullimg.source = ""
                            flick_fullimg.source = fullsizeImage
                        }
                        onScaled: {
                            if(flickDblClickTimer.running)
                                return
                            console.log("Scaled:", image, scale, "max w:", maxWidth, "max h:", maxHeight, "point:", point, "duration:", duration)
                            flick.knownHeight = maxHeight
                            flick.knownWidth = maxWidth
                            if(flick_fullimg.source !== fullsizeImage)
                            {
                                flick_fullimg.source = ""
                            }
                            flick_fullimg.source = fullsizeImage
                            flick_img.source = image
                            var center = point != null ?
                                        point :
                                        Qt.point(flick.contentWidth / 2.0, flick.contentHeight / 2.0)
                            if (duration !== 0) {
                                flick.startZoomAnimation(flick.width, flick.height, scale, center, duration, easing)
                            } else {
                                flick.resizeContent(flick.width * scale, flick.height * scale, center)
                                var deltaX = center.x - flick.width / 2.0
                                var deltaY = center.y - flick.height / 2.0
                                var newContentX = flick.contentX + deltaX
                                var newContentY = flick.contentY + deltaY
                                flick.contentX = Math.max(0, Math.min(newContentX, flick.contentWidth - flick.width))
                                flick.contentY = Math.max(0, Math.min(newContentY, flick.contentHeight - flick.height))
                            }
                            root.nextIndex = media_list.currentIndex
                            root.state = "zooming"
                        }
                        onOpenImageRating: {
                            if (imageRating === Config.RatingUnknown) {
                                return
                            } else if (imageRating === Config.NoRatingTag) {
                                imageRateFailedPopup.error = imageRateFailedPopup.errorRateOldImage
                                imageRateFailedPopup.openPopup = true
                            } else {
                                imageRatingActive = true
                            }
                        }
                        onPinchingChanged: {
                            root.pinching = list_delegate_loader.item.pinching
                        }
                    }
                    Connections {
                        target: fileType === ContentModel.Image ? flick : null
                        onPinchFinished: {
                            list_delegate_loader.item.resetMetaData()
                        }
                    }
                    Connections {
                        target: root
                        onHideInstantAVTV: {
                            if(fileType === ContentModel.Image)
                            {
                                list_delegate_loader.item.hideInstantAVTV()
                            }
                        }
                    }
                }
            }
        }
    }
    ConfirmationButtons {
        id: imageRatingPopupButtons
        visible: imageRatingActive && media_list.visible && !pinching
        color: "black"
        firstText: ""
        middleText: ""
        lastText: ""
        sideOriented: guiconfig.isWedge
    }
    VideoOverlay {
        id: video_overlay
        visible: false
        property int fileIndex
        property string fileName
        function startPlayback(index, name, size, date) {
            if (guiconfig.isWedge) {
                SoundControl.forceHeadset(true)
            }
            fileIndex = index
            fileName = ContentModel.path + "/" + name
            console.log("Start video", fileName)
            VideoControl.setVideoPlaybackState(true, fileName, size)
            root.state = ""
            root.nextIndex = index
            metaImgName =  name
            metaDateTime = date
        }
        function stopPlayback()
        {
            root.state = "list"
        }
        metaVolumeType: ContentModel.browseVolume
        MouseArea {
            anchors.fill: parent
            onClicked: video_overlay.stopPlayback()
        }
    }
    Loader {
        objectName: "browseSelectLoader"
        id: browseSelectLoader
        anchors.fill: parent
        active: false
        visible: false
        onLoaded: item.setFocus()
    }
    Binding on directoryUpHighLight {
        when: (model.source.pathType === ContentModel.PATH_TYPE_DIRECTORIES) && (browseSelectLoader.status === Loader.Ready) && (browseSelectLoader.item != null)
        value: browseSelectLoader.item != null ? browseSelectLoader.item.directoryUpHighLight : false
    }
    Binding on addFolderHighLight {
        when: (model.source.pathType === ContentModel.PATH_TYPE_DIRECTORIES) && (browseSelectLoader.status === Loader.Ready) && (browseSelectLoader.item != null)
        value: browseSelectLoader.item != null ? browseSelectLoader.item.addFolderHighLight : false
    }
    property int previousActiveCard: 0
    Component {
        id: browseSelectCardComponent
        BrowseSelectCard {
            id: browseSelectCard
            model: media_grid.model
            onDirectorySelected: {
                media_grid.model.enterDir(dir)
                media_grid.currentIndex = media_list.count - 1
                media_grid.positionViewAtIndex(media_grid.currentIndex, GridView.Center)
            }
            visible: browseSelectLoader.active
            oldActiveCard: previousActiveCard
        }
    }
    Connections {
        target: ContentModel
        onBrowseVolumeChanged: {
            if(ContentModel.browseVolume != 255)
            {
                previousActiveCard = ContentModel.browseVolume
            }
        }
    }
    Component {
        id: browseSelectDirComponent
        BrowseDirectory {
            id: browseSelectDir
            listModel: media_grid.model
            onDirectorySelected: {
                fromBrowseDir = true
                media_grid.model.enterDir(dir)
                media_grid.currentIndex = -1
                media_grid.positionViewAtIndex(media_grid.currentIndex, GridView.Center)
                listCurrentIndex = 0
                root.state = "grid"
            }
            onDirectoryUpSelected: {
                doDirectoryUp()
            }
            Component.onCompleted: {
                listCurrentIndex = 0
            }
            visible: browseSelectLoader.active
        }
    }
    property bool filteringImages: configstore.imageRating && configstore.imageRateFilter !== Config.MaskRatingAll
    NotificationPopup {
        objectName: "MediaBrowseView_emptyFolder"
        id: emptyFolder
        visible: (model.listSize === 0) && !ContentModel.isBrowsing
        text:  guiconfig.emptyString + ((!System.isTethered && noCardAvailable) ? qsTr("No Card") :
                                                                                  qsTr("No images<br>in this folder"))
        focus: visible
        onVisibleChanged: {
            filterButtonHighLight = false
            imageRatingActive = false
        }
    }
    NotificationPopup {
        objectName: "MediaBrowseView_imageRateFailed"
        id: imageRateFailedPopup
        readonly property int errorRateOldImage: 1
        readonly property int errorRateVideo: 2
        readonly property int errorRateImage: 3
        property int error: 0
        property string errorStr: error === errorRateOldImage ? qsTr("Image taken with old<br>firmware can not be rated.") :
                                  error === errorRateVideo ?    qsTr("Videos can not be rated.") :
                                                                qsTr("Failed to rate image")
        text: errorStr + guiconfig.emptyString
        focus: visible
        closeOnInput: true
        onVisibleChanged: {
            if (!visible) {
                media_list.forceActiveFocus()
            }
        }
        Connections {
            target: farm
            onImageRatingStatusChanged: {
                imageRateFailedPopup.openPopup = (farm.imageRatingstatus !== Farm.RatingOk)
                imageRateFailedPopup.error = (farm.imageRatingstatus === Farm.RatingInvalid) ? imageRateFailedPopup.errorRateOldImage :
                                                                                               imageRateFailedPopup.errorRateImage
            }
        }
    }
    MouseArea {
        z: emptyFolder.z + 1
        id: directoryUp
        anchors {
            top: parent.top
            left: parent.left
            topMargin: 12
            leftMargin: 4
        }
        width: directoryUpIcon.width + 24
        height: directoryUpIcon.height + 24
        enabled: directoryUpIcon.visible
        onClicked: {
            doDirectoryUp()
        }
        Rectangle {
            objectName: "MediaBrowseView_dirUpBg"
            color: directoryUp.containsPress || directoryUpHighLight ? constants.hblOrange : "black"
            anchors.fill: directoryUp.containsPress || !browseSelectLoader.active || directoryUpHighLight ? parent : directoryUpIcon
            opacity: directoryUp.containsPress || directoryUpHighLight ? 1 : 0.5
            visible: directoryUpIcon.visible
        }
        Image {
            id: directoryUpIcon
            visible: media_grid.model.source.parentAvailable && (root.state === "grid") && !createFolderConfirmDialog.active && !System.isTethered
            anchors.centerIn: parent
            source: "qrc:///icons/FolderUp.png"
        }
    }
    MouseArea {
        id: cover_area
        visible: false
        anchors.fill: parent
        onClicked: root.state = "grid"
        Rectangle {
            color: "white"
            anchors.centerIn: parent
            width: parent.width / 2
            height: parent.height / 2
            opacity: 0.8
            Text {
                color: "red"
                text: qsTr("Delete?") + guiconfig.emptyString
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Rectangle {
                color: "Red"
                width: parent.width / 3
                height: parent.height / 3
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                Text {
                    color: "white"
                    anchors.centerIn: parent
                    text: qsTr("YES") + guiconfig.emptyString
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        media_grid.model.remove(media_grid.currentIndex)
                        if (media_grid.currentIndex)
                            media_list.currentIndex = media_grid.currentIndex - 1
                        root.state = "grid"
                    }
                }
            }
        }
    }
    Loader {
        objectName: "deletePopupLoader"
        id: deletePopupLoader
        anchors.fill: parent
        active: false
        asynchronous: true
        focus: active
        property bool deleteFile: false
        source: "qrc:///components/popups/DeletePopup.qml"
        property string deleteText: qsTr("Delete this image?")
        onLoaded: {
            item.deleteText = deleteText
            item.forceActiveFocus()
        }
        onActiveChanged: {
            if(!active)
            {
                if ((root.state == "grid") || (root.state == "delete"))
                {
                    if(deleteFile)
                    {
                        console.log("Delete File. CurrentIndex:", media_grid.currentIndex)
                        media_grid.model.remove(media_grid.currentIndex)
                        if (media_grid.currentIndex)
                            media_grid.currentIndex = media_grid.currentIndex - 1
                    }
                    root.state = "grid"
                    media_grid.forceActiveFocus()
                }
                else
                {
                    if(deleteFile)
                    {
                        console.log("Delete File. CurrentIndex:", media_list.currentIndex, SortedContentModel.getData(media_list.currentIndex, ContentModel.DisplayRole), media_list.count)
                        var oldCurrentIndex = media_list.currentIndex
                        var oldCount = media_list.count
                        media_list.model.remove(media_list.currentIndex)
                        if (media_list.currentIndex)
                            media_list.currentIndex = Math.max(0, Math.min(oldCurrentIndex, oldCount - 2))
                    }
                    media_list.forceActiveFocus()
                }
            }
        }
    }
    NotificationPopup{
        visible: ContentModel.isDeleting
        text: qsTr("Deleting") + guiconfig.emptyString
    }
    NotificationPopup {
        objectName: "MediaBrowseView_addFolderPopup"
        id: addFolderPopup
        z: directoryUp.z + 1
        visible: false
        text:  guiconfig.emptyString + qsTr("Failed to<br>create folder")
        focus: visible
        closeOnInput: true
        onClose: {
            browseSelectLoader.focus = true
        }
    }
    Timer {
        id: addFolderTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: {
            addFolderPopup.visible = true
        }
        function stopTimer() {
            if (running) {
                stop()
                browseSelectLoader.focus = true
                browseSelectLoader.item.folderAdded()
            }
        }
        Component.onCompleted: {
            ContentModel.currentWorkingDirChanged.connect(stopTimer)
        }
    }
    function doAddFolder()
    {
        addFolderTimer.start()
        ContentModel.createNewFolder()
    }
    Loader {
        id: createFolderConfirmDialog
        objectName: "CreateFolder_confirmDialog"
        anchors.fill: parent
        source: "qrc:///components/GenericConfirm.qml"
        active: false
        asynchronous: true
        onLoaded: {
            item.headerText = qsTr("Create New Folder?")
            item.infoText = qsTr("A new folder") + " \"" + farm.nextAvailableFolderName() + "\" " + qsTr("will be created on") + " " +
                            Settings.getDisplayValue("primary_volume_image_raw", ContentModel.browseVolume) + guiconfig.emptyString
            item.leftText = qsTr("Exit")
            item.rightText = qsTr("Create")
            item.middleAvailable = ""
            item.largeHeaderText = true
            item.transparentBackground = true
        }
        onActiveChanged: {
            if(active) {
                forceActiveFocus()
            } else {
                browseSelectLoader.focus = true
            }
        }
        Connections {
            target: createFolderConfirmDialog.item
            onRightSelected: {
                doAddFolder()
            }
        }
        Connections {
            target: ContentModel
            onCard0StatusChanged: {
                if (createFolderConfirmDialog.active) {
                    createFolderConfirmDialog.active = false
                }
            }
            onCard1StatusChanged: {
                if (createFolderConfirmDialog.active) {
                    createFolderConfirmDialog.active = false
                }
            }
        }
    }
    MouseArea {
        id: addFolder
        anchors {
            top: parent.top
            right: battIcon.visible ? battIcon.left : parent.right
            topMargin: 12
            rightMargin: 4
        }
        width: addFolderIcon.width + 24
        height: addFolderIcon.height + 24
        enabled: addFolderIcon.visible
        onClicked: {
            addFolderHighLight = false
            if (ContentModel.checkWriteProtection()) {
                createFolderConfirmDialog.active = true
            }
        }
        Rectangle {
            objectName: "BrowseDir_addFolderBg"
            color: addFolder.containsPress || addFolderHighLight ? constants.hblOrange : "black"
            anchors.fill: addFolder.containsPress || !browseSelectLoader.active || addFolderHighLight ? parent : addFolderIcon
            opacity: addFolder.containsPress || addFolderHighLight ? 1 : 0.5
            visible: addFolderIcon.visible
        }
        Image {
            id: addFolderIcon
            visible: media_grid.model.source.parentAvailable && (root.state === "grid") && browseSelectLoader.active &&
                     ContentModel.isBrowsingActiveVolume && !createFolderConfirmDialog.active
            anchors.centerIn: parent
            source: "qrc:///icons/AddFolder.png"
        }
    }
    BatteryIndicatorScaled {
        id: battIcon
        canShowBattery: !deletePopupLoader.active && !imageRatingActive
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
        target: VideoControl
        onVideoModeChanged: console.log("Video mode:", target.videoMode, root)
    }
    Component.onDestruction: {
        allowDimming = false
        if (usedInEVF) {
            GlobalStateInfo.evfBrowseViewState = ""
        }
        if (state == "video_playback")
            VideoControl.setVideoPlaybackState(false, video_overlay.fileName, 0)
        ContentModel.clearRatingLastExposure()
    }
    property bool noCardAvailable: (ContentModel.card0Status === ContentModel.STORAGE_ABSENT) && (ContentModel.card1Status === ContentModel.STORAGE_ABSENT)
    onNoCardAvailableChanged: {
        if(noCardAvailable && (state == "zooming"))
        {
            state = "list"
        }
    }
    onStateChanged: {
        console.log("new state:", state, "list index:", media_list.currentIndex, "path type:", model.source.pathType)
        if (usedInEVF) {
            GlobalStateInfo.evfBrowseViewState = state
        }
        if (state !== "list" && state !== "zooming") {
            imageRatingActive = false
        }
    }
    states: [
        State {
            name: "list"
            when: (VideoControl.videoMode !== VideoControl.Playback) && (VideoControl.pipelineState === VideoControl.PipelineOff) && (model.source.pathType === ContentModel.PATH_TYPE_FILES) && (!fromBrowseDir) && (model.listSize > 0)
            PropertyChanges { target: media_list; visible: true; focus: true }
            PropertyChanges { target: battIcon; anchors { rightMargin: 10; topMargin: 1 !== configstore.MetaDataOverlayIndex
                                                                                      || (null !== media_list.currentItem && media_list.currentItem.itemModel.fileType === ContentModel.Video) ? 50: 10 } }
            PropertyChanges { target: media_grid; interactive: false }
            PropertyChanges { target: video_overlay; visible: false }
            StateChangeScript {
                script: {
                    if (fromVideoPlayback) {
                        media_list.currentIndex = root.nextIndex
                        root.nextIndex = -1
                        media_list.positionViewAtIndex(media_list.currentIndex, ListView.Center)
                    } else {
                        root.setNextIndex()
                    }
                    fromBrowseDir = false
                    fromVideoPlayback = false
                }
            }
        },
        State {
            name: "zooming"
            PropertyChanges { target: flick; visible: true; focus: true }
            PropertyChanges { target: media_list; visible: false; focus: false }
            StateChangeScript {
                script: {
                    root.nextIndex = media_list.currentIndex
                }
            }
        },
        State {
            name: "grid"
            when: (VideoControl.videoMode !== VideoControl.Playback) && (VideoControl.pipelineState === VideoControl.PipelineOff)
            PropertyChanges { target: media_grid; visible: (model.source.pathType === ContentModel.PATH_TYPE_FILES) && !emptyFolder.visible; focus: media_grid.visible }
            PropertyChanges { target: media_list; visible: false; focus: false }
            PropertyChanges { target: media_list; interactive: false }
            PropertyChanges { target: battIcon; anchors { rightMargin: 30; topMargin: 10 } }
            PropertyChanges { target: browseSelectLoader; active: model.source.pathType !== ContentModel.PATH_TYPE_FILES && !emptyFolder.visible; visible: active}
            PropertyChanges { target: browseSelectLoader; sourceComponent: model.source.pathType === ContentModel.PATH_TYPE_DIRECTORIES ? browseSelectDirComponent : browseSelectCardComponent}
            PropertyChanges { target: video_overlay; visible: false }
            PropertyChanges { target: root; isInStartState: false; restoreEntryValues: false }
            PropertyChanges { target: BodySync; currentState: BodySync.PLAY; restoreEntryValues: false }
            StateChangeScript {
                script: {
                    fromBrowseDir = false
                    media_grid.currentIndex = media_list.currentIndex
                    media_grid.positionViewAtIndex(media_grid.currentIndex, ListView.Center)
                    is9ViewActive = true
                    isIn9View(is9ViewActive)
                    if(emptyFolder.visible)
                    {
                        emptyFolder.forceActiveFocus()
                    }
                }
            }
        },
        State {
            name: "delete"
            PropertyChanges { target: media_list; visible: true; focus: true }
            PropertyChanges { target: media_list; currentIndex: media_grid.currentIndex; restoreEntryValues: false }
            PropertyChanges { target: deletePopupLoader; deleteFile: false; active: true }
        },
        State {
            name: "video_playback"
            when: VideoControl.pipelineState === VideoControl.PipelineLocal && VideoControl.videoMode === VideoControl.Playback
            PropertyChanges { target: media_list; focus: true }
            PropertyChanges { target: root; color: "transparent" }
            PropertyChanges { target: video_overlay; visible: true }
            StateChangeScript {
                script: {
                    fromVideoPlayback = true
                    fromBrowseDir = false
                    preventIdleTimeout(true)
                }
            }
        }
    ]
    transitions: [
        Transition {
            from: "list"
            ScriptAction {
                script: closeAllPopups()
            }
        },
        Transition {
            from: "video_playback"
            ScriptAction {
                script: {
                    VideoControl.setVideoPlaybackState(false, video_overlay.fileName, 0)
                    preventIdleTimeout(false)
                }
            }
        },
        Transition {
            from: "zooming"
            ScriptAction {
                script: {
                    flick_img.source = ""
                    flick_fullimg.source = ""
                    console.log("Released full-size image")
                }
            }
        },
        Transition {
            from: "grid"
            ScriptAction {
                script: {
                    is9ViewActive = false
                    isIn9View(is9ViewActive)
                    directoryUpHighLight = false
                    filterButtonHighLight = false
                }
            }
        }
    ]
    SequentialAnimation {
        id: overexpose_behaviour
        property bool set: false
        running: configstore.OverExposureWarning
        alwaysRunToEnd: true
        loops: Animation.Infinite
        PropertyAction { target: overexpose_behaviour; property: "set"; value: true }
        PauseAnimation { duration: 1000 }
        PropertyAction { target: overexpose_behaviour; property: "set"; value: false }
        PauseAnimation { duration: 1000 }
    }
}
