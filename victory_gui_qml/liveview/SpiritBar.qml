import QtQuick 2.0

Item {
    id: root
    property real sizeFactor: 1
    property real degrees: 0

    Canvas {
        id: axis
        anchors.fill: parent
        onPaint: {
            var ctx = getContext('2d')
            var borderWidth = Math.max(constants.spiritBorderWidth * sizeFactor, constants.spiritBorderWidth)
            var lineWidth = Math.max(constants.spiritLineWidth * sizeFactor, constants.spiritLineWidth) + borderWidth
            ctx.save()
            ctx.clearRect(0, 0, width, height)
            ctx.lineWidth = borderWidth
            var styleWhite = Qt.rgba(1, 1, 1, 1)
            var styleBlack = Qt.rgba(0, 0, 0, 1)
            ctx.beginPath()
            ctx.strokeStyle = styleBlack
            ctx.fillStyle = styleWhite
            // Y Axis Top
            ctx.beginPath()
            ctx.moveTo(width / 2 - lineWidth / 2, lineWidth / 2)
            var outerRadius = width / 2 - borderWidth
            // Arc
            var l = lineWidth / 2
            var aSinVal = Math.asin(l / outerRadius)
            var startAngleLeft = -aSinVal - Math.PI / 2
            var endAngleLeft = - startAngleLeft
            ctx.arc(width / 2, height / 2, outerRadius, startAngleLeft, endAngleLeft, true) // Math.PI * 1 / 3
            ctx.lineTo(width / 2 - lineWidth / 2, height - lineWidth / 2)
            ctx.lineTo(width / 2 + lineWidth / 2, height - lineWidth / 2)
            var endAngleRight = aSinVal - Math.PI / 2
            var startAngleRight = - endAngleRight
            ctx.arc(width / 2, height / 2, outerRadius, startAngleRight, endAngleRight, true) // Math.PI * 1 / 3
            ctx.lineTo(width / 2 + lineWidth / 2, lineWidth / 2)
            ctx.closePath()
            ctx.stroke()
            ctx.fill()

            ctx.beginPath()
            var innerRadius = width / 2 - borderWidth - lineWidth
            ctx.moveTo(width / 2 + innerRadius, height / 2)
            ctx.arc(width / 2, height / 2, innerRadius, 0, 2 * Math.PI) // Math.PI * 1 / 3
            ctx.closePath()
            ctx.stroke()
            ctx.globalCompositeOperation = "source-out"
            ctx.fill()

            ctx.restore()
        }
        onVisibleChanged: if(visible) requestPaint()

    }

    Rectangle {
        id: yMarker
        anchors.centerIn: root
        anchors.verticalCenterOffset: Math.max(-1, Math.min(1, -degrees / constants.spiritBarMaxDegrees)) * (root.height / 2)
        width: axis.width - 2 * (constants.spiritBorderWidth + constants.spiritLineWidth + constants.spiritMarkerAxisDist) * sizeFactor
        height: width
        color: Math.abs(degrees) > constants.spiritBarMaxGoodDegrees ? "white" : constants.spiritMarkerColor
        radius: width / 2
        border.color: "black"
        border.width: constants.spiritMarkerBorderWidth * sizeFactor
    }

}

