import QtQuick 2.0
import com.hasselblad.storage 1.0
import com.hasselblad.settings 1.0
import "qrc:///settings"
import "qrc:///settings/components"
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    objectName: "BrowseDirectory_root"
    id: root
    color: "black"
    property real numberOfVisibleItems: 5
    property alias listModel: file_list.model
    signal directorySelected(string dir)
    property int itemHeight: 78
    property alias listCurrentIndex: file_list.currentIndex
    property int currentItemYValue: (file_list.currentIndex >= 0) && (file_list.currentItem !== null) ? file_list.currentItem.mapToItem(file_list, file_list.contentY * 0, 0).y : 0
    property bool allowDimming: true
    property bool directoryUpHighLight: false
    property bool addFolderHighLight: false
    signal directoryUpSelected()
    signal folderAdded()
    function setFocus()
    {
        file_list.forceActiveFocus()
        file_list.currentIndex = -1;
        file_list.lastIndex = -1
    }
    Keys.onPressed: {
        if(MKeys.pressedFnAcc("CROSS", event))
        {
            if(file_list.currentIndex == 0)
            {
                directoryUpHighLight = true
            }
        }
        MKeys.pressedFnAcc("STAR", event);
        MKeys.pressedFnAcc("BROWSE", event);
        MKeys.pressedFnAcc("ZOOM_IN", event);
    }
    Text {
        id: header
        text: "<font color=\"" + constants.menuHighlightColor + "\">" + qsTr("BROWSE") + ":</font> " + qsTr("FOLDERS") + " - " +
              ((ContentModel.browseVolume === 0xFF) ? guiconfig.emptyString :
                                                      Settings.getDisplayValue("primary_volume_image_raw", ContentModel.browseVolume) + guiconfig.emptyString)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 30
        font.pixelSize: constants.headerTextSize
        color: "white"
        font.capitalization: Font.AllUppercase
    }
    onVisibleChanged: {
        if(visible)
        {
            file_list.currentIndex = -1
            file_list.lastIndex = -1
        }
    }
    Timer {
        id: listTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: {
            directoryUpHighLight = false
            addFolderHighLight = false
            file_list.highlightAllow = false
            file_list.currentIndex = -1
        }
    }
    function startMenuWheelTimeout()
    {
        listTimer.restart();
    }
    function stopMenuWheelTimeout()
    {
        listTimer.stop();
        file_list.highlightAllow = false
    }
    ListView {
        objectName: "BrowseDirectory_file_list"
        id: file_list
        clip: true
        onCurrentIndexChanged: console.log("Now did CurrentIndex change", currentIndex)
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 74
            bottom: bottomRect.top
        }
        focus: true
        boundsBehavior: guiconfig.isRunningSimulation() ? Flickable.StopAtBounds : (Flickable.DragOverBounds | Flickable.CustomBounds)
        BoundsEffectGradient {
            parent: file_list
            fadeColor: constants.hblOrange
        }
        property bool highlightAllow: false
        orientation: ListView.Vertical
        highlightMoveDuration: constants.highlightMoveDuration
        highlight: Rectangle {
            color: file_list.highlightAllow ? constants.highlightColor : constants.popupBackgroundColor
            height: itemHeight
            width: file_list.width
        }
        delegate: Item {
            objectName: "BrowseDirectory_delegate"
            height: itemHeight
            width: file_list.width
            property var itemModel: model
            Image {
                id: folderIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 59
                source: "qrc:///icons/FolderIcon.png"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 6
                anchors.left: folderIcon.right
                anchors.leftMargin: 20
                text: model.display
                color: "white"
                font.pixelSize: 40
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 6
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: 16
                text: ""
                color: "white"
                font.pixelSize: 40
            }
            MouseArea {
                id: buttonMouseArea
                anchors.fill: parent
                onClicked: {
                    stopMenuWheelTimeout()
                    file_list.currentIndex = -1
                    file_list.lastIndex = -1
                    root.directorySelected(model.display)
                }
                onPressed: {
                    file_list.highlightMoveDuration = 0
                    file_list.currentIndex = index
                    file_list.highlightAllow = true
                }
                onReleased: {
                    file_list.highlightMoveDuration = constants.highlightMoveDuration
                    if(!containsMouse)
                        file_list.highlightAllow = false
                }
                onExited: { file_list.highlightAllow = containsMouse }
                onEntered: file_list.highlightAllow = true
                onCanceled: {
                    file_list.highlightMoveDuration = constants.highlightMoveDuration
                    if(file_list.focus) {
                        file_list.highlightAllow = false
                    }
                }
            }
        }
        property int lastIndex: 0
        Keys.onPressed: {
            if (event.isAutoRepeat)
            {
                event.accepted = true
                return
            }
            event.accepted = true
            if(MKeys.pressedFn("SELECT", event.key) ||
               MKeys.pressedFn("TPDOUBLECLICK", event.key))
            {
                event.accepted = true
                stopMenuWheelTimeout()
                if(directoryUpHighLight)
                {
                    directoryUpHighLight = false
                    file_list.lastIndex = -1
                    directoryUpSelected()
                    file_list.currentIndex = -1
                }
                else if(addFolderHighLight)
                {
                    addFolderHighLight = false
                    file_list.lastIndex = -1
                    if (ContentModel.checkWriteProtection()) {
                        createFolderConfirmDialog.active = true
                    }
                    file_list.currentIndex = -1
                }
                else
                {
                    if(file_list.currentItem !== null)
                    {
                        file_list.lastIndex = -1
                        directorySelected(file_list.currentItem.itemModel.display)
                        file_list.currentIndex = -1
                    }
                    else
                    {
                        if(file_list.count == 1)
                        {
                            file_list.lastIndex = -1
                            directorySelected(SortedContentModel.getData(0, ContentModel.DisplayRole))
                            file_list.currentIndex = -1
                        }
                    }
                }
            }
            else if(MKeys.pressedFn("LISTUP", event.key))
            {
                startMenuWheelTimeout()
                if(!highlightAllow)
                {
                    currentIndex = lastIndex
                    if(currentIndex == -1)
                    {
                        directoryUpHighLight = true
                    }
                    else if (currentIndex == -2)
                    {
                        addFolderHighLight = true
                    }
                    highlightAllow = true
                }
                else
                {
                    if(currentIndex === 0)
                    {
                        directoryUpHighLight = true
                        currentIndex = -1
                    }
                    else if(currentIndex === -1)
                    {
                        directoryUpHighLight = false
                        addFolderHighLight = true
                        currentIndex = -2
                    }
                    else if (currentIndex >= 0)
                    {
                        decrementCurrentIndex()
                    }
                }
                lastIndex = currentIndex
            }
            else if(MKeys.pressedFn("LISTDOWN", event.key))
            {
                startMenuWheelTimeout();
                if(!highlightAllow)
                {
                    currentIndex = lastIndex
                    if(currentIndex == -1)
                    {
                        directoryUpHighLight = true
                    }
                    else if(currentIndex == -2)
                    {
                        addFolderHighLight = true
                    }
                    highlightAllow = true
                }
                else
                {
                    if(currentIndex == -1)
                    {
                        currentIndex = 0
                        directoryUpHighLight = false
                    }
                    else if(currentIndex == -2)
                    {
                        currentIndex = -1
                        directoryUpHighLight = true
                        addFolderHighLight = false
                    }
                    else
                    {
                        incrementCurrentIndex()
                    }
                }
                lastIndex = currentIndex
            }
            else
                event.accepted = false
        }
        Connections {
            target: file_list.model
            onListSizeChanged: {
                if((typeof file_list !== "undefined") && (file_list !== null))
                {
                    file_list.currentIndex = 0
                }
            }
        }
    }
    Rectangle {
        visible: !file_list.highlightAllow || file_list.currentIndex === -1 || ((currentItemYValue > file_list.height) ||
                                                   (currentItemYValue < (file_list.height - itemHeight - height)))
        anchors.bottom: file_list.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "black" }
        }
    }
    Rectangle {
        id: topGradient
        visible: !file_list.highlightAllow || file_list.currentIndex === -1 || ((currentItemYValue > height) ||
                                                   (currentItemYValue < -itemHeight))
        anchors.top: file_list.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30
        gradient: Gradient {
            GradientStop { position: 0.0; color: "black" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    Rectangle {
        id: bottomRect
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: 50
        color: "black"
    }
    Component.onDestruction: {
        allowDimming = false
    }
    onFolderAdded: {
        file_list.positionViewAtEnd()
    }
}
