import QtQuick 2.0
import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0
import com.hasselblad.sound 1.0
Item {
    id: af_item
    property real afPointWidth: Camera.firstComponent(Camera.focus_size) * width
    property real afPointHeight: Camera.secondComponent(Camera.focus_size) * height
    property real afWidth: Camera.firstComponent(Camera.focus_size)
    property real afHeight: Camera.secondComponent(Camera.focus_size)
    property real afX: Camera.firstComponent(Camera.focus_point) * width - afPointWidth / 2
    property real afY: Camera.secondComponent(Camera.focus_point) * height - afPointHeight / 2
    property real sizeFactor: 1
    onVisibleChanged: if(visible) af_symbol.requestPaint()
    Component.onCompleted: af_symbol.requestPaint()
    Canvas {
        id: af_symbol
        property string symbol: "idle"
        property color innerCol: "pink"
        property color borderCol: "white"
        readonly property real crossFactor: 0.21
        width: Camera.firstComponent(Camera.focus_size) * af_item.width
        height: Camera.secondComponent(Camera.focus_size) * af_item.height
        x: Camera.firstComponent(Camera.focus_point) * af_item.width - width / 2
        y: Camera.secondComponent(Camera.focus_point) * af_item.height - height / 2
        onPaint: {
            var ctx = getContext('2d')
            ctx.save()
            ctx.clearRect(0, 0, width + 1, height + 1)
            var lineWidth
            if("idle" === symbol || "busy" === symbol || "fail" === symbol)
            {
                lineWidth = 1
                var xStart = Math.round(lineWidth / 2)
                var yStart = Math.round(lineWidth / 2)
                var xEnd = Math.round(width - lineWidth / 2)
                var yEnd = Math.round(height - lineWidth / 2)
                var bracketLength = Math.round(width * crossFactor)
                var bracketWidth = Math.round(4 * sizeFactor)
                ctx.strokeStyle = borderCol
                ctx.fillStyle = innerCol
                ctx.lineWidth = lineWidth + 0.5
                ctx.beginPath()
                ctx.moveTo(xStart, yStart)
                ctx.lineTo(xStart + bracketLength, yStart)
                ctx.lineTo(xStart + bracketLength, yStart + bracketWidth)
                ctx.lineTo(xStart + bracketWidth, yStart + bracketWidth)
                ctx.lineTo(xStart + bracketWidth, yStart + bracketLength)
                ctx.lineTo(xStart, yStart + bracketLength)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(xEnd, yStart)
                ctx.lineTo(xEnd - bracketLength, yStart)
                ctx.lineTo(xEnd - bracketLength, yStart + bracketWidth)
                ctx.lineTo(xEnd - bracketWidth, yStart + bracketWidth)
                ctx.lineTo(xEnd - bracketWidth, yStart + bracketLength)
                ctx.lineTo(xEnd, yStart + bracketLength)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(xStart, yEnd)
                ctx.lineTo(xStart, yEnd - bracketLength)
                ctx.lineTo(xStart + bracketWidth, yEnd - bracketLength)
                ctx.lineTo(xStart + bracketWidth, yEnd - bracketWidth)
                ctx.lineTo(xStart + bracketLength, yEnd - bracketWidth)
                ctx.lineTo(xStart + bracketLength, yEnd)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(xEnd, yEnd)
                ctx.lineTo(xEnd, yEnd - bracketLength)
                ctx.lineTo(xEnd - bracketWidth, yEnd - bracketLength)
                ctx.lineTo(xEnd - bracketWidth, yEnd - bracketWidth)
                ctx.lineTo(xEnd - bracketLength, yEnd - bracketWidth)
                ctx.lineTo(xEnd - bracketLength, yEnd)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
            }
            else if ("success" === symbol)
            {
                ctx.fillStyle = innerCol
                var crossW = 2
                var crossCut = 6
                lineWidth = 4
                ctx.lineWidth = lineWidth
                xStart = Math.round(lineWidth / 2)
                yStart = Math.round(lineWidth / 2)
                xEnd = Math.round(width - lineWidth / 2)
                yEnd = Math.round(height - lineWidth / 2)
                var rWidth = xEnd - xStart
                var rHeight = yEnd - yStart
                ctx.strokeStyle = borderCol
                ctx.strokeRect(xStart, yStart, rWidth, rHeight)
                ctx.strokeStyle = innerCol
                ctx.lineWidth = lineWidth / 2
                ctx.strokeRect(xStart, yStart, rWidth, rHeight)
            }
            ctx.restore()
        }
    }
    Connections {
        target: Camera
        onFocus_pointChanged: {
            af_item.afX = Camera.firstComponent(Camera.focus_point)
            af_item.afY = Camera.secondComponent(Camera.focus_point)
            af_symbol.requestPaint()
        }
        onFocus_sizeChanged: {
            af_item.afWidth = Camera.firstComponent(Camera.focus_size)
            af_item.afHeight = Camera.secondComponent(Camera.focus_size)
            af_symbol.requestPaint()
        }
   }
    state: "idle"
    states: [
        State {
            name: "ongoing"
            when: Camera.findOngoing && Camera.lastAfResult !== Camera.LastAfResultOverride
            PropertyChanges {
                target: af_symbol
                innerCol: "white"
                borderCol: "black"
                symbol: "busy"
            }
            StateChangeScript {
                script: af_symbol.requestPaint()
            }
        },
        State {
            name: "idle"
            when: (!Camera.inSession && !Camera.findOngoing) || (!Camera.findOngoing && Camera.lastAfResult === Camera.LastAfResultOverride)
            PropertyChanges {
                target: af_symbol
                innerCol: "black"
                borderCol: "white"
                symbol: "idle"
            }
            StateChangeScript {
                script: af_symbol.requestPaint()
            }
        },
        State {
            name: "focusfailed"
            when: Camera.inSession && !Camera.findOngoing &&
                  (Camera.lastAfResult === Camera.LastAfResultNotFound || Camera.lastAfResult === Camera.LastAfResultJammed || Camera.lastAfResult === Camera.LastAfResultError)
                  && Camera.lastAfReturnStatus !== Camera.LastAfReturnStatusCanceled
            PropertyChanges {
                target: af_symbol
                innerCol: "red"
                borderCol: "black"
                symbol: "fail"
            }
            StateChangeScript {
                script: {
                    af_symbol.requestPaint()
                    if (configstore.afSucceededSound) {
                        SoundControl.play(SoundControl.SndAfFocusNotFound)
                    }
                }
            }
        },
        State {
            name: "hasfocus"
            when: Camera.inSession && !Camera.findOngoing &&
                  Camera.lastAfResult === Camera.LastAfResultFound
            PropertyChanges {
                target: af_symbol
                innerCol: "#39b54a"
                borderCol: "black"
                symbol: "success"
            }
            StateChangeScript {
                script: {
                    af_symbol.requestPaint()
                    if (configstore.afSucceededSound) {
                        SoundControl.play(SoundControl.SndAfFocusFound)
                    }
                }
            }
        }
    ]
}
