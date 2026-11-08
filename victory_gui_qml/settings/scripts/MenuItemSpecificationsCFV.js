//.pragma library
/* Setting items:

  <name> is variable name to use
  editType: type of item, see "SettingType" below
  name: name of setting variable to transfer to C++. Should be the same name as the property
  text1, text2, button, checkbox: variables to configure item
  proxy: name of proxy to use
  validCheck: optional expression to check if item is valid to change
  suppressUnitOn: "string": Optional property to check if the unit part (text2) should be suppressed when proxy value
            returns the specified string

  [name]: [visible items]
  bool: TEXT<text1> BOOLSWITCH
  radioButtons: RADIOBUTTON1 TEXT1<text1> RADIOBUTTON2 TEXT2<text2>
  dropdDown: TEXT1<text1> DROPDOWN TEXT2_opt<text2> BUTTON_opt<button>
  number: TEXT1<text1> NUMBERSPINNER CHECKBOX_opt<checkbox> SUBTEXT_opt<text2>
  checkbox: CEHCKBOX TEXT<text1> BUTTON_opt<button>
  slider: TEXT<text1> SLIDER
  editxtext: TEXT<text1> EDITBOX BUTTON_opt<button>
  subheader: TEXT<text1>
  button: BUTTON<text1,enableCond>
  enableCond: Optional button property that if given specifies a string with an expression that if evaluates to true will
    enable the button (visually and for clicking). If not given, button is always enabled.


  */

var SettingType = {
    DROPDOWN: 1,
    CHECKBOX: 2,
    BUTTON: 3,
    BOOL: 4,
    SLIDER: 5,
    EDITTEXT: 6,
    TEXT: 7,
    TEXTBUTTON: 8,
    SUBHEADER: 9,
};

// TODO: Items that are not connected to the camera (or whatever) are marked with "demo: true", showing them in red on the camera
// Please remove that when the item is connected

var generalSettingsWiFi = [
            {editType: SettingType.BOOL,           name: "WIFI_power",     text1: qsTranslate("MENUS", "Wi-Fi"), proxy: configstore },
            {editType: SettingType.DROPDOWN,   name: "WIFI_mode", text1: QT_TRANSLATE_NOOP("MENUS", "Mode"), proxy: configstore },
        ];

var generalSettingsPowerTimeouts = [

            {editType: SettingType.DROPDOWN,       name: "GUI_idle_timeout", text1: QT_TRANSLATE_NOOP("MENUS", "Display Off"), text2: qsTranslate("MENUS", "s"), suppressUnitOn: "Never", proxy: configstore},
            /*
            // H6 system has automatic sleep handling, see "powerclient" api in appscommon used by multiple applications on camera (mainly imx).
            {editType: SettingType.DROPDOWN,       name: "sleep",      text1: QT_TRANSLATE_NOOP("MENUS", "Sleep"), text2: qsTranslate("MENUS", "min."), suppressUnitOn: "Never", demo: true},
            */
            {editType: SettingType.DROPDOWN,       name: "SYS_standby_idle_timeout",    text1: QT_TRANSLATE_NOOP("MENUS", "Power Off"), text2: qsTranslate("MENUS", "m"), suppressUnitOn: "Never", proxy: configstore},
        ];

var cameraSettingsImage = [
            {editType: SettingType.SUBHEADER,      name: "aspectRatio",      text1: qsTranslate("MENUS", "Image Format")},
            {editType: SettingType.DROPDOWN,       name: "aspectRatio",      text1: QT_TRANSLATE_NOOP("MENUS", "Crop Mode"), demo: true, proxy: configstore},
            {editType: SettingType.SLIDER,         name: "crop_mode_opacity",        text1: qsTranslate("MENUS", "Mask Opacity"), proxy: configstore},
            {editType: SettingType.SUBHEADER,      name: "imageOrientation", text1: qsTranslate("MENUS", "Image Orientation")},
            {editType: SettingType.DROPDOWN,       name: "ImageOrientation",  text1: QT_TRANSLATE_NOOP("MENUS", "Orientation"), text2: qsTranslate("MENUS", "degrees"), suppressUnitOn: "Auto", proxy: configstore},
        ];

var cameraSettingsLiveView = [
            {editType: SettingType.BUTTON,         name: "liveViewStart",       text1: qsTranslate("MENUS", "Start") },
            {editType: SettingType.DROPDOWN,       name: "MFAid",               text1: qsTranslate("MENUS", "MF Assist"),     proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "FocusPeakingColor",   text1: qsTranslate("MENUS", "Peaking Color"), proxy: configstore, enableCond: "configstore.CustomOption_FocusPeaking" },
            {editType: SettingType.DROPDOWN,       name: "ZoomLevel",           text1: qsTranslate("MENUS", "Zoom Level"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "overlay",             text1: QT_TRANSLATE_NOOP("MENUS", "Overlay"), demo: true},
        ];

var cameraSettingsImageInfo =[
            {editType: SettingType.EDITTEXT,       name: "textForImage",       text1: qsTranslate("MENUS", "Text"), demo: true},
        ];

var cameraSettingsConfiguration = [
            {editType: SettingType.SUBHEADER,      name: "subHeaderImageRating",       text1: qsTranslate("MENUS", "Image Rating"), demo:true},
            {editType: SettingType.CHECKBOX,       name: "imageRating",         text1: qsTranslate("MENUS", "Image Rating"), demo:true, proxy: configstore},
        ];

var videoSettingsVideoQuality = [
            {editType: SettingType.DROPDOWN,           name: "Video_Resolution",  text1: QT_TRANSLATE_NOOP("MENUS", "Resolution"),           proxy: configstore, enableCond: "configstore.Video_Quality === Config.MP4"},
            {editType: SettingType.DROPDOWN,           name: "video_noise",       text1: QT_TRANSLATE_NOOP("MENUS", "Noise Filter"),   demo:true, proxy: configstore},
        ];

var videoSettingsAudio = [
            {editType: SettingType.DROPDOWN,           name: "audioMode",  text1: QT_TRANSLATE_NOOP("MENUS", "Mode"), demo: true},
            {editType: SettingType.SLIDER,             name: "audioLevel", text1: qsTranslate("MENUS", "Level"), demo: true},
        ];

var videoSettingsLiveView = [
            {editType: SettingType.DROPDOWN,       name: "LiveVideoOverlayIndex",     text1: QT_TRANSLATE_NOOP("MENUS", "Overlay"), proxy: configstore},
        ];

var generalSettingsDisplay = [
            {editType: SettingType.SLIDER,         name: "contrast",          text1: qsTranslate("MENUS", "Contrast"), demo: true},
            {editType: SettingType.SLIDER,         name: "BACKLIGHT_brightness", text1: qsTranslate("MENUS", "Brightness"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_ShowPreview",    text1: qsTranslate("MENUS", "Show Preview"),    proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "OverExposureWarning",      text1: qsTranslate("MENUS", "Mark Overexposure"), proxy: configstore },
        ]

var generalSettingsSound = [
            {editType: SettingType.DROPDOWN,       name: "soundLevel",        text1: QT_TRANSLATE_NOOP("MENUS", "Volume"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "keyClick",          text1: qsTranslate("MENUS", "Key Click"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "exposureWarningSound",   text1: qsTranslate("MENUS", "Exposure Warning"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "readyAfterExposureSound", text1: qsTranslate("MENUS", "Ready"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "afSucceeded",       text1: qsTranslate("MENUS", "AF Succeeded"), proxy: configstore, demo: true},  // for Bifrost only
        ]


var generalSettingsDateTime = [
            {editType: SettingType.DROPDOWN,       name: "datePicker",          text1: QT_TRANSLATE_NOOP("MENUS", "Date"), demo: true},
            {editType: SettingType.DROPDOWN,       name: "timePicker",          text1: QT_TRANSLATE_NOOP("MENUS", "Time"),  demo: true},
        ]

var generalSettingsLanguage = [
            {editType: SettingType.DROPDOWN,       name: "languageIndex",          text1: QT_TRANSLATE_NOOP("MENUS", "Language"), proxy: configstore },
        ]

var cameraSettingsCameraBody = [
            {editType: SettingType.DROPDOWN,       name: "CameraType",          text1: QT_TRANSLATE_NOOP("MENUS", "Camera Body"), proxy: configstore, demo: true},
        ]

var generalSettingsService = [
            {editType: SettingType.SUBHEADER,      name: "fwUpdateHeader",      text1: qsTranslate("MENUS", "Firmware Update") },
            {editType: SettingType.BUTTON,         name: "checkForUpdate",      text1: qsTranslate("MENUS", "Check for Update") },
            {editType: SettingType.SUBHEADER,      name: "logDataHeader",       text1: qsTranslate("MENUS", "Log Data") },
            {editType: SettingType.BUTTON,         name: "saveLogData",         text1: qsTranslate("MENUS", "Save") },
            {editType: SettingType.SUBHEADER,      name: "logDefaultSettings",  text1: qsTranslate("MENUS", "Default Settings") },
            {editType: SettingType.BUTTON,         name: "defaultSettings",     text1: qsTranslate("MENUS", "Reset all Settings") },
            {editType: SettingType.CHECKBOX,       name: "resetProfiles",       text1: qsTranslate("MENUS", "Reset Profiles"), proxy: configstore},
            {editType: SettingType.SUBHEADER,      name: "logDefaultSettings",  text1: qsTranslate("MENUS", "File Counter") },
            {editType: SettingType.BUTTON,         name: "resetFileCounter",    text1: qsTranslate("MENUS", "Reset"), proxy: guiconfig },
            {editType: SettingType.SUBHEADER,      name: "demoModeHeader",      text1: qsTranslate("MENUS", "Demo Mode"), validCheck: "guiconfig.showSecretMenuItems"},
            {editType: SettingType.CHECKBOX,       name: "ram_only_mode",       text1: qsTranslate("MENUS", "Deactivate Storage"), text2: qsTranslate("MENUS", "No images will be saved to card!"), proxy: farm, validCheck: "guiconfig.showSecretMenuItems"},
            {editType: SettingType.SUBHEADER,      name: "additionalFunctionsHeader",     text1: qsTranslate("MENUS", "Additional Functions") },
            {editType: SettingType.BUTTON,         name: "fwUpdateRetry",        text1: qsTranslate("MENUS", "Firmware Update Retry"), proxy: guiconfig, validCheck: "guiconfig.showSecretMenuItems"},
        ]

var generalSettingsAbout = [
            {editType: SettingType.TEXTBUTTON,     name: "versionID",         text1: qsTranslate("MENUS", "Firmware: "), proxy: system},
            {editType: SettingType.TEXT,           name: "SuSerial",      text1: qsTranslate("MENUS", "Serial number: "),  proxy: prodinfo },
            {editType: SettingType.BUTTON,         name: "License",       text1: qsTranslate("MENUS", "Licenses") },
        ]

var generalSettingsProfiles = [
            {editType: SettingType.CHECKBOX,       name: "profiles",      text1: qsTranslate("MENUS", "Profiles"), demo: true},
        ]

var generalSettingsStorage = [
            {editType: SettingType.SUBHEADER,      name: "cardFormatCard",                text1: qsTranslate("MENUS", "Format Card") },
            {editType: SettingType.BUTTON,         name: "cardFormatCard0",               text1: qsTranslate("MENUS", "Format SD1"), text2: qsTranslate("MENUS", "All content will be erased!"), enableCond: "ContentModel.card0Status !== ContentModel.STORAGE_ABSENT" },
            {editType: SettingType.BUTTON,         name: "cardFormatCard1",               text1: qsTranslate("MENUS", "Format SD2"), text2: qsTranslate("MENUS", "All content will be erased!"), enableCond: "ContentModel.card1Status !== ContentModel.STORAGE_ABSENT" },
            {editType: SettingType.SUBHEADER,      name: "cardImageDestinationHeader",        text1: qsTranslate("MENUS", "Destination") },
            {editType: SettingType.DROPDOWN,       name: "primary_volume_image_raw",          text1: QT_TRANSLATE_NOOP("MENUS", "Primary Slot"), proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "storage_mode",                      text1: QT_TRANSLATE_NOOP("MENUS", "Secondary Slot Usage"), proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "cardCurrentFolder",                 text1: QT_TRANSLATE_NOOP("MENUS", "Current Folder"), demo: true},
        ]

// settingsList should be the name of list to be opened for item
// itemText is the visible text for each item
var settingsMenuItems = [
            {settingsList: "generalSettingsWiFi",          itemText:QT_TRANSLATE_NOOP("MENUS", "Wi-Fi"),              itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconWiFi"},
            {settingsList: "generalSettingsDisplay",       itemText:QT_TRANSLATE_NOOP("MENUS", "Display"),            itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconDisplay"},
            {settingsList: "generalSettingsProfiles",      itemText:QT_TRANSLATE_NOOP("MENUS", "Profiles"),           itemFile:"qrc:///settings/SettingsGeneric.qml",     demo: true, largeIcon: "LargeIconProfiles"},
            {settingsList: "generalSettingsStorage",       itemText:QT_TRANSLATE_NOOP("MENUS", "Storage"),            itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconStorage"},
            {settingsList: "generalSettingsSound",         itemText:QT_TRANSLATE_NOOP("MENUS", "Sound"),              itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconSound"},
            {settingsList: "generalSettingsDateTime",      itemText:QT_TRANSLATE_NOOP("MENUS", "Date & Time"),        itemFile:"qrc:///settings/DateTime.qml" , largeIcon: "LargeIconDateTime"},
            {settingsList: "generalSettingsPowerTimeouts", itemText:QT_TRANSLATE_NOOP("MENUS", "Power & Timeouts"),   itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconPowerTimeouts"},
            {settingsList: "generalSettingsSpiritLevel",   itemText:QT_TRANSLATE_NOOP("MENUS", "Spirit Level"),       itemFile:"qrc:///settings/SpiritLevelView.qml", demo: true, largeIcon: "LargeIconSpiritLevel" },
            {settingsList: "generalSettingsLanguage",      itemText:QT_TRANSLATE_NOOP("MENUS", "Language"),           itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconLanguage"},
            {settingsList: "generalSettingsService",       itemText:QT_TRANSLATE_NOOP("MENUS", "Service"),            itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconService"},
            {settingsList: "generalSettingsAbout",         itemText:QT_TRANSLATE_NOOP("MENUS", "About"),              itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconAbout"},
        ];

var cameraSettingsQuality = [
            {editType: SettingType.DROPDOWN,       name: "image_format",   text1: QT_TRANSLATE_NOOP("MENUS", "Image Format"),  demo:false, proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "jpg_quality",    text1: QT_TRANSLATE_NOOP("MENUS", "JPG Quality"),   demo:false, proxy: configstore, enableCond: "configstore.image_format !== Config.Raw"},
            {editType: SettingType.DROPDOWN,       name: "jpg_size",       text1: qsTranslate("MENUS", "JPG Size"), text2: qsTranslate("MENUS", "MP"), demo:true,  proxy: configstore, enableCond: "configstore.image_format !== Config.Raw"},
            {editType: SettingType.DROPDOWN,       name: "color_profile",  text1: QT_TRANSLATE_NOOP("MENUS", "Color Profile"), demo:false, proxy: configstore, enableCond: "configstore.image_format !== Config.Raw"},
            {editType: SettingType.DROPDOWN,       name: "image_noise",    text1: QT_TRANSLATE_NOOP("MENUS", "Noise Filter"),  demo:true, proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "compress_3fr",   text1: qsTranslate("MENUS", "Compressed 3FR"),      demo:true, proxy: configstore, enableCond: "configstore.image_format !== Config.RawJpg"},
        ]

var cameraMenuItems = [
        {settingsList: "cameraSettingsCameraBody",           itemText:QT_TRANSLATE_NOOP("MENUS", "Camera Body"),  itemFile:"qrc:///settings/SettingsGeneric.qml", demo: true, largeIcon: "LargeIconCameraBody"},
        {settingsList: "cameraSettingsImage",                itemText:QT_TRANSLATE_NOOP("MENUS", "Image"),        itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconImage"},
        {settingsList: "cameraSettingsQuality",              itemText:QT_TRANSLATE_NOOP("MENUS", "Quality"),      itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconQuality"},
        {settingsList: "cameraSettingsGreyBalanceTool",      itemText:QT_TRANSLATE_NOOP("MENUS", "White Balance Tool"),        itemFile:"qrc:///components/GreyBalanceTool.qml", largeIcon: "LargeIconGreyBalanceTool"},
        {settingsList: "cameraSettingsLiveView",             itemText:QT_TRANSLATE_NOOP("MENUS", "Live View"),    itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconLiveView"},
        {settingsList: "cameraSettingsImageInfo",            itemText:QT_TRANSLATE_NOOP("MENUS", "Image Info"),   itemFile:"qrc:///settings/SettingsGeneric.qml", demo: true, largeIcon: "LargeIconImageInfo"},
        {settingsList: "cameraSettingsConfiguration",        itemText:QT_TRANSLATE_NOOP("MENUS", "Configuration"),itemFile:"qrc:///settings/SettingsGeneric.qml", demo: true, largeIcon: "LargeIconConfiguration"},
        ];


var videoMenuItems = [
        {settingsList: "videoSettingsVideoQuality", itemText:QT_TRANSLATE_NOOP("MENUS", "Quality"), itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconImageVideoQuality"},
        {settingsList: "videoSettingsAudio",        itemText:QT_TRANSLATE_NOOP("MENUS", "Audio"), itemFile:"qrc:///settings/SettingsGeneric.qml",   demo: true, largeIcon: "LargeIconAudio"},
        {settingsList: "videoSettingsLiveView",     itemText:QT_TRANSLATE_NOOP("MENUS", "Live View"), itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconLiveView"},
        ];


function getSettingsList(settingsName)
{
    switch(settingsName)
    {
    case "generalSettingsWiFi": return generalSettingsWiFi;
    case "generalSettingsDisplay": return generalSettingsDisplay;
    case "generalSettingsSound": return generalSettingsSound;
    case "generalSettingsDateTime": return generalSettingsDateTime;
    case "generalSettingsPowerTimeouts": return generalSettingsPowerTimeouts;
    case "cameraSettingsImage": return cameraSettingsImage;
    case "cameraSettingsQuality": return cameraSettingsQuality;
    case "cameraSettingsLiveView": return cameraSettingsLiveView;
    case "cameraSettingsImageInfo": return cameraSettingsImageInfo;
    case "videoSettingsVideoQuality": return videoSettingsVideoQuality;
    case "videoSettingsAudio": return videoSettingsAudio;
    case "videoSettingsLiveView": return videoSettingsLiveView;
    case "generalSettingsDisplay": return generalSettingsDisplay;
    case "generalSettingsDateTime": return generalSettingsDateTime;
    case "generalSettingsLanguage": return generalSettingsLanguage;
    case "cameraSettingsCameraBody": return cameraSettingsCameraBody;
    case "generalSettingsService": return generalSettingsService;
    case "generalSettingsAbout": return generalSettingsAbout;
    case "generalSettingsProfiles": return generalSettingsProfiles;
    case "generalSettingsStorage": return generalSettingsStorage;

    default: return cameraSettingsImage;
    }
}


function getSettingsMenuItems(withWifi) {
    if (typeof withWifi !== 'undefined' && withWifi)
        return settingsMenuItems;
    else
        return settingsMenuItems.filter(function(v) { return (v.settingsList !== "generalSettingsWiFi") })
}
