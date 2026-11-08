import QtQuick 2.0

Rectangle {
    id: root
    objectName: "FramedItem_root"
    width: 50
    height: 80
    color: showInvertedFocus && ((focus && !mouseArea.pressed) || (mouseArea.containsMouse && mouseArea.pressed && selectable) || forceShowHighlite) ? constants.highlightColor : backColor
    border.color: showFrameAtFocus && ((focus && !mouseArea.pressed) || (mouseArea.containsMouse && mouseArea.pressed) || forceShowHighlite) ? borderHighlightColor : backColor
    border.width: 5
    radius: 0
    property bool selectable: true
    opacity: selectable ? 1 : 0.5

    // The color the text should have
    property color textColor: "white"
    property color borderHighlightColor: constants.highlightColor
    property color backColor: "transparent"
    property alias content: childContent.children
    property alias textWrapping: subheading.wrapMode
    property string text: ""
    property bool showInvertedFocus: false // true -> invert frame colors when selected
    property bool showBoldTextAtFocus: true // true -> text will be fat when button focused
    property bool showBoldText: showBoldTextAtFocus && (mouseArea.containsMouse && mouseArea.pressed)
    property bool showFrameAtFocus: false // true -> frame will be highlighted when button focused
    property bool forceShowHighlite: false
    signal clicked()
    signal pressAndHold()
    signal pressed()
    signal released()
    property bool acceptKeys: true

    Keys.onReturnPressed: {
        if(acceptKeys)
        {
            root.clicked()
            event.accepted = true
        }
        else
        {
            event.accepted = false
        }
    }

    Item {
        id: childContent
        anchors.centerIn: parent
    }

    Text {
        id: subheading
        visible: parent.text != ""
        anchors.topMargin: 2
        anchors.top: parent.bottom
        anchors.left: parent.left
        width: parent.width
        text: parent.text
        color: textColor
        font.weight: showBoldText ? Font.Bold : Font.Light
        font.pixelSize: 20
        fontSizeMode: guiconfig.usingUnicodeLanguage ? Text.HorizontalFit : Text.FixedSize
        horizontalAlignment: Text.AlignHCenter
        wrapMode: guiconfig.usingUnicodeLanguage ? Text.NoWrap : Text.Wrap
    }

    MouseArea {
        id: mouseArea
        anchors.top: root.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: subheading.visible ? subheading.bottom : root.bottom
        onClicked: root.clicked()
        onPressAndHold: root.pressAndHold()
        onPressed: root.pressed()
        onReleased: if(!containsMouse) { root.released() }
    }
}
