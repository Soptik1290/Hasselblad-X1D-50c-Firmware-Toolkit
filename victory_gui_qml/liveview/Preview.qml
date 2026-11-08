import QtQuick 2.0
import com.hasselblad.storage 1.0
import com.hasselblad.camera 1.0
import "qrc:///scripts/Keys.js" as MKeys
Photo {
    id: root
    property bool previewActive: false
    focus: true
    fillMode: Image.PreserveAspectFit
    Connections {
        target: ContentModel
        onImageAdded: {
            previewActive = true
            root.source = ContentModel.getAddedImageName()
        }
    }
    Keys.onPressed: {
        event.accepted = false
        if(MKeys.pressedFn("HALFPRESS", event.key) && !Camera.inSession)
        {
            previewActive = false
        }
    }
}
