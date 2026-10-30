import QtQuick 2.0
import "qrc:///scripts/Keys.js" as MKeys
import com.hasselblad.guiconfig 1.0


Rectangle {
    objectName: "BrowseSelectCard_root"
    anchors.fill: parent
    id: root
    color: "black"

//    function directoryUpSelected()
//    {
//        card_list.currentIndex = -1
//        card_list.lastIndex = -1
//    }



    function setFocus()
    {
        card_list.forceActiveFocus()
        card_list.currentIndex = -1
        card_list.lastIndex = -1
    }

    property alias model: card_list.model
    property alias currentIndex: card_list.currentIndex
    signal directorySelected(string dir)
    property alias cardListFocus: card_list.focus
    onCardListFocusChanged: console.log("cardListFocus: ", cardListFocus)
    property bool allowDimming: true
    property int oldActiveCard: -1


    property int itemWidth: 258
    property int buttonWidth: 210
    property int borderThickness: 3

    Keys.onPressed: {
        // Prevent F3 from being used somewhere else
        MKeys.pressedFnAcc("STAR", event);
        MKeys.pressedFnAcc("BROWSE", event);
        MKeys.pressedFnAcc("ZOOM_IN", event);
    }

    Text {
        id: header
        text: "<font color=\"" + constants.menuHighlightColor + "\">" + qsTr("BROWSE") + ":</font> " + qsTr("MEMORY CARDS") + guiconfig.emptyString
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 30
        font.pixelSize: constants.headerTextSize
        color: "white"
        font.capitalization: Font.AllUppercase
    }

    Text {
        id: centerText
        text: qsTr("Select Card to Browse") + guiconfig.emptyString
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 129
            left: parent.left
        }
        font.pixelSize: 60
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        color: "white"
    }

    // Reset index when entering this
    onVisibleChanged: {
        if(visible)
        {
            card_list.currentIndex = -1
        }
    }

    Timer {
        id: listTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: card_list.highlightAllow = false
    }

    function startMenuWheelTimeout()
    {
        listTimer.restart();
    }

    function stopMenuWheelTimeout()
    {
        listTimer.stop();
    }


    ListView {
        objectName: "BrowseSelectCard_card_list"
        id: card_list
        width: count < 2 ? root.itemWidth * count : root.itemWidth * 2
        height: 109
        anchors{
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 226
        }
        focus: true
        onActiveFocusChanged: console.log("active cardListFocus: ", activeFocus)
        interactive: false
        property bool highlightAllow: false

        orientation: ListView.Horizontal
        highlightMoveVelocity: -1 // TODO: make optional animation possible (highlightMoveVelocity: root.width * 5)
        highlight: Item {
            height: card_list.height
            width: root.itemWidth
            z: 10
            Rectangle {
                width: root.buttonWidth
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: "transparent"
                border.color: card_list.highlightAllow ? constants.highlightItemColor : "transparent"
                border.width: (oldActiveCard === card_list.currentIndex ? 2 : 1) * root.borderThickness
            }
        }

        delegate: Item {
            height: card_list.height
            width: root.itemWidth
            Rectangle {
                id: buttonRect
                width: root.buttonWidth
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: buttonMouseArea.containsPress ? "white" : ((index == card_list.currentIndex) && card_list.highlightAllow) ? constants.hblOrange : "transparent"
                border.color: constants.hblOrange
                border.width: (oldActiveCard === index ? 2 : 1) * root.borderThickness
            }
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 9
                text: beautyPrint(model.display) // It would be nice here to have the actual UNIT number as a role and convert into the specific card name.
                color: buttonMouseArea.containsPress ? "black" : "white"
                font.pixelSize: 60
            }
            Keys.onPressed: {
                if(MKeys.pressedFnAcc("SELECT", event) ||
                   MKeys.pressedFn("TPDOUBLECLICK", event.key))
                {
                    root.directorySelected(model.display)
                }
                else
                {
                    event.accepted = false
                }
            }
            MouseArea {
                id: buttonMouseArea
                anchors.fill: buttonRect
                onClicked: {
                    card_list.currentIndex = index
                    root.directorySelected(model.display)
                }
            }
        }

        property int lastIndex: -1
        Keys.onPressed: {
            event.accepted = true
            if(MKeys.pressedFn("NAVLEFT", event.key) || MKeys.pressedFn("UP", event.key)) {
                startMenuWheelTimeout()
                highlightAllow = true
                if(-1 != currentIndex || -1 == lastIndex)
                    decrementCurrentIndex()
                else
                    currentIndex = lastIndex
                lastIndex = currentIndex // This may look peculiar, but its in order!
            }
            else if(MKeys.pressedFn("NAVRIGHT", event.key) || MKeys.pressedFn("DOWN", event.key)) {
                startMenuWheelTimeout();
                highlightAllow = true
                if(-1 != currentIndex || -1 == lastIndex)
                    incrementCurrentIndex()
                else
                    currentIndex = lastIndex
                lastIndex = currentIndex // This may look peculiar, but its in order!
            }
            else
                event.accepted = false
        }

    }

    // Turn off backlight when screen is black (when there are no items to show)
    /*
    states: [
        State {
            name: "NoItems"
            when: (card_list.count == 0) && (ErrorControl.code === Errors.ErrorNone) && root.allowDimming
            PropertyChanges { target: backlight; brightness: constants.blackScreenBrightness }
        }
    ]
    */

    function beautyPrint(cardName)
    {
        if((typeof cardName === 'undefined') || (cardName === undefined))
        {
            return ""
        }

        // TODO: Do something better here. We get a card name as input but should get a slot number.
        switch(cardName.toUpperCase())
        {
        case "SD0":
            if(GuiConfig.SlDualSD === guiconfig.storageSlots) {
                return "SD1";
            }
            return "SD"

        case "SD1":
            if(GuiConfig.SlDualSD === guiconfig.storageSlots) {
                return "SD2";
            }
            return "SD"

        case "SDCARD":
            if(GuiConfig.SlDualSD === guiconfig.storageSlots) {
                return "SD2";
            }
            return "SD"
        case "CFAST0":
        case "CFAST":
            if(GuiConfig.SlDualSD === guiconfig.storageSlots) {
                return "SD1";
            }
            return "CFast"
        default:
            return cardName
        }
    }

    Component.onDestruction: {
        allowDimming = false
    }

}
