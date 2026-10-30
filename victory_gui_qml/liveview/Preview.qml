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
        /*
        else if(MKeys.pressedFnAcc("SQUARE", event))
        {
            meta_data_overlay.setPrevOverlay()
        }
        else if(MKeys.pressedFnAcc("CROSS", event))
        {
            meta_data_overlay.setNextOverlay()
        }
        */

    }
/*
    MetaDataOverlay {
        id: meta_data_overlay
        anchors.fill: parent

        histogramData: 1
        metaIso: "gurka"
        metaDateTime: "gurka"
        metaImgName: "gurka"
        metaEvAdjust: 0.0
        metaLightMeterMode: 0
        metaWhiteBalanceMode: 0
        metaExposureMode: 0
        metaAV: "gurka"
        metaTV: "gurka"
        metaFocalLength: 100
        metaExposureStatus: "gurka"
        metaVolumeType: ContentModel.browseVolume
    }
    */

}

