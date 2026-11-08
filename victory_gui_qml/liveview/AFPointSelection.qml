import QtQuick 2.0
import com.hasselblad.camera 1.0
import "qrc:///scripts/Keys.js" as MKeys
import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.bodysync 1.0

import "qrc:///common"
import "qrc:/components"

Item {
    id: root
    // The AF point is 4x4 mm on the sensor. The sensor is 44x33 mm. Given that we calculate the size of AF points in this context
    property real afPointWidth: Camera.firstComponent(configstore.focus_size) * width
    property real afPointHeight: Camera.secondComponent(configstore.focus_size) * height
    property real sizeFactor: 1
    readonly property color innerCol: "white"
    readonly property color outerCol: "black"
    readonly property real crossFactor: 0.25
    property bool selectionVisible: false
    readonly property real bracketWidth: 1 * sizeFactor
    readonly property int middleIndex: afc.xCount * afc.yCount / 2

    AFCalc {
        id: afc
        screenWidth: root.width
        screenHeight: root.height
        onXCountChanged: afGrid.requestPaint()
        isActive: true //Started from loader so safe to set to active
        idText: "In AFPointSelection"
    }

    function setSelectedPoint(index)
    {
        GlobalStateInfo.afSselectedIndex = index
        afc.resetSavedIndexes()
        selectionVisible = true
//        console.log("Selected pos (x, y)", index % afc.xCount, Math.floor(index / afc.xCount))
    }

    function selectAndClose()
    {
        afc.selectAndSave()
        closeAFPointSelection()
    }

    signal closeAFPointSelection()

    GlobalConstants {
        id: constants
    }

    Canvas {
        id: afGrid
        anchors.centerIn: parent
        width: afc.afItemWidth * afc.xCount
        height: afc.afItemHeight * afc.yCount
        onPaint: {
            var ctx = getContext('2d')
            ctx.save()
            ctx.translate(0.5, 0.5)
            ctx.clearRect(0, 0, width, height)
            var lineWidth = Math.round(1 * sizeFactor)
            ctx.lineWidth = lineWidth

            ctx.beginPath()
            ctx.strokeStyle = outerCol
            var iX
            var iY
            var xStart
            var yStart
            var xEnd
            var yEnd
            var index
            var xOffset = (afc.afItemWidth - afPointWidth) / 2
            var yOffset = (afc.afItemHeight - afPointHeight) / 2
            var bracketLength = Math.round(afc.afItemWidth * crossFactor)
            for(iX = 0; iX < afc.xCount; iX++)
            {
                for(iY = 0; iY < afc.yCount; iY++)
                {
                    index = iY * afc.xCount + iX
                    xStart = Math.round(iX * afc.afItemWidth + lineWidth / 2 - 0.5 + xOffset)
                    yStart = Math.round(iY * afc.afItemHeight + lineWidth / 2 - 0.5 + yOffset)
                    xEnd = Math.round((iX + 1) * afc.afItemWidth - lineWidth / 2 - 0.5 - xOffset)
                    yEnd = Math.round((iY + 1) * afc.afItemHeight - lineWidth / 2 - 0.5 - yOffset)
                    if(index === middleIndex)
                    {
                        ctx.moveTo(xStart, yStart)
                        ctx.lineTo(xStart, yEnd)
                        ctx.lineTo(xEnd, yEnd)
                        ctx.lineTo(xEnd, yStart)
                        ctx.closePath();
                    }
                    else
                    {
                        ctx.moveTo(xStart + bracketLength, yStart)
                        ctx.lineTo(xStart, yStart)
                        ctx.lineTo(xStart, yStart + bracketLength)
                        ctx.moveTo(xEnd - bracketLength, yStart)
                        ctx.lineTo(xEnd, yStart)
                        ctx.lineTo(xEnd, yStart + bracketLength)
                        ctx.moveTo(xStart + bracketLength, yEnd)
                        ctx.lineTo(xStart, yEnd)
                        ctx.lineTo(xStart, yEnd - bracketLength)
                        ctx.moveTo(xEnd - bracketLength, yEnd)
                        ctx.lineTo(xEnd, yEnd)
                        ctx.lineTo(xEnd, yEnd - bracketLength)
                    }
                }
            }
            ctx.stroke()
            bracketLength = Math.round(bracketLength - lineWidth)

            ctx.beginPath()
            ctx.strokeStyle = innerCol
            ctx.lineWidth = lineWidth

            for(iX = 0; iX < afc.xCount; iX++)
            {
                for(iY = 0; iY < afc.yCount; iY++)
                {
                    index = iY * afc.xCount + iX
                    xStart = Math.round(iX * afc.afItemWidth + lineWidth * 1.5 - 0.5 + xOffset)
                    yStart = Math.round(iY * afc.afItemHeight + lineWidth * 1.5 - 0.5 + yOffset)
                    xEnd = Math.round((iX + 1) * afc.afItemWidth - lineWidth * 1.5 - 0.5 - xOffset)
                    yEnd = Math.round((iY + 1) * afc.afItemHeight - lineWidth * 1.5 - 0.5 - yOffset)
                    if(index === middleIndex)
                    {
                        ctx.moveTo(xStart, yStart)
                        ctx.lineTo(xStart, yEnd)
                        ctx.lineTo(xEnd, yEnd)
                        ctx.lineTo(xEnd, yStart)
                        ctx.closePath();
                    }
                    else
                    {
                        ctx.moveTo(xStart + bracketLength, yStart)
                        ctx.lineTo(xStart, yStart)
                        ctx.lineTo(xStart, yStart + bracketLength)
                        ctx.moveTo(xEnd - bracketLength, yStart)
                        ctx.lineTo(xEnd, yStart)
                        ctx.lineTo(xEnd, yStart + bracketLength)
                        ctx.moveTo(xStart + bracketLength, yEnd)
                        ctx.lineTo(xStart, yEnd)
                        ctx.lineTo(xStart, yEnd - bracketLength)
                        ctx.moveTo(xEnd - bracketLength, yEnd)
                        ctx.lineTo(xEnd, yEnd)
                        ctx.lineTo(xEnd, yEnd - bracketLength)
                    }
                }
            }

            ctx.stroke()
            ctx.restore()
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                // find index of selected point
                var xIndex = Math.floor(mouse.x / afc.afItemWidth)
                var yIndex = Math.floor(mouse.y / afc.afItemHeight)
                var index = xIndex + yIndex * afc.xCount
                setSelectedPoint(index)
            }
        }
    }


    Rectangle {
        x: afGrid.x + afc.afSselectedXIndex * afc.afItemWidth + (afc.afItemWidth - afPointWidth) / 2
        y: afGrid.y + afc.afSselectedYIndex * afc.afItemHeight + (afc.afItemHeight - afPointHeight) / 2
        width: afPointWidth
        height: afPointHeight
        color: "transparent"
        border.color: constants.hblOrange
        border.width: 3 * sizeFactor
    }

    Keys.onPressed: {
        var xIndex = GlobalStateInfo.afSselectedIndex % afc.xCount
        if (event.isAutoRepeat)
        {
            return
        }
        else if(MKeys.pressedFnAcc("LEFT", event))
        {
            if(xIndex > 0)
            {
                GlobalStateInfo.afSselectedIndex--
                afc.resetSavedIndexes()
            }
        }
        else if(MKeys.pressedFnAcc("RIGHT", event))
        {
            if(xIndex < (afc.xCount - 1))
            {
                GlobalStateInfo.afSselectedIndex++
                afc.resetSavedIndexes()
            }
        }
        else if(MKeys.pressedFnAcc("CROSS", event))
        {
            afc.resetPosition()
            afc.resetSavedIndexes()
        }
        else if(MKeys.pressedFnAcc("UP", event))
        {
            if(GlobalStateInfo.afSselectedIndex >= afc.xCount)
            {
                GlobalStateInfo.afSselectedIndex -= afc.xCount
                afc.resetSavedIndexes()
            }
        }
        else if(MKeys.pressedFnAcc("DOWN", event))
        {
            if(GlobalStateInfo.afSselectedIndex < (afc.xCount * (afc.yCount - 1)))
            {
                GlobalStateInfo.afSselectedIndex += afc.xCount
                afc.resetSavedIndexes()
            }
        }
        else if(MKeys.pressedFnAcc("AF_D", event) || MKeys.pressedFnAcc("HALFPRESS", event) || MKeys.pressedFnAcc("STAR", event) || MKeys.pressedFnAcc("AF_MF", event) || MKeys.pressedFnAcc("AFPOINTSEL", event))
        {
            selectAndClose()
        }
        else if(MKeys.pressedFnAcc("AE_L", event))
        {
            GlobalStateInfo.afSselectedIndex = afc.selectedXIndex + afc.selectedYIndex * afc.xCount
            afc.resetSavedIndexes()
            closeAFPointSelection()
        }
        else if(MKeys.pressedFnAcc("SQUARE", event) || MKeys.pressedFnAcc("AFPCYCLE", event))
        {
            afc.setNextSize()
        }
        else if(MKeys.pressedFnAcc("ISO_WB", event))
        {
            // Prevent key strokes to propagate further
        }
    }

    // This caused problems when SQUARE button was hit quickly several times. The signal comes late, and disrupts the sizeIndex
    // in the middle of setNextSize() function resulting in the focus point moving around, and in worst case totally disappear
//    Connections {
//        target: configstore
//        onFocusSizeChanged: {
//            //Update sizeIndex on change instead of direct binding since we sometimes need to override the value
//            updateSizeIndex()
//        }
//    }

    Component.onCompleted: {
        afGrid.requestPaint()
    }

    Connections {
        target: BodySync
        onCurrentDialModeChanged: {
            if (BodySync.currentDialMode === BodySync.DmFullauto) {
                closeAFPointSelection()
            }
        }
    }

}

