import QtQuick 2.0
import com.hasselblad.config 1.0
//import com.hasselblad.prodinfo 1.0

Item {
    id: root
    property real cropx: 0
    property real cropy: 0
    property string color: "black"
    property bool fixedMode: false
    property alias cropWidth: cropLeft.width
    property alias cropHeight: cropTop.height
    opacity: configstore.crop_mode_opacity/100

    Rectangle {
        id: cropLeft
        color: root.color
        anchors {
            left: parent.left
            top: parent.top
            topMargin: cropTop.height
            bottom: parent.bottom
            bottomMargin: cropBottom.height
        }
        width: parent.width*cropx
    }
    Rectangle {
        id: cropRight
        color: root.color
        anchors {
            right: parent.right
            top: parent.top
            topMargin: cropTop.height
            bottom: parent.bottom
            bottomMargin: cropBottom.height
        }
        width: parent.width*cropx
    }
    Rectangle {
        id: cropTop
        color: root.color
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: parent.height*cropy
    }
    Rectangle {
        id: cropBottom
        color: root.color
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: parent.height*cropy
    }

    function calcCropping(aspectRatio) {
        switch(aspectRatio) {
        case Config.Ratio1to1:
            cropy = 0
            cropx = (width-height)/(2*width)
            break
        case Config.Ratio7to6:
            cropy = 0
            cropx = (width-height*7/6)/(2*width)
            break
        case Config.Ratio5to4:
            cropy = 0
            cropx = (width-height*5/4)/(2*width)
            break
        case Config.Ratio11to8p5:
            cropy = 0
            cropx = (width-height*22/17)/(2*width)
            break
        case Config.RatioNoCrop:
            cropy = 0
            cropx = 0
            break
        case Config.Ratio297to210:
            cropy = (height-width*210/297)/(2*height)
            cropx = 0
            break
        case Config.Ratio3to2:
            cropy = (height-width*2/3)/(2*height)
            cropx = 0
            break
        case Config.Ratio3to2Crop:
            cropy = (height - 24*height/prodinfo.sensorHeight())/(2*height)
            cropx = (width - 36*width/prodinfo.sensorWidth())/(2*width)
            break
        case Config.Ratio16to9:
            cropy = (height-width*9/16)/(2*height)
            cropx = 0
            break
        case Config.Ratio2to1:
            cropy = (height-width*1/2)/(2*height)
            cropx = 0
            break
        case Config.Ratio65to24:
            cropy = (height-width*24/65)/(2*height)
            cropx = 0
            break
        default:
            console.log("Error: unimplemented aspect ratio", aspectRatio)
            break
        }
    }

    Connections {
        target: configstore
        onAspectRatioChanged: {
            if (root.visible && !fixedMode) {
                calcCropping(configstore.aspectRatio)
            }
        }
    }
}

