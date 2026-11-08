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
    property int nextClickAreaHeight: constants.botMetaHeightSimple
    property int imageRateClickAreaWidth: (configstore.imageRating && state === "detail") ? (starRow.width + constants.metaDataMargins) : 0
    property string metaImgName
    property string metaDateTime
    property string metaIso
    property string metaAV
    property string metaTV
    property bool ramOnly: farm.ram_only_mode === Farm.RamModeRamOnly
    property bool isTethered: System.isTethered
    property int metaFocalLength
    property int metaLightMeterMode
    property int metaWhiteBalanceMode
    property int metaExposureMode
    property real metaEvAdjust
    property int metaVolumeType
    property int metaRating
    property var stateNames: [ "base", "none", "detail", "histCombined", "histSeparate", "histLuminance" ];
    property bool isInstantPreview: false
    property bool showOverlay: true
    state: stateNames[configstore.MetaDataOverlayIndex]
    property alias histogramData: histogram.histogramData
    property alias metaExposureStatus: histogram.exposureStatus
    property bool showInstantAVTV: false
    function hideInstantAVTV()
    {
        showInstantAVTV = false
    }
    function resetOverlay() {
        configstore.MetaDataOverlayIndex = 0
    }
    function setNextOverlay()
    {
        setNextOverlayImpl(configstore.MetaDataOverlayIndex)
    }
    function setNextOverlayImpl(nextIndex)
    {
        nextIndex++
        if (nextIndex >= stateNames.length)
        {
            nextIndex = 0;
        }
        if(isValidOverlay(nextIndex))
        {
            configstore.MetaDataOverlayIndex = nextIndex
        }
        else
        {
            setNextOverlayImpl(nextIndex)
        }
    }
    function setPrevOverlay() {
        setPrevOverlayImpl(configstore.MetaDataOverlayIndex)
    }
    function setPrevOverlayImpl(nextIndex)
    {
        if (0 === nextIndex)
        {
            nextIndex = stateNames.length - 1;
        }
        else
        {
            nextIndex--;
        }
        if(isValidOverlay(nextIndex))
        {
            configstore.MetaDataOverlayIndex = nextIndex
        }
        else
        {
            setPrevOverlayImpl(nextIndex)
        }
    }
    function isValidOverlay(testIndex)
    {
        return true
    }
    Rectangle {
        id: topMeta
        color: "black"
        opacity: constants.metaDataOpacity
        visible: false;
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
        visible: topMeta.visible || ramOnly
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
        visible: topMeta.visible && !ramOnly
        font.pixelSize: constants.mediaBrowseFontSize
        font.family: constants.metaDataTextFontName
        anchors {
            left: volumeBack.right
            right: imgDate.left
            verticalCenter: topMeta.verticalCenter
            verticalCenterOffset: constants.metaDataVertOffset
            leftMargin: isTethered ? 4 : constants.metaDataMargins / 2
            rightMargin: constants.metaDataMargins
        }
        elide: Text.ElideRight
        text: metaImgName.replace(/\.[^/.]+$/, "")
    }
    Text {
        id: imgDate
        visible: topMeta.visible && !ramOnly
        color: "white"
        font.pixelSize:  constants.mediaBrowseFontSize
        font.family: constants.metaDataTextFontName
        anchors {
            right: imgTime.left
            verticalCenter: topMeta.verticalCenter
            verticalCenterOffset: constants.metaDataVertOffset
            leftMargin: constants.metaDataMargins
            rightMargin: 65
        }
        text: metaDateTime.length ? metaDateTime.split('T')[0].slice(2) : ""
    }
    Text {
        id: imgTime
        visible: topMeta.visible
        color: "white"
        font.pixelSize:  constants.mediaBrowseFontSize
        font.family: constants.metaDataTextFontName
        anchors {
            right: topMeta.right
            verticalCenter: topMeta.verticalCenter
            verticalCenterOffset: constants.metaDataVertOffset
            rightMargin: constants.metaDataMargins
        }
        text: metaDateTime.length ? metaDateTime.split('T')[1] : ""
    }
    Rectangle {
        id: bottomMeta
        color: "black"
        opacity: constants.metaDataOpacity
        visible: false;
        anchors {
            left: parent.left
            bottom: parent.bottom
            right: parent.right;
        }
        height: constants.botMetaHeightSimple
    }
    Timer {
        id: avtvTimer
        interval: constants.avtvTimeMs
        running: false
        repeat: false
        onTriggered: hideInstantAVTV()
    }
    function startAvTvShow()
    {
        showInstantAVTV = true
        avtvTimer.restart()
    }
    TextCameraControl {
        id: apertureSetting
        visible: root.isInstantPreview && showInstantAVTV
        allowHighlightBracket: false
        label: cambody.AV_out_of_range ? "" : "f/"
        labelSize: constants.cameraSettingLargeLabelSize
        value: cambody.AV_out_of_range ? "--" : cambody.aperture;
        valueSize: constants.cameraSettingLargeTextSize
        spacing: 13
        outlineText: true
        outlineColor: "white"
        outlineStyleColor: "black"
        anchors.top: topMeta.bottom
        anchors.topMargin: 23
        anchors.left: parent.left
        anchors.leftMargin: constants.cameraViewMargin
        Connections{
            target: cambody
            onApertureChanged: {
                if (Camera.canChange & Camera.PropAV)
                {
                    startAvTvShow()
                }
            }
        }
    }
    ShutterSpeedControl {
        visible: root.isInstantPreview && showInstantAVTV
        id: shutterSpeedSetting
        allowHighlightBracket: false
        outlineText: true
        outlineColor: "white"
        outlineStyleColor: "black"
        shutterSpeedValue: cambody.TV_out_of_range ? "--" : cambody.shutterSpeed
        Connections{
            target: cambody
            onShutterSpeedChanged: {
                if(Camera.canChange & Camera.PropTV)
                {
                    startAvTvShow()
                }
            }
        }
        anchors.top: topMeta.bottom
        anchors.topMargin: 23
        anchors.right: parent.right
        anchors.rightMargin: constants.cameraViewMargin
    }
    Column {
        id: bottomCols
        height: childrenRect.height
        anchors {
            verticalCenter: bottomMeta.verticalCenter
            left: bottomMeta.left
            leftMargin: constants.metaDataMargins
            right: bottomMeta.right
            rightMargin: constants.metaDataMargins
        }
        spacing: constants.metaDataBottomColSpacing
        Item {
            id: col1
            objectName: "MetaDataOverlay_col1"
            visible: false
            anchors.left: parent.left
            anchors.right: parent.right
            height: col1content.height
            Item {
                id: col1content
                height: childrenRect.height
                y: (bottomTextLine1.height - bottomTextLine1.baselineOffset) / 2
                anchors.left: parent.left
                anchors.right: parent.right
                Text {
                    id: bottomTextLine1
                    color: "white"
                    font.pixelSize: constants.mediaBrowseFontSize
                    text: "f/" + metaAV + " ∙ " + metaTV + " ∙ " + qsTr("ISO") + " " + metaIso + guiconfig.emptyString
                    font.family: constants.metaDataTextFontName
                }
                Image {
                    id: exposureCompImage
                    visible: metaEvAdjust != 0x7f
                    source: "qrc:/icons/MetaDataExposureComp.png"
                    anchors.right: bottomTextLine1_2.left
                }
                Text {
                    id: bottomTextLine1_2
                    visible: exposureCompImage.visible
                    color: "white"
                    anchors.right: parent.right
                    font.pixelSize: constants.mediaBrowseFontSize
                    width: 107
                    horizontalAlignment: Text.AlignRight
                    text: (metaEvAdjust / 12).toFixed(1)  + qsTr("EV") + guiconfig.emptyString
                    font.family: constants.metaDataTextFontName
                }
            }
        }
        Item {
            objectName: "MetaDataOverlay_col3"
            id: col3
            visible: false
            height: childrenRect.height
            width: bottomCols.width
            Image {
                id: leftBracket1Image
                source: "qrc:/icons/MetaDataBracketLeft.png"
            }
            Image {
                id: exposureModeImage
                source: exposureModeSymbol(metaExposureMode)
                anchors.left: leftBracket1Image.right
                anchors.verticalCenter: leftBracket1Image.verticalCenter
            }
            Image {
                id: rightBracket1Image
                source: "qrc:/icons/MetaDataBracketRight.png"
                anchors.left: exposureModeImage.right
            }
            Image {
                id: leftBracket2Image
                visible: meteringImage.visible
                source: "qrc:/icons/MetaDataBracketLeft.png"
                anchors.left: rightBracket1Image.right
                anchors.leftMargin: constants.metaDataMargins
            }
            Image {
                id: meteringImage
                visible: meterModeValid(metaLightMeterMode)
                source: meterModeSymbol(metaLightMeterMode)
                anchors.left: leftBracket2Image.right
                anchors.verticalCenter: leftBracket2Image.verticalCenter
            }
            Image {
                id: rightBracket2Image
                visible: meteringImage.visible
                source: "qrc:/icons/MetaDataBracketRight.png"
                anchors.left: meteringImage.right
            }
            Image {
                id: leftBracket3Image
                visible: !System.isTethered
                source: "qrc:/icons/MetaDataBracketLeft.png"
                anchors.left: rightBracket2Image.right
                anchors.leftMargin: constants.metaDataMargins
            }
            Image {
                id: whiteBalanceModeImage
                visible: leftBracket3Image.visible
                source: whiteBalanceModeSymbol(metaWhiteBalanceMode)
                anchors.left: leftBracket3Image.right
                anchors.verticalCenter: leftBracket3Image.verticalCenter
            }
            Image {
                id: rightBracket3Image
                visible: leftBracket3Image.visible
                source: "qrc:/icons/MetaDataBracketRight.png"
                anchors.left: whiteBalanceModeImage.right
            }
            Text {
                id: bottomTextLine2
                visible: metaFocalLength != 0
                color: "white"
                font.pixelSize: constants.mediaBrowseFontSize
                font.family: constants.metaDataTextFontName
                anchors {
                    verticalCenter: rightBracket3Image.verticalCenter
                    verticalCenterOffset: (height - baselineOffset) / 2
                    left: rightBracket3Image.right
                    leftMargin: constants.metaDataMargins
                }
                text: ((metaFocalLength > 950) ? "--" : metaFocalLength + " mm")
            }
            Row {
                id:starRow
                anchors.verticalCenter: exposureModeImage.verticalCenter
                anchors.right: parent.right
                visible: configstore.imageRating
                spacing: 3
                Repeater {
                    model: 5
                    Image {
                        property bool selected: index < metaRating
                        fillMode: Image.PreserveAspectFit
                        height: 40
                        source: selected ? "qrc:///icons/MetaData_StarSelected.png" : "qrc:///icons/MetaData_StarUnSelected.png"
                    }
                }
            }
        }
    }
    HistogramBrowse {
        objectName: "MetaDataOverlay_histogram"
        id: histogram
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: false
    }
    states: [
        State {
            name: "base"
            PropertyChanges { target: topMeta; visible: true;}
            PropertyChanges { target: bottomMeta; visible: true; }
            PropertyChanges { target: bottomMeta; height: constants.botMetaHeightSimple; }
            PropertyChanges { target: col1; visible: true}
            PropertyChanges { target: root; nextClickAreaHeight: bottomMeta.height}
            PropertyChanges { target: bottomCols; height: col1.height}
        },
        State {
            name: "none"
        },
        State {
            name: "detail"
            PropertyChanges { target: topMeta; visible: true;}
            PropertyChanges { target: bottomMeta; visible: true;}
            PropertyChanges { target: bottomMeta; height: constants.botMetaHeightDetails; }
            PropertyChanges { target: col1; visible: true; }
            PropertyChanges { target: col3; visible: true; }
            PropertyChanges { target: root; nextClickAreaHeight: bottomMeta.height}
        },
        State {
            name: "histCombined"
            PropertyChanges { target: topMeta; visible: true;}
            PropertyChanges { target: histogram; visible: true; }
            PropertyChanges { target: histogram; state: "combined" }
            PropertyChanges { target: root; nextClickAreaHeight: histogram.height}
        },
        State {
            name: "histSeparate"
            PropertyChanges { target: topMeta; visible: true;}
            PropertyChanges { target: histogram; visible: true; }
            PropertyChanges { target: histogram; state: "separate" }
            PropertyChanges { target: root; nextClickAreaHeight: histogram.height}
        },
        State {
            name: "histLuminance"
            PropertyChanges { target: topMeta; visible: true;}
            PropertyChanges { target: histogram; visible: true; }
            PropertyChanges { target: histogram; state: "luminance" }
            PropertyChanges { target: root; nextClickAreaHeight: histogram.height}
        }
    ]
    function meterModeValid(index)
    {
        switch(index)
        {
        case 1:
        case 2:
        case 3:
        case 6:
            return true
        default:
            return false
        }
    }
    function meterModeSymbol(index)
    {
        switch(index)
        {
        case 1:
            return "qrc:/icons/MetaData_Metering_Average.png"
        case 2:
            return "qrc:/icons/MetaData_Metering_Centre.png"
        case 3:
            return "qrc:/icons/MetaData_Metering_Spot.png"
        case 6:
            return "qrc:/icons/MetaData_Metering_Multi.png"
        default:
            return "qrc:/icons/MetaData_Metering_None.png"
        }
    }
    function whiteBalanceModeSymbol(index)
    {
        switch(index)
        {
        case 1:
            return "qrc:/icons/MetaData_WBal_Auto.png";
        case 2:
            return "qrc:/icons/MetaData_WBal_Daylight.png";
        case 10:
            return "qrc:/icons/MetaData_WBal_Cloudy.png";
        case 3:
            return "qrc:/icons/MetaData_WBal_Tungsten.png";
        case 5:
            return "qrc:/icons/MetaData_WBal_Flash.png";
        case 11:
            return "qrc:/icons/MetaData_WBal_Shade.png";
        case 4:
            return "qrc:/icons/MetaData_WBal_Fluor.png";
        case 6:
            return "qrc:/icons/MetaData_WBal_Manual.png";
        default:
            return "qrc:/icons/MetaData_WBal_Daylight.png";
        }
    }
    function exposureModeSymbol(index)
    {
        switch(index)
        {
        case 0:
            return "qrc:/icons/MetaData_ExpMode_Manual.png"
        case 1:
            return "qrc:/icons/MetaData_ExpMode_Aperture.png"
        case 2:
            return "qrc:/icons/MetaData_ExpMode_Shutter.png"
        case 3:
            return "qrc:/icons/MetaData_ExpMode_Program.png"
        case 4:
            return "qrc:/icons/MetaData_ExpMode_ProgramV.png"
        default:
            return "qrc:/icons/MetaData_ExpMode_Manual.png";
        }
    }
    function volumeSymbol(index)
    {
        if(isTethered)
            return "USB"
        return guiconfig.storageSlotLetter(index)
    }
}
