import QtQuick 2.0
import com.hasselblad.config 1.0
import com.hasselblad.storage 1.0
import com.hasselblad.systemmanager 1.0
import "qrc:///scripts/Keys.js" as MKeys // TODO: Fix this import(?)

Text {
    property bool enableHalfPressWarning: false
    readonly property bool isVideoMode: System.camera_mode === System.CameraModeVideo
    id: cardText
    color: "white"
    property int numLines: showBackupMissing && allowTwoLineText ? 2 : 1
    anchors.topMargin: ((font.pixelSize/numLines) - baselineOffset) / 2
    font.pixelSize: 78
    //font.bold: true
    font.family: constants.cameraControlTextFontName
    fontSizeMode: Text.Fit
    horizontalAlignment: Text.AlignHCenter

    property bool showCounter: ContentModel.exposuresLeft > 0 && (System.isTethered || ((ContentModel.card0Status === ContentModel.STORAGE_ACTIVE)
                                                                                    || (ContentModel.card1Status === ContentModel.STORAGE_ACTIVE)
                                                                                    || (ContentModel.card0Status === ContentModel.STORAGE_AVAILABLE)
                                                                                    || (ContentModel.card1Status === ContentModel.STORAGE_AVAILABLE)))
    property bool card0Absent: ContentModel.card0Status === ContentModel.STORAGE_ABSENT
    property bool card1Absent: ContentModel.card1Status === ContentModel.STORAGE_ABSENT
    property bool showBackupMissing: !showCounter && backupMissing
    property bool backupMissing: configstore.storage_mode === Config.StorageBackup && !(card0Absent && card1Absent) && (card0Absent || card1Absent)
    property bool allowTwoLineText: false

//    wrapMode: Text.Wrap
    text: {
        if(showCounter) {

            /* temporarily hide until storage-daemon knows how much additional video time we can record: */
            if(isVideoMode)
                return "-"

            return ContentModel.exposuresLeft
        }

        else if (card0Absent && card1Absent) {
            return qsTr("No Card") + guiconfig.emptyString
        }

        /* "Backup Missing" if not two cards inserted in Backup mode */
        else if (backupMissing) {
            return (allowTwoLineText ? qsTr("Backup<br>Missing") : qsTr("Backup Missing")) + guiconfig.emptyString
        }

        else if (isVideoMode && configstore.Video_Quality === Config.RawVideo && ContentModel.card0Status !== ContentModel.STORAGE_ACTIVE) {
            return qsTr("Missing") + guiconfig.emptyString
        }

        return qsTr("Full") + guiconfig.emptyString
    }

    Timer {
        id: blinkTimer
        property int numBlinksLeft
        interval: 100
        repeat: true
        onTriggered: {
            cardText.opacity = 0 === cardText.opacity ? 100 : 0
            if(0 !== cardText.opacity) {
                if(numBlinksLeft > 0)
                    --numBlinksLeft
                else
                    stop()
            }
        }
    }

    function startBlinking()
    {
        if (!System.isTethered && !isVideoMode && enableHalfPressWarning
                && ((ContentModel.card0Status === ContentModel.STORAGE_ABSENT)
                && (ContentModel.card1Status === ContentModel.STORAGE_ABSENT)
                || ((ContentModel.card0Status === ContentModel.STORAGE_FULL)
                && (ContentModel.card1Status === ContentModel.STORAGE_FULL))
                || ContentModel.exposuresLeft <= 0)) {
            blinkTimer.numBlinksLeft = 2
            blinkTimer.start()
        }
    }
}
