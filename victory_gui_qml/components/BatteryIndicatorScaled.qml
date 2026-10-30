import QtQuick 2.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.suc 1.0

Row {
    id: root
    property bool showOnWarningOnly: false
    // Distance from the top of the battery to where the indicator max is
    property real topHeight: 1.5*lineWidth
    property real topWidth: (8/23) * batteryImage.width
    property real lineWidth: 3
    readonly property bool isWarning: System.batteryStatus !== System.BatteryNormal
    property bool isOutlined: false
    property bool canShowBattery: true // External way to hide battery indicator
    property bool showBattery: (System.batteryStatus !== System.BatteryAux) &&
                               (System.batteryStatus !== System.BatteryUnknown)
    property bool showCharge: (((suc.usbChargeLevel !== Suc.UsbChargeOff) && showBattery) || suc.ext_power)
    visible: (showBattery || showCharge) &&
             (!showOnWarningOnly || isWarning) &&
             canShowBattery
    property real sizeFactor: 1
    property alias batteryWidth: batteryImage.width
    Connections{
        target: System
        onBatteryLevelChanged: {
            batteryImage.requestPaint()
        }
        onBatteryStatusChanged: {
            batteryImage.requestPaint()
        }
    }
    spacing: 9 * sizeFactor

    Canvas {
        id: usbChargeLevelIndicator
        width: batteryImage.width
        anchors.bottom: batteryImage.bottom
        anchors.top: batteryImage.top
        anchors.topMargin: 3 * sizeFactor
        visible: showCharge

        onPaint: {
            var ctx = getContext('2d')
            var lineWidthOriginal = 1.4
            var lineWidth = Math.max(lineWidthOriginal * sizeFactor, 1)
            var maxWidth = width - 1 - lineWidth * 2
            var maxHeight = height - 1 - lineWidth * 2

            var flash = [[0.6, 0.0],
                         [0.5, 0.4],
                         [1.0, 0.4],
                         [0.4, 1.0],
                         [0.5, 0.5],
                         [0.0, 0.5]]

            ctx.save()
            ctx.clearRect(0, 0, width + 1, height + 1)
            ctx.lineWidth = Math.floor(lineWidth + 0.5)

            var styleWhite = Qt.rgba(1, 1, 1, 1)
            var styleBlack = Qt.rgba(0, 0, 0, 1)
            ctx.strokeStyle = styleWhite
            ctx.fillStyle = styleWhite

            ctx.beginPath()
            var startIndex = 0
            var endIndex = flash.length
            // TODO: Change when we need to distinguish between Low, Mid, High
            if(suc.ext_power)
            {
                startIndex = 0
                endIndex = flash.length
            }
            else
            {
                switch(suc.usbChargeLevel)
                {
                case Suc.UsbChargeLow:
                    startIndex = 0
                    endIndex = flash.length
                    break
                case Suc.UsbChargeMid:
                    startIndex = 0
                    endIndex = flash.length
                    break
                case Suc.UsbChargeHigh:
                    startIndex = 0
                    endIndex = flash.length
                    break
                }
            }
            //The charge symbol
            ctx.moveTo(flash[startIndex][0] * maxWidth + lineWidth, flash[startIndex][1] * maxHeight + lineWidth)
            for(var iFill = startIndex + 1; iFill < endIndex; iFill++)
            {
                ctx.lineTo(flash[iFill][0] * maxWidth + lineWidth, flash[iFill][1] * maxHeight + lineWidth)
            }

            ctx.closePath()
            ctx.fill()
            if (!isOutlined)  {
                ctx.stroke()
            }

            if (isOutlined)  {
                //Borders for charge symbol
                ctx.strokeStyle = styleBlack
                ctx.beginPath()
                ctx.moveTo(flash[0][0] * maxWidth + lineWidth, flash[0][1] * maxHeight + lineWidth)
                for(var i = 1; i < flash.length; i++)
                {
                    ctx.lineTo(flash[i][0] * maxWidth + lineWidth, flash[i][1] * maxHeight + lineWidth)
                }

                ctx.closePath()
                ctx.stroke()
            }

            ctx.restore()

        }
        onVisibleChanged: if(visible) requestPaint()

    }

    Canvas {
        id: batteryImage
        height: parent.height
        visible: showBattery
        onPaint: {
            var ctx = getContext('2d')
            var lineWidth = root.lineWidth
            var borderWidth = Math.floor(lineWidth/2)

            //Body = the 'body' of the battery
            //Top = the 'head' of the battery
            //Level= battery level square inside the body
            //BodyBorder = black border outside the battery body + head
            //InnerBorder = black border inside body above the battery level
            //Note that the bottom line of the 'top' will overlap with top line of the 'body'

            // Top
            var xTop = (width - topWidth)/2
            var yTop = lineWidth/2 + (isOutlined ? borderWidth : 0)

            // Top border
            var topBorderHeight =  topHeight + 2*borderWidth
            var topBorderWidth =  topWidth + lineWidth + borderWidth
            var xTopBorder = (width - topBorderWidth)/2
            var yTopBorder = borderWidth/2

            // Body
            var bodyHeight = height-topHeight-lineWidth - (isOutlined ? 2*borderWidth : 0)
            var bodyWidth = width-lineWidth - (isOutlined ? 2*borderWidth : 0)
            var xBody = lineWidth/2 + (isOutlined ? borderWidth : 0)
            var yBody = yTop + topHeight

            // Body border
            var bodyBorderHeight = height-topHeight-borderWidth
            var bodyBorderWidth = width-borderWidth
            var xBodyBorder = borderWidth/2
            var yBodyBorder = yTop + topHeight - lineWidth/2 - borderWidth/2

            // Level
            //Show as full when near 100% so we always show full battery when inserting a charged battery even if the battery has degraded.
            var batteryLevel = (System.batteryLevel > 90) ? 100 : System.batteryLevel
            var levelMax = bodyHeight - lineWidth //Height when 100% battery level
            var levelHeight = levelMax*batteryLevel/100 + 1 //Add +1 to avoid rounding effects where the topmost pixels inside battery aren't filled at 100% level
            var levelWidth = bodyWidth - lineWidth
            var yEndLevel = yBody + bodyHeight - lineWidth/2
            var xLevel = xBody + lineWidth/2
            var yLevel = yEndLevel - levelHeight

            // Inner border
            var innerBorderHeight = yLevel - (yBody + lineWidth/2) - borderWidth
            var innerBorderWidth = bodyWidth-lineWidth - borderWidth
            var xInnerBorder = xBody + lineWidth/2 + borderWidth/2
            var yInnerBorder = yBody + lineWidth/2 + borderWidth/2

            ctx.save()
            ctx.clearRect(0, 0, width + 1, height + 1)
            var styleRed = Qt.rgba(1, 0, 0, 1)
            var styleWhite = Qt.rgba(1, 1, 1, 1)
            var styleBlack = Qt.rgba(0, 0, 0, 1)
            ctx.lineWidth = lineWidth
            ctx.strokeStyle = styleWhite


            if (isOutlined) {
                ctx.lineWidth = borderWidth
                ctx.strokeStyle = styleBlack
                //Draw top border
                ctx.beginPath()
                ctx.roundedRect(xTopBorder, yTopBorder, topBorderWidth, topBorderHeight, lineWidth/2 + borderWidth, lineWidth/2 + borderWidth)
                ctx.stroke()

                //Draw body border
                ctx.beginPath()
                ctx.rect(xBodyBorder, yBodyBorder, bodyBorderWidth, bodyBorderHeight)
                ctx.stroke()

                //Draw level border
                if (batteryLevel < 100) {
                    ctx.beginPath()
                    ctx.rect(xInnerBorder, yInnerBorder, innerBorderWidth, innerBorderHeight)
                    ctx.stroke()
                }
            }

            //Draw top
            ctx.lineWidth = lineWidth
            ctx.strokeStyle = styleWhite
            ctx.beginPath()
            ctx.roundedRect(xTop, yTop, topWidth, topHeight, lineWidth/2, lineWidth/2)
            ctx.stroke()

            //Draw Body
            ctx.beginPath()
            ctx.rect(xBody, yBody, bodyWidth, bodyHeight)
            ctx.stroke()

            //Draw Level
            ctx.lineWidth = 1
            ctx.fillStyle = isWarning ? styleRed : styleWhite
            ctx.beginPath()
            ctx.rect(xLevel, yLevel, levelWidth, levelHeight)
            ctx.fill()

            ctx.restore()
        }
        onVisibleChanged: if(visible) requestPaint()
    }
}
