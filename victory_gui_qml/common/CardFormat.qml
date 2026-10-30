import QtQuick 2.0

import com.hasselblad.storage 1.0
import com.hasselblad.config 1.0
import com.hasselblad.farm 1.0

import "qrc:///components"
import "qrc:///components/buttons"
import "qrc:///components/popups"

import "qrc:///scripts/Keys.js" as MKeys

Rectangle {
    objectName: "CardFormat_root"
    id: root
    color: "black"
    property int cardToFormat: (!areAllPresent && isAnyPresent) ? (isCard0Present ? Config.Card0 : Config.Card1) : Config.CardNone
    property int actualCardToFormat: {
        if(cardToFormat === Config.Card0)
        {
            if(isCard0Present)
            {
                return Config.Card0
            }
            else if(isCard1Present)
            {
                return Config.Card1
            }
            else
            {
                return Config.CardNone
            }
        }
        else
        {
            if(isCard1Present)
            {
                return Config.Card1
            }
            else if(isCard0Present)
            {
                return Config.Card0
            }
            else
            {
                return Config.CardNone
            }
        }
    }
    property string header
    property int textOffset: 131
    property alias subHeader: subHeader.text
    property alias subText: subText.text
    property int sideTextCenterMarginFirst: constants.sideTextCenterMarginFirst
    property int sideTextCenterMarginMiddle: constants.sideTextCenterMarginMiddle
    property int sideTextCenterMarginLast: constants.sideTextCenterMarginLast
    property int bottomTextCenterMargin: constants.bottomTextCenterMargin
    property bool allowAskCard: areAllPresent
    property bool sideOriented: guiconfig.isWedge

    // Reducing some complexity, making comparisons more readable.
    readonly property bool isCard0Present: ContentModel.card0Status !== ContentModel.STORAGE_ABSENT
    readonly property bool isCard1Present: ContentModel.card1Status !== ContentModel.STORAGE_ABSENT
    readonly property bool areAllPresent: isCard0Present && isCard1Present
    readonly property bool isAnyPresent: isCard0Present || isCard1Present
    readonly property bool areAllAbsent: !isAnyPresent

    z:200
    focus: true

    Text {
        id: topHeader
        text: qsTr("FORMAT") + guiconfig.emptyString
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: constants.headerVerticalOffset
        font.pixelSize : constants.headerTextSize
        color: constants.dialogHeaderColor
        font.capitalization: Font.AllUppercase
        font.family: constants.menuItemFontName

    }

    Text {
        id: subHeader
        anchors {
            top: parent.top
            topMargin: textOffset
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }
        text: guiconfig.storageSlotName(actualCardToFormat) + guiconfig.emptyString
        color: "white"
        font.pixelSize: 60
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        //font.capitalization: Font.AllUppercase
    }

    Image {
        id: imgExclamationMark
        source: "qrc:///icons/exclamationMark.png"
        anchors.top: root.top
        anchors.horizontalCenter: root.horizontalCenter;
        visible: true
        states: [
            State {
                when: sideOriented
                PropertyChanges { target: imgExclamationMark; anchors { topMargin: 98 } }
            },
            State {
                when: !sideOriented
                PropertyChanges { target: imgExclamationMark; anchors { topMargin: textOffset + 85 } }
            }
        ]
    }

    Text {
        id: subText
        anchors {
            top: parent.top
            topMargin: textOffset + (sideOriented ? 62 : 184)
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }
        color: "white"
        font.pixelSize: 45
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
    }

    function exitDialog()
    {
        // Exit dialog here
        parent.active = false
    }

    function format()
    {
        if(actualCardToFormat !== Config.CardNone || root.state === "FormatCard")
            ContentModel.format(actualCardToFormat)
        else
            console.log("format() fail, state: " + root.state + ", cardToFormat:" + actualCardToFormat);
    }

    Component.onCompleted: {
        if (root.actualCardToFormat === Config.CardNone) {
            // Allow returning to AskCard state on card insert/removal changes.
            allowAskCard = true;
        }
    }


    Keys.onPressed: {
        event.accepted = true;
        // Make sure nothing can disturb formatting
        if(state !== "Formatting" && state !== "CardBusy")
        {
            if(MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("EXPOSURE", event.key))
            {
                event.accepted = false;
            }
            else if(MKeys.pressedFn("DLGEXIT", event.key))
                exitDialog()
            else if(state === "FormatCard") {
                if(MKeys.pressedFn("DLGACCEPT", event.key))
                    format()
            }
        }
    }

    MouseArea{
        anchors.fill: parent
        onClicked: {}
    }

    // This grid is only visible in the AskCard state.
    Grid {
        id: selectCardGrid
        visible: false
        columns: 2
        spacing: 10
        anchors.top: root.top
        anchors.topMargin: 216
        anchors.horizontalCenter: imgExclamationMark.horizontalCenter

        MenuButton {
            text: guiconfig.storageSlotName(Config.Card0) + guiconfig.emptyString
            onClicked: cardToFormat = Config.Card0
        }

        MenuButton {
            text: guiconfig.storageSlotName(Config.Card1) + guiconfig.emptyString
            onClicked: cardToFormat = Config.Card1
        }
    }

    ConfirmationButtons {
        id: confirmButtons
        color: root.color
        transparentBackground: true
        sideOriented: parent.sideOriented
        firstText: qsTr("Exit") + guiconfig.emptyString
        lastText: qsTr("Format") + guiconfig.emptyString
    }

    PopoverBusy {
        id: formatInfo
        anchors.fill: parent
        heading: header
        centerText: qsTr("Formatting") + guiconfig.emptyString
        icon: "qrc:///icons/exclamationMark.png"
        bottomText: qsTr("Do not remove card!") + guiconfig.emptyString
        visible: false
        enabled: false
    }

    PopoverBusy {
        id: cardBusyInfo
        anchors.fill: parent
        heading: header
        centerText: qsTr("Card busy") + guiconfig.emptyString
        icon: "qrc:///icons/exclamationMark.png"
        bottomText: qsTr("Please wait!") + guiconfig.emptyString
        visible: false
        enabled: false
    }

    states: [
        State {
            name: "Formatting"
            when: ContentModel.isFormatting
            PropertyChanges { target: formatInfo; enabled: true; visible: true }
            PropertyChanges { target: root; focus: true }
        },
        State {
            name: "CardBusy"
            when: farm.card_access
            PropertyChanges { target: cardBusyInfo; enabled: true; visible: true }
            PropertyChanges { target: root; focus: true }
        },
        State {
            name: "AskCard"
            when: (cardToFormat === Config.CardNone) && allowAskCard && areAllPresent
            PropertyChanges { target: root; subHeader: qsTr("Card to format?"); subText: "" }
            PropertyChanges { target: imgExclamationMark; visible: false }
            PropertyChanges { target: confirmButtons; lastAvailable: false }
            PropertyChanges { target: selectCardGrid; visible: true }
        },
        State {
            name: "FormatCard"
            when: (actualCardToFormat !== Config.CardRam) && isAnyPresent && !ContentModel.isFormatting
            PropertyChanges { target: root; subHeader: qsTranslate("MENUS", "Format") + ' ' + guiconfig.storageSlotName(actualCardToFormat) + "?";
                subText: qsTranslate("MENUS", "All content will be erased!");
                textOffset: sideOriented ? 80 + 128 : 80}
            PropertyChanges { target: imgExclamationMark; visible: true }
        },
        State {
            name: "NoCard"
            // This state is used when no card is available, or when selected card is not available.
            when: (!isCard0Present || (actualCardToFormat === Config.Card1)) && (!isCard1Present || (actualCardToFormat === Config.Card0))
            PropertyChanges { target: root; subHeader: qsTranslate("CardFormat", "No card available."); subText: qsTranslate("MENUS", "Please insert card...") }
            PropertyChanges { target: imgExclamationMark; visible: false }
            PropertyChanges { target: confirmButtons; firstText: qsTranslate("MENUS", "Exit"); lastAvailable: false }
            PropertyChanges { target: confirmButtons; lastText: "" }
        },
        // Catch-all error state. We should never end up here:
        State {
            name: ""
            PropertyChanges { target: root; subHeader: "Undefined state."; subText: qsTranslate("MENUS", "Error.") }
        }
    ]

    onStateChanged: console.log("New state for CardFormat: ", state)
    transitions: [
        Transition {
            from: "Formatting"
            ScriptAction{
                script: exitDialog()
            }
        }

    ]
}

