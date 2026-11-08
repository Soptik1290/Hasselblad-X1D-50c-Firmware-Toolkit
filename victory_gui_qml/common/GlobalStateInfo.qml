pragma Singleton
import QtQuick 2.0
import com.hasselblad.camera 1.0
QtObject {
    property bool afSelectionActive: false
    property int afSselectedIndex: -1
    property int afSizeIndex: 0
    property bool testMode: false
    property bool evfActive: false
    property bool waitingForExpose: false
    property bool waitingForLiveView: false
    property bool selfTimerAborted: false
    property bool evfLiveViewWasAutostarted: false
    property string errorPopupOwner: ""
    property int mediaIndex: -1
    property int greyBalanceIndex: -1
    property bool evfInPreview: false
    property bool touchpadZoomActive: false
    property string evfBrowseViewState: ""
    property int imgSwipeDir: 0
    property int imgZoomPanXDir: 0
    property int imgZoomPanYDir: 0
    property int imgPinchDir: 0
    property bool imgPinchActive: false
    property string overlayMode: ""
    property string overlayHeader: ""
    property string overlayText: ""
    property bool preventTopSwipe: false
    property int photosAddedCount: 0
    property bool haveHalfPress: false
    property bool haveLiveViewPress: false
}
