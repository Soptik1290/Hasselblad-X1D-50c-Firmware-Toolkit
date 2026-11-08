import QtQuick 2.0
import "qrc:///components"
GenericConfirm {
    largeHeaderText: true
    headerText: qsTr("Reset file counter?")
    infoText: qsTr("The image sequence number will be reset!")
    rightText: qsTr("Reset")
    transparentBackground: true
    onRightSelected: farm.resetGlobalImageSequenceCounter()
}
