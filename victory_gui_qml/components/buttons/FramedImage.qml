import QtQuick 2.0
FramedItem {
    property alias source: imageItem.source
    width: imageItem.width * 2
    content: Image {
        id: imageItem
        anchors.centerIn: parent
        source: source
    }
}
