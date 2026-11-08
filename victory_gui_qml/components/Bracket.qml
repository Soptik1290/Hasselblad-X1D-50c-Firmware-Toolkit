import QtQuick 2.0

Item {

    property int borderWidth: 1
    property int lineWidth: 1
    property bool leftBracket: true

    Canvas {
        width: parent.width
        height: parent.height

        onPaint: {
            var ctx = getContext('2d')
            ctx.save()
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = borderWidth + 0.5
            var styleWhite = Qt.rgba(1, 1, 1, 1)
            var styleBlack = Qt.rgba(0, 0, 0, 1)
            ctx.beginPath()
            ctx.strokeStyle = styleBlack
            ctx.fillStyle = styleWhite
            ctx.moveTo(borderWidth, borderWidth)

            if (leftBracket) {
                ctx.lineTo(borderWidth, height - borderWidth)
                ctx.lineTo(width - borderWidth, height - borderWidth)
                ctx.lineTo(width - borderWidth, height - lineWidth)
                ctx.lineTo(lineWidth, height - lineWidth)
                ctx.lineTo(lineWidth, lineWidth)
                ctx.lineTo(width - borderWidth, lineWidth)
                ctx.lineTo(width - borderWidth, borderWidth)
            }
            else {
                ctx.lineTo(width - borderWidth, borderWidth)
                ctx.lineTo(width - borderWidth, height - borderWidth)
                ctx.lineTo(borderWidth, height - borderWidth)
                ctx.lineTo(borderWidth, height - lineWidth)
                ctx.lineTo(width - lineWidth, height - lineWidth)
                ctx.lineTo(width - lineWidth, lineWidth)
                ctx.lineTo(borderWidth, lineWidth)
            }

            ctx.closePath()
            ctx.stroke()
            ctx.fill()
            ctx.restore()
        }
        onVisibleChanged: if(visible) requestPaint()
    }
}
