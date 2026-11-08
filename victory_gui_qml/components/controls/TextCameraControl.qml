import QtQuick 2.0

Item {
    id: root
    property int labelMargin: 11
    property alias toplabel: toplabel_string.text
    property alias label: label_string.text
    property alias labelSize: label_string.font.pixelSize
    property alias value: value_string.text
    property alias valueSize: value_string.font.pixelSize
    property alias unit1: unit1_string.text
    property alias unit1Size: unit1_string.font.pixelSize
    property alias value2: value2_string.text
    property alias value2Size: value2_string.font.pixelSize
    property alias unit2: unit2_string.text
    property alias unit2Size: unit2_string.font.pixelSize
    property bool labelLow: false
    property bool allowHighlightBracket: false
    property bool forceHighlight: false
    property alias spacing: textRow.spacing
    property bool outlineText: false
    property color outlineColor: "grey"
    property alias outlineStyleColor: label_string.styleColor
    property string icon: ""

    height: value_string.height
    width: (labelIcon.visible ? labelColumn.width : 0) + label_string.width + value_string.width + unit1_string.width + value2_string.width + unit2_string.width // Note that childrenrect.width does not give correct width when text changed
    Row {
        id: textRow
        anchors.top: parent.top

        Column {
            id: labelColumn
            anchors.bottom: root.labelLow ? value_string.bottom : undefined;
            anchors.bottomMargin: root.labelMargin
            spacing: 4

            Item{
                width: labelIcon.width + 10
                height: labelIcon.height
                Image {
                    id: labelIcon
                    visible: icon != ""
                    source: icon
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                }
            }

            RoundedTextIndicator {
                id: toplabel_string
                visible: text != ""
                text: ""
                width: 70
                height: 22
                pixelSize: 20
                outlineText: root.outlineText
                outlineColor: root.outlineColor
                outlineTextColor: root.outlineStyleColor
                nonOutlinedTextColor: label_string.color
            }

            Text {
                id: label_string
                color: ((root.focus && root.allowHighlightBracket) || root.forceHighlight) && !outlineText ?
                           constants.highlightColor :
                           outlineText ?
                               outlineColor :
                               "white"
                font.bold: true
                style: outlineText ? Text.Outline : Text.Normal
                styleColor: "white"
                // labelLow means we anchor by text baseline, otherwise AlightTop (which is the default)
                font.family: constants.cameraControlTextFontName
            }
        }

        Text {
            id: value_string
            anchors.top: parent.top
            height: implicitHeight
            width: implicitWidth
            color: label_string.color
            font.bold: label_string.font.bold
            verticalAlignment: label_string.verticalAlignment
            style : label_string.style
            styleColor: label_string.styleColor
            font.family: constants.cameraControlTextFontName
        }
        Text {
            id: unit1_string
            color: label_string.color
            font.bold: true
            anchors.baseline: value_string.baseline
            style : label_string.style
            styleColor: label_string.styleColor
            font.family: constants.cameraControlTextFontName
        }
        Text {
            id: value2_string
            height: implicitHeight
            width: implicitWidth
            color: label_string.color
            font.bold: label_string.font.bold
            anchors.top: value_string.top
            anchors.topMargin: 12
            style : label_string.style
            styleColor: label_string.styleColor
            font.family: constants.cameraControlTextFontName
        }
        Text {
            id: unit2_string
            color: label_string.color
            font.bold: true

            // labelLow means we anchor by text baseline, otherwise AlightTop (which is the default)
            anchors.baseline: value2_string.baseline
            style : label_string.style
            styleColor: label_string.styleColor
            font.family: constants.cameraControlTextFontName
        }
    } // Row

} // Item

