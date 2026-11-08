import QtQuick 2.0
import com.hasselblad.settings 1.0
import "qrc:/scripts/Keys.js" as MKeys
ListSelector {
    id: root
    property int gridspacing: 10
    property alias model: list.model
    property string currentlySelectedValue: null
    signal selectedValueChanged(string value);
    onFocusChanged: if (focus) list.focus = true;
    function itemSelected(index)
    {
        if (index >= 0)
        {
            root.selectedValueChanged(list.model[index])
        }
        root.close();
    }
    function setSelected()
    {
        if(visible && (list.currentIndex >= 0))
        {
            root.selectedValueChanged(list.model[list.currentIndex])
        }
    }
    function setSelectedClose()
    {
        setSelected()
        root.close();
    }
    contentItem: list
    content: Item {
        anchors.fill: parent
        ListView {
            id: list
            objectName: "popup_listSelector"
            clip: true
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveVelocity: 800
            orientation: ListView.Vertical
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: list.height / 2 - list.height / constants.numberOfItemsVisibleInList / 2
            preferredHighlightEnd: list.height / 2 + list.height / constants.numberOfItemsVisibleInList / 2
            function setSelectedClose()
            {
                setSelected()
                close()
            }
            function positionHighlight() {
                var oldHighlightMoveDuration = list.highlightMoveDuration;
                list.highlightMoveDuration = 0;
                list.currentIndex = list.model.indexOf(currentlySelectedValue);
                list.highlightMoveDuration = oldHighlightMoveDuration;
            }
            onCountChanged: positionHighlight()
            Component.onCompleted: positionHighlight()
            highlight: Rectangle {
                color: constants.popupBackgroundColor
                height: list.height / constants.numberOfItemsVisibleInList
                Rectangle {
                    color: constants.highlightColor
                    anchors.fill: parent
                }
            }
            property real itemFontSizeBase: 50 * 5 / constants.numberOfItemsVisibleInList
            delegate: Item {
                id: theItem
                height: list.height / constants.numberOfItemsVisibleInList
                width: list.width
                property real addSize : (Math.max(height - Math.abs(theItem.y - list.contentY - list.preferredHighlightBegin), 0) / height) * constants.listViewSizeIncreaseFactor
                Text {
                    anchors.horizontalCenter: theItem.horizontalCenter
                    anchors.verticalCenter: theItem.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2
                    text: modelData
                    font.family: constants.menuItemFontName
                    color: theItem.ListView.isCurrentItem ? constants.highlightItemColor: constants.itemColor
                    font.pointSize: list.itemFontSizeBase * (1 + addSize)
                }
                Keys.onPressed: {
                    if(MKeys.pressedFnAcc("SELECT", event))
                    {
                        itemSelected(index)
                    }
                    else
                    {
                        event.accepted = false
                    }
                }
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    onClicked: itemSelected(index)
                }
            }
            Rectangle {
                anchors.left: list.left
                anchors.right: list.right
                anchors.top: list.top
                height: 140
                gradient: Gradient {
                    GradientStop { position: 0.0; color: constants.popoverListViewShadingStartColor }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors.left: list.left
                anchors.right: list.right
                anchors.bottom: list.bottom
                height: 140
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: constants.popoverListViewShadingStartColor }
                }
            }
        }
    }
}
