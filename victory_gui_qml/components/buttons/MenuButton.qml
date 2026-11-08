import QtQuick 2.0
Item {
    id: root
    signal clicked()
    property string text: "..."
    property bool isEnabled: true
    property int fontPixelSize: constants.itemTextSize
    property int spacing: constants.menuButtonSpacing
    property int maxWidth: parent.width
    property int minWidth: 0
    property bool mousePressed: ma.pressed && ma.containsMouse
    property color buttonColor: (mousePressed || buttonPressed) && isEnabled ? constants.buttonAreaPressedColor : highlight ? constants.hblOrange : constants.buttonAreaColor
    property color borderColor: constants.buttonBorderColor
    property color borderColorHighLight: constants.buttonBorderColor
    property bool isImageButton: false
    property int buttonBorderWidth: 3
    property int buttonBorderTextMargin: 3
    property string buttonData
    property bool highlight: false
    property bool buttonPressed: false
    width: {
        var expectedWidth = isImageButton ? (buttonImage.width + 2 * spacing) : buttonText.implicitWidth + 2 * spacing
        if(0 != minWidth)
            expectedWidth = Math.max(minWidth, expectedWidth)
        if(0 != maxWidth)
            expectedWidth = Math.min(maxWidth, expectedWidth)
        return expectedWidth
    }
    height: constants.buttonHeight
    Rectangle {
        id: buttonBorder
        radius: 0
        color: buttonColor
        border {
            color: isEnabled ? (highlight ? borderColorHighLight : borderColor) : constants.buttonDisabledColor
            width: buttonBorderWidth
        }
        height: parent.height
        width: parent.width
    }
    Text {
        id: buttonText
        text: root.text
        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: guiconfig.usingUnicodeLanguage ? 0 : (height - baselineOffset) / 2
            horizontalCenter: buttonBorder.horizontalCenter
        }
        width: root.minWidth - (buttonBorderWidth + buttonBorderTextMargin) * 2
        font.pixelSize: fontPixelSize
        fontSizeMode: Text.HorizontalFit
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        color: isEnabled ? ((mousePressed || buttonPressed) ? constants.buttonTextPressedColor : constants.buttonTextColor) : constants.buttonDisabledColor
        visible: !isImageButton
    }
    Image {
        id: buttonImage
        anchors.centerIn: buttonBorder
        anchors.leftMargin: spacing
        source: buttonData
        clip: true
    }
    MouseArea {
        id: ma
        anchors.fill: buttonBorder
        onClicked: if(isEnabled) root.clicked()
    }
}
