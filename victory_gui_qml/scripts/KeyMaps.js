
// Victory or "generic" mappings.

// This is the mapping of keys to specific camera functions. It is possible to specify the same physical key several
// times in this array, because it can be assigned to different meanings depending on the currently displayed context.
// For instance, F2 on MainScreen means go to CameraMenu, while on most confirmation dialogs it means "Exit" instead.
// Note that the functions log(), camFnFromKey(), pressedFn() and pressedLabel() are available as helpers in Keys.js
// However, the best way to "compare" whether a key has been pressed is by directly indexing the direct key-property, e.g.:
// if(event.key === CAMKEYS[EXIT].key) {...}
var CAMKEYS = {
    MENU:        { name: "Menu",          key: [ Qt.Key_F1 ] },
    CROSS:       { name: "CamMenu",       key: [ Qt.Key_F2 ] },
    STAR:        { name: "Star",          key: [ Qt.Key_F3 ] },
    SQUARE:      { name: "Square",        key: [ Qt.Key_F4 ] },
    F2:          { name: "F2",            key: [ Qt.Key_F2 ] },
    F4:          { name: "F4",            key: [ Qt.Key_F4 ] },
    PLAY:        { name: "Play",          key: [ Qt.Key_F5 ] },
    BROWSE:      { name: "Browse",        key: [ Qt.Key_F5 ] },
    ESCAPE:      { name: "Escape",        key: [ Qt.Key_Escape ] },
    DLGEXIT:     { name: "Exit",          key: [ Qt.Key_F2, Qt.Key_Escape ] },
    DLGACCEPT:   { name: "Accept",        key: [ Qt.Key_F4 ] },
    ABORT:       { name: "Abort",         key: [ Qt.Key_F2, Qt.Key_Escape ] },
    FORMAT:      { name: "Format",        key: [ Qt.Key_F11 ] },
    HALFPRESS:   { name: "Halfpress",     key: [ Qt.Key_F12 ] },
    EXPOSURE:    { name: "Exposure",      key: [ Qt.Key_E ] },
    TRUEFOCUS:   { name: "TrueFocus",     key: [ Qt.Key_Enter, Qt.Key_Return ] },
    SELECT:      { name: "Select",        key: [ Qt.Key_Enter, Qt.Key_Return, Qt.Key_F3 ] }, // TrueFocus, STAR or Enter
    ENTER:       { name: "Select",        key: [ Qt.Key_Enter, Qt.Key_Return ] },
    // The 'NAV' mappings are for navigation in menus and popovers, but not only for the scroll wheel (cursor keys), but
    // also for any other keys that might be suitable for the direction.
    NAVRIGHT:    { name: "NavRight",      key: [ Qt.Key_F4, Qt.Key_Right ] },
    NAVLEFT:     { name: "NavLeft",       key: [ Qt.Key_F2, Qt.Key_Left ] },
    NAVDOWN:     { name: "NavDown",       key: [ Qt.Key_F4, Qt.Key_Down ] }, // NOTE: NAV UP/DOWN are NOT used in the same context as LEFT/RIGHT
    NAVUP:       { name: "NavUp",         key: [ Qt.Key_F2, Qt.Key_Up ] },
    // Navigating in popups
    POPLEFT:     { name: "PopLeft",       key: [ Qt.Key_F2, Qt.Key_Left ] },
    POPRIGHT:    { name: "PopRight",      key: [ Qt.Key_F4, Qt.Key_Right ] },
    // Navigating in lists
    LISTUP:      { name: "ListUp",        key: [ Qt.Key_F2, Qt.Key_Up, Qt.Key_Left ] },
    LISTDOWN:    { name: "ListDown",      key: [ Qt.Key_F4, Qt.Key_Down, Qt.Key_Right ] },
    // These are the exact wheel mappings for navigation, without any additional special keys.
    HORZ:        { name: "Horz",          key: [ Qt.Key_Left, Qt.Key_Right ] },
    VERT:        { name: "Vert",          key: [ Qt.Key_Up, Qt.Key_Down ] },
    RIGHT:       { name: "Right",         key: [ Qt.Key_Right ] },
    LEFT:        { name: "Left",          key: [ Qt.Key_Left ] },
    DOWN:        { name: "Down",          key: [ Qt.Key_Down ] },
    UP:          { name: "Up",            key: [ Qt.Key_Up ] },
    POPACCEPT:   { name: "PopAccept",     key: [ Qt.Key_F3, Qt.Key_F12, Qt.Key_Enter, Qt.Key_Return ] },
    DELETE:      { name: "Delete",        key: [ Qt.Key_Delete ] },
    SPIRITLEVEL: { name: "SpiritLevel",   key: [ Qt.Key_Y] },
    OVEREXP:     { name: "OverExposure",  key: [ Qt.Key_O ] },
    BROWSEMODE:  { name: "BrowseMode",    key: [ Qt.Key_B ] },
    PROFILES:    { name: "ProfilesMenu",  key: [ Qt.Key_NumLock ] },
    CTRLSCREEN:  { name: "ControlScreen", key: [ Qt.Key_V] },
    CROPMODENEXT:  { name: "CropModeNext",     key: [ Qt.Key_CapsLock ] },
    CROPMODEPREV:  { name: "CropModePrevious", key: [ Qt.Key_Print ] },
    INTERVAL:    { name: "Interval",      key: [ Qt.Key_Minus ] },
    BRACKETING:  { name: "Bracketing",    key: [ Qt.Key_Equal ] },
    GREYBALANCE: { name: "GreyBalance", key: [ Qt.Key_Pause ] },
};
