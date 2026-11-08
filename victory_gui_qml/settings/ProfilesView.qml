import QtQuick 2.0
import com.hasselblad.config 1.0
import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    id: root
    color: "black"
    property int gridSideMargin: 50
    property int gridTopMargin: 100
    property bool preventSwipe: popup.active
    MouseArea{
        anchors.fill: parent
        onClicked: {}
    }
    function startWheelTimeout()
    {
        wheelTimer.restart();
    }
    function stopWheelTimeout()
    {
        wheelTimer.stop();
    }
    ListModel {
        id: profileModel
    }
    Timer {
        id: wheelTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: {
            grid.lastIndex = grid.currentIndex
            grid.currentIndex = -1
            root.focus = true
        }
    }
    Rectangle {
        id: viewEndLine
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: constants.viewEndLineWidth
    }
    Text {
        id: header
        anchors {
            left: viewEndLine.right
            right: parent.right
            top: parent.top
            topMargin: constants.headerVerticalOffset
        }
        text: "<font color=\"" + constants.menuHighlightColor + "\">"
              + qsTranslate("MainScreen", "GENERAL SETTINGS").toLocaleUpperCase()
              + ":</font> &nbsp;"
              + qsTranslate("MENUS", "Profiles").toLocaleUpperCase()
              + guiconfig.emptyString
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        font.capitalization: Font.AllUppercase
    }
    GridView {
        objectName: "Profile_grid"
        id: grid
        cellWidth: width / 4
        cellHeight: height / 2
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        visible: true
        model: profileModel
        anchors.fill: parent
        anchors.leftMargin: gridSideMargin
        anchors.rightMargin: gridSideMargin
        anchors.topMargin: gridTopMargin
        keyNavigationWraps: true
        highlightFollowsCurrentItem: false
        currentIndex: -1
        property int lastIndex: -1
        property bool preventFrame: false
        onFocusChanged: {
            if (!focus) {
                lastIndex = currentIndex
                currentIndex = -1
            }
            else {
                startWheelTimeout()
                if (currentIndex < 0 || currentIndex >= count) {
                    if (-1 === lastIndex) {
                        lastIndex = 0
                    }
                    currentIndex = lastIndex
                }
                else if(-1 === lastIndex) {
                    lastIndex = currentIndex
                }
            }
        }
        delegate: Item {
            objectName: "profile_delegate_item"
            id: delegateRoot
            width: grid.cellWidth-15
            height: grid.cellHeight
            FramedImage {
                objectName: "profile_framed_image"
                id: frameImage
                text: qsTranslate("MENUS", name) + guiconfig.emptyString
                textColor: constants.popupTextColor
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                focus: parent.GridView.isCurrentItem
                source: iconSrc
                showFrameAtFocus: !grid.preventFrame
                forceShowHighlite: (index === configstore.activeProfile)
                showInvertedFocus: (index === configstore.activeProfile)
                borderHighlightColor: (index === configstore.activeProfile && index === grid.currentIndex) ? "white" : constants.highlightColor
                selectable: true
                Text {
                    visible: index > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: 1
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 17
                    color: "white"
                    text: index.toString()
                    font.bold: true
                }
                Text {
                    visible: index === configstore.activeProfile && configstore.activeProfileDirty
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 17
                    anchors.rightMargin: index !== 0 ? anchors.topMargin : 5
                    color: "white"
                    text: "*"
                    font.pixelSize: 40
                    font.bold: true
                }
                onPressed: {
                    grid.preventFrame = true
                    grid.focus = true
                    grid.currentIndex = index
                }
                onReleased: { grid.lastIndex = index; grid.currentIndex = -1 }
                onClicked: { gotClick() }
            }
        }
    }
    function gotClick()
    {
        if (grid.currentIndex >= 0 && grid.currentIndex < grid.count) {
            popup.active = true
            grid.currentIndex = -1
            stopWheelTimeout()
        }
        grid.preventFrame = false
    }
    Keys.onPressed: {
        event.accepted = true;
        if(MKeys.pressedFn("RIGHT", event.key) || MKeys.pressedFn("SQUARE", event.key)) {
            if(-1 == grid.currentIndex && -1 != grid.lastIndex) {
                grid.currentIndex = grid.lastIndex
            } else {
                grid.moveCurrentIndexRight()
            }
        } else if(MKeys.pressedFn("LEFT", event.key) || MKeys.pressedFn("CROSS", event.key)) {
            if(-1 == grid.currentIndex && -1 != grid.lastIndex) {
                grid.currentIndex = grid.lastIndex
            } else {
                grid.moveCurrentIndexLeft()
            }
        } else if(MKeys.pressedFn("UP", event.key)) {
            if(-1 == grid.currentIndex && -1 != grid.lastIndex) {
                grid.currentIndex = grid.lastIndex
            } else if (grid.currentIndex >= 4) {
                grid.currentIndex = grid.currentIndex - 4
            }
        } else if(MKeys.pressedFn("DOWN", event.key)) {
            if(-1 == grid.currentIndex && -1 != grid.lastIndex) {
                grid.currentIndex = grid.lastIndex
            } else if (grid.currentIndex < 4) {
                grid.currentIndex = grid.currentIndex + 4
            }
        } else if(MKeys.pressedFnAcc("ENTER", event) || MKeys.pressedFn("STAR", event.key)) {
            gotClick()
        } else
            event.accepted = false
        if(event.accepted && !popup.active) {
            startWheelTimeout()
        }
    }
    function fillModel() {
        profileModel.clear()
        var nameStr = configstore.profileNames
        var names = nameStr.split('€')
        for (var i = 0; i < names.length; i++) {
            profileModel.append({"name": names[i], "iconSrc": (i == 0 ? "qrc:///icons/SpiritNormalMode.png" : "qrc:///icons/SpiritUserMode.png")})
        }
    }
    Loader {
        id: popup
        objectName: "Profiles_popupLoader"
        asynchronous: false
        anchors.fill: parent
        onLoaded: item.forceActiveFocus()
        active: false
        onActiveChanged: {
            if (active) {
                setSource("qrc:/settings/ProfileEdit.qml", {"profileIndex": grid.currentIndex, "name": profileModel.get(grid.currentIndex).name})
            } else {
                source = ""
            }
        }
        Connections {
            target: popup.item
            onVisibleChanged: {
                if ((popup.item !== null) && !popup.item.visible) {
                    popup.active = false
                    root.forceActiveFocus()
                }
            }
        }
    }
    Component.onCompleted: {
        fillModel()
        forceActiveFocus()
    }
}
