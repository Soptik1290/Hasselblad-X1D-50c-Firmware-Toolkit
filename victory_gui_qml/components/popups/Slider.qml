import QtQuick 2.5
import "qrc:///scripts/Keys.js" as MKeys
Rectangle {
    id: sliderWrapper
    objectName: "sliderWrapper"
    color: "transparent"
    property color lineColor: "white"
    property color markerColor: "transparent"
    property real value: 1
    property int iconBorderSize: 6
    property int tickCount: 11
    property real maxValue: 5
    property real minValue: -5
    property alias iconSource: icon.source
    property real realValue: Math.round(((slidingMarker.x - horizontalLine.x + slidingMarker.width / 2 - horizontalLine.width / 2) * (maxValue - minValue) / horizontalLine.width) / stepSize) * stepSize
    property int textEndX: horizontalLine.x + horizontalLine.width + sideMargin - 30 - slidingTextUnit.width
    property int textStartX: horizontalLine.x - sideMargin + 30
    property int lineThickness: constants.sliderThickness
    property int markerSize: 36
    property int zeroMarkerSize: 9
    property real stepSize: 0.5
    property real showValue: valueIsChanged ? realValue : value
    signal changedNewValue(real newValue)
    property int marginTextToMarker: 12
    property int zeroPressHalfSize: 30
    property bool valueIsChanged: false
    property bool changeInProcess: false
    property real latestValue: value
    property real originalValue: 1
    onRealValueChanged: valueIsChanged = true
    Component.onCompleted: valueIsChanged = false
    height: childrenRect.height + 15
    property int sideMargin: (width - (icon.x + icon.width) - 60)/ 10 * (11 - tickCount) / 2 + 30
    function adjustNewValue(newValue)
    {
        newValue = Math.round(newValue / stepSize) * stepSize
        if(newValue < minValue)
        {
            newValue = minValue
        }
        if(newValue > maxValue)
        {
            newValue = maxValue
        }
        changeInProcess = true
        latestValue = newValue
        value = newValue
        changedNewValue(newValue);
    }
    function stepUp()
    {
        adjustNewValue(value + stepSize)
    }
    function stepDown()
    {
        adjustNewValue(value -stepSize)
    }
    Image {
        id: icon
        anchors {
            left: parent.left
            leftMargin: 30
        }
        y: horizontalLine.y + horizontalLine.height / 2 - height / 2
        Rectangle {
            visible: iconZeroArea.containsPress
            anchors.centerIn: parent
            width: parent.width + iconBorderSize
            height: parent.height + iconBorderSize
            color: constants.highlightColor
            z: -1
        }
    }
    Item {
        id: slider
        anchors {
            left: icon.right
            right: parent.right
            leftMargin: sideMargin
            rightMargin: sideMargin
            top: parent.top
            bottom: parent.bottom
        }
        Rectangle {
            id: horizontalLine
            color: lineColor
            height: lineThickness
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: 89
            }
        }
        Rectangle {
            id: zeroMarker
            width: lineThickness;
            height: zeroMarkerSize;
            color: iconZeroArea.containsPress || zeroMarkerMouseArea.containsPress ? constants.highlightColor : lineColor
            anchors.verticalCenter: horizontalLine.verticalCenter
            x: horizontalLine.x - width / 2 + horizontalLine.width / (maxValue - minValue) * (- minValue)
        }
        MouseArea {
            id: zeroMarkerMouseArea
            preventStealing: false
            anchors {
                left: zeroMarker.left
                right: zeroMarker.right
                top: zeroMarker.top
                bottom: zeroMarker.bottom
                bottomMargin: -zeroPressHalfSize
                topMargin: -zeroPressHalfSize
                leftMargin: -zeroPressHalfSize
                rightMargin: -zeroPressHalfSize
            }
            propagateComposedEvents: false
            onPressAndHold: changedNewValue(0)
        }
        Rectangle {
            id: slidingMarker
            anchors.verticalCenter: horizontalLine.verticalCenter
            z: 1
            color: slidingMarkerDragArea.isSliding ? constants.highlightColor : markerColor
            border.width: lineThickness
            border.color: lineColor
            radius: markerSize / 2
            width: markerSize
            height: markerSize
            x: horizontalLine.x - width / 2 + horizontalLine.width / (maxValue - minValue) * (value - minValue)
        }
        MouseArea {
            id: slidingMarkerDragArea
            property bool isSliding: containsPress || drag.active
            preventStealing: true
            propagateComposedEvents: true
            anchors {
                left: slidingMarker.x < slidingText.x ? slidingMarker.left : slidingText.left
                right: slidingMarker.x + slidingMarker.width > slidingTextUnit.x + slidingTextUnit.width ? slidingMarker.right : slidingTextUnit.right
                top: slidingTextUnit.top
                bottom: slidingMarker.bottom
                bottomMargin: -20
                topMargin: -20
            }
            drag {
                target: slidingMarker
                axis: Drag.XAxis
                minimumX: horizontalLine.x - slidingMarker.width / 2
                maximumX: horizontalLine.x + horizontalLine.width - slidingMarker.width / 2
                threshold: horizontalLine.width / ((maxValue - minValue) / stepSize) / 2
            }
            drag.onActiveChanged: if (!drag.active) adjustNewValue(realValue)
        }
        MouseArea {
            id: leftClickArea
            onClicked: adjustNewValue(value - stepSize)
            preventStealing: true
            anchors {
                left: slider.left
                leftMargin: icon.x - slider.x
                right: slidingMarkerDragArea.left
                top: slidingTextUnit.top
                bottom: slidingMarker.bottom
                bottomMargin: -20
                topMargin: -20
            }
            propagateComposedEvents: true
        }
        MouseArea {
            id: rightClickArea
            onClicked: adjustNewValue(value + stepSize)
            preventStealing: true
            anchors {
                left: slidingMarkerDragArea.right
                right: slider.right
                rightMargin: -sideMargin
                top: slidingTextUnit.top
                bottom: slidingMarker.bottom
                bottomMargin: -20
                topMargin: -20
            }
            propagateComposedEvents: true
        }
        Text {
            id: slidingText
            z: 2
            text: (showValue > 0 ? "+" : "") + showValue.toFixed(1)
            anchors {
                right: slidingTextUnit.left
                rightMargin: iconBorderSize
                top: parent.top
                topMargin: 12
            }
            color: "white"
            font {
                family: constants.cameraControlTextFontName
                pixelSize: constants.itemTextSize
                weight: constants.cameraViewFontWeight
            }
            Rectangle {
                visible: false
                anchors {
                    centerIn: parent
                    verticalCenterOffset: -iconBorderSize
                }
                width: parent.width + iconBorderSize
                height: parent.height + iconBorderSize
                color: constants.highlightColor
                z: -1
            }
        }
        Text {
            id: slidingTextUnit
            z: 2
            text: " EV"
            x: {
                var currentX = (slidingMarker.x + slidingMarker.width / 2)
                var currentStartX = (slidingMarker.x + slidingMarker.width / 2) - slidingText.width
                if(currentX > textEndX)
                {
                    return textEndX
                }
                else if(currentStartX < textStartX)
                {
                    return textStartX + slidingText.width
                }
                else
                {
                    return currentX
                }
            }
            color: "white"
            font.pixelSize: constants.itemTextSize
            font.weight: constants.cameraViewFontWeight
            anchors.top: parent.top
            anchors.topMargin: 12
            font.family: constants.cameraControlTextFontName
            Rectangle {
                visible: false
                anchors {
                    centerIn: parent
                    verticalCenterOffset: -iconBorderSize
                }
                width: parent.width + iconBorderSize
                height: parent.height + iconBorderSize
                color: constants.highlightColor
                z: -1
            }
        }
    }
    MouseArea {
        id: iconZeroArea
        width: 50
        height: 60
        anchors.centerIn: icon
        onPressAndHold: if(containsMouse) changedNewValue(0)
        onDoubleClicked: if(containsMouse) changedNewValue(0)
    }
}
