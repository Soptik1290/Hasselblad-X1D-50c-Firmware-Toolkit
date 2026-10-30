import QtQuick 2.0

Item {
    id: root
    property real sizeFactor: 1
    property real evValue: cambody.balanceScaleReal
    property real ticksTotal: 11
    property real ticksVisible: 5
    property real lineThickness: 5
    property real dist: 54 * sizeFactor
    width: dist * 4 + (5 * sizeFactor + 1 * sizeFactor * 2) + 1
    property real evValueLimitThreshold: 11 / 3 // This is '3 2/3'
    property bool validScale: cambody.BalanceScale !== cambody.invalidBalanceScaleCode

    Component.onCompleted: canvas.requestPaint()

    // Arrow in the middle
    Text {
        id: evadjText
        text: (evValue > 0 ? "+" : "") + evValue.toFixed(1)
        anchors {
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: {
                if(evValue < -2)
                {
                    var newOffset = dist * 2
                    if(newOffset > (root.width / 2 - evadjArrowLeft.width))
                    {
                        return -(root.width / 2 - evadjArrowLeft.width)
                    }
                    else
                    {
                        return -newOffset
                    }
                }
                else if(evValue < 2)
                {
                    return dist * evValue
                }
                else
                {
                    return dist * 2
                }
            }
            bottom: evadjArrow.top
            bottomMargin: -5 * sizeFactor
        }
        font {
          family: constants.cameraControlTextFontName
          pixelSize: constants.itemTextSize * sizeFactor
        }
        color: constants.cameraViewNormalTextColor
        style: Text.Outline
        styleColor: "black"
    }

    Canvas {
        id: evadjArrow
        anchors.horizontalCenter: evadjText.horizontalCenter
        anchors.bottom: canvas.top
        anchors.bottomMargin: 1 * sizeFactor
        visible: Math.abs(evValue) < evValueLimitThreshold.toFixed(1)
        height: 26 * sizeFactor
        width: 34 * sizeFactor
//        height: 13 * sizeFactor
//        width: 17 * sizeFactor
        antialiasing: true
        onVisibleChanged: if(visible) requestPaint()

        onPaint:{
            var ctx = getContext('2d')
            ctx.save()
            ctx.clearRect(0, 0, width, height)
            var lineWidth = Math.round(Math.max(1 * sizeFactor, 1))
            ctx.lineWidth = lineWidth + 0.5
            var styleWhite = Qt.rgba(1, 1, 1, 1)
            var styleBlack = Qt.rgba(0, 0, 0, 1)
            ctx.beginPath()
            ctx.strokeStyle = styleBlack
            ctx.fillStyle = styleWhite
            ctx.moveTo(lineWidth, lineWidth)
            ctx.lineTo(width - lineWidth, lineWidth)
            ctx.lineTo(Math.round(width / 2), height - lineWidth)
            ctx.closePath()
            ctx.stroke()
            ctx.fill()
            ctx.restore()
        }

    }
    /*
    Image {
        id: evadjArrow
        source: "qrc:///icons/EVF_EVAdjArrow.png"
        anchors.horizontalCenter: evadjText.horizontalCenter
        anchors.bottom: canvas.top
        anchors.bottomMargin: 1 * sizeFactor
        visible: Math.abs(evValue) < evValueLimitThreshold.toFixed(1)
    }
*/
    Canvas {
        id: evadjArrowLeft
        anchors.verticalCenter: evadjText.verticalCenter
        anchors.verticalCenterOffset: (evadjText.baselineOffset - evadjText.height) / 2
        anchors.right: evadjText.left
        anchors.rightMargin: 3 * sizeFactor
        visible: evValue < -evValueLimitThreshold.toFixed(1)
        height: evadjArrow.width
        width: evadjArrow.height
        antialiasing: true
        onVisibleChanged: if(visible) requestPaint()

        onPaint:{
            var ctx = getContext('2d')
            ctx.save()
            ctx.clearRect(0, 0, width, height)
            var lineWidth = Math.round(Math.max(1 * sizeFactor, 1))
            ctx.lineWidth = lineWidth + 0.5
            var styleWhite = Qt.rgba(1, 1, 1, 1)
            var styleBlack = Qt.rgba(0, 0, 0, 1)
            ctx.beginPath()
            ctx.strokeStyle = styleBlack
            ctx.fillStyle = styleWhite
            ctx.moveTo(width - lineWidth, lineWidth)
            ctx.lineTo(width - lineWidth, height - lineWidth)
            ctx.lineTo(lineWidth, Math.round(height / 2))
            ctx.closePath()
            ctx.stroke()
            ctx.fill()
            ctx.restore()
        }

    }

/*
    Image {
        id: evadjArrowLeft_org
        source: "qrc:///icons/EVF_EVAdjArrowLeft.png"
        anchors.verticalCenter: evadjText.verticalCenter
        anchors.right: evadjText.left
        anchors.rightMargin: 10 * sizeFactor -30
        visible: evValue < -evValueLimitThreshold.toFixed(1)
    }
*/

    Canvas {
        id: evadjArrowRight
        anchors.verticalCenter: evadjText.verticalCenter
        anchors.verticalCenterOffset: (evadjText.baselineOffset - evadjText.height) / 2
        anchors.left: evadjText.right
        anchors.leftMargin: evadjArrowLeft.anchors.rightMargin
        visible: evValue > evValueLimitThreshold.toFixed(1)
        height: evadjArrowLeft.height
        width: evadjArrowLeft.width
        antialiasing: true
        onVisibleChanged: if(visible) requestPaint()

        onPaint:{
            var ctx = getContext('2d')
            ctx.save()
            ctx.clearRect(0, 0, width, height)
            var lineWidth = Math.round(Math.max(1 * sizeFactor, 1))
            ctx.lineWidth = lineWidth + 0.5
            var styleWhite = Qt.rgba(1, 1, 1, 1)
            var styleBlack = Qt.rgba(0, 0, 0, 1)
            ctx.beginPath()
            ctx.strokeStyle = styleBlack
            ctx.fillStyle = styleWhite
            ctx.moveTo(lineWidth, lineWidth)
            ctx.lineTo(width - lineWidth, Math.round(height / 2))
            ctx.lineTo(lineWidth, height - lineWidth)
            ctx.closePath()
            ctx.stroke()
            ctx.fill()
            ctx.restore()
        }

    }
/*
    Image {
        id: evadjArrowRight_org
        source: "qrc:///icons/EVF_EVAdjArrowRight.png"
        anchors.verticalCenter: evadjText.verticalCenter
        anchors.left: evadjText.right
        anchors.leftMargin: evadjArrowLeft.anchors.rightMargin + 30
        visible: evValue > evValueLimitThreshold.toFixed(1)
    }
    */

    Connections{
        target: evadjText
        onTextChanged: canvas.requestPaint()

    }

    Canvas {
        id:canvas
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 36 * sizeFactor
//        antialiasing: false
//        antialiasing: true
        onVisibleChanged: if(visible) requestPaint()

        onPaint:{
            var ctx = canvas.getContext('2d')
            ctx.save()
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = Math.round(1 * sizeFactor) + 0.5
            var styleWhite = Qt.rgba(1, 1, 1, 1)
            var styleBlack = Qt.rgba(0, 0, 0, 1)
            ctx.beginPath()
            ctx.strokeStyle = styleBlack
            ctx.fillStyle = styleWhite
            var iTick = 0;
            var origin = canvas.width / 2;
            var tickDist = dist / 3
            var currentEvVal = Math.min(Math.max(evValue, -evValueLimitThreshold), evValueLimitThreshold)
            if(currentEvVal < -2)
            {
                origin -= (currentEvVal + 2) * dist
            }
            else if(currentEvVal > 2)
            {
                origin -= (currentEvVal - 2) * dist
            }
            var majorTickHeight = 20 * sizeFactor
            var minorTickHeight = 15 * sizeFactor
            var zeroTickHeight = 36 * sizeFactor
            var majorTickWidth = 5 * sizeFactor
            var minorTickWidth = 3 * sizeFactor
            var tickYOffset = 5 * sizeFactor

            for (iTick = -5; iTick <= 5; iTick++)
            {
                var xPosReal = iTick * dist + origin /* - ctx.lineWidth*/ - majorTickWidth / 2
                var xPos = Math.round(xPosReal)
                if(iTick == 0)
                {
                    ctx.rect(xPos, Math.round(ctx.lineWidth), Math.round(majorTickWidth), Math.round(zeroTickHeight - ctx.lineWidth * 2))
                }
                else
                {
                    ctx.rect(xPos, Math.round(ctx.lineWidth + tickYOffset), Math.round(majorTickWidth), Math.round(majorTickHeight - ctx.lineWidth * 2))
                }
                ctx.rect(Math.round(xPosReal + 1 / 3 * dist), Math.round(ctx.lineWidth + tickYOffset), Math.round(minorTickWidth), Math.round(minorTickHeight - ctx.lineWidth * 2))
                ctx.rect(Math.round(xPosReal + 2 / 3 * dist), Math.round(ctx.lineWidth + tickYOffset), Math.round(minorTickWidth), Math.round(minorTickHeight - ctx.lineWidth * 2))
            }
            ctx.stroke()
            ctx.fill()
            ctx.restore()
        }
    }


}

