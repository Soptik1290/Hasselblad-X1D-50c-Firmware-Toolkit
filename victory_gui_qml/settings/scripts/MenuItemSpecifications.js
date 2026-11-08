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
            {editType: SettingType.BOOL,       name: "WIFI_power",     text1: qsTranslate("MENUS", "Wi-Fi"), proxy: configstore },
            {editType: SettingType.DROPDOWN,   name: "WIFI_mode", text1: QT_TRANSLATE_NOOP("MENUS", "Mode"), text2: qsTranslate("MENUS", "GHz"), proxy: configstore },
        ];

var generalSettingsPowerTimeouts = [

            {editType: SettingType.DROPDOWN,       name: "GUI_idle_timeout", text1: QT_TRANSLATE_NOOP("MENUS", "Display Off"), text2: qsTranslate("MENUS", "s"), suppressUnitOn: "Never", proxy: configstore},
            /*
            // H6 system has automatic sleep handling, see "powerclient" api in appscommon used by multiple applications on camera (mainly imx).
            {editType: SettingType.DROPDOWN,       name: "sleep",      text1: QT_TRANSLATE_NOOP("MENUS", "Sleep"), text2: qsTranslate("MENUS", "min."), suppressUnitOn: "Never", demo: true},
            */
            {editType: SettingType.DROPDOWN,       name: "SYS_standby_idle_timeout",    text1: QT_TRANSLATE_NOOP("MENUS", "Power Off"), text2: qsTranslate("MENUS", "m"), suppressUnitOn: "Never", proxy: configstore, enableCond: "System.batteryStatus !== System.BatteryAux"},
            {editType: SettingType.CHECKBOX,       name: "power_from_usb",        text1: qsTranslate("MENUS", "Power from USB"), proxy: configstore},
        ];

var generalSettingsGPS = [
            {editType: SettingType.BOOL,           name: "gpsOn", text1: qsTranslate("MENUS", "GPS") ,      demo: true},
        ];

var cameraSettingsExposure = [
            {editType: SettingType.SUBHEADER,      name: "subHeaderExposure", text1: qsTranslate("MENUS", "Increment Step Size")},
            {editType: SettingType.DROPDOWN,       name: "CustomOption_StepsInc", text1: QT_TRANSLATE_NOOP("MENUS", "Exposure"), text2: qsTranslate("MENUS", "step"), proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "CustomOption_AdjStepsInc",  text1: QT_TRANSLATE_NOOP("MENUS", "Exposure Adjust"), text2: qsTranslate("MENUS", "step"), proxy: configstore, enableCond: "cambody.LMModeListAsInt !== 0"},

            {editType: SettingType.SUBHEADER,      name: "subHeaderLightMetering", text1: qsTranslate("MENUS", "Light Metering")},
            {editType: SettingType.DROPDOWN,       name: "CustomOption_ZoneModeInSpot",  text1: QT_TRANSLATE_NOOP("MENUS", "Spot Mode"), proxy: configstore, enableCond: "cambody.LMModeListAsInt !== 0"},

            {editType: SettingType.SUBHEADER,      name: "subHeaderShutterFunc", text1: qsTranslate("MENUS", "Shutter Function")},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_TrueExpEnabled",        text1: qsTranslate("MENUS", "True Exposure"), proxy: configstore, enableCond: "!configstore.eshutter && (Lens.lens_family === Lens.HCLens || Lens.lens_family === Lens.HCCLens || Lens.lens_family === Lens.XCLens)" },
            {editType: SettingType.CHECKBOX,       name: "eshutter",        text1: qsTranslate("MENUS", "Electronic Shutter"), proxy: configstore, demo: true},

            {editType: SettingType.SUBHEADER,      name: "subHeaderFlash",                       text1: qsTranslate("MENUS", "Flash") },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_LowFlashDisableInverter", text1: qsTranslate("MENUS", "Low Flash Warning"), proxy: configstore, enableCond: "configstore.haveFlashCapabilities" },
            {editType: SettingType.DROPDOWN,       name: "FlashMode",                            text1: QT_TRANSLATE_NOOP("MENUS", "Sync"), proxy: configstore, enableCond: "configstore.haveFlashCapabilities && Lens.lens_family !== Lens.VLens" },

            {editType: SettingType.SUBHEADER,      name: "subHeaderExposureLock",       text1: qsTranslate("MENUS", "Exposure Lock")                        },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_FlashExpPrio",   text1: qsTranslate("MENUS", "Flash Ready"),     proxy:configstore, enableCond: "configstore.haveFlashCapabilities"},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_LensExpLock",    text1: qsTranslate("MENUS", "Lens"),            proxy:configstore, enableCond: "configstore.CameraType === Config.CameraTypeHsystem"},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_RangeExpLock",   text1: qsTranslate("MENUS", "Out of Range"),    proxy:configstore, enableCond: "cambody.LMModeListAsInt !== 0"},

            {editType: SettingType.SUBHEADER,      name: "subHeaderAELock", text1: qsTranslate("MENUS", "AE-L / Quick Adjust")},
            {editType: SettingType.CHECKBOX,       name: "AELockResetAfterExposure",  text1: qsTranslate("MENUS", "Reset After Exposure"), proxy: configstore, enableCond: "(cambody.capabilities & Cambody.CapabilitySupportAE) !== 0"},

            {editType: SettingType.SUBHEADER,      name: "subHeaderMirror",             text1: qsTranslate("MENUS", "Mirror")},
            {editType: SettingType.DROPDOWN,       name: "CustomOption_MirrorDelay",    text1: QT_TRANSLATE_NOOP("MENUS", "Extra Mirror Delay"), text2: qsTranslate("MENUS", "ms"), suppressUnitOn: "None",   proxy: configstore, enableCond: "configstore.CameraType === Config.CameraTypeHsystem"},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_ReturnMirror",   text1: qsTranslate("MENUS", "Always Return Mirror"),    proxy: configstore, enableCond: "configstore.CameraType === Config.CameraTypeHsystem"},
        ];

var cameraSettingsImage = [
            {editType: SettingType.SUBHEADER,      name: "aspectRatio",      text1: qsTranslate("MENUS", "Image Format")},
            {editType: SettingType.DROPDOWN,       name: "aspectRatio",      text1: QT_TRANSLATE_NOOP("MENUS", "Crop Mode"), proxy: configstore},
            {editType: SettingType.SLIDER,         name: "crop_mode_opacity",        text1: qsTranslate("MENUS", "Mask Opacity"), proxy: configstore},

            {editType: SettingType.SUBHEADER,      name: "imageOrientation", text1: qsTranslate("MENUS", "Image Orientation")},
            {editType: SettingType.DROPDOWN,       name: "ImageOrientation",  text1: QT_TRANSLATE_NOOP("MENUS", "Orientation"), text2: qsTranslate("MENUS", "degrees"), suppressUnitOn: "Auto", proxy: configstore},
        ]

var cameraSettingsFocus = [
            {editType: SettingType.DROPDOWN,       name: "FocusScanRange",                  text1: QT_TRANSLATE_NOOP("MENUS", "Scan"),            proxy: configstore, enableCond: "((cambody.capabilities & Cambody.CapabilityGetSetAFmode) !== 0) && Lens.has_divided_scan_range" },
            {editType: SettingType.DROPDOWN,       name: "CustomOption_AfLed",              text1: QT_TRANSLATE_NOOP("MENUS", "AF Assist Light"), proxy: configstore, enableCond: "(cambody.capabilities & Cambody.CapabilityGetSetAFmode) !== 0" },
            {editType: SettingType.DROPDOWN,       name: "CustomOption_ManualFocusAssist",  text1: QT_TRANSLATE_NOOP("MENUS", "Focus Aid in MF"), proxy: configstore, enableCond: "configstore.CameraType === Config.CameraTypeHsystem" },
            {editType: SettingType.CHECKBOX,       name: "TrueFocusInAFSingle",             text1: qsTranslate("MENUS", "True Focus in AF-S"),    proxy: configstore, enableCond: "(cambody.capabilities & Cambody.CapabilityGetSetAFmode) !== 0" },
        ]

var cameraSettingsSelfTimer = [
            {editType: SettingType.CHECKBOX,       name: "selfTimerActive",         text1: qsTranslate("MENUS", "Active"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "SelftimerDelay",          text1: QT_TRANSLATE_NOOP("MENUS", "Time"), text2: qsTranslate("MENUS", "s"), proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "SelftimerSequence",       text1: QT_TRANSLATE_NOOP("MENUS", "Sequence"), proxy: configstore, enableCond: "(configstore.CameraType === Config.CameraTypeHsystem)"},
            {editType: SettingType.DROPDOWN,       name: "SelftimerMirrorRemain",   text1: QT_TRANSLATE_NOOP("MENUS", "Mirror Behaviour"), proxy: configstore, enableCond: "(configstore.CameraType === Config.CameraTypeHsystem)"},
            {editType: SettingType.DROPDOWN,       name: "CustomOption_ExitStay",   text1: QT_TRANSLATE_NOOP("MENUS", "When Finished"), proxy: configstore },
        ];

var cameraSettingsInterval = [
            {editType: SettingType.CHECKBOX,       name: "intervalActive",          text1: qsTranslate("MENUS", "Active"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "IntervalTime",            text1: QT_TRANSLATE_NOOP("MENUS", "Time"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "IntervalNumberOfShots",   text1: QT_TRANSLATE_NOOP("MENUS", "Frames"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "IntervalDelayTime",       text1: QT_TRANSLATE_NOOP("MENUS", "Initial Delay"), text2: qsTranslate("MENUS", "s"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "CustomOption_ExitStay",   text1: QT_TRANSLATE_NOOP("MENUS", "When Finished"), proxy: configstore },
        ];

var cameraSettingsBracketing = [
            {editType: SettingType.CHECKBOX,       name: "bracketingActive",            text1: qsTranslate("MENUS", "Active"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "BracketingStep",              text1: QT_TRANSLATE_NOOP("MENUS", "Amount"), text2: qsTranslate("MENUS", "step"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "BracketingNumberOfFrames",    text1: QT_TRANSLATE_NOOP("MENUS", "Frames"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "BracketingApertureOption",    text1: QT_TRANSLATE_NOOP("MENUS", "Parameter in M"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "BracketingSequenceOption",    text1: QT_TRANSLATE_NOOP("MENUS", "Sequence"), proxy: configstore },
        ];

var cameraSettingsFocusBracketing = [
            {editType: SettingType.CHECKBOX,       name: "focusBracketingActive",          text1: qsTranslate("MENUS", "Active"),        proxy: configstore, enableCond: "(BodySync.currentDialMode !== BodySync.DmFullauto) && ((Lens.lens_family === Lens.HCLens) || (Lens.lens_family === Lens.HCCLens) || (Lens.lens_family === Lens.XCLens) || configstore.focusBracketingActive)" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingNumberOfFrames",   text1: qsTranslate("MENUS", "Frames"),        proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingStepSize",   text1: qsTranslate("MENUS", "Step Size"), text2: qsTranslate("MENUS", "DOF"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
//            {editType: SettingType.DROPDOWN,       name: "FocusBracketingDelayTime",       text1: qsTranslate("MENUS", "Initial Delay"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingStrategy",   text1: qsTranslate("MENUS", "Sequence"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
//            {editType: SettingType.DROPDOWN,       name: "FocusBracketingExitOption",   text1: qsTranslate("MENUS", "When Finished"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];



var cameraSettingsLiveView = [
            {editType: SettingType.BUTTON,         name: "liveViewStart",       text1: qsTranslate("MENUS", "Start") },
            {editType: SettingType.DROPDOWN,       name: "MFAid",               text1: qsTranslate("MENUS", "MF Assist"),     proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "FocusPeakingColor",   text1: qsTranslate("MENUS", "Peaking Color"), proxy: configstore, enableCond: "configstore.CustomOption_FocusPeaking" },
            {editType: SettingType.DROPDOWN,       name: "ZoomLevel",           text1: qsTranslate("MENUS", "Zoom Level"),    proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "overlay",             text1: QT_TRANSLATE_NOOP("MENUS", "Overlay"), demo: true},
        ];

var cameraSettingsCustomButtons = [
            {editType: SettingType.DROPDOWN,       name: "Userbutton_TrueFocusFunction",    text1: QT_TRANSLATE_NOOP("MENUS", "True Focus"),            proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "Userbutton_AELockFunction",       text1: QT_TRANSLATE_NOOP("MENUS", "AE-L"),                  proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "Userbutton_MirrorUpFunction",     text1: QT_TRANSLATE_NOOP("MENUS", "M.UP"),                  proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "Userbutton_StopDownFunction",     text1: QT_TRANSLATE_NOOP("MENUS", "STOP DOWN"),             proxy: configstore },
        ];

var cameraSettingsConfiguration = [
            {editType: SettingType.DROPDOWN,       name: "CustomOption_RearApertureWheel",  text1: QT_TRANSLATE_NOOP("MENUS", "Front Wheel in M"),          proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "CustomOption_AvLightmeterMode",   text1: QT_TRANSLATE_NOOP("MENUS", "Aperture Indication"),  proxy: configstore, demo: true },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_HideBTmode",         text1: qsTranslate("MENUS", "Hide B/T Mode"),              proxy: configstore },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_ShowHistogram",      text1: qsTranslate("MENUS", "Show Histogram"),             proxy: configstore },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_AElockAtHalfpress",  text1: qsTranslate("MENUS", "AE-L when Half-pressed"),     proxy: configstore },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_QuickAdjustOn",      text1: qsTranslate("MENUS", "Exposure Quick Adjust"),      proxy: configstore, enableCond: "(cambody.capabilities & (Cambody.CapabilitySetAV | Cambody.CapabilitySetTV)) !== 0" },
            {editType: SettingType.CHECKBOX,       name: "imageRating",                     text1: qsTranslate("MENUS", "Image Rating"),               proxy: configstore},
        ];

var cameraSettingsImageInfo =[
            {editType: SettingType.EDITTEXT,       name: "textForImage",       text1: qsTranslate("MENUS", "Text"), demo: true},
        ];

var videoSettingsVideoQuality = [
            {editType: SettingType.DROPDOWN,       name: "Video_Quality",     text1: QT_TRANSLATE_NOOP("MENUS", "Quality"),                   proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "Video_Resolution",  text1: QT_TRANSLATE_NOOP("MENUS", "H.264 Resolution"),           proxy: configstore, enableCond: "configstore.Video_Quality === Config.MP4"},
            {editType: SettingType.DROPDOWN,       name: "video_noise",       text1: QT_TRANSLATE_NOOP("MENUS", "Noise Filter"),   demo:true, proxy: configstore},
        ];

var videoSettingsAudio = [
            {editType: SettingType.DROPDOWN,       name: "audioMode",  text1: QT_TRANSLATE_NOOP("MENUS", "Mode"), demo: true},
            {editType: SettingType.SLIDER,         name: "audioLevel", text1: qsTranslate("MENUS", "Level"), demo: true},
        ];

var videoSettingsLiveView = [
            {editType: SettingType.DROPDOWN,       name: "LiveVideoOverlayIndex",     text1: QT_TRANSLATE_NOOP("MENUS", "Overlay"), proxy: configstore},
        ];

var generalSettingsDisplay = [
            {editType: SettingType.SLIDER,         name: "contrast",                    text1: qsTranslate("MENUS", "Contrast"), demo: true},
            {editType: SettingType.SLIDER,         name: "BACKLIGHT_brightness",        text1: qsTranslate("MENUS", "Brightness"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_ShowPreview",    text1: qsTranslate("MENUS", "Show Preview"),    proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "OverExposureWarning",         text1: qsTranslate("MENUS", "Mark Overexposure"), proxy: configstore },
        ]

var generalSettingsSound = [
            {editType: SettingType.DROPDOWN,       name: "soundLevel",        text1: QT_TRANSLATE_NOOP("MENUS", "Volume"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "keyClick",          text1: qsTranslate("MENUS", "Key Click"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "exposureWarningSound",   text1: qsTranslate("MENUS", "Exposure Warning"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "readyAfterExposureSound", text1: qsTranslate("MENUS", "Ready"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "beeper",            text1: qsTranslate("MENUS", "Beeper"), demo: true},
        ]


var generalSettingsDateTime = [
            {editType: SettingType.DROPDOWN,       name: "datePicker",          text1: QT_TRANSLATE_NOOP("MENUS", "Date"), demo: true},
            {editType: SettingType.DROPDOWN,       name: "timePicker",          text1: QT_TRANSLATE_NOOP("MENUS", "Time"),  demo: true},
        ]

var generalSettingsLanguage = [
            {editType: SettingType.DROPDOWN,       name: "languageIndex",       text1: QT_TRANSLATE_NOOP("MENUS", "Language"), proxy: configstore },
        ]

var cameraSettingsCameraBody = [
            {editType: SettingType.DROPDOWN,       name: "CameraType",          text1: QT_TRANSLATE_NOOP("MENUS", "Camera Body"), proxy: configstore},
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
            {editType: SettingType.BUTTON,         name: "fwUpdateRetry",       text1: qsTranslate("MENUS", "Firmware Update Retry"), proxy: guiconfig, validCheck: "guiconfig.showSecretMenuItems"},
        ]

var generalSettingsAbout = [
            {editType: SettingType.TEXTBUTTON,     name: "versionID",         text1: qsTranslate("MENUS", "Firmware: "), proxy: system},
            {editType: SettingType.TEXT,           name: "lensVersion",       text1: qsTranslate("MENUS", "Lens Firmware: "), proxy: suc, enableCond: "suc.lensVersion.length > 0" },
            {editType: SettingType.TEXT,           name: "viewFinderVersion", text1: qsTranslate("MENUS", "Viewfinder Firmware: "), proxy: suc, enableCond: "suc.viewFinderVersion.length > 0" },
            {editType: SettingType.TEXT,           name: "SuSerial",          text1: qsTranslate("MENUS", "Serial number: "),  proxy: prodinfo },
            {editType: SettingType.BUTTON,         name: "License",           text1: qsTranslate("MENUS", "Licenses") },
            {editType: SettingType.BUTTON,         name: "Usage",             text1: qsTranslate("MENUS", "Usage"), enableCond: "configstore.CameraType === Config.CameraTypeHsystem" },
        ]

var generalSettingsAboutUsage = [
            {editType: SettingType.SUBHEADER,      name: "counterHeader",   text1: qsTranslate("MENUS", "Exposures") },
            {editType: SettingType.TEXT,           name: "bodyCounter",     text1: qsTranslate("MENUS", "Body: "),  proxy: suc, enableCond: "suc.bodyCounter > 0"},
            {editType: SettingType.TEXT,           name: "lensCounter",     text1: qsTranslate("MENUS", "Lens: "), proxy: suc },
        ]

var generalSettingsStorage = [
            {editType: SettingType.SUBHEADER,      name: "cardFormatCard",                    text1: qsTranslate("MENUS", "Format Card") },
            {editType: SettingType.BUTTON,         name: "cardFormatCard0",                   text1: qsTranslate("MENUS", "Format CFast"),               text2: qsTranslate("MENUS", "All content will be erased!"), enableCond: "ContentModel.card0Status !== ContentModel.STORAGE_ABSENT" },
            {editType: SettingType.BUTTON,         name: "cardFormatCard1",                   text1: qsTranslate("MENUS", "Format SD"),                  text2: qsTranslate("MENUS", "All content will be erased!"), enableCond: "ContentModel.card1Status !== ContentModel.STORAGE_ABSENT" },
            {editType: SettingType.SUBHEADER,      name: "cardImageDestinationHeader",        text1: qsTranslate("MENUS", "Destination") },
            {editType: SettingType.DROPDOWN,       name: "primary_volume_image_raw",          text1: QT_TRANSLATE_NOOP("MENUS", "Primary Slot"), proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "storage_mode",                      text1: QT_TRANSLATE_NOOP("MENUS", "Secondary Slot Usage"), proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "cardCurrentFolder",                 text1: QT_TRANSLATE_NOOP("MENUS", "Current Folder"), demo: true},
       //     {editType: SettingType.SUBHEADER,      name: "cardPrimaryVideoSlotHeader",        text1: qsTranslate("MENUS", "Video Destination") },
       //     {editType: SettingType.DROPDOWN,       name: "primary_volume_video_encoded",              text1: QT_TRANSLATE_NOOP("MENUS", "Primary H.264 slot"), proxy: configstore, demo: true},
       //     {editType: SettingType.TEXT,           name: "cardPrimaryVideoSlotText",          text1: qsTranslate("MENUS", "RAW video to CFast only"), demo: true},
        ]

// settingsList should be the name of list to be opened for item
// itemText is the visible text for each item
var settingsMenuItems = [
            {settingsList: "generalSettingsWiFi",          itemText:QT_TRANSLATE_NOOP("MENUS", "Wi-Fi"),              itemFile:"qrc:///settings/SettingsGeneric.qml",   largeIcon: "LargeIconWiFi"},
            {settingsList: "generalSettingsDisplay",       itemText:QT_TRANSLATE_NOOP("MENUS", "Display"),            itemFile:"qrc:///settings/SettingsGeneric.qml",   largeIcon: "LargeIconDisplay"},
            {settingsList: "generalSettingsStorage",       itemText:QT_TRANSLATE_NOOP("MENUS", "Storage"),            itemFile:"qrc:///settings/SettingsGeneric.qml",   largeIcon: "LargeIconStorage"},
            {settingsList: "generalSettingsSound",         itemText:QT_TRANSLATE_NOOP("MENUS", "Sound"),              itemFile:"qrc:///settings/SettingsGeneric.qml",   largeIcon: "LargeIconSound"},
            {settingsList: "generalSettingsDateTime",      itemText:QT_TRANSLATE_NOOP("MENUS", "Date & Time"),        itemFile:"qrc:///settings/DateTime.qml" ,         largeIcon: "LargeIconDateTime"},
            {settingsList: "generalSettingsPowerTimeouts", itemText:QT_TRANSLATE_NOOP("MENUS", "Power & Timeouts"),   itemFile:"qrc:///settings/SettingsGeneric.qml" ,  largeIcon: "LargeIconPowerTimeouts"},
            {settingsList: "generalSettingsSpiritLevel",   itemText:QT_TRANSLATE_NOOP("MENUS", "Spirit Level"),       itemFile:"qrc:///settings/SpiritLevelView.qml",   largeIcon: "LargeIconSpiritLevel", enableCond: "suc.cambody_attached && (configstore.CameraType === Config.CameraTypeHsystem)" },
            {settingsList: "generalSettingsHTS",           itemText:QT_TRANSLATE_NOOP("MENUS", "HTS"),                itemFile:"qrc:///settings/HTSView.qml",           largeIcon: "LargeIconHTS", enableCond: "cambody.hts_attached" },
            {settingsList: "generalSettingsGPS",           itemText:QT_TRANSLATE_NOOP("MENUS", "GPS"),                itemFile:"qrc:///settings/SettingsGeneric.qml",   demo: true, largeIcon: "LargeIconGPS"},
            {settingsList: "generalSettingsProfiles",      itemText:QT_TRANSLATE_NOOP("MENUS", "Profiles"),           itemFile:"qrc:///settings/ProfilesView.qml",      largeIcon: "LargeIconProfiles"},
            {settingsList: "generalSettingsLanguage",      itemText:QT_TRANSLATE_NOOP("MENUS", "Language"),           itemFile:"qrc:///settings/SettingsGeneric.qml",   largeIcon: "LargeIconLanguage"},
            {settingsList: "generalSettingsService",       itemText:QT_TRANSLATE_NOOP("MENUS", "Service"),            itemFile:"qrc:///settings/SettingsGeneric.qml",   largeIcon: "LargeIconService"},
            {settingsList: "generalSettingsAbout",         itemText:QT_TRANSLATE_NOOP("MENUS", "About"),              itemFile:"qrc:///settings/SettingsGeneric.qml",   largeIcon: "LargeIconAbout"},
        ];

var cameraSettingsQuality = [
            {editType: SettingType.DROPDOWN,       name: "image_format",   text1: QT_TRANSLATE_NOOP("MENUS", "Image Format"),  demo:false, proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "jpg_quality",    text1: QT_TRANSLATE_NOOP("MENUS", "JPG Quality"),   demo:false, proxy: configstore, enableCond: "configstore.image_format !== Config.Raw"},
            {editType: SettingType.DROPDOWN,       name: "color_profile",  text1: QT_TRANSLATE_NOOP("MENUS", "Color Profile"), demo:false, proxy: configstore, enableCond: "configstore.image_format !== Config.Raw"},
            {editType: SettingType.DROPDOWN,       name: "image_noise",    text1: QT_TRANSLATE_NOOP("MENUS", "Noise Filter"),  demo:true, proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "image_bit_depth",text1: QT_TRANSLATE_NOOP("MENUS", "Bit Depth"),  text2: qsTranslate("MENUS", "bit"),   demo:false, proxy: configstore, validCheck: "guiconfig.isAlbatross"},
            {editType: SettingType.CHECKBOX,       name: "compress_3fr",   text1: qsTranslate("MENUS", "Compressed 3FR"),      demo:true, proxy: configstore, enableCond: "configstore.image_format !== Config.RawJpg"},
        ]

var cameraMenuItems = [
        {settingsList: "cameraSettingsExposure",             itemText:QT_TRANSLATE_NOOP("MENUS", "Exposure"),     itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconExposure"},
        {settingsList: "cameraSettingsImage",                itemText:QT_TRANSLATE_NOOP("MENUS", "Image"),        itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconImage"},
        {settingsList: "cameraSettingsQuality",              itemText:QT_TRANSLATE_NOOP("MENUS", "Quality"),      itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconQuality"},
        {settingsList: "cameraSettingsFocus",                itemText:QT_TRANSLATE_NOOP("MENUS", "Focus"),        itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconFocus",      enableCond: "suc.cambody_attached && (configstore.CameraType === Config.CameraTypeHsystem)"},
        {settingsList: "cameraSettingsGreyBalanceTool",      itemText:QT_TRANSLATE_NOOP("MENUS", "White Balance Tool"),        itemFile:"qrc:///components/GreyBalanceTool.qml", largeIcon: "LargeIconGreyBalanceTool"},
        {settingsList: "cameraSettingsSelfTimer",            itemText:QT_TRANSLATE_NOOP("MENUS", "Self Timer"),   itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconSelfTimer",  enableCond: "(suc.cambody_attached && configstore.CameraType === Config.CameraTypeHsystem) || configstore.CameraType === Config.CameraTypePinhole"},
        {settingsList: "cameraSettingsInterval",             itemText:QT_TRANSLATE_NOOP("MENUS", "Interval"),     itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconInterval",   enableCond: "suc.cambody_attached && (configstore.CameraType === Config.CameraTypeHsystem) && (cambody.capabilities & Cambody.CapabilityContinuousDrive) !== 0"},
        {settingsList: "cameraSettingsBracketing",           itemText:QT_TRANSLATE_NOOP("MENUS", "Bracketing"),   itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconBracketing", enableCond: "suc.cambody_attached && (configstore.CameraType === Config.CameraTypeHsystem) && (cambody.capabilities & Cambody.CapabilityContinuousDrive) !== 0"},
        {settingsList: "cameraSettingsFocusBracketing",      itemText:QT_TRANSLATE_NOOP("MENUS", "Focus Bracketing"), itemFile:"qrc:///settings/SettingsGeneric.qml", demo: true, largeIcon: "LargeIconFocusBracketing", enableCond: "suc.cambody_attached && (configstore.CameraType === Config.CameraTypeHsystem) && (cambody.capabilities & Cambody.CapabilityContinuousDrive) !== 0"},
        {settingsList: "cameraSettingsLiveView",             itemText:QT_TRANSLATE_NOOP("MENUS", "Live View"),    itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconLiveView"},
        {settingsList: "cameraSettingsCustomButtons",        itemText:QT_TRANSLATE_NOOP("MENUS", "Custom Buttons"),     itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconCustomButtons", enableCond: true}, /*"suc.cambody_attached && (configstore.CameraType === Config.CameraTypeHsystem)*/
        {settingsList: "cameraSettingsConfiguration",        itemText:QT_TRANSLATE_NOOP("MENUS", "Configuration"),     itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconConfiguration",  enableCond: "suc.cambody_attached && (configstore.CameraType === Config.CameraTypeHsystem)"},
        {settingsList: "cameraSettingsImageInfo",            itemText:QT_TRANSLATE_NOOP("MENUS", "Image Info"),   itemFile:"qrc:///settings/SettingsGeneric.qml", demo: true, largeIcon: "LargeIconImageInfo"},
        {settingsList: "cameraSettingsCameraBody",           itemText:QT_TRANSLATE_NOOP("MENUS", "Camera Body"),  itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconCameraBody", enableCond: "!suc.cambody_attached || configstore.CameraType !== Config.CameraTypeHsystem"},
        ];


var videoMenuItems = [
        {settingsList: "videoSettingsVideoQuality", itemText:QT_TRANSLATE_NOOP("MENUS", "Quality"),   itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconImageVideoQuality"},
        {settingsList: "videoSettingsAudio",        itemText:QT_TRANSLATE_NOOP("MENUS", "Audio"),     itemFile:"qrc:///settings/SettingsGeneric.qml", demo: true, largeIcon: "LargeIconAudio"},
        {settingsList: "videoSettingsLiveView",     itemText:QT_TRANSLATE_NOOP("MENUS", "Live View"), itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconVideoLiveView"},
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
    case "generalSettingsGPS": return generalSettingsGPS;
    case "cameraSettingsExposure": return cameraSettingsExposure;
    case "cameraSettingsImage": return cameraSettingsImage;
    case "cameraSettingsQuality": return cameraSettingsQuality;
    case "cameraSettingsFocus": return cameraSettingsFocus;
    case "cameraSettingsSelfTimer": return cameraSettingsSelfTimer;
    case "cameraSettingsInterval": return cameraSettingsInterval;
    case "cameraSettingsBracketing": return cameraSettingsBracketing;
    case "cameraSettingsFocusBracketing": return cameraSettingsFocusBracketing;
    case "cameraSettingsLiveView": return cameraSettingsLiveView;
    case "cameraSettingsCustomButtons": return cameraSettingsCustomButtons;
    case "cameraSettingsConfiguration": return cameraSettingsConfiguration;
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
    case "generalSettingsStorage": return generalSettingsStorage;
    case "generalSettingsUsage": return generalSettingsAboutUsage;

    default: return cameraSettingsExposure;
    }
}


function getSettingsMenuItems(withWifi) {
    if (typeof withWifi !== 'undefined' && withWifi)
        return settingsMenuItems;
    else
        return settingsMenuItems.filter(function(v) { return (v.settingsList !== "generalSettingsWiFi") })
}
