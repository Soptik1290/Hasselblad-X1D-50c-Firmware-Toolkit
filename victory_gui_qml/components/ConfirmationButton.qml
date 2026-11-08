import QtQuick 2.0

Rectangle {
    id: root
    visible: parent.visible
    color: "black"
    property alias labelText: label.text
    property alias bold: label.font.bold
    property alias imageSource: arrow.source
    property bool sideOriented: false
    property int centerOffset: sideOriented ? sideTextCenterMarginFirst : -bottomTextCenterMargin
    property alias labelX: label.x
    property alias labelWidth: label.width
    property bool moveLabelUp: false

    Text {
        id: label
        objectName: "ConfirmationButton_label"
        text: ""
        color: constants.dialogButtonTextColor
        font.pixelSize: 45
        horizontalAlignment: Text.AlignHCenter
        visible: parent.visible
    }

    Image {
        id: arrow
        source: "qrc:///icons/popupButtonArrow.png"
        visible: parent.visible
    }

    // Manage button orientation state.
    states: [
        State {
            when: !sideOriented
            name: "bottomOriented"
            PropertyChanges {
                target: root
                width: label.contentWidth + 30
                height: label.contentHeight + arrow.height + constants.popupBottomMargin
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    horizontalCenterOffset: centerOffset
                    bottom: parent.bottom
                }
            }
            PropertyChanges {
                target: label
                anchors {
                    horizontalCenter: root.horizontalCenter
                    bottom: arrow.top
                    bottomMargin: moveLabelUp ? label.height : 0
                }
            }
            PropertyChanges {
                target: arrow
                anchors {
                    horizontalCenter: label.horizontalCenter
                    bottom: root.bottom
                    topMargin: 0//-constants.popupBottomTextMargin
                }
            }
        },

        State {
            when: sideOriented
            name: "sideOriented"
            PropertyChanges {
                target: root
                width: label.width + arrow.width + 30
                height: label.height + label.anchors.verticalCenterOffset
                anchors {
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: centerOffset
                    right: parent.right
                }
            }
            PropertyChanges {
                target: label
                anchors {
                    verticalCenter: root.verticalCenter
                    verticalCenterOffset: guiconfig.isLatin(label.text) ? (label.implicitHeight - label.baselineOffset) * 0.3 : 0
                    right: arrow.left
                    rightMargin: constants.popupBottomTextMargin
                }
            }
            PropertyChanges {
                target: arrow
                rotation: -90
                anchors {
                    verticalCenter: root.verticalCenter
                    rightMargin: 0
                    right: root.right
                }
            }
        }
    ] // states
}
