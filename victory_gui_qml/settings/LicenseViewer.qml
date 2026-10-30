import QtQuick 2.0
import com.hasselblad.licensemodel 1.0
import "qrc:///scripts/Keys.js" as MKeys

Rectangle {
    objectName: "LicenseViewer_root"
    id: root
    property string headingText
    property int itemHeight: 78
    property int currentItemYValue: licenseList.currentItem != null ? licenseList.currentItem.mapToItem(licenseList, licenseList.contentY * 0, 0).y : 0

    function licenseTextSelected(packageName)
    {
        licenseTextView.setSource("LongTextViewer.qml", {"headingText": "<font color=\"" + constants.menuHighlightColor + "\">" + qsTranslate("MENUS", "GENERAL SETTINGS") + ":</font> &nbsp;" + qsTranslate("MENUS", "LICENSES"), "longText": LicenseModel.getLicenseText(packageName) })
        licenseTextView.active = true
    }
    color: constants.menuBackgroundColor

    Rectangle {
        id: viewEndLine
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: constants.viewEndLineWidth
    }


    MouseArea {
        anchors.left: viewEndLine.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        enabled: !licenseTextView.active

        // We must have this here to be able to drag:
        drag {
            target: root
            axis: Drag.XAxis
            minimumX: 0//-constants.viewEndLineWidth
            maximumX: root.width
            threshold: constants.dragThreshold
            filterChildren: true
        }
        drag.onActiveChanged: {
            if (!drag.active) {
                // Done dragging
                if (drag.target.x > (root.width / constants.swipeLengthDividor))
                {
                    // Dragged enough to the right. Close the window
                    closeSubDialog()
                }
                root.x = 0
            }
        }
        onClicked: {}

        // Header text
        Text {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: constants.headerVerticalOffset
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize : constants.headerTextSize
            color: constants.menuHeaderColor
            text: qsTr(headingText) + guiconfig.emptyString
            font.capitalization: Font.AllUppercase
        }

        ListView {
            objectName: "LicenseViewer_licenseList"
            id: licenseList
            clip: true
            anchors.left: parent.left
            anchors.leftMargin: constants.leftMarginForItems
            anchors.right: parent.right
            anchors.rightMargin: constants.leftMarginForItems
            anchors.top: header.bottom
            anchors.topMargin: constants.headerVerticalOffset
            anchors.bottom: parent.bottom
            anchors.bottomMargin: constants.leftMarginForItems
            focus: true
            boundsBehavior: Flickable.StopAtBounds
            model: LicenseModel
            property bool highlightAllow: false
            property int lastIndex: -1
            currentIndex: -1

            orientation: ListView.Vertical
            highlightMoveDuration: constants.highlightMoveDuration
            highlight: Rectangle {
                visible: licenseList.highlightAllow
                color: constants.highlightColor
                height: itemHeight
                width: licenseList.width
            }

            delegate: Item {
                height: itemHeight
                width: licenseList.width
                // Workaround since QML does not let us easily access model data roles outside a delegate:
                property var itemModel: model

                Rectangle{
                    id: leftDot
                    color: "white"
                    width: 10
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 3
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 6
                    anchors.left: leftDot.right
                    anchors.leftMargin: 15
                    anchors.right: parent.right
                    text: packageName
                    color: "white"
                    font.pixelSize: 40
                    fontSizeMode: Text.HorizontalFit
                }
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        licenseList.highlightAllow = false
                        stopMenuWheelTimeout();
                        licenseList.currentIndex = index
                        root.licenseTextSelected(packageName)
                    }
                }
            }

            Keys.onPressed: {
                event.accepted = true // assume we trig on something
                if((guiconfig.isWedge && MKeys.pressedFn("LEFT", event.key)) || MKeys.pressedFn("NAVUP", event.key)) {
                    startMenuWheelTimeout();
                    highlightAllow = true
                    if(-1 != currentIndex || -1 == lastIndex)
                    {
                        decrementCurrentIndex()
                    }
                    else
                    {
                        currentIndex = lastIndex
                    }
                    lastIndex = currentIndex // This may look peculiar, but its in order!
                }
                else if((guiconfig.isWedge && MKeys.pressedFn("RIGHT", event.key)) || MKeys.pressedFn("NAVDOWN", event.key)) {
                    startMenuWheelTimeout();
                    highlightAllow = true
                    if(-1 != currentIndex || -1 == lastIndex) {
                        incrementCurrentIndex()
                    }
                    else {
                        currentIndex = lastIndex
                    }
                    lastIndex = currentIndex // This may look peculiar, but its in order!
                }
                else if(MKeys.pressedFn("SELECT", event.key) || (!guiconfig.isWedge && MKeys.pressedFn("RIGHT", event.key))) {
                    stopMenuWheelTimeout();
                    highlightAllow = false
                    if(-1 != currentIndex)
                    {
                        root.licenseTextSelected(licenseList.currentItem.itemModel.packageName)
                    }
                }
                else if(MKeys.pressedFn("ESCAPE", event.key) || (!guiconfig.isWedge && MKeys.pressedFn("LEFT", event.key))) {
                    stopMenuWheelTimeout();
                    highlightAllow = false
                    closeSubDialog();
                }
                else
                    event.accepted = false
            }

        }
        // Fading on top and bottom. Must be after listview, since it will be on top of it
        Rectangle {
            id: topGradient
            // NOTE: We hide the top transparency gradient if we are navigating with keys and the selected item is the first visible (top) one.
            visible: licenseList.currentIndex === -1 || ((currentItemYValue > height) ||
                                                         (currentItemYValue < -itemHeight))

            anchors.top: licenseList.top
            anchors.left: licenseList.left
            anchors.right: licenseList.right
            height: 30
            gradient: Gradient {
                GradientStop { position: 0.0; color: "black" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            // NOTE: We hide the bottom transparency gradient if we are navigating with keys and the selected item is the last visible (bottom) one.
            visible: licenseList.currentIndex === -1 || ((currentItemYValue > licenseList.height) ||
                                                         (currentItemYValue < (licenseList.height - itemHeight - height)))
            anchors.bottom: licenseList.bottom
            anchors.left: licenseList.left
            anchors.right: licenseList.right
            height: 30
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: "black" }
            }
        }

        Rectangle{
            color: "grey"
            anchors.right: licenseList.right
            anchors.rightMargin: -10
            width: 2
            radius: width / 2
            y: licenseList.visibleArea.yPosition * licenseList.height + licenseList.y
            height: Math.max(20, licenseList.visibleArea.heightRatio * licenseList.height)
        }
    }


    Timer {
        id: listMenuTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: licenseList.highlightAllow = false
    }

    function startMenuWheelTimeout()
    {
        listMenuTimer.restart();
    }

    function stopMenuWheelTimeout()
    {
        listMenuTimer.stop();
    }


    Loader{
        anchors.fill: parent
        id: licenseTextView
        active: false
        visible: active
        asynchronous: true
        focus: active
        onActiveChanged: {
            // If active becomes false, a dialog was closed, and list must get focus
            if(!active)
            {
                licenseList.forceActiveFocus()
            }
        }
        function closeSubDialog()
        {
            licenseTextView.active = false
        }
    }

}
