import QtQuick 2.0

import "qrc:///liveview"

Rectangle {
    color: constants.menuBackgroundColor

    // Header bar
    Rectangle {
        id: headerBar
        color: constants.menuBackgroundColor
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: constants.headerVerticalOffset
        }
        height: header.height
    }

    // Header text
    Text {
        id: header
        anchors {
            left: parent.left
            right: parent.right
            top: headerBar.top
            //topMargin: constants.headerVerticalOffset
        }
        text: "<font color=\"" + constants.menuHighlightColor + "\">"
              + qsTranslate("MainScreen", upperMenuLabel).toLocaleUpperCase()
              + ":</font> &nbsp;"
              + qsTranslate("MENUS", menuLabel).toLocaleUpperCase()
              + guiconfig.emptyString
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: constants.headerTextSize
        color: constants.menuHeaderColor
        font.capitalization: Font.AllUppercase
    }

    HTS {
        id: hts
        anchors {
            top: headerBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }

    Component.onCompleted: hts.setHTS()

}
