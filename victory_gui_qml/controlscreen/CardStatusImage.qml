import QtQuick 2.0
import com.hasselblad.storage 1.0
Image {
    property int status
    source: status === ContentModel.STORAGE_ERROR ? "qrc:///icons/CardStatusError.png" :
            status === ContentModel.STORAGE_FULL ? "qrc:///icons/CardStatusFull.png" :
            status === ContentModel.STORAGE_LOCKED ? "qrc:///icons/CardStatusLocked.png" :
                "qrc:///icons/CardStatusOK.png"
}
