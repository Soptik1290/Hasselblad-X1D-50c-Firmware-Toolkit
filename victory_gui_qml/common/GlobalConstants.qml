import QtQuick 2.0

QtObject {

    id: constants;

    readonly property string helveticaFont: "Helvetica Neue LT Std"

    readonly property string menuItemFontName: helveticaFont
    readonly property string menuSubHeaderFontName: helveticaFont
    readonly property string dialogTextFontName: helveticaFont
    readonly property string cameraControlTextFontName: helveticaFont
    readonly property string metaDataTextFontName: helveticaFont

    readonly property color popupBorderColor : "#646464"
    readonly property color popupFadeoutColor : "black"
    readonly property color popupBackgroundColor : "black"
    readonly property color popupTextColor : "white"

    readonly property color hblOrange: "#de4200" // Non-boosted orange version: "#d95e00"
    // The dark is ONLY used as a border for the on-screen exposure button, when selected.
    readonly property color hblOrangeDark: "#852800" // Non-boosted darkorange version: #823900"

    readonly property color highlightColor : hblOrange
    readonly property color highlightLineColor : "grey"
    readonly property color highlightItemColor : "white"
    readonly property color dialogHeaderColor : "white"
    readonly property color dialogButtonTextColor : "white"
    readonly property color itemColor : "lightgrey"
    readonly property color menuBackgroundColor : "black"
    readonly property color menuItemColor : "white"
    readonly property color menuSubMenuColor : "white"
    readonly property color menuHighlightColor : hblOrange
    readonly property color menuHeaderBackgroundColor : "black"
    readonly property color menuHeaderColor : "white" //#d95e00"
    readonly property color headerColor : "black"
    readonly property color subMenuHeaderColor : "black"
    readonly property color settingLabelColor : "black"
    readonly property color radioButtonBackgroundColor : hblOrange
    readonly property color radioButtonFalseBackgroundColor : "black"
    readonly property color radioButtonBorderColor : "white"
    readonly property color boolSwitchOnColor : hblOrange
    readonly property color  boolSwitchOffColor : "grey"
    readonly property color boolSwitchBorderColor : "white"
    readonly property color boolSwitchButtonColor : "white"
    readonly property color cameraViewBackgroundColor : "black"
    readonly property color cameraViewLineColor : "#58595b"
    readonly property color  cameraViewNormalTextColor : "white"
    readonly property color cameraViewAttentionTextColor : "red"
    readonly property color mainBackgroundColor : "black"
    readonly property color liveViewGridColor : "white"
    readonly property color buttonBorderColor : hblOrange
    readonly property color buttonAreaColor : "transparent"
    readonly property color buttonBorderHighlightColor : "white"
    readonly property color buttonBorderPressedHighlightColor : "black"
    readonly property color buttonAreaPressedColor : "white"
    readonly property color buttonTextColor : "white"
    readonly property color buttonTextPressedColor : "black"
    readonly property color buttonDisabledColor: "#444444"
    readonly property color popoverListViewShadingStartColor : "#a0000000"

    // wedge main screen icons background.
    readonly property color iconsBackWedgeColor: "#222222"
    readonly property int iconsBackWedgeWidth: 160

    readonly property color cardStatusActiveColor : hblOrange
    readonly property color cardStatusNotActiveColor : "black"
    readonly property color cardStatusNotActiveBorderColor : "white"
    readonly property color cardStatusAbsentColor : "black"

    readonly property color videoRecordingColor : "#fb0000"

    readonly property bool useHeaderInList : true
    readonly property bool useTopBottomArrowsInList : false

    readonly property double numberOfItemsVisibleInList : 4.3
    readonly property int  fadeOutDuration : 500

    readonly property double fadeOutOpacity : 0.7

    readonly property string headerTextColor : hblOrange

    // datetime specific objects
    readonly property int timeMonthDayWidth: 160
    readonly property int yearWidth: 300
    readonly property int dateTimeMinMargin: 30

    // Text size for camera view
    readonly property double cameraSettingSmallTextSize : 78.5
    readonly property int cameraSettingSmallLabelSize : 42
    readonly property int cameraSettingLargeTextSize : 137
    readonly property int cameraSettingVerySmallLabelSize : 38
    readonly property int cameraSettingLargeLabelSize : 57//70
    readonly property int minWidthBrackets : 100
    readonly property int cameraViewCFastFontSize : 38
    readonly property int cameraViewFontWeight : 0
    readonly property int cameraViewSettingEVTextSize : 57
    readonly property int cameraViewSettingEVLabelSize : 42
    readonly property int selfTimerCountDownFontSize: 180
    readonly property int intervalTimerCountDownFontSize: 90
    readonly property int bracketingFontSize: 80
    readonly property int focusBracketingFontSize: 60

    readonly property int popoverItemRadius : 15
    // For font weight (cameraViewFontWeight), use one of the following values:
    /*
    Font.Thin	0
    Font.ExtraLight	12
    Font.Light	25 - Works - Default
    Font.Normal	50 - Works
    Font.Medium	57 - Same as Normal
    Font.DemiBold	63 - Same as Bold
    Font.Bold	75 - Works
    Font.ExtraBold	81 - Same as Bold
    Font.Black	87
    */

    // Media Browse View (Meta data)
    readonly property int mediaBrowseFontSize: 34
    readonly property int topMetaHeight : 46
    readonly property int botMetaHeightSimple : topMetaHeight
    readonly property int botMetaHeightDetails : 102/*174*/
    readonly property int botMetaHeightHistoSimple : 174
    readonly property int botMetaHeightHistoDetails : 60
    readonly property int metaDataMargins: 20
    readonly property int metaDataVertOffset: 6//guiconfig.usingUnicodeLanguage ? 0 : 5
    readonly property int metaDataBottomVertOffset: 12
    readonly property int metaDataBottomColSpacing: 8
    readonly property real metaDataOpacity: 0.5
    readonly property int mediaBrowseInfoFontSize: 55

    // Dialogs side button offsets from middle of screen
    readonly property int sideTextCenterMarginFirst: -150
    readonly property int sideTextCenterMarginMiddle: -10
    readonly property int sideTextCenterMarginLast: 122
    readonly property int bottomTextCenterMargin: 163
    readonly property int bottomTextCenterMarginCFV: 135 // Also used for H6D-New-Display (2019-06+)
    readonly property int buttonTextMinDistance: 10

    // Camera View
    readonly property real cameraViewMargin : 13
    readonly property real cameraViewLineTopBottomMargin : 104

    // Exposure button
    readonly property real exposureButtonMargin : 21 //Margin top/left
    readonly property real exposureButtonOffset : cameraViewLineTopBottomMargin //Offset from top of screen

    // Constants for settingsgeneric
    readonly property int radioControlDiameter : 48
    readonly property int checkBoxSize : 32
    readonly property int comboBoxWidth : 200
    readonly property int buttonHeight : 70
    readonly property int menuButtonSpacing : 50
    readonly property real itemTextSize : 40
    readonly property real itemTextSizeMenuLevel1 : 55
    readonly property real headerTextSize : 20
    readonly property real contentTextSize : 24
    readonly property int splashBorderWidth: 16
    readonly property int splashContentSpacing: 10
    readonly property int splashContentLeftMargin: 40
    readonly property real sectionHeaderTextSize : 58
    readonly property int dropDownBoxHeight: 55
    readonly property int headerLineThickness : 2
    readonly property int headerVerticalOffset : 30 // Distance between top and text
    readonly property int highlightMoveDuration : 50
    readonly property double itemCountInListView : 4.5
    readonly property int leftMarginForItems : 50

    // Threshold when settings screen should start to drag
    readonly property int dragThreshold : 20
    readonly property int wheelTimeoutTimeMs : 10000

    // Timeout for zoom indicator
    readonly property int zoomIndicatorTimeout: 4000

    // Blink characteristics
    readonly property int animationDurationBlink : 75
    readonly property int animationBlinkLoops : 2
    readonly property int animationErrorBlinkLoops : 3

    readonly property int liveViewGridCount : 3
    readonly property int liveViewGridLineWidth : 2

    // How long we have to swipe before change takes effect. Dividor of total swipe length
    readonly property int swipeLengthDividor : 5

    // Exposure adjust
    readonly property int outerBoxRadius : 0
    readonly property int sliderThickness : 3

    // Menu level 1
    readonly property int bracketThickness : 3

    readonly property int dialogButtonBorderThickness : 3
    readonly property color dialogButtonBorderColor : hblOrange
    readonly property int dialogButtonBackgroundHeight: 75
    readonly property int dialogButtonVerticalOffset: 4

    readonly property int popupBorderWidth : 2
    readonly property int popupHeaderTextSize : 20
    readonly property real popupSideMargins : 72
    readonly property int popupGridSpacing : 3
    readonly property real popupBottomMargin : 5    // NOTE: Dependent on popupBottomTextMargin, should be reduced as much as popupBottomTextMargin is increased
    readonly property real popupBottomTextMargin : 10

    readonly property int batteryBlinkTimeMs : 500
    readonly property int cardStatusIconSize : 31
    readonly property int cardStatusIconBorderSize : 2
    readonly property int dialogLargeTextSize : 40
    readonly property int dialogMediumTextSize : 35
    readonly property int menuItemIconLeftMargin : 58

    // These two are dependent of default font used (and indirectly the language used).
    readonly property int subSettingYOffset : guiconfig.usingUnicodeLanguage ? 0 : 7
    readonly property int listSelectorYOffsetUnicode: 0
    readonly property int listSelectorYOffsetAscii: 6


    // For drop down items in setting sub menus
    readonly property int subSettingDropDownXMargin : 10 // Higher value moves text to the left
    readonly property int subSettingDropDownSpacing : 15 // Higher value moves drop down list to the right
    readonly property int subSettingDropDownSecondTextSpacing : 15 // Higher value moves second text to the right

    readonly property int errorDialogLargeTextSize: 55
    readonly property int errorDialogSubTextSize: 45
    readonly property int errorDialogBottomTextSize: 30

    // How long AV and TV should show in instant preview when changed
    readonly property int avtvTimeMs : 2000

    // Delay for Settings swiping in from the right
    readonly property int menuSwipeDuration : 200

    // Swipe height for control screen, i.e. vertical size of top swipe area when swiping down control screen
    readonly property real swipeHeightShort: 10
    readonly property real swipeHeightNormal: 51

    property real zoomIndicatorSizeFactor: 0.25
    readonly property real evfTextSize : 49

    readonly property int viewEndLineWidth: 3
    readonly property int numberZoomSteps: 10
    readonly property int zoomAnimateTime: 200
    readonly property int zoomScaleAnimateTime: 25
    readonly property int zoomFullAnimateTime: 500

    readonly property real listViewSizeIncreaseFactor: 0.3

    // Spirit Level
    readonly property int spiritLineWidth: 1
    readonly property int spiritBorderWidth: 2
    readonly property int spiritMarkerBorderWidth: 1
    readonly property int spiritMarkerAxisDist: 6
    readonly property int spiritBarWidth: 91
    readonly property int spiritBarHeight: 544
    readonly property color spiritMarkerColor: "#39b54a"
    readonly property real spiritBarMaxDegrees: 6.0
    readonly property real spiritBarMaxGoodDegrees: 0.1

    // HDMI
    readonly property int hdmiStartLiveViewTextSize: 90

    //Focus point size
    readonly property var focusSize: [39322050, 55050870, 78644100] //2x2mm, 2.8x2.8mm, 4x4mm
    readonly property var focusSizeXCount: [13, 9, 7]
    readonly property var focusSizeYCount: [9, 7, 5]
    readonly property real focusGridXMarginPercent : 1/9 // X margin from screen border to grid for original 5x7 grid, use this margin for all sizes
    readonly property real focusGridYMarginPercent : 1/7 // Y margin from screen border to grid for original 5x7 grid, use this margin for all sizes

    // Live View
    readonly property int liveViewImageTimeoutDefault: 3 * 60
    readonly property int liveViewImageMaxTimeoutSU: 30
    readonly property int liveViewImageTimeoutA6D: 30 * 60
    readonly property int afSelectionLongPressThreshold: 350
    readonly property int liveViewBorderNormalMargin: 30

    // Brightness when black screens
    readonly property int blackScreenBrightness: 9
}
