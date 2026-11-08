import QtQuick 2.0
import com.hasselblad.storage 1.0
Rectangle {
    id: root
    property alias text: text_field.text
    property int status
    width: constants.cardStatusIconSize
    height: constants.cardStatusIconSize
    border.color: root.status === ContentModel.STORAGE_ABSENT ?
                    constants.cardStatusAbsentColor :
                  (root.status === ContentModel.STORAGE_ACTIVE) ?
                    constants.cardStatusActiveColor :
                    constants.cardStatusNotActiveBorderColor
    border.width: 2
    color: root.status === ContentModel.STORAGE_ABSENT ?
               constants.cardStatusAbsentColor :
             (root.status === ContentModel.STORAGE_ACTIVE)?
               constants.cardStatusActiveColor :
               constants.cardStatusNotActiveColor
    Text {
        id: text_field
        text: "S"
        color: "white"
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 3
        font.family: constants.cameraControlTextFontName
        font.pixelSize: 24
    }
}
