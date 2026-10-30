//.import com.hasselblad.settings 1.0 as Settings

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
  enableCond: Optional button property that if given specifies a string with an expression that if evaluates to true will
    enable the button (visually and for clicking). If not given, button is always enabled.
    The enableCond property works differently for TEXT items when given, if it evaluates to false the text will not be visible.

  [name]: [visible items]
  bool: TEXT<text1> BOOLSWITCH
  radioButtons: RADIOBUTTON1 TEXT1<text1> RADIOBUTTON2 TEXT2<text2>
  dropdDown: TEXT1<text1> DROPDOWN TEXT2_opt<text2> BUTTON_opt<button>
  number: TEXT1<text1> NUMBERSPINNER CHECKBOX_opt<checkbox> SUBTEXT_opt<text2>
  checkbox: CEHCKBOX TEXT<text1> BUTTON_opt<button>
  slider: TEXT<text1> SLIDER
  editxtext: TEXT<text1> EDITBOX BUTTON_opt<button>
  subheader: TEXT<text1> button: BUTTON<text1,enableCond>
  text: TEXT<text1, enableCond>
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
            {editType: SettingType.DROPDOWN,   name: "WIFI_mode", text1: qsTranslate("MENUS", "Mode"), text2: qsTranslate("MENUS", "GHz"), proxy: configstore },
        ];

var generalSettingsPowerTimeouts = [

            {editType: SettingType.DROPDOWN,       name: "GUI_idle_timeout", text1: qsTranslate("MENUS", "Display Off"), text2: qsTranslate("MENUS", "s"), proxy: configstore},
            /*
            // H6 system has automatic sleep handling, see "powerclient" api in appscommon used by multiple applications on camera (mainly imx).
            {editType: SettingType.DROPDOWN,       name: "sleep",      text1: qsTranslate("MENUS", "Sleep"),       text2: qsTranslate("MENUS", "min."),      demo: true},
            */
            {editType: SettingType.DROPDOWN,       name: "SYS_standby_idle_timeout",    text1: qsTranslate("MENUS", "Power Off"),   text2: qsTranslate("MENUS", "m"),    proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "power_from_usb",        text1: qsTranslate("MENUS", "Power from USB"), proxy: configstore},
        ];

var cameraSettingsImage = [
            {editType: SettingType.SUBHEADER,      name: "aspectRatio",      text1: qsTranslate("MENUS", "Image Format")},
            {editType: SettingType.DROPDOWN,       name: "aspectRatio",      text1: QT_TRANSLATE_NOOP("MENUS", "Crop Mode"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.SLIDER,         name: "crop_mode_opacity",  text1: qsTranslate("MENUS", "Mask Opacity"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.SUBHEADER,      name: "imageOrientation", text1: qsTranslate("MENUS", "Image Orientation")},
            {editType: SettingType.DROPDOWN,       name: "ImageOrientation",  text1: QT_TRANSLATE_NOOP("MENUS", "Orientation"), text2: qsTranslate("MENUS", "degrees"), suppressUnitOn: "Auto", proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];

var generalSettingsGPS = [
            {editType: SettingType.BOOL,           name: "gpsOn", text1: qsTranslate("MENUS", "GPS") ,      demo: true},
        ];

var cameraSettingsExposure = [
            {editType: SettingType.SUBHEADER,      name: "subHeaderExposure",        text1: qsTranslate("MENUS", "Increment Step Size")},
            {editType: SettingType.DROPDOWN,       name: "CustomOption_StepsInc",    text1: qsTranslate("MENUS", "Exposure"), text2: qsTranslate("MENUS", "step"),        proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "CustomOption_AdjStepsInc", text1: qsTranslate("MENUS", "Exposure Adjust"), text2: qsTranslate("MENUS", "step"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },

   //       {editType: SettingType.SUBHEADER,      name: "subHeaderExposureMode",       text1: qsTranslate("MENUS", "Exposure Mode")},
   //       {editType: SettingType.DROPDOWN,       name: "CustomOption_ZoneModeInSpot", text1: qsTranslate("MENUS", "Spot Mode"), proxy: configstore},   // Zone mode might be a feature in Wedge in the future

            {editType: SettingType.SUBHEADER,      name: "subHeaderShutterFunc", text1: qsTranslate("MENUS", "Shutter Function")},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_TrueExpEnabled", text1: qsTranslate("MENUS", "True Exposure"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto && !configstore.eshutter && (Lens.lens_family === Lens.HCLens || Lens.lens_family === Lens.HCCLens || Lens.lens_family === Lens.XCLens)" },
            {editType: SettingType.CHECKBOX,       name: "eshutter",        text1: qsTranslate("MENUS", "Electronic Shutter"),        proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },

            {editType: SettingType.SUBHEADER,      name: "subHeaderFlash",              text1: qsTranslate("MENUS", "Flash") },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_LowFlashDisableInverter", text1: qsTranslate("MENUS", "Low Flash Warning"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FlashMode",                   text1: qsTranslate("MENUS", "Sync"),                       proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },

            {editType: SettingType.SUBHEADER,      name: "subHeaderExposureLock",       text1: qsTranslate("MENUS", "Exposure Lock")                        },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_FlashExpPrio",   text1: qsTranslate("MENUS", "Flash Ready"),       proxy:configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
//            {editType: SettingType.CHECKBOX,       name: "CustomOption_LensExpLock",  text1: qsTranslate("MENUS", "Lens"),              proxy:configstore,  },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_RangeExpLock",   text1: qsTranslate("MENUS", "Out of Range"),      proxy:configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },

            {editType: SettingType.SUBHEADER,      name: "subHeaderAELock", text1: qsTranslate("MENUS", "AE-L / Quick Adjust")},
            {editType: SettingType.CHECKBOX,       name: "AELockResetAfterExposure", text1: qsTranslate("MENUS", "Reset After Exposure"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];

var cameraSettingsAutofocus = [
            {editType: SettingType.DROPDOWN,       name: "focus_size",                   text1: qsTranslate("MENUS", "AF Point Size"),     text2: qsTranslate("MENUS", "mm"),  proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "focus_point_reset",            text1: qsTranslate("MENUS", "Reset Focus Point"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusScanRange",               text1: QT_TRANSLATE_NOOP("MENUS", "Scan"),        proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto && ((cambody.capabilities & Cambody.CapabilityGetSetAFmode) !== 0) && Lens.has_divided_scan_range" },
            {editType: SettingType.DROPDOWN,       name: "CustomOption_AfLed",           text1: qsTranslate("MENUS", "AF Assist Light"),   proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },

            /* AF debug options */
            {editType: SettingType.CHECKBOX,       name: "af_fir",                       text1: "AF prefilter",      proxy: configstore, demo: true },
            {editType: SettingType.CHECKBOX,       name: "af_log",                       text1: "Save AF sequence",  proxy: configstore, demo: true },
            {editType: SettingType.CHECKBOX,       name: "af_full_scan",                 text1: "AF debug scan",     proxy: configstore, demo: true },
            {editType: SettingType.DROPDOWN,       name: "fpga_debug",                   text1: "Brenner",           proxy: configstore, demo: true },
            {editType: SettingType.CHECKBOX,       name: "DebugAfSpeedEnable",           text1: "Enable AF Speed",   proxy: configstore, demo: true },
            {editType: SettingType.DROPDOWN,       name: "DebugAfSpeed",                 text1: "AF Speed",          proxy: configstore, demo: true },
            {editType: SettingType.DROPDOWN,       name: "DebugAfMode",                  text1: "AF Mode",           proxy: configstore, demo: true },
//            {editType: SettingType.CHECKBOX,       name: "CustomOption_ZoomOnFocusRing", text1: qsTranslate("MENUS", "Auto Zoom in MF"), proxy: configstore },

        ]

var cameraSettingsManualFocus = [
            {editType: SettingType.DROPDOWN,       name: "MFAid",                        text1: qsTranslate("MENUS", "MF Assist"),         proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusPeakingColor",            text1: qsTranslate("MENUS", "Peaking Color"),     proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto && configstore.CustomOption_FocusPeaking" },
        ]

var cameraSettingsSelfTimer = [
            {editType: SettingType.CHECKBOX,       name: "selfTimerActive",       text1: qsTranslate("MENUS", "Active"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "SelftimerDelay",        text1: qsTranslate("MENUS", "Time"), text2: qsTranslate("MENUS", "s"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "CustomOption_ExitStay", text1: qsTranslate("MENUS", "When Finished"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.CHECKBOX,       name: "SelftimerBlinkLed",     text1: qsTranslate("MENUS", "LED Blink"), proxy: configstore },
        ];


var cameraSettingsInterval = [
            {editType: SettingType.CHECKBOX,       name: "intervalActive",          text1: qsTranslate("MENUS", "Active"),        proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "IntervalTime",            text1: qsTranslate("MENUS", "Time"), text2: qsTranslate("MENUS", "s"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "IntervalNumberOfShots",   text1: qsTranslate("MENUS", "Frames"),        proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "IntervalDelayTime",       text1: qsTranslate("MENUS", "Initial Delay"), text2: qsTranslate("MENUS", "s"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "CustomOption_ExitStay",   text1: qsTranslate("MENUS", "When Finished"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];

var cameraSettingsBracketing = [
            {editType: SettingType.CHECKBOX,       name: "bracketingActive",         text1: qsTranslate("MENUS", "Active"), proxy: configstore,  enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
            {editType: SettingType.DROPDOWN,       name: "BracketingStep",           text1: qsTranslate("MENUS", "Amount"), text2: qsTranslate("MENUS", "step"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
            {editType: SettingType.DROPDOWN,       name: "BracketingNumberOfFrames", text1: qsTranslate("MENUS", "Frames"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
            {editType: SettingType.DROPDOWN,       name: "BracketingDelayTime",      text1: qsTranslate("MENUS", "Initial Delay"), text2: qsTranslate("MENUS", "s"), suppressUnitOn: "None", proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
            {editType: SettingType.DROPDOWN,       name: "BracketingApertureOption", text1: qsTranslate("MENUS", "Parameter in M"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
            {editType: SettingType.DROPDOWN,       name: "BracketingSequenceOption", text1: QT_TRANSLATE_NOOP("MENUS", "Sequence"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
            {editType: SettingType.DROPDOWN,       name: "CustomOption_ExitStay",    text1: qsTranslate("MENUS", "When Finished"), proxy: configstore,  enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
        ];

var cameraSettingsFocusBracketing = [
            {editType: SettingType.CHECKBOX,       name: "focusBracketingActive",          text1: qsTranslate("MENUS", "Active"),        proxy: configstore, enableCond: "(BodySync.currentDialMode !== BodySync.DmFullauto) && ((Lens.lens_family === Lens.HCLens) || (Lens.lens_family === Lens.HCCLens) || (Lens.lens_family === Lens.XCLens) || configstore.focusBracketingActive)" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingNumberOfFrames",   text1: qsTranslate("MENUS", "Frames"),        proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingStepSize",   text1: qsTranslate("MENUS", "Step Size"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingDelayTime",       text1: qsTranslate("MENUS", "Initial Delay"), text2: qsTranslate("MENUS", "s"), suppressUnitOn: "None", proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingIntervalTime",       text1: qsTranslate("MENUS", "Exposure Delay"), text2: qsTranslate("MENUS", "s"), suppressUnitOn: "None", proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingStrategy",   text1: qsTranslate("MENUS", "Sequence"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "FocusBracketingExitOption",   text1: qsTranslate("MENUS", "When Finished"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];

var cameraSettingsLiveView = [
            {editType: SettingType.BUTTON,         name: "liveViewStart",       text1: qsTranslate("MENUS", "Start") },
            {editType: SettingType.DROPDOWN,       name: "overlay",             text1: qsTranslate("MENUS", "Overlay"), demo: true, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];

var cameraSettingsCustomButtons = [
            {editType: SettingType.DROPDOWN,       name: "Userbutton_AELockFunction",   text1: qsTranslate("MENUS", "AE-L"),      proxy: configstore, demo: true, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "Userbutton_AFDriveFunction",  text1: qsTranslate("MENUS", "AF-D"),      proxy: configstore, demo: true, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "Userbutton_AFMFFunction",     text1: qsTranslate("MENUS", "AF/MF"),     proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "Userbutton_ISOWBFunction",    text1: qsTranslate("MENUS", "ISO/WB"),    proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "Userbutton_StopDownFunction", text1: qsTranslate("MENUS", "Stop Down"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];

var cameraSettingsConfiguration = [
            {editType: SettingType.DROPDOWN,       name: "CustomOption_RearApertureWheel", text1: qsTranslate("MENUS", "Front Wheel in M"), demo: true,        proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_HideBTmode",        text1: qsTranslate("MENUS", "Hide B/T Mode"),  demo: true,          proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_AElockAtHalfpress", text1: qsTranslate("MENUS", "AE-L when Half-pressed"), demo: true,  proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.SUBHEADER,      name: "subHeaderQuickAdjust",       text1: qsTranslate("MENUS", "Quick Adjust")},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_QuickAdjustOn",     text1: qsTranslate("MENUS", "Exposure Quick Adjust"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.SUBHEADER,      name: "subHeaderAutoIsoLimits",       text1: qsTranslate("MENUS", "Auto ISO Limits")},
            {editType: SettingType.DROPDOWN,       name: "SV_auto_max", text1: qsTranslate("MENUS", "Maximum"), proxy: camera, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "SV_auto_min", text1: qsTranslate("MENUS", "Minimum"), proxy: camera, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.SUBHEADER,      name: "subHeader_A_P_FullAuto_AutoIso",       text1: qsTranslate("MENUS", "Auto ISO / P / <img src=\"qrc:/icons/FullAutoIconLarge.png\" align=\"top\">")},
            {editType: SettingType.DROPDOWN,       name: "shutter_speed_limit", text1: qsTranslate("MENUS", "Shutter Speed Limit"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
            {editType: SettingType.SUBHEADER,      name: "subHeaderLens",       text1: qsTranslate("MENUS", "Lens")},
            {editType: SettingType.DROPDOWN,       name: "max_aperture", text1: qsTranslate("MENUS", "Max Aperture"), proxy: configstore, enableCond: "(BodySync.currentDialMode !== BodySync.DmFullauto) && (Lens.lens_family === Lens.XCLens)" },
            {editType: SettingType.SUBHEADER,      name: "subHeaderImageRating",       text1: qsTranslate("MENUS", "Image Rating")},
            {editType: SettingType.CHECKBOX,       name: "imageRating",         text1: qsTranslate("MENUS", "Image Rating"), proxy: configstore},
        ];

var cameraSettingsImageInfo =[
            {editType: SettingType.EDITTEXT,       name: "textForImage",       text1: qsTranslate("MENUS", "Text"), demo: true},
        ];

var videoSettingsVideoQuality = [
            {editType: SettingType.DROPDOWN,           name: "Video_Resolution", text1: QT_TRANSLATE_NOOP("MENUS", "Resolution"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,           name: "video_noise",      text1: QT_TRANSLATE_NOOP("MENUS", "Noise Filter"), demo:true, proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];

var videoSettingsAudio = [
            {editType: SettingType.DROPDOWN,           name: "audioMode",  text1: qsTranslate("MENUS", "Mode"), demo: true},
            {editType: SettingType.SLIDER,             name: "audioLevel", text1: qsTranslate("MENUS", "Level"), demo: true},
        ];

var videoSettingsLiveView = [
            {editType: SettingType.DROPDOWN,       name: "LiveVideoOverlayIndex",     text1: QT_TRANSLATE_NOOP("MENUS", "Overlay"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
        ];

var generalSettingsDisplay = [
            {editType: SettingType.SUBHEADER,      name: "subHeaderAdjustment",      text1: qsTranslate("MENUS", "Adjustment")},
            {editType: SettingType.SLIDER,         name: "contrast",                 text1: qsTranslate("MENUS", "Contrast"), demo: true },
            {editType: SettingType.SLIDER,         name: "BACKLIGHT_brightness",     text1: qsTranslate("MENUS", "Brightness"), proxy: configstore},
            {editType: SettingType.SUBHEADER,      name: "subHeaderExposureSim",     text1: qsTranslate("MENUS", "Exposure Simulation")},
            {editType: SettingType.CHECKBOX,       name: "exposureSimulationAuto",   text1: "A / S / P / <img src=\"qrc:/icons/FullAutoIcon.png\" align=\"top\">", proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.CHECKBOX,       name: "exposureSimulationManual", text1: "M", proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.SUBHEADER,      name: "subHeaderZoomLevel",       text1: qsTranslate("MENUS", "Live View")},
            {editType: SettingType.DROPDOWN,       name: "ZoomLevel",                text1: qsTranslate("MENUS", "Zoom Level"), proxy: configstore },
            {editType: SettingType.CHECKBOX,       name: "CustomOption_LiveViewEVFOnly", text1: qsTranslate("MENUS", "EVF Only"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.SUBHEADER,      name: "subHeaderImagePreview",    text1: qsTranslate("MENUS", "Image Preview")},
            {editType: SettingType.CHECKBOX,       name: "CustomOption_ShowPreview", text1: qsTranslate("MENUS", "Rear Screen"),    proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "EVFPreviewTimeout",    text1: qsTranslate("MENUS", "EVF"),   text2: qsTranslate("MENUS", "s"),    proxy: configstore},
            {editType: SettingType.DROPDOWN,       name: "Eyesensor_Distance",       text1: qsTranslate("MENUS", "Eye Sensor Distance"), demo:true, proxy: configstore },
            {editType: SettingType.SUBHEADER,      name: "subHeaderOverExposureWarning", text1: qsTranslate("MENUS", "Overexposure Warning")},
            {editType: SettingType.CHECKBOX,       name: "OverExposureWarning",      text1: qsTranslate("MENUS", "Mark Overexposure"), proxy: configstore }
        ];

var generalSettingsTouch = [
            {editType: SettingType.SUBHEADER,      name: "subHeaderTouchpadEvf",    text1: qsTranslate("MENUS", "Touchpad for EVF")},
            {editType: SettingType.DROPDOWN,       name: "touchpad_position",       text1: qsTranslate("MENUS", "Area"), proxy: configstore },
            {editType: SettingType.CHECKBOX,       name: "evf_tp_move_focus",       text1: qsTranslate("MENUS", "Move AF Point"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.CHECKBOX,       name: "evf_tp_image_browse",     text1: qsTranslate("MENUS", "Image Browse"), proxy: configstore},
            {editType: SettingType.SUBHEADER,      name: "subHeaderTouchpadHdmi",   text1: qsTranslate("MENUS", "Touchpad for HDMI")},
            {editType: SettingType.CHECKBOX,       name: "hdmi_tp_move_focus",      text1: qsTranslate("MENUS", "Move AF Point"), proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" }
        ];

var generalSettingsSound = [
            {editType: SettingType.DROPDOWN,       name: "soundLevel",      text1: qsTranslate("MENUS", "Volume"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "keyClick",        text1: qsTranslate("MENUS", "Key Click"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "exposureWarningSound", text1: qsTranslate("MENUS", "Exposure Warning"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "readyAfterExposureSound", text1: qsTranslate("MENUS", "Ready"), proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "afSucceededSound",     text1: qsTranslate("MENUS", "AF Result"), proxy: configstore},
        ];


var generalSettingsDateTime = [
            {editType: SettingType.DROPDOWN,       name: "datePicker",      text1: qsTranslate("MENUS", "Date"), demo: true},
            {editType: SettingType.DROPDOWN,       name: "timePicker",      text1: qsTranslate("MENUS", "Time"),  demo: true},
        ]

var generalSettingsLanguage = [
            {editType: SettingType.DROPDOWN,       name: "languageIndex",   text1: qsTranslate("MENUS", "Language"), proxy: configstore },
        ]

var generalSettingsService = [
            {editType: SettingType.SUBHEADER,      name: "fwUpdateHeader",     text1: qsTranslate("MENUS", "Firmware Update") },
            {editType: SettingType.BUTTON,         name: "checkForUpdate",     text1: qsTranslate("MENUS", "Check for Update") },
            {editType: SettingType.SUBHEADER,      name: "logDataHeader",      text1: qsTranslate("MENUS", "Log Data") },
            {editType: SettingType.BUTTON,         name: "saveLogData",        text1: qsTranslate("MENUS", "Save") },
            {editType: SettingType.SUBHEADER,      name: "logDefaultSettings", text1: qsTranslate("MENUS", "Default Settings") },
            {editType: SettingType.BUTTON,         name: "defaultSettings",    text1: qsTranslate("MENUS", "Reset all Settings") },
            {editType: SettingType.CHECKBOX,       name: "resetProfiles",       text1: qsTranslate("MENUS", "Reset C1 - C3"), proxy: configstore},
            {editType: SettingType.SUBHEADER,      name: "logDefaultSettings", text1: qsTranslate("MENUS", "File Counter") },
            {editType: SettingType.BUTTON,         name: "resetFileCounter",   text1: qsTranslate("MENUS", "Reset"), proxy: guiconfig },
            {editType: SettingType.SUBHEADER,      name: "demoModeHeader",     text1: qsTranslate("MENUS", "Demo Mode"), validCheck: "guiconfig.showSecretMenuItems"},
            {editType: SettingType.CHECKBOX,       name: "ram_only_mode",      text1: qsTranslate("MENUS", "Deactivate Storage"), text2: qsTranslate("MENUS", "No images will be saved to card!"), proxy: farm, validCheck: "guiconfig.showSecretMenuItems"},
            {editType: SettingType.SUBHEADER,      name: "additionalFunctionsHeader",     text1: qsTranslate("MENUS", "Additional Functions") },
            {editType: SettingType.BUTTON,         name: "fwUpdateRetry",      text1: qsTranslate("MENUS", "Firmware Update Retry"), proxy: guiconfig, validCheck: "guiconfig.showSecretMenuItems"},
            {editType: SettingType.DROPDOWN,       name: "thumbwheel_mode",    text1: qsTranslate("MENUS", "Scroll Wheel Handling"), proxy: guiconfig, validCheck: "guiconfig.showSecretMenuItems"},
        ]

var generalSettingsAbout = [
            {editType: SettingType.TEXTBUTTON,     name: "versionID",     text1: qsTranslate("MENUS", "Firmware: "), proxy: system},
            {editType: SettingType.TEXT,           name: "lensVersion",   text1: qsTranslate("MENUS", "Lens Firmware: "), proxy: suc, enableCond: "suc.lensVersion.length > 0" },
            {editType: SettingType.TEXT,           name: "SuSerial",      text1: qsTranslate("MENUS", "Serial number: "),  proxy: prodinfo },
            {editType: SettingType.BUTTON,         name: "License",       text1: qsTranslate("MENUS", "Licenses") },
            {editType: SettingType.BUTTON,         name: "Certification", text1: qsTranslate("MENUS", "Certification") },
            {editType: SettingType.BUTTON,         name: "Usage",         text1: qsTranslate("MENUS", "Usage") },
        ]

var generalSettingsAboutUsage = [
            {editType: SettingType.SUBHEADER,      name: "counterHeader",     text1: qsTranslate("MENUS", "Exposures") },
            {editType: SettingType.TEXT,           name: "lensCounter",       text1: qsTranslate("MENUS", "Lens: "), proxy: suc },
        ]

var generalSettingsProfiles = [
            {editType: SettingType.BUTTON,         name: "saveCustomMode1",    text1: qsTranslate("MENUS", "Save to C1") },
            {editType: SettingType.BUTTON,         name: "saveCustomMode2",    text1: qsTranslate("MENUS", "Save to C2") },
            {editType: SettingType.BUTTON,         name: "saveCustomMode3",    text1: qsTranslate("MENUS", "Save to C3") },
        ]

var generalSettingsStorage = [
            {editType: SettingType.SUBHEADER,      name: "cardFormatCard",                text1: qsTranslate("MENUS", "Format Card") },
            {editType: SettingType.BUTTON,         name: "cardFormatCard0",               text1: qsTranslate("MENUS", "Format SD1"), text2: qsTranslate("MENUS", "All content will be erased!"), enableCond: "ContentModel.card0Status !== ContentModel.STORAGE_ABSENT" },
            {editType: SettingType.BUTTON,         name: "cardFormatCard1",               text1: qsTranslate("MENUS", "Format SD2"), text2: qsTranslate("MENUS", "All content will be erased!"), enableCond: "ContentModel.card1Status !== ContentModel.STORAGE_ABSENT" },
            {editType: SettingType.SUBHEADER,      name: "cardImageDestinationHeader",    text1: qsTranslate("MENUS", "Destination") },
            {editType: SettingType.DROPDOWN,       name: "primary_volume_image_raw",      text1: QT_TRANSLATE_NOOP("MENUS", "Primary Slot"), proxy: configstore },
            {editType: SettingType.DROPDOWN,       name: "storage_mode",                  text1: qsTranslate("MENUS", "Secondary Slot Usage"), proxy: configstore },
    //        {editType: SettingType.DROPDOWN,       name: "cardCurrentFolder",                 text1: qsTranslate("MENUS", "Current Folder"), demo: true},
       //     {editType: SettingType.SUBHEADER,      name: "cardPrimaryVideoSlotHeader",        text1: qsTranslate("MENUS", "Video Destination") },
       //     {editType: SettingType.DROPDOWN,       name: "primary_volume_video_encoded",              text1: qsTranslate("MENUS", "Primary H.264 slot"), proxy: configstore, demo: true},
        ]

// settingsList should be the name of list to be opened for item
// itemText is the visible text for each item
var settingsMenuItems = [
            {settingsList: "generalSettingsWiFi",          itemText:QT_TRANSLATE_NOOP("MENUS", "Wi-Fi"),              itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconWiFi"},
            {settingsList: "generalSettingsDisplay",       itemText:QT_TRANSLATE_NOOP("MENUS", "Display"),            itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconDisplay"},
            {settingsList: "generalSettingsTouch",         itemText:QT_TRANSLATE_NOOP("MENUS", "Touch"),              itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconTouch"},
            {settingsList: "generalSettingsProfiles",      itemText:QT_TRANSLATE_NOOP("MENUS", "Custom Modes"),       itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconProfiles"},
            {settingsList: "generalSettingsStorage",       itemText:QT_TRANSLATE_NOOP("MENUS", "Storage"),            itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconStorage"},
            {settingsList: "generalSettingsSound",         itemText:QT_TRANSLATE_NOOP("MENUS", "Sound"),              itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconSound"},
            {settingsList: "generalSettingsDateTime",      itemText:QT_TRANSLATE_NOOP("MENUS", "Date & Time"),        itemFile:"qrc:///settings/DateTime.qml" , largeIcon: "LargeIconDateTime"},
            {settingsList: "generalSettingsPowerTimeouts", itemText:QT_TRANSLATE_NOOP("MENUS", "Power & Timeouts"),   itemFile:"qrc:///settings/SettingsGeneric.qml" , largeIcon: "LargeIconPowerTimeouts"},
            {settingsList: "generalSettingsSpiritLevel",   itemText:QT_TRANSLATE_NOOP("MENUS", "Spirit Level"),       itemFile:"qrc:///settings/SpiritLevelView.qml", largeIcon: "LargeIconSpiritLevel"},
            {settingsList: "generalSettingsGPS",           itemText:QT_TRANSLATE_NOOP("MENUS", "GPS"),                itemFile:"qrc:///settings/SettingsGeneric.qml",     demo: true, largeIcon: "LargeIconGPS"},
            {settingsList: "generalSettingsLanguage",      itemText:QT_TRANSLATE_NOOP("MENUS", "Language"),           itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconLanguage"},
            {settingsList: "generalSettingsService",       itemText:QT_TRANSLATE_NOOP("MENUS", "Service"),            itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconService"},
            {settingsList: "generalSettingsAbout",         itemText:QT_TRANSLATE_NOOP("MENUS", "About"),              itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconAbout"},
        ];

var cameraSettingsQuality = [
            {editType: SettingType.DROPDOWN,       name: "image_format",  text1: qsTranslate("MENUS", "Image Format"),      demo: false, proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto" },
            {editType: SettingType.DROPDOWN,       name: "jpg_quality",   text1: QT_TRANSLATE_NOOP("MENUS", "JPG Quality"), demo: false, proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto && configstore.image_format !== Config.Raw"},
            {editType: SettingType.DROPDOWN,       name: "jpg_size",      text1: qsTranslate("MENUS", "JPG Size"), text2: qsTranslate("MENUS", "MP"), demo: true, proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto && configstore.image_format !== Config.Raw"},
            {editType: SettingType.DROPDOWN,       name: "color_profile", text1: qsTranslate("MENUS", "Color Profile"),     demo: false, proxy: configstore, enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto && configstore.image_format !== Config.Raw"},
            {editType: SettingType.DROPDOWN,       name: "image_noise",   text1: QT_TRANSLATE_NOOP("MENUS", "Noise Filter"), demo:true, proxy: configstore},
            {editType: SettingType.CHECKBOX,       name: "compress_3fr",  text1: qsTranslate("MENUS", "Compressed 3FR"),    demo:true, proxy: configstore, enableCond: "configstore.image_format !== Config.RawJpg"},
        ];

var cameraMenuItems = [
        {settingsList: "cameraSettingsExposure",        itemText:QT_TRANSLATE_NOOP("MENUS", "Exposure"),            itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconExposure"},
        {settingsList: "cameraSettingsImage",           itemText:QT_TRANSLATE_NOOP("MENUS", "Image"),               itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconImage"},
        {settingsList: "cameraSettingsQuality",         itemText:QT_TRANSLATE_NOOP("MENUS", "Quality"),             itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconQuality"},
        {settingsList: "cameraSettingsAutofocus",       itemText:QT_TRANSLATE_NOOP("MENUS", "Autofocus"),           itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconAutofocus"},
        {settingsList: "cameraSettingsManualFocus",     itemText:QT_TRANSLATE_NOOP("MENUS", "Manual Focus"),        itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconManualFocus"},
        {settingsList: "cameraSettingsGreyBalanceTool", itemText:QT_TRANSLATE_NOOP("MENUS", "White Balance Tool"),  itemFile:"qrc:///components/GreyBalanceTool.qml", largeIcon: "LargeIconGreyBalanceTool", enableCond: "BodySync.currentDialMode !== BodySync.DmFullauto"},
        {settingsList: "cameraSettingsSelfTimer",       itemText:QT_TRANSLATE_NOOP("MENUS", "Self Timer"),          itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconSelfTimer" },
        {settingsList: "cameraSettingsInterval",        itemText:QT_TRANSLATE_NOOP("MENUS", "Interval"),            itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconInterval",   enableCond: "(cambody.capabilities & Cambody.CapabilityContinuousDrive) !== 0"},
        {settingsList: "cameraSettingsBracketing",      itemText:QT_TRANSLATE_NOOP("MENUS", "Exposure Bracketing"), itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconBracketing", enableCond: "(cambody.capabilities & Cambody.CapabilityContinuousDrive) !== 0"},
        {settingsList: "cameraSettingsFocusBracketing", itemText:QT_TRANSLATE_NOOP("MENUS", "Focus Bracketing"),    itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconFocusBracketing", enableCond: "(cambody.capabilities & Cambody.CapabilityContinuousDrive) !== 0"},
        {settingsList: "cameraSettingsLiveView",        itemText:QT_TRANSLATE_NOOP("MENUS", "Live View"),           itemFile:"qrc:///settings/SettingsGeneric.qml", demo: true,  largeIcon: "LargeIconLiveView"},
        {settingsList: "cameraSettingsCustomButtons",   itemText:QT_TRANSLATE_NOOP("MENUS", "Custom Buttons"),      itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconCustomButtons"},
        {settingsList: "cameraSettingsConfiguration",   itemText:QT_TRANSLATE_NOOP("MENUS", "Configuration"),       itemFile:"qrc:///settings/SettingsGeneric.qml", demo: false, largeIcon: "LargeIconConfiguration"},
        {settingsList: "cameraSettingsImageInfo",       itemText:QT_TRANSLATE_NOOP("MENUS", "Image Info"),          itemFile:"qrc:///settings/SettingsGeneric.qml", demo: true,  largeIcon: "LargeIconImageInfo"},
        ];


var videoMenuItems = [
        {settingsList: "videoSettingsVideoQuality", itemText:QT_TRANSLATE_NOOP("MENUS", "Quality"), itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconImageVideoQuality"},
        {settingsList: "videoSettingsAudio",        itemText:QT_TRANSLATE_NOOP("MENUS", "Audio"), itemFile:"qrc:///settings/SettingsGeneric.qml", demo:true, largeIcon: "LargeIconAudio"},
        {settingsList: "videoSettingsLiveView",     itemText:QT_TRANSLATE_NOOP("MENUS", "Live View"), itemFile:"qrc:///settings/SettingsGeneric.qml", largeIcon: "LargeIconVideoLiveView"},
        ];


function getSettingsList(settingsName)
{
    switch(settingsName)
    {
    case "generalSettingsWiFi": return generalSettingsWiFi;
    case "generalSettingsDisplay": return generalSettingsDisplay;
    case "generalSettingsTouch": return generalSettingsTouch;
    case "generalSettingsSound": return generalSettingsSound;
    case "generalSettingsDateTime": return generalSettingsDateTime;
    case "generalSettingsPowerTimeouts": return generalSettingsPowerTimeouts;
    case "cameraSettingsImage": return cameraSettingsImage;
    case "generalSettingsGPS": return generalSettingsGPS;
    case "cameraSettingsExposure": return cameraSettingsExposure;
    case "cameraSettingsQuality": return cameraSettingsQuality;
    case "cameraSettingsAutofocus": return cameraSettingsAutofocus;
    case "cameraSettingsManualFocus": return cameraSettingsManualFocus;
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
    case "generalSettingsService": return generalSettingsService;
    case "generalSettingsAbout": return generalSettingsAbout;
    case "generalSettingsProfiles": return generalSettingsProfiles;
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
