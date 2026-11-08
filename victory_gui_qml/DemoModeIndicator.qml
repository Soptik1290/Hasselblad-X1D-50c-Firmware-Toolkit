import QtQuick 2.0
import com.hasselblad.farm 1.0

Item {
    id: demoIndicator
    property int fontSize: 24
    visible: farm.ram_only_mode === Farm.RamModeRamOnly
    width: childrenRect.width
    height: childrenRect.height

    Rectangle {
        id: demoLabelRect
        width: 130
        height: constants.cardStatusIconSize * 2
        color: "red"
        border.width: 2
        border.color: constants.cardStatusNotActiveBorderColor
    }
    Text {
        anchors {
            top: demoLabelRect.top
            topMargin: 6
            left: demoLabelRect.left
            right: demoLabelRect.right
            leftMargin: 5
            rightMargin: 5
        }
        //anchors.horizontalCenter: demoLabelRect.horizontalCenter
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        color: "white"
        text: qsTr("NO") + guiconfig.emptyString
        font.pixelSize: demoLbText2.font.pixelSize
        font.bold: true
    }

    Text {
        id: demoLbText2
        anchors {
            bottom: demoLabelRect.bottom
            bottomMargin: 2
            left: demoLabelRect.left
            right: demoLabelRect.right
            leftMargin: 5
            rightMargin: 5
        }
        //anchors.horizontalCenter: demoLabelRect.horizontalCenter
        color: "white"
        text: qsTr("STORAGE") + guiconfig.emptyString
        horizontalAlignment: Text.AlignHCenter
        fontSizeMode: Text.Fit
        font.pixelSize: fontSize
        font.bold: true
    }
}
