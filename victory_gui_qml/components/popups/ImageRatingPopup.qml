import QtQuick 2.5

import com.hasselblad.storage 1.0
import com.hasselblad.config 1.0
import com.hasselblad.farm 1.0

import "qrc:///components"
import "qrc:///scripts/Keys.js" as MKeys

Item {
    id: root
    objectName: "ImageRatingPopup_root"

    property int startValue: Config.RatingUnknown
    property int rating: Config.RatingUnknown
    property string name: ""
    property bool filterIconSelected: false
    property bool modified: false
    signal openFilter()

    function saveRating() {
        if (modified && rating >= 0) {
            var path = ContentModel.path + "/" + name
            console.log("ImageRatingPopup: Store rating", rating, "image:", path)
            ContentModel.setImageRating(path, rating)
            modified = false
        }
    }

    // Abort if card is removed
    Connections{
        target: SortedContentModel
        onListSizeChanged: {
            if (visible) {
                imageRatingActive = false
            }
        }
    }

    Connections{
        target: media_list
        onCurrentIndexChanged: {
            if (visible) {
                //Will be called for both old and new currentIndex, but since we only save if rating
                //have changed the new currentIndex will not trigger a save.
                root.saveRating()
            }
        }
    }

    onStartValueChanged: {
        rating = startValue
        modified = false
    }

    Row {
        id: starRow
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 90
        spacing: 20
        Repeater {
            model: 5
            Image {
                property bool selected: index < rating
                source: selected ? "qrc:///icons/RatingStar_Large_selected_75.png" : "qrc:///icons/RatingStar_Large_unselected_75.png"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        modified = true
                        rating = (index === 0 && rating === 1) ? 0 : index+1
                    }
                }
            }
        }
    }

    Keys.onPressed: {
        event.accepted = true
        if(MKeys.pressedFn("DOWN", event.key) || MKeys.pressedFn("SQUARE", event.key)) {
            modified = true
            rating = rating < 0 ? 1 :
                     rating < 6 ? rating+1 : 6
        }
        else if(MKeys.pressedFn("STAR", event.key)) {
            if (filterIconSelected) {
                openFilter()
                filterIconSelected = false
            } else {
                saveRating()
                imageRatingActive = false
            }
            event.accepted = true
        }
        else if(MKeys.pressedFn("UP", event.key) || MKeys.pressedFn("CROSS", event.key)) {
            modified = true
            rating = rating < 0 ? 0 :
                     rating > 0 ? rating-1 : 0
        }
        else if (MKeys.pressedFn("CROSS", event.key) || MKeys.pressedFn("SQUARE", event.key)) {
            //Disable image filtering for now
            //filterIconSelected = !filterIconSelected
        }
        else if (MKeys.pressedFn("MENU", event.key) || MKeys.pressedFn("HALFPRESS", event.key) || MKeys.pressedFn("BROWSE", event.key)) {
            //Save rating but do not block the keys here
            saveRating()
            imageRatingActive = false
            event.accepted = false
        }
        else {
            event.accepted = false
        }
    }

    // Located in MediaBrowseView instead since the button texts will follow swipes if used here
    /*ConfirmationButtons { ... }*/

    Component.onDestruction: {
        if (modified) {
            saveRating()
        }
    }
}

