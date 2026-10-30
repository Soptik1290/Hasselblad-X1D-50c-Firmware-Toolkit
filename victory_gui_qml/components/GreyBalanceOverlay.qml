import QtQuick 2.0
import com.hasselblad.storage 1.0
import com.hasselblad.farm 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.config 1.0

import "qrc:/browseview"
import "qrc:/components/controls"

Item {
    id: root
    property string metaImgName
    property int metaVolumeType
    property bool ramOnly: farm.ram_only_mode === Farm.RamModeRamOnly
    property bool isTethered: System.isTethered

    property string progressDots: ""
    property int greyBalanceTemp: 0xffff
    property int tint: 0xffff

    function volumeSymbol(index)
    {
        // Tethered mode overrides any storage volume.
        if(isTethered)
            return "USB"
        return guiconfig.storageSlotLetter(index)
    }

    Rectangle {
        id: topMeta
        color: "black"
        opacity: constants.metaDataOpacity
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right;
        }
        height: constants.topMetaHeight
    }

    Rectangle {
        id: volumeBack
        color: ramOnly ? "red" : "transparent"
        border.color: "white"
        border.width: 2
        width: ramOnly ? 450 : isTethered ? 60 : 40
        anchors {
            top: topMeta.top
            left: topMeta.left
            bottom: topMeta.bottom
            topMargin: 4
            leftMargin: isTethered ? 4 : constants.metaDataMargins
            bottomMargin: 4
        }
    }

    Text {
        id: cardSymbol
        color: "white"
        visible: volumeBack.visible
        anchors {
            fill: volumeBack
            topMargin: ramOnly && guiconfig.usingUnicodeLanguage ? 0 : constants.metaDataVertOffset + 2
            leftMargin: isTethered ? 6 : 2
            rightMargin: isTethered ? 6 : 2
        }
        // TODO: Here fix the CARD type & slot preferably with an image instead of text.
        text: guiconfig.emptyString + (ramOnly ? qsTr("DEMO - NO STORAGE").toUpperCase() : volumeSymbol(metaVolumeType))
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.Fit
        font.pixelSize: constants.mediaBrowseFontSize
        font.bold: ramOnly && !guiconfig.usingUnicodeLanguage
        font.family: ramOnly && guiconfig.usingUnicodeLanguage ? "DroidSansFallback" : constants.dialogTextFontName
    }

    Text {
        id: imgName
        color: "white"
        visible: !ramOnly
        font.pixelSize: constants.mediaBrowseFontSize
        font.family: constants.metaDataTextFontName
        anchors {
            left: volumeBack.right
            verticalCenter: topMeta.verticalCenter
            verticalCenterOffset: constants.metaDataVertOffset
            leftMargin: isTethered ? 4 : constants.metaDataMargins / 2
            rightMargin: constants.metaDataMargins
        }
        elide: Text.ElideRight
        // TODO: Here fix the CARD type+ slot preferably with an image instead of text.
        text: metaImgName.replace(/\.[^/.]+$/, "") // This regex cuts off the file extension from the picture name!
    }

    Text {
        id: imgGreyBalanceWorking
        visible: progressDots !== ""
        color: "white"
        font.pixelSize: constants.mediaBrowseFontSize
        font.family: constants.metaDataTextFontName
        anchors {
            left: imgName.right
            leftMargin: constants.metaDataMargins
            right: topMeta.right
            verticalCenter: topMeta.verticalCenter
            verticalCenterOffset: constants.metaDataVertOffset
            rightMargin: constants.metaDataMargins
        }
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        text: qsTr("Calculating") + progressDots + guiconfig.emptyString
    }

    Text {
        id: imgGreyBalanceTemp
        visible: progressDots === ""
        color: "white"
        font.pixelSize:  constants.mediaBrowseFontSize
        font.family: constants.metaDataTextFontName
        fontSizeMode: Text.Fit
        horizontalAlignment: Text.AlignRight
        anchors {
            left: imgName.right
            leftMargin: constants.metaDataMargins
            right: topMeta.right
            verticalCenter: topMeta.verticalCenter
            verticalCenterOffset: constants.metaDataVertOffset
            rightMargin: constants.metaDataMargins
        }
        text: qsTr("Temp") + ": " + (greyBalanceTemp === 0xffff ? "-- K   " : (greyBalanceTemp.toString() + "K   ")) +
              qsTr("Tint") + ": " + (tint === 0xffff ? "--" : tint.toString()) + guiconfig.emptyString
    }
}
