// Wedge specific key mappings.

// This is the mapping of keys to specific camera functions. It is possible to specify the same physical key several
// times in this array, because it can be assigned to different meanings depending on the currently displayed context.
// For instance, F2 on MainScreen means go to CameraMenu, while on most confirmation dialogs it means "Exit" instead.
// Note that the functions logKeyItem(), camFnFromKey(), pressedKeyFn() and pressedKeyLabel() are available as helpers in Keys.js.
// However, the best way to "compare" whether a key has been pressed is by directly indexing the direct key-property, e.g.:
// if(event.key === CAMKEYS[EXIT].key) {...}
var CAMKEYS = {
    MENU:        { name: "Menu",         key: [ Qt.Key_F1 ] },
    CROSS:       { name: "Cross",        key: [ Qt.Key_F2 ] },
    STAR:        { name: "Star",         key: [ Qt.Key_F3 ] },
    SQUARE:      { name: "Square",       key: [ Qt.Key_F4 ] },
    F2:          { name: "F2",           key: [ Qt.Key_F4 ] },
    F4:          { name: "F4",           key: [ Qt.Key_F2 ] },
    PLAY:        { name: "Play",         key: [ Qt.Key_F5 ] },
    BROWSE:      { name: "Browse",       key: [ Qt.Key_F5 ] },
    ESCAPE:      { name: "Escape",       key: [ Qt.Key_Escape, Qt.Key_L ] },
    DLGEXIT:     { name: "Exit",         key: [ Qt.Key_F2, Qt.Key_Escape, Qt.Key_L ] },
    ABORT:       { name: "Abort",        key: [ Qt.Key_F2, Qt.Key_Escape ] },
    DLGACCEPT:   { name: "Accept",       key: [ Qt.Key_F4 ] },
    HALFPRESS:   { name: "Halfpress",    key: [ Qt.Key_A ] },
    EXPOSURE:    { name: "Exposure",     key: [ Qt.Key_E ] },
    SELECT:      { name: "Select",       key: [ Qt.Key_Enter, Qt.Key_Return, Qt.Key_F3, Qt.Key_D ] },
    ENTER:       { name: "Select",       key: [ Qt.Key_Enter, Qt.Key_Return, Qt.Key_D ] },
    AE_L:        { name: "AE-L",         key: [ Qt.Key_L ] },
    AF_D:        { name: "AF-D",         key: [ Qt.Key_D ] },
    AF_MF:       { name: "AF-MF",        key: [ Qt.Key_F ] },
    ISO_WB:      { name: "ISO-WB",       key: [ Qt.Key_I ] },
    TOGGLESLEEP: { name: "ToggleSleep",key: [ Qt.Key_F9 ] },
    // The following is for keys reaching EVF window only during sleep mode.
    WAKEUP:      { name: "Wakeup",        key: [ Qt.Key_F9, Qt.Key_F1, Qt.Key_F2, Qt.Key_F3, Qt.Key_F4, Qt.Key_F5, Qt.Key_A, Qt.Key_E ] },
    // The 'NAV' mappings are for navigation in menus and popovers, but not only for the scroll wheel (cursor keys), but
    // also for any other keys that might be suitable for the direction.
    NAVRIGHT:    { name: "NavRight",     key: [ Qt.Key_F2, Qt.Key_Right ] },
    NAVLEFT:     { name: "NavLeft",      key: [ Qt.Key_F4, Qt.Key_Left ] },
    NAVDOWN:     { name: "NavDown",      key: [ Qt.Key_F2, Qt.Key_Down ] }, // NOTE: NAV UP/DOWN are NOT used in the same context as LEFT/RIGHT
    NAVUP:       { name: "NavUp",        key: [ Qt.Key_F4, Qt.Key_Up ] },
    // Navigating in popups
    POPLEFT:     { name: "PopLeft",      key: [ Qt.Key_F4, Qt.Key_Up, Qt.Key_Left ] },
    POPRIGHT:    { name: "PopRight",     key: [ Qt.Key_F2, Qt.Key_Down, Qt.Key_Right ] },
    // Navigating in lists
    LISTUP:      { name: "ListUp",       key: [ Qt.Key_F4, Qt.Key_Up, Qt.Key_Left ] },
    LISTDOWN:    { name: "ListDown",     key: [ Qt.Key_F2, Qt.Key_Down, Qt.Key_Right ] },
    // These are the exact wheel mappings for navigation, without any additional special keys.
    HORZ:        { name: "Horz",         key: [ Qt.Key_Left, Qt.Key_Right ] },
    VERT:        { name: "Vert",         key: [ Qt.Key_Up, Qt.Key_Down ] },
    RIGHT:       { name: "Right",        key: [ Qt.Key_Right ] },
    LEFT:        { name: "Left",         key: [ Qt.Key_Left ] },
    DOWN:        { name: "Down",         key: [ Qt.Key_Down ] },
    UP:          { name: "Up",           key: [ Qt.Key_Up ] },
    POPACCEPT:   { name: "PopAccept",    key: [ Qt.Key_F3, Qt.Key_A, Qt.Key_D ] },
    // ModeWheel (DialMode)
    MANUALQ:     { name: "ManualQuick",  key: [ Qt.Key_0 ] },
    MANUAL:      { name: "ManualQuick",  key: [ Qt.Key_1 ] },
    AUTO:        { name: "Auto",         key: [ Qt.Key_2 ] },
    SHUTTERS:    { name: "ShutterSpeed", key: [ Qt.Key_3 ] },
    PROGRAM:     { name: "Program",      key: [ Qt.Key_4 ] },
    FULLAUTO:    { name: "FullAuto",     key: [ Qt.Key_5 ] },
    VIDEO:       { name: "Video",        key: [ Qt.Key_6 ] },
    CUSTOM1:     { name: "Custom1",      key: [ Qt.Key_7 ] },
    CUSTOM2:     { name: "Custom2",      key: [ Qt.Key_8 ] },
    CUSTOM3:     { name: "ManualQuick",  key: [ Qt.Key_9 ] },
    ANYMODE:     { name: "ModeWheel",    key: [ Qt.Key0, Qt.Key1, Qt.Key2, Qt.Key3, Qt.Key4, Qt.Key5, Qt.Key6, Qt.Key7, Qt.Key8, Qt.Key9 ] },
    STOPDOWN:    { name: "StopDown",     key: [ Qt.Key_S ] },
    OVEREXP:     { name: "OverExposure", key: [ Qt.Key_O ] },
    AFPOINTSEL:  { name: "AfPointSelect",key: [ Qt.Key_P ] },
    BROWSEMODE:  { name: "BrowseMode",   key: [ Qt.Key_B ] },
    RECORD:      { name: "StartRecVideo",key: [ Qt.Key_R ] },
    AFPCYCLE:    { name: "CycleAfPoint" ,key: [Qt.Key_Period] },
    AUTOISO:     { name: "AutoISOMenu",  key: [Qt.Key_M] },
    ISO:         { name: "ISO",          key: [Qt.Key_C] },
    WB:          { name: "WB",           key: [Qt.Key_G] },
    SPIRITLEVEL: { name: "SPIRITLEVEL",  key: [Qt.Key_Y] },
    WIFI:      { name: "Wi-Fi",        key: [Qt.Key_W] },
    OVERLAY:   { name: "Overlay",      key: [Qt.Key_J] },
    ESHUTTER:  { name: "Eshutter",     key: [Qt.Key_H] },
    SELFTIMER: { name: "Selftimer",    key: [Qt.Key_T] },
    LIVEVIEW:  { name: "Liveview",     key: [Qt.Key_K] },
    FORMAT:    { name: "Format",       key: [Qt.Key_F11] },
    CTRLSCREEN:{ name: "ControlScreen", key: [ Qt.Key_V] },
    DELETE:    { name: "Delete",       key: [Qt.Key_Delete] },
    ZOOM_IN:   { name: "Zoom In",      key: [Qt.Key_Z] },
    EXP_CUSTOM:{ name: "Exposure",     key: [Qt.Key_X] },
    CROPMODENEXT:  { name: "CropModeNext",     key: [ Qt.Key_CapsLock ] },
    CROPMODEPREV:  { name: "CropModePrevious",     key: [ Qt.Key_Print ] },
    TPDOUBLECLICK: { name: "Touchpad double-click",key: [ Qt.Key_ScrollLock ] }, //Used by BrowseTouchpad.qml to simulate a keypress
    INTERVAL:      { name: "Interval",    key: [ Qt.Key_Minus ] },
    BRACKETING:    { name: "Bracketing",  key: [ Qt.Key_Equal ] },
    GREYBALANCE:   { name: "GreyBalance", key: [ Qt.Key_Pause ] },
    FOCUSBRACKETING:   { name: "FocusBracketing", key: [ Qt.Key_U ] },
    DRIVETOINF:    { name: "DriveToInf",  key: [ Qt.Key_Q ] },
    DRIVETONEAR:   { name: "DriveToNear", key: [ Qt.Key_N ] },
    CYCLEFOCUSSCANRANGE:   { name: "CycleFocusScanRange", key: [ Qt.Key_F6 ] },
};
