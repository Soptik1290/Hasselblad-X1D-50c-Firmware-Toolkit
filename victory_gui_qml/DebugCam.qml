import QtQuick 2.0

Rectangle {
    id: root
    color: "black"
    property int selected: farm.rawprocessing_mode
    property int buttonWidth: 40
    property string headingText
    property bool patternValue: false

    Text {
        id: heading
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: "white"
        font.pixelSize: buttonWidth
        text: qsTr(headingText) + guiconfig.emptyString
        font.capitalization: Font.AllUppercase
    }

    ListView {
        anchors.top: heading.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.right: parent.right
        model: items
        delegate: Item {
            id: view_delegate
            width: the_row.width
            height: the_row.height
            Row {
                id: the_row
                spacing: 20
                Rectangle{
                    id: button
                    color: root.selected === value ? "black" : "white"
                    border.color: "white"
                    border.width: 5
                    width: buttonWidth
                    height: buttonWidth
                    radius: buttonWidth / 2
                }
                Text {
                    color: "white"
                    font.pixelSize: button.height
                    text: display
                }
            }
            MouseArea{
                anchors.fill: parent
                onClicked: { root.selected = value }
            }
        }
    }

    ListModel {
        id: items

        ListElement {
            display: "Normal"
            value: 0
        }

        ListElement {
            display: "Uncalibrated"
            value: 1
        }

        ListElement {
            display: "GC Map"
            value: 2
        }

        ListElement {
            display: "Offset Map"
            value: 3
        }

        ListElement {
            display: "ETC Map"
            value: 4
        }

        ListElement {
            display: "Gain Map"
            value: 5
        }

        ListElement {
            display: "Blemish Map"
            value: 6
        }
    }

    onSelectedChanged: farm.rawprocessing_mode = selected
}

