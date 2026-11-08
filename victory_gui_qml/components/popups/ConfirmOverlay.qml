import QtQuick 2.0
import com.hasselblad.storage 1.0
import "qrc:///components"
import "qrc:///scripts/Keys.js" as MKeys
Item {
    id: root
    objectName: "ConfirmOverlay_root"
    property int sideTextCenterMarginFirst: constants.sideTextCenterMarginFirst
    property int sideTextCenterMarginMiddle: constants.sideTextCenterMarginMiddle
    property int sideTextCenterMarginLast: constants.sideTextCenterMarginLast
    property int bottomTextCenterMargin: constants.bottomTextCenterMargin
    property bool sideOriented: guiconfig.isWedge
    property string headerText: ""
    property string displayText: ""
    property string confirmButtonText: ""
    property alias mainTextItem: displayTextItem
    signal exitSelected()
    signal confirmSelected()
    Keys.onPressed: {
        if(MKeys.pressedFn("ABORT", event.key)) {
            exitSelected()
            event.accepted = true
        }
        else if(MKeys.pressedFn("DLGACCEPT", event.key)) {
            confirmSelected()
            event.accepted = true
        }
        else if(MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("EXPOSURE", event.key) || MKeys.pressedFn("TOGGLESLEEP", event.key) || MKeys.pressedFn("FORMAT", event.key)) {
        }
        else
            event.accepted = true
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }
    Rectangle {
        id: bg
        color: "black"
        opacity: 0.5
        anchors.fill: parent
    }
    Rectangle {
        height: constants.dialogButtonBackgroundHeight
        width: parent.width
        anchors.top: parent.top
        color: bg.color
        opacity: 1.0
        visible: !sideOriented
        Text {
            id: headerTextItem
            text: qsTr(headerText) + guiconfig.emptyString
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: constants.dialogButtonVerticalOffset
            color: constants.dialogHeaderColor
            font.pixelSize: 20
            anchors.horizontalCenter: parent.horizontalCenter
            font.capitalization: Font.AllUppercase
        }
    }
    Text {
        id: displayTextItem
        text: qsTr(displayText) + guiconfig.emptyString
        style: Text.Outline
        styleColor: "black"
        color: "white"
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 60
        wrapMode: Text.WordWrap
        anchors {
            top: parent.top
            topMargin: 184
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }
    }
    ConfirmationButtons {
        color: "black"
        lastText: qsTr(confirmButtonText)
        sideOriented: parent.sideOriented
    }
}
