pragma Singleton
import QtQuick 2.0
import com.hasselblad.camera 1.0

// This object holds global state information.
// It is a singleton to make it easy to access from both EVFWindow and TouchWindow children
// Primarily intended to be used for state info that should be transferred between EVFWindow and TouchWindow

// To use:
// import com.hasselblad.globalstateinfo 1.0


QtObject {


    // For AF selection point:
    property bool afSelectionActive: false
    property int afSselectedIndex: -1
    property int afSizeIndex: 0
    property bool testMode: false //Used to override timers etc when testing

    property bool evfActive: false
    property bool waitingForExpose: false //Handle gap between expose is set and when it can be read with correct value
    property bool waitingForLiveView: false //Handle gap between Camera.exposing->false and liveview->on
    property bool selfTimerAborted: false
    property bool evfLiveViewWasAutostarted: false
    property string errorPopupOwner: "" //Keep track of if evf or main which had focus when errorPopup was activated
    property int mediaIndex: -1 //CurrentIndex in MediaBrowseView
    property int greyBalanceIndex: -1 //start index for GreyBalanceTool
    property bool evfInPreview: false
    property bool touchpadZoomActive: false
    property string evfBrowseViewState: "" //The current state for the MediaBrowseView used in the EVFWindow
    property int imgSwipeDir: 0 //Swipe direction (left/right) when swiping images in 1view. Sent from BrowseTouchpad
    property int imgZoomPanXDir: 0 //X-direction for panning in zoomed-in image. Sent from BrowseTouchpad
    property int imgZoomPanYDir: 0 //Y-direction for panning in zoomed-in image. Sent from BrowseTouchpad
    property int imgPinchDir: 0 //Pinch direction (in/out) when pinching image. Sent from BrowseTouchpad
    property bool imgPinchActive: false //Pinch active. Sent from BrowseTouchpad
    property string overlayMode: "" //Mode for showing global overlay header/text on top of active screen for a few seconds
    property string overlayHeader: "" //Header text for global overlay
    property string overlayText: ""   //Info text for global overlay
    property bool preventTopSwipe: false
    property int photosAddedCount: 0
    property bool haveHalfPress: false
    property bool haveLiveViewPress: false
    property bool haveAfDrive: false
    property bool afcLoopActive: false
    property bool afcHasLocked: false
    property int afcGatedState: 0
    property int afcPeakCv: 24000
    property int afcCurrCv: 24000
    property int afcLensPos: 1000
    property int afcTrackDir: 1
    property int lastAutoFocusMode: 1
}

