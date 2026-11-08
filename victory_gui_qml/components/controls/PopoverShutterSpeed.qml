import QtQuick 2.0
import com.hasselblad.settings 1.0
import "qrc:///scripts/Keys.js" as MKeys
ListSelector {
    id: popShutterSpeed
    isToLeft: false
    property int gridspacing: 10
    onFocusChanged: if (focus) list.focus = true
    function itemSelected(index)
    {
        if(index >= 0)
        {
            cambody.shutterSpeed = list.model[index]
        }
        popShutterSpeed.close();
    }
    function setSelected()
    {
        if(visible && (list.currentIndex >= 0))
        {
            cambody.shutterSpeed = list.model[list.currentIndex]
        }
    }
    contentItem: list
    content: Item {
        anchors.fill: parent
        ListView {
            id: list
            model: Settings.shutterspeedValues
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
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
            onCountChanged: updateHighlight()
            Component.onCompleted: updateHighlight()
            function updateHighlight() {
                var oldHighlightMoveDuration = highlightMoveDuration;
                highlightMoveDuration = 0;
                currentIndex = model.indexOf(cambody.shutterSpeed);
                highlightMoveDuration = oldHighlightMoveDuration;
            }
            highlight: Rectangle{
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
                    anchors {
                        verticalCenter: theItem.verticalCenter
                        verticalCenterOffset: (height - baselineOffset) / 2
                        left: parent.left
                        right: parent.right
                        leftMargin: 10
                        rightMargin: 10
                    }
                    font.family: constants.menuItemFontName
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: theItem.ListView.isCurrentItem ? constants.highlightItemColor: constants.itemColor
                    font.pointSize: list.itemFontSizeBase * (1 + addSize)
                    fontSizeMode: Text.HorizontalFit
                }
                Keys.onPressed: {
                    if(MKeys.pressedFnAcc("SELECT", event))
                    {
                        list.focus = false
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
                    onClicked: {
                        list.focus = false
                        itemSelected(index)
                    }
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
