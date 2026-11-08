import QtQuick 2.0

Item {
    id: grid
    property int gridSizeHorizontal : width / constants.liveViewGridCount
    property int gridSizeVertical : height / constants.liveViewGridCount
    property int gridCountVertical: constants.liveViewGridCount
    property int gridCountHorizontal: constants.liveViewGridCount
    property int internalBottomMargin: 0
    property bool fadeTopBottom: false

    Gradient {
        id: topBottomGradientBlack
        GradientStop { position: 0.0; color : "transparent" }
        GradientStop { position: 0.3; color: "black" }
        GradientStop { position: 0.7; color: "black" }
        GradientStop { position: 1.0; color: "transparent" }
    }
    Gradient {
        id: topBottomGradientGridColor
        GradientStop { position: 0.0; color : "transparent" }
        GradientStop { position: 0.3; color: constants.liveViewGridColor }
        GradientStop { position: 0.7; color: constants.liveViewGridColor }
        GradientStop { position: 1.0; color: "transparent" }
    }

    property string verticalLine: "import QtQuick 2.0;
            Rectangle {
            width: constants.liveViewGridLineWidth
            color: constants.liveViewGridColor
            gradient: fadeTopBottom ? topBottomGradientGridColor : null
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: grid.internalBottomMargin
            property int index
            x: parent.gridSizeHorizontal * index - width / 2
        }"
    property string verticalLineLeft: "import QtQuick 2.0;
            Rectangle {
            width: 1
            color: \"black\"
            gradient: fadeTopBottom ? topBottomGradientBlack : null
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: grid.internalBottomMargin
            property int index
            x: parent.gridSizeHorizontal * index - width / 2 - constants.liveViewGridLineWidth / 2
        }"
    property string verticalLineRight: "import QtQuick 2.0;
            Rectangle {
            width: 1
            color: \"black\"
            gradient: fadeTopBottom ? topBottomGradientBlack : null
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: grid.internalBottomMargin
            property int index
            x: parent.gridSizeHorizontal * index - width / 2 + constants.liveViewGridLineWidth / 2
        }"
    property string horizontalLine: "import QtQuick 2.0;
            Rectangle {
            height: constants.liveViewGridLineWidth
            color: constants.liveViewGridColor
            anchors.left: parent.left
            anchors.right: parent.right
            property int index
            y: parent.gridSizeVertical * index - height / 2
        }"
    property string horizontalLineTop: "import QtQuick 2.0;
            Rectangle {
            height: 1
            color: \"black\"
            anchors.left: parent.left
            anchors.right: parent.right
            property int index
            y: parent.gridSizeVertical * index - height / 2 - constants.liveViewGridLineWidth / 2
        }"
    property string horizontalLineBottom: "import QtQuick 2.0;
            Rectangle {
            height: 1
            color: \"black\"
            anchors.left: parent.left
            anchors.right: parent.right
            property int index
            y: parent.gridSizeVertical * index - height / 2 + constants.liveViewGridLineWidth / 2
        }"
    Component.onCompleted: {
        for (var iTickVert = 1; iTickVert < gridCountVertical; ++iTickVert){
            var tickVert = Qt.createQmlObject(verticalLine, grid, 'tickVert' + iTickVert);
            var tickVertLeft = Qt.createQmlObject(verticalLineLeft, grid, 'tickVertLeft' + iTickVert);
            var tickVertRight = Qt.createQmlObject(verticalLineRight, grid, 'tickVertRight' + iTickVert);
            tickVert.index = iTickVert
            tickVertLeft.index = iTickVert
            tickVertRight.index = iTickVert
        }
        for (var iTickHorz = 1; iTickHorz < gridCountHorizontal; ++iTickHorz){
            var tickHorz = Qt.createQmlObject(horizontalLine, grid, 'tickHorz' + iTickHorz);
            var tickHorzTop = Qt.createQmlObject(horizontalLineTop, grid, 'tickHorzTop' + iTickHorz);
            var tickHorzBottom = Qt.createQmlObject(horizontalLineBottom, grid, 'tickHorzBottom' + iTickHorz);
            tickHorz.index = iTickHorz
            tickHorzTop.index = iTickHorz
            tickHorzBottom.index = iTickHorz
        }
    }
}

