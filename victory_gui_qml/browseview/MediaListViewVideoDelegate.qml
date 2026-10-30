import QtQuick 2.0
import com.hasselblad.storage 1.0
import com.hasselblad.video 1.0
import com.hasselblad.config 1.0

import "qrc:///components/buttons"
import "qrc:///scripts/Keys.js" as MKeys

Rectangle {
    id: list_delegate
    objectName: "MediaListViewVideoDelegate"
    anchors.fill: parent
    color: "black"
    focus: true
    property alias loadImage: overlay.loadImage

    signal loaded()
    signal playbackVideo()
    signal stopPlaybackVideo()
    signal openImageRateFilter()

    MouseArea {
        anchors.fill: parent
        onClicked: list_delegate.playbackVideo()
    }

    Keys.onPressed: {
        if(MKeys.pressedFn("HALFPRESS", event.key))
        {
            if(VideoControl.videoMode === VideoControl.Playback)
            {
                list_delegate.stopPlaybackVideo()
                event.accepted = false
            }
        }
        else if(MKeys.pressedFn("ESCAPE", event.key) || MKeys.pressedFn("CROSS", event.key))
        {
            if(VideoControl.videoMode === VideoControl.Playback)
            {
                list_delegate.stopPlaybackVideo()
                event.accepted = true
            }
            else
            {
                event.accepted = false
            }
        }
        else if((VideoControl.videoMode !== VideoControl.Playback) && (MKeys.pressedFn("TRUEFOCUS", event.key) || MKeys.pressedFn("AF_D", event.key) || MKeys.pressedFn("PLAY", event.key)))
        {
            list_delegate.playbackVideo()
        }
        else if((MKeys.pressedFn("SQUARE", event.key)) || ((VideoControl.videoMode === VideoControl.Playback) && (MKeys.pressedFn("AF_D", event.key) || MKeys.pressedFn("PLAY", event.key))))
        {
            event.accepted = true
        }
        else
        {
            event.accepted = false
        }
    }

    Keys.onReleased: {
        // Eat the released event
        if(MKeys.pressedFn("AF_D", event.key))
            event.accepted = true
        else
            event.accepted = false
    }

    Connections {
        target: configstore
        onExpModeChanged: {
            if(VideoControl.videoMode === VideoControl.Playback)
            {
                list_delegate.stopPlaybackVideo()
            }
        }
    }

    VideoOverlay {
        id: overlay
        anchors.fill: parent
        fileIndex: index
        fileName: display
        fileSize: model.fileSize
        metaVolumeType: ContentModel.browseVolume
        Binding on metaDateTime {
            when: date !== undefined
            value: date
        }
        Binding on metaImgName {
            when: display !== undefined
            value: display
        }
        //Disable image filtering for now
        /*FilterButton {
            id: filterImage
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: 10
                topMargin: 10 + constants.topMetaHeight
            }
            visible: filteringImages
            enabled: visible
            onClicked: list_delegate.openImageRateFilter()
        }*/
    }
}
