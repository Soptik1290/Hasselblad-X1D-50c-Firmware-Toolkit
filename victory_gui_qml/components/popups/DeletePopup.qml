import QtQuick 2.0
import com.hasselblad.storage 1.0
import "qrc:///components"
ConfirmOverlay {
    id: root
    objectName: "DeletePopup_root"
    headerText: qsTr("DELETE")
    displayText: qsTr("Delete this image?")
    confirmButtonText: qsTr("Delete")
    property alias deleteText: root.displayText
    onExitSelected: exitDialog()
    onConfirmSelected: deleteFile()
    function exitDialog()
    {
        parent.deleteFile = false
        parent.active = false
    }
    function deleteFile()
    {
        parent.deleteFile = true
        parent.active = false
    }
    Connections{
        target: SortedContentModel
        onListSizeChanged: exitDialog()
    }
}
