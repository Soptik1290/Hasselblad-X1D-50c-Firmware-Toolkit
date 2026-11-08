
import QtQuick 2.0

Item {
    objectName: "settingsCheckbox"
    property int boxSize: 30
    property bool value
    property string checkboxText
    property int itemSpacing: 20
    property bool isEnabled: true
    property int checkBoxTextRightMargin: constants.subSettingDropDownXMargin

    signal checkChange()

    // Checkbox
    Rectangle{
        id: check
        anchors {
            left: checkText.right
            leftMargin: constants.subSettingDropDownSpacing
            verticalCenter: parent.verticalCenter
        }
        width: boxSize
        height: boxSize
        color: "transparent"
        border.color: isEnabled ? "white" : "grey"
        border.width: 2
    }


    // Text
    Text {
        id: checkText
        anchors {
            right: parent.horizontalCenter
            rightMargin: checkBoxTextRightMargin
            left: parent.left
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: guiconfig.usingUnicodeLanguage ? 0 : (height - baselineOffset) / 2
        }
        fontSizeMode: Text.HorizontalFit

        text: checkboxText + ":"
        color: isEnabled ? constants.menuItemColor : "grey"
        font.family: constants.menuItemFontName
        font.pixelSize: constants.itemTextSize
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
    }

    Image {
        source: isEnabled ? "qrc:///icons/Check.png" : "qrc:///icons/Check_inactive.png"
        anchors.left: check.left
        anchors.leftMargin: 5
        anchors.top: check.top
        anchors.topMargin: -5
        visible: value ? true : false
    }

    MouseArea{
        enabled: isEnabled
        anchors.fill: parent
        onClicked: checkChange()
    }
    Keys.onReturnPressed: if(isEnabled) checkChange()
}

