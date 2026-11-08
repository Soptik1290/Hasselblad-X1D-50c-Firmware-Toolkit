import QtQuick 2.0

import com.hasselblad.cambody 1.0
import com.hasselblad.camera 1.0

Item {
    id: root
    focus: true

    property real sizeFactor: 1
    property int itemTextSize: calcFontSize()
    property int itemBoxSize: itemTextSize * 0.75
    property real verticalOffset: (height - ((shiftLeft.height * 3) + (marginBetweenRows * 2))) / 2
    property real marginBetweenRows: itemTextSize
    property real shiftMil: cambody.hts_shift / 10
    property real tiltDegrees: cambody.hts_tilt / 10
    property real rotDegrees: cambody.hts_rotation / 10
	property bool hts_attached: cambody.hts_attached

    readonly property int maxWidth: parent.width

    function calcFontSize() {
        var stringsToConsider = [qsTranslate("HTS", "Shift"), qsTranslate("HTS", "Tilt"), qsTranslate("HTS", "Rotation")]

        stringsToConsider.sort(function (a, b) { return b.length - a.length });

        //console.log("HTS strings ", stringsToConsider)

        var maxLength = maxWidth
        var pixelSize = Math.ceil(maxLength / stringsToConsider[0].length)

        //console.log("Length: ", stringsToConsider[0].length, " maxLength ", maxLength, " Proposed font size ", pixelSize)

        // The font shall no be larger than 68.
        return (pixelSize < constants.itemTextSizeMenuLevel1 ? pixelSize : constants.itemTextSizeMenuLevel1) * root.sizeFactor
    }

    function calcHorizontalOffset() {
        var contentWidth = [shiftLeft.contentWidth,
                            tiltLeft.contentWidth,
                            rotLeft.contentWidth]

        console.log("Content widths ", contentWidth)

        var widestItemText = contentWidth.sort(function (a,b) {return b - a})[0]

        if (widestItemText > maxWidth/2) {
            var largetsContentWidth =  widestItemText + 20 + (shiftRight.contentWidth)

            return (maxWidth - largetsContentWidth) / 2
        }

        return 0
    }

    MouseArea {
        propagateComposedEvents: true
        anchors.fill: parent
    }

    Item {
        id: horizontalRuler
        width: 20
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: calcHorizontalOffset()
    }

    Item {
        id: verticalRuler
        height: verticalOffset
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    Text {
        id: shiftLeft
        anchors.top: verticalRuler.bottom
        anchors.right: horizontalRuler.left

        text: qsTranslate("HTS", "Shift") + ":"
        color: "white"

        horizontalAlignment: Text.AlignRight
        style: Text.Outline
        styleColor: "black"
        font.family: constants.menuItemFontName
        font.pixelSize: itemTextSize
    }

    Text {
        id: shiftRight
        anchors.left: horizontalRuler.right
        anchors.bottom: shiftLeft.bottom

        text: shiftMil.toFixed(1) + " mm"
        color: "white"

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignBottom
        style: Text.Outline
        styleColor: "black"
        font.family: constants.menuItemFontName
        font.pixelSize: itemTextSize
    }

    Text {
        id: tiltLeft
        anchors.top: shiftLeft.bottom
        anchors.topMargin: marginBetweenRows
        anchors.right: horizontalRuler.left

        text: qsTranslate("HTS", "Tilt") + ":"
        color: "white"

        style: Text.Outline
        styleColor: "black"
        font.family: constants.menuItemFontName
        font.pixelSize: itemTextSize
    }

    Text {
        id: tiltRight
        anchors.left: horizontalRuler.right
        anchors.bottom: tiltLeft.bottom

        text: tiltDegrees.toFixed(1) + "°"
        color: "white"

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignBottom
        style: Text.Outline
        styleColor: "black"
        font.family: constants.menuItemFontName
        font.pixelSize: itemTextSize
        fontSizeMode: Text.HorizontalFit
    }

    Text {
        id: rotLeft
        anchors.top: tiltLeft.bottom
        anchors.topMargin: marginBetweenRows
        anchors.right: horizontalRuler.left

        text: " " + qsTranslate("HTS", "Rotation") + ":"
        color: "white"

        horizontalAlignment: Text.AlignRight
        style: Text.Outline
        styleColor: "black"
        font.family: constants.menuItemFontName
        font.pixelSize: itemTextSize
        fontSizeMode: Text.HorizontalFit
    }

    Text {
        id: rotRight
        anchors.left: horizontalRuler.right
        anchors.bottom: rotLeft.bottom

        text: rotDegrees.toFixed(0) + "°"
        color: "white"

        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignBottom
        style: Text.Outline
        styleColor: "black"
        font.family: constants.menuItemFontName
        font.pixelSize: itemTextSize
        fontSizeMode: Text.HorizontalFit
    }

    states: [
        State {
            name: "HTSattachedNoPoll"
            when: hts_attached && !cambody.current_hts_polling
            PropertyChanges { target: shiftRight; text: "--"}
            PropertyChanges { target: tiltRight; text: "--"}
            PropertyChanges { target: rotRight; text: "--"}
            StateChangeScript {
                script: setHTS()
            }
        },
        State {
            name: "HTSdefualtValues"
            when: cambody.hts_shift < -1000 || cambody.hts_tilt < -1000 || cambody.hts_rotation < -1000
            PropertyChanges { target: shiftRight; text: "--"}
            PropertyChanges { target: tiltRight; text: "--"}
            PropertyChanges { target: rotRight; text: "--"}
        },
        State {
            name: "HTSattached"
            when: hts_attached
            PropertyChanges {
                target: root
                shiftMil: cambody.hts_shift / 10
                tiltDegrees: cambody.hts_tilt / 10
                rotDegrees: cambody.hts_rotation / 10
            }
        },
        State {
            name: "HTSdisconnected"
            when: !hts_attached
            PropertyChanges { target: shiftRight; text: "--"}
            PropertyChanges { target: tiltRight; text: "--"}
            PropertyChanges { target: rotRight; text: "--"}
        }
    ]

    function setHTS()
    {
        cambody.setHtsPolling(visible && cambody.hts_attached)
    }

    onVisibleChanged: {
        setHTS()

        if(visible)
            forceActiveFocus()
    }

    Component.onCompleted: {
        if(typeof hideStatusIcons !== "undefined")
        {
            hideStatusIcons = true
        }
    }
    Component.onDestruction: {
        if(typeof hideStatusIcons !== "undefined")
        {
            hideStatusIcons = false
        }
    }
}
