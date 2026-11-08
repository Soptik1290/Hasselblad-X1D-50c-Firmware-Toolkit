import QtQuick 2.0
import com.hasselblad.settings 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.config 1.0
import com.hasselblad.bodysync 1.0
import "qrc:///settings/scripts/MenuItemImporter.js" as MenuItems
import "qrc:///scripts/Keys.js" as MKeys
ListSelector {
    objectName: "FavoriteAddSelector_root"
    id: popAdd
    z: 100
    property int gridspacing: 10
    property var targetModel
    property var favoriteModel
    isToLeft: false
    visible: false
    property bool preventSwipe: visible
    property int sideMargin: 50
    property int topBottomMargin: sideMargin - 30
    popupAnchor.leftMargin: sideMargin
    popupAnchor.rightMargin: sideMargin
    popupAnchor.topMargin: topBottomMargin
    popupAnchor.bottomMargin: topBottomMargin
    setValueWhenOutsideClick: false
    preventAFMFPropagation: false
    preventPLAYPropagation: false
    signal subMenuAboutToShow(var menuName)
    finalBodyState: BodySync.MENU
    function populateModel(menuItemValues) {
        list_model.clear()
        populateModelSection("camera_menu", MenuItems.cameraMenuItems)
        populateModelSection("video_menu", MenuItems.videoMenuItems)
        populateModelSection("settings_menu", MenuItems.getSettingsMenuItems(prodinfo.wifiAvailable))
        open()
    }
    function postClose()
    {
        closeMenu()
    }
    function populateModelSection(sectionStateName, sectionItems)
    {
        sectionItems.forEach(function(v)
        {
            var isDemo = (typeof v.demo !== 'undefined') && (v.demo !== undefined && v.demo);
            var isEnabled = (typeof v.enableCond === 'undefined') || v.enableCond === undefined || v.enableCond === "" || eval(v.enableCond)
            if((v.settingsList !== "") && !favoriteModel.isInList(v.settingsList) && (!isDemo || !guiconfig.hideDemoItems))
            {
                list_model.append({ "settingsList" : v.settingsList, "clicked_state": sectionStateName, "icon" : v.largeIcon, "text" : qsTranslate("MENUS", v.itemText), "untranslatedText" : v.itemText, "itemFile" : v.itemFile, "itemEnabled" : isEnabled })
            }
        });
    }
    Keys.onPressed: {
        if(!event.accepted && MKeys.pressedFnAcc("EXPOSURE", event))
        {
            close()
        }
    }
    onVisibleChanged: {
        if (!visible)
        {
            return;
        }
        list.focus = true;
        list.currentIndex = 0
    }
    function itemSelected(index)
    {
        if(index >= 0)
        {
            var setModel = list.model.get(index)
            targetModel.addRow(setModel.settingsList, setModel.clicked_state, setModel.icon, setModel.untranslatedText, setModel.itemFile)
        }
        popAdd.close();
    }
    function setSelected()
    {
        if(list.currentIndex >= 0)
        {
            var setModel = list.model.get(list.currentIndex)
            targetModel.addRow(setModel.settingsList, setModel.clicked_state, setModel.icon, setModel.untranslatedText, setModel.itemFile)
        }
    }
    Connections {
        target: configstore
        onExpModeChanged: {
            popAdd.close();
        }
    }
    content: list
    contentItem: list
    Item {
        id: listWrapper
        anchors.fill: parent
        ListView {
            objectName: "FavoriteAddSelector_list"
            id: list
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            orientation: ListView.Vertical
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: list.height / 2 - list.height / constants.numberOfItemsVisibleInList / 2
            preferredHighlightEnd: list.height / 2 + list.height / constants.numberOfItemsVisibleInList / 2
            function setSelectedClose()
            {
                setSelected()
                close()
                closeMenu()
            }
            highlight: Rectangle{
                color: constants.popupBackgroundColor
                height: list.height / constants.numberOfItemsVisibleInList
                Rectangle {
                    color: constants.highlightColor
                    anchors.fill: parent
                }
            }
            model: list_model
            delegate: Item {
                id: theItem
                height: list.height / constants.numberOfItemsVisibleInList
                width: list.width
                property real addSize : (Math.max(height - Math.abs(theItem.y - list.contentY - list.preferredHighlightBegin), 0) / height) * constants.listViewSizeIncreaseFactor
                Item {
                    id: itemIcon
                    anchors.verticalCenter: theItem.verticalCenter
                    anchors.left: theItem.left
                    height: list.height / constants.numberOfItemsVisibleInList
                    width: 80
                    Image {
                        anchors.centerIn: parent
                        source: {
                            if(settingsList !== "")
                            {
                                return "qrc:///icons/" + settingsList + ".png"
                            }
                            else
                            {
                                return "qrc:///icons/" + icon + ".png"
                            }
                        }
                        scale: 1 + addSize
                    }
                }
                Text {
                    anchors {
                        verticalCenter: itemIcon.verticalCenter
                        verticalCenterOffset: guiconfig.usingUnicodeLanguage ?  0 : (height - baselineOffset) / 2
                        left: itemIcon.right
                        leftMargin: 10
                        right: parent.right
                        rightMargin: 10
                    }
                    id: itemText
                    text: model.text + guiconfig.emptyString
                    color: theItem.ListView.isCurrentItem ? constants.highlightItemColor: constants.itemColor
                    font.pixelSize: constants.itemTextSizeMenuLevel1 * (1 + addSize)
                    fontSizeMode: Text.HorizontalFit
                    verticalAlignment: Text.AlignVCenter
                }
                Keys.onReturnPressed: itemSelected(index)
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    onClicked: itemSelected(index)
                }
            }
            Rectangle {
                anchors {
                    left: list.left
                    right: list.right
                    top: list.top
                }
                height: 140
                gradient: Gradient {
                    GradientStop { position: 0.0; color: constants.popoverListViewShadingStartColor }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
            Rectangle {
                anchors {
                    left: list.left
                    right: list.right
                    bottom: list.bottom
                }
                height: 140
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: constants.popoverListViewShadingStartColor }
                }
            }
        }
    }
    ListModel {
        id: list_model
    }
}
