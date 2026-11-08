import QtQuick 2.0
import com.hasselblad.upgrade 1.0

import "qrc:///components"

Rectangle {
    anchors.fill: parent
    id: root
    property alias centerText: center.text
    property alias icon: busyIcon.source
    property alias bottomText: footerText.text
    property int lineWidth: 10
    property alias heading: headingText.text
    property int headingTopMargin: 30
    property int statusTopMargin: 20
    property int footerMargin: 0
    property bool showPercentage: false
    property int progressMargin: 20
    property int percentage: 0
    property real animDelay: 0
    property alias statusText: status.text
    property alias showStatusRow: statusRow.visible

    color: "black"

    StatusRow {
        id: statusRow
        visible: false
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: headingTopMargin
        id: headingText
        color: "white"
        font.pixelSize: constants.popupHeaderTextSize
        font.capitalization: Font.AllUppercase

    }

    Text {
        id: status
        visible: text != ""
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: headingText.bottom
            topMargin: statusTopMargin
        }
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: constants.popupHeaderTextSize
        color: "white"
    }

    Column {
        id: busySymbol
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10 - (status.visible ? 0 : statusTopMargin)
        width: 245
        spacing: 10

        Item {
            width: parent.width
            height: width
            Canvas {
                id: busyMarker
                width: parent.width
                height: width

                onPaint: {
                    var xCenter = width / 2
                    var yCenter = height / 2
                    var outerRadius = width / 2
                    var context = getContext("2d")
                    context.lineWidth = root.lineWidth
                    context.beginPath();
                    var gradient = context.createConicalGradient(xCenter, yCenter, Math.PI / 2);
                    gradient.addColorStop(0, Qt.rgba(1, 1, 1, 1));
                    gradient.addColorStop(1, Qt.rgba(1, 1, 1, 0));
                    context.strokeStyle = gradient;
                    context.arc(xCenter, yCenter, outerRadius - lineWidth, 0, Math.PI * 2, true);
                    context.stroke();

                    //                if(root.showPercentage) {
                    //                    if(0 !== percentage) {
                    //                        context.beginPath();
                    //                        context.fillStyle = constants.hblOrange;
                    //                        context.moveTo(xCenter, yCenter);
                    //                        context.arc(xCenter, yCenter, outerRadius / 2, 0, Math.PI * 2 * root.percentage / 100, false);
                    //                        context.lineTo(xCenter, yCenter);
                    //                        context.fill();
                    //                    }
                    //                    if(100 !== percentage) {
                    //                        context.beginPath();
                    //                        context.fillStyle = "dimgray";
                    //                        context.moveTo(xCenter, yCenter);
                    //                        context.arc(xCenter, yCenter, outerRadius / 2, Math.PI * 2 * root.percentage / 100, Math.PI * 2, false);
                    //                        context.lineTo(xCenter, yCenter);
                    //                        context.fill();
                    //                    }
                    //                }
                }

                transform: Rotation { id: rotation; origin.x: busyMarker.width / 2; origin.y: busyMarker.height / 2}
                PropertyAnimation {
                    target: rotation
                    property: "angle"
                    from: 0
                    to: 360
                    duration: 2000
                    running: true
                    loops: Animation.Infinite
                }
                onVisibleChanged: if(visible) requestPaint()
            }

            /*
            // Use rectangle below to find text size
            Rectangle{
                color: "red"
                opacity: 0.5
                width: 180
                height: 110
                anchors.centerIn: busyMarker
            }
            */
            Text {
                id: center
                width: 180
                height: 110
                //            width: busyMarker.width - root.lineWidth * 2
                anchors.centerIn: busyMarker
                color: "white"
                font.pixelSize: constants.dialogLargeTextSize
                wrapMode: guiconfig.usingUnicodeLanguage ? Text.NoWrap : Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
            }
        }
    }


    Item {
        width: busyIcon.width + footerText.anchors.leftMargin * 2 + footerText.contentWidth
        anchors {
            top: busySymbol.bottom
            topMargin: footerMargin
            horizontalCenter: busySymbol.horizontalCenter
        }

        Image {
            id: busyIcon
        }

        Text {
            id: footerText
            width: root.width - busyIcon.width - anchors.leftMargin * 2
            onWidthChanged: console.log("text width is", width)
            anchors {
                left: busyIcon.right
                leftMargin: 16
                verticalCenter: busyIcon.verticalCenter
                verticalCenterOffset: guiconfig.isLatin(text) ? (implicitHeight - baselineOffset) * 0.4 : 0
            }
            color: "white"
            fontSizeMode: Text.HorizontalFit
            font.pixelSize: constants.dialogLargeTextSize
        }

        ProgressBar {
            id: progress
            width: parent.width
            percentageAnimDelay: percentage === 0 ? 0 : root.animDelay
            height: 25
            anchors {
                top: busyIcon.bottom
                topMargin: progressMargin
                horizontalCenter: parent.horizontalCenter
            }
            visible: root.showPercentage
            progressPercent: root.percentage / 100

        }
    }

    // Prevent closing when clicking outside of popup
    MouseArea {
        z: -1
        anchors.fill: parent
        onClicked: {}
    }
}
