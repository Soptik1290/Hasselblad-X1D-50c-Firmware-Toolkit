import QtQuick 2.0

import com.hasselblad.hblsystemtime 1.0
import com.hasselblad.bodysync 1.0

import "qrc:///scripts/Keys.js" as MKeys


Rectangle {
    objectName: "DateTime"
    id: root
    color: constants.menuBackgroundColor
    property string upperMenuLabel
    property string menuLabel
//    property string headingText
    // How much space between objects in view
    property int itemSpacing: 15
    property bool allowHighlightBracket: false
    property real maxVisibleItems: 4.5
    property int itemHeight: contentArea.height / maxVisibleItems
    property bool preventSwipe: popup_loader.status !== Loader.Null

    Keys.onPressed: {
        event.accepted = true
        if(MKeys.pressedFn("NAVRIGHT", event.key) && !allowHighlightBracket) {
            yearinput.focus = true
            allowHighlightBracket = true
            startWheelTimout();
        }
        else if(MKeys.pressedFn("NAVLEFT", event.key) && !allowHighlightBracket) {
            dayinput.focus = true
            allowHighlightBracket = true
            startWheelTimout();
        }
        else if(MKeys.pressedFn("UP", event.key) && !allowHighlightBracket) {
            hourinput.focus = true
            allowHighlightBracket = true
            startWheelTimout();
        }
        else if(MKeys.pressedFn("DOWN", event.key) && !allowHighlightBracket)
        {
            yearinput.focus = true
            allowHighlightBracket = true
            startWheelTimout();
        }
        else
            event.accepted = false
    }


    MouseArea{
        anchors.fill: parent
/*
        // We must have this here to be able to drag:
        drag {
            target: root
            axis: Drag.XAxis
            minimumX: 0
            maximumX: root.width
            threshold: constants.dragThreshold
            filterChildren: true
        }
        drag.onActiveChanged: {
            if (!drag.active) {
                // Done dragging
                if (drag.target.x > (root.width / constants.swipeLengthDividor))
                {
                    // Dragged enough to the right. Close the window
                    root.parent.active = false;
                }
                root.x = 0
            }
        }
        */
        onClicked: {}
    }

    Timer {
        id: wheelTimer
        interval: constants.wheelTimeoutTimeMs
        running: false
        repeat: false
        onTriggered: {
            allowHighlightBracket = false
            root.forceActiveFocus();
        }
    }

    function startWheelTimout()
    {
        wheelTimer.restart();
    }

    Rectangle {
        id: viewEndLine
        color: constants.cameraViewLineColor
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.top: parent.top
        width: constants.viewEndLineWidth
    }

    // Calculate left and right margin, adapted to centering the object of given size to another given object (relative to 'root').
    // The margin can be limited to a certain width avoiding going outside of parent object.
    function marginsFromObject(object, centeredSize, minMargin)
    {
        var middlePos = mapFromItem(object, object.width / 2, 0).x  // middle position of "parent" object
        var left = middlePos - centeredSize / 2
        var right = width - (middlePos + centeredSize / 2);

        // limit to min on both sides.
        if(left < minMargin) {
            right -= minMargin - left
            left = minMargin
        }
        else if(right < minMargin) {
            left -= minMargin - right
            right = minMargin
        }

        return {
            left: left,
            right: right
        }
    }

    Loader {
        objectName: "DateTime_popupLoader"
        id: popup_loader
        anchors {
            bottom: parent.bottom
            left: viewEndLine.right
            top: parent.top
            right: parent.right
        }
        source: "qrc:///components/popups/PopoverGenericNumber.qml"
        active: false
        // Must have a high z som this will be in the front when visible:
        z: 100
        focus: true
        property var model
        property int selectedValue
        property int chosenValue
        property bool isToLeft: true
        onLoaded: {
            item.forceActiveFocus()
            item.finalBodyState = BodySync.MENU
        }
        Connections {
            target: popup_loader.item
            onVisibleChanged: {
                if (!popup_loader.item.visible)
                    popup_loader.state = ""
            }
            onSelected: popup_loader.chosenValue = number
        }

        Binding {
            target: popup_loader.item
            property: "model"
            value: popup_loader.model
        }
        Binding {
            target: popup_loader.item
            property: "selectedValue"
            value: popup_loader.selectedValue
        }
        Binding {
            target: popup_loader.item
            property: "isToLeft"
            value: popup_loader.isToLeft
        }

        states: [
            State {
                name: "year"
                PropertyChanges { target: popup_loader;
                    selectedValue: SystemTimeControl.year
                    model: yearmodel
                    active: true
                }
                StateChangeScript {
                    script: {
                        var margins = root.marginsFromObject(yearinput, constants.yearWidth, constants.dateTimeMinMargin)
                        popup_loader.setSource("qrc:///components/popups/PopoverGenericNumber.qml", { "popupAnchor.leftMargin": margins.left, "popupAnchor.rightMargin": margins.right })
                        root.updateYearModel();
                    }
                }
            },
            State {
                name: "month"
                PropertyChanges { target: popup_loader;
                    selectedValue: SystemTimeControl.month
                    model: monthmodel
                    active: true
                }
                StateChangeScript {
                    script: {
                        var margins = root.marginsFromObject(monthinput, constants.timeMonthDayWidth, constants.dateTimeMinMargin)
                        popup_loader.setSource("qrc:///components/popups/PopoverGenericNumber.qml", { "popupAnchor.leftMargin": margins.left, "popupAnchor.rightMargin": margins.right })
                    }
                }
            },
            State {
                name: "day"
                PropertyChanges { target: popup_loader;
                    selectedValue: SystemTimeControl.day
                    model: daymodel
                    isToLeft: false
                    active: true
                }
                StateChangeScript {
                    script: {
                        var margins = root.marginsFromObject(dayinput, constants.timeMonthDayWidth, constants.dateTimeMinMargin)
                        popup_loader.setSource("qrc:///components/popups/PopoverGenericNumber.qml", { "popupAnchor.leftMargin": margins.left, "popupAnchor.rightMargin": margins.right })
                        root.updateDayModel();
                    }
                }
            },
            State {
                name: "hour"
                PropertyChanges { target: popup_loader;
                    selectedValue: SystemTimeControl.hour
                    model: hourmodel
                    active: true
                }
                StateChangeScript {
                    script: {
                        var margins = root.marginsFromObject(hourinput, constants.timeMonthDayWidth, constants.dateTimeMinMargin)
                        popup_loader.setSource("qrc:///components/popups/PopoverGenericNumber.qml", { "popupAnchor.leftMargin": margins.left, "popupAnchor.rightMargin": margins.right})
                    }
                }
            },
            State {
                name: "minute"
                PropertyChanges { target: popup_loader;
                    selectedValue: SystemTimeControl.minute
                    model: minutemodel
                    active: true
                }
                StateChangeScript {
                    script: {
                        var margins = root.marginsFromObject(minuteinput, constants.timeMonthDayWidth, constants.dateTimeMinMargin)
                        popup_loader.setSource("qrc:///components/popups/PopoverGenericNumber.qml", {  "popupAnchor.leftMargin": margins.left, "popupAnchor.rightMargin": margins.right})
                    }
                }
            }
        ]

        transitions: [
            Transition {
                from: "year"
                ScriptAction {
                    script: {
                        SystemTimeControl.setYear(popup_loader.chosenValue)
                        SystemTimeControl.setSystemDateTime()
                        yearinput.forceActiveFocus()
                    }
                }
            },
            Transition {
                from: "month"
                ScriptAction {
                    script: {
                        SystemTimeControl.setMonth(popup_loader.chosenValue)
                        SystemTimeControl.setSystemDateTime()
                        monthinput.forceActiveFocus()
                    }
                }
            },
            Transition {
                from: "day"
                ScriptAction {
                    script: {
                        SystemTimeControl.setDay(popup_loader.chosenValue)
                        SystemTimeControl.setSystemDateTime()
                        dayinput.forceActiveFocus()
                    }
                }
            },
            Transition {
                from: "hour"
                ScriptAction {
                    script: {
                        SystemTimeControl.setHour(popup_loader.chosenValue)
                        SystemTimeControl.setSystemDateTime()
                        hourinput.forceActiveFocus()
                    }
                }
            },
            Transition {
                from: "minute"
                ScriptAction {
                    script: {
                        SystemTimeControl.setMinute(popup_loader.chosenValue)
                        SystemTimeControl.setSecond(0)
                        SystemTimeControl.setSystemDateTime()
                        minuteinput.forceActiveFocus()
                    }
                }
            }
        ]
    }

    // Header text
    Text {
        id: header
        anchors {
            left: viewEndLine.right
            right: parent.right
            top: parent.top
            topMargin: constants.headerVerticalOffset
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize : constants.headerTextSize
        color: constants.menuHeaderColor
//        text: qsTr(headingText) + guiconfig.emptyString
        text: "<font color=\"" + constants.menuHighlightColor + "\">"
              + qsTranslate("MainScreen", upperMenuLabel).toLocaleUpperCase()
              + ":</font> &nbsp;"
              + qsTranslate("MENUS", menuLabel).toLocaleUpperCase()
              + guiconfig.emptyString

        font.capitalization: Font.AllUppercase
    }

    Item {
        id: contentArea
        anchors {
            top: header.bottom
            left: viewEndLine.right
            right: root.right
            bottom: root.bottom
        }
    }

    Column {
        anchors {
            left: viewEndLine.right
            right: parent.right
            verticalCenter: contentArea.verticalCenter
        }

        Item {
            height: root.itemHeight
            anchors.left: parent.left
            anchors.right: parent.right
            Text {
                id: datehdr
                text: qsTr("Date:") + guiconfig.emptyString
                font.pixelSize: constants.itemTextSize
                anchors {
                    right: parent.horizontalCenter
                    rightMargin: constants.subSettingDropDownXMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: guiconfig.usingUnicodeLanguage ? 0 : (height - baselineOffset) / 2
                }
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.family: constants.menuItemFontName
                color: constants.menuItemColor
            }

            Row {
                anchors {
                    left: datehdr.right
                    leftMargin: constants.subSettingDropDownSpacing
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height
                spacing: itemSpacing

                Text {
                    id: yearinput
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2//constants.subSettingYOffset
                    text: SystemTimeControl.year
                    color: (allowHighlightBracket && focus) ? constants.menuHighlightColor : constants.menuItemColor
                    font.pixelSize: constants.itemTextSize
                    font.bold: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: popup_loader.state = "year"
                    }
                    Keys.onPressed: {
                        if(allowHighlightBracket)
                        {
                            event.accepted = true
                            if(MKeys.pressedFn("NAVRIGHT", event.key)) {
                                startWheelTimout()
                                monthinput.forceActiveFocus()
                            }
                            else if(MKeys.pressedFn("SELECT", event.key)) {
                                wheelTimer.stop()
                                allowHighlightBracket = false;
                                popup_loader.state = "year"
                            }
                            else if(MKeys.pressedFn("NAVLEFT", event.key)) {
                                startWheelTimout()
                                minuteinput.forceActiveFocus()
                            }
                            else if(MKeys.pressedFn("VERT", event.key)) {
                                startWheelTimout()
                                hourinput.forceActiveFocus()
                            }
                            else
                                event.accepted = false
                        }
                    }


                }

                Text {
                    text: "-"
                    color: constants.menuItemColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2//constants.subSettingYOffset
                    font.pixelSize: constants.itemTextSize
                    font.bold: true
                }

                Text {
                    id: monthinput
                    text: (SystemTimeControl.month < 10 ? "0" : "") + SystemTimeControl.month
                    color: (allowHighlightBracket && focus) ? constants.menuHighlightColor : constants.menuItemColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2
                    font.pixelSize: constants.itemTextSize
                    font.bold: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: popup_loader.state = "month"
                    }

                    Keys.onPressed: {
                        if(allowHighlightBracket) {
                            event.accepted = true
                            if(MKeys.pressedFn("NAVRIGHT", event.key)) {
                                startWheelTimout()
                                dayinput.forceActiveFocus()
                            }
                            else if(MKeys.pressedFn("SELECT", event.key)) {
                                wheelTimer.stop()
                                allowHighlightBracket = false;
                                popup_loader.state = "month"
                            }
                            else if(MKeys.pressedFn("NAVLEFT", event.key)) {
                                startWheelTimout()
                                yearinput.forceActiveFocus()
                            }
                            else if(MKeys.pressedFn("VERT", event.key)) {
                                startWheelTimout()
                                hourinput.forceActiveFocus()
                            }
                            else
                                event.accepted = true
                        }
                    }
                }

                Text {
                    text: "-"
                    color: constants.menuItemColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2//constants.subSettingYOffset
                    font.pixelSize: constants.itemTextSize
                    font.bold: true
                }

                Text {
                    id: dayinput
                    text: (SystemTimeControl.day < 10 ? "0" : "") + SystemTimeControl.day
                    color: (allowHighlightBracket && focus) ? constants.menuHighlightColor : constants.menuItemColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2//constants.subSettingYOffset
                    font.pixelSize: constants.itemTextSize
                    font.bold: true

                    Keys.onReturnPressed: popup_loader.state = "day"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: popup_loader.state = "day"
                    }
                    Keys.onPressed: {
                        if(allowHighlightBracket)
                        {
                            event.accepted = true
                            if (MKeys.pressedFn("NAVRIGHT", event.key)) {
                                startWheelTimout()
                                hourinput.forceActiveFocus()
                            }
                            else if (MKeys.pressedFn("SELECT", event.key)) {
                                wheelTimer.stop()
                                allowHighlightBracket = false;
                                popup_loader.state = "day"
                            }
                            else if (MKeys.pressedFn("NAVLEFT", event.key)) {
                                startWheelTimout()
                                monthinput.forceActiveFocus()
                            }
                            else if(MKeys.pressedFn("VERT", event.key)) {
                                startWheelTimout()
                                minuteinput.forceActiveFocus()
                            }
                            else
                                event.accepted = false
                        }
                    }

                }

            }
        }
        Item {
            height: root.itemHeight
            anchors.left: parent.left
            anchors.right: parent.right
            Text {
                id: timehdr
                text: qsTr("Time:") + guiconfig.emptyString
                font.pixelSize: constants.itemTextSize
                anchors {
                    right: parent.horizontalCenter
                    rightMargin: constants.subSettingDropDownXMargin
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: guiconfig.usingUnicodeLanguage ? 0 : (height - baselineOffset) / 2
                }
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.family: constants.menuItemFontName
                color: constants.menuItemColor
            }
            Row {
                anchors {
                    left: timehdr.right
                    leftMargin: constants.subSettingDropDownSpacing
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height
                spacing: itemSpacing

                Text {
                    id: hourinput
                    text: (SystemTimeControl.hour < 10 ? "0" : "") + SystemTimeControl.hour
                    color: (allowHighlightBracket && focus) ? constants.menuHighlightColor : constants.menuItemColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2
                    font.pixelSize: constants.itemTextSize
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: popup_loader.state = "hour"
                    }
                    Keys.onPressed: {
                        if(allowHighlightBracket) {
                            event.accepted = true
                            if (MKeys.pressedFn("NAVRIGHT", event.key)) {
                                event.accepted = true
                                startWheelTimout()
                                minuteinput.forceActiveFocus()
                            }
                            else if (MKeys.pressedFn("SELECT", event.key)) {
                                wheelTimer.stop()
                                allowHighlightBracket = false;
                                popup_loader.state = "hour"
                            }
                            else if (MKeys.pressedFn("NAVLEFT", event.key)) {
                                startWheelTimout()
                                dayinput.forceActiveFocus()
                            }
                            else if(MKeys.pressedFn("VERT", event.key)) {
                                startWheelTimout()
                                yearinput.forceActiveFocus()
                            }
                            else
                                event.accepted = false
                        }
                    }

                }

                Text {
                    text: ":"
                    color: constants.menuItemColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2
                    font.pixelSize: constants.itemTextSize
                    font.bold: true
                }

                Text {
                    id: minuteinput
                    text: (SystemTimeControl.minute < 10 ? "0" : "") + SystemTimeControl.minute
                    color: (allowHighlightBracket && focus) ? constants.menuHighlightColor : constants.menuItemColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (height - baselineOffset) / 2
                    font.pixelSize: constants.itemTextSize
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: popup_loader.state = "minute"
                    }
                    Keys.onPressed: {
                        if(allowHighlightBracket)
                        {
                            event.accepted = true
                            if (MKeys.pressedFn("NAVRIGHT", event.key)) {
                                startWheelTimout()
                                yearinput.forceActiveFocus()
                            }
                            else if (MKeys.pressedFn("SELECT", event.key)) {
                                wheelTimer.stop()
                                allowHighlightBracket = false;
                                popup_loader.state = "minute"
                            }
                            else if(MKeys.pressedFn("NAVLEFT", event.key))
                            {
                                startWheelTimout()
                                hourinput.forceActiveFocus()
                            }
                            else if(MKeys.pressedFn("VERT", event.key)) {
                                startWheelTimout()
                                dayinput.forceActiveFocus()
                            }
                            else
                                event.accepted = false
                        }
                    }

                }
            }
        }
    }

    function populateModel() {
        SystemTimeControl.loadSystemDateTime();

        // this one never change dynamically so we populate it only once here.
        updateMonthModel();
        updateHourModel();
        updateMinuteModel();

        root.focus = true
    }


    ListModel {
        id: yearmodel
    }

    function updateYearModel() {
        yearmodel.clear();
        var beginYear = 2016
        var startYear = Math.max(beginYear, SystemTimeControl.year - 10)
        var endYear = startYear + 35

        // The freescale kernel used in the Victory/Wedge/Albatross projects doesn't include the fixes for year 2038 problem, so limit the upper range to work around issues.
        // http://hrs.hasselblad.se/openproject/work_packages/4373
        // https://en.wikipedia.org/wiki/Year_2038_problem
        // Drop this part when we no longer use an ancient linux kernel:
        // ------->8------8<---------
        var year2038problem = 2038;
        if (startYear > year2038problem - 10) {
            startYear = year2038problem - 10;
        }
        if (endYear >= year2038problem) {
            endYear = year2038problem-1;
        }
        // ------->8------8<---------

        for (var i = startYear; i <= endYear; i++)
            yearmodel.append({ "number" : i });
    }

    ListModel {
        id: monthmodel
    }

    function updateMonthModel() {
        monthmodel.clear();
        for (var i = 1; i <= 12; i++)
            monthmodel.append({"number": i});
    }

    ListModel {
        id: daymodel
    }

    function updateDayModel() {
        daymodel.clear();
        for (var i = 1; i <= SystemTimeControl.getDaysInCurrentMonth(); i++)
            daymodel.append({ "number": i });
    }

    ListModel {
        id: hourmodel
    }

    function updateHourModel() {
        hourmodel.clear()
        for (var i = 0; i <= 23 ; i++)
            hourmodel.append({"number": i})
    }

    ListModel {
        id: minutemodel
    }

    function updateMinuteModel() {
        minutemodel.clear()
        for (var i = 0 ; i <= 59; i++)
            minutemodel.append({"number": i});
    }

    Component.onCompleted: {
        populateModel()
    }
}
