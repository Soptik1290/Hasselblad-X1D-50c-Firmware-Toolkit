import QtQuick 2.0
import "qrc:///components/controls"
ListSelector {
    objectName: "PopoverGenericNumber"
    id: popNumber
    visible: false
    property alias model: list.model
    property int selectedValue: -1
    property int numberWidth: 0
    signal selected(int number)
    onSelectedValueChanged: updateHighlight()
    onModelChanged: updateHighlight()
    function updateHighlight() {
        if (selectedValue < 0 || !model)
            return
        var oldHighlightMoveDuration = list.highlightMoveDuration;
        list.highlightMoveDuration = 0;
        for (var i = 0 ; i < model.count ; i++) {
            if (model.get(i).number === selectedValue) {
                list.currentIndex = i;
                break;
            }
        }
        list.highlightMoveDuration = oldHighlightMoveDuration;
        list.focus = true;
    }
    function itemSelected(index)
    {
        if(index >= 0)
        {
            popNumber.selected(model.get(index).number)
        }
        popNumber.close();
    }
    function setSelected() {
        popNumber.selected(model.get(list.currentIndex).number)
    }
    content: list
    contentItem: list
    ListView {
        id: list
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        anchors.fill: parent
        model: null
        function setSelectedClose()
        {
            popNumber.setSelected()
            popNumber.close();
        }
        delegate: Item {
            id: theItem
            height: list.height / constants.numberOfItemsVisibleInList
            width: list.width
            property real addSize : (Math.max(height - Math.abs(theItem.y - list.contentY - list.preferredHighlightBegin), 0) / height) * constants.listViewSizeIncreaseFactor
            Text {
                anchors.horizontalCenter: theItem.horizontalCenter
                anchors.verticalCenter: theItem.verticalCenter
                anchors.verticalCenterOffset: (height - baselineOffset) / 2
                id: numberText
                text: numberWidth === 0 ? number : String("0" + number).slice(-numberWidth);
                font.family: constants.menuItemFontName
                color: theItem.ListView.isCurrentItem ? constants.highlightItemColor: constants.itemColor
                font.pointSize: (50 * 5 / constants.numberOfItemsVisibleInList) * (1 + addSize)
                verticalAlignment: Text.AlignVCenter
            }
            Keys.onReturnPressed: popNumber.itemSelected(index)
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onClicked: popNumber.itemSelected(index)
            }
        }
        orientation: ListView.Vertical
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: list.height / 2 - list.height / constants.numberOfItemsVisibleInList / 2
        preferredHighlightEnd: list.height / 2 + list.height / constants.numberOfItemsVisibleInList / 2
        highlight: Rectangle {
            color: constants.popupBackgroundColor
            height: list.height / constants.numberOfItemsVisibleInList
            Rectangle {
                color: constants.highlightColor
                anchors.fill: parent
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
