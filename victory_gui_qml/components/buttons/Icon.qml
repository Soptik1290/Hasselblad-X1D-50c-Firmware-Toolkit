import QtQuick 2.0
FramedItem {
    id: imageContainer
    property alias source: image.source
    property bool scaleIcon : false
    content: Image {
        id: image
        anchors.centerIn: parent
        fillMode: Image.PreserveAspectFit
        width: scaleIcon ? imageContainer.width -10 : undefined
        height: scaleIcon ? imageContainer.height -10 : undefined
    }
}
