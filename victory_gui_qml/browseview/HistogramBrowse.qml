import QtQuick 2.0
import com.hasselblad.storage 1.0

Item {
    id: root
    // Size should be set by parent

    property var histogramData
    property var exposureStatus
    property bool hideMissingHistogramText: false

    // Newly captured images will have no histogram data until a fraction of a second later,
    // thus to prevent "Histogram Data Missing" to flash for that time, we hide that text for
    // a second. Hopefully it will have a histogram by then
    Component.onCompleted: startHideHistogramTimer()

    function startHideHistogramTimer()
    {
        hideMissingHistogramText = true
        histogramTimer.restart()
    }

    Timer{
        id: histogramTimer
        interval: 1000
        onTriggered: hideMissingHistogramText = false
    }


    onHistogramDataChanged: canvas.requestPaint()

    height: constants.botMetaHeightHistoSimple + constants.botMetaHeightHistoDetails

    Item {
        height: constants.botMetaHeightHistoDetails
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: (exposureStatus === ContentModel.EXPOSURE_OVER) || (exposureStatus === ContentModel.EXPOSURE_UNDER)
        Rectangle{
            color: "black"
            opacity: constants.metaDataOpacity
            anchors.fill: parent
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 5
            anchors.left: parent.left
            anchors.leftMargin: 17
            text:  guiconfig.emptyString + (exposureStatus === ContentModel.EXPOSURE_OVER ? qsTr("High Exposure") : qsTr("Low Exposure"))
            font.pixelSize: 40
            color: "white"
        }
        Rectangle{
            color: "white"
            height: 2
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }
    }

    Item {
        id: histogramItem
        height: constants.botMetaHeightHistoSimple
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        Rectangle{
            color: "black"
            opacity: constants.metaDataOpacity
            anchors.fill: parent
        }


        Canvas {
            id:canvas
            anchors.fill: parent
            antialiasing: true

            onPaint:{
                if (root.histogramData === undefined)
                    return
                if(root.state === "none")
                    return

                var drawWidth = 512
                var startX = (width - drawWidth) / 2

                var ctx = canvas.getContext('2d')
                ctx.save()
                ctx.clearRect(0, 0, width, height)
                ctx.lineWidth = 2
                var styleRed = Qt.rgba(1, 0 , 0 , 1)
                var styleGreen = Qt.rgba(0, 1 , 0 , 1)
                var styleBlue = Qt.rgba(0, 0 , 1 , 1)
                var styleWhite = Qt.rgba(1, 1 , 1 , 1)
                var iData = 0
                var iData2 = 0
                if(root.state === "separate")
                {
                    var heightFactor = canvas.height / (3 * 256)
                    var blueYStart = canvas.height
                    var greenYStart = blueYStart - canvas.height / 3
                    var redYStart = greenYStart - canvas.height / 3
                    ctx.beginPath()
                    ctx.strokeStyle = styleRed
                    for (iData = 0; iData < 256; iData++)
                    {
                        // Red
                        iData2 = iData * 2
                        ctx.moveTo(iData2 + startX, redYStart)
                        ctx.lineTo(iData2 + startX, redYStart - histogramData[iData] * heightFactor)
                    }
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.strokeStyle = styleGreen
                    for (iData = 0; iData < 256; iData++)
                    {
                        iData2 = iData * 2
                        // Green
                        ctx.moveTo(iData2 + startX, greenYStart)
                        ctx.lineTo(iData2 + startX, greenYStart - histogramData[256 + iData] * heightFactor)
                    }
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.strokeStyle = styleBlue

                    for (iData = 0; iData < 256; iData++)
                    {
                        iData2 = iData * 2
                        // Blue
                        ctx.moveTo(iData2 + startX, blueYStart)
                        ctx.lineTo(iData2 + startX, blueYStart - histogramData[512 + iData] * heightFactor)
                    }
                    ctx.stroke()
                }
                else if(root.state === "combined")
                {
                    // We need to normalize so that highest always goes to the top
                    var maxTotalHeight = 0
                    var totalHeight = 0
                    for (iData = 0; iData < 256; iData++)
                    {
                        totalHeight = histogramData[512 + iData] + histogramData[256 + iData] + histogramData[iData]
                        if(totalHeight > maxTotalHeight)
                        {
                            maxTotalHeight = totalHeight
                        }
                    }
                    var heightFactorCombined = canvas.height / maxTotalHeight
                    ctx.beginPath()
                    ctx.strokeStyle = styleBlue
                    var drawToYArray = [];
                    drawToYArray[255] = 0
                    for (iData = 0; iData < 256; iData++)
                    {
                        iData2 = iData * 2
                        // blue at bottom
                        ctx.moveTo(iData2 + startX, canvas.height)
                        drawToYArray[iData] = canvas.height - histogramData[512 + iData] * heightFactorCombined
                        ctx.lineTo(iData2 + startX, drawToYArray[iData])
                    }
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.strokeStyle = styleGreen
                    for (iData = 0; iData < 256; iData++)
                    {
                        iData2 = iData * 2
                        // green in the middle
                        ctx.moveTo(iData2 + startX, drawToYArray[iData])
                        drawToYArray[iData] = drawToYArray[iData] - histogramData[256 + iData] * heightFactorCombined
                        ctx.lineTo(iData2 + startX, drawToYArray[iData])
                    }
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.strokeStyle = styleRed
                    for (iData = 0; iData < 256; iData++)
                    {
                        iData2 = iData * 2
                        // red at the top
                        ctx.moveTo(iData2 + startX, drawToYArray[iData])
                        drawToYArray[iData] = drawToYArray[iData] - histogramData[iData] * heightFactorCombined
                        ctx.lineTo(iData2 + startX, drawToYArray[iData])
                    }
                    ctx.stroke()
                }
                else
                {
                    var heightFactorLuminance = canvas.height / 256
                    ctx.beginPath()
                    ctx.strokeStyle = styleWhite
                    for (iData = 0; iData < 256; iData++)
                    {
                        iData2 = iData * 2
                        // White
                        ctx.moveTo(iData2 + startX, canvas.height)
                        ctx.lineTo(iData2 + startX, canvas.height - histogramData[768 + iData] * heightFactorLuminance)
                    }
                    ctx.stroke()
                }

                // Draw help lines
                ctx.beginPath()
                ctx.lineWidth = 2
                ctx.strokeStyle = styleWhite
                var distBetween = drawWidth / 4
                var distY = canvas.height / 16
                // Three dotted lines
                for(var iLine = 1; iLine <= 3; iLine++)
                {
                    for(var iY = 0; iY < 16; iY++)
                    {
                        ctx.moveTo(distBetween * iLine + startX, distY * iY)
                        ctx.lineTo(distBetween * iLine + startX, distY * iY + distY / 2)
                    }

                }

                // A solid line
                ctx.moveTo(drawWidth + startX, 0)
                ctx.lineTo(drawWidth + startX, canvas.height)

                // A solid line
                ctx.moveTo(startX - ctx.lineWidth, 0)
                ctx.lineTo(startX - ctx.lineWidth, canvas.height)

                ctx.stroke()
                ctx.restore()
            }
            onVisibleChanged: if(visible) requestPaint()
        }

        Text {
            anchors.centerIn: parent
            visible: (root.histogramData === undefined) && !hideMissingHistogramText
            text: qsTr("Histogram Data Missing") + guiconfig.emptyString
            font.pixelSize: 40
            color: "white"
        }
    }

    state: "none"
//    onStateChanged: console.log("Histogram changed state to: ", state)
    states: [
        State {
            name: "combined"
            StateChangeScript { script: {
                    canvas.requestPaint()
                }
            }
        },
        State {
            name: "separate"
            StateChangeScript { script: {
                    canvas.requestPaint()
                }
            }
        },
        State {
            name: "luminance"
            StateChangeScript { script: {
                    canvas.requestPaint()
                }
            }
        },
        State {
            name: "none"
        }
    ]
}
