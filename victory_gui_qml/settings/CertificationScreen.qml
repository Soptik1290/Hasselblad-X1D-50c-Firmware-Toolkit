import QtQuick 2.0
import "qrc:///scripts/Keys.js" as MKeys

Rectangle {
    objectName: "CertificationScreen_root"
    id: root
    property alias headerBgCol: headerBg.color
    property alias splashBgCol: splashBg.color
    property color splashBorderCol: "black"

    property string headingText: ""
    property string contentText1: ""
    property string contentText2: ""
    property string contentText3: ""
    property string contentText4: ""
    property string image1Source: "qrc:///icons/exclamationMark.png" // A default initial value
    property string image2Source: "qrc:///icons/exclamationMark.png" // A default initial value

    color: constants.menuBackgroundColor

    Rectangle {
        id: headerBg
        color: "black"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: header.bottom
        }
    }

    // Header text
    Text {
        id: header
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: constants.headerVerticalOffset
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
        text: qsTr(headingText) + guiconfig.emptyString
        font.capitalization: Font.AllUppercase
    }

    Rectangle {
        id: splashBg
        color: "white"
        border.color: splashBorderCol
        border.width: constants.splashBorderWidth
        anchors {
            top: headerBg.bottom
            left: headerBg.left
            right: headerBg.right
            bottom: parent.bottom
        }

        Column {
            id: splashContent
            spacing: constants.splashContentSpacing
            anchors {
                left: parent.left
                leftMargin: constants.splashContentLeftMargin
                verticalCenter: parent.verticalCenter
            }

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                horizontalAlignment: Text.AlignLeft
                color: "black"
                text: qsTr(contentText1) + guiconfig.emptyString
                font {
                    family: constants.helveticaFont
                    pixelSize : constants.contentTextSize
                    capitalization: Font.AllUppercase
                }
            }

            Row {
                anchors {
                    left: parent.left
                    //right: parent.right
                }
                spacing: 20

                Text {
                    anchors {
                        verticalCenter: img1.verticalCenter
//                        right: parent.left
//                        rightMargin: 20
                    }
                    horizontalAlignment: Text.AlignLeft
                    color: "black"
                    text: qsTr(contentText2) + guiconfig.emptyString
                    font {
                        family: constants.helveticaFont
                        pixelSize : constants.contentTextSize
                        //capitalization: Font.AllUppercase
                    }
                }

                Image {
                    id: img1
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Image.AlignLeft
                    source: image1Source
                }

                Text {
                    anchors {
                        verticalCenter: img1.verticalCenter
//                        left: parent.left
//                        right: parent.right
                    }
                    horizontalAlignment: Text.AlignLeft
                    color: "black"
                    text: qsTr(contentText3) + guiconfig.emptyString
                    font {
                        family: constants.helveticaFont
                        pixelSize : constants.contentTextSize
                        capitalization: Font.AllUppercase
                    }
                }
            }
            Image {
                id: img2
                horizontalAlignment: Image.AlignLeft
                source: image2Source
            }
            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                horizontalAlignment: Text.AlignLeft
                color: "black"
                text: qsTr(contentText4) + guiconfig.emptyString
                font {
                    family: constants.helveticaFont
                    pixelSize : constants.contentTextSize
                    capitalization: Font.AllUppercase
                }
            }
        }
    }


    MouseArea {
        anchors.fill: parent
        enabled: !certificationView.active

        // We must have this here to be able to drag:
        drag {
            target: root
            axis: Drag.XAxis
            minimumX: 0
            maximumX: root.width
            threshold: constants.dragThreshold
            filterChildren: true
        }
        drag.onActiveChanged: {
            if (!drag.active) {
                // Done dragging
                if (drag.target.x > (root.width / constants.swipeLengthDividor))
                {
                    // Dragged enough to the right. Close the window
                    closeSubDialog()
                }
                root.x = 0
            }
        }
        onClicked: {}
    }

    Rectangle {
        id: viewEndLine
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: constants.viewEndLineWidth
    }




    Loader {
        anchors.fill: parent
        id: certificationView
        active: false
        visible: active
        asynchronous: true
        focus: active
        function closeSubDialog()
        {
            certificationView.active = false
        }
    }

}
