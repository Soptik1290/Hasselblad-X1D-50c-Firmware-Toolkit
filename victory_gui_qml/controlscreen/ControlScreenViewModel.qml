import QtQuick 2.0
import com.hasselblad.bodysync 1.0
import com.hasselblad.camera 1.0
import com.hasselblad.cambody 1.0
import com.hasselblad.config 1.0
import com.hasselblad.systemmanager 1.0
import com.hasselblad.video 1.0
QtObject {
    readonly property bool videoMode: System.camera_mode === System.CameraModeVideo
    readonly property bool fullAuto: configstore.ExpMode === Config.ExpMode_FullAuto
    readonly property bool whiteBalanceControlVisible: Camera.canShow & Camera.PropWBMode
    readonly property url whitebalanceControlSymbol: fullAuto ? "qrc:///icons/WBal_Auto_inactive.png" :
                                                                  Camera.WBMode === 1  ? "qrc:///icons/WBal_Auto.png"
                                                                : Camera.WBMode === 2  ? "qrc:///icons/WBal_Daylight.png"
                                                                : Camera.WBMode === 10 ? "qrc:///icons/WBal_Cloudy.png"
                                                                : Camera.WBMode === 3  ? "qrc:///icons/WBal_Tungsten.png"
                                                                : Camera.WBMode === 5  ? "qrc:///icons/WBal_Flash.png"
                                                                : Camera.WBMode === 11 ? "qrc:///icons/WBal_Shade.png"
                                                                : Camera.WBMode === 4  ? "qrc:///icons/WBal_Fluor.png"
                                                                : Camera.WBMode === 6  ? "qrc:///icons/WBal_Empty.png"
                                                                : "qrc:///icons/WBal_Empty.png";
    readonly property bool afControlVisible: Camera.canShow & Camera.PropFocusMode
    readonly property bool apertureSettingVisible: Camera.canShow & Camera.PropAV
    readonly property bool shutterSpeedSettingVisible: Camera.canShow & Camera.PropTV
    readonly property bool exposureAdjustSettingVisible: (Camera.canShow & Camera.PropEVADJ) || (Camera.canShow & Camera.PropFlashEVADJ)
    readonly property url exposureControlSymbol: videoMode ? "qrc:///icons/ExpMode_Video.png"
                                                         : (((cambody.capabilities & Cambody.CapabilitySupportAE) === 0) || !selectedExposureModeValid) ?  "qrc:///icons/ExpMode_Manual.png"
                                                         : configstore.ExpMode === Config.ExpMode_Manual ? "qrc:///icons/ExpMode_Manual.png"
                                                         : configstore.ExpMode === Config.ExpMode_Aperture ? "qrc:///icons/ExpMode_Aperture.png"
                                                         : configstore.ExpMode === Config.ExpMode_ShutterSpeed ? "qrc:///icons/ExpMode_Shutter.png"
                                                         : configstore.ExpMode === Config.ExpMode_Program ? "qrc:///icons/ExpMode_Program.png"
                                                         : configstore.ExpMode === Config.ExpMode_ProgramVariable ? "qrc:///icons/ExpMode_ProgramV.png"
                                                         : configstore.ExpMode === Config.ExpMode_ManualQuick ? "qrc:///icons/ExpMode_MQ.png"
                                                         : fullAuto ? "qrc:///icons/ExpMode_Auto.png"
                                                         : "qrc:///icons/ExpMode_Manual.png"
    readonly property bool exposureControlAllowedToChange: !videoMode &&
                                                           (((cambody.capabilities & Cambody.CapabilitySupportAE) !== 0)
                                                                || ((cambody.capabilities & Cambody.CapabilityVideoMode) !== 0)) &&
                                                           (BodySync.currentDialMode === BodySync.DmCustom1
                                                            || BodySync.currentDialMode === BodySync.DmCustom2
                                                            || BodySync.currentDialMode === BodySync.DmCustom3)
    readonly property url meterControlSymbol: fullAuto ?  "qrc:/icons/Metering_Centre_inactive.png" :
                                                                !selectedLightMeterModeValid ? "qrc:/icons/Metering_None.png"
                                                              : Camera.LMMode === Config.LMM_CenterWeighted ? "qrc:/icons/Metering_Centre.png"
                                                              : Camera.LMMode === Config.LMM_Spot ? "qrc:/icons/Metering_Spot.png"
                                                              : Camera.LMMode === Config.LMM_CentreSpot ? "qrc:/icons/Metering_Multi.png"
                                                              : Camera.LMMode === Config.LMM_Matrix ? "qrc:/icons/Metering_None.png"
                                                              : Camera.LMMode === Config.LMM_Average ? "qrc:/icons/Metering_None.png"
                                                              : Camera.LMMode === Config.LMM_Incident ? "qrc:/icons/Metering_None.png"
                                                              : "qrc:/icons/Metering_None.png"
    readonly property url driveControlSymbol: !(Camera.canChange & Camera.PropDriveMode) ? "qrc:/icons/DriveMode_Single_inactive.png"
                                                       : Camera.DriveMode ===  0 ? "qrc:/icons/DriveMode_Single.png"
                                                       : Camera.DriveMode ===  1 ? "qrc:/icons/DriveMode_Cont.png"
                                                       : "qrc:/icons/DriveMode_Single.png";
    readonly property bool selectedExposureModeValid: (cambody.ExpModeList & (1 << configstore.ExpMode)) != 0
    readonly property bool selectedLightMeterModeValid: (cambody.LMModeListAsInt & (1 << Camera.LMMode)) != 0
    readonly property bool videoRecordMode: VideoControl.videoMode === VideoControl.Record
    readonly property bool liveViewVisible: !videoMode &&
                                            ((configstore.CameraType === Config.CameraTypeFlashsync) ||
                                             (configstore.CameraType === Config.CameraTypePinhole))
}
