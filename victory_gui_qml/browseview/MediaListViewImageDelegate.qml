import QtQuick 2.0
import com.hasselblad.storage 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0

import "qrc:///settings"
import "qrc:///components/buttons"
import "qrc:///components/popups"
import "qrc:///scripts/Keys.js" as MKeys

Rectangle {
    id: list_delegate
    objectName: "MediaListViewImageDelegate"
    anchors.fill: parent
    color: "black"
    focus: true
    property alias showOverExposureMask: list_img.showOverExposureMask
    property bool isInstantPreview: false
    property bool loadImage: false
    property bool pinching: false

    signal prepareScaling()
    signal scaled(real scale, int maxWidth, int maxHeight, var point, var duration, var easing)
    signal loaded()
    signal zoomedOut()
    signal keyPressed()
    signal initPinching()
    signal openImageRating()
    signal openImageRateFilter()

    onActiveFocusChanged: {
        if (activeFocus && imageRatingActive) {
            imageRatingPopup.forceActiveFocus()
        }
    }

    onInitPinching: {
        list_delegate.scaled(1.01, scaling.maxWidth, scaling.maxHeight, null, 0, 0)
    }

    function hideInstantAVTV()
    {
        meta_data_overlay.hideInstantAVTV()
    }


    // Make sure we show overlay if user is swiping to another image
    Connections {
        target: media_list
        onCurrentIndexChanged: {
            resetMetaData()
        }
    }

    function resetMetaData()
    {
        meta_data_overlay.showOverlay = true
    }

    Photo {
        id: list_img
        anchors.centerIn: parent
        width: scaling.scale * parent.width
        height: scaling.scale * parent.height
        source: list_delegate.loadImage ? image : ""
//        onVisibleChanged: console.log("visible changed", image, "now:", visible)

        onStatusChanged: {
            if (status === Image.Ready)
                list_delegate.loaded()
        }
    }

    Item {
        id: scaling
        property int maxWidth: imageWidth !== undefined ? imageWidth : list_img.implicitWidth
        property int maxHeight: imageHeight !== undefined ? imageHeight : list_img.implicitHeight
        property real maxScale: Math.max(maxWidth / parent.width, maxHeight / parent.height)

        property real minScale: 0.9

        scale: 1
        Binding on scale {
            when: media_list.currentIndex !== index
            value: 1
        }
    }

    Keys.onPressed: {
        autoZoomLongPressTimer.stop()
        if (event.isAutoRepeat)
        {
            event.accepted = true
            return
        }
        list_delegate.keyPressed()
        event.accepted = true
        if(MKeys.pressedFn("UP", event.key))
        {
            if(meta_data_overlay.visible)
            {
                meta_data_overlay.setPrevOverlay()
            }
            else
            {
                meta_data_overlay.showOverlay = true
            }
        }
        else if(MKeys.pressedFn("DOWN", event.key) || MKeys.pressedFn("SQUARE", event.key))
        {
            if(meta_data_overlay.visible)
            {
                meta_data_overlay.setNextOverlay()
            }
            else
            {
                meta_data_overlay.showOverlay = true
            }
        }
        else if(MKeys.pressedFn("TRUEFOCUS", event.key)
                || MKeys.pressedFn("AF_D", event.key)
                || MKeys.pressedFn("ZOOM_IN", event.key))
        {
            autoZoomLongPressTimer.start()
        }
        else if (System.isTethered && (MKeys.pressedFn("NAVLEFT", event.key) || MKeys.pressedFn("NAVRIGHT", event.key))) {
            // In tethered only the active image can be browsed so need to disable thumbwheel navigation
            event.accepted = true
        }
        else if(MKeys.pressedFn("TPDOUBLECLICK", event.key)) {
            list_delegate.scaled(scaling.maxScale, scaling.maxWidth, scaling.maxHeight, null, 0, 0)
            event.accepted = true
        }
        else
        {
            event.accepted = false
        }
    }

    Keys.onReleased: {
        // Eat the released event
        if (MKeys.pressedFn("TRUEFOCUS", event.key)
                || MKeys.pressedFn("AF_D", event.key)
                || MKeys.pressedFn("ZOOM_IN", event.key))
        {
            if(autoZoomLongPressTimer.running)
            {
                autoZoomLongPressTimer.stop()
                // Short press.
                zoomIn1Step()
            }
        }
        if(MKeys.pressedFn("AF_D", event.key))
            event.accepted = true
        else
            event.accepted = false
    }

    MetaDataOverlay {
        id: meta_data_overlay
        anchors.fill: parent
        isInstantPreview: root.isInstantPreview
        visible: showOverlay && !imageRatingPopup.visible

        Binding on histogramData {
            when: histogram !== undefined
            value: histogram
        }
        Binding on metaIso {
            when: iso !== undefined
            value: iso
        }
        Binding on metaDateTime {
            when: date !== undefined
            value: date
        }
        Binding on metaImgName {
            when: display !== undefined
            value: display
        }
        Binding on metaEvAdjust {
            when: exposureBias !== undefined
            value: exposureBias
        }
        Binding on metaLightMeterMode {
            when: lightMeterMode !== undefined
            value: lightMeterMode
        }
        Binding on metaWhiteBalanceMode {
            when: whiteBalance !== undefined
            value: whiteBalance
        }
        Binding on metaExposureMode {
            when: exposureMode !== undefined
            value: exposureMode
        }
        Binding on metaAV {
            when: apertureValue !== undefined
            value: apertureValue
        }
        Binding on metaTV {
            when: timeValue !== undefined
            value: timeValue === "--" ? "--s" : timeValue
        }
        Binding on metaFocalLength {
            when: focalLength !== undefined
            value: focalLength
        }
        Binding on metaExposureStatus {
            when: exposureStatus !== undefined
            value: exposureStatus
        }
        Binding on metaRating {
            when: imageRating !== undefined
            value: imageRating
        }
        metaVolumeType: ContentModel.browseVolume
    }

    Loader {
        function shouldShowIntervalTimer()
        {
            if (configstore.intervalActive && Camera.intervalTimerCountDown > 0)
                return true
            else if (configstore.intervalActive && Camera.exposureTimerCount > 0 &&
                     (guiconfig.isWedge || (cambody.capabilities & Cambody.CapabilityGuiExposure) !== 0))
                return true
            return false
        }
        objectName: "intervalTimerOverlayLoader"
        id: intervalTimerOverlay
        anchors.fill: parent
        active: shouldShowIntervalTimer()
        visible: active
        asynchronous: true
        focus: active
        source: "qrc:///common/IntervalTimerScreen.qml"
        onLoaded: item.overlay = true
        onActiveChanged: {
            if (!active) {
                list_delegate.focus = true
            }
        }
    }

    PinchArea {
        // Only allow pinching when not tethering
        id: pincher
        enabled: !System.isTethered
        anchors.fill: parent
        pinch.target: scaling
        pinch.minimumScale: scaling.minScale
        pinch.maximumScale: scaling.maxScale
        onPinchFinished: {
            list_delegate.pinching = false
            if (scaling.scale > 1) {
                list_delegate.scaled(scaling.scale, scaling.maxWidth, scaling.maxHeight, null, 0, 0)
                scaling.scale = 1
                meta_data_overlay.showOverlay = true
            }
            else if (scaling.scale < 1)
            {
                scaling.scale = 1
                list_delegate.zoomedOut()
            }
        }
        onPinchStarted: {
            list_delegate.pinching = true
            list_delegate.prepareScaling()
            meta_data_overlay.showOverlay = false
        }
        // This replaces the mousearea in the pitch area. This construction is needed since it seems
        // propagateComposedEvents does not work 100% correct (it misses the first swipe to left/right)
        property int previousX: -1
        property int previousY: -1
        property double previousClickTime: -1
        function doOnPressed(mousex, mousey)
        {
            var now = new Date().valueOf()
            if ((previousClickTime < 0) || ((now - previousClickTime) > 1000))
            {
                previousX = mousex
                previousY = mousey + y
                previousClickTime = now
                console.log("Registered first click at ", previousX, previousY)
            }
            else
            {
                console.log("Unregistered click at:", mousex, mousey + y, "previousClickTime:", previousClickTime, "now:", now)

            }
        }
        function doOnDoubleClicked (mousex, mousey)
        {
            if((previousX === -1) || (previousY === -1))
            {
                previousX = mousex
                previousY = mousey + y
            }
            list_delegate.scaled(scaling.maxScale, scaling.maxWidth, scaling.maxHeight, Qt.point(previousX, previousY), 0, 0)
            console.log("Registered second click at ", mousex, mousey + y)
            console.log("Using ", previousX, previousY)
            previousX = -1
            previousY = -1
            previousClickTime = -1
        }

        MouseArea {
            id: clickAreaBeyond
            enabled: media_list.enableMouseClick
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: meta_data_overlay.visible ? meta_data_overlay.nextClickAreaHeight : 0
            onClicked: {
                meta_data_overlay.setNextOverlay()
            }
            onDoubleClicked: {
                pincher.doOnDoubleClicked (mouse.x, mouse.y + clickAreaAbove.height)
            }
            onPressed:
            {
                pincher.doOnPressed(mouse.x, mouse.y + clickAreaAbove.height)
            }

            MouseArea {
                id: imageRateArea
                anchors {
                    right:parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
                enabled: configstore.imageRating && !Camera.inSession //Is in session during interval
                width: meta_data_overlay.visible ? meta_data_overlay.imageRateClickAreaWidth : 0
                onClicked: list_delegate.openImageRating()
            }
        }
        MouseArea {
            id: clickAreaAbove
            enabled: media_list.enableMouseClick
            anchors {
                left: parent.left
                right: parent.right
                bottom: clickAreaBeyond.top
                top: parent.top
            }
            onClicked: {
                meta_data_overlay.showOverlay = !meta_data_overlay.showOverlay
            }
            onDoubleClicked: {
                pincher.doOnDoubleClicked (mouse.x, mouse.y)
            }
            onPressed:
            {
                pincher.doOnPressed(mouse.x, mouse.y)
            }
        }
    } // PinchArea

    Timer {
        id: autoZoomLongPressTimer
        running: false
        interval: 350
        repeat: false
        onTriggered: {
            // Timer timed out, thus this is a long press -> zoom to 100%
            var point = Qt.point(list_delegate.width / 2, list_delegate.height / 2)
            if (guiconfig.isWedge && display === ContentModel.lastExposureName()) {
                point = Qt.point(ContentModel.lastExposureFocusPointX()*list_delegate.width, ContentModel.lastExposureFocusPointY()*list_delegate.height)
            }
            list_delegate.scaled(scaling.maxScale, scaling.maxWidth, scaling.maxHeight, point, constants.zoomFullAnimateTime, Easing.InQuad)
        }
    }

    function zoomIn1Step() {
        list_delegate.scaled(zoomFactor, scaling.maxWidth, scaling.maxHeight, Qt.point(list_delegate.width / 2, list_delegate.height / 2), -1, Easing.Linear)
    }


    Component {
        id: ratingComponent
        ImageRatingPopup {
            onVisibleChanged: {
                if (!visible) {
                    list_delegate.focus = true
                }
            }
            focus: true
            startValue: imageRating
            name: display
            onOpenFilter: list_delegate.openImageRateFilter()
        }
    }

    Loader{
        id: imageRatingPopup
        anchors.fill: list_delegate
        focus: visible
        sourceComponent: ratingComponent
        active: configstore.imageRating && imageRatingActive
        visible: imageRatingActive && !pincher.pinch.active
        asynchronous: true
    }

    //Disable image filtering for now
    /*FilterButton {
        id: filterImage
        anchors {
            top: list_delegate.top
            left: list_delegate.left
            leftMargin: 10
            topMargin: 10 + constants.topMetaHeight
        }
        highlight: imageRatingPopup.filterIconSelected
        visible: (filteringImages || imageRatingActive) && !pincher.pinch.active
        enabled: visible
        onClicked: list_delegate.openImageRateFilter()
    }*/

} // Rectangle
