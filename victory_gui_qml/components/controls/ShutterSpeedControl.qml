import QtQuick 2.5

Item {
    id: root
    property alias allowHighlightBracket: shutterSpeedSetting.allowHighlightBracket
    property alias forceHighlight: shutterSpeedSetting.forceHighlight
    property alias outlineText: shutterSpeedSetting.outlineText
    property alias outlineColor: shutterSpeedSetting.outlineColor
    property alias outlineStyleColor: shutterSpeedSetting.outlineStyleColor
    property string shutterSpeedValue: "--"
    width: shutterSpeedSetting.width
    height: shutterSpeedSetting.height
    property bool showIcon: false

    TextCameraControl {
        id: shutterSpeedSetting
        objectName: "ShutterSpeedControlSetting"
        focus: root.activeFocus
        labelSize: constants.cameraSettingVerySmallLabelSize
        valueSize: constants.cameraSettingLargeTextSize
        unit1Size: constants.cameraSettingLargeLabelSize
        unit2Size: constants.cameraSettingLargeLabelSize
        value2Size: constants.cameraSettingLargeLabelSize
        labelLow: false
        anchors.top: parent.top
        anchors.right: parent.right
        icon: showIcon ? "qrc:/icons/ControlScreen_EShutter.png" : ""
    }

    // Somewhat lengthy function to set shutter speed
    // Problem is that the text is splitted to several different items
    function setShutterSpeedValue()
    {
        var speedParts = shutterSpeedValue.split(/[m|h|s]/);
        shutterSpeedSetting.value = speedParts[0];
        shutterSpeedSetting.label = "";
        if(speedParts.length === 1)
        {
            // Either a number or either "B Mode", "T Mode"
            // If large enough, replace last three zeros witk "k"
            if(shutterSpeedSetting.value > 9999)
            {
                shutterSpeedSetting.value = shutterSpeedSetting.value / 1000 + "k"
                shutterSpeedSetting.unit1 = "";
            }
            else
            {
                shutterSpeedSetting.unit1 = "";
            }
            shutterSpeedSetting.value2 = "";
            shutterSpeedSetting.unit2 = "";
        }
        else
        {
            // We have either "<hour>h<min>m" or "<min>m<sec>s" os "<num>s" or "<num>m"
            var lastLetter = shutterSpeedValue.slice(-1);
            if(speedParts.length === 2)
            {
                // No label // '<number>s' or '<number>m'
                shutterSpeedSetting.unit1 = lastLetter;
                shutterSpeedSetting.unit2 = "";
                shutterSpeedSetting.value2 = "";
            }
            else
            {
                shutterSpeedSetting.unit1 = shutterSpeedValue.slice(-4, -3);
                shutterSpeedSetting.unit2 = lastLetter;
                shutterSpeedSetting.value2 = speedParts[1];
            }
        }
    }

    onShutterSpeedValueChanged: setShutterSpeedValue()
    Component.onCompleted: setShutterSpeedValue()
}

