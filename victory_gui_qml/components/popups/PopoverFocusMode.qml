import QtQuick 2.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0
import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys
Popover {
    id: popFocusMode
    property int gridspacing: constants.popupGridSpacing
    onFocusChanged: if (focus) grid.focus = true
    heading: qsTr("FOCUS MODE") + guiconfig.emptyString
    contentItem: grid
    content: Item {
        anchors.fill: parent
        GridView {
            id: grid
            interactive: false
            anchors {
                fill: parent
                leftMargin: constants.popupSideMargins
                rightMargin: constants.popupSideMargins
                topMargin: 29
                bottomMargin: 41
            }
            keyNavigationWraps: false
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: width / 2
            cellHeight: height / 2
            Component.onCompleted: updateFocus()
            onCountChanged: updateFocus()
            function updateFocus() {
                for (var i = 0; i < model.count; i++) {
                    if (model.get(i).focusmode === Camera.FocusMode)
                        currentIndex = i;
                }
            }
            function setSelected()
            {
                Camera.FocusMode = model.get(grid.currentIndex).focusmode
                popFocusMode.close();
            }
            model: grid_model_wedge
            delegate: Item {
                id: grid_delegate
                width: grid.cellWidth - gridspacing
                height: grid.cellHeight - gridspacing
                FramedImage {
                    text: qsTr(model.text) + guiconfig.emptyString
                    textColor: constants.popupTextColor
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    focus: parent.GridView.isCurrentItem
                    source: icon
                    showInvertedFocus: true
                    onPressed: {
                        grid.focus = true
                    }
                    onClicked: {
                        grid.currentIndex = index
                        grid.setSelected()
                    }
                }
                Keys.onPressed: {
                    if(MKeys.pressedFnAcc("AF_MF", event))
                    {
                        grid.setSelected()
                    }
                    else
                    {
                        event.accepted = false
                    }
                }
            }
        }
        ListModel {
            id: grid_model_wedge
            ListElement {
                icon: "qrc:///icons/AF_Manual.png"
                text: QT_TR_NOOP("Manual Focus")
                focusmode: Config.Focus_MAN
            }
            ListElement {
                icon: "qrc:///icons/AF_Single.png"
                text: QT_TR_NOOP("Single Focus")
                focusmode: Config.Focus_AFS
            }
        }
    }
}
