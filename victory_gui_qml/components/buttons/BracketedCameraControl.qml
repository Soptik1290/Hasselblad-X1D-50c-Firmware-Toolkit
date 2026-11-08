import QtQuick 2.5
import QtGraphicalEffects 1.0
Item {
    property alias symbol: symbol.source
    width: Math.max(constants.minWidthBrackets, left_bracket.width + symbol.width +right_bracket.width)
    height: left_bracket.height
    property bool allowHighligtBracket: false
    property bool showBracket: true
    property bool forceBackground: false
    id: root
    property bool popupShowed: false
    property alias symbolOpacity: symbol.opacity
    function startBlink()
    {
        blinkLoop.start();
    }
    signal clicked
    Rectangle {
        id: backGround
        color: (ma.containsPress && showBracket) || forceBackground ? constants.hblOrange : "transparent"
        anchors.fill: parent
        visible: true
    }
    Image {
        id: left_bracket
        anchors.left: parent.left
        anchors.top: parent.top
        source: parent.focus && allowHighligtBracket ? "qrc:///icons/left_bracket_orange.png" : "qrc:///icons/left_bracket.png"
        visible: showBracket
    }
    Image {
        id: symbol
        anchors.verticalCenter: left_bracket.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
    }
    Image {
        id: right_bracket
        anchors.right: parent.right
        anchors.verticalCenter: symbol.verticalCenter
        source: parent.focus && allowHighligtBracket ? "qrc:///icons/right_bracket_orange.png" : "qrc:///icons/right_bracket.png"
        visible: showBracket
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if(containsPress) parent.clicked()
    }
    SequentialAnimation {
        id: blinkLoop
        loops: constants.animationBlinkLoops
        NumberAnimation {
            target: symbol
            property: "opacity"
            to: 0
            duration: constants.animationDurationBlink
            easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: constants.animationDurationBlink }
        NumberAnimation {
            target: symbol
            property: "opacity"
            to: 1
            duration: constants.animationDurationBlink
            easing.type: Easing.OutCubic
        }
        PauseAnimation { duration: constants.animationDurationBlink }
    }
    onSymbolChanged: {
        if(popupShowed)
        {
            startBlink();
            popupShowed = false;
        }
    }
}
