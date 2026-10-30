import QtQuick 2.5

import com.hasselblad.globalstateinfo 1.0
import com.hasselblad.config 1.0
import com.hasselblad.camera 1.0

/* Object for sharing properties/functions used by:
  - AFPointSelection
  - EVFTouchpad
*/

Item {
    id: afc
    property int screenWidth: 0
    property int screenHeight: 0
    property bool isActive: false //If this is the active instance (we have multiple instances)
    property int xPanYCountAdjust: GlobalStateInfo.afSizeIndex === 0 ? 2 : 1
    property int cropXCountAdjust: (configstore.aspectRatio === Config.Ratio1to1) ? 1 : 0
    property int cropYCountAdjust: (configstore.aspectRatio === Config.Ratio2to1) ? 1 :
                                   (configstore.aspectRatio === Config.Ratio65to24) ? xPanYCountAdjust : 0
    property int defaultXCount: constants.focusSizeXCount[GlobalStateInfo.afSizeIndex]
    property int defaultYCount: constants.focusSizeYCount[GlobalStateInfo.afSizeIndex]
    property int defaultGridXMargin: screenWidth * constants.focusGridXMarginPercent //X margin from screen border to grid for original 5x7 grid, use this margin for all sizes
    property int defaultGridYMargin: screenHeight * constants.focusGridYMarginPercent //Y margin from screen border to grid for original 5x7 grid, use this margin for all sizes
    property real afItemWidth: (screenWidth - 2*defaultGridXMargin) / defaultXCount
    property real afItemHeight: (screenHeight - 2*defaultGridYMargin) / defaultYCount
    property int gridXMargin: defaultGridXMargin + cropXCountAdjust*afItemWidth
    property int gridYMargin: defaultGridYMargin + cropYCountAdjust*afItemHeight
    property int xCount: defaultXCount - 2*cropXCountAdjust
    property int yCount: defaultYCount - 2*cropYCountAdjust
    property int selectedXIndex: (Camera.firstComponent(Camera.focus_point)*screenWidth - gridXMargin) / afItemWidth
    property int selectedYIndex: (Camera.secondComponent(Camera.focus_point)*screenHeight - gridYMargin) / afItemHeight
    property int afSselectedXIndex : GlobalStateInfo.afSselectedIndex % xCount
    property int afSselectedYIndex : GlobalStateInfo.afSselectedIndex / xCount
    property string idText: ""
    // Used to temporarily store indexes when cycling through focus sizes:
    property var savedIndexes : [-1, -1, -1]
    property int prevCropMode: -1
    property int prevXCount: -1
    property int prevYCount: -1

    onIsActiveChanged: {
        if (isActive) {
            resetSavedIndexes()
        }
    }

    function resetSavedIndexes()
    {
        savedIndexes = [-1, -1, -1]
        prevXCount = xCount
        prevYCount = yCount
    }

    function resetPosition() {
        var xIndex = Math.floor(xCount / 2)
        var yIndex = Math.floor(yCount / 2)
        GlobalStateInfo.afSselectedIndex = xIndex + yIndex * xCount
    }

    function selectAndSave()
    {
        // Find x and y points
        var xPoint = (gridXMargin + ((GlobalStateInfo.afSselectedIndex % xCount) + 0.5) * afItemWidth) / screenWidth
        var yPoint = (gridYMargin + (Math.floor(GlobalStateInfo.afSselectedIndex / xCount) + 0.5) * afItemHeight) / screenHeight
        Camera.focus_point = Camera.combine(xPoint, yPoint)
    }

    function setNextSize()
    {
        //Keep track of x,y for currently selected position (which may not be saved as a focus_point yet).
        //Cannot save to focus_point here since we need the updated value immediately so do calculation locally instead
        //of reusing functions based on focus_point and focus_size.
        var origX = ((GlobalStateInfo.afSselectedIndex % xCount) + 0.5) * afItemWidth
        var origY = (Math.floor(GlobalStateInfo.afSselectedIndex / xCount) + 0.5) * afItemHeight
        savedIndexes[GlobalStateInfo.afSizeIndex] = GlobalStateInfo.afSselectedIndex
        GlobalStateInfo.afSizeIndex = ((GlobalStateInfo.afSizeIndex + constants.focusSize.length - 1) % constants.focusSize.length)
        if(savedIndexes[GlobalStateInfo.afSizeIndex] < 0)
        {
            GlobalStateInfo.afSselectedIndex = Math.floor(origX / afItemWidth) + Math.floor(origY / afItemHeight)*xCount
            //We may end up outside the grid when calculating afSselectedIndex based on previous x,y coordinate after
            //changing point size in some crop modes
            var xCorrection = (origX >= xCount*afItemWidth) ? -1 :
                              (origX < 0) ? 1 : 0
            var yCorrection = (origY >= yCount*afItemHeight) ? -1 :
                              (origY < 0) ? 1 : 0
            if (xCorrection !== 0 || yCorrection !== 0) {
                GlobalStateInfo.afSselectedIndex = GlobalStateInfo.afSselectedIndex + xCorrection + yCorrection*xCount
            }
        }
        else
        {
            GlobalStateInfo.afSselectedIndex = savedIndexes[GlobalStateInfo.afSizeIndex]
        }
        configstore.focus_size = constants.focusSize[GlobalStateInfo.afSizeIndex]
        selectAndSave()
        prevXCount = xCount
        prevYCount = yCount
    }

    function updateSizeIndex() {
        for (var i = 0; i < constants.focusSize.length; i++) {
            if (configstore.focus_size === constants.focusSize[i]) {
                GlobalStateInfo.afSizeIndex = i
                return
            }
        }
        GlobalStateInfo.afSizeIndex = 0
    }

    function setStartPoint()
    {
        GlobalStateInfo.afSselectedIndex = selectedXIndex + selectedYIndex * xCount
        resetSavedIndexes()
    }

    Connections {
        target: configstore
        onAspectRatioChanged: cropModeChanged()
    }

    Connections {
        target: configstore
        onFocusSizeChanged: {
            if (afc.isActive && GlobalStateInfo.afSselectedIndex === -1) {
                //AF point size has been cycled with custom button when grid is hidden. Need to update position even if
                //grid is hidden since we need the position when calculating grid changes due to crop mode change
                updateSizeIndex()
                //We may end up outside the grid when calculating afSselectedIndex based on focus point after
                //changing point size in some crop modes
                var xCorrection = (selectedXIndex >= xCount) ? -1 :
                                 (selectedXIndex < 0) ? 1 : 0
                var yCorrection = (selectedYIndex >= yCount) ? -1 :
                                 (selectedXIndex < 0) ? 1 : 0

                GlobalStateInfo.afSselectedIndex = selectedXIndex + xCorrection + (selectedYIndex + yCorrection) * xCount
                resetSavedIndexes()
                if (xCorrection !== 0 || yCorrection !== 0) {
                    selectAndSave()
                }
            }
        }
    }

    function cropModeChanged() {
        var newCropMode = configstore.aspectRatio

        if (afc.isActive) {
            if (GlobalStateInfo.afSselectedIndex >= 0) {
                var afIndex = calculateNewAFSelectedIndex(GlobalStateInfo.afSselectedIndex, prevXCount, prevYCount, prevCropMode, newCropMode)
                if (GlobalStateInfo.afSselectedIndex !== afIndex) {
                    GlobalStateInfo.afSselectedIndex = afIndex
                }
                //Always save since focus_point may need to change even when the afSselectedIndex is unchanged
                selectAndSave()

                //Changing grid size will make savedIndexes invalid -> reset them.
                if (prevXCount !== xCount || prevYCount !== yCount) {
                    resetSavedIndexes()
                }
            }
        }
        prevCropMode = newCropMode
        prevXCount = xCount
        prevYCount = yCount
    }

    function calculateNewAFSelectedIndex(oldAFIndex, oldXCount, oldYCount, oldCropMode, newCropMode) {
        var retVal = oldAFIndex
        var yAdjustCount = 0
        var xAdjustCount = (newCropMode === Config.Ratio1to1) ? -1 :
                           (oldCropMode === Config.Ratio1to1) ? 1 : 0
        if (newCropMode === Config.Ratio65to24) {
            if (oldCropMode === Config.Ratio2to1) {
                yAdjustCount = (GlobalStateInfo.afSizeIndex === 0) ? -1 : 0
            } else {
                yAdjustCount = (GlobalStateInfo.afSizeIndex === 0) ? -2 : -1
            }
        }
        else if (newCropMode === Config.Ratio2to1) {
            if (oldCropMode === Config.Ratio65to24) {
                yAdjustCount = (GlobalStateInfo.afSizeIndex === 0) ? 1 : 0
            } else {
                yAdjustCount = -1
            }
        } else { //Any other crop mode wich doesn't affect the grid
            if (oldCropMode === Config.Ratio65to24) {
                yAdjustCount = (GlobalStateInfo.afSizeIndex === 0) ? 2 : 1
            } else if (oldCropMode === Config.Ratio2to1) {
                yAdjustCount = 1
            } else {
                yAdjustCount = 0
            }
        }
        //Keep for debugging
        //console.log("==== newCropMode",newCropMode,"oldCropMode", oldCropMode)
        //console.log("==== new xCount, yCount",xCount, yCount,"prev xCount, yCount", oldXCount, oldYCount)
        //console.log("==== yAdjustCount",yAdjustCount, "xAdjustCount",xAdjustCount, "afSselectedIndex", oldAFIndex)
        var xCorrection = 0
        var yCorrection = 0
        if (xAdjustCount !== 0) {
            if (xAdjustCount > 0) {
                xCorrection = 2*Math.floor(oldAFIndex / oldXCount) + 1
            } else {
                var borderAdjust = (oldAFIndex % oldXCount == 0) ? 0 :
                               (oldAFIndex % oldXCount == oldXCount-1) ? 2 : 1
                xCorrection = -(2*Math.floor(oldAFIndex / oldXCount) + borderAdjust)
            }
            //Pretend that the new xCount already was present before the crop change to simplify
            // the yAdjust calculations below
            oldXCount = oldXCount + 2*xAdjustCount
            oldAFIndex = oldAFIndex + xCorrection
            //console.log("recalculated oldXCount", oldXCount, "oldAFIndex", oldAFIndex)
        }
        if (yAdjustCount > 0) {
            yCorrection = yAdjustCount*oldXCount
        } else if (yAdjustCount < 0) {
            if (oldAFIndex >= oldXCount*(oldYCount+yAdjustCount)) {
                yCorrection = 2*yAdjustCount*oldXCount
            } else if (oldAFIndex >= oldXCount*(-yAdjustCount)) {
                yCorrection = yAdjustCount*oldXCount
            }
        }
        return oldAFIndex + yCorrection
    }

    Component.onCompleted: {
        updateSizeIndex()
        if (GlobalStateInfo.afSselectedIndex < 0) {
            setStartPoint()
        }
        prevCropMode = configstore.aspectRatio
        prevXCount = xCount
        prevYCount = yCount
    }
}
