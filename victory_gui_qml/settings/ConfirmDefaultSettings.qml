import QtQuick 2.0
import com.hasselblad.guiconfig 1.0

import "qrc:///components"

GenericConfirm {
    largeHeaderText: true
    headerText: qsTr("Reset All Settings?")
    largeInfoText: false
    infoMarginSide: 20
    bgHeaderTopMargin: 80
    infoText: (guiconfig.isWedge && configstore.resetProfiles) ?   qsTr("All settings including<br>custom modes will be<br>reset to default values!") :
              (guiconfig.isWedge && !configstore.resetProfiles) ?  qsTr("All settings except<br>custom modes will be<br>reset to default values!") :
              (!guiconfig.isWedge && configstore.resetProfiles) ?  qsTr("All settings including<br>profiles will be reset<br>to default values!") :
                                                                   qsTr("All settings except<br>profiles will be reset<br>to default values!")


    rightText: qsTr("Reset")

    onRightSelected: configstore.resetDefaultSettings(configstore.resetProfiles);
}
