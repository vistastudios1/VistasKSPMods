wait until ship:unpacked.
unlock steering.
clearguis().
clearscreen.
set Scriptversion to "V3.5.2".


//<------------Telemtry Scale-------------->

set TScale to 1.

// 720p     -   0.67
// 1080p    -   1
// 1440p    -   1.33
// 2160p    -   2
//_________________________________________

if exists("0:/settings.json") {
    set L to readjson("0:/settings.json").
    if L:haskey("TelemetryScale") {
        set TScale to L["TelemetryScale"].
    }
}


//---------------Self-Update--------------//



if homeconnection:isconnected {
    if config:arch {
        set config:arch to false.
        HUDTEXT("kOS start on archive setting turned off. Please reload the scene.. (no reverting!)", 30, 2, 20, red, false).
        shutdown.
    }
    switch to 0.
    if exists("1:starship.ksm") {
        if homeconnection:isconnected {
            HUDTEXT("Starting Interface..", 5, 2, 20, green, false).
            if open("0:starship.ks"):readall:string = open("1:/boot/starship.ks"):readall:string {}
            else {
                sas on.
                HUDTEXT("Receiving Flight Control Software Update..", 10, 2, 20, yellow, false).
                COMPILE "0:/starship.ks" TO "0:/starship.ksm".
                if homeconnection:isconnected {
                    copypath("0:starship.ks", "1:/boot/").
                    copypath("starship.ksm", "1:").
                    set core:BOOTFILENAME to "starship.ksm".
                    reboot.
                }
                else {
                    HUDTEXT("Connection lost during Update! Can't update Interface..", 10, 2, 20, red, false).
                }
            }
        }
        else {
            HUDTEXT("Connection lost during Update! Can't update Interface..", 10, 2, 20, red, false).
        }
    }
    else {
        HUDTEXT("Receiving Flight Control Software uplink..", 10, 2, 20, green, false).
        print "starship.ksm doesn't yet exist in boot.. creating..".
        COMPILE "0:/starship.ks" TO "0:/starship.ksm".
        copypath("0:starship.ks", "1:/boot/").
        copypath("starship.ksm", "1:").
        set core:BOOTFILENAME to "starship.ksm".
        reboot.
    }
}
else {
    HUDTEXT("No connection available! Can't check for updates..", 10, 2, 20, yellow, false).
    HUDTEXT("Starting Interface..", 5, 2, 20, green, false).
}



//---------------Telemetry GUI-----------------//

set runningprogram to "None".
set missionTimer to 0.
if exists("0:/settings.json") {
    set L to readjson("0:/settings.json").
    if L:haskey("Launch Time") {
        set missionTimer to L["Launch Time"].
    }
}

if exists("0:/settings.json") {
    set L to readjson("0:/settings.json").
    if L:haskey("Launch Coordinates") {
        set LSCoords to L["Launch Coordinates"].
    }
    else set LSCoords to ("0,0").
} 
else set LSCoords to ("0,0").

set RadarAlt to 0.
set Hotstaging to false.

local sTelemetry is GUI(150).
    set sTelemetry:style:bg to "starship_img/telemetry_bg".
    set sTelemetry:skin:label:textcolor to white.
    set sTelemetry:skin:textfield:textcolor to white.
    set sTelemetry:skin:label:font to "Arial Bold".
    set sTelemetry:skin:textfield:font to "Arial Bold".
local sAttitudeTelemetry is sTelemetry:addhlayout().
local BoosterSpace is sAttitudeTelemetry:addvlayout().
local sMissionTime is sAttitudeTelemetry:addvlayout().
local ShipAttitude is sAttitudeTelemetry:addvlayout().
local ShipStatus is sAttitudeTelemetry:addvlayout().
local ShipRaptors is sAttitudeTelemetry:addvlayout().
local bSpace is BoosterSpace:addlabel().
local missionTimeLabel is sMissionTime:addlabel().
    set missionTimeLabel:style:wordwrap to false.
    set missionTimeLabel:style:align to "center".
    set missionTimeLabel:text to "Startup".
local VersionDisplay is GUI(100).
    set VersionDisplay:style:bg to "".
    local VersionDisplayLabel is VersionDisplay:addlabel().
        set VersionDisplayLabel:style:wordwrap to false.
        set VersionDisplayLabel:style:align to "center".
        set VersionDisplayLabel:text to Scriptversion.
VersionDisplay:show().
local sAttitude is ShipAttitude:addlabel().
    set sAttitude:style:bg to "starship_img/ship".
local sSpeed is ShipStatus:addlabel("<b>SPEED  </b>").
    set sSpeed:style:wordwrap to false.
local sAltitude is ShipStatus:addlabel("<b>ALTITUDE  </b>").
    set sAltitude:style:wordwrap to false.

local sLOX is ShipStatus:addhlayout().
local sLOXLabel is sLOX:addlabel("<b>LOX  </b>").
    set sLOXLabel:style:wordwrap to false.
local sLOXBorder is sLOX:addlabel("").
    set sLOXBorder:style:align to "CENTER".
    set sLOXBorder:style:bg to "starship_img/telemetry_bg".
local sLOXSlider is sLOX:addlabel().
    set sLOXSlider:style:align to "CENTER".
    set sLOXSlider:style:bg to "starship_img/telemetry_fuel".
local sLOXNumber is sLOX:addlabel("100%").
    set sLOXNumber:style:wordwrap to false.
    set sLOXNumber:style:align to "LEFT".

local sCH4 is ShipStatus:addhlayout().
local sCH4Label is sCH4:addlabel("<b>CH4  </b>").
    set sCH4Label:style:wordwrap to false.
local sCH4Border is sCH4:addlabel("").
    set sCH4Border:style:align to "CENTER".
    set sCH4Border:style:bg to "starship_img/telemetry_bg".
local sCH4Slider is sCH4:addlabel().
    set sCH4Slider:style:align to "CENTER".
    set sCH4Slider:style:bg to "starship_img/telemetry_fuel".
local sCH4Number is sCH4:addlabel("100%").
    set sCH4Number:style:wordwrap to false.
    set sCH4Number:style:align to "LEFT".

local sThrust is ShipStatus:addlabel("<b>THRUST  </b>").
    set sThrust:style:wordwrap to false.
local sEngines is ShipRaptors:addlabel().
    set sEngines:style:bg to "starship_img/ship0".
set sTelemetry:draggable to false.

CreateTelemetry().

function CreateTelemetry {
    set sTelemetry:style:border:h to 10*TScale.
    set sTelemetry:style:border:v to 10*TScale.
    set sTelemetry:style:padding:v to 0.
    set sTelemetry:style:padding:h to 0.
    set sTelemetry:x to 0.
    set sTelemetry:y to -220*TScale.

    set bSpace:style:width to 860*TScale.

    set missionTimeLabel:style:margin:left to 0.
    set missionTimeLabel:style:margin:right to 120*TScale.
    set missionTimeLabel:style:margin:top to 80*TScale.
    set missionTimeLabel:style:width to 160*TScale.
    set missionTimeLabel:style:fontsize to 42*TScale.

    set VersionDisplay:x to 0.
    set VersionDisplay:y to 36*TScale.
        set VersionDisplayLabel:style:width to 100*TScale.
        set VersionDisplayLabel:style:fontsize to 12*TScale.

    set sAttitude:style:margin:left to 20*TScale.
    set sAttitude:style:margin:right to 20*TScale.
    set sAttitude:style:margin:top to 20*TScale.
    set sAttitude:style:width to 180*TScale.
    set sAttitude:style:height to 180*TScale.

    set sSpeed:style:margin:left to 45*TScale.
    set sSpeed:style:margin:top to 20*TScale.
    set sSpeed:style:width to 296*TScale.
    set sSpeed:style:fontsize to 30*TScale.

    set sAltitude:style:margin:left to 45*TScale.
    set sAltitude:style:margin:top to 2*TScale.
    set sAltitude:style:width to 296*TScale.
    set sAltitude:style:fontsize to 30*TScale.

    set sLOXLabel:style:margin:left to 50*TScale.
    set sLOXLabel:style:margin:top to 10*TScale.
    set sLOXLabel:style:width to 60*TScale.
    set sLOXLabel:style:fontsize to 20*TScale.

    set sLOXBorder:style:margin:left to 0*TScale.
    set sLOXBorder:style:margin:top to 19*TScale.
    set sLOXBorder:style:width to 190*TScale.
    set sLOXBorder:style:height to 8*TScale.
    set sLOXBorder:style:border:h to 8*TScale.
    set sLOXBorder:style:border:v to 0*TScale.
    set sLOXBorder:style:overflow:left to 0*TScale.
    set sLOXBorder:style:overflow:right to 8*TScale.
    set sLOXBorder:style:overflow:bottom to 1*TScale.

    set sLOXSlider:style:margin:left to 0*TScale.
    set sLOXSlider:style:margin:top to 19*TScale.
    set sLOXSlider:style:width to 0*TScale.
    set sLOXSlider:style:height to 8*TScale.
    set sLOXSlider:style:border:h to 4*TScale.
    set sLOXSlider:style:border:v to 0*TScale.
    set sLOXSlider:style:overflow:left to 200*TScale.
    set sLOXSlider:style:overflow:right to 0*TScale.
    set sLOXSlider:style:overflow:bottom to 1*TScale.

    set sLOXNumber:style:padding:left to 0*TScale.
    set sLOXNumber:style:margin:left to 10*TScale.
    set sLOXNumber:style:margin:top to 13*TScale.
    set sLOXNumber:style:width to 20*TScale.
    set sLOXNumber:style:fontsize to 12*TScale.
    set sLOXNumber:style:overflow:left to 80*TScale.
    set sLOXNumber:style:overflow:right to 0*TScale.
    set sLOXNumber:style:overflow:bottom to 0*TScale.

    set sCH4Label:style:margin:left to 50*TScale.
    set sCH4Label:style:margin:top to 4*TScale.
    set sCH4Label:style:width to 60*TScale.
    set sCH4Label:style:fontsize to 20*TScale.

    set sCH4Border:style:margin:left to 0*TScale.
    set sCH4Border:style:margin:top to 12*TScale.
    set sCH4Border:style:width to 190*TScale.
    set sCH4Border:style:height to 8*TScale.
    set sCH4Border:style:border:h to 8*TScale.
    set sCH4Border:style:border:v to 0*TScale.
    set sCH4Border:style:overflow:left to 0*TScale.
    set sCH4Border:style:overflow:right to 8*TScale.
    set sCH4Border:style:overflow:bottom to 1*TScale.

    set sCH4Slider:style:margin:left to 0*TScale.
    set sCH4Slider:style:margin:top to 12*TScale.
    set sCH4Slider:style:width to 0*TScale.
    set sCH4Slider:style:height to 8*TScale.
    set sCH4Slider:style:border:h to 4*TScale.
    set sCH4Slider:style:border:v to 0*TScale.
    set sCH4Slider:style:overflow:left to 200*TScale.
    set sCH4Slider:style:overflow:right to 0*TScale.
    set sCH4Slider:style:overflow:bottom to 1*TScale.

    set sCH4Number:style:padding:left to 0*TScale.
    set sCH4Number:style:margin:left to 10*TScale.
    set sCH4Number:style:margin:top to 7*TScale.
    set sCH4Number:style:width to 20*TScale.
    set sCH4Number:style:fontsize to 12*TScale.
    set sCH4Number:style:overflow:left to 80*TScale.
    set sCH4Number:style:overflow:right to 0*TScale.
    set sCH4Number:style:overflow:bottom to 0*TScale.

    set sThrust:style:margin:left to 45*TScale.
    set sThrust:style:margin:top to 15*TScale.
    set sThrust:style:width to 150*TScale.
    set sThrust:style:fontsize to 16*TScale.

    set sEngines:style:width to 180*TScale.
    set sEngines:style:height to 180*TScale.
    set sEngines:style:margin:top to 20*TScale.
    set sEngines:style:margin:left to 25*TScale.
    set sEngines:style:margin:right to 5*TScale.
    set sEngines:style:margin:bottom to 20*TScale.

}

set partsfound to false.

when partsfound then {
    updateTelemetry().
    wait 0.02.
    preserve.
}


//------------Initial Setup-------------//

print "starting initial setup".
wait 1.

set RSS to false.
set KSRSS to false.
set STOCK to false.
set RESCALE to false.
set Methane to false.
set LF to false.
if bodyexists("Earth") {
    if body("Earth"):radius > 1600000 {
        set RSS to true.
        set planetpack to "RSS".
    }
    else {
        set KSRSS to true.
        set planetpack to "KSRSS".
        if body("Earth"):radius < 1500001 {
            set RESCALE to true.
            set planetpack to "Rescale".
        }
    }
}
else {
    if body("Kerbin"):radius > 1000000 {
        set KSRSS to true.
        set planetpack to "KSRSS".
        if body("Kerbin"):radius < 1500001 {
            set RESCALE to true.
            set planetpack to "Rescale".
        }
    }
    else {
        set STOCK to true.
        set planetpack to "Stock".
    }
}

set FuelUnitsToKg to 11 + (1/9).
for res in Core:part:resources {
    if res:name = "LqdMethane" {
        set Methane to true.
        set FuelUnitsToKg to 2.09227666666667.
    }
    if res:name = "LiquidFuel" {
        set LF to true.
    }
}


if ship:name:contains(" Real Size") and (RSS) {
    set ship:name to ship:name:replace(" Real Size", "").
}

set ShipType to "".
FindParts().
if Tank:hasmodule("FARPartModule") {
    set FAR to true.
    set FARValue to 1.
}
else {
    set FAR to false.
    set FARValue to 0.
}
set aoa to 60.
if RSS set aoa to 58.
set BoosterAp to 35000.

set config:obeyhideui to false.

//------------Configurables-------------//



if RSS {         // Real Solar System
    set LandingAoA to 80.
    set MaxCargoToOrbit to 75000.
    set MaxReEntryCargoThickAtmo to 2500.
    set MaxIU to 200.
    set MaxReEntryCargoThinAtmo to 151000.
    set LaunchTimeSpanInSeconds to 480.
    set ShipHeight to 49.7.
    set BoosterMinPusherDistance to 0.48.
    set ShipMinPusherDistance to 1.12.
    set towerhgt to 96.
    set LaunchSites to lexicon("Launch Site", "28.549072,-80.655925").
    set DefaultLaunchSite to "28.549072,-80.655925".
    set FuelVentCutOffValue to 3000.
    set FuelBalanceSpeed to 50.
    set RollVector to heading(270,0):vector.
    set SafeAltOverLZ to 10000.  // Defines the Safe Altitude it should reach over the landing zone during landing on a moon.
    set OriginalTargetAp to 225000.
    set TargetAp to 225000.
    set RCSThrust to 100.
    set RCSBurnTimeLimit to 120.
    if Methane {
        set VentRate to 974.745.
        set FuelVentCutOffValue to FuelVentCutOffValue * 5.310536.
    }
    else {
        set VentRate to 183.55.
    }
    set ArmsHeight to 138.16.
    set OrbitPrecision to 250.
    set RendezvousOrbitLeadFactor to 0.6.
    set Scale to 1.6.
    if FAR {
        set TRJCorrection to -7. // The error between desired AoA and what AoA actually needs to be flown to follow this path.
        set aoa to aoa - TRJCorrection.
    }
    else {
        set TRJCorrection to -2.4.
    }
}
else if KSRSS {      // 2.5-2.7x scaled Kerbin
    set LandingAoA to 75.
    set MaxCargoToOrbit to 126000.
    set MaxReEntryCargoThickAtmo to 1000.
    set MaxIU to 100.
    set MaxReEntryCargoThinAtmo to 126000.
    set LaunchTimeSpanInSeconds to 360.
    set ShipHeight to 31.0.
    set BoosterMinPusherDistance to 0.3.
    set ShipMinPusherDistance to 0.7.
    set towerhgt to 60.
    if RESCALE and bodyexists("Kerbin") {
        set LaunchSites to lexicon("Launch Site", "-0.0970,-74.5833", "Dessert", "-6.5604,-143.95", "Woomerang", "45.2896,136.11", "Baikerbanur", "20.6635,-146.4210").
        set DefaultLaunchSite to "-0.0970,-74.5833".
        set FuelVentCutOffValue to 1150.
    }
    else {
        set LaunchSites to lexicon("Launch Site", "28.497545,-80.535394").
        set DefaultLaunchSite to "28.497545,-80.535394".
        set FuelVentCutOffValue to 1150.
    }
    set FuelBalanceSpeed to 30.
    set RollVector to heading(242,0):vector.
    set SafeAltOverLZ to 5000.  // Defines the Safe Altitude it should reach over the landing zone during landing on a moon.
    set OriginalTargetAp to 125000.
    set TargetAp to 125000.
    set RCSThrust to 70.
    set RCSBurnTimeLimit to 180.
    if Methane {
        set VentRate to 487.3725.
        set FuelVentCutOffValue to FuelVentCutOffValue * 5.310536.
    }
    else {
        set VentRate to 91.775.
    }
    set ArmsHeight to 86.35.
    set OrbitPrecision to 150.
    set RendezvousOrbitLeadFactor to 0.6.
    set Scale to 1.
    if FAR {
        set TRJCorrection to -15. // The error between desired AoA and what AoA actually needs to be flown to follow this path.
        set aoa to aoa - TRJCorrection.
    }
    else {
        set TRJCorrection to -2.
    }
}
else {       // Stock Kerbin
    set LandingAoA to 75.
    set MaxCargoToOrbit to 77800.
    set MaxReEntryCargoThickAtmo to 1000.
    set MaxIU to 100.
    set MaxReEntryCargoThinAtmo to 77800.
    set LaunchTimeSpanInSeconds to 265.
    set ShipHeight to 31.0.
    set BoosterMinPusherDistance to 0.3.
    set ShipMinPusherDistance to 0.7.
    set towerhgt to 60.
    set LaunchSites to lexicon("Launch Site", "-0.0972,-74.5562", "Dessert", "-6.5604,-143.95", "Woomerang", "45.2896,136.11", "Baikerbanur", "20.6635,-146.4210").
    set DefaultLaunchSite to "-0.0972,-74.5562".
    set FuelVentCutOffValue to 1000.
    set FuelBalanceSpeed to 20.
    set RollVector to heading(270,0):vector.
    set SafeAltOverLZ to 2500.  // Defines the Safe Altitude it should reach over the landing zone during landing on a moon.
    set OriginalTargetAp to 75000.
    set TargetAp to 75000.
    set RCSThrust to 40.
    set RCSBurnTimeLimit to 120.
    if Methane {
        set VentRate to 194.949.
        set FuelVentCutOffValue to FuelVentCutOffValue * 5.310536.
    }
    else {
        set VentRate to 36.71.
    }
    set ArmsHeight to 86.35.
    set OrbitPrecision to 100.
    set RendezvousOrbitLeadFactor to 0.6.
    set Scale to 1.
    if FAR {
        set TRJCorrection to -15. // The error between desired AoA and what AoA actually needs to be flown to follow this path.
        set aoa to aoa - TRJCorrection.
    }
    else {
        set TRJCorrection to -3.
    }
}
set SNStart to 30.  // Defines the first Serial Number when multiple ships are found and renaming is necessary.
set MaxTilt to 3.5.  // Defines maximum allowed slope for the Landing Zone Search Function
set maxstabengage to 0.  // Defines max closing of the stabilizers after landing.
set CPUSPEED to 600.  // Defines cpu speed in lines per second.
set FWDFlapDefault to 55.
set AFTFlapDefault to 65.
set rcsRaptorBoundary to 80.  // Defines the custom burn boundary velocity where the ship will burn either RCS/Single Raptor below it or VAC Raptors above it.
set CoGFuelBalancing to true.  // Disable this to stop constant fuel transfers during re-entry.
set DynamicPitch to true.   // Change the flap defaults dynamically during re-entry.
set steeringmanager:pitchtorquefactor to 0.75.
set steeringmanager:yawtorquefactor to 0.75.
set steeringmanager:rolltorquefactor to 0.75.
        set SRFPRGD to prograde.
        lock GSVec to vxcl(up:vector, velocity:surface).



//---------Initial Program Variables-----------//



set startup to false.
set config:ipu to CPUSPEED.
set NrOfGuisOpened to 0.
set exit to false.
set AbortLaunchInProgress to false.
set AbortLaunchComplete to false.
set LaunchComplete to false.
set LandSomewhereElse to false.
set currentdeltav to 0.
set ShipMass to 0.
set FuelMass to 1.
set TargetShip to false.
set FindNewTarget to false.
set executeconfirmed to 0.
set cancelconfirmed to 0.
set InhibitExecute to 1.
set InhibitCancel to 1.
set InhibitPages to 0.
set currVel to SHIP:VELOCITY:ORBIT.
set currTime to time:seconds.
set prevVel to SHIP:VELOCITY:ORBIT.
set prevACCTime to time:seconds.
set TimeSinceLastFullBGU to time:seconds.
set prevFanTime to time:seconds.
set prevTargetFindingTime to time:seconds - 4.
set PrevUpdateTime to TIME:SECONDS.
set prevCargoPageTime to time:seconds.
set TimeSinceLastSteering to time:seconds - 1.
set TimeSinceLastAttSteering to time:seconds - 1.
set prevattroll to 0.
SetPlanetData().
set prevattpitch to aoa.
set towerrot to 8.
set towerang to 0.
set towerpush to 0.7.
set towerpushfwd to 0.
set towerstab to 0.
set attroll to 0.
set attpitch to aoa.
set acc TO V(0, 0, 0).
set ApproachVector to v(0,0,0).
set ApproachUPVector to v(0,0,0).
set SecondsToCancelHorVelocity to 0.
set SteeringIsRunning to false.
set BGUisRunning to false.
set LandButtonIsRunning to false.
set LaunchButtonIsRunning to false.
set OrbitPageIsRunning to false.
set StatusPageIsRunning to false.
set EnginePageIsRunning to false.
set StatusBarIsRunning to false.
set AttitudeIsRunning to false.
set ClosingIsRunning to false.
set CargoPageIsRunning to false.
set CrewPageIsRunning to false.
set towerPageIsRunning to false.
set SettingCoordinatesInProgress to false.
set ManeuverPageIsRunning to false.
set AutodockingIsRunning to false.
set PerformingManeuver to false.
set ShipIsDocked to false.
set ShipType to "".
set CrewOnboard to false.
set EngineTogglesHidden to false.
set Refueling to false.
set NewTargetSet to false.
set BurnComplete to false.
set Logging to false.
set fan to false.
set FlapsYawEngaged to true.
set CargoBay to false.
set IdealRCS to 100.
set LiftOffTime to 0.
set PreviousAoAError to 0.
set AvailableLandingSpots to list(0, latlng(0,0), 0, 0, 0).
set TargetSelected to false.
set docked to false.
set OnOrbitalMount to false.
set ship:control:translation to v(0, 0, 0).
set LandingFacingVector to v(0, 0, 0).
set CargoMass to 0.
set CalculationsPerSecond to 0.
set prevCalcTime to time:seconds.
set PrevActiveStatus to KUniverse:activevessel.
set LZFinderCancelled to false.
set LastMessageSentTime to time:seconds.
set CancelVelocityHasStarted to false.
set LandingFacingVector to v(0, 0, 0).
set MaxAccel to 10.
set Launch180 to false.
set ShipWasDocked to false.
set TargetOLM to false.
set StageSepComplete to false.
set FLflap to false.
set FRflap to false.
set ALflap to false.
set ARflap to false.
set DesiredAccel to 0.
set deltaV to 0.
set MaintainVS to false.
set myAzimuth to 90.
set targetpitch to 90.
set LaunchLabelIsRunning to false.
set MinFuel to 0.
set MaxFuel to 0.
set TwoVacEngineLanding to false.
set FourVacBrakingBurn to false.
set FinalDescentEngines to list().
set result to v(0, 0, 0).
set LandAtOLMisrunning to false.
set BoosterAlreadyExists to false.
set TowerAlreadyExists to false.
set OrbitBurnPitchCorrection to 0.
set ProgradeAngle to 0.
set SteeringError to 0.
set RelVelX to 0.
set RelVelY to 0.
set RelVelZ to 0.
set TimeSinceDock to 0.
set TimeSinceLastSteering to 0.
set TimeToOrbitCompletion to 0.
set FullTanks to true.
set AirlockStatus to false.
set DockingHatchStatus to false.
set CargoDoorStatus to false.
set HotStageTime to time:seconds.
set LngError to 0.
set LatError to 0.
set LngLatErrorList to list(0,0).
set t to time:seconds.
set ShipRot to 0.
set TowerHeadingVector to v(0,0,0).
set tLZ to time:seconds.
set CancelTime to 1.
set CancelDist to 1.
set Dist2LandProc to 1.
set LowCargoMass to false.
set HSRJet to false.
set Booster to "".
set DeltaVCheck to true.
set oldArms to false.
set twoSL to false.
set oneSL to false.
set shipThrust to 0.00001.
set angle to 75.
set speed to 12.
set oldBooster to false.




//---------------Finding Parts-----------------//

when NOT CORE:MESSAGES:EMPTY then {
    hudtext("Message",5,2,5,yellow,false).
    SET RECEIVED TO CORE:MESSAGES:POP.
    if RECEIVED:CONTENT = "Arms,true" {
        set oldArms to true.
        print "Old Arms".
    }
    else if RECEIVED:CONTENT = "Arms,false" {
        set oldArms to false.
        print "New Arms".
    }
}


function FindParts {
    if ship:dockingports[0]:haspartner and SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length = 0  and SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length = 0 {
        set ShipIsDocked to true.
    }
    else {
        set ShipIsDocked to false.
    }

    set Tank to Core:part.

    set PartListStep to List(Tank).
    set ShipMassStep to Tank:mass.
    set SingleCenter to false.
    set SingleOuter to false.
    set CargoMassStep to 0.
    set CargoItems to 0.
    set CargoCoG to 0.
    set SLEnginesStep to List("","","").
    set SL to false.
    set Vac to false.
    set SLcount to 0.
    set Vaccount to 0.
    set VACEnginesStep to List("","","","","","").
    if Tank:name:contains("SEP.23.SHIP.DEPOT") {
        set ShipType to "Depot".
        set CargoMassStep to CargoMassStep + Tank:mass - Tank:drymass.
        if stock {
            set MaxCargoToOrbit to 291000.
            set RCSThrust to 80.
        }
        else if KSRSS {
            set MaxCargoToOrbit to 521000.
            set RCSThrust to 140.
        }
        else if RSS {
            set MaxCargoToOrbit to 1710000.
            set RCSThrust to 200.
        }
    }
    Treewalking(Core:part).
    function TreeWalking {
        parameter StartPart.
        for x in StartPart:children {
            if x:name:contains("SEP.23.BOOSTER.INTEGRATED") {}
            else if x:name:contains("SEP.25.BOOSTER.CORE") {}
            else if x:name:contains("SEP.23.SHIP.BODY") {}
			else if x:name:contains("SEP.24.SHIP.CORE") {}
            else if x:name:contains("SEP.23.BOOSTER.HSR") {}
            else if x:name:contains("SEP.25.BOOSTER.HSR") {}
            else if x:name:contains("VS.25.HSR.BL3") {}
            else {
                if x:name:contains("SEP.23.RAPTOR2.SL.RC") and x:parent:name:contains("SHIP") {
                    set SL to true.
                    set SLcount to SLcount + 1.
                }
                else if x:name:contains("SEP.23.RAPTOR.VAC") {
                    set Vac to true.
                    set Vaccount to Vaccount + 1.
                }
                else if x:name:contains("SEP.23.SHIP.AFT.LEFT") or x:title = "Donnager MK-1 Rear Left Flap" or x:title = "Starship Rear Left Flap" {
                    set ALflap to x.
                }
                else if x:name:contains("SEP.23.SHIP.AFT.RIGHT") or x:title = "Donnager MK-1 Rear Right Flap" or x:title = "Starship Rear Right Flap" {
                    set ARflap to x.
                }
                else if x:name:contains("SEP.23.SHIP.FWD.LEFT") or x:title = "Donnager MK-1 Front Left Flap" or x:title = "Starship Forward Left Flap" {
                    set FLflap to x.
                }
                else if x:name:contains("SEP.23.SHIP.FWD.RIGHT") or x:title = "Donnager MK-1 Front Right Flap" or x:title = "Starship Forward Right Flap" {
                    set FRflap to x.
                }
				else if x:name:contains("SEP.24.SHIP.AFT.LEFT.FLAP") or x:title = "Donnager MK-3 Rear Left Flap" or x:title = "Starship Block 1 Rear Left Flap" {
                    set ALflap to x.
                }
                else if x:name:contains("SEP.24.SHIP.AFT.RIGHT.FLAP") or x:title = "Donnager MK-3 Rear Right Flap" or x:title = "Starship Block 1 Rear Right Flap" {
                    set ARflap to x.
                }
                else if x:name:contains("SEP.24.SHIP.FWD.LEFT.FLAP") or x:title = "Donnager MK-3 Front Left Flap" or x:title = "Starship Block 1 Forward Left Flap" {
                    set FLflap to x.
                }
                else if x:name:contains("SEP.24.SHIP.FWD.RIGHT.FLAP") or x:title = "Donnager MK-3 Front Right Flap" or x:title = "Starship Block 1 Forward Right Flap" {
                    set FRflap to x.
                }
                else if x:name:contains("SEP.23.SHIP.HEADER") {
                    set HeaderTank to x.
                }
                else if x:title = "Donnager MK-1 Header Tank" {
                    set HeaderTank to x.
                }
				else if x:title = "Donnager MK-3 Header Tank" or x:name:contains("SEP.24.SHIP.HEADER") {
                    set HeaderTank to x.
                }
                else if x:name:contains("SEP.23.SHIP.CARGO") and not x:name:contains("SEP.23.SHIP.CARGO.EXP") {
                    set Nose to x.
                    set ShipType to "Cargo".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
				else if x:name:contains("SEP.24.SHIP.NOSECONE") and not x:name:contains("SEP.24.SHIP.NOSECONE.EXP") {
                    set Nose to x.
                    set ShipType to "Block1".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
                else if x:name:contains("SEP.24.SHIP.CARGO") and not x:name:contains("SEP.24.SHIP.CARGO.EXP") {
                    set Nose to x.
                    set MaxCargoToOrbit to 66000.
                    set ShipType to "Block1Cargo".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
                else if x:name:contains("SEP.24.SHIP.NOSECONE.EXP") {
                    set Nose to x.
                    set MaxCargoToOrbit to 65000.
                    set ShipType to "Block1Exp".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
                else if x:name:contains("SEP.24.SHIP.CARGO.EXP") {
                    set Nose to x.
                    set MaxCargoToOrbit to 69000.
                    set ShipType to "Block1CargoExp".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
                else if x:name:contains("SEP.24.SHIP.PEZ") and not x:name:contains("EXP") {
                    set Nose to x.
                    set MaxCargoToOrbit to 65000.
                    set ShipType to "Block1PEZ".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
                else if x:name:contains("SEP.24.SHIP.PEZ.EXP") {
                    set Nose to x.
                    set MaxCargoToOrbit to 68000.
                    set ShipType to "Block1PEZExp".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
                else if x:name:contains("SEP.23.SHIP.CREW") {
                    set Nose to x.
                    set ShipType to "Crew".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
                else if x:name:contains("SEP.23.SHIP.TANKER") {
                    set Nose to x.
                    set ShipType to "Tanker".
                    set CargoMassStep to CargoMassStep + x:mass - x:drymass.
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                    if RSS {
                        set MaxCargoToOrbit to 150000.
                    } else if KSRSS {
                        set MaxCargoToOrbit to 97000.
                    } else {
                        set MaxCargoToOrbit to 79000.
                    }
                }
                else if x:name:contains("SEP.23.SHIP.CARGO.EXP") {
                    set Nose to x.
                    set ShipType to "Expendable".
                    set Nose:getmodule("kOSProcessor"):volume:name to "watchdog".
                }
                else if not (ShipType = "Tanker") and not x:name:contains("SEP.25.BOOSTER.CORE") {
                    set CargoMassStep to CargoMassStep + x:mass.
                    set CargoItems to CargoItems + 1.
                    set CargoCoG to CargoCoG + vdot(x:position - Tank:position, facing:forevector) * x:mass.
                }
                
                set ShipMassStep to ShipMassStep + (x:mass).
                PartListStep:add(x).
                Treewalking(x).
            }
        }
    }

    if SL and SLcount = 3 {
        set SL1 to false.
        set SL2 to false.
        set SL3 to false.
        for x in Tank:children {
            if x:parent:name:contains("SEP.24.SHIP.CORE") or x:parent:name:contains("SEP.23.SHIP.BODY") {
                if x:name:contains("SEP.23.RAPTOR2.SL.RC") {
                    set partPos to x:position - Tank:position.
                    set compPos to Tank:facing:topvector.
                    if vAng(partPos, compPos) < 89 {
                        set SLEnginesStep[0] to x.
                        set SL1 to true.
                    }  
                    else {
                        set compPos to -Tank:facing:starvector.
                        if vAng(partPos, compPos) < 89 {
                            set SLEnginesStep[1] to x.
                            set SL2 to true.
                        } 
                        else {
                            set compPos to Tank:facing:starvector.
                            if vAng(partPos, compPos) < 89 {
                                set SLEnginesStep[2] to x.
                                set SL3 to true.
                            }
                        }
                    }
                }
            }
        }
        set SLcount to 0.
        if SL1 and SL2 and SL3 {}
        else {
            print("Not all SLEngines have been set..!!!").
        }
    } 
    else {
        print("SLEngine count is wrong!").
        hudtext("SLEngine count is wrong! (" + SLcount + "/3)",10,2,18,red,false).
    }

    if Vac and Vaccount = 3 {
        set VACEnginesStep to List("","","").
        set Vac1 to false.
        set Vac2 to false.
        set Vac3 to false.
        for x in Tank:children {
            if x:parent:name:contains("SEP.24.SHIP.CORE") or x:parent:name:contains("SEP.23.SHIP.BODY") {
                if x:name:contains("SEP.23.RAPTOR.VAC") {
                    set partPos to x:position - Tank:position.
                    set compPos to -Tank:facing:topvector.
                    if vAng(partPos, compPos) < 89 {
                        set VACEnginesStep[0] to x.
                        set Vac1 to true.
                    }  
                    else {
                        set compPos to Tank:facing:starvector.
                        if vAng(partPos, compPos) < 89 {
                            set VACEnginesStep[1] to x.
                            set Vac2 to true.
                        } 
                        else {
                            set compPos to -Tank:facing:starvector.
                            if vAng(partPos, compPos) < 89 {
                                set VACEnginesStep[2] to x.
                                set Vac3 to true.
                            }
                        }
                    }
                }
            }
        }
        set Vaccount to 0.
        if Vac1 and Vac2 and Vac3 {}
        else {
            print("Not all VACEngines have been set..!!!").
        }
    } 
    else if Vac and Vaccount = 6 {
        set Vac1 to false.
        set Vac2 to false.
        set Vac3 to false.
        set Vac4 to false.
        set Vac5 to false.
        set Vac6 to false.
        for x in Tank:children {
            if x:parent:name:contains("SEP.24.SHIP.CORE") or x:parent:name:contains("SEP.23.SHIP.BODY") {
                if x:name:contains("SEP.23.RAPTOR.VAC") {
                    set partPos to vxcl(Tank:facing:forevector,x:position - Tank:position).
                    set compPos to -Tank:facing:starvector.
                    if vAng(partPos, compPos) < 10 {
                        set VACEnginesStep[0] to x.
                        set Vac1 to true.
                    }  
                    else {
                        set compPos to -Tank:facing:starvector - 2*Tank:facing:topvector.
                        if vAng(partPos, compPos) < 10 {
                            set VACEnginesStep[1] to x.
                            set Vac2 to true.
                        } 
                        else {
                            set compPos to Tank:facing:starvector - 2*Tank:facing:topvector.
                            if vAng(partPos, compPos) < 10 {
                                set VACEnginesStep[2] to x.
                                set Vac3 to true.
                            }
                            else {
                                set compPos to Tank:facing:starvector.
                                if vAng(partPos, compPos) < 10 {
                                    set VACEnginesStep[3] to x.
                                    set Vac4 to true.
                                }
                                else {
                                    set compPos to Tank:facing:starvector + 2*Tank:facing:topvector.
                                    if vAng(partPos, compPos) < 10 {
                                        set VACEnginesStep[4] to x.
                                        set Vac5 to true.
                                    }
                                    else {
                                        set compPos to -Tank:facing:starvector + 2*Tank:facing:topvector.
                                        if vAng(partPos, compPos) < 10 {
                                            set VACEnginesStep[5] to x.
                                            set Vac6 to true.
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        set Vaccount to 0.
        if Vac1 and Vac2 and Vac3 and Vac4 and Vac5 and Vac6 {}
        else {
            print("Not all VACEngines have been set..!!!").
        }
    } 
    else {
        print("VACEngine count is wrong!").
        hudtext("VACEngine count is wrong! (" + Vaccount + "; needs 3 or 6)",10,2,18,red,false).
    }

    set SLEngines to SLEnginesStep.
    set VACEngines to VACEnginesStep.
    set NrOfVacEngines to VACEngines:length.
    set ShipMass to ShipMassStep * 1000.
    set CargoMass to CargoMassStep * 1000.
    set PartList to PartListStep.
    set NrofCargoItems to CargoItems.
    set CargoCG to CargoCoG.

    for res in ship:resources {
        if res:name = "LiquidFuel" {
            set LFcap to res:capacity.
        }
        if res:name = "LqdMethane" {
            set LFcap to res:capacity.
        }
        if res:name = "Oxidizer" {
            set Oxcap to res:capacity.
        }
        if res:name = "ElectricCharge" {
            set ELECcap to res:capacity.
        }
    }
    wait 0.01.

    if SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length > 0 {
        set oldBooster to true.
        set Boosterconnected to true.
        set sAltitude:style:textcolor to grey.
        set sSpeed:style:textcolor to grey.
        set sLOXLabel:style:textcolor to grey.
        set sLOXSlider:style:bg to "starship_img/telemetry_fuel_grey".
        set sCH4Label:style:textcolor to grey.
        set sCH4Slider:style:bg to "starship_img/telemetry_fuel_grey".
        set sThrust:style:textcolor to grey.
        set BoosterEngines to SHIP:PARTSNAMED("SEP.23.BOOSTER.CLUSTER").
        set GridFins to SHIP:PARTSNAMED("SEP.23.BOOSTER.GRIDFIN").
        set HSR to SHIP:PARTSNAMED("SEP.23.BOOSTER.HSR").
        set BoosterCore to SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED").
        if BoosterCore:length > 0 {
            set BoosterCore[0]:getmodule("kOSProcessor"):volume:name to "Booster".
            print(round(BoosterCore[0]:drymass)).
            if round(BoosterCore[0]:drymass) = 55 and not (RSS) or round(BoosterCore[0]:drymass) = 80 and RSS {
                set BoosterCorrectVariant to true.
            }
            else {
                set BoosterCorrectVariant to false.
            }
            if ShipType = "Depot" {
                sendMessage(processor(volume("Booster")),"Depot").
            }
            sendMessage(processor(volume("Booster")), "ShipDetected").
        }
        set sTelemetry:style:bg to "starship_img/telemetry_bg_".
        set missionTimeLabel:text to "".
    } else if ship:partsnamed("SEP.25.BOOSTER.CORE"):length > 0 {
        set Boosterconnected to true.
        set sAltitude:style:textcolor to grey.
        set sSpeed:style:textcolor to grey.
        set sLOXLabel:style:textcolor to grey.
        set sLOXSlider:style:bg to "starship_img/telemetry_fuel_grey".
        set sCH4Label:style:textcolor to grey.
        set sCH4Slider:style:bg to "starship_img/telemetry_fuel_grey".
        set sThrust:style:textcolor to grey.
        set BoosterEngines to SHIP:PARTSNAMED("SEP.25.BOOSTER.CLUSTER").
        set GridFins to SHIP:PARTSNAMED("SEP.25.BOOSTER.GRIDFIN").
        if ship:partsnamed("VS.25.HSR.BL3"):length > 0 {
            set HSR to SHIP:PARTSNAMED("VS.25.HSR.BL3").
        } else {
            set HSR to SHIP:PARTSNAMED("SEP.25.BOOSTER.HSR").
        }
        set BoosterCore to SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE").
        if BoosterCore:length > 0 {
            set BoosterCore[0]:getmodule("kOSProcessor"):volume:name to "Booster".
            //print(round(BoosterCore[0]:drymass)).
            if round(BoosterCore[0]:drymass) = 55 and not (RSS) or round(BoosterCore[0]:drymass) = 80 and RSS {
                set BoosterCorrectVariant to true.
            }
            else {
                set BoosterCorrectVariant to false.
            }
            if ShipType = "Depot" {
                sendMessage(processor(volume("Booster")),"Depot").
            }
            sendMessage(processor(volume("Booster")), "ShipDetected").
        }
        set sTelemetry:style:bg to "starship_img/telemetry_bg_".
        set missionTimeLabel:text to "".
        print(BoosterCore[0]:mass).
    }
    else {
        set Boosterconnected to false.
        if not runningprogram = "LAUNCH" {
            set sTelemetry:style:bg to "starship_img/telemetry_bg".
        }

    }

    if Boosterconnected and not Hotstaging {
        if BoosterEngines[0]:children:length > 1 and ( BoosterEngines[0]:children[0]:name:contains("SEP.23.RAPTOR2.SL.RC") or BoosterEngines[0]:children[0]:name:contains("SEP.23.RAPTOR2.SL.RB") 
                or BoosterEngines[0]:children[1]:name:contains("SEP.23.RAPTOR2.SL.RC") or BoosterEngines[0]:children[1]:name:contains("SEP.23.RAPTOR2.SL.RB") ) {
            set BoosterSingleEngines to true.
            set BoosterSingleEnginesRB to list().
            set BoosterSingleEnginesRC to list().
            set x to 1.
            until x > 33 or not Boosterconnected {
                if x < 14 BoosterSingleEnginesRC:insert(x-1,ship:partstagged(x:tostring)[0]).
                else BoosterSingleEnginesRB:insert(x-14,ship:partstagged(x:tostring)[0]).
                set x to x + 1.
            }
        } 
        else {
            set BoosterSingleEngines to false.
        }
        print "bEngines set.. SingleEng.:" + BoosterSingleEngines.
    }

    if ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
        set OnOrbitalMount to True.
        set OLM to ship:partstitled("Starship Orbital Launch Mount")[0].
        set OLM:getmodule("kOSProcessor"):volume:name to "OrbitalLaunchMount".
        set TowerBase to ship:partstitled("Starship Orbital Launch Integration Tower Base")[0].
        set TowerCore to ship:partstitled("Starship Orbital Launch Integration Tower Core")[0].
        //set TowerTop to ship:partstitled("Starship Orbital Launch Integration Tower Rooftop")[0].
        set SQD to ship:partstitled("Starship Quick Disconnect Arm")[0].
        set SteelPlate to ship:partstitled("Water Cooled Steel Plate")[0].
        Set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
        sendMessage(processor(volume("OrbitalLaunchMount")), "getArmsVersion").
        if RSS {
            set ArmsHeight to (Mechazilla:position - ship:body:position):mag - SHIP:BODY:RADIUS - ship:geoposition:terrainheight + 12.
        }
        else {
            set ArmsHeight to (Mechazilla:position - ship:body:position):mag - SHIP:BODY:RADIUS - ship:geoposition:terrainheight + 7.5.
        }
        //SaveToSettings("ArmsHeight", ArmsHeight).
        set StackMass to ship:mass - OLM:Mass - TowerBase:mass - TowerCore:mass - Mechazilla:mass.
        print("Stack mass: " + StackMass).
        print(ship:mass).
    }
    else {
        set OnOrbitalMount to False.
        set OLM to false.
        set StackMass to ship:mass.
        //print("Stack mass (no OLM found): " + StackMass).
    }
    set partsfound to true.


    
}


//-------------Initial Program Start-Up--------------------//

function EngineTest {
    hudtext("Static Fire Test starting..",5,2,18,yellow,false).
    wait 5.
    lock throttle to 0.8.
    for eng in VACEngines {
        eng:activate.
        wait 0.2.
    } 
    wait 1.
    for eng in SLEngines {
        eng:activate.
        wait 0.2.
    } 
    wait 5.
    for eng in VACEngines {
        eng:shutdown.
        wait 0.2.
    } 
    wait 2.
    for eng in SLEngines {
        eng:shutdown.
        wait 0.2.
    } 
    lock throttle to 0.
    unlock throttle.
    hudtext("Static Fire Test complete..",5,2,18,green,false).
}


SetLoadDistances(ship, "default").
lock throttle to 0.
unlock throttle.

if OnOrbitalMount {
    if RSS {
        sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaHeight,12,0.8").
        sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaArms,8.2,1,97.5,false").
        sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaPushers,0,0.2,1.12,false").
        sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaStabilizers,0").
    }
    else {
        sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaHeight,4,0.5").
        sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaArms,8.2,1,97.5,false").
        sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaPushers,0,0.2,0.7,false").
        sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaStabilizers,0").
    }
    if ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
        set OnOrbitalMount to True.
        set OLM to ship:partstitled("Starship Orbital Launch Mount")[0].
        set OLM:getmodule("kOSProcessor"):volume:name to "OrbitalLaunchMount".
        set TowerBase to ship:partstitled("Starship Orbital Launch Integration Tower Base")[0].
        set TowerCore to ship:partstitled("Starship Orbital Launch Integration Tower Core")[0].
        //set TowerTop to ship:partstitled("Starship Orbital Launch Integration Tower Rooftop")[0].
        set SQD to ship:partstitled("Starship Quick Disconnect Arm")[0].
        set SteelPlate to ship:partstitled("Water Cooled Steel Plate")[0].
        Set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
        if SQD:getmodule("ModuleSLESequentialAnimate"):hasevent("Full Extension") {
            SQD:getmodule("ModuleSLESequentialAnimate"):DOEVENT("Full Extension").
        }
    }
}
set ship:type to "Ship".
ShipsInOrbit().
Tank:getmodule("ModuleDockingNode"):SETFIELD("docking acquire force", 0).
FindParts().

if ship:name:contains("OrbitalLaunchMount") {
    set ship:name to ("Starship " + ShipType).
}
print ShipType.
print "Starship Interface startup complete!".



//-------------Start Graphic User Interface-------------//

local ScaleUI is GUI(300).
    set ScaleUI:style:bg to "starship_img/starship_background".
    set ScaleUI:style:border:h to 10.
    set ScaleUI:style:border:v to 10.
    set ScaleUI:style:padding:v to 0.
    set ScaleUI:style:padding:h to 0.
    set ScaleUI:x to 240.
    set ScaleUI:y to 240.
    set ScaleUI:skin:button:bg to "starship_img/starship_background".
    set ScaleUI:skin:button:on:bg to "starship_img/starship_background_light".
    set ScaleUI:skin:button:hover:bg to "starship_img/starship_background_light".
    set ScaleUI:skin:button:hover_on:bg to "starship_img/starship_background_light".
    set ScaleUI:skin:button:active:bg to "starship_img/starship_background_light".
    set ScaleUI:skin:button:active_on:bg to "starship_img/starship_background_light".
    set ScaleUI:skin:button:border:v to 10.
    set ScaleUI:skin:button:border:h to 10.
    set ScaleUI:skin:button:textcolor to white.
    set ScaleUI:skin:label:textcolor to white.
local ScaleLayout is ScaleUI:addvlayout().
local ScaleQuest is ScaleLayout:addlabel().
    set ScaleQuest:text to "Enter your Vertical Resolution (f.e. 1080 for 1080p):".
    set ScaleQuest:style:margin:top to 12.
    set ScaleQuest:style:margin:bottom to 12.
    set ScaleQuest:style:margin:left to 12.
local ScaleSelect is ScaleLayout:addtextfield().
    set ScaleSelect:tooltip to "Vertical Resolution".
    set ScaleSelect:style:margin:bottom to 12.
    set ScaleSelect:style:margin:left to 12.
local ScaleConfirm is ScaleLayout:addbutton().
    set ScaleConfirm:text to "<b><color=green>Confirm</color></b>".
    set ScaleConfirm:onclick to {
        sTelemetry:hide().
        if ScaleSelect:text = "" {}
        else {
            set TScale to round(ScaleSelect:text:toscalar/1080,12).
            CreateTelemetry().
            if Boosterconnected {
                sendMessage(processor(Volume("Booster")),"ScaleT,"+TScale:tostring).
                set sTelemetry:style:bg to "".
            }
            SaveToSettings("TelemetryScale",TScale).
            wait 0.2.
            sTelemetry:show().
        }
        set scalebutton:pressed to false.
        ScaleUI:hide().
    }.
    



local g is GUI(600).
    set g:style:bg to "starship_img/starship_background".
    set g:style:border:h to 10.
    set g:style:border:v to 10.
    set g:style:padding:v to 0.
    set g:style:padding:h to 0.
    set g:x to -130.
    SetInterfaceLocation().


//-------------------------Skin-------------------------//


set g:skin:popupwindow:normal:bg to "starship_img/starship_background".
set g:skin:popupwindow:on:bg to "starship_img/starship_background".
set g:skin:popupwindow:hover:bg to "starship_img/starship_background".
set g:skin:popupwindow:hover_on:bg to "starship_img/starship_background".
set g:skin:popupwindow:active:bg to "starship_img/starship_background".
set g:skin:popupwindow:active_on:bg to "starship_img/starship_background".
set g:skin:popupwindow:focused:bg to "starship_img/starship_background".
set g:skin:popupwindow:focused_on:bg to "starship_img/starship_background".
set g:skin:popupwindow:border:v to 10.
set g:skin:popupwindow:border:h to 10.
set g:skin:popupwindow:margin:v to 0.
set g:skin:popupwindow:margin:h to 0.
set g:skin:popupwindow:padding:v to 0.
set g:skin:popupwindow:padding:h to 0.
set g:skin:popupwindow:height to 150.
set g:skin:popupmenuitem:fontsize to 18.


set g:skin:button:bg to "starship_img/starship_background".
set g:skin:button:on:bg to "starship_img/starship_background_light".
set g:skin:button:hover:bg to "starship_img/starship_background_light".
set g:skin:button:hover_on:bg to "starship_img/starship_background_light".
set g:skin:button:active:bg to "starship_img/starship_background_light".
set g:skin:button:active_on:bg to "starship_img/starship_background_light".
set g:skin:button:border:v to 10.
set g:skin:button:border:h to 10.
set g:skin:button:textcolor to white.

set g:skin:textfield:textcolor to white.
set g:skin:textfield:bg to "starship_img/starship_background".
set g:skin:textfield:on:bg to "starship_img/starship_background_light".
set g:skin:textfield:hover:bg to "starship_img/starship_background_light".
set g:skin:textfield:hover_on:bg to "starship_img/starship_background_light".
set g:skin:textfield:active:bg to "starship_img/starship_background_light".
set g:skin:textfield:active_on:bg to "starship_img/starship_background_light".
set g:skin:textfield:focused:bg to "starship_img/starship_background_light".
set g:skin:textfield:focused_on:bg to "starship_img/starship_background_light".
set g:skin:textfield:border:v to 10.
set g:skin:textfield:border:h to 10.
set g:skin:textfield:fontsize to 19.

set g:skin:toggle:fontsize to 15.
set g:skin:toggle:wordwrap to false.
set g:skin:toggle:bg to "starship_img/starship_radiobutton".
set g:skin:toggle:on:bg to "starship_img/starship_radiobutton_on".
set g:skin:toggle:hover:bg to "starship_img/starship_radiobutton_hover".
set g:skin:toggle:hover_on:bg to "starship_img/starship_radiobutton_on".
set g:skin:toggle:active:bg to "starship_img/starship_radiobutton_on".
set g:skin:toggle:active_on:bg to "starship_img/starship_radiobutton_on".
set g:skin:toggle:border:left to 0.
set g:skin:toggle:border:top to 0.
set g:skin:toggle:border:right to 0.
set g:skin:toggle:border:bottom to 0.

set g:skin:label:textcolor to white.


//---------------Add Buttons and Functions--------------//


local box_all is g:addvlayout().

local topbuttonbar is box_all:addhlayout().
local launchlabel to topbuttonbar:addlabel("<size=16><b>LAUNCH</b></size>").
    set launchlabel:style:width to 80.
    set launchlabel:style:height to 35.
    set launchlabel:style:border:v to 10.
    set launchlabel:style:border:h to 10.
    set launchlabel:style:align to "CENTER".
    set launchlabel:style:bg to "starship_img/starship_background_dark".
    set launchlabel:tooltip to "Launch Button Inhibited".
    launchlabel:hide().
local launchbutton to topbuttonbar:addbutton("<size=16>LAUNCH</size>").
    set launchbutton:toggle to true.
    set launchbutton:style:width to 80.
    set launchbutton:style:height to 35.
    set launchbutton:tooltip to "Prepare the Ship for Launch (with the option to cancel)".
local landlabel to topbuttonbar:addlabel("<size=16><b>DE-ORBIT & LAND</b></size>").
    set landlabel:style:width to 155.
    set landlabel:style:height to 35.
    set landlabel:style:border:v to 10.
    set landlabel:style:border:h to 10.
    set landlabel:style:align to "CENTER".
    set landlabel:style:bg to "starship_img/starship_background_dark".
    set landlabel:tooltip to "De-orbit Button Inhibited".
    landlabel:hide().
local landbutton to topbuttonbar:addbutton("<size=16>DE-ORBIT & LAND</size>").
    set landbutton:toggle to true.
    set landbutton:style:width to 155.
    set landbutton:style:height to 35.
    set landbutton:tooltip to "Prepare the Ship for Re-Entry and Landing (with the option to cancel)".
local statuslabel to topbuttonbar:addlabel("").
    set statuslabel:style:height to 35.
    set statuslabel:style:fontsize to 16.
    set statuslabel:style:align to "center".
    set statuslabel:style:vstretch to true.
    set statuslabel:style:hstretch to true.
local scalebutton is topbuttonbar:addbutton().
    set scalebutton:toggle to true.
    set scalebutton:style:width to 35.
    set scalebutton:style:height to 35.
    set scalebutton:style:bg to "starship_img/telemetryScale".
    set scalebutton:style:on:bg to "starship_img/telemetryScale_on".
    set scalebutton:style:hover:bg to "starship_img/telemetryScale_hover".
    set scalebutton:style:hover_on:bg to "starship_img/telemetryScale_on".
    set scalebutton:style:active:bg to "starship_img/telemetryScale_hover".
    set scalebutton:style:active_on:bg to "starship_img/telemetryScale_hover".
    set scalebutton:style:border:v to 0.
    set scalebutton:style:border:h to 0.
    set scalebutton:tooltip to "Scale Settings for the Telemetry".
local statusbutton is topbuttonbar:addbutton().
    set statusbutton:toggle to true.
    set statusbutton:style:width to 35.
    set statusbutton:style:height to 35.
    set statusbutton:style:bg to "starship_img/starship_status".
    set statusbutton:style:on:bg to "starship_img/starship_status_on".
    set statusbutton:style:hover:bg to "starship_img/starship_status_hover".
    set statusbutton:style:hover_on:bg to "starship_img/starship_status_on".
    set statusbutton:style:active:bg to "starship_img/starship_status_hover".
    set statusbutton:style:active_on:bg to "starship_img/starship_status_hover".
    set statusbutton:style:border:v to 0.
    set statusbutton:style:border:h to 0.
    set statusbutton:tooltip to "Status Page".
local crewbutton is topbuttonbar:addbutton().
    set crewbutton:toggle to true.
    set crewbutton:style:width to 35.
    set crewbutton:style:height to 35.
    set crewbutton:style:bg to "starship_img/starship_crew_icon".
    set crewbutton:style:on:bg to "starship_img/starship_crew_icon_on".
    set crewbutton:style:hover:bg to "starship_img/starship_crew_icon_hover".
    set crewbutton:style:hover_on:bg to "starship_img/starship_crew_icon_on".
    set crewbutton:style:active:bg to "starship_img/starship_crew_icon_hover".
    set crewbutton:style:active_on:bg to "starship_img/starship_crew_icon_hover".
    set crewbutton:style:border:v to 0.
    set crewbutton:style:border:h to 0.
    set crewbutton:tooltip to "Crew Page".
crewbutton:hide().
local orbitbutton is topbuttonbar:addbutton().
    set orbitbutton:toggle to true.
    set orbitbutton:style:width to 35.
    set orbitbutton:style:height to 35.
    set orbitbutton:style:bg to "starship_img/starship_orbit".
    set orbitbutton:style:on:bg to "starship_img/starship_orbit_on".
    set orbitbutton:style:hover:bg to "starship_img/starship_orbit_hover".
    set orbitbutton:style:hover_on:bg to "starship_img/starship_orbit_on".
    set orbitbutton:style:active:bg to "starship_img/starship_orbit_hover".
    set orbitbutton:style:active_on:bg to "starship_img/starship_orbit_hover".
    set orbitbutton:style:border:v to 0.
    set orbitbutton:style:border:h to 0.
    set orbitbutton:tooltip to "Orbit Page".
local maneuverbutton is topbuttonbar:addbutton().
    set maneuverbutton:toggle to true.
    set maneuverbutton:style:width to 35.
    set maneuverbutton:style:height to 35.
    set maneuverbutton:style:bg to "starship_img/starship_maneuver_icon".
    set maneuverbutton:style:on:bg to "starship_img/starship_maneuver_icon_on".
    set maneuverbutton:style:hover:bg to "starship_img/starship_maneuver_icon_hover".
    set maneuverbutton:style:hover_on:bg to "starship_img/starship_maneuver_icon_on".
    set maneuverbutton:style:active:bg to "starship_img/starship_maneuver_icon_hover".
    set maneuverbutton:style:active_on:bg to "starship_img/starship_maneuver_icon_hover".
    set maneuverbutton:style:border:v to 0.
    set maneuverbutton:style:border:h to 0.
    set maneuverbutton:tooltip to "Maneuver Page".
maneuverbutton:hide().
local enginebutton is topbuttonbar:addbutton().
    set enginebutton:toggle to true.
    set enginebutton:style:width to 35.
    set enginebutton:style:height to 35.
    set enginebutton:style:bg to "starship_img/starship_engine".
    set enginebutton:style:on:bg to "starship_img/starship_engine_on".
    set enginebutton:style:hover:bg to "starship_img/starship_engine_hover".
    set enginebutton:style:hover_on:bg to "starship_img/starship_engine_on".
    set enginebutton:style:active:bg to "starship_img/starship_engine_hover".
    set enginebutton:style:active_on:bg to "starship_img/starship_engine_hover".
    set enginebutton:style:border:v to 0.
    set enginebutton:style:border:h to 0.
    set enginebutton:tooltip to "Engines Page".
local attitudebutton is topbuttonbar:addbutton().
    set attitudebutton:toggle to true.
    set attitudebutton:style:width to 35.
    set attitudebutton:style:height to 35.
    set attitudebutton:style:bg to "starship_img/starship_attitude".
    set attitudebutton:style:on:bg to "starship_img/starship_attitude_on".
    set attitudebutton:style:hover:bg to "starship_img/starship_attitude_hover".
    set attitudebutton:style:hover_on:bg to "starship_img/starship_attitude_on".
    set attitudebutton:style:active:bg to "starship_img/starship_attitude_hover".
    set attitudebutton:style:active_on:bg to "starship_img/starship_attitude_hover".
    set attitudebutton:style:border:v to 0.
    set attitudebutton:style:border:h to 0.
    set attitudebutton:tooltip to "Manual Re-Entry Attitude Page (Landing armed @ 10km Radar Altitude)".
local cargobutton is topbuttonbar:addbutton().
    set cargobutton:toggle to true.
    set cargobutton:style:width to 35.
    set cargobutton:style:height to 35.
    set cargobutton:style:bg to "starship_img/starship_cargo".
    set cargobutton:style:on:bg to "starship_img/starship_cargo_on".
    set cargobutton:style:hover:bg to "starship_img/starship_cargo_hover".
    set cargobutton:style:hover_on:bg to "starship_img/starship_cargo_on".
    set cargobutton:style:active:bg to "starship_img/starship_cargo_hover".
    set cargobutton:style:active_on:bg to "starship_img/starship_cargo_hover".
    set cargobutton:style:border:v to 0.
    set cargobutton:style:border:h to 0.
    set cargobutton:tooltip to "Cargo Page".
cargobutton:hide().
local towerbutton is topbuttonbar:addbutton().
    set towerbutton:toggle to true.
    set towerbutton:style:width to 35.
    set towerbutton:style:height to 35.
    set towerbutton:style:bg to "starship_img/starship_tower".
    set towerbutton:style:on:bg to "starship_img/starship_tower_on".
    set towerbutton:style:hover:bg to "starship_img/starship_tower_hover".
    set towerbutton:style:hover_on:bg to "starship_img/starship_tower_on".
    set towerbutton:style:active:bg to "starship_img/starship_tower_hover".
    set towerbutton:style:active_on:bg to "starship_img/starship_tower_hover".
    set towerbutton:style:border:v to 0.
    set towerbutton:style:border:h to 0.
    set towerbutton:tooltip to "Tower Page".
towerbutton:hide().
local settingsbutton is topbuttonbar:addbutton().
    set settingsbutton:toggle to true.
    set settingsbutton:style:width to 35.
    set settingsbutton:style:height to 35.
    set settingsbutton:style:bg to "starship_img/starship_settings".
    set settingsbutton:style:on:bg to "starship_img/starship_settings_on".
    set settingsbutton:style:hover:bg to "starship_img/starship_settings_hover".
    set settingsbutton:style:hover_on:bg to "starship_img/starship_settings_on".
    set settingsbutton:style:active:bg to "starship_img/starship_settings_hover".
    set settingsbutton:style:active_on:bg to "starship_img/starship_settings_hover".
    set settingsbutton:style:border:v to 0.
    set settingsbutton:style:border:h to 0.
    set settingsbutton:tooltip to "Settings Page".
local g_close is topbuttonbar:addbutton("<size=20>X</size>").
    set g_close:style:textcolor to white.
    set g_close:style:bg to "starship_img/starship_blue_bg".
    set g_close:style:on:bg to "starship_img/starship_blue_bg".
    set g_close:style:hover:bg to "starship_img/starship_blue_bg".
    set g_close:style:hover_on:bg to "starship_img/starship_blue_bg".
    set g_close:style:active:bg to "starship_img/starship_blue_bg".
    set g_close:style:active_on:bg to "starship_img/starship_blue_bg".
    set g_close:style:margin:top to 6.
    set g_close:style:margin:right to 6.
    set g_close:style:width to 30.
    set g_close:tooltip to "Close the GUI and shut down the CPU? (toggle CPU power to restart)".

set g_close:onclick to {
    if not ClosingIsRunning {
        set ClosingIsRunning to true.
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        Droppriority().
        ShowHomePage().
        set message1:text to "<b><color=red>Are you sure you want to Quit?</color></b>".
        set message2:text to "<b><color=yellow>The Interface will shut down..</color></b>".
        set message3:text to "<b>Quit <color=white>or</color> Cancel?</b><color=white><size=14>  (Restart: Toggle kOS Power in Tank Section)</size></color>".
        set message3:style:textcolor to cyan.
        set cancel:text to "<b>CANCEL</b>".
        set cancel:style:textcolor to cyan.
        set execute:text to "<b>QUIT</b>".
        LogToFile("Close Button Clicked, waiting for confirm").
        if LandButtonIsRunning or LaunchButtonIsRunning or AbortLaunchInProgress {InhibitButtons(1, 0, 0).}
        else {InhibitButtons(0, 0, 0).}
        if runningprogram = "Venting Fuel.." {
            ShutDownAllEngines()..
        }
        if confirm() {
            sas on.
            lock throttle to 0.
            unlock throttle.
            if defined Nose {
                if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).}
                else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
                Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
                }
            }
            Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
            if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
            LogToFile("Closing GUI confirmed").
            if defined watchdog {
                Watchdog:deactivate().
            }
            g:hide().
            shutdown.
        }
        else {
            LogToFile("Closing GUI Cancelled").
            set execute:text to "<b>EXECUTE</b>".
            if LandButtonIsRunning or LaunchButtonIsRunning {
                InhibitButtons(1, 1, 0).
                set message1:text to "".
                set message2:text to "".
                set message3:text to "".
                set message3:style:textcolor to white.
                if Boosterconnected {
                    set cancel:text to "<b>ABORT</b>".
                    set cancel:style:textcolor to red.
                }
                else if LaunchButtonIsRunning {
                    InhibitButtons(1, 1, 1).
                }
            }
            else {
                InhibitButtons(0, 1, 1).
                set message1:text to "".
                set message2:text to "".
                set message3:text to "".
                set message3:style:textcolor to white.
                if AttitudeIsRunning {
                    set attitudebutton:pressed to true.
                }
            }
            SetShipBGPage().
        }
        set ClosingIsRunning to false.
    }
}.

    
local mainbox is box_all:addvlayout().
local flightstack is mainbox:addstack().
local settingsstack is mainbox:addstack().
local cargostack is mainbox:addstack().
local attitudestack is mainbox:addstack().
local statusstack is mainbox:addstack().
local orbitstack is mainbox:addstack().
local enginestack is mainbox:addstack().
local crewstack is mainbox:addstack().
local towerstack is mainbox:addstack().
local maneuverstack is mainbox:addstack().
mainbox:showonly(flightstack).


set settingsbutton:ontoggle to {
    parameter toggle.
    if toggle {
        set cargobutton:pressed to false.
        set attitudebutton:pressed to false.
        set statusbutton:pressed to false.
        set orbitbutton:pressed to false.
        set enginebutton:pressed to false.
        set crewbutton:pressed to false.
        set towerbutton:pressed to false.
        set maneuverbutton:pressed to false.
        if InhibitPages = false {
            mainbox:showonly(settingsstack).
        }
        else {
            set settingsbutton:pressed to false.
        }
    }
    else {mainbox:showonly(flightstack).}
}.

set cargobutton:ontoggle to {
    parameter toggle.
    if toggle {
        set settingsbutton:pressed to false.
        set attitudebutton:pressed to false.
        set statusbutton:pressed to false.
        set orbitbutton:pressed to false.
        set enginebutton:pressed to false.
        set crewbutton:pressed to false.
        set towerbutton:pressed to false.
        set maneuverbutton:pressed to false.
        if InhibitPages = false {
            mainbox:showonly(cargostack).
        }
        else {
            set cargobutton:pressed to false.
        }
    }
    else {mainbox:showonly(flightstack).}
}.
    
set attitudebutton:ontoggle to {
    parameter toggle.
    if toggle {
        set settingsbutton:pressed to false.
        set cargobutton:pressed to false.
        set statusbutton:pressed to false.
        set orbitbutton:pressed to false.
        set enginebutton:pressed to false.
        set crewbutton:pressed to false.
        set towerbutton:pressed to false.
        set maneuverbutton:pressed to false.
        if InhibitPages = false {
            mainbox:showonly(attitudestack).
        }
        else {
            set attitudebutton:pressed to false.
        }
    }
    else {mainbox:showonly(flightstack).}
}.

set scalebutton:ontoggle to {
    parameter toggle.
    if toggle {
        set ScaleSelect:text to "".
        ScaleUI:show().
    }
    else ScaleUI:hide().
}.


set statusbutton:ontoggle to {
    parameter toggle.
    if toggle {
        set settingsbutton:pressed to false.
        set cargobutton:pressed to false.
        set attitudebutton:pressed to false.
        set orbitbutton:pressed to false.
        set enginebutton:pressed to false.
        set crewbutton:pressed to false.
        set towerbutton:pressed to false.
        set maneuverbutton:pressed to false.
        mainbox:showonly(statusstack).
    }
    else {mainbox:showonly(flightstack).}
}.
    
set orbitbutton:ontoggle to {
    parameter toggle.
    if toggle {
        set settingsbutton:pressed to false.
        set cargobutton:pressed to false.
        set attitudebutton:pressed to false.
        set statusbutton:pressed to false.
        set enginebutton:pressed to false.
        set crewbutton:pressed to false.
        set towerbutton:pressed to false.
        set maneuverbutton:pressed to false.
        mainbox:showonly(orbitstack).
    }
    else {mainbox:showonly(flightstack).}
}.
    
set enginebutton:ontoggle to {
    parameter toggle.
    if toggle {
        set settingsbutton:pressed to false.
        set cargobutton:pressed to false.
        set attitudebutton:pressed to false.
        set statusbutton:pressed to false.
        set orbitbutton:pressed to false.
        set crewbutton:pressed to false.
        set towerbutton:pressed to false.
        set maneuverbutton:pressed to false.
        mainbox:showonly(enginestack).
    }
    else {mainbox:showonly(flightstack).}
}.

set crewbutton:ontoggle to {
    parameter toggle.
    if toggle {
        set g:style:height to 315.
        set settingsbutton:pressed to false.
        set cargobutton:pressed to false.
        set attitudebutton:pressed to false.
        set statusbutton:pressed to false.
        set enginebutton:pressed to false.
        set orbitbutton:pressed to false.
        set towerbutton:pressed to false.
        set maneuverbutton:pressed to false.
        mainbox:showonly(crewstack).
    }
    else {
        set g:style:height to 192.
        mainbox:showonly(flightstack).
    }
}.

set towerbutton:ontoggle to {
    parameter toggle.
    if toggle {
        set settingsbutton:pressed to false.
        set cargobutton:pressed to false.
        set attitudebutton:pressed to false.
        set statusbutton:pressed to false.
        set enginebutton:pressed to false.
        set orbitbutton:pressed to false.
        set crewbutton:pressed to false.
        set maneuverbutton:pressed to false.
        mainbox:showonly(towerstack).
    }
    else {mainbox:showonly(flightstack).}
}.

set maneuverbutton:ontoggle to {
    parameter toggle.
    if toggle {
        set settingsbutton:pressed to false.
        set cargobutton:pressed to false.
        set attitudebutton:pressed to false.
        set statusbutton:pressed to false.
        set enginebutton:pressed to false.
        set orbitbutton:pressed to false.
        set crewbutton:pressed to false.
        set towerbutton:pressed to false.
        mainbox:showonly(maneuverstack).
    }
    else {mainbox:showonly(flightstack).}
}.


local textbox is flightstack:addhlayout().
    SetShipBGPage().
local textboxvlayout1 is textbox:addvlayout().
    set textboxvlayout1:style:vstretch to true.
local textboxvlayout2 is textbox:addvlayout().
    set textboxvlayout2:style:bg to "starship_img/starship_main_square_bg".
    set textboxvlayout2:style:vstretch to true.
    set textboxvlayout2:style:width to 150.
local message1 is textboxvlayout1:addlabel().
    set message1:style:wordwrap to false.
    set message1:style:margin:left to 10.
    set message1:style:margin:top to 10.
    set message1:style:width to 450.
    set message1:style:fontsize to 21.
local message2 is textboxvlayout1:addlabel().
    set message2:style:wordwrap to false.
    set message2:style:margin:left to 10.
    set message2:style:width to 450.
    set message2:style:fontsize to 21.
local message3 is textboxvlayout1:addlabel().
    set message3:style:wordwrap to false.
    set message3:style:margin:left to 10.
    set message3:style:width to 450.
    set message3:style:fontsize to 21.
local message12 is textboxvlayout2:addlabel("           0  CREW").
    set message12:style:wordwrap to false.
    set message12:style:margin:top to 8.
    set message12:style:margin:left to 10.
    set message12:style:width to 30.
    set message12:style:height to 30.
    set message12:style:fontsize to 15.
    set message12:tooltip to "Number of Crew onboard / Cargo Mass".
local message22 is textboxvlayout2:addlabel("          AVNCS 0/3").
    set message22:style:wordwrap to false.
    set message22:style:margin:left to 10.
    set message22:style:width to 30.
    set message22:style:height to 30.
    set message22:style:fontsize to 15.
    set message22:style:textcolor to grey.
    set message22:style:bg to "starship_img/starship_chip".
    set message22:tooltip to "GUI requirements fulfilled / Watchdog indicator (white/grey)".
local message32 is textboxvlayout2:addlabel("          NO COM").
    set message32:style:wordwrap to false.
    set message32:style:margin:left to 10.
    set message32:style:width to 30.
    set message32:style:height to 30.
    set message32:style:fontsize to 15.
    set message32:style:textcolor to grey.
    set message32:style:bg to "starship_img/starship_signal_grey".
    set message32:tooltip to "COM1 (signal with KSC) / DLK (Downlink) or TLM (Telemetry, logging enabled)".

    

local settingsstackhlayout is settingsstack:addhlayout().
    set settingsstackhlayout:style:bg to "starship_img/starship_main_square_bg".
local settingsstackvlayout1 is settingsstackhlayout:addvlayout().
    set settingsstackvlayout1:style:vstretch to 1.
    set settingsstackvlayout1:style:margin:h to 0.
local settingsstackvlayout2 is settingsstackhlayout:addvlayout().
    set settingsstackvlayout2:style:vstretch to 1.
    set settingsstackvlayout2:style:hstretch to 1.
local settingsstackvlayout3 is settingsstackhlayout:addvlayout().

local setting1label is settingsstackvlayout1:addlabel("<b>Target Landing Zone:</b>").
    set setting1label:style:margin:left to 10.
    set setting1label:style:margin:top to 10.
    set setting1label:style:fontsize to 19.
    set setting1label:style:wordwrap to false.
    set setting1label:style:width to 225.
    set setting1label:tooltip to "Ship Landing Target coordinates (e.g. " + DefaultLaunchSite + "). Default = Launchpad".
local setting1 is settingsstackvlayout2:addtextfield(DefaultLaunchSite).
    set setting1:style:width to 175.
    set setting1:style:margin:top to 10.
local setting2 is settingsstackvlayout1:addcheckbox("<b>  Show Tooltips</b>").
    set setting2:style:margin:left to 10.
    set setting2:style:margin:top to 7.
    set setting2:style:fontsize to 18.
    set setting2:style:bg to "starship_img/starship_toggle_off".
    set setting2:style:on:bg to "starship_img/starship_toggle_on".
    set setting2:style:hover:bg to "starship_img/starship_toggle_hover".
    set setting2:style:hover_on:bg to "starship_img/starship_toggle_hover".
    set setting2:style:active:bg to "starship_img/starship_toggle_off".
    set setting2:style:active_on:bg to "starship_img/starship_toggle_on".
    set setting2:style:width to 225.
    set setting2:style:height to 29.
    set setting2:style:overflow:right to -197.
    set setting2:style:overflow:left to -3.
    set setting2:style:overflow:top to -4.
    set setting2:style:overflow:bottom to -9.
    set setting2:tooltip to "Show tooltips like this one".
local TargetLZPicker is settingsstackvlayout2:addpopupmenu().
    set TargetLZPicker:style:textcolor to white.
    set TargetLZPicker:style:fontsize to 16.
    set TargetLZPicker:style:width to 175.
    set TargetLZPicker:style:border:v to 10.
    set TargetLZPicker:style:border:h to 10.
    set TargetLZPicker:style:bg to "starship_img/starship_background".
    set TargetLZPicker:style:normal:bg to "starship_img/starship_background".
    set TargetLZPicker:style:on:bg to "starship_img/starship_background_light".
    set TargetLZPicker:style:hover:bg to "starship_img/starship_background_light".
    set TargetLZPicker:style:hover_on:bg to "starship_img/starship_background_light".
    set TargetLZPicker:style:active:bg to "starship_img/starship_background_light".
    set TargetLZPicker:style:active_on:bg to "starship_img/starship_background_light".
    set TargetLZPicker:style:focused:bg to "starship_img/starship_background_light".
    set TargetLZPicker:style:focused_on:bg to "starship_img/starship_background_light".
    if RSS or KSRSS {
        set TargetLZPicker:maxvisible to 6.
        set TargetLZPicker:options to list("<color=grey><b>Select existing LZ</b></color>", "<b><color=white>Current Impact</color></b>", "<b><color=white>Launch Site</color></b>", "<b><color=white>Off-Shore</color></b>", "<b><color=white>Off-Shore Boca Chica</color></b>").
    }
    else {
        set TargetLZPicker:maxvisible to 8.
        set TargetLZPicker:options to list("<color=grey><b>Select existing LZ</b></color>", "<b><color=white>Current Impact</color></b>", "<b><color=white>Launch Site</color></b>", "<b><color=white>Dessert</color></b>", "<b><color=white>Woomerang</color></b>", "<b><color=white>Off-Shore</color></b>","<b><color=white>Baikerbanur</color></b>").
    }
    set TargetLZPicker:tooltip to "Select a predefined Landing Zone here:  e.g.  KSC, Off-Shore".
local setting3label is settingsstackvlayout1:addlabel("<b>Launch Inclination (°)</b>").
    set setting3label:style:margin:left to 10.
    set setting3label:style:fontsize to 19.
    set setting3label:style:wordwrap to false.
    set setting3label:style:width to 225.
    set setting3label:tooltip to "Set Launch Inclination here:    > 0 = North  /  < 0 = South".
local setting3 is settingsstackvlayout2:addtextfield("0°").
    set setting3:style:width to 175.

local settingscheckboxes is settingsstackvlayout3:addvbox().
    set settingscheckboxes:style:vstretch to 1.
    set settingscheckboxes:style:margin:right to 0.
    set settingscheckboxes:style:bg to "starship_img/starship_main_square_bg".
local quicksetting1 is settingscheckboxes:addcheckbox("<b>Auto-Stack</b>").
    set quicksetting1:style:margin:top to 12.
    set quicksetting1:style:margin:left to 10.
    set quicksetting1:style:fontsize to 14.
    set quicksetting1:style:width to 145.
    set quicksetting1:style:height to 24.
    set quicksetting1:style:overflow:right to -130.
    set quicksetting1:style:overflow:left to -3.
    set quicksetting1:style:overflow:top to -4.
    set quicksetting1:style:overflow:bottom to -9.
    set quicksetting1:tooltip to "Auto stacks both Ship and Booster (unable in RSS)".
local quicksetting2 is settingscheckboxes:addcheckbox("<b>  KX500</b>").
    set quicksetting2:style:fontsize to 14.
    set quicksetting2:style:margin:left to 10.
    set quicksetting2:style:bg to "starship_img/starship_toggle_off".
    set quicksetting2:style:on:bg to "starship_img/starship_toggle_on".
    set quicksetting2:style:hover:bg to "starship_img/starship_toggle_hover".
    set quicksetting2:style:hover_on:bg to "starship_img/starship_toggle_hover".
    set quicksetting2:style:active:bg to "starship_img/starship_toggle_off".
    set quicksetting2:style:active_on:bg to "starship_img/starship_toggle_on".
    set quicksetting2:style:width to 145.
    set quicksetting2:style:height to 24.
    set quicksetting2:style:overflow:right to -122.
    set quicksetting2:style:overflow:left to -3.
    set quicksetting2:style:overflow:top to -4.
    set quicksetting2:style:overflow:bottom to -9.
    set quicksetting2:tooltip to "kOS CPU speed. KX2000 = 4x faster, but also 4x heavier on performance".
local quicksetting3 is settingscheckboxes:addcheckbox("<b>Log Data</b>").
    set quicksetting3:toggle to true.
    set quicksetting3:style:fontsize to 14.
    set quicksetting3:style:margin:left to 10.
    set quicksetting3:style:width to 145.
    set quicksetting3:style:height to 24.
    set quicksetting3:style:overflow:right to -130.
    set quicksetting3:style:overflow:left to -3.
    set quicksetting3:style:overflow:top to -4.
    set quicksetting3:style:overflow:bottom to -9.
    set quicksetting3:tooltip to "Flight Data Recorder. Saves data in 'KSP folder'/Ships/Script".
local quicksetting4 is settingscheckboxes:addcheckbox("<b>Hide on F2</b>").
    set quicksetting4:toggle to true.
    set quicksetting4:style:fontsize to 14.
    set quicksetting4:style:margin:left to 10.
    set quicksetting4:style:width to 145.
    set quicksetting4:style:height to 24.
    set quicksetting4:style:overflow:right to -130.
    set quicksetting4:style:overflow:left to -3.
    set quicksetting4:style:overflow:top to -4.
    set quicksetting4:style:overflow:bottom to -9.
    set quicksetting4:tooltip to "Hide UI and Telemetry on F2".


set setting1:onconfirm to {
    parameter value.
    if not SettingCoordinatesInProgress {
        set SettingCoordinatesInProgress to true.
        if value = "" or not (value:contains(",")) {
            if homeconnection:isconnected {
                if exists("0:/settings.json") {
                    if L:haskey("Launch Coordinates") {
                        set value to L["Launch Coordinates"].
                        set value2 to value:split(",").
                        set landingzone to latlng(value2[0]:toscalar, value2[1]:toscalar).
                        print "Launch Coordinates set instead".
                    }
                }
            }
            else {
                set value to DefaultLaunchSite.
                set value2 to value:split(",").
                set landingzone to latlng(value2[0]:toscalar, value2[1]:toscalar).
                print "Default KSC Pad Coordinates set instead".
            }
            set setting1:text to value.
            SaveToSettings("Landing Coordinates", value).
        }
        else {
            set value to value:split(",").
            if value[0]:toscalar(-9999) = -9999 or value[1]:toscalar(-9999) = -9999 {
                set value to DefaultLaunchSite.
                set value2 to value:split(",").
                set landingzone to latlng(value2[0]:toscalar, value2[1]:toscalar).
                set setting1:text to value.
                SaveToSettings("Landing Coordinates", value).
                print "Default KSC Pad Coordinates set due to input error".
            }
            else {
                set landingzone to latlng(value[0]:toscalar, value[1]:toscalar).
                SaveToSettings("Landing Coordinates", (value[0]:toscalar + "," + value[1]:toscalar):tostring).
                print "Landing Coordinates set: " + landingzone.
            }
        }
        if KUniverse:activevessel = vessel(ship:name) {
            ADDONS:TR:SETTARGET(landingzone).
        }
        set SettingCoordinatesInProgress to false.
    }
}.


set setting2:ontoggle to {
    parameter pressed.
    if pressed {
        SaveToSettings("Tooltips", "true").
        set setting2:text to "<b>  Don't show Tooltips</b>".
    }
    if not pressed {
        SaveToSettings("Tooltips", "false").
        set setting2:text to "<b>  Show Tooltips</b>".
    }
}.


set TargetLZPicker:onchange to {
    parameter choice.
    if choice = "<b><color=white>Launch Site</color></b>" {
        if RSS {
            if exists("0:/settings.json") {
                set L to readjson("0:/settings.json").
                if L:haskey("Launch Coordinates") {
                    set LSCoords to L["Launch Coordinates"].
                }
            }
            set setting1:text to LSCoords.
            set landingzone to latlng(LSCoords:split(",")[0]:toscalar,LSCoords:split(",")[1]:toscalar).
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", LSCoords).
            }
        }
        else if KSRSS {
            if RESCALE and bodyexists("Kerbin") {
                if exists("0:/settings.json") {
                    set L to readjson("0:/settings.json").
                    if L:haskey("Launch Coordinates") {
                        set LSCoords to L["Launch Coordinates"].
                    }
                }
                set setting1:text to LSCoords.
                set landingzone to latlng(LSCoords:split(",")[0]:toscalar,LSCoords:split(",")[1]:toscalar).
                if homeconnection:isconnected {
                    SaveToSettings("Landing Coordinates", LSCoords).
                }
            }
            else {
                if exists("0:/settings.json") {
                set L to readjson("0:/settings.json").
                if L:haskey("Launch Coordinates") {
                    set LSCoords to L["Launch Coordinates"].
                }
            }
            set setting1:text to LSCoords.
            set landingzone to latlng(LSCoords:split(",")[0]:toscalar,LSCoords:split(",")[1]:toscalar).
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", LSCoords).
            }
            }
        }
        else {
            if exists("0:/settings.json") {
                set L to readjson("0:/settings.json").
                if L:haskey("Launch Coordinates") {
                    set LSCoords to L["Launch Coordinates"].
                }
            }
            set setting1:text to LSCoords.
            set landingzone to latlng(LSCoords:split(",")[0]:toscalar,LSCoords:split(",")[1]:toscalar).
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", LSCoords).
            }
        }
        if KUniverse:activevessel = vessel(ship:name) {
            ADDONS:TR:SETTARGET(landingzone).
        }
    }
    if choice = "<b><color=white>Dessert</color></b>" {
        set setting1:text to "-6.5604,-143.95".
        set landingzone to latlng(-6.5604,-143.95).
        if homeconnection:isconnected {
            SaveToSettings("Landing Coordinates", "-6.5604,-143.95").
        }
        if KUniverse:activevessel = vessel(ship:name) {
            ADDONS:TR:SETTARGET(landingzone).
        }
    }
    if choice = "<b><color=white>Woomerang</color></b>" {
        set setting1:text to "45.2896,136.11".
        set landingzone to latlng(45.2896,136.11).
        if homeconnection:isconnected {
            SaveToSettings("Landing Coordinates", "45.2896,136.11").
        }
        if KUniverse:activevessel = vessel(ship:name) {
            ADDONS:TR:SETTARGET(landingzone).
        }
    }
    if choice = "<b><color=white>Baikerbanur</color></b>" {
        set setting1:text to "20.6635,-146.4210".
        set landingzone to latlng(20.6635,-146.4210).
        if homeconnection:isconnected {
            SaveToSettings("Landing Coordinates", "20.6635,-146.4210").
        }
        if KUniverse:activevessel = vessel(ship:name) {
            ADDONS:TR:SETTARGET(landingzone).
        }
    }
    if choice = "<b><color=white>Off-Shore</color></b>" {
        if not RSS and not KSRSS {
            set setting1:text to "-0.0970,-74.2".
            set landingzone to latlng(-0.0970,-74.2).
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", "-0.0970,-74.2").
            }
            if KUniverse:activevessel = vessel(ship:name) {
                ADDONS:TR:SETTARGET(landingzone).
            }
        } else if RSS {
            set setting1:text to "28.497545,-80.46".
            set landingzone to latlng(28.497545,-80.46).
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", "28.497545,-80.46").
            }
            if KUniverse:activevessel = vessel(ship:name) {
                ADDONS:TR:SETTARGET(landingzone).
            }
        } else {
            set setting1:text to "28.50895,-80.4".
            set landingzone to latlng(28.50895,-80.4).
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", "28.50895,-80.4").
            }
            if KUniverse:activevessel = vessel(ship:name) {
                ADDONS:TR:SETTARGET(landingzone).
            }
        }
    }
    if choice = "<b><color=white>Off-Shore Boca Chica</color></b>" {
        if RSS {
            set setting1:text to "25.9965,-97.075".
            set landingzone to latlng(25.9965,-97.075).
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", "25.9965,-97.075").
            }
            if KUniverse:activevessel = vessel(ship:name) {
                ADDONS:TR:SETTARGET(landingzone).
            }
        } else {
            set setting1:text to "25.9965,-97.07".
            set landingzone to latlng(25.9965,-97.070).
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", "25.9965,-97.070").
            }
            if KUniverse:activevessel = vessel(ship:name) {
                ADDONS:TR:SETTARGET(landingzone).
            }
        }
    }
    if choice = "<b><color=white>Current Impact</color></b>" {
        if addons:tr:hasimpact {
            set impactpos to addons:tr:impactpos.
            set impactpos to latlng(round(impactpos:lat, 4), round(impactpos:lng, 4)).
            set landingzone to impactpos.
            set impactpos to impactpos:lat + "," + impactpos:lng.
            set setting1:text to impactpos.
            if homeconnection:isconnected {
                SaveToSettings("Landing Coordinates", impactpos).
            }
            if KUniverse:activevessel = vessel(ship:name) {
                ADDONS:TR:SETTARGET(landingzone).
            }
        }
    }
}.


set setting3:onconfirm to {
    parameter value.
    if value:contains("°") {
        set value to value:split("°")[0]:toscalar(0).
        if value > 180 {
            set value to 180.
        }
        if value < -180 {
            set value to -180.
        }
        SaveToSettings("Launch Inclination", value).
        set setting3:text to (value + "°").
    }
    else if value:toscalar(9999) = 9999 {
        set value to 0.
        SaveToSettings("Launch Inclination", value).
        set setting3:text to (value + "°").
    }
    else {
        set value to value:toscalar(0).
        if value > 180 {
            set value to 180.
        }
        if value < -180 {
            set value to -180.
        }
        SaveToSettings("Launch Inclination", value).
        set setting3:text to (value + "°").
    }
}.

set quicksetting1:ontoggle to {
    parameter pressed.
    if pressed {
        SaveToSettings("Auto-Stack", "true").
    }
    if not pressed {
        SaveToSettings("Auto-Stack", "false").
    }
}.


set quicksetting2:ontoggle to {
    parameter pressed.
    if pressed {
        SaveToSettings("CPU_SPD", "800").
        set quicksetting2:text to "<b>  KX800</b>".
        set CPUSPEED to 800.
        set config:ipu to CPUSPEED.
    }
    if not pressed {
        SaveToSettings("CPU_SPD", "2000").
        set quicksetting2:text to "<b>  KX2000</b>".
        set CPUSPEED to 2000.
        set config:ipu to CPUSPEED.
    }
}.


set quicksetting3:ontoggle to {
    parameter pressed.
    if pressed {
        if homeconnection:isconnected {
            if exists("0:/LaunchData.csv") {
                if ship:status = "PRELAUNCH" {
                    deletepath("0:/LaunchData.csv").
                }
            }
            if exists("0:/LandingData.csv") {
                deletepath("0:/LandingData.csv").
            }
            if exists("0:/FlightData.txt") {
                deletepath("0:/FlightData.txt").
            }
            if defined PrevLogTime {
                unset PrevLogTime.
            }
            SaveToSettings("Log Data", "true").
            set Logging to true.
            LogToFile("Flight Data Recorder Started").
        }
        else {
            set quicksetting3:text to "<b><color=red>Log Data</color></b>".
            wait 0.25.
            set quicksetting3:text to "<b>Log Data</b>".
            set quicksetting3:pressed to false.
        }
    }
    if not pressed {
        SaveToSettings("Log Data", "false").
        set Logging to false.
    }
}.
set quicksetting4:ontoggle to {
    parameter pressed.
    if pressed {
        SaveToSettings("ObeyHideUI", "true").
        set config:obeyhideui to true.
    }
    if not pressed {
        SaveToSettings("ObeyHideUI", "false").
        set config:obeyhideui to false.
    }
}.

local cargostackhlayout to cargostack:addhlayout().
    set cargostackhlayout:style:bg to "starship_img/starship_main_square_bg".
local cargostackvlayout1 is cargostackhlayout:addvlayout().
local cargostackvlayout2 is cargostackhlayout:addvlayout().
local cargostackvlayout3 is cargostackhlayout:addvlayout().
local cargostackvlayout4 is cargostackhlayout:addvlayout().
local cargostackvlayout5 is cargostackhlayout:addvlayout().
local cargostackvlayout6 is cargostackhlayout:addvlayout().
local cargo1label is cargostackvlayout1:addlabel("<b>Hatch:</b>").
    set cargo1label:style:fontsize to 20.
    set cargo1label:style:width to 75.
    set cargo1label:style:wordwrap to false.
    set cargo1label:style:align to "CENTER".
    set cargo1label:style:margin:top to 7.
local cargo1text is cargostackvlayout2:addlabel("Locked").
    set cargo1text:style:fontsize to 19.
    set cargo1text:style:width to 75.
    set cargo1text:style:margin:top to 7.
    set cargo1text:tooltip to "Door Status".
local cargo1button is cargostackvlayout3:addbutton("<>").
    set cargo1button:style:align to "CENTER".
    set cargo1button:style:width to 35.
    set cargo1button:style:height to 25.
    set cargo1button:style:fontsize to 20.
    set cargo1button:style:margin:top to 7.
    set cargo1button:tooltip to "Open/Close the Hatch/Cargo Door".
local cargoimage is cargostackvlayout4:addlabel().
    set cargoimage:style:width to 80.
    set cargoimage:style:height to 100.
    set cargoimage:style:margin:top to 7.
    set cargoimage:style:bg to "starship_img/starship_cargobay_closed".
    set cargoimage:tooltip to "Visual Representation of current hatch status".
local cargo1label2 is cargostackvlayout5:addlabel("<b>Cargo:</b>").
    set cargo1label2:style:width to 100.
    set cargo1label2:style:fontsize to 20.
    set cargo1label2:style:wordwrap to false.
    set cargo1label2:style:align to "CENTER".
    set cargo1label2:style:margin:top to 7.
    set cargo1label2:tooltip to "Cargo found onboard will be shown here".
local cargo2label is cargostackvlayout1:addlabel("<b><color=grey>Winch:</color></b>").
    set cargo2label:style:align to "CENTER".
    set cargo2label:style:margin:top to 25.
    set cargo2label:style:fontsize to 20.
    set cargo2label:tooltip to "not yet implemented".
local cargo2extend is cargostackvlayout2:addbutton("<color=grey><</color>").
    set cargo2extend:style:margin:top to 10.
    set cargo2extend:style:margin:right to 10.
    set cargo2extend:style:width to 25.
    set cargo2extend:style:height to 25.
    set cargo2extend:style:fontsize to 20.
    set cargo2extend:tooltip to "not yet implemented".
local cargo2retract is cargostackvlayout3:addbutton("<color=grey>></color>").
    set cargo2retract:style:margin:top to 10.
    set cargo2retract:style:width to 25.
    set cargo2retract:style:height to 25.
    set cargo2retract:style:fontsize to 20.
    set cargo2retract:tooltip to "not yet implemented".
local cargo2label2 is cargostackvlayout5:addlabel("-").
    set cargo2label2:style:width to 100.
    set cargo2label2:style:fontsize to 19.
    set cargo2label2:style:wordwrap to false.
    set cargo2label2:style:align to "CENTER".
    set cargo2label2:style:margin:top to 7.
    set cargo2label2:style:textcolor to grey.
    set cargo2label2:tooltip to "Cargo Mass in kg".
local cargo3lower is cargostackvlayout2:addbutton("<color=grey>v</color>").
    set cargo3lower:style:margin:top to 10.
    set cargo3lower:style:margin:right to 10.
    set cargo3lower:style:width to 25.
    set cargo3lower:style:height to 25.
    set cargo3lower:style:fontsize to 20.
    set cargo3lower:tooltip to "not yet implemented".
local cargo3raise is cargostackvlayout3:addbutton("<color=grey>^</color>").
    set cargo3raise:style:margin:top to 10.
    set cargo3raise:style:width to 25.
    set cargo3raise:style:height to 25.
    set cargo3raise:style:fontsize to 20.
    set cargo3raise:tooltip to "not yet implemented".
local cargo3label2 is cargostackvlayout5:addlabel("-").
    set cargo3label2:style:width to 100.
    set cargo3label2:style:fontsize to 19.
    set cargo3label2:style:wordwrap to false.
    set cargo3label2:style:align to "CENTER".
    set cargo3label2:style:margin:top to 7.
    set cargo3label2:style:textcolor to grey.
    set cargo3label2:tooltip to "index units define the Center of Gravity of the Ship (max " + MaxIU + " i.u. for re-entry)".
    
local cargocheckboxes is cargostackvlayout6:addvbox().
    set cargocheckboxes:style:margin:right to 0.
    set cargocheckboxes:style:vstretch to 1.
    set cargocheckboxes:style:bg to "starship_img/starship_main_square_bg".
local quickcargo1 is cargocheckboxes:addcheckbox("<b>Dome Light</b>").
    set quickcargo1:style:margin:top to 12.
    set quickcargo1:style:margin:left to 10.
    set quickcargo1:style:fontsize to 18.
    set quickcargo1:style:width to 150.
    set quickcargo1:style:height to 29.
    set quickcargo1:style:overflow:right to -130.
    set quickcargo1:style:overflow:left to -3.
    set quickcargo1:style:overflow:top to -4.
    set quickcargo1:style:overflow:bottom to -9.
    set quickcargo1:tooltip to "Toggle Dome Light (function to be expanded)".
local quickcargo2 is cargocheckboxes:addcheckbox("<b>Solar Panels</b>").
    set quickcargo2:style:margin:left to 10.
    set quickcargo2:style:fontsize to 18.
    set quickcargo2:style:width to 150.
    set quickcargo2:style:height to 29.
    set quickcargo2:style:overflow:right to -130.
    set quickcargo2:style:overflow:left to -3.
    set quickcargo2:style:overflow:top to -4.
    set quickcargo2:style:overflow:bottom to -9.
    set quickcargo2:tooltip to "Toggle Solar Panels".
local quickcargo3 is cargocheckboxes:addcheckbox("<b><color=grey>LR Antenna</color></b>").
    set quickcargo3:style:margin:left to 10.
    set quickcargo3:style:fontsize to 18.
    set quickcargo3:style:width to 150.
    set quickcargo3:style:height to 29.
    set quickcargo3:style:overflow:right to -130.
    set quickcargo3:style:overflow:left to -3.
    set quickcargo3:style:overflow:top to -4.
    set quickcargo3:style:overflow:bottom to -9.
    set quickcargo3:tooltip to "not yet implemented".

set quickcargo1:ontoggle to {
    parameter click.
    if click {
        lights on.
    }
    else {
        lights off.
    }
}.

set quickcargo2:ontoggle to {
    parameter click.
    if click {
        panels on.
    }
    else {
        panels off.
    }
}.

set quickcargo3:ontoggle to {
    parameter click.
    if click {

    }
    else {

    }
}.

set cargo1button:onclick to {
    set CargoBayOperationComplete to false.
    set CargoBayDoorHalfOpen to false.
    set CargoBayOperationStart to time:seconds.
    if ShipType:contains("Cargo") {
        for x in range(0, Nose:modules:length) {
            if Nose:getmodulebyindex(x):hasaction("toggle cargo door") {
                Nose:getmodulebyindex(x):DoAction("toggle cargo door", true).
            }
        }
    } else if ShipType:contains("PEZ") {
        for x in range(0, Nose:modules:length) {
            if Nose:getmodulebyindex(x):hasaction("toggle pez door") {
                Nose:getmodulebyindex(x):DoAction("toggle pez door", true).
            }
        }
    }
    else {
        if Nose:getmodule("ModuleAnimateGeneric"):hasevent("open docking hatch") {
            for x in range(0, Nose:modules:length) {
                if Nose:getmodulebyindex(x):hasevent("open airlock") {
                    Nose:getmodulebyindex(x):DoEvent("open airlock").
                }
                if Nose:getmodulebyindex(x):hasevent("open docking hatch") {
                    Nose:getmodulebyindex(x):DoEvent("open docking hatch").
                }
            }
        }
        if Nose:getmodule("ModuleAnimateGeneric"):hasevent("close docking hatch") {
            for x in range(0, Nose:modules:length) {
                if Nose:getmodulebyindex(x):hasevent("close airlock") {
                    Nose:getmodulebyindex(x):DoEvent("close airlock").
                }
                if Nose:getmodulebyindex(x):hasevent("close docking hatch") {
                    Nose:getmodulebyindex(x):DoEvent("close docking hatch").
                }
            }
        }
    }
    LogToFile("Cargo Door Operation Requested").
}.
    

local attitudestackhlayout to attitudestack:addhlayout().
    set attitudestackhlayout:style:bg to "starship_img/starship_main_square_bg".
local attitudestackvlayout1 is attitudestackhlayout:addvlayout().
    set attitudestackvlayout1:style:vstretch to 1.
local attitudestackvlayout2 is attitudestackhlayout:addvlayout().
local attitudestackvlayout3 is attitudestackhlayout:addvlayout().
local attitudestackvlayout4 is attitudestackhlayout:addvlayout().
local attitudestackvlayout5 is attitudestackhlayout:addvlayout().
local attitude1label is attitudestackvlayout1:addlabel("<b>AoA & Roll command:</b>").
    set attitude1label:style:fontsize to 19.
    set attitude1label:style:align to "CENTER".
    set attitude1label:style:margin:left to 20.
    set attitude1label:style:margin:top to 7.
    set attitude1label:style:wordwrap to false.
    set attitude1label:tooltip to "Manual Attitude Control (Landing armed @ 10km Radar Altitude)".
local attitude1text is attitudestackvlayout3:addtextfield(aoa:tostring).
    set attitude1text:style:fontsize to 19.
    set attitude1text:style:margin:top to 10.
    set attitude1text:style:width to 50.
local attitude1text2 is attitudestackvlayout4:addtextfield("0").
    set attitude1text2:style:fontsize to 19.
    set attitude1text2:style:margin:top to 10.
    set attitude1text2:style:width to 60.
local attitude2label is attitudestackvlayout1:addlabel("AoA: -").
    set attitude2label:style:align to "CENTER".
    set attitude2label:style:margin:top to 10.
    set attitude2label:style:margin:left to 20.
    set attitude2label:style:fontsize to 19.
    set attitude2label:style:textcolor to grey.
    set attitude2label:tooltip to "Current AoA. Trk/X-Track Error shown when low enough".
    set attitude2label:style:wordwrap to false.
    set attitude2label:style:width to 200.
    set attitude2label:style:bg to "starship_img/attitude_page_background".
    set attitude2label:style:overflow:left to -155.
    set attitude2label:style:overflow:right to 25.
    set attitude2label:style:overflow:top to -5.
    set attitude2label:style:overflow:bottom to 40.
local attitude2up is attitudestackvlayout3:addbutton("^").
    set attitude2up:style:margin:top to 10.
    set attitude2up:style:margin:left to 17.
    set attitude2up:style:width to 25.
    set attitude2up:style:height to 25.
    set attitude2up:style:fontsize to 20.
local attitude3button is attitudestackvlayout1:addbutton("<b>RESET</b>").
    set attitude3button:style:margin:top to 12.
    set attitude3button:style:margin:left to 85.
    set attitude3button:style:width to 75.
    set attitude3button:style:height to 25.
    set attitude3button:style:fontsize to 18.
    set attitude3button:tooltip to "Reset to 60° Angle-of-Attack / 0° Roll".
local attitude3left is attitudestackvlayout2:addbutton("<").
    set attitude3left:style:margin:top to 65.
    set attitude3left:style:margin:left to 20.
    set attitude3left:style:width to 25.
    set attitude3left:style:height to 25.
    set attitude3left:style:fontsize to 20.
local attitude3right is attitudestackvlayout4:addbutton(">").
    set attitude3right:style:margin:top to 27.
    set attitude3right:style:width to 25.
    set attitude3right:style:height to 25.
    set attitude3right:style:fontsize to 20.
local attitude3down is attitudestackvlayout3:addbutton("v").
    set attitude3down:style:margin:top to 10.
    set attitude3down:style:margin:left to 17.
    set attitude3down:style:width to 25.
    set attitude3down:style:height to 25.
    set attitude3down:style:fontsize to 20.
local attituderadiobuttons is attitudestackvlayout5:addvbox().
    set attituderadiobuttons:style:margin:right to 0.
    set attituderadiobuttons:style:vstretch to 1.
    set attituderadiobuttons:style:bg to "starship_img/starship_main_square_bg".
local quickattitude1 is attituderadiobuttons:addradiobutton("<b>Off</b>").
    set quickattitude1:pressed to 1.
    set quickattitude1:style:margin:top to 12.
    set quickattitude1:style:margin:left to 10.
    set quickattitude1:style:fontsize to 18.
    set quickattitude1:style:width to 150.
    set quickattitude1:style:height to 29.
    set quickattitude1:style:overflow:right to -130.
    set quickattitude1:style:overflow:left to -3.
    set quickattitude1:style:overflow:top to -4.
    set quickattitude1:style:overflow:bottom to -9.
    set quickattitude1:tooltip to "Disable Attitude Control".
local quickattitude2 is attituderadiobuttons:addradiobutton("<b>ATT Control</b>").
    set quickattitude2:style:margin:left to 10.
    set quickattitude2:style:fontsize to 18.
    set quickattitude2:style:width to 150.
    set quickattitude2:style:height to 29.
    set quickattitude2:style:overflow:right to -130.
    set quickattitude2:style:overflow:left to -3.
    set quickattitude2:style:overflow:top to -4.
    set quickattitude2:style:overflow:bottom to -9.
    set quickattitude2:tooltip to "Manual Attitude Control (Landing armed @ 10km Radar Altitude)".
local quickattitude3 is attituderadiobuttons:addcheckbox("<b>RCS ON</b>").
    set quickattitude3:style:margin:left to 10.
    set quickattitude3:style:fontsize to 18.
    set quickattitude3:style:width to 150.
    set quickattitude3:style:height to 29.
    set quickattitude3:style:overflow:right to -130.
    set quickattitude3:style:overflow:left to -3.
    set quickattitude3:style:overflow:top to -4.
    set quickattitude3:style:overflow:bottom to -9.
    set quickattitude3:tooltip to "Force RCS ON during Attitude Control".

set attitude1text:onconfirm to {
    parameter string.
    if string = "" {
        set attitude1text:text to (aoa):tostring.
        set attpitch to aoa.
    }
    else {
        if string:toscalar(-9999) = -9999 {
            set attitude1text:text to (prevattpitch):tostring.
        }
        else {
            if string:toscalar > 85 {
                set attitude1text:text to (85):tostring.
                set attpitch to 85.
            }
            else if string:toscalar < 0 {
                set attitude1text:text to (0):tostring.
                set attpitch to 0.
            }
            else {
                set attpitch to string:toscalar.
            }
            set prevattpitch to attpitch.
        }
    }
}.

set attitude1text2:onconfirm to {
    parameter string.
    if string = "" {
        set attroll to 0.
        set attitude1text2:text to (0):tostring.
    }
    else {
        if string:toscalar(-9999) = -9999 {
            set attitude1text2:text to (prevattroll):tostring.
        }
        else {
            if string:toscalar > 60 {
                set attitude1text2:text to (60):tostring.
                set attroll to 60.
            }
            else if string:toscalar < -60 {
                set attitude1text2:text to (-60):tostring.
                set attroll to -60.
            }
            else {
                set attroll to string:toscalar.
            }
            set prevattroll to attroll.
        }
    }
}.

set quickattitude1:onclick to {
    set attitude2label:text to "<b><size=19>AoA: -</size></b>".
    set attitude2label:style:align to "CENTER".
    set attitude2label:style:textcolor to grey.
    set attitude2label:style:bg to "starship_img/attitude_page_background".
    if defined Nose {
        if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).}
            else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
        Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).
        }
    }
    Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).
    unlock steering.
    SetPlanetData().
    sas on.
    rcs off.
    set quickstatus1:pressed to false.
    set attitude1text:text to (aoa):tostring.
    set attitude1text2:text to (0):tostring.
    set runningprogram to "None".
    LogToFile("Attitude Control Set to OFF").
}.

set quickattitude2:onclick to {
    if not AttitudeIsRunning {
        if ship:body:atm:exists {
            SetPlanetData().
            set AttitudeIsRunning to true.
            if LaunchButtonIsRunning or LandButtonIsRunning or ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                set quickattitude2:text to "<b><color=red>ATT Control</color></b>".
                wait 0.25.
                set quickattitude2:text to "<b>ATT Control</b>".
                set quickattitude1:pressed to true.
            }
            else {
                set attitudebutton:style:bg to "starship_img/starship_attitude_running".
                set attitudebutton:style:on:bg to "starship_img/starship_attitude_running_on".
                set attitudebutton:style:hover:bg to "starship_img/starship_attitude_running_hover".
                set attitudebutton:style:hover_on:bg to "starship_img/starship_attitude_running_on".
                set attitudebutton:style:active:bg to "starship_img/starship_attitude_running_hover".
                set attitudebutton:style:active_on:bg to "starship_img/starship_attitude_running_hover".
                SetPlanetData().
                set addons:tr:descentmodes to list(true, true, true, true).
                set addons:tr:descentgrades to list(false, false, false, false).
                set addons:tr:descentangles to DescentAngles.
                LogToFile("Attitude Control Set to ON").
                Droppriority().
                sas off.
                set quickstatus1:pressed to true.
                if AbortLaunchInProgress {
                    set quickattitude3:pressed to true.
                }
                set quickattitude2:text to "<b><color=green>ATT Control</color></b>".
                set attpitch to attitude1text:text:toscalar.
                set attroll to attitude1text2:text:toscalar.
                SetRadarAltitude().
                setflaps(FWDFlapDefault, AFTFlapDefault, 1, 30).
                lock steering to AttitudeSteering().
                until quickattitude1:pressed or RadarAlt < 10000 {
                    AttitudeData().
                }
                if RadarAlt < 10000 {
                    unlock steering.
                    set quickattitude1:pressed to true.
                    ShowHomePage().
                    sas on.
                    ReEntryAndLand().
                }
                set quickattitude2:text to "<b>ATT Control</b>".
                set attitudebutton:style:bg to "starship_img/starship_attitude".
                set attitudebutton:style:on:bg to "starship_img/starship_attitude_on".
                set attitudebutton:style:hover:bg to "starship_img/starship_attitude_hover".
                set attitudebutton:style:hover_on:bg to "starship_img/starship_attitude_on".
                set attitudebutton:style:active:bg to "starship_img/starship_attitude_hover".
                set attitudebutton:style:active_on:bg to "starship_img/starship_attitude_hover".
                LogToFile("Attitude Control Cancelled").
            }
            set AttitudeIsRunning to false.
        }
        else {
            set quickattitude2:text to "<b><color=red>ATT Control</color></b>".
            wait 0.25.
            set quickattitude2:text to "<b>ATT Control</b>".
            set quickattitude1:pressed to true.
        }
    }
}.

function AttitudeSteering {
    if time:seconds > TimeSinceLastAttSteering + 0.2 {
        set result to srfprograde * R(- attpitch * cos(attroll), attpitch * sin(attroll), 0).
        set TimeSinceLastAttSteering to time:seconds.
        return lookdirup(result:vector, vxcl(velocity:surface, result:vector)).
    }
    else {
        return lookdirup(result:vector, vxcl(velocity:surface, result:vector)).
    }
}


function AttitudeData {
    if quickattitude3:pressed {rcs on.} else {rcs off.}
    if airspeed < 450 and kuniverse:timewarp:warp > 1 {set kuniverse:timewarp:warp to 1.}
    set runningprogram to "Attitude (Landing Armed)".
    set status1:style:textcolor to green.

    set LngLatErrorList to LngLatError().

    if attitude1text:text:toscalar(-9999) = -9999 {}
    else {
        if attitude1text:text:toscalar = attpitch {}
        else {
            set attpitch to attitude1text:text:toscalar.
        }
    }
    if attitude1text2:text:toscalar(-9999) = -9999 {}
    else {
        if attitude1text2:text:toscalar = attroll {}
        else {
            set attroll to attitude1text2:text:toscalar.
        }
    }

    if RadarAlt > 35000 {
        set attitude2label:style:align to "CENTER".
        set attitude2label:text to "<b><size=19><color=magenta>AoA: " + round(vang(ship:facing:forevector, velocity:surface), 1) + "°</color></size></b>".
        set attitude2label:style:bg to "starship_img/attitude_page_background".
    }
    else {
        set attitude2label:style:bg to "".
        set attitude2label:style:align to "LEFT".
        if addons:tr:hasimpact {
            set attitude2label:text to "<b><size=15><color=magenta>AoA: " + round(vang(ship:facing:forevector, velocity:surface), 1) + "°</color>  <color=cyan>Trk: " + round(LngLatErrorList[0]) + "m X-Trk: " + round(LngLatErrorList[1]) + "m</color></size></b>".
        }
        else {
            set attitude2label:text to "<b><size=19><color=magenta>AoA: " + round(vang(ship:facing:forevector, velocity:surface), 1) + "°</color></size></b>".
        }
    }

    if RadarAlt < 10000 and not ClosingIsRunning {
        if abs(LngLatErrorList[0]) > 500 or abs(LngLatErrorList[1]) > 250 {
            set message3:style:textcolor to yellow.
        }
        else {
            set message3:style:textcolor to white.
        }
    }
    BackGroundUpdate().
}


set attitude2up:onclick to {
    if attpitch = 85 {}
    else {
        set attpitch to attpitch + 1.
        set attitude1text:text to (attpitch):tostring.
    }
}.
set attitude3down:onclick to {
    if attpitch = 0 {}
    else {
        set attpitch to attpitch - 1.
        set attitude1text:text to (attpitch):tostring.
    }
}.
set attitude3left:onclick to {
    if attroll = -60 {}
    else {
        set attroll to attroll - 1.
        set attitude1text2:text to (attroll):tostring.
    }
}.
set attitude3right:onclick to {
    if attroll = 60 {}
    else {
        set attroll to attroll + 1.
        set attitude1text2:text to (attroll):tostring.
    }
}.
set attitude3button:onclick to {
    set attpitch to aoa.
    set attroll to 0.
    set attitude1text:text to (attpitch):tostring.
    set attitude1text2:text to (attroll):tostring.
}.



local statusstackhlayout to statusstack:addhlayout().
    set statusstackhlayout:style:bg to "starship_img/starship_main_square_bg".
local statusstackvlayout1 is statusstackhlayout:addvlayout().
    set statusstackvlayout1:style:vstretch to 1.
local statusstackvlayout2 is statusstackhlayout:addvlayout().
local statusstackvlayout3 is statusstackhlayout:addvlayout().
local statusstackvlayout4 is statusstackhlayout:addvlayout().
local statusstackvlayout5 is statusstackhlayout:addvlayout().
local statusstackvlayout6 is statusstackhlayout:addvlayout().

    
local status1label1 is statusstackvlayout1:addlabel().
    set status1label1:style:margin:left to 10.
    set status1label1:style:margin:top to 25.
    set status1label1:style:width to 50.
    set status1label1:style:fontsize to 19.
    set status1label1:style:align to "CENTER".
    set status1label1:style:wordwrap to false.
    set status1label1:tooltip to "Left Hand Forward Flap Angle Command".
local status1label2 is statusstackvlayout2:addlabel("<b>FLAP      ANGLE</b>").
    set status1label2:style:margin:left to 5.
    set status1label2:style:margin:top to 3.
    set status1label2:style:width to 50.
    set status1label2:style:align to "CENTER".
    set status1label2:style:fontsize to 18.
    set status1label2:style:overflow:left to 50.
    set status1label2:style:overflow:right to 0.
    set status1label2:style:wordwrap to false.
local status1label3 is statusstackvlayout3:addlabel().
    set status1label3:style:margin:top to 25.
    set status1label3:style:fontsize to 19.
    set status1label3:style:align to "LEFT".
    set status1label3:style:wordwrap to false.
    set status1label3:tooltip to "Right Hand Forward Flap Angle Command".
local status1label4 is statusstackvlayout4:addlabel().
    set status1label4:style:margin:top to 5.
    set status1label4:style:margin:left to 20.
    set status1label4:style:fontsize to 16.
    set status1label4:style:align to "LEFT".
    set status1label4:style:width to 110.
    set status1label4:style:wordwrap to false.
    set status1label4:tooltip to "Current Angle-of-Attack".
local status1label5 is statusstackvlayout5:addlabel().
    set status1label5:style:margin:top to 5.
    set status1label5:style:margin:left to 20.
    set status1label5:style:fontsize to 16.
    set status1label5:style:align to "LEFT".
    set status1label5:style:width to 105.
    set status1label5:style:wordwrap to false.
    set status1label5:tooltip to "Current Ship Mass in metric tons".
    
local status2label1 is statusstackvlayout1:addlabel("").
    set status2label1:style:textcolor to grey.
    set status2label1:style:margin:left to 5.
    set status2label1:style:width to 50.
    set status2label1:style:wordwrap to false.
    set status2label1:style:fontsize to 12.
    set status2label1:style:align to "LEFT".
    //set status2label1:tooltip to "Left Hand Heat-Tile Surface Temperature".
local status2label2 is statusstackvlayout2:addlabel().
    set status2label2:style:bg to "starship_img/starship_symbol".
    set status2label2:style:margin:top to 3.
    set status2label2:style:width to 50.
    set status2label2:style:height to 50.
    set status2label2:style:overflow:top to 25.
    set status2label2:style:overflow:bottom to 25.
    set status2label2:style:overflow:left to 1.
    set status2label2:style:overflow:right to -19.
    set status2label2:tooltip to "Visual Representation of the Hull".
    
local status2label3 is statusstackvlayout3:addlabel(" ").
    set status2label3:style:textcolor to grey.
    set status2label3:style:width to 50.
    set status2label3:style:wordwrap to false.
    set status2label3:style:fontsize to 12.
    set status2label3:style:align to "CENTER".
    //set status2label3:tooltip to "Right Hand Heat-Tile Surface Temperature".
local status2label4 is statusstackvlayout4:addlabel().
    set status2label4:style:fontsize to 16.
    set status2label4:style:align to "LEFT".
    set status2label4:style:margin:left to 20.
    set status2label4:style:wordwrap to false.
    set status2label4:style:width to 110.
    set status2label4:style:bg to "starship_img/starship_background_white".
    set status2label4:style:border:h to 10.
    set status2label4:style:border:v to 10.
    set status2label4:style:overflow:left to -135.
    set status2label4:style:overflow:right to 128.
    set status2label4:style:overflow:bottom to -1.
    set status2label4:tooltip to "Dynamic Pressure in kPa (orange during max-Q at launch)".
local status2label5 is statusstackvlayout5:addlabel().
    set status2label5:style:margin:left to 20.
    set status2label5:style:fontsize to 16.
    set status2label5:style:align to "CENTER".
    set status2label5:style:wordwrap to false.
    set status2label5:style:width to 105.
    set status2label5:style:bg to "starship_img/starship_background_dark_opacity0".
    set status2label5:style:border:h to 10.
    set status2label5:style:border:v to 10.
    set status2label5:tooltip to "% Methane Fuel Remaining".
    
local status3label1 is statusstackvlayout1:addlabel().
    set status3label1:style:margin:left to 10.
    set status3label1:style:width to 50.
    set status3label1:style:fontsize to 19.
    set status3label1:style:align to "CENTER".
    set status3label1:style:wordwrap to false.
    set status3label1:tooltip to "Left Hand Aft Flap Angle Command".
local status3label3 is statusstackvlayout3:addlabel().
    set status3label3:style:width to 50.
    set status3label3:style:fontsize to 19.
    set status3label3:style:align to "LEFT".
    set status3label3:style:wordwrap to false.
    set status3label3:tooltip to "Right Hand Aft Flap Angle Command".
local status3label4 is statusstackvlayout4:addlabel().
    set status3label4:style:fontsize to 16.
    set status3label4:style:align to "LEFT".
    set status3label4:style:margin:left to 20.
    set status3label4:style:wordwrap to false.
    set status3label4:style:width to 110.
    set status3label4:style:bg to "starship_img/starship_background_white".
    set status3label4:style:border:h to 10.
    set status3label4:style:border:v to 10.
    set status3label4:style:overflow:left to -135.
    set status3label4:style:overflow:right to 128.
    set status3label4:style:overflow:bottom to -1.
    set status3label4:tooltip to "Current Acceleration in G-Force (1G = Kerbin: 9.81 m/s/s)".
local status3label5 is statusstackvlayout5:addlabel().
    set status3label5:style:margin:left to 20.
    set status3label5:style:fontsize to 16.
    set status3label5:style:align to "CENTER".
    set status3label5:style:wordwrap to false.
    set status3label5:style:width to 105.
    set status3label5:style:bg to "starship_img/starship_background_dark_opacity0".
    set status3label5:style:border:h to 10.
    set status3label5:style:border:v to 10.
    set status3label5:tooltip to "% Liquid Oxygen Fuel Remaining".
    
local status4label4 is statusstackvlayout4:addlabel().
    set status4label4:style:fontsize to 16.
    set status4label4:style:align to "LEFT".
    set status4label4:style:margin:left to 20.
    set status4label4:style:wordwrap to false.
    set status4label4:style:width to 110.
    set status4label4:style:height to 19.
    set status4label4:tooltip to "Mach Nr. / Ground Speed / Orbital Speed".
local status4label5 is statusstackvlayout5:addlabel().
    set status4label5:style:margin:left to 20.
    set status4label5:style:fontsize to 16.
    set status4label5:style:align to "LEFT".
    set status4label5:style:wordwrap to false.
    set status4label5:style:width to 105.
    set status4label5:style:height to 19.
    set status4label5:tooltip to "Vertical Speed in m/s".

local statuscheckboxes is statusstackvlayout6:addvbox().
    set statuscheckboxes:style:margin:right to 0.
    set statuscheckboxes:style:vstretch to 1.
    set statuscheckboxes:style:bg to "starship_img/starship_main_square_bg".
local quickstatus1 is statuscheckboxes:addcheckbox("<b>Flaps</b>").
    set quickstatus1:style:margin:top to 12.
    set quickstatus1:style:margin:left to 10.
    set quickstatus1:style:fontsize to 18.
    set quickstatus1:style:width to 150.
    set quickstatus1:style:height to 29.
    set quickstatus1:style:overflow:right to -130.
    set quickstatus1:style:overflow:left to -3.
    set quickstatus1:style:overflow:top to -4.
    set quickstatus1:style:overflow:bottom to -9.
    set quickstatus1:tooltip to "Activate/Deactivate Flap Steering".
local quickstatus2 is statuscheckboxes:addcheckbox("<b>Lights</b>").
    set quickstatus2:style:margin:left to 10.
    set quickstatus2:style:fontsize to 18.
    set quickstatus2:style:width to 150.
    set quickstatus2:style:height to 29.
    set quickstatus2:style:overflow:right to -130.
    set quickstatus2:style:overflow:left to -3.
    set quickstatus2:style:overflow:top to -4.
    set quickstatus2:style:overflow:bottom to -9.
    set quickstatus2:tooltip to "Lights on/Lights off".
local quickstatus3 is statuscheckboxes:addcheckbox("<b>Gear</b>").
    set quickstatus3:style:margin:left to 10.
    set quickstatus3:style:fontsize to 18.
    set quickstatus3:style:wordwrap to false.
    set quickstatus3:style:width to 150.
    set quickstatus3:style:height to 29.
    set quickstatus3:style:overflow:right to -130.
    set quickstatus3:style:overflow:left to -3.
    set quickstatus3:style:overflow:top to -4.
    set quickstatus3:style:overflow:bottom to -9.
    set quickstatus3:tooltip to "Extend/Retract Gear".
    

set quickstatus1:ontoggle to {
    parameter click.
    if click {
        if ship:status = "PRELAUNCH" or LaunchButtonIsRunning or runningprogram = "After Landing" or runningprogram = "Landing" or runningprogram = "Final Approach" or runningprogram = "Venting Fuel.." {
            set quickstatus1:text to "<b><color=red>Flaps</color></b>".
            wait 0.25.
            set quickstatus1:text to "<b>Flaps</b>".
            if ship:status = "PRELAUNCH" or LaunchButtonIsRunning or runningprogram = "Venting Fuel.." {
                set quickstatus1:pressed to false.
            }
        }
        else {
            LogToFile("Flap control ON").
            setflaps(FWDFlapDefault, AFTFlapDefault, 1, 30).
        }
    }
    else {
        if not LandButtonIsRunning {
            LogToFile("Flap control OFF").
            setflaps(FWDFlapDefault, AFTFlapDefault, 0, 30).
        }
        else if AttitudeIsRunning {
            LogToFile("Flap control OFF").
            setflaps(FWDFlapDefault, AFTFlapDefault, 0, 30).
        }
        else if runningprogram = "After Landing" or runningprogram = "Landing" or runningprogram = "Final Approach" or runningprogram = "De-orbit & Landing" {
            set quickstatus1:pressed to true.
        }
        else {
            set quickstatus1:text to "<b>Flaps</b>".
        }
    }
}.

set quickstatus2:ontoggle to {
    parameter click.
    if click {
        LIGHTS ON.
    }
    else {
        LIGHTS OFF.
    }
}.

set quickstatus3:ontoggle to {
    parameter click.
    if click {
        GEAR ON.
    }
    else {
        GEAR OFF.
    }
}.


local enginestackhlayout to enginestack:addhlayout().
    set enginestackhlayout:style:bg to "starship_img/starship_main_square_bg".
local enginestackvlayout1 is enginestackhlayout:addvlayout().
    set enginestackvlayout1:style:vstretch to 1.
local enginestackvlayout2 is enginestackhlayout:addvlayout().
local enginestackvlayout3 is enginestackhlayout:addvlayout().
local enginestackvlayout4 is enginestackhlayout:addvlayout().
local enginestackvlayout5 is enginestackhlayout:addvlayout().
local enginestackvlayout6 is enginestackhlayout:addvlayout().
    
local engine1label1 is enginestackvlayout1:addlabel("<b> SL Raptors</b>").
    set engine1label1:style:margin:left to 5.
    set engine1label1:style:margin:top to 10.
    set engine1label1:style:width to 100.
    set engine1label1:style:fontsize to 18.
    set engine1label1:style:wordwrap to false.
    set engine1label1:style:align to "LEFT".
local engine1label2 is enginestackvlayout2:addlabel("-").
    set engine1label2:style:textcolor to grey.
    set engine1label2:style:margin:top to 10.
    set engine1label2:style:width to 40.
    set engine1label2:style:fontsize to 19.
    set engine1label2:style:wordwrap to false.
    set engine1label2:style:align to "LEFT".
local engine1label4 is enginestackvlayout4:addlabel("-").
    set engine1label4:style:textcolor to grey.
    set engine1label4:style:margin:top to 10.
    set engine1label4:style:margin:left to 20.
    set engine1label4:style:width to 40.
    set engine1label4:style:fontsize to 19.
    set engine1label4:style:wordwrap to false.
    set engine1label4:style:align to "LEFT".
local engine1label5 is enginestackvlayout5:addlabel("<b>VAC Raptors</b>").
    set engine1label5:style:margin:top to 10.
    set engine1label5:style:width to 100.
    set engine1label5:style:fontsize to 18.
    set engine1label5:style:wordwrap to false.
    set engine1label5:style:align to "LEFT".
    
local engine2label1 is enginestackvlayout1:addlabel("-").
    set engine2label1:style:textcolor to grey.
    set engine2label1:style:margin:top to 8.
    set engine2label1:style:margin:left to 10.
    set engine2label1:style:width to 100.
    set engine2label1:style:fontsize to 16.
    set engine2label1:style:wordwrap to false.
    set engine2label1:style:align to "CENTER".
    set engine2label1:style:bg to "starship_img/starship_background_white".
    set engine2label1:style:border:h to 10.
    set engine2label1:style:border:v to 10.
    set engine2label1:style:overflow:top to -1.
local engine2label2 is enginestackvlayout2:addlabel().
    set engine2label2:style:margin:top to 8.
    set engine2label2:style:bg to "starship_img/starship_background_dark_opacity0".
    set engine2label2:style:border:h to 10.
    set engine2label2:style:width to 40.
    set engine2label2:style:border:v to 10.
    set engine2label2:style:overflow:left to 110.
    set engine2label2:style:overflow:right to -50.
    set engine2label2:style:overflow:bottom to 0.
local engine2label3 is enginestackvlayout3:addlabel().
    set engine2label3:style:bg to "starship_img/starship_9engine_none_active".
    set engine2label3:style:wordwrap to false.
    set engine2label3:style:width to 70.
    set engine2label3:style:height to 48.
    set engine2label3:style:margin:top to 3.
    set engine2label3:style:margin:bottom to -20.
    set engine2label3:style:overflow:top to -5.
    set engine2label3:style:overflow:bottom to 55.
    set engine2label3:style:overflow:left to 65.
    set engine2label3:style:overflow:right to 65.
    set engine2label3:tooltip to "Visual Representation of current Engine performance".
local engine2label4 is enginestackvlayout4:addlabel().
    set engine2label4:style:margin:top to 8.
    set engine2label4:style:margin:left to 20.
    set engine2label4:style:align to "CENTER".
    set engine2label4:style:width to 40.
    set engine2label4:style:bg to "starship_img/starship_background_white".
    set engine2label4:style:border:h to 10.
    set engine2label4:style:border:v to 10.
    set engine2label4:style:overflow:left to -50.
    set engine2label4:style:overflow:right to 110.
    set engine2label4:style:overflow:bottom to -1.
local engine2label5 is enginestackvlayout5:addlabel("-").
    set engine2label5:style:textcolor to grey.
    set engine2label5:style:margin:top to 8.
    set engine2label5:style:width to 100.
    set engine2label5:style:fontsize to 16.
    set engine2label5:style:wordwrap to false.
    set engine2label5:style:align to "CENTER".
    set engine2label5:style:bg to "starship_img/starship_background_dark_opacity0".
    set engine2label5:style:border:h to 10.
    set engine2label5:style:border:v to 10.
    set engine2label5:style:overflow:bottom to 1.
    
local engine3label1 is enginestackvlayout1:addlabel("Pitch Gimbal").
    set engine3label1:style:margin:top to 2.
    set engine3label1:style:margin:left to 8.
    set engine3label1:style:width to 100.
    set engine3label1:style:fontsize to 19.
    set engine3label1:style:wordwrap to false.
    set engine3label1:style:align to "LEFT".
    set engine3label1:tooltip to "Thrust Vector Angle in the pitch axis".
local engine3label2 is enginestackvlayout2:addlabel("-").
    set engine3label2:style:margin:top to 2.
    set engine3label2:style:margin:left to 5.
    set engine3label2:style:fontsize to 19.
    set engine3label2:style:width to 50.
    set engine3label2:style:wordwrap to false.
    set engine3label2:style:align to "CENTER".
    set engine3label2:tooltip to "Engines pitch gimbal angle".
local engine3label4 is enginestackvlayout4:addlabel("-").
    set engine3label4:style:margin:top to 2.
    set engine3label4:style:margin:left to 0.
    set engine3label4:style:fontsize to 19.
    set engine3label4:style:width to 50.
    set engine3label4:style:wordwrap to false.
    set engine3label4:style:align to "CENTER".
    set engine3label4:tooltip to "Engines yaw gimbal angle".
local engine3label5 is enginestackvlayout5:addlabel("Yaw Gimbal").
    set engine3label5:style:margin:top to 2.
    set engine3label5:style:fontsize to 19.
    set engine3label5:style:wordwrap to false.
    set engine3label5:style:align to "LEFT".
    set engine3label5:tooltip to "Thrust Vector Angle in the yaw axis".

local enginecheckboxes is enginestackvlayout6:addvbox().
    set enginecheckboxes:style:margin:right to 0.
    set enginecheckboxes:style:vstretch to 1.
    set enginecheckboxes:style:bg to "starship_img/starship_main_square_bg".
local quickengine1 is enginecheckboxes:addcheckbox("<b>OFF</b>").
    set quickengine1:exclusive to true.
    //set quickengine1:toggle to true.
    set quickengine1:style:margin:top to 12.
    set quickengine1:style:margin:left to 10.
    set quickengine1:style:fontsize to 18.
    set quickengine1:style:width to 150.
    set quickengine1:style:height to 29.
    set quickengine1:style:overflow:right to -130.
    set quickengine1:style:overflow:left to -3.
    set quickengine1:style:overflow:top to -4.
    set quickengine1:style:overflow:bottom to -9.
    set quickengine1:tooltip to "Turn off all engines".
local quickengine2 is enginecheckboxes:addcheckbox("<b>SL Raptors</b>").
    set quickengine2:toggle to true.
    set quickengine2:style:margin:left to 10.
    set quickengine2:style:fontsize to 18.
    set quickengine2:style:width to 150.
    set quickengine2:style:height to 29.
    set quickengine2:style:overflow:right to -130.
    set quickengine2:style:overflow:left to -3.
    set quickengine2:style:overflow:top to -4.
    set quickengine2:style:overflow:bottom to -9.
    set quickengine2:tooltip to "Turn on sea-level Raptors".
local quickengine3 is enginecheckboxes:addcheckbox("<b>VAC Raptors</b>").
    set quickengine3:toggle to true.
    set quickengine3:style:margin:left to 10.
    set quickengine3:style:fontsize to 18.
    set quickengine3:style:width to 150.
    set quickengine3:style:height to 29.
    set quickengine3:style:overflow:right to -130.
    set quickengine3:style:overflow:left to -3.
    set quickengine3:style:overflow:top to -4.
    set quickengine3:style:overflow:bottom to -9.
    set quickengine3:tooltip to "Turn on vacuum Raptors".
    
set quickengine1:onclick to {
    for eng in SLEngines {eng:shutdown.}.
    for eng in VACEngines {eng:shutdown.}.
    LogToFile("ALL Engines turned OFF").
    if not (ShipType = "Expendable") and not (ShipType = "Depot") and not (ShipType = "Block1Exp") and not (ShipType = "Block1") and not (ShipType = "Block1Cargo") and not (ShipType = "Block1CargoExp") and not (ShipType = "Block1PEZExp") and not (ShipType = "Block1PEZ") {
        Nose:shutdown.
    } else if (ShipType = "Block1" or ShipType = "Block1Cargo" or ShipType = "Block1PEZ") {
        HeaderTank:shutdown.
    }
    Tank:shutdown.
    SLEngines[0]:getmodule("ModuleGimbal"):SetField("gimbal limit", 0).
    SLEngines[1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 0).
    SLEngines[2]:getmodule("ModuleGimbal"):SetField("gimbal limit", 0).
}.

set quickengine2:ontoggle to {
    parameter click.
    if click {
        if ship:status = "PRELAUNCH" {
            set quickengine2:text to "<b><color=red>SL Raptors</color></b>".
            wait 0.25.
            set quickengine2:text to "<b>SL Raptors</b>".
            set quickengine2:pressed to false.
        }
        else {
            set quickengine1:pressed to false.
            ActivateEngines(0).
            LogToFile("SL Engines ON").
        }
    }
    else {
        if quickengine3:pressed {
            for eng in SLEngines {eng:shutdown.}.
            LogToFile("SL Engines OFF").
        }
        else {
            ShutDownAllEngines().
        }
    }
}.
    
set quickengine3:ontoggle to {
    parameter click.
    if click {
        if ship:status = "PRELAUNCH" {
            set quickengine3:text to "<b><color=red>VAC Raptors</color></b>".
            wait 0.25.
            set quickengine3:text to "<b>VAC Raptors</b>".
            set quickengine3:pressed to false.
        }
        else {
            set quickengine1:pressed to false.
            ActivateEngines(1).
            LogToFile("VAC Engines ON").
        }
    }
    else {
        if quickengine2:pressed {
            for eng in VACEngines {eng:shutdown.}.
            LogToFile("VAC Engines OFF").
        }
        else {
            ShutDownAllEngines().
        }
    }
}.

local orbitstackhlayout to orbitstack:addhlayout().
    set orbitstackhlayout:style:bg to "starship_img/starship_main_square_bg".
local orbitstackvlayout1 is orbitstackhlayout:addvlayout().
    set orbitstackvlayout1:style:vstretch to true.
local orbitstackvlayout2 is orbitstackhlayout:addvlayout().
local orbitstackvlayout3 is orbitstackhlayout:addvlayout().
    
local orbit1label1 is orbitstackvlayout1:addlabel().
    set orbit1label1:style:wordwrap to false.
    set orbit1label1:style:margin:left to 10.
    set orbit1label1:style:margin:top to 8.
    set orbit1label1:style:fontsize to 19.
    set orbit1label1:style:width to 200.
    set orbit1label1:style:align to "LEFT".
    set orbit1label1:style:vstretch to true.
    set orbit1label1:tooltip to "Highest point in orbit (km)".
local orbit1label2 is orbitstackvlayout2:addlabel().
    set orbit1label2:style:wordwrap to false.
    set orbit1label2:style:margin:top to 8.
    set orbit1label2:style:fontsize to 19.
    set orbit1label2:style:width to 200.
    set orbit1label2:style:align to "LEFT".
    set orbit1label2:style:vstretch to true.
    set orbit1label2:tooltip to "Time to highest point in orbit".
    set orbit1label2:style:overflow:left to -245.
    set orbit1label2:style:overflow:right to 145.
    set orbit1label2:style:overflow:top to 0.
    set orbit1label2:style:overflow:bottom to 60.
local orbit1label3 is orbitstackvlayout3:addlabel().
    set orbit1label3:style:wordwrap to false.
    set orbit1label3:style:margin:top to 8.
    set orbit1label3:style:fontsize to 19.
    set orbit1label3:style:align to "LEFT".
    set orbit1label3:style:vstretch to true.
    set orbit1label3:style:width to 125.
    set orbit1label3:style:height to 25.
    set orbit1label3:style:overflow:right to -100.
    set orbit1label3:tooltip to "No Maneuver Node = Grey / Maneuver Node = Magenta".
    
local orbit2label1 is orbitstackvlayout1:addlabel().
    set orbit2label1:style:wordwrap to false.
    set orbit2label1:style:margin:left to 10.
    set orbit2label1:style:width to 200.
    set orbit2label1:style:vstretch to true.
    set orbit2label1:style:fontsize to 19.
    set orbit2label1:style:align to "LEFT".
    set orbit2label1:tooltip to "Lowest point in orbit (km). <0 = Below the surface".
local orbit2label2 is orbitstackvlayout2:addlabel().
    set orbit2label2:style:vstretch to true.
    set orbit2label2:style:wordwrap to false.
    set orbit2label2:style:fontsize to 19.
    set orbit2label2:style:width to 200.
    set orbit2label2:style:align to "LEFT".
    set orbit2label2:tooltip to "Time to lowest point in orbit".
local orbit2label3 is orbitstackvlayout3:addlabel().
    set orbit2label3:style:vstretch to true.
    set orbit2label3:style:wordwrap to false.
    set orbit2label3:style:fontsize to 19.
    set orbit2label3:style:width to 125.
    set orbit2label3:style:align to "LEFT".
    set orbit2label3:tooltip to "Required Delta-V for Maneuver".
    
local orbit3label1 is orbitstackvlayout1:addlabel().
    set orbit3label1:style:margin:left to 10.
    set orbit3label1:style:margin:bottom to 9.
    set orbit3label1:style:wordwrap to false.
    set orbit3label1:style:width to 200.
    set orbit3label1:style:vstretch to true.
    set orbit3label1:style:fontsize to 19.
    set orbit3label1:style:align to "LEFT".
    set orbit3label1:tooltip to "Time it takes for 1 full orbit".
local orbit3label2 is orbitstackvlayout2:addlabel().
    set orbit3label2:style:margin:bottom to 9.
    set orbit3label2:style:wordwrap to false.
    set orbit3label2:style:vstretch to true.
    set orbit3label2:style:fontsize to 19.
    set orbit3label2:style:width to 200.
    set orbit3label2:style:align to "LEFT".
    set orbit3label2:tooltip to "Angle between the reference plane and the orbital plane".
local orbit3label3 is orbitstackvlayout3:addlabel().
    set orbit3label3:style:margin:bottom to 9.
    set orbit3label3:style:wordwrap to false.
    set orbit3label3:style:vstretch to true.
    set orbit3label3:style:fontsize to 19.
    set orbit3label3:style:align to "LEFT".
    set orbit3label3:style:width to 125.
    set orbit3label3:style:height to 25.
    set orbit3label3:style:overflow:right to -100.
    set orbit3label3:tooltip to "Navigational Capability: GPS (Satellite), IRS (Inertial) or CBN (Celestial)".
    

local crewstackhlayout to crewstack:addhlayout().
    set crewstackhlayout:style:bg to "starship_img/starship_main_square_bg".
local crewstackvlayout1 is crewstackhlayout:addvlayout().
    set crewstackvlayout1:style:vstretch to true.
local crewstackvlayout2 is crewstackhlayout:addvlayout().
local crewstackvlayout3 is crewstackhlayout:addvlayout().
local crewstackvlayout4 is crewstackhlayout:addvlayout().
local crewstackvlayout5 is crewstackhlayout:addvlayout().
local crewstackvlayout6 is crewstackhlayout:addvlayout().

local crew1label1 is crewstackvlayout1:addlabel().
    set crew1label1:style:wordwrap to false.
    set crew1label1:style:margin:top to 0.
    set crew1label1:style:margin:left to 20.
    set crew1label1:style:fontsize to 19.
    set crew1label1:style:width to 80.
    set crew1label1:style:height to 25.
    set crew1label1:style:align to "LEFT".
    set crew1label1:style:overflow:top to -10.
    set crew1label1:style:overflow:bottom to 70.
    set crew1label1:tooltip to "Experience Level".
local crew1label2 is crewstackvlayout2:addlabel().
    set crew1label2:style:wordwrap to false.
    set crew1label2:style:margin:top to 0.
    set crew1label2:style:fontsize to 19.
    set crew1label2:style:width to 80.
    set crew1label2:style:height to 25.
    set crew1label2:style:align to "LEFT".
    set crew1label2:style:overflow:top to -10.
    set crew1label2:style:overflow:bottom to 70.
    set crew1label2:tooltip to "Experience Level".
local crew1label3 is crewstackvlayout3:addlabel().
    set crew1label3:style:wordwrap to false.
    set crew1label3:style:margin:top to 0.
    set crew1label3:style:fontsize to 19.
    set crew1label3:style:align to "LEFT".
    set crew1label3:style:width to 80.
    set crew1label3:style:height to 25.
    set crew1label3:style:overflow:top to -10.
    set crew1label3:style:overflow:bottom to 70.
    set crew1label3:tooltip to "Experience Level".
local crew1label4 is crewstackvlayout4:addlabel().
    set crew1label4:style:wordwrap to false.
    set crew1label4:style:margin:top to 0.
    set crew1label4:style:fontsize to 19.
    set crew1label4:style:align to "LEFT".
    set crew1label4:style:width to 80.
    set crew1label4:style:height to 25.
    set crew1label4:style:overflow:top to -10.
    set crew1label4:style:overflow:bottom to 70.
    set crew1label4:tooltip to "Experience Level".
local crew1label5 is crewstackvlayout5:addlabel().
    set crew1label5:style:wordwrap to false.
    set crew1label5:style:margin:top to 0.
    set crew1label5:style:fontsize to 19.
    set crew1label5:style:align to "LEFT".
    set crew1label5:style:width to 80.
    set crew1label5:style:height to 25.
    set crew1label5:style:overflow:top to -10.
    set crew1label5:style:overflow:bottom to 70.
    set crew1label5:tooltip to "Experience Level".
local crew1label6 is crewstackvlayout6:addlabel().
    set crew1label6:style:wordwrap to false.
    set crew1label6:style:margin:top to 0.
    set crew1label6:style:fontsize to 19.
    set crew1label6:style:align to "LEFT".
    set crew1label6:style:width to 80.
    set crew1label6:style:height to 25.
    set crew1label6:style:overflow:top to -10.
    set crew1label6:style:overflow:bottom to 70.
    set crew1label6:tooltip to "Experience Level".

local crew2label1 is crewstackvlayout1:addlabel().
    set crew2label1:style:wordwrap to false.
    set crew2label1:style:margin:left to 20.
    set crew2label1:style:fontsize to 22.
    set crew2label1:style:align to "CENTER".
    set crew2label1:style:textcolor to grey.
    set crew2label1:style:width to 80.
    set crew2label1:style:height to 49.
    set crew2label1:style:overflow:top to 25.
    set crew2label1:style:overflow:bottom to -54.
    set crew2label1:style:overflow:left to -10.
    set crew2label1:style:overflow:right to -10.
    set crew2label1:tooltip to "Crew Member 1".
local crew2label2 is crewstackvlayout2:addlabel().
    set crew2label2:style:wordwrap to false.
    set crew2label2:style:fontsize to 22.
    set crew2label2:style:align to "CENTER".
    set crew2label2:style:textcolor to grey.
    set crew2label2:style:width to 80.
    set crew2label2:style:height to 49.
    set crew2label2:style:overflow:top to 25.
    set crew2label2:style:overflow:bottom to -54.
    set crew2label2:style:overflow:left to -10.
    set crew2label2:style:overflow:right to -10.
    set crew2label2:tooltip to "Crew Member 2".
local crew2label3 is crewstackvlayout3:addlabel().
    set crew2label3:style:wordwrap to false.
    set crew2label3:style:fontsize to 22.
    set crew2label3:style:align to "CENTER".
    set crew2label3:style:textcolor to grey.
    set crew2label3:style:width to 80.
    set crew2label3:style:height to 49.
    set crew2label3:style:overflow:top to 25.
    set crew2label3:style:overflow:bottom to -54.
    set crew2label3:style:overflow:left to -10.
    set crew2label3:style:overflow:right to -10.
    set crew2label3:tooltip to "Crew Member 3".
local crew2label4 is crewstackvlayout4:addlabel().
    set crew2label4:style:wordwrap to false.
    set crew2label4:style:fontsize to 22.
    set crew2label4:style:align to "CENTER".
    set crew2label4:style:textcolor to grey.
    set crew2label4:style:width to 80.
    set crew2label4:style:height to 49.
    set crew2label4:style:overflow:top to 25.
    set crew2label4:style:overflow:bottom to -54.
    set crew2label4:style:overflow:left to -10.
    set crew2label4:style:overflow:right to -10.
    set crew2label4:tooltip to "Crew Member 4".
local crew2label5 is crewstackvlayout5:addlabel().
    set crew2label5:style:wordwrap to false.
    set crew2label5:style:fontsize to 22.
    set crew2label5:style:align to "CENTER".
    set crew2label5:style:textcolor to grey.
    set crew2label5:style:width to 80.
    set crew2label5:style:height to 49.
    set crew2label5:style:overflow:top to 25.
    set crew2label5:style:overflow:bottom to -54.
    set crew2label5:style:overflow:left to -10.
    set crew2label5:style:overflow:right to -10.
    set crew2label5:tooltip to "Crew Member 5".
local crew2label6 is crewstackvlayout6:addlabel().
    set crew2label6:style:wordwrap to false.
    set crew2label6:style:fontsize to 22.
    set crew2label6:style:align to "CENTER".
    set crew2label6:style:textcolor to grey.
    set crew2label6:style:width to 80.
    set crew2label6:style:height to 49.
    set crew2label6:style:overflow:top to 25.
    set crew2label6:style:overflow:bottom to -54.
    set crew2label6:style:overflow:left to -10.
    set crew2label6:style:overflow:right to -10.
    set crew2label6:tooltip to "Crew Member 6".

local crew3label1 is crewstackvlayout1:addlabel().
    set crew3label1:style:margin:top to 5.
    set crew3label1:style:margin:left to 20.
    set crew3label1:style:wordwrap to false.
    set crew3label1:style:fontsize to 18.
    set crew3label1:style:align to "CENTER".
    set crew3label1:style:width to 80.
    set crew3label1:style:height to 30.
    set crew3label1:style:overflow:top to 20.
    set crew3label1:style:overflow:bottom to -20.
    set crew3label1:style:overflow:left to 15.
    set crew3label1:style:overflow:right to -65.
    set crew3label1:tooltip to "Name & Role (Pilot, Engineer or Scientist)".
local crew3label2 is crewstackvlayout2:addlabel().
    set crew3label2:style:margin:top to 5.
    set crew3label2:style:wordwrap to false.
    set crew3label2:style:fontsize to 18.
    set crew3label2:style:align to "CENTER".
    set crew3label2:style:width to 80.
    set crew3label2:style:height to 30.
    set crew3label2:style:overflow:top to 20.
    set crew3label2:style:overflow:bottom to -20.
    set crew3label2:style:overflow:left to 15.
    set crew3label2:style:overflow:right to -65.
    set crew3label2:tooltip to "Name & Role (Pilot, Engineer or Scientist)".
local crew3label3 is crewstackvlayout3:addlabel().
    set crew3label3:style:margin:top to 5.
    set crew3label3:style:wordwrap to false.
    set crew3label3:style:fontsize to 18.
    set crew3label3:style:align to "CENTER".
    set crew3label3:style:width to 80.
    set crew3label3:style:height to 30.
    set crew3label3:style:overflow:top to 20.
    set crew3label3:style:overflow:bottom to -20.
    set crew3label3:style:overflow:left to 15.
    set crew3label3:style:overflow:right to -65.
    set crew3label3:tooltip to "Name & Role (Pilot, Engineer or Scientist)".
local crew3label4 is crewstackvlayout4:addlabel().
    set crew3label4:style:margin:top to 5.
    set crew3label4:style:wordwrap to false.
    set crew3label4:style:fontsize to 18.
    set crew3label4:style:align to "CENTER".
    set crew3label4:style:width to 80.
    set crew3label4:style:height to 30.
    set crew3label4:style:overflow:top to 20.
    set crew3label4:style:overflow:bottom to -20.
    set crew3label4:style:overflow:left to 15.
    set crew3label4:style:overflow:right to -65.
    set crew3label4:tooltip to "Name & Role (Pilot, Engineer or Scientist)".
local crew3label5 is crewstackvlayout5:addlabel().
    set crew3label5:style:margin:top to 5.
    set crew3label5:style:wordwrap to false.
    set crew3label5:style:fontsize to 18.
    set crew3label5:style:align to "CENTER".
    set crew3label5:style:width to 80.
    set crew3label5:style:height to 30.
    set crew3label5:style:overflow:top to 20.
    set crew3label5:style:overflow:bottom to -20.
    set crew3label5:style:overflow:left to 15.
    set crew3label5:style:overflow:right to -65.
    set crew3label5:tooltip to "Name & Role (Pilot, Engineer or Scientist)".
local crew3label6 is crewstackvlayout6:addlabel().
    set crew3label6:style:margin:top to 5.
    set crew3label6:style:wordwrap to false.
    set crew3label6:style:fontsize to 18.
    set crew3label6:style:align to "CENTER".
    set crew3label6:style:width to 80.
    set crew3label6:style:height to 30.
    set crew3label6:style:overflow:top to 20.
    set crew3label6:style:overflow:bottom to -20.
    set crew3label6:style:overflow:left to 15.
    set crew3label6:style:overflow:right to -65.
    set crew3label6:tooltip to "Name & Role (Pilot, Engineer or Scientist)".

local crew1label7 is crewstackvlayout1:addlabel().
    set crew1label7:style:wordwrap to false.
    set crew1label7:style:margin:top to 0.
    set crew1label7:style:margin:left to 20.
    set crew1label7:style:fontsize to 19.
    set crew1label7:style:width to 80.
    set crew1label7:style:height to 25.
    set crew1label7:style:align to "LEFT".
    set crew1label7:style:overflow:top to -10.
    set crew1label7:style:overflow:bottom to 70.
    set crew1label7:tooltip to "Experience Level".
local crew1label8 is crewstackvlayout2:addlabel().
    set crew1label8:style:wordwrap to false.
    set crew1label8:style:margin:top to 0.
    set crew1label8:style:fontsize to 19.
    set crew1label8:style:width to 80.
    set crew1label8:style:height to 25.
    set crew1label8:style:align to "LEFT".
    set crew1label8:style:overflow:top to -10.
    set crew1label8:style:overflow:bottom to 70.
    set crew1label8:tooltip to "Experience Level".
local crew1label9 is crewstackvlayout3:addlabel().
    set crew1label9:style:wordwrap to false.
    set crew1label9:style:margin:top to 0.
    set crew1label9:style:fontsize to 19.
    set crew1label9:style:width to 80.
    set crew1label9:style:height to 25.
    set crew1label9:style:align to "LEFT".
    set crew1label9:style:overflow:top to -10.
    set crew1label9:style:overflow:bottom to 70.
    set crew1label9:tooltip to "Experience Level".
local crew1label10 is crewstackvlayout4:addlabel().
    set crew1label10:style:wordwrap to false.
    set crew1label10:style:margin:top to 0.
    set crew1label10:style:fontsize to 19.
    set crew1label10:style:width to 80.
    set crew1label10:style:height to 25.
    set crew1label10:style:align to "LEFT".
    set crew1label10:style:overflow:top to -10.
    set crew1label10:style:overflow:bottom to 70.
    set crew1label10:tooltip to "Experience Level".
local crew2label7 is crewstackvlayout1:addlabel().
    set crew2label7:style:wordwrap to false.
    set crew2label7:style:margin:left to 20.
    set crew2label7:style:fontsize to 22.
    set crew2label7:style:align to "CENTER".
    set crew2label7:style:textcolor to grey.
    set crew2label7:style:width to 80.
    set crew2label7:style:height to 49.
    set crew2label7:style:overflow:top to 25.
    set crew2label7:style:overflow:bottom to -54.
    set crew2label7:style:overflow:left to -10.
    set crew2label7:style:overflow:right to -10.
    set crew2label7:tooltip to "Crew Member 7".
local crew2label8 is crewstackvlayout2:addlabel().
    set crew2label8:style:wordwrap to false.
    set crew2label8:style:fontsize to 22.
    set crew2label8:style:align to "CENTER".
    set crew2label8:style:textcolor to grey.
    set crew2label8:style:width to 80.
    set crew2label8:style:height to 49.
    set crew2label8:style:overflow:top to 25.
    set crew2label8:style:overflow:bottom to -54.
    set crew2label8:style:overflow:left to -10.
    set crew2label8:style:overflow:right to -10.
    set crew2label8:tooltip to "Crew Member 8".
local crew2label9 is crewstackvlayout3:addlabel().
    set crew2label9:style:wordwrap to false.
    set crew2label9:style:fontsize to 22.
    set crew2label9:style:align to "CENTER".
    set crew2label9:style:textcolor to grey.
    set crew2label9:style:width to 80.
    set crew2label9:style:height to 49.
    set crew2label9:style:overflow:top to 25.
    set crew2label9:style:overflow:bottom to -54.
    set crew2label9:style:overflow:left to -10.
    set crew2label9:style:overflow:right to -10.
    set crew2label9:tooltip to "Crew Member 9".
local crew2label10 is crewstackvlayout4:addlabel().
    set crew2label10:style:wordwrap to false.
    set crew2label10:style:fontsize to 22.
    set crew2label10:style:align to "CENTER".
    set crew2label10:style:textcolor to grey.
    set crew2label10:style:width to 80.
    set crew2label10:style:height to 49.
    set crew2label10:style:overflow:top to 25.
    set crew2label10:style:overflow:bottom to -54.
    set crew2label10:style:overflow:left to -10.
    set crew2label10:style:overflow:right to -10.
    set crew2label10:tooltip to "Crew Member 10".
local crew3label7 is crewstackvlayout1:addlabel().
    set crew3label7:style:margin:top to 5.
    set crew3label7:style:margin:left to 20.
    set crew3label7:style:wordwrap to false.
    set crew3label7:style:fontsize to 18.
    set crew3label7:style:align to "CENTER".
    set crew3label7:style:width to 80.
    set crew3label7:style:height to 30.
    set crew3label7:style:overflow:top to 20.
    set crew3label7:style:overflow:bottom to -20.
    set crew3label7:style:overflow:left to 15.
    set crew3label7:style:overflow:right to -65.
    set crew3label7:tooltip to "Name & Role (Pilot, Engineer or Scientist)".
local crew3label8 is crewstackvlayout2:addlabel().
    set crew3label8:style:margin:top to 5.
    set crew3label8:style:wordwrap to false.
    set crew3label8:style:fontsize to 18.
    set crew3label8:style:align to "CENTER".
    set crew3label8:style:width to 80.
    set crew3label8:style:height to 30.
    set crew3label8:style:overflow:top to 20.
    set crew3label8:style:overflow:bottom to -20.
    set crew3label8:style:overflow:left to 15.
    set crew3label8:style:overflow:right to -65.
    set crew3label8:tooltip to "Name & Role (Pilot, Engineer or Scientist)".
local crew3label9 is crewstackvlayout3:addlabel().
    set crew3label9:style:margin:top to 5.
    set crew3label9:style:wordwrap to false.
    set crew3label9:style:fontsize to 18.
    set crew3label9:style:align to "CENTER".
    set crew3label9:style:width to 80.
    set crew3label9:style:height to 30.
    set crew3label9:style:overflow:top to 20.
    set crew3label9:style:overflow:bottom to -20.
    set crew3label9:style:overflow:left to 15.
    set crew3label9:style:overflow:right to -65.
    set crew3label9:tooltip to "Name & Role (Pilot, Engineer or Scientist)".
local crew3label10 is crewstackvlayout4:addlabel().
    set crew3label10:style:margin:top to 5.
    set crew3label10:style:wordwrap to false.
    set crew3label10:style:fontsize to 18.
    set crew3label10:style:align to "CENTER".
    set crew3label10:style:width to 80.
    set crew3label10:style:height to 30.
    set crew3label10:style:overflow:top to 20.
    set crew3label10:style:overflow:bottom to -20.
    set crew3label10:style:overflow:left to 15.
    set crew3label10:style:overflow:right to -65.
    set crew3label10:tooltip to "Name & Role (Pilot, Engineer or Scientist)".

local crewlabel1 is crewstackvlayout5:addlabel("<b>ECLSS</b>").
    set crewlabel1:style:fontsize to 18.
    set crewlabel1:style:margin:top to 15.
    set crewlabel1:style:width to 60.
    set crewlabel1:style:bg to "starship_img/starship_background_dark".
    set crewlabel1:style:overflow:left to 10.
    set crewlabel1:style:overflow:top to 5.
    set crewlabel1:style:overflow:right to 126.
    set crewlabel1:style:overflow:bottom to 75.
    set crewlabel1:style:border:h to 10.
    set crewlabel1:style:border:v to 10.
    set crewlabel1:style:wordwrap to false.
    set crewlabel1:tooltip to "Environmental Control and Life Support System".
local crewlabel2 is crewstackvlayout5:addlabel("<b>P:  <color=green>99.2 kPa</color></b>").
    set crewlabel2:style:fontsize to 13.
    set crewlabel2:style:width to 60.
    set crewlabel2:style:margin:top to 15.
    set crewlabel2:style:wordwrap to false.
    set crewlabel2:tooltip to "Cabin Pressure. Normal: 96.5 kPa - 102.7 kPa".
local crewlabel3 is crewstackvlayout5:addlabel("<b>T:   <color=green>22.3°c</color></b>").
    set crewlabel3:style:fontsize to 13.
    set crewlabel3:style:width to 60.
    set crewlabel3:style:margin:top to 6.
    set crewlabel3:style:wordwrap to false.
    set crewlabel3:tooltip to "Cabin Temperature. Normal: 18.3°c - 26.7°c".
local crewlabel4 is crewstackvlayout6:addlabel("<size=14>3/3 running</size>").
    set crewlabel4:style:fontsize to 18.
    set crewlabel4:style:width to 60.
    set crewlabel4:style:wordwrap to false.
    set crewlabel4:style:margin:top to 15.
    set crewlabel4:style:overflow:left to 30.
    set crewlabel4:style:overflow:right to -70.
    set crewlabel4:style:bg to "starship_img/eclss".
    set crewlabel4:tooltip to "All Environmental Control Systems functioning properly".
local crewlabel5 is crewstackvlayout6:addlabel("<b>AQM:  <color=green>OK</color></b>").
    set crewlabel5:style:fontsize to 13.
    set crewlabel5:style:width to 60.
    set crewlabel5:style:margin:top to 15.
    set crewlabel5:style:wordwrap to false.
    set crewlabel5:tooltip to "Air Quality Monitor".
local crewlabel6 is crewstackvlayout6:addlabel().
    set crewlabel6:style:fontsize to 13.
    set crewlabel6:style:width to 60.
    set crewlabel6:style:margin:top to 6.
    set crewlabel6:style:overflow:left to -5.
    set crewlabel6:style:overflow:right to -5.
    set crewlabel6:tooltip to "Circulation Fan running".

local towerstackhlayout is towerstack:addhlayout().
    set towerstackhlayout:style:bg to "starship_img/starship_main_square_bg".
local towerstackvlayout1 is towerstackhlayout:addvlayout().
local towerstackvlayout2 is towerstackhlayout:addvlayout().
local towerstackvlayout3 is towerstackhlayout:addvlayout().
local towerstackvlayout4 is towerstackhlayout:addvlayout().
local towerstackvlayout5 is towerstackhlayout:addvlayout().
local towerstackvlayout6 is towerstackhlayout:addvlayout().
local towerstackhlayout2 is towerstackhlayout:addhlayout().
    set towerstackhlayout2:style:margin:right to 0.
    set towerstackhlayout2:style:vstretch to 1.
    set towerstackhlayout2:style:bg to "starship_img/starship_main_square_bg".
local towerstackvlayout7 is towerstackhlayout2:addvlayout().
local towerstackvlayout8 is towerstackhlayout2:addvlayout().
local towerstackvlayout9 is towerstackhlayout2:addvlayout().
local towerstackvlayout10 is towerstackhlayout2:addvlayout().
local towerstackvlayout11 is towerstackhlayout2:addvlayout().
local towerstackvlayout12 is towerstackhlayout2:addvlayout().
local towerstackvlayout13 is towerstackhlayout2:addvlayout().


local tower1label2 is towerstackvlayout1:addlabel("<b>ROT</b>").
    set tower1label2:style:wordwrap to false.
    set tower1label2:style:vstretch to true.
    set tower1label2:style:fontsize to 16.
    set tower1label2:style:align to "LEFT".
    set tower1label2:style:width to 35.
    set tower1label2:tooltip to "Mechazilla Arm Rotation".
local tower1label3 is towerstackvlayout1:addlabel("<b>ANG</b>").
    set tower1label3:style:wordwrap to false.
    set tower1label3:style:vstretch to true.
    set tower1label3:style:fontsize to 16.
    set tower1label3:style:align to "LEFT".
    set tower1label3:style:width to 35.
    set tower1label3:tooltip to "Mechazilla Arm Open Angle".
local tower1label4 is towerstackvlayout1:addlabel("<b>HGT</b>").
    set tower1label4:style:wordwrap to false.
    set tower1label4:style:vstretch to true.
    set tower1label4:style:fontsize to 16.
    set tower1label4:style:align to "LEFT".
    set tower1label4:style:width to 35.
    set tower1label4:tooltip to "Mechazilla Arm Height".

local tower2button2 is towerstackvlayout2:addbutton("<b><<</b>").
    set tower2button2:style:margin:top to 8.
    set tower2button2:style:margin:left to 0.
    set tower2button2:style:width to 35.
    set tower2button2:style:height to 25.
    set tower2button2:style:fontsize to 20.
local tower2button3 is towerstackvlayout2:addbutton("<b><<</b>").
    set tower2button3:style:margin:top to 12.
    set tower2button3:style:margin:left to 0.
    set tower2button3:style:width to 35.
    set tower2button3:style:height to 25.
    set tower2button3:style:fontsize to 20.
local tower2button4 is towerstackvlayout2:addbutton("<b>vv</b>").
    set tower2button4:style:margin:top to 12.
    set tower2button4:style:margin:left to 0.
    set tower2button4:style:width to 35.
    set tower2button4:style:height to 25.
    set tower2button4:style:fontsize to 20.

local tower3button2 is towerstackvlayout3:addbutton("<b><</b>").
    set tower3button2:style:margin:top to 8.
    set tower3button2:style:margin:left to 0.
    set tower3button2:style:width to 25.
    set tower3button2:style:height to 25.
    set tower3button2:style:fontsize to 20.
local tower3button3 is towerstackvlayout3:addbutton("<b><</b>").
    set tower3button3:style:margin:top to 12.
    set tower3button3:style:margin:left to 0.
    set tower3button3:style:width to 25.
    set tower3button3:style:height to 25.
    set tower3button3:style:fontsize to 20.
local tower3button4 is towerstackvlayout3:addbutton("<b>v</b>").
    set tower3button4:style:margin:top to 12.
    set tower3button4:style:margin:left to 0.
    set tower3button4:style:width to 25.
    set tower3button4:style:height to 25.
    set tower3button4:style:fontsize to 20.

local tower4label2 is towerstackvlayout4:addlabel("<b>0*</b>").
    set tower4label2:style:wordwrap to false.
    set tower4label2:style:vstretch to true.
    set tower4label2:style:fontsize to 16.
    set tower4label2:style:align to "CENTER".
    set tower4label2:style:width to 50.
    set tower4label2:tooltip to "Mechazilla Current/Desired Rotation".
local tower4label3 is towerstackvlayout4:addlabel("<b>0*</b>").
    set tower4label3:style:wordwrap to false.
    set tower4label3:style:vstretch to true.
    set tower4label3:style:fontsize to 16.
    set tower4label3:style:align to "CENTER".
    set tower4label3:style:width to 50.
    set tower4label3:tooltip to "Mechazilla Current/Desired Arm Open Angle".
local tower4label4 is towerstackvlayout4:addlabel("<b>0*</b>").
    set tower4label4:style:wordwrap to false.
    set tower4label4:style:vstretch to true.
    if RSS {
        set tower4label4:style:fontsize to 11.
    }
    else {
        set tower4label4:style:fontsize to 14.
    }
    set tower4label4:style:align to "CENTER".
    set tower4label4:style:width to 50.
    set tower4label4:tooltip to "Mechazilla Current/Desired Height".

local tower5button2 is towerstackvlayout5:addbutton("<b>></b>").
    set tower5button2:style:margin:top to 8.
    set tower5button2:style:margin:left to 0.
    set tower5button2:style:width to 25.
    set tower5button2:style:height to 25.
    set tower5button2:style:fontsize to 20.
local tower5button3 is towerstackvlayout5:addbutton("<b>></b>").
    set tower5button3:style:margin:top to 12.
    set tower5button3:style:margin:left to 0.
    set tower5button3:style:width to 25.
    set tower5button3:style:height to 25.
    set tower5button3:style:fontsize to 20.
local tower5button4 is towerstackvlayout5:addbutton("<b>^</b>").
    set tower5button4:style:margin:top to 12.
    set tower5button4:style:margin:left to 0.
    set tower5button4:style:width to 25.
    set tower5button4:style:height to 25.
    set tower5button4:style:fontsize to 20.

local tower6button2 is towerstackvlayout6:addbutton("<b>>></b>").
    set tower6button2:style:margin:top to 8.
    set tower6button2:style:margin:left to 0.
    set tower6button2:style:width to 35.
    set tower6button2:style:height to 25.
    set tower6button2:style:fontsize to 20.
local tower6button3 is towerstackvlayout6:addbutton("<b>>></b>").
    set tower6button3:style:margin:top to 12.
    set tower6button3:style:margin:left to 0.
    set tower6button3:style:width to 35.
    set tower6button3:style:height to 25.
    set tower6button3:style:fontsize to 20.
local tower6button4 is towerstackvlayout6:addbutton("<b>^^</b>").
    set tower6button4:style:margin:top to 12.
    set tower6button4:style:margin:left to 0.
    set tower6button4:style:width to 35.
    set tower6button4:style:height to 25.
    set tower6button4:style:fontsize to 20.

local tower7label2 is towerstackvlayout7:addlabel("<b>PUSH</b>").
    set tower7label2:style:wordwrap to false.
    set tower7label2:style:vstretch to true.
    set tower7label2:style:fontsize to 16.
    set tower7label2:style:align to "LEFT".
    set tower7label2:style:width to 45.
    set tower7label2:tooltip to "Mechazilla Pusher Controls".
local tower7label3 is towerstackvlayout7:addlabel("<b>STAB</b>").
    set tower7label3:style:wordwrap to false.
    set tower7label3:style:vstretch to true.
    set tower7label3:style:fontsize to 16.
    set tower7label3:style:align to "LEFT".
    set tower7label3:style:width to 45.
    set tower7label3:tooltip to "Mechazilla Stabilizer Controls".
local tower7label4 is towerstackvlayout7:addlabel("<b>OTHR</b>").
    set tower7label4:style:wordwrap to false.
    set tower7label4:style:vstretch to true.
    set tower7label4:style:fontsize to 16.
    set tower7label4:style:align to "LEFT".
    set tower7label4:style:width to 45.
    set tower7label4:tooltip to "Additional Orbital Launch Mount Controls".
    set tower7label4:style:bg to "starship_img/tower_page_background".
    set tower7label4:style:overflow:top to 35.
    set tower7label4:style:overflow:bottom to 3.
    set tower7label4:style:overflow:right to 110.
    set tower7label4:style:overflow:left to -100.

local tower8button2 is towerstackvlayout8:addbutton("<b>BO</b>").
    set tower8button2:style:margin:top to 8.
    set tower8button2:style:margin:left to 0.
    set tower8button2:style:width to 35.
    set tower8button2:style:height to 25.
    set tower8button2:style:fontsize to 12.
    set tower8button2:tooltip to "Mechazilla Pushers Setting for carrying a Booster. <color=red><b>DO NOT USE FOR SHIP</b></color>".

local tower9button2 is towerstackvlayout9:addbutton("<b>SHIP</b>").
    set tower9button2:style:margin:top to 8.
    set tower9button2:style:margin:left to 0.
    set tower9button2:style:width to 35.
    set tower9button2:style:height to 25.
    set tower9button2:style:fontsize to 12.
    set tower9button2:tooltip to "Mechazilla Pushers Setting for carrying a Ship".

local tower10button2 is towerstackvlayout10:addbutton("<b>OPEN</b>").
    set tower10button2:style:margin:top to 8.
    set tower10button2:style:margin:left to 0.
    set tower10button2:style:width to 50.
    set tower10button2:style:height to 25.
    set tower10button2:style:fontsize to 12.
    set tower10button2:tooltip to "Mechazilla Pushers Open Setting".

local tower11button2 is towerstackvlayout11:addbutton("<b><</b>").
    set tower11button2:style:margin:top to 8.
    set tower11button2:style:margin:left to 0.
    set tower11button2:style:width to 50.
    set tower11button2:style:height to 25.
    set tower11button2:style:fontsize to 15.
    set tower11button2:tooltip to "Move Ship Closer to Tower".
local tower11button3 is towerstackvlayout11:addbutton("<b>STOW</b>").
    set tower11button3:style:margin:top to 12.
    set tower11button3:style:margin:left to 0.
    set tower11button3:style:width to 50.
    set tower11button3:style:height to 25.
    set tower11button3:style:fontsize to 12.
    set tower11button3:tooltip to "Disengage Mechazilla Stabilizers".
local tower11button4 is towerstackvlayout11:addbutton("<b>FUEL</b>").
    set tower11button4:style:margin:top to 12.
    set tower11button4:style:margin:left to 0.
    set tower11button4:style:width to 50.
    set tower11button4:style:height to 25.
    set tower11button4:style:align to "CENTER".
    set tower11button4:style:fontsize to 14.
    set tower11button4:tooltip to "Toggle Refueling".

local tower12label2 is towerstackvlayout12:addlabel("<b>0*</b>").
    set tower12label2:style:wordwrap to false.
    set tower12label2:style:vstretch to true.
    set tower12label2:style:fontsize to 15.
    set tower12label2:style:align to "CENTER".
    set tower12label2:style:width to 65.
    set tower12label2:tooltip to "Mechazilla Pushers current/desired FWD/AFT movement".
local tower12label3 is towerstackvlayout12:addlabel("<b>0*</b>").
    set tower12label3:style:wordwrap to false.
    set tower12label3:style:vstretch to true.
    set tower12label3:style:fontsize to 14.
    set tower12label3:style:align to "CENTER".
    set tower12label3:style:width to 65.
    set tower12label3:tooltip to "Mechazilla Stabilizers Status".
local tower12label4 is towerstackvlayout12:addlabel("<b></b>").
    set tower12label4:style:wordwrap to false.
    set tower12label4:style:vstretch to true.
    set tower12label4:style:fontsize to 14.
    set tower12label4:style:align to "CENTER".
    set tower12label4:style:width to 65.

local tower13button2 is towerstackvlayout13:addbutton("<b>></b>").
    set tower13button2:style:margin:top to 8.
    set tower13button2:style:margin:left to 0.
    set tower13button2:style:width to 50.
    set tower13button2:style:height to 25.
    set tower13button2:style:fontsize to 15.
    set tower13button2:tooltip to "Move Ship further away from Tower".
local tower13button3 is towerstackvlayout13:addbutton("<b>ACT.</b>").
    set tower13button3:style:margin:top to 12.
    set tower13button3:style:margin:left to 0.
    set tower13button3:style:width to 50.
    set tower13button3:style:height to 25.
    set tower13button3:style:fontsize to 12.
    set tower13button3:tooltip to "Engage Mechazilla Stabilizers".
local tower13button4 is towerstackvlayout13:addbutton("<b><color=red>STOP!</color></b>").
    set tower13button4:style:margin:top to 12.
    set tower13button4:style:margin:left to 0.
    set tower13button4:style:width to 50.
    set tower13button4:style:height to 25.
    set tower13button4:style:align to "CENTER".
    set tower13button4:style:fontsize to 14.
    set tower13button4:tooltip to "Activate EMERGENCY STOP! Stops all tower movement..".

set tower2button2:onclick to {
    if towerrot = -52 {}
    else {
        if towerrot > 8 {
            set towerrot to 8.
        }
        else {
            set towerrot to - 52.
        }
        if OnOrbitalMount {
            if towerang = 0 {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
            }
            else {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
            }
        }
        else {
            if towerang = 0 {
                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
            }
        }
    }
}.

set tower3button2:onclick to {
    if towerrot = -52 {}
    else {
        set towerrot to towerrot - 1.
        if OnOrbitalMount {
            if towerang = 0 {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
            }
            else {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
            }
        }
        else {
            if towerang = 0 {
                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
            }
        }
    }
}.

set tower5button2:onclick to {
    if towerrot = 52 {}
    else {
        set towerrot to towerrot + 1.
        if OnOrbitalMount {
            if towerang = 0 {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
            }
            else {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
            }
        }
        else {
            if towerang = 0 {
                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
            }
        }
    }
}.

set tower6button2:onclick to {
    if towerrot = 52 {}
    else {
        if towerrot < 8 {
            set towerrot to 8.
        }
        else {
            set towerrot to 52.
        }
        if OnOrbitalMount {
            if towerang = 0 {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
            }
            else {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
            }
        }
        else {
            if towerang = 0 {
                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
            }
        }
    }
}.


set tower2button3:onclick to {
    if towerang = 5 {
        set towerang to 0.
        if OnOrbitalMount {
            sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
        }
        else {
            sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",false")).
        }
    }
    else if towerang = 0 {}
    else {
        set towerang to 5.
        if OnOrbitalMount {
            sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
        }
        else {
            sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
        }
    }
}.

set tower3button3:onclick to {
    if towerang = 0 {}
    else if towerang = 5 {}
    else {
        set towerang to towerang - 1.
        if OnOrbitalMount {
            sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
        }
        else {
            sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
        }
    }
}.

set tower5button3:onclick to {
    if towerang = 0 {
        set towerang to 4.
    }
    if towerang = 95 {}
    else {
        set towerang to towerang + 1.
        if OnOrbitalMount {
            sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
        }
        else {
            sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
        }
    }
}.

set tower6button3:onclick to {
    if towerang = 95 {}
    else {
        set towerang to 95.
        if OnOrbitalMount {
            sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
        }
        else {
            sendMessage(Vessel(TargetOLM), ("MechazillaArms," + towerrot:tostring + ",1.0," + towerang:tostring + ",true")).
        }
    }
}.


set tower2button4:onclick to {
    if towerhgt = 0 {}
    else {
        set towerhgt to 0.
        if OnOrbitalMount {
            if RSS {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + (104 - towerhgt):tostring + ",0.8")).
            }
            else {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + (65 - towerhgt):tostring + ",0.8")).
            }
        }
        else {
            if RSS {
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (104 - towerhgt):tostring + ",0.8")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (65 - towerhgt):tostring + ",0.8")).
            }
        }
    }
}.

set tower3button4:onclick to {
    if towerhgt = 0 {}
    else {
        set towerhgt to towerhgt - 1.
        if OnOrbitalMount {
            if RSS {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + (104 - towerhgt):tostring + ",0.8")).
            }
            else {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + (65 - towerhgt):tostring + ",0.8")).
            }
        }
        else {
            if RSS {
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (104 - towerhgt):tostring + ",0.8")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (65 - towerhgt):tostring + ",0.8")).
            }
        }
    }
}.

set tower5button4:onclick to {
    if RSS {
        if towerhgt = 104 {}
        else {
            set towerhgt to towerhgt + 1.
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + (104 - towerhgt):tostring + ",0.8")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (104 - towerhgt):tostring + ",0.8")).
            }
        }
    }
    else {
        if towerhgt = 65 {}
        else {
            set towerhgt to towerhgt + 1.
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + (65 - towerhgt):tostring + ",0.8")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (65 - towerhgt):tostring + ",0.5")).
            }
        }
    }
}.

set tower6button4:onclick to {
    if RSS {
        if towerhgt = 104 {}
        else {
            set towerhgt to 104.
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + (104 - towerhgt):tostring + ",0.8")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (104 - towerhgt):tostring + ",0.8")).
            }
        }
    }
    else {
        if towerhgt = 65 {}
        else {
            set towerhgt to 65.
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + (65 - towerhgt):tostring + ",0.8")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (65 - towerhgt):tostring + ",0.8")).
            }
        }
    }
}.


set tower8button2:onclick to {
    set towerpush to BoosterMinPusherDistance.
    if OnOrbitalMount {
        sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
    }
    else {
        sendMessage(Vessel(TargetOLM), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
    }
}.
set tower9button2:onclick to {
    set towerpush to ShipMinPusherDistance.
    if OnOrbitalMount {
        sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
    }
    else {
        sendMessage(Vessel(TargetOLM), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
    }
}.
set tower10button2:onclick to {
    if RSS {
        set towerpush to 20.
    }
    else {
        set towerpush to 12.5.
    }
    if OnOrbitalMount {
        sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",true")).
    }
    else {
        sendMessage(Vessel(TargetOLM), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",true")).
    }
}.
set tower11button2:onclick to {
    if RSS {
        if towerpushfwd < -9.5 {}
        else {
            set towerpushfwd to towerpushfwd - 0.25.
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
            }
        }
    }
    else {
        if towerpushfwd = -6 {}
        else {
            set towerpushfwd to towerpushfwd - 0.25.
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
            }
        }
    }
}.
set tower13button2:onclick to {
    if RSS {
        if towerpushfwd > 9.5 {}
        else {
            set towerpushfwd to towerpushfwd + 0.25.
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
            }
        }
    }
    else {
        if towerpushfwd = 6 {}
        else {
            set towerpushfwd to towerpushfwd + 0.25.
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
            }
            else {
                sendMessage(Vessel(TargetOLM), ("MechazillaPushers," + towerpushfwd:tostring + ",0.2," + towerpush:tostring + ",false")).
            }
        }
    }
}.


set tower11button3:onclick to {
    if towerstab = 0 {}
    else {
        set towerstab to 0.
        if OnOrbitalMount {
            sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaStabilizers,0").
        }
        else {
            sendMessage(Vessel(TargetOLM), ("MechazillaStabilizers,0")).
        }
    }
}.

set tower13button3:onclick to {
    if towerstab = maxstabengage {}
    else {
        set towerstab to maxstabengage.
        if OnOrbitalMount {
            sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaStabilizers," + maxstabengage)).
        }
        else {
            sendMessage(Vessel(TargetOLM), ("MechazillaStabilizers," + maxstabengage)).
        }
    }
}.

set tower11button4:onclick to {
    Refuel().
}.

set tower13button4:onclick to {
    FindParts().
    if OnOrbitalMount {
        sendMessage(Processor(volume("OrbitalLaunchMount")), "EmergencyStop").
    }
    else {
        sendMessage(Vessel(TargetOLM), "EmergencyStop").
    }
}.


local maneuverstackhlayout to maneuverstack:addhlayout().
    set maneuverstackhlayout:style:bg to "starship_img/starship_main_square_bg".
local maneuverstackvlayout1 is maneuverstackhlayout:addvlayout().
    set maneuverstackvlayout1:style:vstretch to true.
local maneuverstackvlayout2 is maneuverstackhlayout:addvlayout().
local maneuverstackvlayout3 is maneuverstackhlayout:addvlayout().

local maneuver1label1 is maneuverstackvlayout1:addlabel("<b>Selected Maneuver:</b>").
    set maneuver1label1:style:wordwrap to false.
    set maneuver1label1:style:margin:top to 5.
    set maneuver1label1:style:margin:left to 10.
    set maneuver1label1:style:fontsize to 18.
    set maneuver1label1:style:width to 200.
    set maneuver1label1:style:height to 35.
    set maneuver1label1:style:align to "LEFT".
    set maneuver1label1:tooltip to "Select a Maneuver in the next window to start".
local ManeuverPicker is maneuverstackvlayout2:addpopupmenu().
    set ManeuverPicker:style:textcolor to white.
    set ManeuverPicker:style:fontsize to 18.
    set ManeuverPicker:style:margin:top to 5.
    set ManeuverPicker:style:width to 175.
    set ManeuverPicker:style:height to 35.
    set ManeuverPicker:style:border:v to 10.
    set ManeuverPicker:style:border:h to 10.
    set ManeuverPicker:style:bg to "starship_img/starship_background".
    set ManeuverPicker:style:normal:bg to "starship_img/starship_background".
    set ManeuverPicker:style:on:bg to "starship_img/starship_background_light".
    set ManeuverPicker:style:hover:bg to "starship_img/starship_background_light".
    set ManeuverPicker:style:hover_on:bg to "starship_img/starship_background_light".
    set ManeuverPicker:style:active:bg to "starship_img/starship_background_light".
    set ManeuverPicker:style:active_on:bg to "starship_img/starship_background_light".
    set ManeuverPicker:style:focused:bg to "starship_img/starship_background_light".
    set ManeuverPicker:style:focused_on:bg to "starship_img/starship_background_light".
    if ShipType = "Depot" {
        set ManeuverPicker:options to list("<color=grey><b>Select Maneuver</b></color>",
        "<b><color=grey>Auto-Dock</color></b>",
        "<b><color=white>Circularize at Pe</color></b>",
        "<b><color=white>Circularize at Ap</color></b>",
        "<b><color=white>Execute Burn</color></b>",
        "<b><color=white>Align Planes</color></b>").
    }
    else {
        set ManeuverPicker:options to list("<color=grey><b>Select Maneuver</b></color>",
        "<b><color=white>Auto-Dock</color></b>",
        "<b><color=white>Circularize at Pe</color></b>",
        "<b><color=white>Circularize at Ap</color></b>",
        "<b><color=white>Execute Burn</color></b>",
        "<b><color=white>Align Planes</color></b>").
    }
    set ManeuverPicker:tooltip to "Select a Maneuver here:  e.g.  docking, circularizing, performing a burn".
local maneuver3button is maneuverstackvlayout3:addbutton("<b>CREATE</b>").
    set maneuver3button:style:margin:top to 5.
    set maneuver3button:style:margin:left to 50.
    set maneuver3button:style:width to 100.
    set maneuver3button:style:height to 35.
    set maneuver3button:style:fontsize to 18.
    set maneuver3button:tooltip to "Create / Start / Execute Maneuver".
set maneuver3button:enabled to false.

local maneuver2label1 is maneuverstackvlayout1:addlabel("").
    set maneuver2label1:style:wordwrap to false.
    set maneuver2label1:style:fontsize to 18.
    set maneuver2label1:style:margin:left to 10.
    set maneuver2label1:style:width to 200.
    set maneuver2label1:style:height to 30.
    set maneuver2label1:style:align to "LEFT".
    set maneuver2label1:tooltip to "Select a Target for Auto-Docking (needs to be within 10km distance)".
local maneuver2label2 is maneuverstackvlayout2:addlabel("").
    set maneuver2label2:style:wordwrap to false.
    set maneuver2label2:style:fontsize to 18.
    set maneuver2label2:style:width to 200.
    set maneuver2label2:style:height to 30.
    set maneuver2label2:style:align to "LEFT".
    set maneuver2label2:tooltip to "".
local TargetPicker is maneuverstackvlayout2:addpopupmenu().
    set TargetPicker:style:textcolor to white.
    set TargetPicker:style:fontsize to 12.
    set TargetPicker:style:width to 175.
    set TargetPicker:style:height to 30.
    set TargetPicker:style:border:v to 10.
    set TargetPicker:style:border:h to 10.
    set TargetPicker:style:bg to "starship_img/starship_background".
    set TargetPicker:style:normal:bg to "starship_img/starship_background".
    set TargetPicker:style:on:bg to "starship_img/starship_background_light".
    set TargetPicker:style:hover:bg to "starship_img/starship_background_light".
    set TargetPicker:style:hover_on:bg to "starship_img/starship_background_light".
    set TargetPicker:style:active:bg to "starship_img/starship_background_light".
    set TargetPicker:style:active_on:bg to "starship_img/starship_background_light".
    set TargetPicker:style:focused:bg to "starship_img/starship_background_light".
    set TargetPicker:style:focused_on:bg to "starship_img/starship_background_light".
    set TargetPicker:options to list("<color=grey><b>Select Target</b></color>").
    set TargetPicker:tooltip to "Select a Target here (targets are checked every 5 seconds)".
TargetPicker:hide().
local maneuver2textfield2 is maneuverstackvlayout2:addtextfield("75").
    set maneuver2textfield2:style:width to 175.
    set maneuver2textfield2:style:height to 30.
    set maneuver2textfield2:tooltip to "".
maneuver2textfield2:hide().
local maneuver2label3 is maneuverstackvlayout3:addlabel("").
    set maneuver2label3:style:wordwrap to false.
    set maneuver2label3:style:fontsize to 18.
    set maneuver2label3:style:width to 175.
    set maneuver2label3:style:height to 30.
    set maneuver2label3:style:align to "LEFT".
    set maneuver2label3:tooltip to "".

local maneuver3label1 is maneuverstackvlayout1:addlabel("").
    set maneuver3label1:style:wordwrap to false.
    set maneuver3label1:style:fontsize to 18.
    set maneuver3label1:style:margin:left to 10.
    set maneuver3label1:style:width to 200.
    set maneuver3label1:style:height to 30.
    set maneuver3label1:style:align to "LEFT".
    set maneuver3label1:tooltip to "".
local maneuver3label2 is maneuverstackvlayout2:addlabel("").
    set maneuver3label2:style:wordwrap to false.
    set maneuver3label2:style:fontsize to 18.
    set maneuver3label2:style:width to 200.
    set maneuver3label2:style:height to 30.
    set maneuver3label2:style:align to "LEFT".
    set maneuver3label2:tooltip to "".
local maneuver3label3 is maneuverstackvlayout3:addlabel("").
    set maneuver3label3:style:wordwrap to false.
    set maneuver3label3:style:fontsize to 18.
    set maneuver3label3:style:width to 175.
    set maneuver3label3:style:height to 30.
    set maneuver3label3:style:align to "LEFT".
    set maneuver3label3:tooltip to "".


set ManeuverPicker:onchange to {
    parameter choice.
    if choice = "<color=grey><b>Select Maneuver</b></color>" {
        set maneuver2label1:text to "".
        set maneuver3label1:text to "".
        set maneuver3label2:text to "".
        set maneuver3label3:text to "".
        set maneuver3button:text to "<b>CREATE</b>".
        set maneuver3button:enabled to false.
        maneuver2textfield2:hide().
        TargetPicker:hide().
        maneuver2label2:show().
    }
    if choice = "<b><color=white>Auto-Dock</color></b>" {
        set maneuver3label1:text to "".
        set maneuver3label2:text to "".
        set maneuver3label3:text to "".
        set maneuver2label1:text to "<b>Select Target (<10km):</b>".
        set maneuver3button:text to "<b>START</b>".
        set maneuver3button:enabled to true.
        maneuver2label2:hide().
        maneuver2textfield2:hide().
        TargetPicker:show().
    }
    if choice = "<b><color=grey>Auto-Dock</color></b>" {
        set maneuver3label1:text to "<b><color=grey>Auto-docking is disabled for Depot (due to low RCS capability)..</color></b>".
        set maneuver3label2:text to "".
        set maneuver3label3:text to "".
        //set maneuver2label1:text to "<b>Select Target (<10km):</b>".
        //set maneuver3button:text to "<b>START</b>".
        //set maneuver3button:enabled to true.
        //maneuver2label2:hide().
        //maneuver2textfield2:hide().
        //TargetPicker:show().
    }
    if choice = "<b><color=white>Circularize at Pe</color></b>" {
        set maneuver2label1:text to "".
        set maneuver3label1:text to "".
        set maneuver3label2:text to "".
        set maneuver3label3:text to "".
        set maneuver3button:text to "<b>CREATE</b>".
        set maneuver3button:enabled to true.
        maneuver2textfield2:hide().
        TargetPicker:hide().
        maneuver2label2:show().
    }
    if choice = "<b><color=white>Circularize at Ap</color></b>" {
        set maneuver2label1:text to "".
        set maneuver3label1:text to "".
        set maneuver3label2:text to "".
        set maneuver3label3:text to "".
        set maneuver3button:text to "<b>CREATE</b>".
        set maneuver3button:enabled to true.
        maneuver2textfield2:hide().
        TargetPicker:hide().
        maneuver2label2:show().
    }
    if choice = "<b><color=white>Execute Burn</color></b>" {
        if hasnode {
            if nextnode:deltav:mag > rcsRaptorBoundary {
                set maneuver2label1:text to "<b>Burn @:  </b><color=yellow>" + timestamp(nextnode:time):full + "</color>           <b>Thrust:  </b><color=magenta>VAC Engines</color>".
                set MaxAccel to (VACEngines[0]:possiblethrust * NrOfVacEngines) / ship:mass.
            }
            else {
                set maneuver2label1:text to "<b>Burn @:  </b><color=yellow>" + timestamp(nextnode:time):full + "</color>           <b>Thrust:  </b><color=magenta>RCS Thrusters</color>".
                if RSS {
                    set MaxAccel to 100/ship:mass.
                }
                else {
                    set MaxAccel to 40/ship:mass.
                }
            }
            set BurnAccel to min(29.62, MaxAccel).
            set BurnDuration to nextnode:deltav:mag / BurnAccel.
            set maneuver3label1:text to "<b>ΔV:  </b><color=yellow>" + round(nextnode:deltav:mag, 1) + "m/s</color>           Burn Duration:  <color=yellow>" + timeSpanCalculator(BurnDuration) + "</color>".
            set maneuver3label2:text to "".
            set maneuver3label3:text to "".
        }
        else {
            set maneuver2label1:text to "".
            set maneuver3label1:text to "".
            set maneuver3label2:text to "".
            set maneuver3label3:text to "".
        }
        set maneuver3button:text to "<b>EXECUTE</b>".
        set maneuver3button:enabled to true.
        maneuver2textfield2:hide().
        TargetPicker:hide().
        maneuver2label2:show().
    }
    if choice = "<b><color=white>Align Planes</color></b>" {
        set maneuver2label1:text to "".
        set maneuver3label1:text to "".
        set maneuver3label2:text to "".
        set maneuver3label3:text to "".
        set maneuver3button:text to "<b>CREATE</b>".
        set maneuver3button:enabled to true.
        maneuver2textfield2:hide().
        TargetPicker:hide().
        maneuver2label2:show().
    }
}.


set TargetPicker:onchange to {
    parameter choice.
    if choice = "<color=grey><b>Select Target</b></color>" {
        set maneuver3label1:text to "".
        set maneuver3label2:text to "".
        set maneuver3label3:text to "".
        set TargetSelected to false.
    }
    else {
        if KUniverse:activevessel = vessel(ship:name) {}
        else {
            ShipsInOrbit().
            set KUniverse:activevessel to vessel(ship:name).
        }
        set target to Vessel(choice).
        set TargetSelected to true.
    }
}.

set maneuver3button:onclick to {
    if not AutodockingIsRunning {
        Droppriority().
        if ManeuverPicker:text = "<color=grey><b>Select Maneuver</b></color>" {

        }
        if ManeuverPicker:text = "<b><color=white>Auto-Dock</color></b>" {
            if TargetPicker:text = "" or TargetPicker:text = "<color=grey><b>Select Target</b></color>" {}
            else {
                AutoDocking().
            }
        }
        if ManeuverPicker:text = "<b><color=white>Circularize at Pe</color></b>" {
            set PerformingManeuver to true.
            set launchlabel:style:textcolor to grey.
            set landlabel:style:textcolor to grey.
            if eta:periapsis > 0 {
                if hasnode {
                    remove nextnode.
                    wait 0.001.
                }
                set OrbitalVelocity to ship:body:radius * sqrt(Planet1G / (ship:body:radius + periapsis)).
                set ProgradeVelocity to OrbitalVelocity - velocityat(ship, time:seconds + eta:periapsis):orbit:mag.
                if not (KUniverse:activevessel = vessel(ship:name)) {
                    set KUniverse:activevessel to vessel(ship:name).
                }
                PerformBurn(eta:periapsis, ProgradeVelocity, 0, 0, "Circ").
            }
            else {
                ShowHomePage().
                set message1:text to "<b><color=yellow>Can't circularize when escaping..</color></b>".
                set textbox:style:bg to "starship_img/starship_main_square_bg".
                wait 3.
                set message1:text to "".
            }
            set PerformingManeuver to false.
        }
        if ManeuverPicker:text = "<b><color=white>Circularize at Ap</color></b>" {
            set PerformingManeuver to true.
            set launchlabel:style:textcolor to grey.
            set landlabel:style:textcolor to grey.
            if apoapsis > 0 {
                if hasnode {
                    remove nextnode.
                    wait 0.001.
                }
                set OrbitalVelocity to ship:body:radius * sqrt(Planet1G / (ship:body:radius + apoapsis)).
                set ProgradeVelocity to OrbitalVelocity - velocityat(ship, time:seconds + eta:apoapsis):orbit:mag.
                if not (KUniverse:activevessel = vessel(ship:name)) {
                    set KUniverse:activevessel to vessel(ship:name).
                }
                PerformBurn(eta:apoapsis, ProgradeVelocity, 0, 0, "Circ").
            }
            else {
                ShowHomePage().
                set message1:text to "<b><color=yellow>Can't circularize when escaping..</color></b>".
                set textbox:style:bg to "starship_img/starship_main_square_bg".
                wait 3.
                set message1:text to "".
            }
            set PerformingManeuver to false.
        }
        if ManeuverPicker:text = "<b><color=white>Execute Burn</color></b>" {
            set PerformingManeuver to true.
            set launchlabel:style:textcolor to grey.
            set landlabel:style:textcolor to grey.
            if hasnode {
                if not (KUniverse:activevessel = vessel(ship:name)) {
                    set KUniverse:activevessel to vessel(ship:name).
                }
                PerformBurn(nextnode:eta, nextnode:prograde, nextnode:normal, nextnode:radialout, "Execute").
            }
            else {
                ShowHomePage().
                set message1:text to "<b><color=yellow>No Maneuver Node found..</color></b>".
                set textbox:style:bg to "starship_img/starship_main_square_bg".
                wait 3.
                set message1:text to "".
            }
            set PerformingManeuver to false.
        }
        if ManeuverPicker:text = "<b><color=white>Align Planes</color></b>" {
            set PerformingManeuver to true.
            set launchlabel:style:textcolor to grey.
            set landlabel:style:textcolor to grey.

            if hasnode {
                remove nextnode.
                wait 0.001.
            }

            if not (hastarget) {
                ShowHomePage().
                set message1:text to "<b><color=yellow>Select a Target first..</color></b>".
                set textbox:style:bg to "starship_img/starship_main_square_bg".
                wait 3.
                set message1:text to "".
                return.
            }

            set AscNode to relative_asc_node(ship:orbit, target:orbit).
            //set AscNodeDraw to vecdraw(AscNode, AscNode, green, "AN", 20, true, 0.005, true, true).

            set DegreesToAN to vang(AscNode, body:position - ship:position).
            if vdot(velocity:orbit, AscNode) > 0 {
                set DegreesToAN to 360 - DegreesToAN.
            }
            set TimeToAN to DegreesToAN / 360 * ship:orbit:period.
            if TimeToAN < 0.5 * ship:orbit:period {
                set TimeToDN to TimeToAN + 0.5 * ship:orbit:period.
            }
            else {
                set TimeToDN to TimeToAN - 0.5 * ship:orbit:period.
            }

            //print "Degrees to AN: " + DegreesToAN.
            //print "Time to AN: " + TimeToAN.
            //print "Time to DN: " + TimeToDN.

            if TimeToDN < TimeToAN {
                set TimeToNode to TimeToDN.
                set WhichNode to -1.
            }
            else {
                set TimeToNode to TimeToAN.
                set WhichNode to 1.
            }

            set NormalVelocity to 0.
            set RelInc to 90.
            set LastRelInc to RelInc.
            until RelInc > LastRelInc {
                set LastRelInc to RelInc.
                //print "last: " + LastRelInc.
                set burn to node(time:seconds + TimeToNode, 0, NormalVelocity, 0).
                add burn.
                set RelInc to relative_inc(orbitat(ship, time:seconds + TimeToNode + 30), target:orbit).
                //print "Relative Inclination: " + RelInc.
                set NormalVelocity to NormalVelocity - WhichNode * 5 * RelInc.
                remove burn.
            }
            //print "Normal Velocity: " + NormalVelocity.

            if not (KUniverse:activevessel = vessel(ship:name)) {
                set KUniverse:activevessel to vessel(ship:name).
            }
            PerformBurn(timestamp(time:seconds + TimeToNode), 0, NormalVelocity, 0, "Align").

            set PerformingManeuver to false.
        }
    }
}.



local statusbar is box_all:addhlayout().
    set statusbar:style:margin:h to 0.
    set statusbar:style:height to 35.
local tooltip is statusbar:addtipdisplay().
    set tooltip:style:wordwrap to false.
    set tooltip:style:hstretch to false.
    set tooltip:style:vstretch to true.
    set tooltip:style:fontsize to 13.
    set tooltip:style:textcolor to rgb(0.75, 0.75, 0.75).
    set tooltip:style:margin:left to 10.
    set tooltip:style:width to 1.
local status1 is statusbar:addlabel().
    set status1:style:wordwrap to false.
    set status1:style:vstretch to true.
    set status1:style:margin:left to 10.
    set status1:style:fontsize to 16.
local statusstretch1 is statusbar:addlabel().
    set statusstretch1:style:hstretch to true.
local status2 is statusbar:addlabel().
    set status2:style:wordwrap to false.
    set status2:style:vstretch to true.
    set status2:style:fontsize to 16.
    set status2:style:align to "CENTER".
local statusstretch2 is statusbar:addlabel().
    set statusstretch2:style:hstretch to true.
local status3 is statusbar:addlabel().
    set status3:style:vstretch to true.
    set status3:style:wordwrap to false.
    set status3:style:width to 80.
    set status3:style:border:top to 0.
    set status3:style:border:bottom to 0.
    set status3:style:border:left to 0.
    set status3:style:border:right to 0.
    set status3:style:overflow:top to -3.
    set status3:style:overflow:bottom to -3.
    set status3:style:overflow:left to -60.
    set status3:style:overflow:right to 0.
    set status3:style:fontsize to 16.
    set status3:style:align to "RIGHT".
local execute is statusbar:addbutton("<b>EXECUTE</b>").
    set execute:style:width to 75.
    set execute:style:margin:left to 10.
    set execute:tooltip to "Execute selected Command".

local cancel is statusbar:addbutton("<b>CANCEL</b>").
    set cancel:style:width to 65.
    set cancel:tooltip to "Cancel selected Command".

set execute:onclick to {
    LogToFile("Execute button clicked").
    if not InhibitExecute {
        if LandButtonIsRunning or LaunchButtonIsRunning or PerformingManeuver or AutodockingIsRunning or ClosingIsRunning {
            LogToFile("Executing").
            set executeconfirmed to 1.
            set execute:pressed to false.
        }
    }
}.

set cancel:onclick to {
    LogToFile("Cancel button clicked").
    if not InhibitCancel {
        if LandButtonIsRunning or LaunchButtonIsRunning or AutodockingIsRunning or PerformingManeuver or ClosingIsRunning {
            LogToFile("Cancelling").
            set cancelconfirmed to 1.
            set cancel:pressed to false.
        }
        if ShipIsDocked {
            LogToFile("Undocking").
            Tank:getmodule("ModuleDockingNode"):doevent("undock").
            set TimeSinceDock to 0.
        }
    }
}.

    
set launchbutton:ontoggle to {
    parameter click.
    if not LaunchButtonIsRunning and not LaunchComplete {
        set LaunchButtonIsRunning to true.
        LogToFile("Launch button clicked").
        ShowButtons(0).
        Droppriority().
        set landlabel:style:textcolor to grey.
        set landlabel:style:bg to "starship_img/starship_background".
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        if click {
            if ship:body:atm:exists and Boosterconnected {
                if not (CheckFullTanks()) {
                    ShowHomePage().
                    InhibitButtons(0, 0, 0).
                    set message1:text to "<b><color=red>Error: Not all tanks are full!</color></b> <color=yellow>(launch may fail)</color>".
                    set message2:text to "<b>Refuel before proceeding?</b>".
                    set message3:text to "<b>Start refuelling <color=white>or</color> cancel refuelling?</b>".
                    set message3:style:textcolor to cyan.
                    set execute:text to "<b>REFUEL</b>".
                    if confirm() {
                        set DeltaVCheck to false.
                        set message3:style:textcolor to white.
                        set message3:text to "".
                        set execute:text to "<b>EXECUTE</b>".
                        InhibitButtons(0, 1, 1).
                        Refuel().
                    }
                    else {
                        set message3:style:textcolor to white.
                        set execute:text to "<b>EXECUTE</b>".
                    }
                }
                set runningprogram to "Input".
                set targetap to OriginalTargetAp.
                updateCargoPage().
                if alt:radar < 120 {
                    if vang(ship:facing:topvector, heading(90,0):vector) < 30 or ShipType = "Crew" {
                        set Launch180 to true.
                    }
                    else {
                        set Launch180 to false.
                    }
                    ShipsInOrbit().
                    if BoosterAlreadyExists {
                        LogToFile("Launch cancelled due to other Booster found").
                        set message1:text to "<b>Error: Recover other Boosters first!</b>".
                        set message2:text to "".
                        set message3:text to "".
                        set message1:style:textcolor to yellow.
                        set textbox:style:bg to "starship_img/starship_main_square_bg".
                        wait 3.
                        ClearInterfaceAndSteering().
                        return.
                    }
                    if not (BoosterCorrectVariant) {
                        LogToFile("Launch cancelled due to wrong Booster Type").
                        set message1:text to "<b>Error: Wrong Booster Variant!</b>".
                        set message2:text to "<b>Select Booster 9 Variant..</b>".
                        set message3:text to "".
                        set message1:style:textcolor to yellow.
                        set textbox:style:bg to "starship_img/starship_main_square_bg".
                        wait 3.
                        ClearInterfaceAndSteering().
                        return.
                    }
                    if TowerAlreadyExists {
                        LogToFile("Launch cancelled due to other Tower found").
                        set message1:text to "<b>Error: Recover other Towers first!</b>".
                        set message2:text to "".
                        set message3:text to "".
                        set message1:style:textcolor to yellow.
                        set textbox:style:bg to "starship_img/starship_main_square_bg".
                        wait 3.
                        ClearInterfaceAndSteering().
                        return.
                    }
                    
                    if CargoMass < MaxCargoToOrbit + 1 and cargo1text:text = "Closed" {
                        ShowHomePage().
                        InhibitButtons(0, 0, 0).
                        set LaunchToTargetOrbit to false.
                        set LaunchIntoLAN to false.
                        set SavedInclination to setting3:text.
                        if ShipsInOrbit():length > 0 {
                            set TargetShip to false.
                            until false {
                                for tship in ShipsInOrbit {
                                    if RSS {
                                        set message1:text to "<b>Launch to Intercept Orbit</b>  (± " + ((targetap - 10000) / 1000) + "km, " + round(tship:orbit:inclination, 2) + "°)".
                                    }
                                    else if KSRSS {
                                        set message1:text to "<b>Launch to Intercept Orbit</b>  (± " + ((targetap - 5000) / 1000) + "km, " + round(tship:orbit:inclination, 2) + "°)".
                                    }
                                    else {
                                        set message1:text to "<b>Launch to Intercept Orbit</b>  (± " + ((targetap - 2500) / 1000) + "km, " + round(tship:orbit:inclination, 2) + "°)".
                                    }
                                    set message2:text to "<b>Rendezvous Target:  <size=17><color=green>" + tship:name + "</color></size></b>".
                                    set message3:text to "<b>Confirm <color=white>or</color> Cancel?</b>".
                                    set message3:style:textcolor to cyan.
                                    set execute:text to "<b>CONFIRM</b>".
                                    if confirm() {
                                        set TargetShip to tship.
                                        set setting3:text to round(tship:orbit:inclination, 2) + "°".
                                        break.
                                    }
                                }
                                break.
                            }
                            set execute:text to "<b>LAUNCH</b>".
                        }
                        if hastarget and TargetShip = 0 {
                            set message1:text to "<b>Launch to coplanar orbit</b>  (± " + (targetap / 1000) + "km, " + round(target:orbit:inclination, 2) + "°)".
                            if ship:geoposition:lat > min(target:orbit:inclination, 180 - target:orbit:inclination) {
                                set message2:text to "<b>Target: </b>" + target:name + "   <color=yellow><b>ΔPlane: </b>" + round(ship:geoposition:lat - min(target:orbit:inclination, 180 - target:orbit:inclination), 2) + "°</color>".
                            }
                            else {
                                set message2:text to "<b>Target: </b>" + target:name.
                            }
                            set message3:text to "<b>Confirm <color=white>or</color> Cancel?</b>".
                            set message3:style:textcolor to cyan.
                            set execute:text to "<b>CONFIRM</b>".
                            if confirm() {
                                set LaunchToTargetOrbit to true.
                            }
                        }
                        set IntendedInc to setting3:text:split("°")[0]:toscalar(0).
                        set data to LAZcalc_init(targetap, IntendedInc).
                        if data[0] = abs(IntendedInc) {}
                        else {
                            set message1:text to "<b><color=yellow>Inclination impossible from current latitude..</color></b>".
                            set message2:text to "<b>Setting Inclination to:  </b>" + round(data[0], 1) + "°".
                            set message3:text to "<b>Confirm <color=white>or</color> Cancel?</b>".
                            set message3:style:textcolor to cyan.
                            set execute:text to "<b>CONFIRM</b>".
                            if confirm() {}
                            else {
                                set setting3:text to IntendedInc + "°".
                                set execute:text to "<b>EXECUTE</b>".
                                LogToFile("Launch Function cancelled").
                                ClearInterfaceAndSteering().
                                set setting3:text to SavedInclination.
                                return.
                            }
                        }

                        if oldBooster {   
                            set message1:text to "<b>HSR Jettison after Boostback?</b>".
                            set message2:text to "".
                            set message3:text to "<b><color=green>Confirm</color> <color=white>or</color> <color=red>Deny</color> ?</b>".
                            set execute:text to "<b>CONFIRM</b>".
                            set cancel:text to "<b>DENY</b>".
                            if confirm() {
                                set DeltaVCheck to true.
                                set HSRJet to true.
                            } else {
                                set HSRJet to false.
                                set DeltaVCheck to true.
                            }
                            set message1:text to "".
                            set message2:text to "".
                            set message3:text to "".
                        } else {
                            set HSRJet to true.
                            set DeltaVCheck to true.
                            set message1:text to "".
                            set message2:text to "".
                            set message3:text to "".
                        }
                        if not (TargetShip = 0) {
                            if RSS {
                                set targetap to targetap - 10000.
                            }
                            else if KSRSS {
                                set targetap to targetap - 5000.
                            }
                            else {
                                set targetap to targetap - 2500.
                            }
                            set message1:text to "<b>Launch to Intercept Orbit</b>  (± " + (targetap / 1000) + "km, " + round(TargetShip:orbit:inclination, 2) + "°)".
                            set message2:text to "<b>Target Ship:  <color=green>" + TargetShip:name + "</color></b>".
                        }
                        else if hastarget and LaunchToTargetOrbit {
                            if ship:geoposition:lat > min(target:orbit:inclination, 180 - target:orbit:inclination) {
                                set message1:text to "<b>Launch to Parking Orbit</b>  (± " + (targetap / 1000) + "km, " + round(ship:geoposition:lat, 2) + "°)".
                            }
                            else {
                                set message1:text to "<b>Launch to Parking Orbit</b>  (± " + (targetap / 1000) + "km, " + round(target:orbit:inclination, 2) + "°)".
                            }
                            //set message2:text to "<b>Booster Return to Launch Site</b>".
                        }
                        else {
                            set message1:text to "<b>Launch to Parking Orbit</b>  (± " + (targetap / 1000) + "km, " + round(setting3:text:split("°")[0]:toscalar(0), 2) + "°)".
                            //set message2:text to "<b>Booster Return to Launch Site</b>".
                        }

                        set message3:text to "<b>Launch <color=white>or</color> Cancel?</b>".
                        set message1:style:textcolor to white.
                        set message2:style:textcolor to white.
                        set message3:style:textcolor to cyan.
                        set execute:text to "<b>LAUNCH</b>".
                        set launchlabel:style:textcolor to white.
                        if confirm() {
                            set execute:text to "<b>EXECUTE</b>".
                            LogToFile("Starting Launch Function").
                            sendMessage(processor(volume("Booster")),"Countdown").
                            sendMessage(processor(volume("OrbitalLaunchMount")),"Countdown").
                            set MissionTimer to time:seconds-17.
                            SaveToSettings("Launch Time", time:seconds+17).
                            if TargetShip = 0 and not hastarget {}
                            else if not (TargetShip = 0) {
                                if RSS {
                                    set LaunchTimeSpanInSeconds to 450.
                                    set LaunchDistance to 1450000.
                                }
                                else if KSRSS {
                                    set LaunchTimeSpanInSeconds to 300.
                                    set LaunchDistance to 700000.
                                }
                                else {
                                    set LaunchTimeSpanInSeconds to 250.
                                    set LaunchDistance to 200000.
                                }
                                set target to TargetShip.
                                if abs(TargetShip:orbit:inclination) < 0.5 and stock {
                                    set LongitudeToRendezvous to 360 * (LaunchTimeSpanInSeconds / TargetShip:orbit:period) - 5.
                                    set OrbitalCircumferenceDelta to (((LongitudeToRendezvous / 360) * 471239) / 4241150) * 360 * 0.5.
                                    set LongitudeToRendezvous to LongitudeToRendezvous - OrbitalCircumferenceDelta.

                                    //print "delta Longitude: " + LongitudeToRendezvous.

                                    set IdealLaunchTargetShipsLongitude to ship:geoposition:lng + (LaunchDistance / (1000 * Planet1Degree)) - LongitudeToRendezvous.

                                    //print "Launch when Target passes Longitude: " + IdealLaunchTargetShipsLongitude.

                                    set LaunchToRendezvousLng to mod(IdealLaunchTargetShipsLongitude - TargetShip:geoposition:lng, 360).
                                    if LaunchToRendezvousLng < 0 {
                                        set LaunchToRendezvousLng to 360 + LaunchToRendezvousLng.
                                    }
                                    set LaunchToRendezvousTime to (LaunchToRendezvousLng / 360) * TargetShip:orbit:period.
                                    set LaunchToRendezvousTime to LaunchToRendezvousTime + (LaunchToRendezvousTime + LaunchTimeSpanInSeconds) / body:rotationperiod * TargetShip:orbit:period.

                                    set LaunchTime to time:seconds + LaunchToRendezvousTime - 19.
                                }
                                else {
                                    launchWindow(TargetShip, 0).
                                    if launchWindowList[0] = -1 or launchWindowList[0] = -2 {
                                        ShowHomePage().
                                        if launchWindowList[0] = -1 {
                                            set message1:text to "<b>No close encounters found (31 days)..</b>".
                                            set message2:text to "<b>Try again later..</b>".
                                        }
                                        else {
                                            set message1:text to "<b>Error: Not crossing target plane..</b>".
                                            set message2:text to "".
                                        }
                                        set message3:text to "".
                                        set message1:style:textcolor to yellow.
                                        set message2:style:textcolor to yellow.
                                        set message3:style:textcolor to yellow.
                                        set textbox:style:bg to "starship_img/starship_main_square_bg".
                                        InhibitButtons(0, 1, 1).
                                        wait 3.
                                        ClearInterfaceAndSteering().
                                        set setting3:text to SavedInclination.
                                        return.
                                    }
                                    set LaunchTime to time:seconds + launchWindowList[0] - 19.
                                    set targetincl to launchWindowList[1].
                                    set setting3:text to (round(targetincl, 2) + "°").
                                    print "Launch Time: " + LaunchTime.
                                }
                                InhibitButtons(1, 1, 0).
                                set cancel:text to "<b>ABORT</b>".
                                set cancel:style:textcolor to red.
                                set message3:style:textcolor to white.
                                set runningprogram to "Countdown".
                                until time:seconds > LaunchTime or cancelconfirmed {
                                    TimeWarp(LaunchTime, 0).
                                    set message1:text to "<b>All Systems:              <color=green>GO</color></b>".
                                    set message2:text to "<b>Launch to:                 <size=17><color=green>" + TargetShip:name + "</color></size></b>".
                                    set message3:text to "<b>Time to Ignition:</b>    " + timeSpanCalculator(LaunchTime - time:seconds + 16).
                                    BackGroundUpdate().
                                }
                                if cancelconfirmed or time:seconds > LaunchTime + 5 {
                                    ClearInterfaceAndSteering().
                                    set setting3:text to SavedInclination.
                                    return.
                                }
                            }
                            if hastarget and TargetShip = 0 and LaunchToTargetOrbit {
                                launchWindow(target, 0).
                                if launchWindowList[0] = -1 or launchWindowList[0] = -2 {
                                    ShowHomePage().
                                    if launchWindowList[0] = -1 {
                                        set message1:text to "<b>No close encounters found (31 days)..</b>".
                                        set message2:text to "<b>Try again later..</b>".
                                    }
                                    else {
                                        set message1:text to "<b>Error: Not crossing target plane..</b>".
                                        set message2:text to "<b>Unsetting target..</b>".
                                        set target to "".
                                    }
                                    set message3:text to "".
                                    set message1:style:textcolor to yellow.
                                    set message2:style:textcolor to yellow.
                                    set message3:style:textcolor to yellow.
                                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                                    InhibitButtons(0, 1, 1).
                                    wait 3.
                                    ClearInterfaceAndSteering().
                                    set setting3:text to SavedInclination.
                                    return.
                                }
                                set LaunchTime to time:seconds + launchWindowList[0] - 19.
                                set targetincl to launchWindowList[1].
                                set setting3:text to (round(targetincl, 2) + "°").
                                print "Launch Time: " + LaunchTime.
                                InhibitButtons(1, 1, 0).
                                set cancel:text to "<b>ABORT</b>".
                                set cancel:style:textcolor to red.
                                set message3:style:textcolor to white.
                                set runningprogram to "Countdown".
                                until time:seconds > LaunchTime or cancelconfirmed {
                                    TimeWarp(LaunchTime, 0).
                                    set message1:text to "<b>All Systems:              <color=green>GO</color></b>".
                                    set message2:text to "<b>Launch to:                 <color=green>" + target:name + "</color></b>".
                                    set message3:text to "<b>Time to Ignition:</b>    " + timeSpanCalculator(LaunchTime - time:seconds + 16).
                                    BackGroundUpdate().
                                }
                                if cancelconfirmed or time:seconds > LaunchTime + 5 {
                                    ClearInterfaceAndSteering().
                                    set setting3:text to SavedInclination.
                                    return.
                                }
                            }
                            if cancelconfirmed {
                                ClearInterfaceAndSteering().
                                set setting3:text to SavedInclination.
                                return.
                            }
                            Launch().
                        }
                        else {
                            set execute:text to "<b>EXECUTE</b>".
                            LogToFile("Launch Function cancelled").
                            set setting3:text to SavedInclination.
                            ClearInterfaceAndSteering().
                        }
                    }
                    else {
                        print "cargo fail".
                        ShowHomePage().
                        if CargoMass > MaxCargoToOrbit + 1 {
                            LogToFile("Launch cancelled due to too much Cargo").
                            set message1:text to "<b>Error: Over Max Payload.. </b>(" + round(CargoMass) + " kg)".
                            set message2:text to "<b>Maximum Payload: </b>" + MaxCargoToOrbit + " kg".
                            set message3:text to "<b></b>".
                            print "1".
                        }
                        else if cargo1text:text = "Open" or cargo1text:text = "Moving..." {
                            LogToFile("Launch cancelled due to Cargo Door Open").
                            set message1:text to "<b>Error: Cargo Door still open!</b>".
                            set message2:text to "<b>Please close the Cargo Door and try again.</b>".
                            set message3:text to "<b></b>".
                            print "2".
                        }
                        set message3:text to "<b>Launch cancelled.</b>".
                        set message1:style:textcolor to yellow.
                        set message2:style:textcolor to yellow.
                        set message3:style:textcolor to yellow.
                        set textbox:style:bg to "starship_img/starship_main_square_bg".
                        wait 3.
                        ClearInterfaceAndSteering().
                    }
                }
                else if verticalspeed > 1 and periapsis < 70000 {
                    LogToFile("Starting Launch Function").
                    Launch().
                }
                else {
                    ShowHomePage().
                    LogToFile("Launch cancelled due to conditions not fulfilled").
                    set message1:text to "<b>Error: Conditions not fulfilled..</b>".
                    set message2:text to "<b>Launch cancelled.</b>".
                    set message3:text to "".
                    set message1:style:textcolor to yellow.
                    set message2:style:textcolor to yellow.
                    set message3:style:textcolor to yellow.
                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                    wait 3.
                    ClearInterfaceAndSteering().
                }
            }
            else if airspeed > 10 and periapsis < 0 and verticalspeed > 0 {
                Launch().
            }
            else {
                ShowHomePage().
                LogToFile("Launch cancelled due to conditions not fulfilled").
                if Boosterconnected {
                    set message1:text to "<b>Error: You're not on the right planet..</b>".
                }
                else {
                    set message1:text to "<b>Error: No Booster found..</b>".
                }
                set message2:text to "<b>Launch cancelled.</b>".
                set message3:text to "".
                set message1:style:textcolor to yellow.
                set message2:style:textcolor to yellow.
                set message3:style:textcolor to yellow.
                set textbox:style:bg to "starship_img/starship_main_square_bg".
                wait 3.
                ClearInterfaceAndSteering().
            }
        }
        else {
            LogToFile("Launch button UNclicked").
            ClearInterfaceAndSteering().
        }
    }
}.
    
    
set landbutton:ontoggle to {
    parameter click.
    if not LandButtonIsRunning {
        set config:ipu to 2000.
        if ShipIsDocked {
            ShowHomePage().
            set textbox:style:bg to "starship_img/starship_main_square_bg".
            set message1:text to "<b><color=yellow>Ship is still docked!</color></b>".
            set message2:text to "".
            set message3:text to "".
            wait 3.
            ClearInterfaceAndSteering().
            return.
        }
        set LandButtonIsRunning to true.
        LogToFile("Land button clicked").
        ShowButtons(0).
        ShipsInOrbit().
        Droppriority().
        set message1:style:textcolor to white.
        set message2:style:textcolor to white.
        set message3:style:textcolor to white.
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        if click and not (ShipType = "Expendable") and not (ShipType = "Depot") {
            if ship:body:atm:exists {
                ShowHomePage().
                FindParts().
                SetPlanetData().
                if CargoMass > MaxReEntryCargoThickAtmo and CargoCG < MaxIU and ship:body:atm:sealevelpressure > 0.5 and not (ShipType = "Tanker") or CargoMass > MaxReEntryCargoThinAtmo and ship:body:atm:sealevelpressure < 0.5 and not (ShipType = "Tanker") {
                    ShowHomePage().
                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                    LogToFile("De-Orbit cancelled due to Cargo Overload").
                    set message1:text to "<b>Error: Too much Cargo onboard!</b>".
                    set message2:text to "<b>Current Cargo Mass: </b><color=yellow>" + round(CargoMass) + " kg</color>".
                    if ship:body:atm:sealevelpressure > 0.5 {
                        set message3:text to "<b>Max. Re-Entry Cargo Mass: </b><color=yellow>" + MaxReEntryCargoThickAtmo + "kg</color>".
                    }
                    if ship:body:atm:sealevelpressure < 0.5 {
                        set message3:text to "<b>Max. Re-Entry Cargo Mass: </b><color=yellow>" + MaxReEntryCargoThinAtmo + "kg</color>".
                    }
                    set message1:style:textcolor to yellow.
                    wait 3.
                    ClearInterfaceAndSteering().
                }
                else if CargoCG > MaxIU and CargoMass < MaxReEntryCargoThickAtmo and ship:body:atm:sealevelpressure > 0.5 {
                    ShowHomePage().
                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                    LogToFile("De-Orbit cancelled due to Cargo Center of Gravity").
                    set message1:text to "<b>Error: Center of Gravity too far forward!</b>".
                    set message2:text to "<b>Current Cargo CoG: </b><color=yellow>" + round(CargoCG) + " index units</color>".
                    set message3:text to "<b>Max. Re-Entry Cargo CoG: </b><color=yellow>" + MaxIU + " index units</color>".
                    set message1:style:textcolor to yellow.
                    wait 3.
                    ClearInterfaceAndSteering().
                }
                else if CargoCG > MaxIU and CargoMass > MaxReEntryCargoThickAtmo and ship:body:atm:sealevelpressure > 0.5 {
                    ShowHomePage().
                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                    LogToFile("De-Orbit cancelled due to Cargo Overload").
                    set message1:text to "<b>Error: Too much Cargo onboard!</b>".
                    set message2:text to "<b>Current Cargo: </b><color=yellow>" + round(CargoMass) + " kg & " + round(CargoCG) + " index units</color>".
                    set message3:text to "<b>Max. Re-Entry Cargo: </b><color=yellow>" + MaxReEntryCargoThickAtmo + " kg & " + MaxIU + " i. u.</color>".
                    set message1:style:textcolor to yellow.
                    wait 3.
                    ClearInterfaceAndSteering().
                }
                else if CargoCG > 5 * MaxIU and CargoMass < MaxReEntryCargoThinAtmo and ship:body:atm:sealevelpressure < 0.5 {
                    ShowHomePage().
                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                    LogToFile("De-Orbit cancelled due to Cargo Center of Gravity").
                    set message1:text to "<b>Error: Center of Gravity too far forward!</b>".
                    set message2:text to "<b>Current Cargo CoG: </b><color=yellow>" + round(CargoCG) + " index units</color>".
                    set message3:text to "<b>Max. Re-Entry Cargo CoG: </b><color=yellow>" + 5 * MaxIU + " index units</color>".
                    set message1:style:textcolor to yellow.
                    wait 3.
                    ClearInterfaceAndSteering().
                }
                else if CargoCG > 5 * MaxIU and CargoMass > MaxReEntryCargoThinAtmo and ship:body:atm:sealevelpressure < 0.5 {
                    ShowHomePage().
                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                    LogToFile("De-Orbit cancelled due to Cargo Overload").
                    set message1:text to "<b>Error: Too much Cargo onboard!</b>".
                    set message2:text to "<b>Current Cargo: </b><color=yellow>" + round(CargoMass) + " kg & " + round(CargoCG) + " index units</color>".
                    set message3:text to "<b>Max. Re-Entry Cargo: </b><color=yellow>" + MaxReEntryCargoThinAtmo + " kg & " + 5 * MaxIU + " i. u.</color>".
                    set message1:style:textcolor to yellow.
                    wait 3.
                    ClearInterfaceAndSteering().
                }
                else if cargo1text:text = "Open" {
                    ShowHomePage().
                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                    LogToFile("De-Orbit cancelled due to orbit requirements not fulfilled").
                    set message1:text to "<b>Error: Cargo Door still open!</b>".
                    set message2:text to "<b>Please close the Cargo Door and try again.</b>".
                    set message3:text to "<b></b>".
                    set message1:style:textcolor to yellow.
                    set message2:style:textcolor to yellow.
                    set message3:style:textcolor to yellow.
                    wait 3.
                    ClearInterfaceAndSteering().
                }
                else {
                    if ShipType = "Tanker" and CargoMass > MaxReEntryCargoThickAtmo and ship:body:atm:sealevelpressure > 0.5 or ShipType = "Tanker" and CargoMass > MaxReEntryCargoThinAtmo and ship:body:atm:sealevelpressure < 0.5 {
                        for res in tank:resources {
                            if res:name = "LiquidFuel" {
                                set RepositionLF to TRANSFERALL("LiquidFuel", Nose, Tank).
                                set RepositionLF:ACTIVE to TRUE.
                            }
                            if res:name = "LqdMethane" {
                                set RepositionLF to TRANSFERALL("LqdMethane", Nose, Tank).
                                set RepositionLF:ACTIVE to TRUE.
                            }
                            if res:name = "Oxidizer" {
                                set RepositionOxidizer to TRANSFERALL("Oxidizer", Nose, Tank).
                                set RepositionOxidizer:ACTIVE to TRUE.
                            }
                        }
                        until Nose:mass = Nose:drymass or CargoMass < MaxReEntryCargoThickAtmo and ship:body:atm:sealevelpressure > 0.5 or CargoMass < MaxReEntryCargoThinAtmo and ship:body:atm:sealevelpressure < 0.5 or RepositionOxidizer:STATUS = "Failed" or RepositionOxidizer:STATUS = "Finished" {
                            set message1:text to "<b>Transferring Fuel..</b>".
                            BackGroundUpdate().
                        }
                        set message1:text to "".
                        set CargoMass to ship:mass - ship:drymass.
                        if ShipType = "Tanker" and CargoMass > MaxReEntryCargoThickAtmo and ship:body:atm:sealevelpressure > 0.5 or ShipType = "Tanker" and CargoMass > MaxReEntryCargoThinAtmo and ship:body:atm:sealevelpressure < 0.5 {
                            ShowHomePage().
                            set textbox:style:bg to "starship_img/starship_main_square_bg".
                            LogToFile("De-Orbit cancelled due to Fuel Overload").
                            set message1:text to "<b>Error: Too much Fuel onboard!</b>".
                            set message2:text to "<b>Manually vent some fuel first..</b>".
                            set message1:style:textcolor to yellow.
                            wait 3.
                            ClearInterfaceAndSteering().
                            return.
                        }
                    }
                    set landlabel:style:textcolor to green.
                    set launchlabel:style:textcolor to grey.
                    set launchlabel:style:bg to "starship_img/starship_background".
                    set runningprogram to "Input".
                    if quickattitude2:pressed {
                        set quickattitude1:pressed to true.
                    }
                    if hasnode {
                        LogToFile("Existing Node removed").
                        remove nextnode.
                        wait until not (addons:tr:hasimpact).
                    }
                    if addons:tr:hasimpact {
                        set ErrorVector to ADDONS:TR:IMPACTPOS:POSITION - landingzone:POSITION.
                        LandingZoneFinder().
                        if LZFinderCancelled {
                            ClearInterfaceAndSteering().
                            return.
                        }
                        set LngLatErrorList to LngLatError().
                        if abs(LngLatErrorList[0]) > LongitudinalAcceptanceLimit or abs(LngLatErrorList[1]) > LateralAcceptanceLimit {
                            ShowHomePage().
                            set message1:text to "<b>Landingzone out of Range..   Slope:  </b>" + round(AvailableLandingSpots[3], 1) + "°".
                            set message2:text to "<b>Override Re-Entry?</b> (" + round(LngLatErrorList[0] / 1000, 2) + "km  " + round((LngLatErrorList[1] / 1000), 2) + "km)".
                            set message3:text to "<b>Execute <color=white>or</color> Cancel?</b>".
                            set message1:style:textcolor to yellow.
                            set message2:style:textcolor to yellow.
                            set message3:style:textcolor to cyan.
                            set landlabel:style:textcolor to white.
                            InhibitButtons(0, 0, 0).
                            if confirm() {
                                LogToFile("Starting Re-Entry & Land Function").
                                ReEntryAndLand().
                            }
                            else {
                                LogToFile("Land Function cancelled").
                                ClearInterfaceAndSteering().
                                return.
                            }
                        }
                        else {
                            ShowHomePage().
                            set message1:text to aoa + "° <b>AoA Re-Entry</b>".
                            for var in LaunchSites:keys {
                                if BodyExists("Kerbin") {
                                    if LaunchSites[var] = setting1:text and ship:body = BODY("Kerbin") {
                                        set message2:text to "<b>Landing Zone:</b>  <color=yellow>" + var + "</color>".
                                        break.
                                    }
                                    set message2:text to "<b>Landing Zone:</b>  <color=yellow>" + round(landingzone:lat, 4) + "," + round(landingzone:lng, 4) + "</color>   <b>Slope:</b> <color=yellow>" + round(AvailableLandingSpots[3], 1) + "°</color>".
                                }
                                if BodyExists("Earth") {
                                    if LaunchSites[var] = setting1:text and ship:body = BODY("Earth") {
                                        set message2:text to "<b>Landing Zone:</b>  <color=yellow>" + var + "</color>".
                                        break.
                                    }
                                    set message2:text to "<b>Landing Zone:</b>  <color=yellow>" + round(landingzone:lat, 4) + "," + round(landingzone:lng, 4) + "</color>   <b>Slope:</b> <color=yellow>" + round(AvailableLandingSpots[3], 1) + "°</color>".
                                }
                            }
                            set message1:style:textcolor to white.
                            set message2:style:textcolor to white.
                            set message3:style:textcolor to cyan.
                            set message3:text to "<b>Execute <color=white>or</color> Cancel?</b>".
                            set landlabel:style:textcolor to white.
                            InhibitButtons(0, 0, 0).
                            if confirm() {
                                LogToFile("Starting Re-Entry & Land Function").
                                ReEntryAndLand().
                            }
                            else {
                                LogToFile("Land Function cancelled").
                                ClearInterfaceAndSteering().
                            }
                        }
                    }
                    if not addons:tr:hasimpact and ship:body:atm:exists {
                        if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                            LogToFile("Land Function cancelled due to ship:status").
                            ClearInterfaceAndSteering().
                        }
                        else if ship:orbit:inclination > 60 and ship:orbit:inclination < 120 or ship:orbit:inclination < -60 and ship:orbit:inclination > -120 {
                            ShowHomePage().
                            LogToFile("Automatic De-Orbit burn not possible, inclination too high. Please de-orbit manually..").
                            set message1:text to "<b>Error: Inclination out of limits.. (> ±60°)</b>".
                            set message1:style:textcolor to yellow.
                            set message2:text to "<b>Please perform De-Orbit Burn manually!</b>".
                            set message2:style:textcolor to yellow.
                            set message3:text to "<b>Tip: </b>use Trajectories..".
                            set textbox:style:bg to "starship_img/starship_main_square_bg".
                            wait 3.
                            ClearInterfaceAndSteering().
                            return.
                        }
                        else if RSS and apoapsis > 500000 and ship:body:atm:sealevelpressure > 0.5 or not (RSS) and apoapsis > 250000 and ship:body:atm:sealevelpressure > 0.5 or RSS and apoapsis > 300000 and ship:body:atm:sealevelpressure < 0.5 or not (RSS) and apoapsis > 100000 and ship:body:atm:sealevelpressure < 0.5 or periapsis < ship:body:atm:height or abs(ship:orbit:inclination) + 2.5 < abs(setting1:text:split(",")[0]:toscalar(0)) {
                            ShowHomePage().
                            LogToFile("De-Orbit cancelled due to orbit requirements not fulfilled").
                            set message1:text to "<b>Automatic De-Orbit Requirements:</b>".
                            if ship:body:atm:sealevelpressure > 0.5 {
                                if RSS {
                                    set message2:text to "<b>Ap/Pe " + round(ship:body:atm:height / 1000) + "-500km   LZ latitude < Inclination</b>".
                                }
                                else {
                                    set message2:text to "<b>Ap/Pe " + round(ship:body:atm:height / 1000) + "-250km   LZ latitude < Inclination</b>".
                                }
                            }
                            if ship:body:atm:sealevelpressure < 0.5 {
                                if RSS {
                                    set message2:text to "<b>Ap/Pe " + round(ship:body:atm:height / 1000) + "-300km   LZ latitude < Inclination</b>".
                                }
                                else {
                                    set message2:text to "<b>Ap/Pe " + round(ship:body:atm:height / 1000) + "-100km   LZ latitude < Inclination</b>".
                                }
                            }
                            set message3:text to "<b>Modify orbit or perform manual de-orbit..</b>".
                            set message2:style:textcolor to yellow.
                            set message3:style:textcolor to white.
                            wait 3.
                            ClearInterfaceAndSteering().
                        }
                        else {
                            LandingZoneFinder().
                            if LZFinderCancelled {
                                ClearInterfaceAndSteering().
                                return.
                            }
                            set message1:text to "<b>Automatic De-Orbit & Land at:</b>".
                            for var in LaunchSites:keys {
                                if BodyExists("Kerbin") {
                                    if LaunchSites[var] = setting1:text and ship:body = BODY("Kerbin") {
                                        set message2:text to "<b><color=yellow>" + var + "</color></b>".
                                        break.
                                    }
                                    set message2:text to "<b>Landing Zone:</b>  <color=yellow>" + round(landingzone:lat, 4) + "," + round(landingzone:lng, 4) + "</color>   <b>Slope:</b> <color=yellow>" + round(AvailableLandingSpots[3], 1) + "°</color>".
                                }
                                if BodyExists("Earth") {
                                    if LaunchSites[var] = setting1:text and ship:body = BODY("Earth") {
                                        set message2:text to "<b><color=yellow>" + var + "</color></b>".
                                        break.
                                    }
                                    set message2:text to "<b>Landing Zone:</b>  <color=yellow>" + round(landingzone:lat, 4) + "," + round(landingzone:lng, 4) + "</color>   <b>Slope:</b> <color=yellow>" + round(AvailableLandingSpots[3], 1) + "°</color>".
                                }
                            }
                            set message3:style:textcolor to cyan.
                            set message3:text to "<b>Confirm <color=white>or</color> Cancel?</b>".
                            set execute:text to "<b>CONFIRM</b>".
                            InhibitButtons(0, 0, 0).
                            if confirm() {}
                            else {
                                set execute:text to "<b>EXECUTE</b>".
                                ClearInterfaceAndSteering().
                                set settingsbutton:pressed to true.
                                return.
                            }
                            set execute:text to "<b>EXECUTE</b>".
                            set message3:text to "".

                            if ship:body:atm:sealevelpressure < 0.5 {
                                if RSS {
                                    set MinFuel to 35000 + (CargoMass / 150000 * 200000).
                                    set MaxFuel to MinFuel + CargoMass + 75000.
                                }
                                else if KSRSS {
                                    set MinFuel to max(10000 + (CargoMass / 100000 * 40000), CargoMass - 25000).
                                    set MaxFuel to MinFuel + CargoMass + 25000.
                                }
                                else {
                                    set MinFuel to max(10000 + (CargoMass / 75000 * 15000), CargoMass - 25000).
                                    set MaxFuel to MinFuel + CargoMass + 25000.
                                }
                                print "Min Fuel for safe re-entry: " + round(MinFuel).
                                print "Max Fuel for safe re-entry: " + round(MaxFuel).
                                print "Fuel on board: " + round(LFShip * FuelUnitsToKg).
                                if LFShip * FuelUnitsToKg < MinFuel {
                                    LogToFile("Automatic De-Orbit burn not possible, not enough fuel for a safe re-entry..").
                                    set message1:text to "<b>Error: Not enough Fuel on Board..</b>".
                                    set message1:style:textcolor to yellow.
                                    set message2:text to "<b>Min. Fuel: </b>" + round(MinFuel / 1000, 1) + "t  (<b>FOB: </b>" + round((LFShip * FuelUnitsToKg) / 1000, 1) + "t)".
                                    set message2:style:textcolor to yellow.
                                    set message3:text to "".
                                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                                    wait 3.
                                    ClearInterfaceAndSteering().
                                    return.
                                }
                            }

                            if LFShip > FuelVentCutOffValue and ship:body:atm:sealevelpressure > 0.5 or LFShip * FuelUnitsToKg > MaxFuel and ship:body:atm:sealevelpressure < 0.5 {
                                ShowHomePage().
                                set drainBegin to LFShip.
                                set landlabel:style:textcolor to white.
                                if ship:body:atm:sealevelpressure > 0.5 {
                                    set message1:text to "<b>Required Fuel Venting:</b>  " + timeSpanCalculator((LFShip - FuelVentCutOffValue) / VentRate).
                                    set message2:text to "<b>Max. Fuel Mass: </b>" + round((FuelVentCutOffValue * FuelUnitsToKg) / 1000, 1) + "t  (<b>FOB: </b>" + round((LFShip * FuelUnitsToKg) / 1000, 1) + "t)".
                                }
                                else {
                                    set message1:text to "<b>Required Fuel Venting:</b>  " + timeSpanCalculator((LFShip - MaxFuel / FuelUnitsToKg) / VentRate).
                                    set message2:text to "<b>Max. Fuel Mass: </b>" + round(MaxFuel / 1000, 1) + "t  (<b>FOB: </b>" + round((LFShip * FuelUnitsToKg) / 1000, 1) + "t)".
                                }
                                set message3:text to "<b>Execute <color=white>or</color> Cancel?</b>".
                                set message3:style:textcolor to cyan.
                                InhibitButtons(0, 0, 0).
                                if confirm() {
                                    if KUniverse:activevessel = vessel(ship:name) {}
                                    else {
                                        set KUniverse:activevessel to vessel(ship:name).
                                    }
                                    LogToFile("Start Venting").
                                    set landlabel:style:textcolor to green.
                                    InhibitButtons(0, 1, 0).
                                    sas on.
                                    rcs on.
                                    set runningprogram to "Venting Fuel..".
                                    HideEngineToggles(1).
                                    ToggleHeaderTank(0).
                                    if not Nose:name:contains("SEP.23.SHIP.FLAPS") and not ShipType:contains("Block1") {
                                        Nose:activate.
                                    } else if ShipType:contains("Block1") and not ShipType:contains("Exp") {
                                        HeaderTank:activate.
                                    } else if ShipType:contains("Exp") and ShipType:contains("Block1") {
                                        Nose:activate.
                                    }
                                    Tank:activate.
                                    lock throttle to 0.
                                    set message1:text to "<b>Fuel Vent Progress:</b>".
                                    set message2:text to "".
                                    set message3:text to "".
                                    set message3:style:textcolor to white.
                                    until cancelconfirmed or LFShip < FuelVentCutOffValue and ship:body:atm:sealevelpressure > 0.5 or LFShip * FuelUnitsToKg < MaxFuel and ship:body:atm:sealevelpressure < 0.5 or runningprogram = "Input" {
                                        if not cancelconfirmed {
                                            if KUniverse:activevessel = vessel(ship:name) {}
                                            else {
                                                ShutDownAllEngines().
                                                LogToFile("Stop Venting").
                                                ClearInterfaceAndSteering().
                                                return.
                                            }
                                            if ship:body:atm:sealevelpressure > 0.5 {
                                                set message2:text to round((((drainBegin - FuelVentCutOffValue) - (LFShip - FuelVentCutOffValue)) / (LFcap - (LFcap - drainBegin) - FuelVentCutOffValue)) * 100, 1):tostring + "% Complete".
                                                set message3:text to "<b>Time Remaining:</b> " + timeSpanCalculator((LFShip - FuelVentCutOffValue) / VentRate).
                                            }
                                            else {
                                                set message2:text to round((((drainBegin - MaxFuel / FuelUnitsToKg) - (LFShip - MaxFuel / FuelUnitsToKg)) / (LFcap - (LFcap - drainBegin) - MaxFuel / FuelUnitsToKg)) * 100, 1):tostring + "% Complete".
                                                set message3:text to "<b>Time Remaining:</b> " + timeSpanCalculator((LFShip - MaxFuel / FuelUnitsToKg) / VentRate).
                                            }
                                            BackGroundUpdate().
                                        }
                                    }
                                    ShutDownAllEngines().
                                    ToggleHeaderTank(1).
                                    rcs off.
                                    LogToFile("Stop Venting").
                                    if kuniverse:timewarp:warp > 0 {
                                        set kuniverse:timewarp:warp to 0.
                                        until kuniverse:timewarp:warp = 0 {}
                                        wait 1.
                                    }
                                    HideEngineToggles(0).
                                    set message1:text to "".
                                    set message2:text to "".
                                    set message3:text to "".
                                    if cancelconfirmed {
                                        ShutDownAllEngines().
                                        HideEngineToggles(0).
                                        LogToFile("Venting stopped by user").
                                        set runningprogram to "None".
                                        ClearInterfaceAndSteering().
                                    }
                                }
                                else {
                                    ShutDownAllEngines().
                                    HideEngineToggles(0).
                                    LogToFile("Venting cancelled by user").
                                    ClearInterfaceAndSteering().
                                }
                            }
                            if LFShip < FuelVentCutOffValue + 0.01 and ship:body:atm:sealevelpressure > 0.5 or LFShip * FuelUnitsToKg < MaxFuel + 0.01 and ship:body:atm:sealevelpressure < 0.5 {
                                set runningprogram to "Input".
                                wait 0.1.
                                if KUniverse:activevessel = vessel(ship:name) {}
                                else {
                                    set KUniverse:activevessel to vessel(ship:name).
                                    wait 3.
                                }
                                ShowHomePage().
                                LandingZoneFinder().
                                if LZFinderCancelled {
                                    ClearInterfaceAndSteering().
                                    return.
                                }
                                InhibitButtons(1,1,1).
                                LogToFile("Calculating De-Orbit Burn").
                                set landlabel:style:textcolor to white.
                                set message1:text to "<b>Looking for suitable Re-Entry Trajectory..</b>".
                                set message2:text to "".
                                set message3:text to "".
                                set message1:style:textcolor to white.
                                set message2:style:textcolor to white.
                                set TimeToBurn to CalculateDeOrbitBurn(10).
                                if TimeToBurn = 0 {
                                    set message1:text to "<b>Error: No burn found in the next 31 days..</b>".
                                    set message1:style:textcolor to yellow.
                                    set message2:text to "<b>Try again later..</b>".
                                    set message2:style:textcolor to yellow.
                                    set message3:text to "".
                                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                                    wait 3.
                                    ClearInterfaceAndSteering().
                                    return.
                                }
                                set deorbitburnstarttime to timestamp(time:seconds + TimeToBurn).
                                set ProgradeVelocity to DeOrbitVelocity().
                                if ProgradeVelocity = 0 {
                                    set message1:text to "<b>Error: Not passing overhead the LZ..</b>".
                                    set message1:style:textcolor to yellow.
                                    set message2:text to "<b>Try again later..</b>".
                                    set message2:style:textcolor to yellow.
                                    set message3:text to "".
                                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                                    wait 3.
                                    ClearInterfaceAndSteering().
                                    return.
                                }
                                ShowHomePage().
                                if addons:tr:hasimpact {
                                    if (landingzone:position - addons:tr:impactpos:position):mag > LateralAcceptanceLimit {
                                        LogToFile("Automatic De-Orbit burn not possible, target too far away from estimated impact").
                                        set message1:text to "<b>Error: Impact Position out of tolerances..</b>".
                                        set message1:style:textcolor to yellow.
                                        set message2:text to "<b>De-orbit manually or try again..</b>".
                                        set message2:style:textcolor to yellow.
                                        set message3:text to "".
                                        set textbox:style:bg to "starship_img/starship_main_square_bg".
                                        wait 3.
                                        ClearInterfaceAndSteering().
                                        return.
                                    }.
                                }
                                
                                PerformBurn(deorbitburnstarttime, ProgradeVelocity, 0, 0, "DeOrbit").
                                ReEntryAndLand().
                            }
                        }
                    }
                    else {
                        LogToFile("Land Function Stopped").
                        ClearInterfaceAndSteering().
                    }
                }
            }
            else if not (ship:body:atm:exists) {
                ShowHomePage().
                SetPlanetData().
                if RSS {
                    set MinFuel to 135000 + (CargoMass / 150000 * 95000).
                    set MaxFuel to 900000.
                    if LFShip * FuelUnitsToKg > 600000 {
                        set SafeAltOverLZ to 10000 + (MaxFuel - 600000) / 1000 * 30.
                    }
                }
                else if KSRSS {
                    set MinFuel to 35000 + (CargoMass / 100000 * 40000).
                    set MaxFuel to 135000.
                    if LFShip * FuelUnitsToKg > 90000 {
                        set SafeAltOverLZ to 5000 + (MaxFuel - 90000) / 1000 * 30.
                    }
                }
                else {
                    set MinFuel to 20000 + (CargoMass / 75000 * 42500)..
                    set MaxFuel to 69000.
                    if LFShip * FuelUnitsToKg > 34500 {
                        set SafeAltOverLZ to 2500 + (MaxFuel - 34500) / 1000 * 30.
                    }
                }
                print "Min Fuel for safe landing: " + round(MinFuel).
                print "Max Fuel for safe landing: " + round(MaxFuel).
                print "Fuel on board: " + round(LFShip * FuelUnitsToKg).
                if LFShip * FuelUnitsToKg < MinFuel {
                    LogToFile("Automatic De-Orbit burn not possible, not enough fuel for a safe landing..").
                    set message1:text to "<b>Error: Not enough Fuel on Board..</b>".
                    set message1:style:textcolor to yellow.
                    set message2:text to "<b>Min. Fuel: </b>" + round(MinFuel / 1000, 1) + "t  (<b>FOB: </b>" + round((LFShip * FuelUnitsToKg) / 1000, 1) + "t)".
                    set message2:style:textcolor to yellow.
                    set message3:text to "".
                    set textbox:style:bg to "starship_img/starship_main_square_bg".
                    wait 3.
                    ClearInterfaceAndSteering().
                    return.
                }

                if LFShip * FuelUnitsToKg > MaxFuel {
                    ShowHomePage().
                    set drainBegin to LFShip.
                    set landlabel:style:textcolor to white.
                    set message1:text to "<b>Required Fuel Venting:</b>  " + timeSpanCalculator((LFShip - MaxFuel / FuelUnitsToKg) / VentRate).
                    print LFShip - MaxFuel / FuelUnitsToKg.
                    print (LFShip - MaxFuel / FuelUnitsToKg) / VentRate.
                    set message2:text to "<b>Max. Fuel Mass: </b>" + round(MaxFuel / 1000, 1) + "t  (<b>FOB: </b>" + round((LFShip * FuelUnitsToKg) / 1000, 1) + "t)".
                    set message3:text to "<b>Execute <color=white>or</color> Cancel?</b>".
                    set message3:style:textcolor to cyan.
                    InhibitButtons(0, 0, 0).
                    if confirm() {
                        if KUniverse:activevessel = vessel(ship:name) {}
                        else {
                            set KUniverse:activevessel to vessel(ship:name).
                        }
                        LogToFile("Start Venting").
                        set landlabel:style:textcolor to green.
                        InhibitButtons(0, 1, 0).
                        sas on.
                        rcs on.
                        set runningprogram to "Venting Fuel..".
                        ToggleHeaderTank(0).
                        HideEngineToggles(1).
                        Nose:activate.
                        Tank:activate.
                        lock throttle to 0.
                        set message1:text to "<b>Fuel Vent Progress:</b>".
                        set message2:text to "".
                        set message3:text to "".
                        set message3:style:textcolor to white.
                        until cancelconfirmed or LFShip * FuelUnitsToKg < MaxFuel or runningprogram = "Input" {
                            if not cancelconfirmed {
                                if KUniverse:activevessel = vessel(ship:name) {}
                                else {
                                    ShutDownAllEngines().
                                    LogToFile("Stop Venting").
                                    ClearInterfaceAndSteering().
                                    return.
                                }
                                set message2:text to round((((drainBegin - MaxFuel / FuelUnitsToKg) - (LFShip - MaxFuel / FuelUnitsToKg)) / (LFcap - (LFcap - drainBegin) - MaxFuel / FuelUnitsToKg)) * 100, 1):tostring + "% Complete".
                                set message3:text to "<b>Time Remaining:</b> " + timeSpanCalculator((LFShip - MaxFuel / FuelUnitsToKg) / VentRate).
                                BackGroundUpdate().
                            }
                        }
                        ShutDownAllEngines().
                        ToggleHeaderTank(1).
                        rcs off.
                        if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
                        LogToFile("Stop Venting").
                        HideEngineToggles(0).
                        set message1:text to "".
                        set message2:text to "".
                        set message3:text to "".
                        if cancelconfirmed {
                            ShutDownAllEngines().
                            HideEngineToggles(0).
                            LogToFile("Venting stopped by user").
                            set runningprogram to "None".
                            ClearInterfaceAndSteering().
                        }
                    }
                    else {
                        ShutDownAllEngines().
                        HideEngineToggles(0).
                        LogToFile("Venting cancelled by user").
                        ClearInterfaceAndSteering().
                    }
                }
                if cargo1text:text = "Open" {
                    ShowHomePage().
                    LogToFile("De-Orbit cancelled due to orbit requirements not fulfilled").
                    set message1:text to "<b>Error: Cargo Door still open!</b>".
                    set message2:text to "<b>Please close the Cargo Door and try again.</b>".
                    set message3:text to "<b></b>".
                    set message1:style:textcolor to yellow.
                    set message2:style:textcolor to yellow.
                    set message3:style:textcolor to yellow.
                    wait 3.
                    ClearInterfaceAndSteering().
                }
                else if LFShip * FuelUnitsToKg < MaxFuel {
                    set landlabel:style:textcolor to green.
                    set launchlabel:style:textcolor to grey.
                    set launchlabel:style:bg to "starship_img/starship_background".
                    set runningprogram to "Input".
                    if quickattitude2:pressed {
                        set quickattitude1:pressed to true.
                    }
                    if hasnode {
                        LogToFile("Existing Node removed").
                        remove nextnode.
                        wait 0.1.
                    }
                    if addons:tr:hasimpact {
                        set ErrorVector to ADDONS:TR:IMPACTPOS:POSITION - landingzone:POSITION.
                        LandingZoneFinder().
                        if LZFinderCancelled {
                            ClearInterfaceAndSteering().
                            return.
                        }
                        set LngLatErrorList to LngLatError().
                        if RSS {
                            set LongitudinalAcceptanceLimit to 350000.
                            set LateralAcceptanceLimit to 10000.
                        }
                        else {
                            set LongitudinalAcceptanceLimit to 100000.
                            set LateralAcceptanceLimit to 5000.
                        }
                        if abs(LngLatErrorList[0]) > LongitudinalAcceptanceLimit or abs(LngLatErrorList[1]) > LateralAcceptanceLimit {
                            ShowHomePage().
                            set message1:text to "<b>Landingzone out of Range..   Slope:  </b>" + round(AvailableLandingSpots[3], 1) + "°".
                            set message2:text to "<b>Override Re-Entry?</b> (" + round(LngLatErrorList[0] / 1000, 2) + "km  " + round((LngLatErrorList[1] / 1000), 2) + "km)".
                            set message3:text to "<b>Execute <color=white>or</color> Cancel?</b>".
                            set message1:style:textcolor to yellow.
                            set message2:style:textcolor to yellow.
                            set message3:style:textcolor to cyan.
                            set landlabel:style:textcolor to white.
                            InhibitButtons(0, 0, 0).
                            if confirm() {
                                LogToFile("Starting Land w/o Atmosphere Function").
                                LandwithoutAtmo().
                            }
                            else {
                                LogToFile("Land Function cancelled").
                                ClearInterfaceAndSteering().
                                return.
                            }
                        }
                        else {
                            ShowHomePage().
                            set message1:text to "<b>Automatic De-Orbit and Landing:</b>".
                            set message2:text to "<b>Landing Zone:</b>  <color=yellow>" + round(landingzone:lat, 4) + "," + round(landingzone:lng, 4) + "</color>   <b>Slope:</b> <color=yellow>" + round(AvailableLandingSpots[3], 1) + "°</color>".
                            set message1:style:textcolor to white.
                            set message2:style:textcolor to white.
                            set message3:style:textcolor to cyan.
                            set message3:text to "<b>Execute <color=white>or</color> Cancel?</b>".
                            set landlabel:style:textcolor to white.
                            InhibitButtons(0, 0, 0).
                            if confirm() {
                                LogToFile("Starting Land without Atmo Function").
                                LandwithoutAtmo().
                            }
                            else {
                                LogToFile("Land Function cancelled").
                                ClearInterfaceAndSteering().
                            }
                        }
                    }
                    if not addons:tr:hasimpact {
                        if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                            LogToFile("Land Function cancelled due to ship:status").
                            ClearInterfaceAndSteering().
                        }
                        else if apoapsis < 0 or apoapsis > 200000 or abs(ship:orbit:inclination) + 20 < abs(setting1:text:split(",")[0]:toscalar(0)) {
                            ShowHomePage().
                            LogToFile("De-Orbit cancelled due to orbit requirements not fulfilled").
                            set message1:text to "<b>Automatic De-Orbit Requirements:</b>".
                            set message2:text to "<b>Max Ap 200km  &  LZ Lat. < Inclination + 20°</b>".
                            set message3:text to "<b>Modify orbit or perform manual de-orbit..</b>".
                            set message2:style:textcolor to yellow.
                            set message3:style:textcolor to white.
                            wait 3.
                            ClearInterfaceAndSteering().
                        }
                        else {
                            LandingZoneFinder().
                            if LZFinderCancelled {
                                ClearInterfaceAndSteering().
                                return.
                            }
                            set message1:text to "<b>Automatic De-Orbit & Land at:</b>".
                            set message2:text to "<b>Landing Zone:</b>  <color=yellow>" + round(landingzone:lat, 4) + "," + round(landingzone:lng, 4) + "</color>   <b>Slope:</b> <color=yellow>" + round(AvailableLandingSpots[3], 1) + "°</color>".
                            set message3:style:textcolor to cyan.
                            set message3:text to "<b>Confirm <color=white>or</color> Cancel?</b>".
                            set execute:text to "<b>CONFIRM</b>".
                            InhibitButtons(0, 0, 0).
                            if confirm() {

                            }
                            else {
                                set execute:text to "<b>EXECUTE</b>".
                                ClearInterfaceAndSteering().
                                set settingsbutton:pressed to true.
                                return.
                            }
                            set execute:text to "<b>EXECUTE</b>".
                            set message3:text to "".
                            set runningprogram to "Input".
                            if KUniverse:activevessel = vessel(ship:name) {}
                            else {
                                set KUniverse:activevessel to vessel(ship:name).
                                wait 3.
                            }
                            ShowHomePage().
                            LandingZoneFinder().
                            if LZFinderCancelled {
                                ClearInterfaceAndSteering().
                                return.
                            }
                            InhibitButtons(1,1,1).
                            LogToFile("Calculating De-Orbit Burn").
                            set landlabel:style:textcolor to white.
                            set message1:text to "<b>Looking for suitable Re-Entry Trajectory..</b>".
                            set message2:text to "".
                            set message3:text to "".
                            set message1:style:textcolor to white.
                            set message2:style:textcolor to white.
                            if ship:orbit:inclination > 60 or ship:orbit:inclination < -60 {
                                LogToFile("Automatic De-Orbit burn not possible, inclination too high. Please de-orbit manually..").
                                set message1:text to "<b>Error: Inclination too high.. (> ±60°)</b>".
                                set message1:style:textcolor to yellow.
                                set message2:text to "<b>Please De-orbit manually..</b>".
                                set message2:style:textcolor to yellow.
                                set message3:text to "".
                                set textbox:style:bg to "starship_img/starship_main_square_bg".
                                wait 3.
                                ClearInterfaceAndSteering().
                                return.
                            }
                            set TimeToBurn to CalculateDeOrbitBurn(10).
                                if TimeToBurn = 0 {
                                    ClearInterfaceAndSteering().
                                    return.
                                }
                            set deorbitburnstarttime to timestamp(time:seconds + TimeToBurn).
                            set Burnlist to DeOrbitVelocity().
                            set ProgradeVelocity to Burnlist[0].
                            set NormalVelocity to Burnlist[1].
                            set AltitudeOverLZ to Burnlist[2].
                            if ProgradeVelocity = 0 {
                                set message1:text to "<b>Error: Not passing overhead the LZ..</b>".
                                set message1:style:textcolor to yellow.
                                set message2:text to "<b>Try again later..</b>".
                                set message2:style:textcolor to yellow.
                                set textbox:style:bg to "starship_img/starship_main_square_bg".
                                wait 3.
                                ClearInterfaceAndSteering().
                                return.
                            }
                            else {
                                ShowHomePage().
                                PerformBurn(deorbitburnstarttime, ProgradeVelocity, NormalVelocity, 0, "DeOrbit").
                                LandwithoutAtmo().
                            }
                        }
                    }
                }
            }
            else {
                ShowHomePage().
                LogToFile("Land Function Stopped").
                set message1:text to "<b>De-Orbit & Landing Cancelled.</b>".
                set message1:style:textcolor to yellow.
                set message2:text to "<b>This program only works on planets with atmo..</b>".
                set message2:style:textcolor to yellow.
                set textbox:style:bg to "starship_img/starship_main_square_bg".
                set message3:text to "".
                wait 3.
                ClearInterfaceAndSteering().
            }
        }
        else if ShipType = "Expendable" or ShipType = "Depot" {
            ShowHomePage().
            LogToFile("Land Function Stopped").
            set message1:text to "<b>De-Orbit & Landing Cancelled.</b>".
            set message1:style:textcolor to yellow.
            set message2:text to "<b>This Ship is not fitted for recovery..</b>".
            set message2:style:textcolor to yellow.
            set textbox:style:bg to "starship_img/starship_main_square_bg".
            set message3:text to "".
            wait 3.
            ClearInterfaceAndSteering().
        }
    }
}.



g:show().
sTelemetry:show().


if addons:tr:available and not startup {
    if Career():canmakenodes = true and Career():candoactions = true and Career():patchlimit > 0 {
        InhibitButtons(0, 1, 1).
        SetRadarAltitude().
        set runningprogram to "None".
        FindParts().
        if homeconnection:isconnected {
            if exists("0:/settings.json") {
                set L to readjson("0:/settings.json").
                if L:haskey("Tooltips") {
                    if L["Tooltips"] = true {
                        set setting2:pressed to true.
                    }
                    else {
                        set setting2:pressed to false.
                    }
                }
                if L:haskey("Launch Inclination") {
                    set setting3:text to (L["Launch Inclination"] + "°").
                }
                else {
                    set setting3:text to ("0°").
                }
                if L:haskey("Log Data") {
                    if L["Log Data"] = true {
                        set quicksetting3:pressed to true.
                    }
                }
                if L:haskey("ObeyHideUI") {
                    if L["ObeyHideUI"] = true {
                        set quicksetting4:pressed to true.
                    }
                    else set quicksetting4:pressed to false.
                }
                if L:haskey("Auto-Stack") {
                    if L["Auto-Stack"] = true {
                        set quicksetting1:pressed to true.
                    }
                }
                if L:haskey("Landing Coordinates") {
                    set LandingCoords to L["Landing Coordinates"].
                    set setting1:text to LandingCoords.
                }
                else {
                    set LandingCoords to DefaultLaunchSite.
                    set setting1:text to LandingCoords.
                }
                if L:haskey("CPU_SPD") {
                    if L["CPU_SPD"] = "800" {
                        set quicksetting2:pressed to true.
                    }
                    else {
                        set quicksetting2:pressed to true.
                        set quicksetting2:pressed to false.
                    }
                }
                else {
                    set quicksetting2:pressed to true.
                    set quicksetting2:pressed to false.
                    set quicksetting2:pressed to true.
                }
                //if L:haskey("ArmsHeight") {
                //    set ArmsHeight to L["ArmsHeight"].
                //}
            }
            else {
                set L to lexicon().
                set L["Landing Coordinates"] to DefaultLaunchSite.
                set LandingCoords to DefaultLaunchSite.
                set setting1:text to LandingCoords.
                writejson(L, "0:/settings.json").
            }
        }
        else {
            set LandingCoords to DefaultLaunchSite.
            set setting1:text to LandingCoords.
        }
        set LandingCoords to LandingCoords:split(",").
        set landingzone to latlng(LandingCoords[0]:toscalar, LandingCoords[1]:toscalar).
        if setting1:text = "-0.0972,-74.5577" {
            set TargetLZPicker:index to 2.
        }
        else if setting1:text = "-6.5604,-143.95" {
            set TargetLZPicker:index to 3.
        }
        else if setting1:text = "45.2896,136.11" {
            set TargetLZPicker:index to 4.
        }
        else if setting1:text = "20.6622,-146.4603" {
            set TargetLZPicker:index to 5.
        }
        else {
            set TargetLZPicker:index to 0.
        }
        if kuniverse:activevessel = ship {
            set addons:tr:descentmodes to list(true, true, true, true).
            set addons:tr:descentgrades to list(false, false, false, false).
            set addons:tr:descentangles to DescentAngles.
            ADDONS:TR:SETTARGET(landingzone).
        }
        if LIGHTS {set quickstatus2:pressed to true.}
        if GEAR {set quickstatus3:pressed to true.}

        if not (FLflap = "false") {
            if FLflap:getmodule("ModuleSEPControlSurface"):GetField("Deploy") = true {
                set quickstatus1:pressed to true.
            }
        }
        if panels {
            set quickcargo2:pressed to true.
        }
        if SLEngines[0]:ignition = true and VACEngines[0]:ignition = true {
            set quickengine2:pressed to true.
            set quickengine3:pressed to true.
        }
        if SLEngines[0]:ignition = true {
            set quickengine2:pressed to true.
        }
        else if VACEngines[0]:ignition = true {
            set quickengine3:pressed to true.
        }
        else {
            ShutDownAllEngines().
        }
        if Boosterconnected {
            HideEngineToggles(1).
        }
        else {
            HideEngineToggles(0).
        }
        if ShipType = "Cargo" {
            cargobutton:show().
            if Nose:name:contains("SEP.23.SHIP.FLAPS") {print("V2 Flap config").}
            if nose:name:contains("SEP.23.SHIP.CARGO") {
                set Watchdog to nose:PARTSNAMED("SEP.23.SHIP.CARGO").
                if Watchdog:length = 0 {
                    set Watchdog to nose:PARTSNAMED(("SEP.23.SHIP.CARGO (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
                }
                else {
                    set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
                }
            } else if Nose:name:contains("SEP.23.SHIP.FLAPS") {
                set Watchdog to nose:PARTSNAMED("SEP.23.SHIP.FLAPS").
                if Watchdog:length = 0 {
                    set Watchdog to nose:PARTSNAMED(("SEP.23.SHIP.FLAPS (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
                }
                else {
                    set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
                }
            }
            Watchdog:activate().
        }
		if ShipType = "Block1" {
            set cargo1text:text to "Closed".
            set Watchdog to SHIP:PARTSNAMED("SEP.24.SHIP.NOSECONE").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.24.SHIP.NOSECONE (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Block1Cargo" {
            set cargo1text:text to "Closed".
            cargobutton:show().
            set Watchdog to SHIP:PARTSNAMED("SEP.24.SHIP.CARGO").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.24.SHIP.CARGO (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Block1CargoExp" {
            set cargo1text:text to "Closed".
            cargobutton:show().
            set Watchdog to SHIP:PARTSNAMED("SEP.24.SHIP.CARGO.EXP").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.24.SHIP.CARGO.EXP (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Block1PEZExp" {
            set cargo1text:text to "Closed".
            cargobutton:show().
            set Watchdog to SHIP:PARTSNAMED("SEP.24.SHIP.PEZ.EXP").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.24.SHIP.PEZ.EXP (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Block1PEZ" {
            set cargo1text:text to "Closed".
            cargobutton:show().
            set Watchdog to SHIP:PARTSNAMED("SEP.24.SHIP.PEZ").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.24.SHIP.PEZ (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Crew" {
            cargobutton:show().
            set Watchdog to SHIP:PARTSNAMED("SEP.23.SHIP.CREW").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.23.SHIP.CREW (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Tanker" {
            set cargo1text:text to "Closed".
            set Watchdog to SHIP:PARTSNAMED("SEP.23.SHIP.TANKER").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.23.SHIP.TANKER (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Expendable" {
            set cargo1text:text to "Closed".
            set Watchdog to SHIP:PARTSNAMED("SEP.23.SHIP.CARGO.EXP").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.23.SHIP.CARGO.EXP (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Block1Exp" {
            set cargo1text:text to "Closed".
            set Watchdog to SHIP:PARTSNAMED("SEP.24.SHIP.NOSECONE.EXP").
            if Watchdog:length = 0 {
                set Watchdog to SHIP:PARTSNAMED(("SEP.24.SHIP.NOSECONE.EXP (" + ship:name + ")"))[0]:getmodule("kOSProcessor").
            }
            else {
                set Watchdog to Watchdog[0]:getmodule("kOSProcessor").
            }
            Watchdog:activate().
        }
        if ShipType = "Depot" {
            set cargo1text:text to "Closed".
        }
        SetShipBGPage().
    }
    else {
        print "Upgrade of KSC facilities required!".
        print "Interface Disabled..".
        LogToFile("Upgrade of KSC facilities required! Interface Disabled..").
        InhibitButtons(1, 1, 1).
        ShowButtons(0).
        ShowHomePage().
        set message1:text to "<b>Please upgrade your KSC facilities..</b>".
        set message2:text to "<b>needs: makenodes, candoactions & patchlimit > 0</b>".
        set message3:text to "<b>Interface has been disabled!</b>".
        set message1:style:textcolor to red.
        set message2:style:textcolor to yellow.
        set message3:style:textcolor to grey.
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        set runningprogram to "Self-Test Failed".
        updatestatusbar().
    }
    set avionics to 0.
    if Career():canmakenodes = true {set avionics to avionics + 1.}
    if Career():candoactions = true {set avionics to avionics + 1.}
    if Career():patchlimit > 0 {set avionics to avionics + 1.}
    if avionics < 3 {
        set message22:text to "          AVNCS " + avionics + "/3".
        set message22:style:textcolor to yellow.
        set message22:style:bg to "starship_img/starship_chip_yellow".
    }
    else {
        set message22:text to "          AVNCS 3/3".
        set message22:style:textcolor to white.
        set message22:style:bg to "starship_img/starship_chip".
    }
    updatestatusbar().
    SteeringManager:RESETTODEFAULT().
    clearvecdraws().
    if ship:status = "FLYING" and eta:apoapsis < eta:periapsis and altitude < body:atm:height - 5000 and alt:radar > 1000 or ship:status = "SUB_ORBITAL" and eta:apoapsis < eta:periapsis and altitude < body:atm:height - 5000 and alt:radar > 1000 and ship:body:atm:exists {
        if ship:mass - ship:drymass > 12 and not (RSS) or ship:mass - ship:drymass > 30 and RSS {
            Launch().
        }
    }
    if ship:status = "FLYING" and eta:periapsis < eta:apoapsis and alt:radar > 1000 or ship:status = "SUB_ORBITAL" and eta:periapsis < eta:apoapsis and alt:radar > 1000 {
        if ship:body:atm:exists {
            ReEntryAndLand().
        }
        else {
            LandwithoutAtmo().
        }
    }
    if SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length = 0 and SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length = 0 and alt:radar < 1000 and ship:mass - ship:drymass < 5 and quicksetting1:pressed and not (RSS) {
        LandAtOLM().
        if not (TargetOLM = "False") {
            if Vessel(TargetOLM):PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length > 0  and Vessel(TargetOLM):PARTSNAMED("SEP.25.BOOSTER.CORE"):length > 0 {
                if defined watchdog {
                    Watchdog:deactivate().
                }
                wait 3.
                Tank:getmodule("ModuleDockingNode"):SETFIELD("docking acquire force", 200).
                HUDTEXT("Stacking Starship and Booster..", 15, 2, 20, green, false).
                when alt:radar < 1000 and ship:mass - ship:drymass < 50 and SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length = 0  and SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length = 0 then {
                    sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (4 * Scale) + ",0.25")).
                    wait 4 * Scale.
                    if SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length = 0  and SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length = 0 {
                        sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (3 * Scale) + ",0.25")).
                        wait 4 * Scale.
                        preserve.
                    }
                }
                until SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length > 0 and SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length > 0  and alt:radar < 1000 and ship:mass - ship:drymass < 50 {
                    BackGroundUpdate().
                    wait 0.001.
                }
                if ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
                    set OnOrbitalMount to True.
                    set OLM to ship:partstitled("Starship Orbital Launch Mount")[0].
                    set OLM:getmodule("kOSProcessor"):volume:name to "OrbitalLaunchMount".
                    set TowerBase to ship:partstitled("Starship Orbital Launch Integration Tower Base")[0].
                    set TowerCore to ship:partstitled("Starship Orbital Launch Integration Tower Core")[0].
                    //set TowerTop to ship:partstitled("Starship Orbital Launch Integration Tower Rooftop")[0].
                    set SQD to ship:partstitled("Starship Quick Disconnect Arm")[0].
                    set SteelPlate to ship:partstitled("Water Cooled Steel Plate")[0].
                    Set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
                    if SQD:getmodule("ModuleSLESequentialAnimate"):hasevent("Full Extension") {
                        SQD:getmodule("ModuleSLESequentialAnimate"):DOEVENT("Full Extension").
                    }
                }
                
                HUDTEXT("Starship Re-stacked! Rebooting..", 5, 2, 20, green, false).
                wait 1.
                reboot.
            }
        }
    }
    VehicleSelfCheck().
    set startup to true.
}
else if not startup {
    print "Trajectories mod required!".
    print "Interface Disabled..".
    LogToFile("Trajectories mod required! Interface Disabled..").
    InhibitButtons(1, 1, 1).
    ShowButtons(0).
    ShowHomePage().
    set message1:text to "<b>Trajectories Mod not found!</b>".
    set message2:text to "<b>Trajectories is a requirement..</b>".
    set message3:text to "<b>Interface has been disabled!</b>".
    set message1:style:textcolor to red.
    set message2:style:textcolor to yellow.
    set message3:style:textcolor to grey.
    set textbox:style:bg to "starship_img/starship_main_square_bg".
    set runningprogram to "Self-Test Failed".
    updatestatusbar().
    set startup to true.
}

if not Boosterconnected and Ship:status = "PRELaunch" and ship:partsnamed("SLE.SS.TS"):length > 0 {
    EngineTest().
}

WHEN runningprogram = "None" THEN {
    BackGroundUpdate().
    preserve.
}

wait until exit.
LogToFile("Closing GUI").
g:dispose().
shutdown.



function InhibitButtons {
    parameter pagebuttons.
    parameter executebutton.
    parameter cancelbutton.
    
    if pagebuttons {
        set attitudebutton:style:bg to "starship_img/starship_attitude_inhibited".
        set attitudebutton:style:on:bg to "starship_img/starship_attitude_inhibited".
        set attitudebutton:style:hover:bg to "starship_img/starship_attitude_inhibited_hover".
        set attitudebutton:style:hover_on:bg to "starship_img/starship_attitude_inhibited_hover".
        set attitudebutton:style:active:bg to "starship_img/starship_attitude_inhibited_active".
        set attitudebutton:style:active_on:bg to "starship_img/starship_attitude_inhibited_active".
        set cargobutton:style:bg to "starship_img/starship_cargo_inhibited".
        set cargobutton:style:on:bg to "starship_img/starship_cargo_inhibited".
        set cargobutton:style:hover:bg to "starship_img/starship_cargo_inhibited_hover".
        set cargobutton:style:hover_on:bg to "starship_img/starship_cargo_inhibited_hover".
        set cargobutton:style:active:bg to "starship_img/starship_cargo_inhibited_active".
        set cargobutton:style:active_on:bg to "starship_img/starship_cargo_inhibited_active".
        set settingsbutton:style:bg to "starship_img/starship_settings_inhibited".
        set settingsbutton:style:on:bg to "starship_img/starship_settings_inhibited".
        set settingsbutton:style:hover:bg to "starship_img/starship_settings_inhibited_hover".
        set settingsbutton:style:hover_on:bg to "starship_img/starship_settings_inhibited_hover".
        set settingsbutton:style:active:bg to "starship_img/starship_settings_inhibited_active".
        set settingsbutton:style:active_on:bg to "starship_img/starship_settings_inhibited_active".
        set attitudebutton:tooltip to "Attitude Page inhibited".
        set cargobutton:tooltip to "Cargo Page inhibited".
        set settingsbutton:tooltip to "Settings Page inhibited".
        set InhibitPages to 1.}
    if not pagebuttons {
        set attitudebutton:style:bg to "starship_img/starship_attitude".
        set attitudebutton:style:on:bg to "starship_img/starship_attitude_on".
        set attitudebutton:style:hover:bg to "starship_img/starship_attitude_hover".
        set attitudebutton:style:hover_on:bg to "starship_img/starship_attitude_on".
        set attitudebutton:style:active:bg to "starship_img/starship_attitude_hover".
        set attitudebutton:style:active_on:bg to "starship_img/starship_attitude_hover".
        set cargobutton:style:bg to "starship_img/starship_cargo".
        set cargobutton:style:on:bg to "starship_img/starship_cargo_on".
        set cargobutton:style:hover:bg to "starship_img/starship_cargo_hover".
        set cargobutton:style:hover_on:bg to "starship_img/starship_cargo_on".
        set cargobutton:style:active:bg to "starship_img/starship_cargo_hover".
        set cargobutton:style:active_on:bg to "starship_img/starship_cargo_hover".
        set settingsbutton:style:bg to "starship_img/starship_settings".
        set settingsbutton:style:on:bg to "starship_img/starship_settings_on".
        set settingsbutton:style:hover:bg to "starship_img/starship_settings_hover".
        set settingsbutton:style:hover_on:bg to "starship_img/starship_settings_on".
        set settingsbutton:style:active:bg to "starship_img/starship_settings_hover".
        set settingsbutton:style:active_on:bg to "starship_img/starship_settings_hover".
        set attitudebutton:tooltip to "Manual Attitude Control Page (Landing armed @ 10km Radar Altitude)".
        set cargobutton:tooltip to "Cargo Page".
        set settingsbutton:tooltip to "Settings Page".
        set InhibitPages to 0.}

    if executebutton {   
        set execute:style:textcolor to grey.
        set execute:style:hover:bg to "starship_img/starship_background".
        set execute:style:active:bg to "starship_img/starship_background".
        set execute:style:hover:textcolor to grey.
        set execute:tooltip to "Execute inhibited".
        set InhibitExecute to 1.}
    if not executebutton {
        set execute:style:textcolor to cyan.
        set execute:style:hover:bg to "starship_img/starship_background_light".
        set execute:style:active:bg to "starship_img/starship_background_light".
        set execute:style:hover:textcolor to white.
        set execute:tooltip to "Execute selected Maneuver".
        set InhibitExecute to 0.}
    if cancelbutton {
        set cancel:style:textcolor to grey.
        set cancel:style:hover:bg to "starship_img/starship_background".
        set cancel:style:active:bg to "starship_img/starship_background".
        set cancel:style:hover:textcolor to grey.
        set cancel:tooltip to "Cancel inhibited".
        set InhibitCancel to 1.}
    if not cancelbutton {
        set cancel:style:textcolor to cyan.
        set cancel:style:hover:bg to "starship_img/starship_background_light".
        set cancel:style:active:bg to "starship_img/starship_background_light".
        set cancel:style:hover:textcolor to white.
        set cancel:tooltip to "Cancel selected Maneuver".
        set InhibitCancel to 0.}
}



//--------------Launch Program--------------------------------//



function Launch {
    if not AbortLaunchInProgress and not LaunchComplete {
        SetLoadDistances(ship, "default").
        set LaunchButtonIsRunning to true.
        set landingzone to latlng(0, 0).
        mainbox:showonly(flightstack).
        if hasnode {
            remove nextnode.
            wait 0.001.
        }
        set launchlabel:style:textcolor to green.
        set message1:style:textcolor to white.
        set message2:style:textcolor to white.
        set message3:style:textcolor to white.
        set landlabel:style:textcolor to grey.
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        HideEngineToggles(1).
        SetRadarAltitude().
        set BurnDuration to 0.
        set TargetError to 0.
        LogToFile("Launch Program Started").
        set runningprogram to "Launch".
        ShowButtons(0).
        sas off.
        rcs off.
        setflaps(0, 0, 0, 20).
        if ship:name:contains("OrbitalLaunchMount") {
            set ship:name to ("Starship " + ShipType).
        }
        list targets in shiplist.
        RenameShip().
        SaveToSettings("Ship Name", ship:name).

        set targetincl to setting3:text:split("°")[0]:toscalar(0).
        set LaunchData to LAZcalc_init(targetap, targetincl).
        print "Target Inc: " + round(setting3:text:split("°")[0]:toscalar(0)).

        if not (TargetShip = 0) {
            set target to TargetShip.
            local testHeading to heading(LAZcalc(LaunchData), 0):vector.
            local targetHeading to vxcl(up:vector, target:velocity:orbit).
            print "Heading difference: " + vang(testHeading, targetHeading).
            if vang(testHeading, targetHeading) > 15 {
                set targetincl to -targetincl.
                set LaunchData to LAZcalc_init(targetap, targetincl).
                print "Changing Launch Inclination to depart southbound!".
                print " ".
            }
        }
        print "Target Inc: " + round(setting3:text:split("°")[0]:toscalar(0)).
        

        if RSS {
            set LaunchElev to altitude - 108.384.
            if ShipType = "Depot" or CargoMass > 64000 {
                set BoosterAp to 106000 + (cos(targetincl) * 3000).
                set turnAltitude to 750.
            } else if CargoMass > 32000 {
                set BoosterAp to 96000 + (cos(targetincl) * 3000).
                set turnAltitude to 280.
            } else {
                set BoosterAp to 90000 + (cos(targetincl) * 3000).
                set turnAltitude to 280.
            }
            set PitchIncrement to 0 + 2.4 * CargoMass / MaxCargoToOrbit.
            set OrbitBurnPitchCorrectionPID to PIDLOOP(0.01, 0, 0, -30, PitchIncrement).
            set TimeFromLaunchToOrbit to LaunchTimeSpanInSeconds - 20.
            set BoosterThrottleDownAlt to 2100.
        }
        else if KSRSS {
            set LaunchElev to altitude - 67.74.
            if ShipType = "Depot" or CargoMass > 64000 {
                set BoosterAp to 69000 + (cos(targetincl) * 1500).
                set TimeFromLaunchToOrbit to 360.
            }
            else if CargoMass > 32000 {
                set BoosterAp to 67000 + (cos(targetincl) * 1500).
                set TimeFromLaunchToOrbit to LaunchTimeSpanInSeconds + 20.
            }
            else {
                set BoosterAp to 65000 + (cos(targetincl) * 1500).
                set TimeFromLaunchToOrbit to LaunchTimeSpanInSeconds - 10.
            }
            set PitchIncrement to 0 + 2.5 * CargoMass / MaxCargoToOrbit.
            set OrbitBurnPitchCorrectionPID to PIDLOOP(0.025, 0, 0, -30, PitchIncrement).
            set BoosterThrottleDownAlt to 1800.
        }
        else {
            set LaunchElev to altitude - 67.74.
            if ShipType = "Depot" or CargoMass > 64000 {
                set BoosterAp to 52000 + (cos(targetincl) * 1000).
                set TimeFromLaunchToOrbit to 285.
                set PitchIncrement to 5.
            }
            else if CargoMass > 32000 {
                set BoosterAp to 48500 + (cos(targetincl) * 1000).
                set TimeFromLaunchToOrbit to LaunchTimeSpanInSeconds + 10.
                set PitchIncrement to 0.
            }
            else {
                set BoosterAp to 46500 + (cos(targetincl) * 1000).
                set TimeFromLaunchToOrbit to LaunchTimeSpanInSeconds - 10.
                set PitchIncrement to 0.
            }
            set OrbitBurnPitchCorrectionPID to PIDLOOP(0.025, 0, 0, -30, PitchIncrement).
            set BoosterThrottleDownAlt to 1600.
        }
        set OrbitBurnPitchCorrectionPID:setpoint to targetap.

        set myAzimuth to LAZcalc(LaunchData).
        set LaunchRollVector to heading(mod(myAzimuth - 270, 360),0):vector.
        if vang(north:vector, LaunchRollVector) > 270 {
            set LaunchRollVector to -LaunchRollVector.
        }
        //set lv to vecdraw(v(0, 0, 0), LaunchRollVector, green, "LaunchRollVector", 35, true, 0.005, true, true).

        if OnOrbitalMount {
            if not BoosterSingleEngines {
                until BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode") = "All Engines" {
                    BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
                    wait 0.01.
                }
            }
            InhibitButtons(1, 1, 0).
            set cancel:text to "<b>ABORT</b>".
            set cancel:style:textcolor to red.
            if RSS {
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaArms,0,5,117.5,true").
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaPushers,0,2,20,true").
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaStabilizers,0").
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaHeight,5,0.6").
                sendMessage(Processor(volume("OrbitalLaunchMount")), "ExtendMechazillaRails").
            }
            else {
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaArms,0,5,117.5,true").
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaPushers,0,2,12.5,true").
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaStabilizers,0").
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaHeight,1.8,0.5").
                sendMessage(Processor(volume("OrbitalLaunchMount")), "ExtendMechazillaRails").
            }
            set x to time:seconds + 14.
            when x - time:seconds < 2 then {
                wait 0.01.
                lock throttle to 0.5.
            }
            until x < time:seconds or cancelconfirmed {
                set message1:text to "<b>All Systems:               <color=green>GO</color></b>".
                set message3:text to "<b>Time to Ignition:         </b>" + round(x - time:seconds) + "<b> seconds</b>".
                if not BGUisRunning {
                    BackGroundUpdate().
                }
                if x - time:seconds > 5 {
                    set message2:text to "<b>Stage 0/Mechazilla:    <color=yellow>Disconnecting..</color></b>".
                }
                else {
                    set message2:text to "<b>Booster/Ship:             <color=green>Start-Up Confirmed..</color></b>".
                }
                if x - time:seconds < 9 {
                    for k in list(OLM) {
                        if k:hasmodule("ModuleEnginesFX") {
                            if k:getmodule("ModuleEnginesFX"):hasevent("activate engine") {
                                k:getmodule("ModuleEnginesFX"):doevent("activate engine").
                            }
                        }
                        if k:hasmodule("ModuleEnginesRF") {
                            if k:getmodule("ModuleEnginesRF"):hasevent("activate engine") {
                                k:getmodule("ModuleEnginesRF"):doevent("activate engine").
                            }
                        }
                    }
                    
                }
                if x - time:seconds < 3 {
                    for p in list(SteelPlate) {
                        if p:hasmodule("ModuleEnginesFX") {
                            if P:getmodule("ModuleEnginesFX"):hasevent("activate engine") {
                                p:getmodule("ModuleEnginesFX"):doevent("activate engine").
                            }
                        }
                        if p:hasmodule("ModuleEnginesRF") {
                            if p:getmodule("ModuleEnginesRF"):hasevent("activate engine") {
                                p:getmodule("ModuleEnginesRF"):doevent("activate engine").
                            }
                        }
                    }
                    
                    
                }
            }
            if cancelconfirmed {
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaArms,8.2,5,97.5,false").
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers,0,0.25," + (0.7 * Scale) + ",false")).
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaStabilizers," + maxstabengage)).
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + 8*Scale + ",0.8")).
                sendMessage(Processor(volume("OrbitalLaunchMount")), "RetractMechazillaRails").
                set message3:text to "".
                if time:seconds > x - 1 {
                    set t to time:seconds.
                    for x in list(OLM,SteelPlate) {
                        if x:hasmodule("ModuleEnginesFX") {
                            if x:getmodule("ModuleEnginesFX"):hasevent("shutdown engine") {
                                x:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
                            }
                        }
                        if x:hasmodule("ModuleEnginesRF") {
                            if x:getmodule("ModuleEnginesRF"):hasevent("shutdown engine") {
                                x:getmodule("ModuleEnginesRF"):doevent("shutdown engine").
                            }
                        }
                    }
                    until time:seconds > t + 31 {
                        SendPing().
                        set message1:text to "<b><color=yellow>ABORT IN PROGRESS..</color></b>".
                        set message2:text to "<b>Please standby..</b> (" + round(t + 31 - time:seconds) + "s)".
                        if SQD:getmodule("ModuleSLESequentialAnimate"):hasevent("Full Extension") {
                            SQD:getmodule("ModuleSLESequentialAnimate"):DOEVENT("Full Extension").
                        }
                    }
                }
                ClearInterfaceAndSteering().
                if not BoosterSingleEngines {
                    until BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode") = "All Engines" {
                        BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
                        wait 0.01.
                    }
                }
                return.
            }
        }

        if RadarAlt < 100 {
            for resBooster in BoosterCore[0]:resources {
                if resBooster:name = "Oxidizer" or resBooster:name = "LqdMethane" or resBooster:name = "LiquidFuel" {
                    set resBooster:enabled to true.
                }
            }
            for resShip in Tank:resources {
                if resShip:name = "Oxidizer" or resShip:name = "LqdMethane" or resShip:name = "LiquidFuel" {
                    set resShip:enabled to true.
                }
            }
            if hastarget {
                print " ".
                print "Target LNG at Launch: " + round(target:geoposition:lng, 1).
                print "Time at Launch: " + timestamp(time:seconds + 2.5):full.
                print "Actual Distance: " + round((target:position - ship:position):mag / 1000, 1).
            }
            for fin in GridFins {
                if fin:hasmodule("ModuleControlSurface") {
                    fin:getmodule("ModuleControlSurface"):SetField("authority limiter", 3).
                    fin:getmodule("ModuleControlSurface"):DoAction("activate roll control", true).
                    fin:getmodule("ModuleControlSurface"):SetField("deploy direction", true).
                }
                if fin:hasmodule("SyncModuleControlSurface") {
                    fin:getmodule("SyncModuleControlSurface"):SetField("authority limiter", 3).
                    fin:getmodule("SyncModuleControlSurface"):DoAction("activate roll control", true).
                    fin:getmodule("SyncModuleControlSurface"):SetField("deploy direction", true).
                }
            }
            if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).

            wait 0.02. 
            
            if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleEnginesFX"):doaction("activate engine", true).
            else {
                for eng in BoosterSingleEnginesRC if random() < 0.98 eng:activate.
            }

            set EngineStartTime to time:seconds.
            set message1:text to "<b>Ignition Sequence</b>".
            set message2:text to "<b>Expected Engine Count:</b>    13".
            set message3:text to "<b>Engine throttle:     </b>" + round(throttle * 100) + "%".
            wait 1.

            if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true). 
            else {
                set x to 0.
                for eng in BoosterSingleEnginesRB {
                    if x = 3 or x = 7 or x = 11 or x = 15  or x = 19 {}
                    else if random() < 0.98 eng:activate.
                    set x to x + 1.
                }
                set inactiveEng to List(7,11,15,19,24).
            }
            set message2:text to "<b>Expected Engine Count:</b>    28".
            wait 0.7.
            
            //last 5 outer ignition
            set message2:text to "<b>Expected Engine Count:</b>    33".
            if BoosterSingleEngines {
                set x to 0.
                for eng in BoosterSingleEnginesRB {
                    if x = 3 or x = 7 or x = 11 or x = 15 or x = 19 if random() < 0.98 eng:activate.
                    set x to x + 1.
                }
            }
            

            wait 0.1.
            if SQD:getmodule("ModuleSLESequentialAnimate"):hasevent("Full Retraction") {
                SQD:getmodule("ModuleSLESequentialAnimate"):DOEVENT("Full Retraction").
            }
            BoosterCore[0]:activate.

            until time:seconds - EngineStartTime > 3.8 or cancelconfirmed {
                set message3:text to "<b>Engine throttle up:  </b>" + round(throttle * 100) + "%".
                set message1:text to "<b>Clamps Release in:   </b>" + round(-time:seconds + EngineStartTime + 4.2, 1) + "<b> seconds</b>".
                lock throttle to 0.5 + 0.27 * (time:seconds - EngineStartTime - 1.8) / 2.
                
                BackGroundUpdate().
            }

            g:hide().
            
            set message1:text to "".
            set message3:text to "<b>Engine throttle up:  </b>" + round(throttle * 100) + "%".
            set message2:text to "<b>Clamps Releasing..</b>".
            if cancelconfirmed {
                if not BoosterSingleEngines BoosterEngines[0]:shutdown.
                else {
                    for eng in BoosterSingleEnginesRB eng:shutdown.
                    for eng in BoosterSingleEnginesRC eng:shutdown.
                }
                BoosterCore[0]:shutdown.
                if not BoosterSingleEngines {
                    until BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode") = "All Engines" {
                        BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
                        wait 0.01.
                    }
                }
                for x in list(OLM,SteelPlate) {
                    if x:hasmodule("ModuleEnginesFX") {
                        if x:getmodule("ModuleEnginesFX"):hasevent("shutdown engine") {
                            x:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
                        }
                    }
                    if x:hasmodule("ModuleEnginesRF") {
                        if x:getmodule("ModuleEnginesRF"):hasevent("shutdown engine") {
                            x:getmodule("ModuleEnginesRF"):doevent("shutdown engine").
                        }
                    }
                }
                if SQD:getmodule("ModuleSLESequentialAnimate"):hasevent("Full Extension") {
                    SQD:getmodule("ModuleSLESequentialAnimate"):DOEVENT("Full Extension").
                }
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaArms,8.2,5,97.5,false").
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers,0,0.25," + (0.7 * Scale) + ",false")).
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaStabilizers," + maxstabengage)).
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + 8*Scale + ",0.8")).
                sendMessage(Processor(volume("OrbitalLaunchMount")), "RetractMechazillaRails").
                ClearInterfaceAndSteering().
                return.
            }
            set lowTWR to false.
            set StackMass to ship:mass - OLM:Mass - TowerBase:mass - TowerCore:mass - Mechazilla:mass.
            lock throttle to 0.77.
            wait 0.1.
            
            if BoosterSingleEngines {
                set ActiveRC to 0. set ActiveRB to 0.
                for eng in BoosterSingleEnginesRC if eng:thrust > 85 set ActiveRC to ActiveRC + 1.
                for eng in BoosterSingleEnginesRB if eng:thrust > 85 set ActiveRB to ActiveRB + 1.
                lock bLiftOffThrust to ActiveRB * BoosterSingleEnginesRB[0]:thrust  + ActiveRC * BoosterSingleEnginesRC[0]:thrust.
            } 
            else lock bLiftOffThrust to BoosterEngines[0]:thrust.
            wait 0.1.
            if bLiftOffThrust > StackMass * Planet1G * 1.4 and bLiftOffThrust < StackMass * Planet1G * 2 {}
            else {
                lock throttle to 0.85. 
                print(round(bLiftOffThrust, 2) + "<" + round(StackMass * Planet1G * 1.4, 2)).
                wait 0.01.}
            set message3:text to "<b>Engine throttle up:  </b>" + round(throttle * 100) + "%".
            if bLiftOffThrust > StackMass * Planet1G * 1.37 and bLiftOffThrust < StackMass * Planet1G * 2 {}
            else {
                lock throttle to 0.9. 
                print(round(bLiftOffThrust, 2) + "<" + round(StackMass * Planet1G * 1.37, 2)).
                wait 0.01.}
            set message3:text to "<b>Engine throttle up:  </b>" + round(throttle * 100) + "%".
            if bLiftOffThrust > StackMass * Planet1G * 1.34 and bLiftOffThrust < StackMass * Planet1G * 2 {}
            else {
                lock throttle to 0.95. 
                print(round(bLiftOffThrust, 2) + "<" + round(StackMass * Planet1G * 1.34, 2)).
                wait 0.01.}
            set message3:text to "<b>Engine throttle up:  </b>" + round(throttle * 100) + "%".
            if bLiftOffThrust > StackMass * Planet1G * 1.3 and bLiftOffThrust < StackMass * Planet1G * 2 {}
            else {
                lock throttle to 1. 
                print(round(bLiftOffThrust, 2) + "<" + round(StackMass * Planet1G * 1.3, 2)).
                wait 0.01.}
            set message3:text to "<b>Engine throttle up:  </b>" + round(throttle * 100) + "%".
            if bLiftOffThrust > StackMass * Planet1G * 1.24 and bLiftOffThrust < StackMass * Planet1G * 2 {}
            //if 1=1 {}
            else {
                print(round(bLiftOffThrust, 2) + "<" + round(StackMass * Planet1G * 1.24, 2)).
                g:show().
                set message1:text to "<b>Launch Abort: </b>Thrust anomaly!".
                set message2:text to "<b>Thrust Range: </b>" + round(StackMass * Planet1G * 1.24) + "kN - " + round(StackMass * Planet1G * 2) + "kN".
                set message3:text to "<b>Actual Thrust: </b>" + round(bLiftOffThrust) + "kN".
                lock throttle to 0.
                unlock bLiftOffThrust.
                if not BoosterSingleEngines BoosterEngines[0]:shutdown.
                else {
                    for eng in BoosterSingleEnginesRB eng:shutdown.
                    for eng in BoosterSingleEnginesRC eng:shutdown.
                }
                BoosterCore[0]:shutdown.
                if not BoosterSingleEngines {
                    until BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode") = "All Engines" {
                        BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
                        wait 0.01.
                    }
                }
                sendMessage(Processor(volume("OrbitalLaunchMount")), "RetractMechazillaRails").
                set message1:style:textcolor to yellow.
                set textbox:style:bg to "starship_img/starship_main_square_bg".
                wait 3.
                for x in list(OLM,SteelPlate) {
                    if x:hasmodule("ModuleEnginesFX") {
                        if x:getmodule("ModuleEnginesFX"):hasevent("shutdown engine") {
                            x:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
                        }
                    }
                    if x:hasmodule("ModuleEnginesRF") {
                        if x:getmodule("ModuleEnginesRF"):hasevent("shutdown engine") {
                            x:getmodule("ModuleEnginesRF"):doevent("shutdown engine").
                        }
                    }
                }
                if SQD:getmodule("ModuleSLESequentialAnimate"):hasevent("Full Extension") {
                    SQD:getmodule("ModuleSLESequentialAnimate"):DOEVENT("Full Extension").
                }
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaArms,8.2,5,97.5,false").
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers,0,0.25," + (0.7 * Scale) + ",false")).
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaStabilizers," + maxstabengage)).
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + 8*Scale + ",0.8")).
                ClearInterfaceAndSteering().
                return.
            }
            if bLiftOffThrust/(StackMass * Planet1G) < 1.3 set lowTWR to true.
            unlock bLiftOffThrust.
            BoosterCore[0]:shutdown.
            wait 0.01.
            set SteeringManager:rollts to 5.
            if ShipType = "Cargo" or ShipType = "Tanker" or ShipType = "Block1Cargo" or ShipType = "Block1CargoExp" or ShipType = "Block1PEZExp" {
                InhibitButtons(1, 1, 1).
            }
            if OnOrbitalMount {
                sendMessage(Processor(volume("OrbitalLaunchMount")), "LiftOff").
            }
            if ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
                if OLM:getmodule("ModuleDockingNode"):hasevent("undock") {
                    OLM:getmodule("ModuleDockingNode"):doevent("undock").
                }
            }
            else {
                OLM:getmodule("LaunchClamp"):DoEvent("release clamp").
            }
            if SHIP:PARTSNAMED("SEP.23.BOOSTER.CLUSTER"):length > 0 {
                if BoosterEngines[0]:getmodule("ModuleDockingNode"):hasevent("undock") {
                    BoosterEngines[0]:getmodule("ModuleDockingNode"):doevent("undock").
                }
            }
            set OnOrbitalMount to False.
            if defined LaunchTime {
                LogToFile("Lift-Off! Time difference from Launch-to-Rendezvous-Time to Lift-off: " + timeSpanCalculator(time:seconds - LaunchTime - 16)).
            }
            else {
                LogToFile("Lift-Off!").
            }
            set LiftOffTime to time:seconds.
            wait 0.1.
            if ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
                lock throttle to 0.
                set message1:text to "<b>Launch Abort: </b>Clamps Failure!".
                set message2:text to "<b>Please refuel (tower page) and try again..</b>".
                set message3:text to "<b></b>".
                set message1:style:textcolor to yellow.
                set textbox:style:bg to "starship_img/starship_main_square_bg".
                HUDTEXT("Clamp Failure! Please refuel (tower page) and try again..", 10, 2, 20, red, false).
                wait 3.
                for x in list(OLM,SteelPlate) {
                    if x:hasmodule("ModuleEnginesFX") {
                        if x:getmodule("ModuleEnginesFX"):hasevent("shutdown engine") {
                            x:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
                        }
                    }
                    if x:hasmodule("ModuleEnginesRF") {
                        if x:getmodule("ModuleEnginesRF"):hasevent("shutdown engine") {
                            x:getmodule("ModuleEnginesRF"):doevent("shutdown engine").
                        }
                    }
                }
                sendMessage(Processor(volume("OrbitalLaunchMount")), "MechazillaArms,8.2,5,97.5,false").
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaPushers,0,0.25," + (0.7 * Scale) + ",false")).
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaStabilizers," + maxstabengage)).
                sendMessage(Processor(volume("OrbitalLaunchMount")), ("MechazillaHeight," + 8*Scale + ",0.8")).
                OLM:getmodule("ModuleAnimateGeneric"):doevent("open clamps + qd").
                ClearInterfaceAndSteering().
                reboot.
            }
            if RSS {
                if round(ship:geoposition:lat, 3) = round(landingzone:lat, 3) and round(ship:geoposition:lng, 3) = round(landingzone:lng, 3) {}
                else {
                    set landingzone to latlng(round(ship:geoposition:lat, 6), round(ship:geoposition:lng, 6)).
                    set setting1:text to (landingzone:lat + "," + landingzone:lng).
                    SaveToSettings("Landing Coordinates", (landingzone:lat + "," + landingzone:lng)).
                }
            }
            else {
                if round(ship:geoposition:lat, 2) = round(landingzone:lat, 2) and round(ship:geoposition:lng, 2) = round(landingzone:lng, 2) {}
                else {
                    set landingzone to latlng(round(ship:geoposition:lat, 4), round(ship:geoposition:lng, 4)).
                    set setting1:text to (landingzone:lat + "," + landingzone:lng).
                    SaveToSettings("Landing Coordinates", (landingzone:lat + "," + landingzone:lng)).
                }
            }
            SaveToSettings("Launch Coordinates", (landingzone:lat + "," + landingzone:lng)).
            if kuniverse:activevessel = ship {
                ADDONS:TR:SETTARGET(landingzone).
            }



        }
        else if apoapsis < targetap {
            LogToFile("Launching").
        }.

        when altitude-LaunchElev > 243 then {
            lock throttle to LaunchThrottle().
        }
        lock steering to LaunchSteering().


        when cancelconfirmed and not ClosingIsRunning and LaunchButtonIsRunning then {
            Droppriority().
            AbortLaunch().
        }
        when apoapsis > BoosterAp and not AbortLaunchInProgress then {
            if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
        }

        if Boosterconnected {
            set steeringManager:maxstoppingtime to 0.8*Scale.
            when apoapsis > BoosterAp - 21000 * Scale then {
                set steeringManager:maxstoppingtime to 0.2.
                if HSRJet {
                    sendMessage(processor(volume("Booster")), "HSRJet").
                } 
                else {
                    sendMessage(processor(volume("Booster")), "NoHSRJet").
                } 
            }
            when apoapsis > BoosterAp - 7500 * Scale and ShipType = "Crew" then {
                HUDTEXT("Leave IVA ASAP! (to avoid stuck cameras)", 10, 2, 20, yellow, false).
            }
            when apoapsis > BoosterAp and not AbortLaunchInProgress then {
                set Hotstaging to true.
                if BoosterSingleEngines {
                    set x to 1.
                    for eng in BoosterSingleEnginesRB {
                        if x = 4 or x = 8 or x = 12 or x = 16 or x = 20 eng:shutdown.
                        set x to x + 1.
                    }
                }
                for fin in GridFins {
                    if fin:hasmodule("ModuleControlSurface") {
                        fin:getmodule("ModuleControlSurface"):SetField("deploy direction", false).
                        fin:getmodule("ModuleControlSurface"):SetField("authority limiter", 32).
                        fin:getmodule("ModuleControlSurface"):DoAction("deactivate roll control", true).
                    }
                    if fin:hasmodule("SyncModuleControlSurface") {
                        fin:getmodule("SyncModuleControlSurface"):SetField("deploy direction", false).
                        fin:getmodule("SyncModuleControlSurface"):SetField("authority limiter", 32).
                        fin:getmodule("SyncModuleControlSurface"):DoAction("deactivate roll control", true).
                    }
                }
                updateTelemetry().
                wait 0.12.
                
                if BoosterSingleEngines {
                    set x to 1.
                    for eng in BoosterSingleEnginesRB {
                        if x = 2 or x = 6 or x = 10 or x = 14 or x = 18 eng:shutdown.
                        set x to x + 1.
                    }
                }

                wait 0.12.
                //GridFins[0]:getmodule("ModuleControlSurface"):doaction("toggle deploy", true).
                //GridFins[2]:getmodule("ModuleControlSurface"):doaction("toggle deploy", true).
                if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
                else {
                    set x to 1.
                    for eng in BoosterSingleEnginesRB {
                        if x = 3 or x = 7 or x = 11 or x = 15 or x = 19 eng:shutdown.
                        set x to x + 1.
                    }
                }
                LogToFile("Starting stage-separation").
                set message1:text to "<b>Hot staging..</b>".
                set message2:text to "".
                set message3:text to "".
                ShowHomePage().
                updateTelemetry().
                wait 0.12.
                
                if BoosterSingleEngines {
                    set x to 1.
                    for eng in BoosterSingleEnginesRB {
                        if x = 1 or x = 5 or x = 9 or x = 13 or x = 17 eng:shutdown.
                        set x to x + 1.
                    }
                    for eng in BoosterSingleEnginesRB eng:shutdown.
                }
                wait 0.12.
                set CargoBeforeSeparation to CargoMass.
                //if Tank:getmodule("ModuleB9PartSwitch"):getfield("current docking system") = "QD" {
                //    Tank:getmodule("ModuleB9PartSwitch"):DoAction("next docking system", true).
                //}
                if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
                else {
                    set x to 1.
                    for eng in BoosterSingleEnginesRC {
                        if x = 1 or x = 2 or x = 3 or x = 4 or x = 6 or x = 8 or x = 10 or x = 12 {} else eng:shutdown.
                        set x to x + 1.
                    }
                }
                updateTelemetry().
                wait 0.24.
                if BoosterSingleEngines {
                    set x to 1.
                    for eng in BoosterSingleEnginesRC {
                        if x = 4 or x = 6 or x = 8 or x = 10 or x = 12 eng:shutdown.
                        set x to x + 1.
                    }
                }
                wait 0.02.
                set t to time:seconds.
                until time:seconds > t + 2.5 {
                    clearscreen.
                    SendPing().
                    BackGroundUpdate().
                    LaunchLabelData().
                    wait 0.1.
                }
                updateTelemetry().
                wait 0.02.
                if defined HSR {
                    for x in range(0, HSR[0]:modules:length) {
                        if HSR[0]:getmodulebyindex(x):hasfield("% rated thrust") {
                            if HSR[0]:getmodulebyindex(x):hasevent("activate engine") {
                                HSR[0]:getmodulebyindex(x):DoEvent("activate engine").
                            }
                        }
                    }
                }
                set steeringManager:maxstoppingtime to 0.4.
                until time:seconds > t + 2.93 {
                    clearscreen.
                    SendPing().
                    BackGroundUpdate().
                    LaunchLabelData().
                    wait 0.1.
                }
                lock throttle to 0.5.
                updateTelemetry().
                unlock steering.
                if not cancelconfirmed {
                    sendMessage(Processor(volume("Booster")), "Boostback").
                }
                set quickengine3:pressed to true.
                updateTelemetry().
                for eng in SLEngines {
                    eng:getmodule("ModuleSEPRaptor"):doaction("enable actuate out", true).
                    eng:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
                }
                if ShipType:contains("Block1") {
                    print "Block 1".
                    if defined HSR {
                        HSR[0]:getmodule("ModuleDockingNode"):doaction("undock node", true).
                        HSR[0]:getmodule("ModuleDecouple"):doaction("Decouple", true).
                    }
                    Tank:getmodule("ModuleDockingNode"):doaction("undock node", true).
                    wait 0.1.
                    if Tank:getmodule("ModuleDockingNode"):hasaction("undock node") {
                        Tank:getmodule("ModuleDockingNode"):doaction("undock node", true).
                    }
                } else {
                    if defined HSR {
                        HSR[0]:getmodule("ModuleDockingNode"):doaction("undock node", true).
                    }
                    else {
                        BoosterCore[0]:getmodule("ModuleDockingNode"):doaction("undock node", true).
                    }
                    Tank:getmodule("ModuleDockingNode"):doaction("undock node", true).
                    wait 0.1.
                    if Tank:getmodule("ModuleDockingNode"):hasaction("undock node") {
                        Tank:getmodule("ModuleDockingNode"):doaction("undock node", true).
                    }
                }
                updateTelemetry().

                wait until SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):LENGTH = 0.
                updateTelemetry().
                set HotStageTime to time:seconds.
                set StageSepComplete to true.
                set ship:name to ("Starship " + ShipType).
                set Boosterconnected to false.
                set CargoAfterSeparation to CargoMass.
                InhibitButtons(1, 1, 1).
                set cancel:text to "<b>CANCEL</b>".
                rcs on.
                lock steering to LaunchSteering().
                wait 0.1.
                set kuniverse:activevessel to vessel(ship:name).
                HideEngineToggles(1).
                //if Tank:getmodule("ModuleB9PartSwitch"):getfield("current docking system") = "BTB" {
                //    Tank:getmodule("ModuleB9PartSwitch"):DoAction("next docking system", true).
                //}
                set StageSepComplete to true.
                if RSS {
                    SetLoadDistances(ship, 1650000).
                }
                else if KSRSS {
                    SetLoadDistances(ship, 1100000).
                }
                else {
                    SetLoadDistances(ship, 900000).
                }
                LogToFile("Hot-Staging Complete").
                when time:seconds > HotStageTime + 0.2 then {
                    set quickengine2:pressed to true.
                }
                when time:seconds > HotStageTime + 0.4 then {
                    set tgtThro to LaunchThrottle().
                    set curThro to throttle.
                    lock throttle to curThro + (tgtThro - curThro)*(time:seconds-HotStageTime-0.4)/2.
                    when throttle > tgtThro - 0.02 then lock throttle to LaunchThrottle().
                }
                if CPUSPEED < 1000 {
                    set config:ipu to 1000.
                }
                list targets in shiplist.
                RenameShip().
            }
        }
        else {
            set StageSepComplete to true.
            rcs on.
            set quickengine2:pressed to true.
            set quickengine3:pressed to true.
            lock throttle to 1.
            set cancel:text to "<b>CANCEL</b>".
            InhibitButtons(1, 1, 1).
        }

        when StageSepComplete then {
            set sAltitude:style:textcolor to white.
            set sSpeed:style:textcolor to white.
            set sLOXLabel:style:textcolor to white.
            set sLOXSlider:style:bg to "starship_img/telemetry_fuel".
            set sCH4Label:style:textcolor to white.
            set sCH4Slider:style:bg to "starship_img/telemetry_fuel".
            set sThrust:style:textcolor to white.
            when time:seconds > HotStageTime + 1.5 then {
                set Booster to Vessel("Booster").
                for eng in SLEngines {
                    eng:getmodule("ModuleSEPRaptor"):doaction("disable actuate out", true).
                }
            }
            when time:seconds > HotStageTime + 3 then {
                lock steering to LaunchSteering().
            }
            when time:seconds > HotStageTime + 5 then {
                KUniverse:forceactive(vessel("Booster")).
            }

            when deltav < 89 and deltav > 0 or throttle < 0.42 and deltav < 600*Scale and deltav > 0 then {
                set quickengine3:pressed to false.
            }

            if ShipType = "Depot" {
                set steeringmanager:yawtorquefactor to 0.1.
            }
            if STOCK {
                set steeringmanager:pitchtorquefactor to 0.5.
            }
            if RSS {
                when TargetAp < apoapsis and altitude > TargetAp*0.9 or altitude > targetap - 500 or eta:apoapsis > 0.5 * ship:orbit:period or eta:apoapsis < 5 or deltav < 750 then {
                    if ShipType = "Depot" {
                        set OrbitBurnPitchCorrectionPID to PIDLOOP(0.75, 0, 0, -7.5, 20).
                    }
                    else if NrOfVacEngines = 6 {
                        set OrbitBurnPitchCorrectionPID to PIDLOOP(0.75, 0, 0, -7.5, 15).
                    }
                    else {
                        set OrbitBurnPitchCorrectionPID to PIDLOOP(0.75, 0, 0, -7.5, 15).
                    }
                    set MaintainVS to true.
                }
            }
            else if KSRSS {
                when DesiredAccel / MaxAccel < 0.6 and altitude > 80000 or apoapsis > targetap then {
                    //if NrOfVacEngines = 6 or ShipType = "Depot" or verticalspeed < 0 {
                    //    set quickengine2:pressed to false.
                    //}
                    when altitude > targetap - 100 or eta:apoapsis > 0.5 * ship:orbit:period or eta:apoapsis < 5 or deltav < 400 then {
                        set OrbitBurnPitchCorrectionPID to PIDLOOP(1.5, 0, 0, -10, 17.5).
                        set MaintainVS to true.
                    }
                }
            }
            else {
                when apoapsis > targetap - 10000 and time:seconds > HotStageTime + 15 or verticalspeed < 0 then {
                    //if NrOfVacEngines = 6 or ShipType = "Depot" {
                    //    set quickengine2:pressed to false.
                    //}
                    when altitude > targetap - 1000 or eta:apoapsis > 0.5 * ship:orbit:period or eta:apoapsis < 5 or deltav < 100 then {
                        if ShipType = "Depot" {
                            set OrbitBurnPitchCorrectionPID to PIDLOOP(2.5, 0, 0, -10, 12.5).
                        }
                        else {
                            set OrbitBurnPitchCorrectionPID to PIDLOOP(2.5, 0, 0, -10, 7.5).
                        }
                        set MaintainVS to true.
                    }
                }
            }
        }

        until BurnComplete or AbortLaunchInProgress {
            clearscreen.
            SendPing().
            BackGroundUpdate().
            LaunchLabelData().
            //print "OPCodes left    until: " + opcodesleft.
            wait 0.1.
        }
        
        g:show().

        unlock steering.
        SteeringManager:RESETTODEFAULT().
        set steeringmanager:pitchtorquefactor to 0.75.
        set steeringmanager:yawtorquefactor to 0.75.
        set steeringmanager:rolltorquefactor to 0.75.
        wait 0.001.
        lock throttle to 0.
        set config:ipu to CPUSPEED.
        if NrOfVacEngines = 3 {
            SLEngines[0]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
            SLEngines[1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
            SLEngines[2]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
        }
        wait 0.001.
        if hasnode {
            remove nextnode.
            wait 0.001.
        }
        ShutDownAllEngines().
        BackGroundUpdate().
        set DistanceToTarget to ((landingzone:lng - ship:geoposition:lng) * Planet1Degree).
        LogToFile("Distance flown from Launch Site to Orbit Complete: " + round(DistanceToTarget, 3) + "km").
        if not (LiftOffTime = 0) {
            LogToFile("Circularization Burn Finished. Time since Lift-Off: " + timeSpanCalculator(time:seconds - LiftOffTime)).
        }
        sas on.
        set message1:text to "<b>Current Orbit:</b>  " + round(APOAPSIS / 1000, 1) + "km x " + round(PERIAPSIS / 1000, 1) + "km".
        set message2:text to "<b>Orbit achieved!</b>".
        set message3:text to "<b>Launch Program completed..</b>".
        wait 0.001.
        if not RSS {sendMessage(Vessel("Booster"), "Orbit Insertion").}
        HideEngineToggles(1).
        wait 0.001.
        Droppriority().
        rcs off.
        HUDTEXT("Ship: Orbit achieved! Interface shutdown commanded..", 10, 2, 22, green, false).
        wait 0.001.
        set ship:name to ("Starship " + ShipType + " Orbit").
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        ShowHomePage().
        LogToFile("Launch Complete").
        wait 3.
        if not RSS HUDTEXT("Booster: Automated Return is in progress..", 15, 2, 22, white, false).
        LogToFile("Launch Program Ended").
        print "Launch Program Ended".
        SetLoadDistances(ship, "default").
        ClearInterfaceAndSteering().
    }
}.

function LaunchThrottle {
    local thr is 0.
    SendPing().
    if Boosterconnected {
        set gLoad to ship:maxThrust / (ship:mass * 9.805).
        if ship:q > 0.25 {
            set thr to 1 - 3 * (ship:q - 0.25).
        }
        else if gLoad > 2.5 {
            set thr to 1 - 0.1 * (gLoad - 2.5).
        }
        else {
            set thr to 1.
        }
        if apoapsis > BoosterAp {
            set thr to max((1 - 0.1 * (gLoad - 2.5))/2 + min((1 - 0.1 * (gLoad - 2.5))/2 - ((apoapsis - BoosterAp) / BoosterThrottleDownAlt),0.5),0.5).
        }
    }
    else {
        set ApoapsisVelocity to sqrt(ship:body:mu * ((2 / (ship:body:radius + APOAPSIS)) - (1 / ship:obt:semimajoraxis))).
        if MaintainVS {
            set OrbitalVelocity to ship:body:radius * sqrt(9.81 / (ship:body:radius + altitude)).
            set deltaV to OrbitalVelocity - velocity:orbit:mag.
        }
        else {
            set OrbitalVelocity to ship:body:radius * sqrt(9.81 / (ship:body:radius + targetap)).
            set deltaV to OrbitalVelocity - ApoapsisVelocity.
        }
        set TimeToOrbitCompletion to TimeFromLaunchToOrbit - (time:seconds - LiftOffTime).
        set DesiredAccel to max(deltaV / (TimeToOrbitCompletion), 0.25 * MaxAccel).
        set MaxAccel to 10.
        if quickengine2:pressed {
            if defined CargoBeforeSeparation and defined CargoAfterSeparation {
                set MaxAccel to max((ship:availablethrust / (ship:mass + ((CargoBeforeSeparation - CargoAfterSeparation) / 1000))), 0.000001).
            }
            else {
                set MaxAccel to max(ship:availablethrust / (ship:mass), 0.000001).
            }
            if periapsis < altitude - OrbitPrecision {
                if apoapsis < targetap + 7500 {
                    if apoapsis < targetap or MaintainVS and verticalspeed < 0 {
                        if STOCK {
                            set thr to max(min((1 * Planet1G) / MaxAccel, max(deltaV / MaxAccel, 0.1)), 0.33).
                        }
                        else {
                            set thr to max(min((3 * Planet1G) / MaxAccel, max(deltaV / MaxAccel, 0.1)), 0.33).
                        }
                    }
                    else {
                        set thr to max(min(DesiredAccel / MaxAccel, max(deltaV / MaxAccel, 0.1)), 0.33).
                    }
                }
                else if MaintainVS and periapsis < (ship:body:atm:height + TargetAp) / 2 {
                    set thr to max(min(DesiredAccel / MaxAccel, max(deltaV / MaxAccel, 0.1)), 0.33).
                }
                else {
                    set thr to 0.
                    if periapsis > body:atm:height {
                        set BurnComplete to true.
                    }
                }
            }
            else {
                set thr to 0.
                if periapsis > body:atm:height {
                    set BurnComplete to true.
                }
            }
        }
    }
    return min(max(thr,0),1).
}

Function LaunchSteering {
    set myAzimuth to LAZcalc(LaunchData).
    clearscreen.
    print "Steering Error: " + round(SteeringManager:angleerror, 2).
    print " ".

    if hastarget {
        set TargetError to vang(normal(target:orbit), normal(ship:orbit)).
        if vdot(ship:velocity:orbit, normal(target:orbit)) < 0 {
            set TargetError to -TargetError.
        }
        print "Target Error: " + round(TargetError, 2).
    }
    else if not (TargetShip = 0) {
        set target to TargetShip.
    }

    if altitude - LaunchElev < 120 {
        set result to heading(myAzimuth + TargetError, 90).
    } 
    else if altitude - LaunchElev < 1000 {
        if RSS {
            set targetpitch to 90 - (7.5 * SQRT(max((altitude - 120 - LaunchElev), 0)/1600)).
        }
        else if KSRSS {
            if RESCALE {
                set targetpitch to 90 - (8.375 * SQRT(max((altitude - 120 - LaunchElev), 0)/1700)).
            }
            else {
                set targetpitch to 90 - (9.625 * SQRT(max((altitude - 120 - LaunchElev), 0)/1700)).
            }
        }
        else {
            set targetpitch to 90 - (11 * SQRT(max((altitude - 120 - LaunchElev), 0)/1650)).
        }
        set result to lookdirup(heading(myAzimuth + 3 * TargetError, targetpitch):vector, LaunchRollVector).
    } 
    else if apoapsis > BoosterAp - 21000 * Scale and Boosterconnected {
        if apoapsis > BoosterAp - 10000 * Scale and Boosterconnected {
            if RSS {
                set result to lookDirUp(srfPrograde:vector + 0.16*up:vector, LaunchRollVector).
            } else {
                set result to lookDirUp(srfPrograde:vector, LaunchRollVector).
            }
        }
        else {
            if RSS {
                set result to lookDirUp(srfPrograde:vector + 0.26*up:vector, LaunchRollVector).
            } else {
                set result to lookDirUp(srfPrograde:vector + 0.2*up:vector, LaunchRollVector).
            }
        }
    }
    else if Boosterconnected and not lowTWR and CargoMass < 50001 {
        if RSS {
            if ShipType = "Depot" {
                set targetpitch to 90 - (7.25 * SQRT(max((altitude - 250 - LaunchElev), 0)/1300)).
            }
            else {
                set targetpitch to 90 - (8.42 * SQRT(max((altitude - 250 - LaunchElev), 0)/1100)).
            }
        }
        else if KSRSS {
            if RESCALE {
                if ShipType = "Depot" {
                    set targetpitch to 90 - (8.2 * SQRT(max((altitude - 250 - LaunchElev), 0)/1250)).
                }
                else {
                    set targetpitch to 90 - (8.45 * SQRT(max((altitude - 250 - LaunchElev), 0)/1150)).
                }
            }
            else {
                if ShipType = "Depot" {
                    set targetpitch to 90 - (9.45 * SQRT(max((altitude - 250 - LaunchElev), 0)/1200)).
                }
                else {
                    set targetpitch to 90 - (9.8 * SQRT(max((altitude - 250 - LaunchElev), 0)/1100)).
                }
            }
        }
        else {
            if ShipType = "Depot" {
                set targetpitch to 90 - (6.5 * SQRT(max((altitude - 250 - LaunchElev), 0)/1200)).
            }
            else {
                set targetpitch to 90 - (11.5 * SQRT(max((altitude - 250 - LaunchElev), 0)/1000)).
            }
        }
        set result to lookdirup(heading(myAzimuth + 3 * TargetError, targetpitch):vector, LaunchRollVector).
    }
    else if Boosterconnected and not lowTWR and CargoMass > 50000 {
        if RSS {
            if ShipType = "Depot" {
                set targetpitch to 90 - (7.25 * SQRT(max((altitude - 250 - LaunchElev), 0)/1250)).
            }
            else {
                set targetpitch to 90 - (8.48 * SQRT(max((altitude - 250 - LaunchElev), 0)/1100)).
            }
        }
        else if KSRSS {
            if RESCALE {
                if ShipType = "Depot" {
                    set targetpitch to 90 - (8.2 * SQRT(max((altitude - 250 - LaunchElev), 0)/1250)).
                }
                else {
                    set targetpitch to 90 - (8.45 * SQRT(max((altitude - 250 - LaunchElev), 0)/1100)).
                }
            }
            else {
                if ShipType = "Depot" {
                    set targetpitch to 90 - (9.45 * SQRT(max((altitude - 250 - LaunchElev), 0)/1200)).
                }
                else {
                    set targetpitch to 90 - (9.8 * SQRT(max((altitude - 250 - LaunchElev), 0)/1050)).
                }
            }
        }
        else {
            if ShipType = "Depot" {
                set targetpitch to 90 - (6.5 * SQRT(max((altitude - 250 - LaunchElev), 0)/1200)).
            }
            else {
                set targetpitch to 90 - (11.5 * SQRT(max((altitude - 250 - LaunchElev), 0)/950)).
            }
        }
        set result to lookdirup(heading(myAzimuth + 3 * TargetError, targetpitch):vector, LaunchRollVector).
    }
    else if Boosterconnected {
        if RSS {
            if ShipType = "Depot" {
                set targetpitch to 90 - (7.25 * SQRT(max((altitude - 250 - LaunchElev), 0)/1350)).
            }
            else {
                set targetpitch to 90 - (8.3 * SQRT(max((altitude - 250 - LaunchElev), 0)/1250)).
            }
        }
        else if KSRSS {
            if RESCALE {
                if ShipType = "Depot" {
                    set targetpitch to 90 - (8.125 * SQRT(max((altitude - 250 - LaunchElev), 0)/1400)).
                }
                else {
                    set targetpitch to 90 - (8.375 * SQRT(max((altitude - 250 - LaunchElev), 0)/1300)).
                }
            }
            else {
                if ShipType = "Depot" {
                    set targetpitch to 90 - (9.375 * SQRT(max((altitude - 250 - LaunchElev), 0)/1350)).
                }
                else {
                    set targetpitch to 90 - (9.625 * SQRT(max((altitude - 250 - LaunchElev), 0)/1250)).
                }
            }
        }
        else {
            if ShipType = "Depot" {
                set targetpitch to 90 - (6.5 * SQRT(max((altitude - 250 - LaunchElev), 0)/1350)).
            }
            else {
                set targetpitch to 90 - (11 * SQRT(max((altitude - 250 - LaunchElev), 0)/1250)).
            }
        }
        set result to lookdirup(heading(myAzimuth + 3 * TargetError, targetpitch):vector, LaunchRollVector).
    }
    else {
        set ProgradeAngle to 90 - vang(velocity:surface, up:vector).
        if RSS {
            if apoapsis > 1.05*TargetAp set OrbitBurnPitchCorrectionPID:setpoint to max(min((-altitude+TargetAp)/3000,24),-24).
            if CargoMass < 50000 set ProgradeAngle to ProgradeAngle * 0.9.
            else set ProgradeAngle to ProgradeAngle * 0.82.
        }
        if MaintainVS {
            if deltaV > 500*Scale {
                set OrbitBurnPitchCorrectionPID:setpoint to (targetap - altitude) / 100.
                if apoapsis > 1.05*TargetAp set OrbitBurnPitchCorrectionPID:setpoint to max(min((altitude-apoapsis)/3000,24),-24).
            }
            else {
                set OrbitBurnPitchCorrectionPID:setpoint to 0.
            }
            set OrbitBurnPitchCorrection to OrbitBurnPitchCorrectionPID:UPDATE(TIME:SECONDS, verticalspeed).
        }
        else {
            set OrbitBurnPitchCorrection to OrbitBurnPitchCorrectionPID:UPDATE(TIME:SECONDS, apoapsis).
        }
        

        print "Target Pitch: " + round(ProgradeAngle + OrbitBurnPitchCorrection, 1) + "°".
        print "Desired Accel: " + round(DesiredAccel / 9.81, 2) + "G".
        print "Ratio: " + round(DesiredAccel / MaxAccel, 2).
        print "Time to Orbit Completion: " + round(TimeToOrbitCompletion) + "s".
        print " ".
        print "Pitch: " + round(ship:facing:pitch).

        rcs on.
        set result to lookdirup(heading(myAzimuth + 3 * TargetError, ProgradeAngle + OrbitBurnPitchCorrection):vector, LaunchRollVector).
    }
    return result.
}


function LaunchLabelData {
    if not (LaunchLabelIsRunning) {
        set LaunchLabelIsRunning to true.
        set SteeringError to steeringmanager:angleerror.
        if kuniverse:timewarp:warp > 1 and altitude - LaunchElev > 500 and altitude - LaunchElev < 2500 {
            set kuniverse:timewarp:warp to 1.
        }
        if altitude - LaunchElev > 2000 and altitude - LaunchElev < 3000 and kuniverse:timewarp:warp = 1 {
            set kuniverse:timewarp:warp to 4.
        }
        else if apoapsis > BoosterAp - 8000*Scale {
            if not StageSepComplete {
                if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
            }
        }
        set DownRange to landingzone:distance / 1000.
        if altitude - LaunchElev < 500 {
            if not ClosingIsRunning {
                set message1:text to "<b>Actual/Target Apoapsis:</b>   " + round(apoapsis/1000,1) + "/" + round(targetap / 1000, 1) + "km".
                set message2:text to "<b>Guidance (Az./Pitch):</b>         " + round(myAzimuth + TargetError, 1) + "°/90°".
                set message3:text to "<b>Down Range:</b>                         " + round(DownRange, 1) + "km".
            }
        }
        else {
            if not ClosingIsRunning {
                set message1:text to "<b>Actual/Target Apoapsis:</b>   " + round(apoapsis/1000,1) + "/" + round(targetap / 1000, 1) + "km".
            }
            else {
                if defined Booster and not ClosingIsRunning {
                    if not Booster:isdead {
                        if Booster:status = "LANDED" {
                            set message3:text to "<b>Booster Landing Confirmed!</b>".
                        }
                        else {
                            set message3:text to "".
                            //set message3:text to "<b>Booster Alt / Spd:</b> " + round((Booster:altitude - landingzone:terrainheight) / 1000, 1) + "km / " + round(Booster:airspeed) + "m/s".
                        }
                    }
                    else {
                        set message3:text to "<b>Booster Loss of Signal..</b>".
                        set message3:style:textcolor to yellow.
                    }
                }
            }
            if Boosterconnected {
                if not ClosingIsRunning {
                    if abs(SteeringError) < 2.5 {
                        set message2:text to "<b>Guidance (Az./Pitch/Err):</b>  " + round(myAzimuth + TargetError, 1) + "°/" + round(targetpitch, 1) + "°/" + round(SteeringError, 1) + "°".
                    }
                    else if abs(SteeringError) < 35 {
                        set message2:text to "<b>Guidance (Az./Pitch/Err):</b>  " + round(myAzimuth + TargetError, 1) + "°/" + round(targetpitch, 1) + "°/<color=yellow>" + round(SteeringError, 1) + "°</color>".
                    }
                    else {
                        set message2:text to "<b>Guidance (Az./Pitch/Err):</b>  " + round(myAzimuth + TargetError, 1) + "°/" + round(targetpitch, 1) + "°/<color=red>" + round(SteeringError, 1) + "°</color>".
                    }
                    set message3:text to "<b>Down Range:</b>                         " + round(DownRange, 1) + "km".
                }
            }
            else {
                if not ClosingIsRunning {
                    if abs(SteeringError) < 2.5 {
                        set message2:text to "<b>Guidance (Az./Pitch/Err):</b>  " + round(myAzimuth + TargetError, 1) + "°/" + round(ProgradeAngle + OrbitBurnPitchCorrection, 1) + "°/" + round(SteeringError, 1) + "°".
                    }
                    else if abs(SteeringError) < 35 {
                        set message2:text to "<b>Guidance (Az./Pitch/Err):</b>  " + round(myAzimuth + TargetError, 1) + "°/" + round(ProgradeAngle + OrbitBurnPitchCorrection, 1) + "°/<color=yellow>" + round(SteeringError, 1) + "°</color>".
                    }
                    else {
                        set message2:text to "<b>Guidance (Az./Pitch/Err):</b>  " + round(myAzimuth + TargetError, 1) + "°/" + round(ProgradeAngle + OrbitBurnPitchCorrection, 1) + "°/<color=red>" + round(SteeringError, 1) + "°</color>".
                    }
                    if defined Booster and time:seconds > HotStageTime + 4 {
                        if not Booster:isdead {
                            if Booster:status = "LANDED" {
                                set message3:text to "<b>Booster Landing Confirmed!</b>".
                            }
                            else {
                                set message3:text to "".
                                //set message3:text to "<b>Booster Alt / Spd:</b>                " + round((Booster:altitude - landingzone:terrainheight) / 1000, 1) + "km / " + round(Booster:airspeed) + "m/s".
                            }
                        }
                        else {
                            set message3:text to "<b>Booster Loss of Signal..</b>".
                            set message3:style:textcolor to yellow.
                        }
                    }
                }
            }
        }
        if not (BurnComplete) {
            LogToFile("Launch Telemetry").
            if ship:name:contains("OrbitalLaunchMount") {
                set ship:name to ("Starship " + ShipType).
            }
            BackGroundUpdate().
        }
        set LaunchLabelIsRunning to false.
    }
}


FUNCTION LAZcalc_init {
    PARAMETER
        desiredAlt, //Altitude of desired target orbit (in *meters*)
        desiredInc. //Inclination of desired target orbit

    PARAMETER autoNodeEpsilon IS 10. // How many m/s north or south
        // will be needed to cause a north/south switch. Pass zero to disable
        // the feature.
    SET autoNodeEpsilon to ABS(autoNodeEpsilon).

    //We'll pull the latitude now so we aren't sampling it multiple times
    if not (ship:status = "FLYING") and not (ship:status = "SUB_ORBITAL") {
        set launchLatitude to SHIP:LATITUDE.
    }
    else {
        set launchLatitude to -0.0972.
    }

    LOCAL data IS LIST().   // A list is used to store information used by LAZcalc

    //Orbital altitude can't be less than sea level
    IF desiredAlt <= 0 {
        PRINT "Target altitude cannot be below sea level".
        SET launchAzimuth TO 1/0.		//Throws error
    }.

    //Determines whether we're trying to launch from the ascending or descending node
    LOCAL launchNode TO "Ascending".
    IF desiredInc < 0 {
        SET launchNode TO "Descending".

        //We'll make it positive for now and convert to southerly heading later
        SET desiredInc TO ABS(desiredInc).
    }.

    //Orbital inclination can't be less than launch latitude or greater than 180 - launch latitude
    IF ABS(launchLatitude) > desiredInc {
        SET desiredInc TO ABS(launchLatitude).
        //HUDTEXT("Inclination impossible from current latitude, setting inclination to: " + round(desiredInc, 2) + "°", 10, 2, 20, RED, FALSE).
        SaveToSettings("Launch Inclination", round(desiredInc, 2)).
        set setting3:text to (round(desiredInc, 2) + "°").
    }.

    IF 180 - ABS(launchLatitude) < desiredInc {
        SET desiredInc TO 180 - ABS(launchLatitude).
        //HUDTEXT("Inclination impossible from current latitude, setting inclination to: " + round(desiredInc, 2) + "°", 10, 2, 20, RED, FALSE).
        SaveToSettings("Launch Inclination", round(desiredInc, 2)).
        set setting3:text to (round(desiredInc, 2) + "°").
    }.

    //Does all the one time calculations and stores them in a list to help reduce the overhead or continuously updating
    LOCAL equatorialVel IS (2 * CONSTANT():Pi * BODY:RADIUS) / BODY:ROTATIONPERIOD.
    LOCAL targetOrbVel IS SQRT(BODY:MU/ (BODY:RADIUS + desiredAlt)).
    data:ADD(desiredInc).       //[0]
    data:ADD(launchLatitude).   //[1]
    data:ADD(equatorialVel).    //[2]
    data:ADD(targetOrbVel).     //[3]
    data:ADD(launchNode).       //[4]
    data:ADD(autoNodeEpsilon).  //[5]
    RETURN data.
}.

FUNCTION LAZcalc {
    PARAMETER
        data. //pointer to the list created by LAZcalc_init
    LOCAL inertialAzimuth IS ARCSIN(MAX(MIN(COS(data[0]) / COS(SHIP:LATITUDE), 1), -1)).
    LOCAL VXRot IS data[3] * SIN(inertialAzimuth) - data[2] * COS(data[1]).
    LOCAL VYRot IS data[3] * COS(inertialAzimuth).

    // This clamps the result to values between 0 and 360.
    LOCAL Azimuth IS MOD(ARCTAN2(VXRot, VYRot) + 360, 360).

    IF data[5] {
        LOCAL NorthComponent IS VDOT(SHIP:VELOCITY:ORBIT, SHIP:NORTH:VECTOR).
        IF NorthComponent > data[5] {
            SET data[4] TO "Ascending".
        }
        ELSE IF NorthComponent < -data[5] {
            SET data[4] to "Descending".
        }.
    }.

    //Returns northerly azimuth if launching from the ascending node
    IF data[4] = "Ascending" {
        RETURN Azimuth.

    //Returns southerly azimuth if launching from the descending node
    }
    ELSE IF data[4] = "Descending" {
        IF Azimuth <= 90 {
            RETURN 180 - Azimuth.

        }
        ELSE IF Azimuth >= 270 {
            RETURN 540 - Azimuth.

        }.
    }.
}.



//-------------------Abort Program----------------------//



Function AbortLaunch {
    if not LandButtonIsRunning {
        unlock steering.
        set AbortLaunchInProgress to true.
        lock throttle to 1.
        rcs on.
        set LaunchButtonIsRunning to false.
        if Boosterconnected {
            if not BoosterSingleEngines BoosterEngines[0]:shutdown.
            else {
                for eng in BoosterSingleEnginesRB eng:shutdown.
                for eng in BoosterSingleEnginesRC eng:shutdown.
            }
            wait 0.1.
            HSR[0]:getmodule("ModuleDockingNode"):doaction("undock node", true).
            Tank:getmodule("ModuleDockingNode"):doaction("undock node", true).
            wait 0.1.
            if Tank:getmodule("ModuleDockingNode"):hasaction("undock node") {
                Tank:getmodule("ModuleDockingNode"):doaction("undock node", true).
            }
            set Boosterconnected to false.
        }
        set runningprogram to "Launch Abort!".
        set cancelconfirmed to false.
        LogToFile("AbortLaunching!!").
        set message1:text to "Emergency Escape from Booster!".
        set message2:text to "".
        set message3:text to "".
        HideEngineToggles(0).

        set message1:style:textcolor to red.
        set launchlabel:style:textcolor to red.
        set cancel:text to "<b>CANCEL</b>".
        InhibitButtons(1, 1, 1).
        ShutDownAllEngines().
        wait 0.001.
        set quickengine2:pressed to true.
        set quickengine3:pressed to true.
        if ship:partsnamed("SEP.23.BOOSTER.HSR"):length > 0 or ship:partsnamed("SEP.25.BOOSTER.HSR"):length > 0 or ship:partsnamed("VS.25.HSR.BL3"):length > 0 {
            HSR[0]:getmodule("ModuleDockingNode"):doaction("undock node", true).
            HSR[0]:getmodule("ModuleDecouple"):doaction("Decouple", true).
            Tank:getmodule("ModuleDockingNode"):doaction("undock node", true).
            wait 0.1.
            if Tank:getmodule("ModuleDockingNode"):hasaction("undock node") {
                Tank:getmodule("ModuleDockingNode"):doaction("undock node", true).
            }
        }
        if ShipType:contains("Block1") {} else Nose:activate.
        Tank:activate.
        if apoapsis < 2500 {
            set AbortLaunchMode to "Early AbortLaunch".
            lock steering to heading(90, 85).
        }
        else if apoapsis < 30000 {
            set AbortLaunchMode to "Intermediate AbortLaunch".
            set quickstatus1:pressed to true.
            lock steering to ship:prograde.
        }
        else {
            set AbortLaunchMode to "Late AbortLaunch".
            lock steering to ship:prograde.
        }
        wait 2.
        lock steering to AbortLaunchSteering().

        if AbortLaunchMode = "Early AbortLaunch" {
            LogToFile("Early AbortLaunch").
            set message1:text to "<b>Thrusting away from the Booster..</b>".
            set message3:text to "<b>Venting in Progress..</b>".
            until apoapsis > 30000 or LFShip < FuelVentCutOffValue {}
            ShutDownAllEngines().
            lock throttle to 0.
            set message1:text to "<b>Venting until Main Tanks empty..</b>".
            wait 0.1.
            if ShipType:contains("Block1") HeaderTank:activate.
            else if not ShipType:contains("EXP") Nose:activate.
            Tank:activate.
            until LFShip < FuelVentCutOffValue {}
            ShutDownAllEngines().
            wait 0.001.
            ShutDownAllEngines()..
            until verticalspeed < 0 {}
            set message3:text to "".
            ShowHomePage().
            InhibitButtons(0, 1, 1).
            set message1:text to "".
            set message1:style:textcolor to white.
            set message3:text to "<b>Manual Control in 3 seconds..</b>".
            wait 1.
            set message3:text to "<b>Manual Control in 2 seconds..</b>".
            wait 1.
            set message3:text to "<b>Manual Control in 1 seconds..</b>".
            wait 1.
            unlock steering.
            set attitudebutton:pressed to true.
            set message1:text to "".
            set message2:text to "".
            set message3:text to "".
            set AbortLaunchComplete to true.
            set quickattitude2:pressed to true.
        }

        if AbortLaunchMode = "Intermediate AbortLaunch" {
            LogToFile("Intermediate AbortLaunch").
            set message1:text to "<b>Thrusting away from the Booster..</b>".
            set message3:text to "<b>Venting in Progress..</b>".
            until apoapsis > 40000 or LFShip < FuelVentCutOffValue {}
            ShutDownAllEngines().
            lock throttle to 0.
            set message1:text to "<b>Venting until Main Tanks empty..</b>".
            wait 0.1.
            Nose:activate.
            Tank:activate.
            until LFShip < FuelVentCutOffValue {}
            ShutDownAllEngines().
            wait 0.001.
            ShutDownAllEngines()..
            until verticalspeed < 0 {}
            set message3:text to "".
            ShowHomePage().
            InhibitButtons(0, 1, 1).
            set message1:text to "".
            set message1:style:textcolor to white.
            set message3:text to "<b>Manual Control in 3 seconds..</b>".
            wait 1.
            set message3:text to "<b>Manual Control in 2 seconds..</b>".
            wait 1.
            set message3:text to "<b>Manual Control in 1 seconds..</b>".
            wait 1.
            unlock steering.
            set attitudebutton:pressed to true.
            set message1:text to "".
            set message2:text to "".
            set message3:text to "".
            set AbortLaunchComplete to true.
            set quickattitude2:pressed to true.
        }

        if AbortLaunchMode = "Late AbortLaunch" {
            LogToFile("Late AbortLaunch").
            set message1:text to "<b>Thrusting away from the Booster..</b>".
            set message3:text to "<b>Venting in Progress..</b>".
            until apoapsis > 60000 or LFShip < FuelVentCutOffValue {}
            ShutDownAllEngines().
            lock throttle to 0.
            set message1:text to "<b>Venting until Main Tanks empty..</b>".
            wait 0.1.
            Nose:activate.
            Tank:activate.
            until LFShip < FuelVentCutOffValue {}
            ShutDownAllEngines().
            wait 0.001.
            ShutDownAllEngines()..
            until verticalspeed < 0 {}
            set message3:text to "".
            ShowHomePage().
            InhibitButtons(0, 1, 1).
            set message1:text to "".
            set message1:style:textcolor to white.
            set message3:text to "<b>Manual Control in 3 seconds..</b>".
            wait 1.
            set message3:text to "<b>Manual Control in 2 seconds..</b>".
            wait 1.
            set message3:text to "<b>Manual Control in 1 seconds..</b>".
            wait 1.
            unlock steering.
            set attitudebutton:pressed to true.
            set message1:text to "".
            set message2:text to "".
            set message3:text to "".
            set AbortLaunchComplete to true.
            set quickattitude2:pressed to true.
        }

        wait until AbortLaunchComplete.
        LogToFile("AbortLaunch Complete").
        set AbortLaunchInProgress to false.
        ClearInterfaceAndSteering().
    }
}


Function AbortLaunchSteering {
    if AbortLaunchMode = "Early AbortLaunch" {
        if throttle = 1 {
            set result to heading(90, 85).
            set message2:text to "<b>Steering: </b>85° pitch".
        }
        else if verticalspeed > 0 {
            set result to velocity:surface.
            set message2:text to "<b>Steering: </b>Surface Velocity".
        }
        else {
            set result to velocity:surface * R(0, 60, 0).
            set message2:text to "<b>Steering: </b>60° AoA".
            if quickstatus1:pressed = False {
                set quickstatus1:pressed to true.
            }
            rcs on.
        }
    }
    if AbortLaunchMode = "Intermediate AbortLaunch" {
        set result to heading(90, 85).
        set message2:text to "<b>Steering: </b>85° pitch".
    }
    if AbortLaunchMode = "Late AbortLaunch" {
        set result to ship:prograde * R(-10, 0, 0).
        set message2:text to "<b>Steering: </b>Prograde + 10°".
    }
    BackGroundUpdate().
    return result.
}




    
function sendMessage {
    parameter ves, msg.
    set cnx to ves:connection.
    if cnx:isconnected {
        if cnx:sendmessage(msg) {
            if msg = "ping" {}
            else {
                print "message sent: (" + msg + ")".
                if defined message32 {
                    set message32:style:bg to "starship_img/starship_signal_green".
                }
                set LastMessageSentTime to time:seconds.
            }
        }
        else {
            print "message could not be sent!! (" + msg + ")".
            HUDTEXT("Sending a Message failed!", 10, 2, 20, red, false).
            if defined message32 {
                set message32:style:bg to "starship_img/starship_signal_red".
            }
            set LastMessageSentTime to time:seconds.
        }.
    }
    else {
        print "connection could not be established..".
        HUDTEXT("Sending a Message failed due to Connection problems..", 10, 2, 20, red, false).
        if defined message32 {
            set message32:style:bg to "starship_img/starship_signal_red".
        }
        set LastMessageSentTime to time:seconds.
    }
}
//--------------Update Functions------------------------------//
function updatestatusbar {

    
    if not (StatusBarIsRunning) {
        set StatusBarIsRunning to true.
        for res in ship:resources {
            if res:name = "ElectricCharge" {
                set ELECcap to res:capacity.
            }
        }
        set status1:text to "<b>Active: </b>" + runningprogram.
        if defined status1 {
            if runningprogram = "None" or runningprogram = "Checking System.." or runningprogram = "System OK" {
                set status1:style:textcolor to white.
            }
            else if runningprogram = "Input" or runningprogram = "Override" {
                set status1:style:textcolor to cyan.
            }
            else if runningprogram = "Launch Abort!" or runningprogram = "Self-Test Failed"{
                set status1:style:textcolor to red.
            }
            else {
                set status1:style:textcolor to green.
            }
            if runningprogram = "Launch" and alt:radar > 500 {
                set status1:text to status1:text + " (" + round(altitude/1000, 1) + "km)".
            }
        }
        for res in Tank:resources {
            if res:name = "LiquidFuel" {
                set LFShip to res:amount.
                set LFShipCap to res:capacity.
            }
            if res:name = "LqdMethane" {
                set LFShip to res:amount.
                set LFShipCap to res:capacity.
            }
            if res:name = "Oxidizer" {
                set OxShip to res:amount.
                set OxShipCap to res:capacity.
            }
            if not (res:enabled) {
                set res:enabled to true.
            }
        }
        if defined HeaderTank {
            for res in HeaderTank:resources {
                if res:name = "LiquidFuel" {
                    set LFShip to LFShip + res:amount.
                    set LFShipCap to LFShipCap + res:capacity.
                }
                if res:name = "LqdMethane" {
                    set LFShip to LFShip + res:amount.
                    set LFShipCap to LFShipCap + res:capacity.
                }
                if res:name = "Oxidizer" {
                    set OxShip to OxShip + res:amount.
                    set OxShipCap to OxShipCap + res:capacity.
                }
                if not (res:enabled) {
                    set res:enabled to true.
                }
            }
            set FuelMass to (Tank:mass - Tank:drymass) + (HeaderTank:mass - HeaderTank:drymass).
            if FuelMass = 0 {
                set FuelMass to 0.001.
            }
        }
        else {
            set FuelMass to Tank:mass - Tank:drymass.
            if FuelMass = 0 {
                set FuelMass to 0.001.
            }
        }

        if SLEngines[0]:ignition and not (VACEngines[0]:ignition) {
            set EngineISP to 327.
        }
        else if VACEngines[0]:ignition and not (SLEngines[0]:ignition) {
            set EngineISP to 378.
        }
        else if SLEngines[0]:ignition and VACEngines[0]:ignition {
            set EngineISP to 352.5.
        }
        else {
            set EngineISP to 327.
        }
        if FuelMass = 0 {
            set FuelMass to 0.001.
        }
        if DeltaVCheck and not docked and (ShipMass - FuelMass*1000 > 0) {set currentdeltav to round(9.81 * EngineISP * ln(ShipMass / (ShipMass - (FuelMass * 1000)))).} 
        if currentdeltav > 275 {set status2:style:textcolor to white.}
        else if currentdeltav < 250 {set status2:style:textcolor to red.}
        else {set status2:style:textcolor to yellow.}
        if SLEngines[0]:ignition and not (VACEngines[0]:ignition) {
            set status2:text to "<b>ΔV: </b>" + currentdeltav + "m/s <b><size=12>@SL</size></b>".
        }
        else if VACEngines[0]:ignition and not (SLEngines[0]:ignition) {
            set status2:text to "<b>ΔV: </b>" + currentdeltav + "m/s <b><size=12>@VAC</size></b>".
        }
        else if SLEngines[0]:ignition and VACEngines[0]:ignition {
            set status2:text to "<b>ΔV: </b>" + currentdeltav + "m/s".
        }
        else {
            set status2:text to "<b>ΔV: </b>" + currentdeltav + "m/s <b><size=12>@SL</size></b>".
        }
        set bat to round(100 * (ship:electriccharge / ELECcap), 2).
        if bat < 25 and bat > 15 {
            set status3:style:textcolor to yellow.
            set status3:style:bg to "starship_img/starship_battery".
        }
        if bat < 15 {
            set status3:style:textcolor to red.
            set status3:style:bg to "starship_img/starship_battery_red".
        }
        else {
            set status3:style:textcolor to white.
            set status3:style:bg to "starship_img/starship_battery".
        }
        set status3:text to (bat):tostring + "%      ".
        if tooltip:text = "" {
            status1:show().
            status2:show().
            status3:show().
            set tooltip:style:margin:left to 0.
        }
        else {
            if not setting2:pressed {
                status1:hide().
                status2:hide().
                status3:hide().
                set tooltip:style:margin:left to 10.
                tooltip:show().
            }
            else {
                tooltip:hide().
                status1:show().
                status2:show().
                status3:show().
            }
        }
        if homeconnection:isconnected {
            set message32:style:textcolor to white.
            if time:seconds < LastMessageSentTime + 5 {}
            else {
                set message32:style:bg to "starship_img/starship_signal_white".
            }
            if Logging {
                set message32:text to "          COM1/TLM".
            }
            else {
                set message32:text to "          COM1/DLK".
            }
        }
        else {
            set message32:style:textcolor to yellow.
            if time:seconds < LastMessageSentTime + 5 {}
            else {
                set message32:style:bg to "starship_img/starship_signal_grey".
            }
            set message32:text to "          NO COM/-".
        }
        if ShipType = "Crew" {
            if CargoMass = 0 {
                set message12:text to "          " + ship:crew:length + " CREW".
                set message12:style:textcolor to white.
                set message12:style:bg to "starship_img/starship_crew_male_small".
                set message12:style:overflow:right to 0.
            }
            else {
                set message12:text to "          " + ship:crew:length + "           " + round(CargoMass/1000) + "T".
                set message12:style:textcolor to white.
                set message12:style:bg to "starship_img/starship_crew_and_cargo".
                set message12:style:overflow:right to 65.
            }
        }
        else {
            set message12:style:overflow:right to 0.
            if CargoMass = 0 {
                set message12:text to "          0 kg".
                set message12:style:textcolor to grey.
                if ShipType = "Tanker" or ShipType = "Depot" {
                    set message12:style:bg to "starship_img/starship_fuel_grey".
                }
                else {
                    set message12:style:bg to "starship_img/starship_cargo_box_grey".
                }
            }
            else {
                if CargoMass > 100000 {
                    set message12:text to "          " + round(CargoMass / 1000) + " T".
                }
                else {
                    set message12:text to "          " + round(CargoMass) + " kg".
                }
                set message12:style:textcolor to white.
                if ShipType = "Tanker" or ShipType = "Depot" {
                    set message12:style:bg to "starship_img/starship_fuel".
                }
                else {
                    set message12:style:bg to "starship_img/starship_cargo_box".
                }
            }
        }
        if ShipType = "Tanker" or ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1Exp" {
            cargobutton:hide().
        }
        else {
            cargobutton:show().
        }
        if defined watchdog {
            if Watchdog:Mode = "READY" and avionics = 3 {
                if not (TargetOLM = "False") and LandButtonIsRunning {
                    set message22:style:bg to "starship_img/starship_chip_magenta".
                    set message22:style:textcolor to magenta.
                    set message22:text to "          OLM/CH1".
                }
                else {
                    set message22:style:bg to "starship_img/starship_chip".
                    set message22:style:textcolor to white.
                    set message22:text to "          AVNCS 3/3".
                }
            }
            else if avionics = 3 {
                set message22:style:bg to "starship_img/starship_chip_grey".
                set message22:style:textcolor to grey.
            }
            else {
                set message22:style:bg to "starship_img/starship_chip_yellow".
                set message22:style:textcolor to yellow.
            }
        }
        else {
            set message22:style:bg to "starship_img/starship_chip_grey".
            set message22:style:textcolor to white.
        }
        set StatusBarIsRunning to false.
    }
}


function updateStatus {
    if not StatusPageIsRunning {
        set StatusPageIsRunning to true.
        if not (ShipType = "Expendable") and not (ShipType = "Depot") and not (ShipType = "Block1CargoExp") and not (ShipType = "Block1Exp") and not (ShipType = "Block1PEZExp") {
            if FLflap:getmodule("ModuleSEPControlSurface"):GetField("Deploy") {
                if defined FL {}
                else {
                    set FL to FLflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle").
                    set FR to FRflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle").
                    set AL to ALflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle").
                    set AR to ARflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle").
                    set FlapAuthority to FLflap:getmodule("ModuleSEPControlSurface"):GetField("authority limiter").
                }
                if defined Fpitch {
                    if SLEngines[0]:ignition {
                        set Fpitch to SLEngines[0]:gimbal:pitchangle * FlapAuthority.
                        set Fyaw to SLEngines[0]:gimbal:yawangle * FlapAuthority.
                        set Froll to SLEngines[0]:gimbal:rollangle * (FlapAuthority / 3).
                    }
                    else {
                        set Fpitch to ship:control:pilotpitch * FlapAuthority.
                        set Fyaw to ship:control:pilotyaw * FlapAuthority.
                        set Froll to ship:control:pilotroll * (FlapAuthority / 3).
                    }
                }
                else {
                    set Fpitch to 0.000001.
                    set Fyaw to 0.
                    set Froll to 0.
                }
                if not FlapsYawEngaged {
                    set Fyaw to 0.
                }

                set FLold to FL.
                set FRold to FR.
                set ALold to AL.
                set ARold to AR.

                set FLchange to - Fpitch + Fyaw - Froll.
                set FRchange to - Fpitch - Fyaw + Froll.
                set ALchange to Fpitch - Fyaw - Froll.
                set ARchange to Fpitch + Fyaw + Froll.

                set FLcommand to FLflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle") + FLchange.
                set FRcommand to FRflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle") + FRchange.
                set ALcommand to ALflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle") + ALchange.
                set ARcommand to ARflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle") + ARchange.

                set FL to FLold + ((FLcommand - FLold) / 5).
                set FR to FRold + ((FRcommand - FRold) / 5).
                set AL to ALold + ((ALcommand - ALold) / 5).
                set AR to ARold + ((ARcommand - ARold) / 5).

                set FWDdownlim to FLflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle") - FlapAuthority.
                set FWDuplim to FLflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle") + FlapAuthority.
                set AFTdownlim to ALflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle") - FlapAuthority.
                set AFTuplim to ALflap:getmodule("ModuleSEPControlSurface"):GetField("deploy angle") + FlapAuthority.

                if FL < max(FWDdownlim, 0) {set FL to max(FWDdownlim, 0).} if FL > min(FWDuplim, 78) {set FL to min(FWDuplim, 78).}
                if FR < max(FWDdownlim, 0) {set FR to max(FWDdownlim, 0).} if FR > min(FWDuplim, 78) {set FR to min(FWDuplim, 78).}
                if AL < max(AFTdownlim, 0) {set AL to max(AFTdownlim, 0).} if AL > min(AFTuplim, 70) {set AL to min(AFTuplim, 70).}
                if AR < max(AFTdownlim, 0) {set AR to max(AFTdownlim, 0).} if AR > min(AFTuplim, 70) {set AR to min(AFTuplim, 70).}

                set status1label1:text to round(FL):tostring + "°".
                set status1label3:text to round(FR):tostring + "°".
                set status3label1:text to round(AL):tostring + "°".
                set status3label3:text to round(AR):tostring + "°".
            }
            else {
                set status1label1:text to "0°".
                set status1label3:text to "0°".
                set status3label1:text to "0°".
                set status3label3:text to "0°".
                set status1label1:style:textcolor to white.
                set status1label3:style:textcolor to white.
                set status3label1:style:textcolor to white.
                set status3label3:style:textcolor to white.
                set status1label2:style:textcolor to white.
            }
        }
        else {
            set status1label1:text to "-°".
            set status1label3:text to "-°".
            set status3label1:text to "-°".
            set status3label3:text to "-°".
            set status1label1:style:textcolor to grey.
            set status1label3:style:textcolor to grey.
            set status3label1:style:textcolor to grey.
            set status3label3:style:textcolor to grey.
            set status1label2:style:textcolor to grey.
        }
        set PrevUpdateTime to time:seconds.

        if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
            set status2label2:style:bg to "starship_img/starship_symbol_no_flaps".
        }
        else if FLflap:getmodule("ModuleSEPControlSurface"):GetField("Deploy") = true {
            if runningprogram = "De-orbit & Landing" or runningprogram = "Final Approach" or runningprogram = "Landing" or runningprogram = "After Landing" or runningprogram = "Attitude (Landing Armed)" {
                set status2label2:style:bg to "starship_img/starship_symbol_flaps_magenta".
            }
            else {
                set status2label2:style:bg to "starship_img/starship_symbol_flaps_cyan".
            }
        }
        else {
            set status2label2:style:bg to "starship_img/starship_symbol".
        }

        if ship:status = "PRELAUNCH" or ship:status = "LANDED" {set status1label4:text to "<b>AoA:</b>  0°".}
        else{set status1label4:text to "<b>AoA:</b>  " + round(vang(ship:facing:forevector, velocity:surface), 1) + "°".}
        if altitude < body:atm:height {
            set MachNr to airspeed / (airspeed / (sqrt(2 / 1.4 * max(ship:q, 0.000001) / max(body:atm:altitudepressure(altitude), 0.000001)))).
            if MachNr > 0.5 {
                set status4label4:text to "<b>MACH:</b>  " + round(MachNr, 2).
            }
            else {
                set status4label4:text to "<b>GSPD:</b>  " + round(groundspeed) + "m/s".
            }
        }
        if altitude > 0.75 * body:atm:height {
            set status4label4:text to "<b>OSPD:</b>  " + round(ship:velocity:orbit:mag) + "m/s".
        }
        
        set currVel to SHIP:VELOCITY:ORBIT.
        local timeDelta to time:seconds - prevACCTime.
        if timeDelta <> 0 {
            set totalacc to (currVel:mag - prevVel:mag) * (1 / timeDelta) / 9.81.
            set acc to (currVel - prevVel) * (1 / timeDelta) + UP:FOREVECTOR * (SHIP:BODY:MU / (SHIP:BODY:RADIUS + SHIP:ALTITUDE)^2).
        }
        set prevVel to SHIP:VELOCITY:ORBIT.
        set prevACCTime to TIME:SECONDS.
        set GForce to acc:mag / 9.81.
        if GForce < 0.08 {
            set status3label4:text to "<b>ACC:</b>  " + round(totalacc, 2) + "G".
        }
        else {
            set status3label4:text to "<b>ACC:</b>  " + round(GForce, 2) + "G".
        }
        if GForce > 3.02 and GForce < 4 {set status3label4:style:textcolor to yellow.}
        if GForce > 4 {set status3label4:style:textcolor to red.}
        if GForce < 3.02 {set status3label4:style:textcolor to white.}

        set DynamicQ to 100 * ship:q.
        if DynamicQ > 25 {
            set status2label4:style:textcolor to yellow.
        }
        else {
            set status2label4:style:textcolor to white.
        }
        set status2label4:text to "<b>Q:  </b>" + round(DynamicQ, 2) + "kPa".
        local LQFpct is 100 * (LFShip / LFShipCap).
        local OXpct is 100 * (OxShip / OxShipCap).
        if LQFpct > 10 {set status2label5:style:textcolor to grey.}
        if OXpct > 10 {set status3label5:style:textcolor to grey.}
        if LQFpct < 10 and LQFpct > 6 {set status2label5:style:textcolor to yellow.}
        if OXpct < 10 and OXpct > 6 {set status3label5:style:textcolor to yellow.}
        if LQFpct < 6 {set status2label5:style:textcolor to red.}
        if OXpct < 6 {set status3label5:style:textcolor to red.}
        if OnOrbitalMount {
            set status1label5:text to "<b>MASS:</b>  " + round(ship:mass - OLM:mass - TowerBase:mass - TowerCore:mass - Mechazilla:mass) + "t".
        }
        else if ShipMass < 999999 {
            set status1label5:text to "<b>MASS:</b>  " + round(ShipMass / 1000, 1) + "t".
        }
        else {
            set status1label5:text to "<b>MASS:</b>  " + round(ShipMass / 1000) + "t".
        }
        set status2label5:text to "<b>" + round(LQFpct, 1) + "% CH4</b>".
        if LQFpct < 20 {
            set status2label4:style:border:h to (LQFpct / 20) * 10.
            set status2label4:style:border:v to (LQFpct / 20) * 10.
            set status3label4:style:border:h to (LQFpct / 20) * 10.
            set status3label4:style:border:v to (LQFpct / 20) * 10.
        }
        else {
            set status2label4:style:border:h to 10.
            set status2label4:style:border:v to 10.
            set status3label4:style:border:h to 10.
            set status3label4:style:border:v to 10.
        }
        set status2label4:style:overflow:right to 25 + (LQFpct * 1.03).
        set status3label5:text to "<b>" + round(OXpct, 1) + "% LOX</b>".
        set status3label4:style:overflow:right to 25 + (OXpct * 1.03).
        set status4label5:text to "<b>VS:</b>  " + round(ship:verticalspeed, 1) + "m/s".
        set StatusPageIsRunning to false.
    }
}


function updateEnginePage {
    if not EnginePageIsRunning {
        set EnginePageIsRunning to true.
        if throttle < 0.2 {
            set throttleborder to (throttle / 0.2) * 10.
        }
        else {
            set throttleborder to 10.
        }
        if Boosterconnected {
            set engine1label1:text to "<b>SH Raptors</b>".
            set engine1label1:tooltip to "33 Super Heavy Raptor Engines".
            set engine1label5:tooltip to "Performance Status of the Super Heavy Raptor Engines".
            set engine1label2:tooltip to "Command Status of the Super Heavy Raptor Engines".
            set engine1label4:tooltip to "".
            set engine2label1:tooltip to "Thrust in kN of the Super Heavy Raptor Engines".
            set engine2label5:tooltip to "% of Fuel Remaining in the Booster CH4 & LOX tanks".
            set boosterfuel to 100 * (BoosterCore[0]:resources[2]:amount / BoosterCore[0]:resources[2]:capacity).
            if boosterfuel < 20 {
                set engine2label4:style:border:h to (boosterfuel / 20) * 10.
                set engine2label4:style:border:h to (boosterfuel / 20) * 10.
            }
            else {
                set engine2label4:style:border:h to 10.
                set engine2label4:style:border:h to 10.
            }
            set engine2label4:style:overflow:right to 39 + round(boosterfuel).
            set engine2label5:text to "<b>" + round(boosterfuel) + "% <size=12>CH4/LOX</size></b>".
            if BoosterEngines[0]:ignition and BoosterEngines[0]:thrust > 0 {
                set engine2label3:style:bg to "starship_img/booster_active".
                set engine1label1:style:textcolor to green.
                set engine1label2:style:textcolor to green.
                set engine1label2:text to "ON".
                set engine3label1:style:textcolor to magenta.
                set engine3label2:style:textcolor to magenta.
                set engine3label4:style:textcolor to magenta.
                set engine3label5:style:textcolor to magenta.
                set engine3label2:text to round(BoosterEngines[0]:gimbal:pitchangle * BoosterEngines[0]:gimbal:range) + "°".
                set engine3label4:text to round(BoosterEngines[0]:gimbal:yawangle * BoosterEngines[0]:gimbal:range) + "°".
                set engine2label1:text to round(BoosterEngines[0]:thrust):tostring + " kN".
                set engine2label1:style:overflow:right to min(-100 + (100 * (BoosterEngines[0]:thrust / max(BoosterEngines[0]:availablethrust, 0.000001))), 0).
                set engine2label1:style:border:h to throttleborder.
                set engine2label1:style:border:v to throttleborder.
                set engine1label5:text to "<b>33/33 OK</b>".
                set engine1label5:style:textcolor to green.
            }
            else if BoosterEngines[0]:ignition {
                set engine2label3:style:bg to "starship_img/booster_ready".
                set engine1label1:style:textcolor to cyan.
                set engine1label2:style:textcolor to cyan.
                set engine1label2:text to "SBY".
                set engine3label1:style:textcolor to magenta.
                set engine3label2:style:textcolor to magenta.
                set engine3label4:style:textcolor to magenta.
                set engine3label5:style:textcolor to magenta.
                set engine3label2:text to round(BoosterEngines[0]:gimbal:pitchangle * SLEngines[0]:gimbal:range) + "°".
                set engine3label4:text to round(BoosterEngines[0]:gimbal:yawangle * SLEngines[0]:gimbal:range) + "°".
                set engine2label1:text to round(BoosterEngines[0]:thrust):tostring + " kN".
                set engine2label1:style:overflow:right to -100.
                set engine2label1:style:border:h to 0.
                set engine2label1:style:border:v to 0.
                set engine1label5:text to "<b>33/33 Ready</b>".
                set engine1label5:style:textcolor to cyan.
            }
            else {
                set engine2label3:style:bg to "starship_img/booster_off".
                set engine1label1:style:textcolor to grey.
                set engine1label2:style:textcolor to grey.
                set engine1label2:text to "OFF".
                set engine3label1:style:textcolor to grey.
                set engine3label2:style:textcolor to grey.
                set engine3label4:style:textcolor to grey.
                set engine3label5:style:textcolor to grey.
                set engine2label1:text to round(BoosterEngines[0]:thrust):tostring + " kN".
                set engine2label1:style:overflow:right to -100.
                set engine2label1:style:border:h to 0.
                set engine2label1:style:border:v to 0.
                set engine3label2:text to "-".
                set engine3label4:text to "-".
                set engine1label5:text to "0/33 Ready".
                set engine1label5:style:textcolor to grey.
            }
        }
        else {
            set engine1label1:text to "<b>SL Raptors</b>".
            set engine1label5:text to "<b>VAC Raptors</b>".
            set engine1label1:tooltip to "Inner 3 Sea-Level Raptor Engines".
            set engine1label5:tooltip to "Outer 6 Vacuum Raptor Engines".
            set engine1label2:tooltip to "Status of the Sea-Level Raptor Engines".
            set engine1label4:tooltip to "Status of the Vacuum Raptor Engines".
            set engine2label1:tooltip to "Thrust in kN of the Sea-Level Raptor Engines".
            set engine2label5:tooltip to "Thrust in kN of the Vacuum Raptor Engines".
            if SLEngines[0]:ignition = false and VACEngines[0]:ignition = false and not (FourVacBrakingBurn) and not (TwoVacEngineLanding) {
                if ship:control:translation:z > 0 or ship:control:pilottranslation:z > 0 {
                    if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
                        set engine2label3:style:bg to "starship_img/starship_noflaps_rcs".
                    }
                    else if NrOfVacEngines = 6 {
                        set engine2label3:style:bg to "starship_img/starship_9engine_rcs".
                    }
                    if NrOfVacEngines = 3 {
                        set engine2label3:style:bg to "starship_img/starship_6engine_rcs".
                    }
                }
                else {
                    if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
                        set engine2label3:style:bg to "starship_img/starship_noflaps_none_active".
                    }
                    else if NrOfVacEngines = 6 {
                        set engine2label3:style:bg to "starship_img/starship_9engine_none_active".
                    }
                    if NrOfVacEngines = 3 {
                        set engine2label3:style:bg to "starship_img/starship_6engine_none_active".
                    }
                }
                set engine1label1:style:textcolor to white.
                set engine1label5:style:textcolor to white.
                set engine1label2:style:textcolor to grey.
                set engine1label2:text to "OFF".
                set engine1label4:style:textcolor to grey.
                set engine1label4:text to "OFF".
                set engine3label1:style:textcolor to grey.
                set engine3label2:style:textcolor to grey.
                set engine3label4:style:textcolor to grey.
                set engine3label5:style:textcolor to grey.
                set engine3label2:text to "-".
                set engine3label4:text to "-".
                set engine2label1:text to "SBY".
                set engine2label1:style:overflow:right to -100.
                set engine2label1:style:border:h to 0.
                set engine2label1:style:border:v to 0.
                set engine2label4:style:border:h to 0.
                set engine2label4:style:border:v to 0.
                set engine2label5:text to "SBY".
                if EngineTogglesHidden {
                    set engine2label4:style:overflow:right to 39.
                }
                else {
                    set engine2label4:style:overflow:right to 10.
                }
            }
            if SLEngines[0]:ignition = true and VACEngines[0]:ignition = false {
                if SLEngines[0]:thrust > 0 {
                    if SLEngines[1]:ignition = true and SLEngines[2]:ignition = true {
                        if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
                            set engine2label3:style:bg to "starship_img/starship_noflaps_sl_active".
                        }
                        else if NrOfVacEngines = 6 {
                            set engine2label3:style:bg to "starship_img/starship_9engine_sl_active".
                        }
                        if NrOfVacEngines = 3 {
                            set engine2label3:style:bg to "starship_img/starship_6engine_sl_active".
                        }
                    }
                    else if SLEngines[2]:ignition = true {
                        if NrOfVacEngines = 6 {
                            set engine2label3:style:bg to "starship_img/starship_9engine_2sl_active".
                        }
                        if NrOfVacEngines = 3 {
                            set engine2label3:style:bg to "starship_img/starship_6engine_2sl_active".
                        }
                    }
                    else {
                        if NrOfVacEngines = 6 {
                            set engine2label3:style:bg to "starship_img/starship_9engine_1sl_active".
                        }
                        if NrOfVacEngines = 3 {
                            set engine2label3:style:bg to "starship_img/starship_6engine_1sl_active".
                        }
                    }
                }
                else {
                    if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
                        set engine2label3:style:bg to "starship_img/starship_noflaps_sl_ready".
                    }
                    else if NrOfVacEngines = 6 {
                        set engine2label3:style:bg to "starship_img/starship_9engine_sl_ready".
                    }
                    if NrOfVacEngines = 3 {
                        set engine2label3:style:bg to "starship_img/starship_6engine_sl_ready".
                    }
                }
                set engine1label1:style:textcolor to cyan.
                set engine1label5:style:textcolor to white.
                set engine1label2:style:textcolor to cyan.
                set engine1label2:text to "ON".
                set engine1label4:style:textcolor to grey.
                set engine1label4:text to "OFF".
                set engine3label1:style:textcolor to magenta.
                set engine3label2:style:textcolor to magenta.
                set engine3label4:style:textcolor to magenta.
                set engine3label5:style:textcolor to magenta.
                set engine3label2:text to round(SLEngines[0]:gimbal:pitchangle * SLEngines[0]:gimbal:range) + "°".
                set engine3label4:text to round(SLEngines[0]:gimbal:yawangle * SLEngines[0]:gimbal:range) + "°".
                if SLEngines[1]:ignition = true and SLEngines[2]:ignition = true {
                    set engine2label1:text to round(3 * SLEngines[0]:thrust):tostring + " kN".
                }
                else if SLEngines[2]:ignition = true {
                    set engine2label1:text to round(2 * SLEngines[0]:thrust):tostring + " kN".
                }
                else {
                    set engine2label1:text to round(1 * SLEngines[0]:thrust):tostring + " kN".
                }
                set engine2label1:style:overflow:right to min(-100 + (100 * (SLEngines[0]:thrust / max(SLEngines[0]:availablethrust, 0.000001))), 0).
                set engine2label1:style:border:h to throttleborder.
                set engine2label1:style:border:v to throttleborder.
                set engine2label4:style:border:h to 0.
                set engine2label4:style:border:v to 0.
                if EngineTogglesHidden {
                    set engine2label4:style:overflow:right to 39.
                }
                else {
                    set engine2label4:style:overflow:right to 10.
                }
                set engine2label5:text to "SBY".
            }
            if SLEngines[0]:ignition = false and VACEngines[0]:ignition = true or FourVacBrakingBurn or TwoVacEngineLanding {
                if throttle > 0 {
                    if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
                        set engine2label3:style:bg to "starship_img/starship_noflaps_vac_active".
                    }
                    else if NrOfVacEngines = 6 {
                        if FourVacBrakingBurn {
                            set engine2label3:style:bg to "starship_img/starship_9engine_4vac_active".
                        }
                        else if TwoVacEngineLanding {
                            set engine2label3:style:bg to "starship_img/starship_9engine_2vac_active".
                        }
                        else {
                            set engine2label3:style:bg to "starship_img/starship_9engine_vac_active".
                        }
                    }
                    else {
                        set engine2label3:style:bg to "starship_img/starship_6engine_vac_active".
                    }
                }
                else {
                    if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
                        set engine2label3:style:bg to "starship_img/starship_noflaps_vac_ready".
                    }
                    else if NrOfVacEngines = 6 {
                        if FourVacBrakingBurn {
                            set engine2label3:style:bg to "starship_img/starship_9engine_4vac_ready".
                        }
                        else if TwoVacEngineLanding {
                            set engine2label3:style:bg to "starship_img/starship_9engine_2vac_ready".
                        }
                        else {
                            set engine2label3:style:bg to "starship_img/starship_9engine_vac_ready".
                        }
                    }
                    else {
                        set engine2label3:style:bg to "starship_img/starship_6engine_vac_ready".
                    }
                }
                set engine1label1:style:textcolor to white.
                set engine1label5:style:textcolor to cyan.
                set engine1label2:style:textcolor to grey.
                set engine1label2:text to "OFF".
                set engine1label4:style:textcolor to cyan.
                set engine1label4:text to "ON".
                set engine3label1:style:textcolor to grey.
                set engine3label2:style:textcolor to grey.
                set engine3label4:style:textcolor to grey.
                set engine3label5:style:textcolor to grey.
                set engine3label2:text to "-".
                set engine3label4:text to "-".
                set engine2label1:text to "SBY".
                set engine2label1:style:border:h to 0.
                set engine2label1:style:border:v to 0.
                set engine2label4:style:border:h to throttleborder.
                set engine2label4:style:border:v to throttleborder.
                set engine2label1:style:overflow:right to -100.
                if FourVacBrakingBurn {
                    set engine2label5:text to round(throttle * 4 * VACEngines[0]:availablethrust):tostring + " kN".
                }
                else if TwoVacEngineLanding {
                    set engine2label5:text to round(2 * FinalDescentEngines[0]:thrust):tostring + " kN".
                }
                else {
                    set engine2label5:text to round(NrOfVacEngines * VACEngines[0]:thrust):tostring + " kN".
                }
                if EngineTogglesHidden {
                    set engine2label4:style:overflow:right to min(39 + (100 * min(throttle, 1)), 139).
                }
                else {
                    set engine2label4:style:overflow:right to min(10 + (100 * min(throttle, 1)), 110).
                }
            }
            if SLEngines[0]:ignition = true and VACEngines[0]:ignition = true {
                if SLEngines[0]:thrust > 0 {
                    if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
                        set engine2label3:style:bg to "starship_img/starship_noflaps_all_active".
                    }
                    else if NrOfVacEngines = 6 {
                        set engine2label3:style:bg to "starship_img/starship_9engine_all_active".
                    }
                    if NrOfVacEngines = 3 {
                        set engine2label3:style:bg to "starship_img/starship_6engine_all_active".
                    }
                }
                else {
                    if ShipType = "Depot" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" {
                        set engine2label3:style:bg to "starship_img/starship_noflaps_all_ready".
                    }
                    else if NrOfVacEngines = 6 {
                        set engine2label3:style:bg to "starship_img/starship_9engine_all_ready".
                    }
                    if NrOfVacEngines = 3 {
                        set engine2label3:style:bg to "starship_img/starship_6engine_all_ready".
                    }
                }
                set engine1label1:style:textcolor to cyan.
                set engine1label5:style:textcolor to cyan.
                set engine1label2:style:textcolor to cyan.
                set engine1label2:text to "ON".
                set engine1label4:style:textcolor to cyan.
                set engine1label4:text to "ON".
                set engine3label1:style:textcolor to magenta.
                set engine3label2:style:textcolor to magenta.
                set engine3label4:style:textcolor to magenta.
                set engine3label5:style:textcolor to magenta.
                set engine3label2:text to round(SLEngines[0]:gimbal:pitchangle * SLEngines[0]:gimbal:range) + "°".
                set engine3label4:text to round(SLEngines[0]:gimbal:yawangle * SLEngines[0]:gimbal:range) + "°".
                set engine2label1:text to round(3 * SLEngines[0]:thrust):tostring + " kN".
                set engine2label1:style:border:h to throttleborder.
                set engine2label1:style:border:v to throttleborder.
                set engine2label4:style:border:h to throttleborder.
                set engine2label4:style:border:v to throttleborder.
                set engine2label1:style:overflow:right to min(-100 + (100 * (SLEngines[0]:thrust / max(SLEngines[0]:availablethrust, 0.000001))), 0).
                set engine2label5:text to round(3 * VACEngines[0]:thrust):tostring + " kN".
                if EngineTogglesHidden {
                    set engine2label4:style:overflow:right to min(39 + (100 * (VACEngines[0]:thrust / max(VACEngines[0]:availablethrust, 0.000001))), 139).
                }
                else {
                    set engine2label4:style:overflow:right to min(10 + (100 * (VACEngines[0]:thrust / max(VACEngines[0]:availablethrust, 0.000001))), 110).
                }
            }
        }
        set EnginePageIsRunning to false.
    }
}


function updateOrbit {
    if not OrbitPageIsRunning {
        set OrbitPageIsRunning to true.
        if ship:orbit:hasnextpatch {
            set period to 0.
        }
        else {
            set period to ship:orbit:period.
        }
        if ship:status = "LANDED" or ship:status = "PRELAUNCH" or ship:status = "SPLASHED" {
            set orbit1label1:text to "<b>Apoapsis:    -</b>".
            set orbit2label1:text to "<b>Periapsis:    -</b>".
            set orbit3label1:text to "<b>Period:         -</b>".
            set orbit1label2:text to "<b>Time to Ap:    -</b>".
            set orbit2label2:text to "<b>Time to Pe:    -</b>".
            set orbit3label2:text to "<b>Inclination:    -</b>".
        }
        else {
            if apoapsis > 9999999 {
                set orbit1label1:text to "<b>Apoapsis: </b>" + round(apoapsis / 1000) + "km".
            }
            else {
                set orbit1label1:text to "<b>Apoapsis: </b>" + round(apoapsis / 1000, 3) + "km".
            }
            if periapsis > 9999999 {
                set orbit2label1:text to "<b>Periapsis: </b>" + round(periapsis / 1000) + "km".
            }
            else {
                set orbit2label1:text to "<b>Periapsis: </b>" + round(periapsis / 1000, 3) + "km".
            }
            set orbit3label1:text to "<b>Period: </b>" + timeSpanCalculator(period).
            set orbit1label2:text to "<b>Time to Ap: </b>" + timeSpanCalculator(eta:apoapsis).
            set orbit2label2:text to "<b>Time to Pe: </b>" + timeSpanCalculator(eta:periapsis).
            set orbit3label2:text to "<b>Inclination: </b>" + round(ship:orbit:inclination, 3) + "°".
        }
        if hasnode {
            set orbit1label3:text to "       <b>" + timeSpanCalculator(nextnode:eta) + "</b>".
            set orbit2label3:text to "<b>ΔV: " + round(nextnode:deltav:mag, 1) + "m/s</b>".
            set orbit1label3:style:bg to "starship_img/starship_maneuver_node".
            set orbit1label3:style:textcolor to magenta.
            set orbit2label3:style:textcolor to magenta.}
        else {
            set orbit1label3:text to "".
            set orbit2label3:text to "<b>  -</b>".
            set orbit1label3:style:bg to "starship_img/starship_maneuver_node_grey".
            set orbit1label3:style:textcolor to grey.
            set orbit2label3:style:textcolor to grey.}
        if homeconnection:isconnected {
            if body:name = "Kerbin" {
                if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_kerbin_landed".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed > 0 or ship:status = "FLYING" and verticalspeed > 0 or LaunchButtonIsRunning {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_kerbin_launch".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed < 0 or ship:status = "FLYING" and verticalspeed < 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_kerbin_reentry".
                }
                else {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_kerbin".
                }
                set orbit3label3:style:textcolor to cyan.
                set orbit3label3:style:bg to "starship_img/starship_comms_cyan".
                set orbit3label3:text to "<b>      GPS/GPS</b>".
            }
            else if body:name = "Earth" {
                if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_earth_landed".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed > 0 or ship:status = "FLYING" and verticalspeed > 0 or LaunchButtonIsRunning {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_earth_launch".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed < 0 or ship:status = "FLYING" and verticalspeed < 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_earth_reentry".
                }
                else {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_earth".
                }
                set orbit3label3:style:textcolor to cyan.
                set orbit3label3:style:bg to "starship_img/starship_comms_cyan".
                set orbit3label3:text to "<b>      GPS/GPS</b>".
            }
            else if body:name = "Duna" {
                if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_duna_landed".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed > 0 or ship:status = "FLYING" and verticalspeed > 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_duna_launch".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed < 0 or ship:status = "FLYING" and verticalspeed < 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_duna_reentry".
                }
                else {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_duna".
                }
                set orbit3label3:style:textcolor to white.
                set orbit3label3:style:bg to "starship_img/starship_comms_celestial_nav".
                set orbit3label3:text to "<b>      CBN/CBN</b>".
            }
            else if body:name = "Mars" {
                if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_mars_landed".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed > 0 or ship:status = "FLYING" and verticalspeed > 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_mars_launch".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed < 0 or ship:status = "FLYING" and verticalspeed < 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_mars_reentry".
                }
                else {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_mars".
                }
                set orbit3label3:style:textcolor to white.
                set orbit3label3:style:bg to "starship_img/starship_comms_celestial_nav".
                set orbit3label3:text to "<b>      CBN/CBN</b>".
            }
            else if body:name = "Mun" {
                if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_mun_landed".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed > 0 or ship:status = "FLYING" and verticalspeed > 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_mun_launch".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed < 0 or ship:status = "FLYING" and verticalspeed < 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_mun_reentry".
                }
                else {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_mun".
                }
                set orbit3label3:style:textcolor to cyan.
                set orbit3label3:style:bg to "starship_img/starship_comms_cyan".
                set orbit3label3:text to "<b>      GPS/CBN</b>".
            }
            else if body:name = "Moon" {
                if ship:status = "LANDED" or ship:status = "PRELAUNCH" {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_moon_landed".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed > 0 or ship:status = "FLYING" and verticalspeed > 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_moon_launch".
                }
                else if ship:status = "SUB_ORBITAL" and verticalspeed < 0 or ship:status = "FLYING" and verticalspeed < 0 {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_moon_reentry".
                }
                else {
                    set orbit1label2:style:bg to "starship_img/orbit_page_background_moon".
                }
                set orbit3label3:style:textcolor to cyan.
                set orbit3label3:style:bg to "starship_img/starship_comms_cyan".
                set orbit3label3:text to "<b>      GPS/CBN</b>".
            }
            else {
                set orbit1label2:style:bg to "starship_img/orbit_page_background_transfer".
                set orbit3label3:style:textcolor to white.
                set orbit3label3:style:bg to "starship_img/starship_comms_celestial_nav".
                set orbit3label3:text to "<b>      CBN/CBN</b>".
            }
        }
        else {
            set orbit1label2:style:bg to "starship_img/orbit_page_background_unknown_transfer".
            set orbit3label3:style:textcolor to yellow.
            set orbit3label3:style:bg to "starship_img/starship_comms_grey".
            set orbit3label3:text to "<b>      IRS/IRS</b>".
        }
        set OrbitPageIsRunning to false.
    }
}


function updateCrew {
    if not CrewPageIsRunning {
        set CrewPageIsRunning to true.
        set CrewList to ship:crew.
        if CrewList:length > 0 {
            if CrewList[0]:gender = "male" {
                set crew1label1:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label1:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label1:text to CrewList[0]:name:split(" ")[0].
            set crew2label1:text to "".
            set crew2label1:style:bg to FindExperience(CrewList[0]:experience).
            if CrewList[0]:trait  = "Pilot" {
                set crew3label1:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[0]:trait  = "Engineer" {
                set crew3label1:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[0]:trait  = "Scientist" {
                set crew3label1:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label1:style:bg to "starship_img/starship_crew_grey".
            set crew2label1:text to "<b>1</b>".
            set crew3label1:style:bg to "".
            set crew2label1:style:bg to "".
            set crew1label1:text to "".
            set crew3label1:text to "".
        }
        if CrewList:length > 1 {
            if CrewList[1]:gender = "male" {
                set crew1label2:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label2:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label2:text to CrewList[1]:name:split(" ")[0].
            set crew2label2:text to "".
            set crew2label2:style:bg to FindExperience(CrewList[1]:experience).
            if CrewList[1]:trait  = "Pilot" {
                set crew3label2:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[1]:trait  = "Engineer" {
                set crew3label2:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[1]:trait  = "Scientist" {
                set crew3label2:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label2:style:bg to "starship_img/starship_crew_grey".
            set crew2label2:text to "<b>2</b>".
            set crew3label2:style:bg to "".
            set crew2label2:style:bg to "".
            set crew1label2:text to "".
            set crew3label2:text to "".
        }
        if CrewList:length > 2 {
            if CrewList[2]:gender = "male" {
                set crew1label3:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label3:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label3:text to CrewList[2]:name:split(" ")[0].
            set crew2label3:text to "".
            set crew2label3:style:bg to FindExperience(CrewList[2]:experience).
            if CrewList[2]:trait  = "Pilot" {
                set crew3label3:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[2]:trait  = "Engineer" {
                set crew3label3:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[2]:trait  = "Scientist" {
                set crew3label3:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label3:style:bg to "starship_img/starship_crew_grey".
            set crew2label3:text to "<b>3</b>".
            set crew3label3:style:bg to "".
            set crew2label3:style:bg to "".
            set crew1label3:text to "".
            set crew3label3:text to "".
        }
        if CrewList:length > 3 {
            if CrewList[3]:gender = "male" {
                set crew1label4:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label4:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label4:text to CrewList[3]:name:split(" ")[0].
            set crew2label4:text to "".
            set crew2label4:style:bg to FindExperience(CrewList[3]:experience).
            if CrewList[3]:trait  = "Pilot" {
                set crew3label4:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[3]:trait  = "Engineer" {
                set crew3label4:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[3]:trait  = "Scientist" {
                set crew3label4:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label4:style:bg to "starship_img/starship_crew_grey".
            set crew2label4:text to "<b>4</b>".
            set crew3label4:style:bg to "".
            set crew2label4:style:bg to "".
            set crew1label4:text to "".
            set crew3label4:text to "".
        }
        if CrewList:length > 4 {
            if CrewList[4]:gender = "male" {
                set crew1label5:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label5:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label5:text to CrewList[4]:name:split(" ")[0].
            set crew2label5:text to "".
            set crew2label5:style:bg to FindExperience(CrewList[4]:experience).
            if CrewList[4]:trait  = "Pilot" {
                set crew3label5:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[4]:trait  = "Engineer" {
                set crew3label5:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[4]:trait  = "Scientist" {
                set crew3label5:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label5:style:bg to "starship_img/starship_crew_grey".
            set crew2label5:text to "<b>5</b>".
            set crew3label5:style:bg to "".
            set crew2label5:style:bg to "".
            set crew1label5:text to "".
            set crew3label5:text to "".
        }
        if CrewList:length > 5 {
            if CrewList[5]:gender = "male" {
                set crew1label6:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label6:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label6:text to CrewList[5]:name:split(" ")[0].
            set crew2label6:text to "".
            set crew2label6:style:bg to FindExperience(CrewList[5]:experience).
            if CrewList[5]:trait  = "Pilot" {
                set crew3label6:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[5]:trait  = "Engineer" {
                set crew3label6:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[5]:trait  = "Scientist" {
                set crew3label6:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label6:style:bg to "starship_img/starship_crew_grey".
            set crew2label6:text to "<b>6</b>".
            set crew3label6:style:bg to "".
            set crew2label6:style:bg to "".
            set crew1label6:text to "".
            set crew3label6:text to "".
        }
        if CrewList:length > 6 {
            if CrewList[6]:gender = "male" {
                set crew1label7:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label7:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label7:text to CrewList[6]:name:split(" ")[0].
            set crew2label7:text to "".
            set crew2label7:style:bg to FindExperience(CrewList[6]:experience).
            if CrewList[6]:trait  = "Pilot" {
                set crew3label7:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[6]:trait  = "Engineer" {
                set crew3label7:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[6]:trait  = "Scientist" {
                set crew3label7:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label7:style:bg to "starship_img/starship_crew_grey".
            set crew2label7:text to "<b>7</b>".
            set crew3label7:style:bg to "".
            set crew2label7:style:bg to "".
            set crew1label7:text to "".
            set crew3label7:text to "".
        }
        if CrewList:length > 7 {
            if CrewList[7]:gender = "male" {
                set crew1label8:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label8:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label8:text to CrewList[7]:name:split(" ")[0].
            set crew2label8:text to "".
            set crew2label8:style:bg to FindExperience(CrewList[7]:experience).
            if CrewList[7]:trait  = "Pilot" {
                set crew3label8:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[7]:trait  = "Engineer" {
                set crew3label8:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[7]:trait  = "Scientist" {
                set crew3label8:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label8:style:bg to "starship_img/starship_crew_grey".
            set crew2label8:text to "<b>8</b>".
            set crew3label8:style:bg to "".
            set crew2label8:style:bg to "".
            set crew1label8:text to "".
            set crew3label8:text to "".
        }
        if CrewList:length > 8 {
            if CrewList[8]:gender = "male" {
                set crew1label9:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label9:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label9:text to CrewList[8]:name:split(" ")[0].
            set crew2label9:text to "".
            set crew2label9:style:bg to FindExperience(CrewList[8]:experience).
            if CrewList[8]:trait  = "Pilot" {
                set crew3label9:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[8]:trait  = "Engineer" {
                set crew3label9:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[8]:trait  = "Scientist" {
                set crew3label9:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label9:style:bg to "starship_img/starship_crew_grey".
            set crew2label9:text to "<b>9</b>".
            set crew3label9:style:bg to "".
            set crew2label9:style:bg to "".
            set crew1label9:text to "".
            set crew3label9:text to "".
        }
        if CrewList:length > 9 {
            if CrewList[9]:gender = "male" {
                set crew1label10:style:bg to "starship_img/starship_crew_male".
            }
            else {
                set crew1label10:style:bg to "starship_img/starship_crew_female".
            }
            set crew3label10:text to CrewList[9]:name:split(" ")[0].
            set crew2label10:text to "".
            set crew2label10:style:bg to FindExperience(CrewList[9]:experience).
            if CrewList[9]:trait  = "Pilot" {
                set crew3label10:style:bg to "starship_img/starship_crew_pilot".
            }
            if CrewList[9]:trait  = "Engineer" {
                set crew3label10:style:bg to "starship_img/starship_crew_engineer".
            }
            if CrewList[9]:trait  = "Scientist" {
                set crew3label10:style:bg to "starship_img/starship_crew_scientist".
            }
        }
        else {
            set crew1label10:style:bg to "starship_img/starship_crew_grey".
            set crew2label10:text to "<b>10</b>".
            set crew3label10:style:bg to "".
            set crew2label10:style:bg to "".
            set crew1label10:text to "".
            set crew3label10:text to "".
        }
        if time:seconds > prevFanTime + 0.5 {
            if fan {
                set crewlabel6:style:bg to "starship_img/fan_spinning_1".
                set fan to false.
            }
            else {
                set crewlabel6:style:bg to "starship_img/fan_spinning_2".
                set fan to true.
            }
            set TempPressVariations to time:seconds / 3600 - floor(time:seconds / 3600).
            set TempPressVariations to sin(TempPressVariations * 360).
            set crewlabel2:text to "<b>P:  <color=green>" + round(99.2 + (1.5 * TempPressVariations), 1) + " kPa</color></b>".
            set crewlabel3:text to "<b>T:   <color=green>" + round(22.3 - (1.5 * TempPressVariations), 1) + "°c</color></b>".
            if TempPressVariations > 0.5 and TempPressVariations < 0.75 {
                set crewlabel5:text to "<b>AQM:  <color=yellow>MED</color></b>".
            }
            else {
                set crewlabel5:text to "<b>AQM:  <color=green>OK</color></b>".
            }
            set prevFanTime to time:seconds.
        }
        set CrewPageIsRunning to false.
    }
}


function FindExperience {
    parameter experience.
    if experience = 0 {
        return "".
    }
    if experience = 1 {
        return "starship_img/starship_crew_1star".
    }
    if experience = 2 {
        return "starship_img/starship_crew_2star".
    }
    if experience = 3 {
        return "starship_img/starship_crew_3star".
    }
    if experience = 4 {
        return "starship_img/starship_crew_4star".
    }
    if experience = 5 {
        return "starship_img/starship_crew_5star".
    }
}



function BackGroundUpdate {
    if not BGUisRunning {
        set BGUisRunning to true.
        if prevCalcTime + 0.1 < time:seconds {
            SendPing().
            updatestatusbar().
            if time:seconds < LiftOffTime + 90*Scale {
                FindParts().
            } else if time:seconds < HotStageTime + 12 and apoapsis > BoosterAp {
                FindParts().
            }
            SetPlanetData().
            if ShipIsDocked {
                if Tank:getmodule("ModuleDockingNode"):hasevent("undock") {
                    if time:seconds - TimeSinceDock > 10 and not (TimeSinceDock = "0") {
                        InhibitButtons(0, 1, 0).
                        set cancel:text to "<b>UNDOCK</b>".
                        //print ship:dockingports[0]:partner.
                    }
                    else if TimeSinceDock = "0" {
                        set TimeSinceDock to time:seconds.
                    }
                }
                else if not ClosingIsRunning {
                    InhibitButtons(0, 1, 1).
                    set cancel:text to "<b>CANCEL</b>".
                }
                set ShipWasDocked to true.
            }
            else if ShipWasDocked {
                InhibitButtons(0, 1, 1).
                set cancel:text to "<b>CANCEL</b>".
                set ShipWasDocked to false.
            }
            if not (KUniverse:activevessel = PrevActiveStatus) {
                SetInterfaceLocation().
            }
            set PrevActiveStatus to KUniverse:activevessel.
            if ship:crew:length <> 0 and not CrewOnboard {
                set CrewOnboard to true.
                crewbutton:show().
            }
            else if ship:crew:length = 0 {
                set CrewOnboard to false.
                crewbutton:hide().
                set crewbutton:pressed to false.
            }
            if LaunchButtonIsRunning or LandButtonIsRunning or AttitudeIsRunning {
                maneuverbutton:hide().
                towerbutton:hide().
                scalebutton:hide().
                ScaleUI:hide().
                if AttitudeIsRunning {
                    if landbutton:visible {
                        landbutton:hide().
                        landlabel:show().
                    }
                }
            }
            else {
                if ship:status = "PRELAUNCH" or ship:status = "LANDED" or alt:radar < 200 {
                    if landbutton:visible {
                        landbutton:hide().
                        landlabel:show().
                    }
                    list targets in tlist.
                    for tgt in tlist {
                        if tgt:name:contains("OrbitalLaunchMount") and tgt:distance < 1800 and not (LaunchButtonIsRunning) and not (LandButtonIsRunning) or ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
                            towerbutton:show().
                            set TargetOLM to tgt:name.
                            break.
                        }
                    }
                    if TargetOLM = "False" {
                        towerbutton:hide().
                    }
                }
                else if landlabel:visible {
                    landlabel:hide().
                    landbutton:show().
                }
                if ship:status = "ORBITING" or ship:status = "ESCAPING" or ship:status = "SUB_ORBITAL" and apoapsis > 10000 or ship:status = "FLYING" and apoapsis > 50000 {
                    maneuverbutton:show().
                    if launchbutton:visible {
                        launchbutton:hide().
                        launchlabel:show().
                    }
                }
                else {
                    maneuverbutton:hide().
                    if launchlabel:visible {
                        launchlabel:hide().
                        launchbutton:show().
                    }
                }
            }
            if ship:body:atm:exists and not (ship:status = "PRELAUNCH") and not (ship:status = "LANDED") and alt:radar > 1000 {
                attitudebutton:show().
            }
            else {
                attitudebutton:hide().
            }
            set prevCalcTime to time:seconds.
        }
        if orbitbutton:pressed {updateOrbit().}
        if statusbutton:pressed {updateStatus().}
        if enginebutton:pressed {updateEnginePage().}
        if cargobutton:pressed {updateCargoPage().}
        if crewbutton:pressed {updateCrew().}
        if towerbutton:pressed {updateTower().}
        if maneuverbutton:pressed {updateManeuver().}
        set BGUisRunning to false.
    }
}





function setflaps {
    parameter angleFwd, angleAft, deploy, authority.
    if not (ShipType = "Expendable") and not (ShipType = "Depot") and not (ShipType = "Block1CargoExp") and not (ShipType = "Block1Exp") and not(ShipType = "Block1PEZExp") {
        if FLflap:hasmodule("ModuleSEPControlSurface") {
            FLflap:getmodule("ModuleSEPControlSurface"):SetField("Deploy", deploy).
        }
        FRflap:getmodule("ModuleSEPControlSurface"):SetField("Deploy", deploy).
        ALflap:getmodule("ModuleSEPControlSurface"):SetField("Deploy", deploy).
        ARflap:getmodule("ModuleSEPControlSurface"):SetField("Deploy", deploy).

        FLflap:getmodule("ModuleSEPControlSurface"):SetField("Deploy Angle", angleFwd).
        FRflap:getmodule("ModuleSEPControlSurface"):SetField("Deploy Angle", angleFwd).
        ALflap:getmodule("ModuleSEPControlSurface"):SetField("Deploy Angle", angleAft).
        ARflap:getmodule("ModuleSEPControlSurface"):SetField("Deploy Angle", angleAft).

        FLflap:getmodule("ModuleSEPControlSurface"):SetField("Authority Limiter", authority).
        FRflap:getmodule("ModuleSEPControlSurface"):SetField("Authority Limiter", authority).
        ALflap:getmodule("ModuleSEPControlSurface"):SetField("Authority Limiter", authority).
        ARflap:getmodule("ModuleSEPControlSurface"):SetField("Authority Limiter", authority).
    }
}




function AutoDocking {
    if target:name:contains("Body") {
        set target to target:ship.
    }
    set textbox:style:bg to "starship_img/starship_main_square_bg".
    set target:loaddistance:orbit:unload to 25000.
    set target:loaddistance:orbit:load to 10050.
    set target:loaddistance:orbit:unpack to 2100.
    set target:loaddistance:orbit:pack to 2250.
    wait 0.001.
    if not (target:loaded) {
        wait 1.
        if not (target:loaded) {
            return.
        }
    }

    if ShipIsDocked {
        return.
    }
    else if target:dockingports[0]:haspartner {
        set TargetPicker:index to 0.
        set AutodockingIsRunning to false.
        ShowHomePage().
        set message1:text to "<b>Targets docking port is already occupied..</b>".
        set message2:text to "<b>Try again later..</b>".
        set message3:text to "".
        set message1:style:textcolor to yellow.
        set message2:style:textcolor to yellow.
        set message3:style:textcolor to yellow.
        wait 3.
        ClearInterfaceAndSteering().
        return.
    }

    set AutodockingIsRunning to true.
    InhibitButtons(1,1,0).
    HideEngineToggles(1).
    ShowButtons(0).
    set dockingmode to "None".
    set launchlabel:style:textcolor to grey.
    set landlabel:style:textcolor to grey.
    set ship:control:translation to v(0, 0, 0).
    set message1:style:textcolor to white.
    set message1:style:textcolor to white.
    set message1:style:textcolor to white.
    set maneuver3button:enabled to false.
    set ManeuverPicker:enabled to false.
    set TargetPicker:enabled to false.
    ShowHomePage().
    set steeringmanager:pitchtorquefactor to 0.75.
    set steeringmanager:yawtorquefactor to 0.75.
    set steeringmanager:rolltorquefactor to 0.75.
    sas off.
    set Continue to false.
    if KUniverse:activevessel = vessel(ship:name) {}
    else {
        set KUniverse:activevessel to vessel(ship:name).
    }
    if Tank:getmodule("ModuleSepPartSwitchAction"):getfield("current docking system") = "BTB" {
        Tank:getmodule("ModuleSepPartSwitchAction"):DoAction("next docking system", true).
    }
    Tank:getmodule("ModuleDockingNode"):SETFIELD("docking acquire force", 0).
    if ShipType = "Depot" {
        set steeringmanager:yawtorquefactor to 0.1.
    }

    set PortDistanceVector to target:position - ship:position.
    print "Initial Facing error: " + vang(target:facing:topvector, PortDistanceVector) + " degrees".
    //set VectorDraw to vecdraw(target:dockingports[0]:nodeposition, 5 * target:facing:topvector, magenta, "", 20, true, 0.005, true, true).

    if vang(target:facing:topvector, PortDistanceVector) < 120 {
        print "Maneuvring to Intermediate Safe Point..".
        set dockingmode to "INTMD".
        DetermineSafeVector().
        lock steering to AutoDockSteering().
        until SafeVector:mag < 25 or vang(target:facing:topvector, PortDistanceVector) > 120 or cancelconfirmed {
            BackGroundUpdate().
        }
    }
    if PortDistanceVector:mag > 250 {
        print "Approaching Docking Port..".
        set dockingmode to "APPR".
        lock steering to AutoDockSteering().
        until PortDistanceVector:mag < 75 or cancelconfirmed {
            BackGroundUpdate().
        }
    }
    if PortDistanceVector:mag < 250 {
        print "Docking to Docking Port..".
        set dockingmode to "DOCK".
        lock steering to AutoDockSteering().
    }

    until ship:dockingports[0]:state = "Docked (docker)" or ship:dockingports[0]:state = "Docked (dockee)" or ship:dockingports[0]:state = "Docked (same vessel)" or cancelconfirmed {
        BackGroundUpdate().
        set t to time:seconds.
    }
    until time:seconds > t + 0.5 or cancelconfirmed {
        BackGroundUpdate().
    }
    if not (cancelconfirmed) {
        HUDTEXT("Docking confirmed!", 5, 2, 20, green, false).
    }
    else if dockingmode = "DOCK" {
        unlock steering.
        wait 0.001.
        lock steering to lookdirup(facing:forevector, facing:topvector).
        until abs(RelVelX) < 0.05 and abs(RelVelY) < 0.05 and abs(RelVelZ) < 0.05 {
            rcs on.
            if hastarget {
                set RelativeVelocityVector to target:velocity:orbit - ship:velocity:orbit.
            }
            set RelVelX to vdot(facing:forevector, RelativeVelocityVector).
            set RelVelY to vdot(facing:starvector, RelativeVelocityVector).
            set RelVelZ to vdot(facing:topvector, RelativeVelocityVector).
            set ship:control:translation to v(3 * RelVelY, 3 * RelVelZ, 3 * RelVelX).
            set message1:text to "<b>Cancelling Velocity..</b>".
            set message2:text to "".
            set message3:text to "".
            BackGroundUpdate().
        }
    }
    set maneuver3button:enabled to true.
    set ManeuverPicker:enabled to true.
    set ManeuverPicker:index to 0.
    set TargetPicker:enabled to true.
    unlock steering.
    Droppriority().
    HideEngineToggles(0).
    ShowButtons(1).
    set ship:control:translation to v(0, 0, 0).
    set AutodockingIsRunning to false.
    SetInterfaceLocation().
    rcs off.
    ClearInterfaceAndSteering().
}


function AutoDockSteering {
    set runningprogram to "Auto-Docking".
    SendPing().
    rcs on.
    set textbox:style:bg to "starship_img/starship_main_square_bg".
    if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
    if not (cancelconfirmed) {
        set status1:style:textcolor to green.
        set message1:text to "<b><color=green>Auto-Docking in Progress..</color></b>  <size=13><color=yellow>(DON'T CHANGE VESSEL)</color></size>".
    }

    if not (hastarget) and not (ship:dockingports[0]:haspartner) or PortDistanceVector:mag > 10000 {
        set TargetPicker:index to 0.
        if PortDistanceVector:mag > 10000 {
            print "Target too far away (>10km)..".
            HUDTEXT("Target too far away (>10km)..", 10, 2, 20, red, false).
        }
        else {
            print "Target lost..".
            HUDTEXT("Target lost..", 10, 2, 20, red, false).
        }
        set cancelconfirmed to true.
        return lookdirup(facing:forevector, facing:topvector).
    }
    if ship:dockingports[0]:haspartner and t = 0 {
        set TargetPicker:index to 0.
        return lookdirup(facing:forevector, facing:topvector).
    }
    if KUniverse:activevessel = vessel(ship:name) {}
    else {
        set KUniverse:activevessel to vessel(ship:name).
        HUDTEXT("Auto-Docking Cancelled!", 10, 2, 20, red, false).
        HUDTEXT("Switching ships not allowed during Auto-Docking..", 10, 2, 20, red, false).
        set cancelconfirmed to true.
        return lookdirup(facing:forevector, facing:topvector).
    }

    wait 0.001.
    if hastarget {
        if target:name:contains("Docking Port") or target:name:contains("Body") {
            set PortDistanceVector to target:position - ship:dockingports[0]:nodeposition.
        }
        else {
            if target:distance < 2000 {
                set PortDistanceVector to target:dockingports[0]:nodeposition - ship:dockingports[0]:nodeposition.
                if not (target:dockingports[0]:nodetype = "QD") {
                    HUDTEXT("Target docking mode not set to 'QD-QD'..", 15, 2, 22, red, false).
                    HUDTEXT("Please select 'QD-QD' manually..", 15, 2, 20, yellow, false).
                    print "Target docking mode not set to QD-QD..".
                    print "Please select 'QD-QD' manually..".
                    set cancelconfirmed to true.
                    return lookdirup(facing:forevector, facing:topvector).
                }
                if abs((target:position - ship:position):mag - (target:dockingports[0]:nodeposition - ship:dockingports[0]:nodeposition):mag) > 37.5 * scale {
                    set PortDistanceVector to target:position - ship:position.
                    if dockingmode = "DOCK" {
                        HUDTEXT("Docking Node error detected..", 15, 2, 22, red, false).
                        HUDTEXT("Please dock manually..", 15, 2, 20, yellow, false).
                        print "Docking Node error detected..".
                        set cancelconfirmed to true.
                        return lookdirup(facing:forevector, facing:topvector).
                    }
                }
            }
            else {
                set PortDistanceVector to target:position - ship:position.
            }
        }
    }
    //set PVectorDraw to vecdraw(ship:position, PortDistanceVector, yellow, "", 20, true, 0.005, true, true).

    set RelDistX to vdot(facing:forevector, PortDistanceVector).
    set RelDistY to vdot(facing:starvector, PortDistanceVector).
    set RelDistZ to vdot(facing:topvector, PortDistanceVector).
    wait 0.001.
    if hastarget {
        set RelativeVelocityVector to target:velocity:orbit - ship:velocity:orbit.
    }
    set RelVelX to vdot(facing:forevector, RelativeVelocityVector).
    set RelVelY to vdot(facing:starvector, RelativeVelocityVector).
    set RelVelZ to vdot(facing:topvector, RelativeVelocityVector).

    wait 0.001.
    if hastarget {
        clearscreen.
        print "Target Name: " + target:name.
        print "Docking Mode: " + dockingmode.
        print " ".
        if target:distance < 2000 {
            print "Ship   State: " + ship:dockingports[0]:state.
            print "Target State: " + target:dockingports[0]:state.
            print "Target Node:  " + target:dockingports[0]:nodetype.
            print " ".
        }
        print "Distance X: " + round(RelDistX, 2).
        print "Distance Y: " + round(RelDistY, 2).
        print "Distance Z: " + round(RelDistZ, 2).
        print " ".
        print "Velocity X: " + round(RelVelX, 2).
        print "Velocity Y: " + round(RelVelY, 2).
        print "Velocity Z: " + round(RelVelZ, 2).
        print " ".
        print "Target Distance: " + round((target:position - ship:position):mag, 1).
        print "D-Port Distance: " + round(PortDistanceVector:mag, 1).
        print "Node Distance:   " + round((target:dockingports[0]:nodeposition - ship:dockingports[0]:nodeposition):mag, 1).
        print " ".
        print "Target Loaded:   " + target:loaded.
        print "Target Unpacked: " + target:unpacked.
        //print "cancelconfirmed: " + cancelconfirmed.
    }

    if dockingmode = "INTMD" {
        set message2:text to "<b>Target:</b>  Intermediate Safe Point  (" + round(SafeVector:mag, 1) + "m)".
        set message3:text to "<b>Relative Velocity (m/s):   </b><size=14>X: " + round(RelVelX, 2) + "   Y: " + round(RelVelY,2) + "   Z: " + round(RelVelZ,2) + "</size>".
        DetermineSafeVector().
        if vang(SafeVector, facing:forevector) < 5 and abs(RelVelY) < 0.5 and abs(RelVelZ) < 0.5 {
            set ship:control:translation to v(RelVelY/2, RelVelZ/2, (min(5, (SafeVector:mag - 20) / 10) + SafeVector:mag / 400) + RelVelX).
        }
        else if vang(SafeVector, facing:forevector) < 5 {
            set ship:control:translation to v(RelVelY, RelVelZ, 0).
        }
        else {
            set ship:control:translation to v(0, 0, 0).
        }
        //set SVectorDraw to vecdraw(ship:position, SafeVector, green, "", 20, true, 0.005, true, true).
        return lookdirup(SafeVector, facing:topvector).
    }
    if dockingmode = "APPR" {
        set message2:text to "<b>Target:</b>  Docking Port  (" + round(PortDistanceVector:mag, 1) + "m)".
        set message3:text to "<b>Relative Velocity (m/s):   </b><size=14>X: " + round(RelVelX, 2) + "   Y: " + round(RelVelY,2) + "   Z: " + round(RelVelZ,2) + "</size>".
        set PortApproachVector to target:position + 15 * target:facing:topvector + 20 * target:facing:forevector - ship:dockingports[0]:nodeposition.
        if vang(PortApproachVector, facing:forevector) < 5 and abs(RelVelY) < 0.15 and abs(RelVelZ) < 0.15 {
            set ship:control:translation to v(RelVelY/2, RelVelZ/2, (min(5, (PortDistanceVector:mag - 50) / 20) + PortDistanceVector:mag / 400) + RelVelX).
        }
        else {
            set ship:control:translation to v(RelVelY, RelVelZ, RelVelX).
        }
        return lookdirup(PortApproachVector, facing:topvector).
    }
    if dockingmode = "DOCK" {
        if not (cancelconfirmed) and hastarget {
            set message2:text to "<b>Target:</b>  Docking Port  (" + round(PortDistanceVector:mag, 1) + "m)".
            if PortDistanceVector:mag < 10 {
                set message3:text to "<b>Relative Distance (m):   </b><size=14>X: " + round(RelDistX, 2) + "   Y: " + round(RelDistY,2) + "   Z: " + round(RelDistZ,2) + "</size>".
            }
            else {
                set message3:text to "<b>Relative Velocity (m/s):   </b><size=14>X: " + round(RelVelX, 2) + "   Y: " + round(RelVelY,2) + "   Z: " + round(RelVelZ,2) + "</size>".
            }
            wait 0.001.
            if hastarget {
                if vang(target:facing:forevector, facing:forevector) < 5 and vang(facing:topvector, -target:facing:topvector) < 5 {
                    if RelDistZ > 7.5 {
                        set ship:control:translation to v(min(max(RelDistY, -6), 6) + 4 * RelVelY, min(max(RelDistZ, -2.25), 2.25) + 3 * RelVelZ, min(max(RelDistX, -6), 6) + 4 * RelVelX).
                    }
                    else {
                        set ship:control:translation to v(4 * (min(max(RelDistY, -0.75), 0.75) + RelVelY), min(max(RelDistZ, -0.75), 0.75) + 3 * RelVelZ, 4 * (min(max(RelDistX, -0.75), 0.75) + RelVelX)).
                    }
                }
                else {
                    set ship:control:translation to v(RelVelY, RelVelZ, RelVelX).
                }
                //set VectorDraw to vecdraw(target:dockingports[0]:nodeposition, -target:dockingports[0]:portfacing:vector, magenta, "", 20, true, 0.005, true, true).
                return lookdirup(target:facing:forevector, -target:dockingports[0]:portfacing:vector).
            }
            else {
                return lookdirup(facing:forevector, facing:topvector).
            }
        }
        else {
            return lookdirup(facing:forevector, facing:topvector).
        }
    }
}

function DetermineSafeVector {
    set SafeVector1 to target:position + 50 * Scale * target:facing:topvector + -25 * Scale * target:facing:forevector + 25 * Scale * target:facing:starvector - ship:position.
    set SafeVector2 to target:position + 50 * Scale * target:facing:topvector + -25 * Scale * target:facing:forevector - 25 * Scale * target:facing:starvector - ship:position.
    set SafeVector3 to target:position + 50 * Scale * target:facing:topvector + 25 * Scale * target:facing:forevector + 25 * Scale * target:facing:starvector - ship:position.
    set SafeVector4 to target:position + 50 * Scale * target:facing:topvector + 25 * Scale * target:facing:forevector - 25 * Scale * target:facing:starvector - ship:position.
    set SVlist to list(SafeVector1,SafeVector2,SafeVector3,SafeVector4).
    for vec in SVlist {
        set SV2list to SVlist:copy.
        SV2list:remove(SVlist:indexof(vec)).
        set SV3list to SV2list:copy.
        for vec2 in SV2list {
            if vec:mag < vec2:mag {
                SV3list:remove(SV3list:indexof(vec2)).
            }
        }
        if SV3list:length = 0 {
            set SafeVector to vec.
        }
    }
}















function LandwithoutAtmo {
    if addons:tr:hasimpact {
        set LandButtonIsRunning to true.
        set SteeringManager:ROLLCONTROLANGLERANGE to 10.
        set TimeToOVHD to 90.
        set config:ipu to max(CPUSPEED, 600).
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        set LandingFacingVector to v(0, 0, 0).
        set CosAngle to 1.
        set LandSomewhereElse to false.
        set LandingBurnStarted to false.
        set CancelVelocityHasStarted to false.
        set CancelVelocityHasFinished to false.
        set ApproachAltitude to 1.
        set NewTargetSet to false.
        SetPlanetData().
        LogToFile("Landing without Atmosphere Program Started").
        set runningprogram to "De-orbit & Landing".
        SetRadarAltitude().
        set message1:style:textcolor to white.
        set message2:style:textcolor to white.
        set message3:style:textcolor to white.
        set landlabel:style:textcolor to green.
        set launchlabel:style:textcolor to grey.
        HideEngineToggles(1).
        ShutDownAllEngines().
        set launchlabel:style:bg to "starship_img/starship_background".
        ShowButtons(0).
        InhibitButtons(1, 1, 0).
        for res in tank:resources {
            if res:name = "Oxidizer" {
                set RepositionOxidizer to TRANSFERALL("Oxidizer", Tank, HeaderTank).
                set RepositionOxidizer:ACTIVE to TRUE.
            }
            if res:name = "LiquidFuel" {
                set RepositionLF to TRANSFERALL("LiquidFuel", Tank, HeaderTank).
                set RepositionLF:ACTIVE to TRUE.
            }
            if res:name = "LqdMethane" {
                set RepositionLF to TRANSFERALL("LqdMethane", Tank, HeaderTank).
                set RepositionLF:ACTIVE to TRUE.
            }
        }
        sas off.
        rcs on.
        ActivateEngines(0).
        ActivateEngines(1).
        lock throttle to 0.
        if defined Nose {
            if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).}
            else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
            Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).
            }
        }
        Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).

        if groundspeed > 50 or altitude > 10000 {
            LogToFile("Landing without atmo, with cancelling of velocity enabled").
            when horDist < horStopDist then {
                LogToFile("Cancelling velocity...").
                lock throttle to max(min(abs(LngLatErrorList[0]) / (CosAngle * 2000), min(29.43 / MaxAccel, CancelHorVelRatio * min(29.43, MaxAccel) / MaxAccel)), 0.33).
                set runningprogram to "Landing".
                set LandingFacingVector to vxcl(ApproachUPVector, ApproachVector).
                set CancelVelocityHasStarted to true.
                when LngLatErrorList[0] < 150 then {
                    lock throttle to 0.
                    for engine in VACEngines {
                        engine:shutdown.
                    }
                    set CancelVelocityHasFinished to true.
                    when landingRatio > 1 then {
                        lock throttle to min(((DesiredDecel + Planet1G) * landingRatio) / MaxAccel, 2 * 9.81 / MaxAccel).
                        set LandingBurnStarted to true.
                        LogToFile("Landing Burn Started").
                    }
                    LogToFile("LngError < 100m").
                }
            }
        }
        else {
            LogToFile("Landing without atmo, no cancelling of velocity").
            if kuniverse:timewarp:warp > 0 {
                set kuniverse:timewarp:warp to 0.
            }
            for engine in VACEngines {
                engine:shutdown.
            }
            set LandingFacingVector to vxcl(ApproachUPVector, landingzone:position - ship:position):normalized.
            set runningprogram to "Landing".
            set CancelVelocityHasStarted to true.
            set CancelVelocityHasFinished to true.
            when landingRatio > 1 and groundspeed < 75 then {
                LogToFile("Landing Burn Started").
                lock throttle to min(((DesiredDecel + Planet1G) * landingRatio) / MaxAccel, 2 * 9.81 / MaxAccel).
                set LandingBurnStarted to true.
            }
        }
        lock STEERING to LandwithoutAtmoSteering.

        when verticalspeed > -10 and LandingBurnStarted then {
            GEAR on.
            set quickstatus3:pressed to true.
            LogToFile("Extending Landing Gear").
        }

        until verticalspeed > -0.02 and ship:status = "LANDED" and RadarAlt < 5 or verticalspeed > -0.02 and RadarAlt < 2 or ship:status = "LANDED" or cancelconfirmed and not ClosingIsRunning {
            if defined horStopDist {
                LandwithoutAtmoLabels().
                BackGroundUpdate().
                wait 0.001.
            }
        }

        lock steering to lookdirup(ship:up:vector,ship:facing:topvector).
        lock throttle to 0.
        wait 0.001.

        if cancelconfirmed and not ClosingIsRunning {
            ClearInterfaceAndSteering().
            return.
        }
        set runningprogram to "After Landing".
        if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 0).}
        Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 0).
        set ship:control:translation to v(0, 0, 0).
        set ShutdownComplete to false.
        set ShutdownProcedureStart to time:seconds.
        LogToFile("Vehicle Touchdown, performing self-check").
        if GEAR {
            Tank:getmodule("ModuleLevelingBase"):doaction("auto-level", true).
        }
        if not LandSomewhereElse {
            set message1:text to "<b><color=green>Successful Landing Confirmed!</color></b> (" + round((SLEngines[0]:position - landingzone:position):mag - 0.5) + "m)".
        }
        else {
            set message1:text to "<b>Successful Landing Confirmed!</b> (" + round((SLEngines[0]:position - landingzone:position):mag) + "m)".
            set message1:style:textcolor to yellow.
        }
        set message2:text to "<b>Performing Vehicle Self-Check..</b>".
        set message2:style:textcolor to white.
        set message3:style:textcolor to white.

        ShutDownAllEngines().
        //set TwoVacEngineLanding to false.
        until ShutdownComplete {
            set message3:text to "<b>Please Standby..</b> (" + round((ShutdownProcedureStart + 17) - time:seconds) + "s)".
            BackGroundUpdate().
            if time:seconds > ShutdownProcedureStart + 17 {
                set ShutdownComplete to true.
            }
        }
        rcs off.
        set ship:control:neutralize to true.
        unlock steering.
        wait 0.001.
        lock throttle to 0.
        unlock throttle.
        set message1:text to "<b><color=green>Vehicle Self-Check OK!</color></b>".
        set message1:style:textcolor to white.
        set message2:text to "<b>Landing Program completed..</b>".
        set message3:text to "<b>Hatches may now be opened..</b>".
        set runningprogram to "None".
        if defined Nose {
            if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).}
            else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
            Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).
            }
        }
        Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).
        unlock steering.
        LogToFile("Self-Check Complete, Landing Program Complete.").
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        wait 3.
        ClearInterfaceAndSteering().
    }
    else {
        ClearInterfaceAndSteering().
    }
}


function LandwithoutAtmoSteering {
    SendPing().
    set LngLatErrorList to LngLatError().
    set MaxAccel to max(ship:availablethrust / ship:mass, 0.000001).
    set BurnAccel to min(29.43, MaxAccel).
    set DesiredDecel to 4.
    set stopTime to airspeed / (DesiredDecel - Planet1G).
    set stopDist to 0.5 * airspeed * stopTime.
    set landingRatio to stopDist / RadarAlt.
    local lng to ship:geoposition:lng.
    local lat to ship:geoposition:lat.

    if (landingzone:lng - lng) < -180 {
        set LngDistanceToTarget to ((landingzone:lng - lng + 360) * Planet1Degree).
    }
    else {
        set LngDistanceToTarget to ((landingzone:lng - lng) * Planet1Degree).
    }
    local LatDistanceToTarget to max(landingzone:lat - lat, lat - landingzone:lat) * Planet1Degree.
    if LatDistanceToTarget < 0 {set LatDistanceToTarget to -1 * LatDistanceToTarget.}
    set DistanceToTarget to sqrt(LngDistanceToTarget * LngDistanceToTarget + LatDistanceToTarget * LatDistanceToTarget).

    if not (CancelVelocityHasStarted) {
        set CosAngle to cos(vang(velocityat(ship, time:seconds + TimeToOVHD):surface, vxcl(ApproachUPVector, velocityat(ship, time:seconds + TimeToOVHD):surface))).
    }
    set horDist to 1000 * DistanceToTarget.
    if horDist < stopDist + 10000 {
        set horDist to min(horDist, vdot(vxcl(up:vector, Landingzone:position - ship:position), ApproachVector)).
    }
    local horStopTime to groundspeed / BurnAccel.
    set horStopDist to (0.5 * BurnAccel * horStopTime * horStopTime) / CosAngle + 100.
    set CancelHorVelRatio to abs(horStopDist / horDist).

    if RadarAlt < 1000 and ErrorVector:MAG > (RadarAlt + 15) and groundspeed < 75 and not LandSomewhereElse {
        set LandSomewhereElse to true.
    }
    if LandingBurnStarted and verticalspeed > 0 {
        lock throttle to 0.
        set LandingBurnStarted to false.
    }

    if ErrorVector:mag > max(min(RadarAlt / 20, 10), 2.5) {
        set ErrorVector to ErrorVector:normalized * max(min(RadarAlt / 20, 10), 2.5).
    }

    if not (CancelVelocityHasStarted) {
        set SecondsToCancelHorVelocity to (horDist - horStopDist) / groundspeed.
        set x to SecondsToCancelHorVelocity + horStopTime.
        set OVHDlng to -9999.
        until OVHDlng > landingzone:lng {
            set OVHDlng to ship:body:geopositionof(positionat(ship, time:seconds + x)):lng - x / ship:body:rotationperiod * 360.
            set x to x + 1.
        }
        set TimeToOVHD to x.

        //set TimeToOVHD to SecondsToCancelHorVelocity + (velocityat(ship, time:seconds + SecondsToCancelHorVelocity + stopTime):surface:mag / BurnAccel) + (x / ship:body:rotationperiod * ship:orbit:period).

        //local LZPos to -angleaxis((((SecondsToCancelHorVelocity + horStopTime) / ship:orbit:period) / 360 * ship:orbit:period) / body:rotationperiod * 360, latlng(90,0):position - body:position) * (landingzone:position - body:position).
        //set TimeToOVHD to vang(ship:position - body:position, LZpos) / 360 * ship:orbit:period.

        set ApproachAltitude to ship:body:altitudeof(positionat(ship, time:seconds + TimeToOVHD)).
    }

    clearscreen.
    if CancelVelocityHasFinished {
        print "Radar Alt:      " + round(RadarAlt) + "m".
        print "stop time:      " + round(stopTime) + "s".
        print "stop dist:      " + round(stopDist) + "m".
        print "landing ratio:  " + round(landingRatio, 2).
    }
    else {
        print "Lng Error:      " + round(LngLatErrorList[0]) + "m".
        print " ".
        print "hor. distance:  " + round(horDist) + "m".
        print "hor. stop dist: " + round(horStopDist) + "m".
        print "groundspeed:    " + round(groundspeed) + "m/s".
        print "hor. stop time: " + round(horStopTime) + "s".
        print "cancel ratio:   " + round(CancelHorVelRatio, 2).
        print "T to cancel V:  " + round(SecondsToCancelHorVelocity) + "s".
        print " ".
        print "Time to OVHD:   " + round(TimeToOVHD) + "s".
        print "Radar Alt:      " + round(RadarAlt) + "m".
        print "LZ Altitude:    " + round(ApproachAltitude) + "m".
        print "Goal Alt:       " + round(landingzone:terrainheight + SafeAltOverLZ) + "m".
    }
    //print "Angle: " + vang(velocityat(ship, time:seconds + TimeToOVHD):surface, vxcl(ApproachUPVector, velocityat(ship, time:seconds + TimeToOVHD):surface)).
    //print "Cos Angle result: " + cos(vang(velocityat(ship, time:seconds + TimeToOVHD):surface, vxcl(ApproachUPVector, velocityat(ship, time:seconds + TimeToOVHD):surface))).

    if not CancelVelocityHasStarted and RadarAlt > SafeAltOverLZ + 1000 {
        if SecondsToCancelHorVelocity < 300 and not (RSS) or SecondsToCancelHorVelocity < 600 and RSS {
            if vang(facing:topvector, -up:vector) < 45 and vang(result, facing:forevector) < 10 {
                set ship:control:translation to v(LngLatErrorList[1] / 250, (ApproachAltitude - (landingzone:terrainheight + SafeAltOverLZ)) / 2500, 0).
            }
            else {
                set ship:control:translation to v(0, 0, 0).
            }
        }
    }
    else if CancelVelocityHasStarted {
        if addons:tr:hasimpact and not (ship:status = "LANDED") {
            rcs on.
            if vang(facing:topvector, -LandingFacingVector) < 10 and groundspeed < 25 and vang(facing:forevector, result) < 10 {
                set ship:control:translation to v(LngLatErrorList[1] / 10, LngLatErrorList[0] / 10, 0).
            }
            else {
                set ship:control:translation to v(0, 0, 0).
            }
        }
        if addons:tr:hasimpact and not (ship:status = "LANDED") and NewTargetSet {
            if abs(LngLatErrorList[0]) > 100 or abs(LngLatErrorList[1]) > 100 {
                set LandingFacingVector to vxcl(ApproachUPVector, landingzone:position - addons:tr:impactpos:position):normalized.
            }
        }
    }
    else {
        set ship:control:translation to v(0, 0, 0).
    }

    if RadarAlt > SafeAltOverLZ - 100 {
        set result to -velocity:surface:normalized.
    }
    else if not (LandSomewhereElse) and verticalspeed < -10 {
        set result to ship:up:vector - 0.15 * velocity:surface - 0.015 * ErrorVector.
    }
    else if not (LandSomewhereElse) and CancelVelocityHasFinished {
        set result to ship:up:vector.
    }
    else {
        set result to ship:up:vector - 0.025 * velocity:surface.
    }

    //set LdgVectorDraw to vecdraw(v(0, 0, 0), 5 * result:normalized, green, "Landing Vector", 20, true, 0.005, true, true).
    //set LdgFcgVectorDraw to vecdraw(v(0, 0, 0), -LandingFacingVector, blue, "Landing Vector", 20, true, 0.005, true, true).

    if CancelVelocityHasStarted and vang(facing:forevector, up:vector) < 45 {
        return lookDirUp(result, -LandingFacingVector).
    }
    else {
        return lookDirUp(result, -up:vector).
    }
}

function LandwithoutAtmoLabels {
    if CancelVelocityHasStarted {
        if RadarAlt > SafeAltOverLZ {
            set message1:text to "<b>Remaining Flight Time:</b>  " + timeSpanCalculator(ADDONS:TR:TIMETILLIMPACT).
        }
        else {
            set message1:text to "<b>Radar Altimeter:</b>                " + round(RadarAlt) + "m".
        }
    }
    else {
        set message1:text to "<b>Slowing down Ship in:</b>    " + timeSpanCalculator(SecondsToCancelHorVelocity).
        if STOCK {
            if (horDist - horStopDist) / groundspeed < 120 and kuniverse:timewarp:warp > 2 {
                set kuniverse:timewarp:warp to 2.
            }

            if (horDist - horStopDist) / groundspeed < 60 and kuniverse:timewarp:warp > 0 {
                set kuniverse:timewarp:warp to 0.
                rcs on.
                HUDTEXT("Stopping time-warp for burn..", 10, 2, 20, yellow, false).
            }
            if vang(facing:forevector, -velocity:surface) > 45 and kuniverse:timewarp:warp > 0 {
                set kuniverse:timewarp:warp to 0.
                HUDTEXT("Correcting to Retrograde..", 15, 2, 20, yellow, false).
            }
        }
        else {
            if (horDist - horStopDist) / groundspeed < 240 and kuniverse:timewarp:warp > 2 {
                set kuniverse:timewarp:warp to 2.
            }

            if (horDist - horStopDist) / groundspeed < 180 and kuniverse:timewarp:warp > 1 {
                set kuniverse:timewarp:warp to 1.
            }

            if (horDist - horStopDist) / groundspeed < 90 and kuniverse:timewarp:warp > 0 {
                set kuniverse:timewarp:warp to 0.
                rcs on.
                HUDTEXT("Stopping time-warp for burn..", 10, 2, 20, yellow, false).
            }
            if vang(facing:forevector, -velocity:surface) > 45 and kuniverse:timewarp:warp > 0 {
                set kuniverse:timewarp:warp to 0.
                HUDTEXT("Correcting to Retrograde..", 5, 2, 20, yellow, false).
            }
        }
        if abs(LngLatErrorList[1]) > 100 and kuniverse:timewarp:warp > 0 or abs(ApproachAltitude - (landingzone:terrainheight + SafeAltOverLZ)) > 1000 and kuniverse:timewarp:warp > 0 {
            if SecondsToCancelHorVelocity < 300 and not (RSS) or SecondsToCancelHorVelocity < 600 and RSS {
                set kuniverse:timewarp:warp to 0.
                HUDTEXT("Small RCS Corrections in progress..", 2.5, 2, 20, yellow, false).
            }
        }
    }

    if DistanceToTarget < 10 {
        set message2:text to "<b>Distance to Target:</b>           " + round(DistanceToTarget, 2) + "km".
    }
    else {
        set message2:text to "<b>Distance to Target:</b>           " + round(DistanceToTarget) + "km".
    }

    if addons:tr:hasimpact and not LandSomewhereElse {
        if CancelVelocityHasFinished {
            set message3:text to "<b>Track/X-Trk Error:</b>             " + round(LngLatErrorList[0]) + "m  " + round(LngLatErrorList[1]) + "m".
        }
        else if CancelVelocityHasStarted {
            set message3:text to "<b>Track/X-Trk Error:</b>             " + round(LngLatErrorList[0] / 1000, 2) + "km  " + round(LngLatErrorList[1] / 1000, 2) + "km".
        }
        else if abs(ApproachAltitude - landingzone:terrainheight - SafeAltOverLZ) > 1000 {
            set message3:text to "<b>R Alt. @LZ/X-Trk Error:</b>   <color=yellow>" + round((ApproachAltitude - landingzone:terrainheight) / 1000, 1) + "km</color>  " + round((LngLatErrorList[1] / 1000), 2) + "km".
        }
        else {
            set message3:text to "<b>R Alt. @LZ/X-Trk Error:</b>   " + round((ApproachAltitude - landingzone:terrainheight) / 1000, 1) + "km  " + round((LngLatErrorList[1] / 1000), 2) + "km".
        }
    }
    else {
        set message3:text to "<b><color=yellow>Landing off-Target..</color></b>".
    }
}.










//--------------Re-Entry & Landing Program----------------//



function ReEntryAndLand {
    if addons:tr:hasimpact {
        set LandButtonIsRunning to true.
        set FindNewTarget to false.
        set LZsettoOLM to false.
        set tt to time:seconds.
        set config:ipu to CPUSPEED.
        set LandSomewhereElse to false.
        set WobblyTower to false.
        SetPlanetData().
        set FlipAltitude to 700.

        set steeringManager:maxstoppingtime to 0.9.

        set addons:tr:descentmodes to list(true, true, true, true).
        set addons:tr:descentgrades to list(false, false, false, false).
        LogToFile("Re-Entry & Landing Program Started").
        set runningprogram to "De-orbit & Landing".
        SetRadarAltitude().
        set message1:style:textcolor to white.
        set message2:style:textcolor to white.
        set message3:style:textcolor to white.
        set landlabel:style:textcolor to green.
        set launchlabel:style:textcolor to grey.
        HideEngineToggles(1).
        ShutDownAllEngines().
        set launchlabel:style:bg to "starship_img/starship_background".
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        set t to time:seconds.

        if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 25).}
            else if not (ShipType="Block1") and not Nose:name:contains("SEP.23.SHIP.FLAPS") {Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 25).}
        Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 25).
        //if Tank:getmodule("ModuleSepPartSwitchAction"):getfield("current docking system") = "QD" {
        //    Tank:getmodule("ModuleSepPartSwitchAction"):DoAction("next docking system", true).
        //}
        for res in HeaderTank:resources {
            if not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") {
                set res:enabled to true.
            } 
        }
        ShowButtons(0).
        InhibitButtons(1, 1, 0).
        if altitude > 30000 {
            for res in tank:resources {
                if res:name = "Oxidizer" {
                    set RepositionOxidizer to TRANSFERALL("Oxidizer", Tank, HeaderTank).
                    set RepositionOxidizer:ACTIVE to TRUE.
                }
                if res:name = "LiquidFuel" {
                    set RepositionLF to TRANSFERALL("LiquidFuel", Tank, HeaderTank).
                    set RepositionLF:ACTIVE to TRUE.
                }
                if res:name = "LqdMethane" {
                    set RepositionLM to TRANSFERALL("LqdMethane", Tank, HeaderTank).
                    set RepositionLM:ACTIVE to TRUE.
                }
            }
        }
            set RebalanceCoGox to TRANSFER("OXIDIZER", HeaderTank, Tank, 0).
            set RebalanceCoGlf to TRANSFER("LiquidFuel", HeaderTank, Tank, 0).
        
        sas off.
        rcs off.
        ActivateEngines(0).

        if ship:body:atm:sealevelpressure < 0.5 {
            setflaps(FWDFlapDefault - 20, AFTFlapDefault - 20, 1, 10).
            ActivateEngines(1).
        }
        if ship:body:atm:sealevelpressure > 0.5 {
            setflaps(FWDFlapDefault, AFTFlapDefault, 1, 10).
        }

        FLflap:getmodule("ModuleSEPControlSurface"):DoAction("activate yaw control", true).
        FRflap:getmodule("ModuleSEPControlSurface"):DoAction("activate yaw control", true).
        ALflap:getmodule("ModuleSEPControlSurface"):DoAction("deactivate yaw control", true).
        ARflap:getmodule("ModuleSEPControlSurface"):DoAction("deactivate yaw control", true).

        if LFShip > max(FuelVentCutOffValue, MaxFuel) and ship:body:atm:sealevelpressure > 0.5 {
            ToggleHeaderTank(0).
            if not ShipType:contains("Block1") {
                Nose:activate.
            }
            Tank:activate.
            when LFShip < max(FuelVentCutOffValue, MaxFuel) then {
                Tank:shutdown.
                if not ShipType:contains("Block1") {
                    Nose:shutdown.
                }
                ToggleHeaderTank(1).
            }
        }

        SteeringManager:RESETTODEFAULT().
        set steeringmanager:yawts to 10.

        set PitchPID to PIDLOOP(0.000025, 0, 0, -10, 10 - TRJCorrection).
        set ChangeOverSensitivity to ship:body:radius * sqrt(9.81 / (ship:body:radius + ship:body:atm:height)).

        if RSS {
            when airspeed < ChangeOverSensitivity then {
                set PitchPID to PIDLOOP(0.00002, 0, 0.0001, -25, 30 - TRJCorrection). // 0.0025, 0, 0, -25, 30 - 
            }
            set YawPID to PIDLOOP(0.0005, 0, 0, -50, 50).
            when airspeed < 7000 and ship:body:atm:sealevelpressure > 0.5 or airspeed < 3000 and ship:body:atm:sealevelpressure < 0.5 then {
                set PitchPID to PIDLOOP(0.00001, 0, 0.00005, -25, 30 - TRJCorrection).
                set YawPID to PIDLOOP(0.0012, 0, 0.000001, -50, 50).
            }
        }
        else if KSRSS {
            when airspeed < ChangeOverSensitivity then {
                set PitchPID to PIDLOOP(0.0005, 0, 0, -25, 30 + TRJCorrection). // 0.0025, 0, 0, -25, 30 + 
            }
            set YawPID to PIDLOOP(0.0055, 0, 0, -50, 50).
        }
        else {
            when airspeed < ChangeOverSensitivity then {
                set PitchPID to PIDLOOP(0.0005, 0, 0, -25, 30 - TRJCorrection). // 0.0025, 0, 0, -25, 30 - 
            }
            set YawPID to PIDLOOP(0.0055, 0, 0, -50, 50).
        }

        when altitude < 39000 and STOCK then {
            set TRJCorrection to 1.5*TRJCorrection.
        }
        when altitude < 28000 and STOCK then {
            set TRJCorrection to 1.5*TRJCorrection.
        }

        when altitude < 55000 and KSRSS then {
            set TRJCorrection to 2*TRJCorrection.
        }
        when altitude < 40000 and KSRSS then {
            set TRJCorrection to 1.5*TRJCorrection.
        }
        when altitude < 50000 and KSRSS then {
            set TRJCorrection to 1.36*TRJCorrection.
        }
        
        when altitude < 44000 and Stock or altitude < 45000 and KSRSS or altitude < 74000 and RSS then {
            set TRJCorrection to 1.5*TRJCorrection.
        }
        when altitude < 44000 and RSS then {
            set TRJCorrection to -TRJCorrection*1.5.
        }
        when altitude < 20000 and RSS then {
            set TRJCorrection to -TRJCorrection/1.5.
        }
        when altitude < 14000 and Stock or altitude < 17000 and KSRSS or altitude < 15000 and RSS then {
            set TRJCorrection to 0.
        }

        lock STEERING to ReEntrySteering().

        when altitude < body:atm:height then {
            //set quickstatus1:pressed to true.
            //LogToFile("<Atmosphere Height, Body-Flaps Activated").
            when airspeed < 2150 or airspeed < 7100 and RSS then {
                set t to time:seconds.
                if ship:body:atm:sealevelpressure < 0.5 {
                    setflaps(FWDFlapDefault - 20, AFTFlapDefault - 20, 1, 12).
                    if RSS {
                        set YawPID to PIDLOOP(0.0175, 0.015, 0.005, -50, 50).
                    }
                    else {
                        set PitchPID:kp to 0.0005. //0.0025
                    }
                }
                else {
                    setflaps(FWDFlapDefault, AFTFlapDefault, 1, 12).
                    set PitchPID:kp to 0.0004.
                }

                when airspeed < 300 and ship:body:atm:sealevelpressure > 0.5 or airspeed < 750 and ship:body:atm:sealevelpressure < 0.5 and KSRSS or airspeed < 2000 and ship:body:atm:sealevelpressure < 0.5 and RSS or airspeed < 450 and ship:body:atm:sealevelpressure < 0.5 and STOCK then {
                    CheckLZReachable().
                    set t to time:seconds.
                    if ship:body:atm:sealevelpressure > 0.5 {
                        setflaps(FWDFlapDefault, AFTFlapDefault, 1, 35).
                        set aoa to LandingAoA.
                        set DescentAngles to list(aoa, aoa, aoa, aoa).
                        if RSS {
                            set PitchPID:kp to 0.04.
                            set PitchPID:ki to 0.03.
                            set PitchPID:kd to 0.025.
                            set YawPID:kp to 0.025.
                            set YawPID:ki to 0.0125.
                            set YawPID:kd to 0.01.
                            set maxDeltaV to 450.
                        }
                        else if KSRSS {
                            set PitchPID:kp to 0.01. //0.25
                            set PitchPID:ki to 0.01. //0.0225
                            set PitchPID:kd to 0.005. //0.03
                            set YawPID:kp to 0.02. //0.1
                            set YawPID:ki to 0.045. //0.75
                            set YawPID:kd to 0.012. //0.25
                            set maxDeltaV to 400.
                        }
                        else {
                            set PitchPID:kp to 0.0012. //0.03
                            set PitchPID:ki to 0.01. //0.035
                            set PitchPID:kd to 0.008. //0.028
                            set YawPID:kp to 0.02. //0.1
                            set YawPID:ki to 0.045. //0.075
                            set YawPID:kd to 0.015. //0.025
                            set maxDeltaV to 400.
                        }
                    }
                    else {
                        setflaps(FWDFlapDefault - 20, AFTFlapDefault - 20, 1, 8).
                        if RSS {
                            //set PitchPID:kp to 0.01.
                            set PitchPID:ki to 0.00005.
                            set PitchPID:kd to 0.00001.
                        }
                        else if KSRSS {
                            //set PitchPID:kp to 0.005.
                            set PitchPID:ki to 0.0001.
                            set PitchPID:kd to 0.00005.
                        }
                        else {
                            set PitchPID:kp to 0.01.
                            set PitchPID:ki to 0.0075.
                            set PitchPID:kd to 0.005.
                        }
                    }
                    set runningprogram to "Final Approach".
                    LogToFile("Vehicle is Subsonic, precise steering activated").
                    when RadarAlt < 12000 then {
                        //InhibitButtons(1, 1, 1).
                        LandAtOLM().
                        if ship:body:atm:sealevelpressure > 0.5 {
                            when RadarAlt < 1500 then {
                                if currentdeltav > maxDeltaV*1.1 and ship:body:atm:sealevelpressure > 0.5 {
                                    Tank:activate.
                                    //Nose:activate.
                                    when currentdeltav < maxDeltaV then {
                                        Tank:shutdown.
                                        //Nose:shutdown.
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if ship:body:atm:sealevelpressure > 0.5 {
            until RadarAlt < FlipAltitude or altitude - AvailableLandingSpots[4] < FlipAltitude or cancelconfirmed and not ClosingIsRunning or vAng(facing:forevector,up:vector) < 45 and RadarAlt < 3*FlipAltitude {
                ReEntryData().
            }
            LogToFile("Radar Altimeter < " + round(FlipAltitude) + " (" + round(RadarAlt) + "), starting Landing Procedure").
        }
        if ship:body:atm:sealevelpressure < 0.5 {
            wait 0.001.
            if (0.8 * max(SLEngines[0]:availablethrust, 0.000001) * 3) / ship:mass > 2 * 9.805 {
                for eng in VACEngines {
                    eng:shutdown.
                }
            }

            function CalcCancelTime {
                local ISP to EngineISP.
                local F to 0.8 * ship:availablethrust.
                local v0 to groundspeed.
                local m0 to ship:mass.
                local g0 to 9.805.

                // Calculate the exhaust velocity
                local ve to ISP * g0.

                // Calculate the mass flow rate
                local dm to F / ve.

                // Calculate the burn time to bring the rocket to a full stop
                local CancelTime to (v0 * m0) / F.

                // Number of intervals for the numerical integration
                local num_intervals to 10.

                // Calculate the step size for the integration
                local h to CancelTime / num_intervals.

                // Initialize the sum for the integration
                local Cdistance to 0.

                // Initialize the previous velocity
                local current_velocity to v0.

                // Perform the numerical integration using the trapezoidal rule
                for i in range(0, num_intervals) {
                    local t to i * h.
                    local mt to m0 - dm * t.
                    local acceleration to F / mt.
                    local new_velocity to current_velocity - acceleration * h.
                    set Cdistance to Cdistance + (current_velocity + new_velocity) * h / 2.
                    set current_velocity to new_velocity.
                }

                return Cdistance.
            }



            lock CancelDist to CalcCancelTime().
            lock Dist2LandProc to vxcl(up:vector, ship:position - landingzone:position):mag - CancelDist - 500 - 3 * groundspeed.

            until vxcl(up:vector, ship:position - landingzone:position):mag < CancelDist + 500 + 3 * groundspeed or cancelconfirmed and not ClosingIsRunning {
                ReEntryData().
                wait 0.001.
            }

            LogToFile("Starting Low Atmo Landing Procedure").
        }
        if cancelconfirmed {
            sas on.
            ClearInterfaceAndSteering().
        }
        
    
//------------------Re-Entry Loop-----------------------///



function ReEntrySteering {
    if not SteeringIsRunning and time:seconds > TimeSinceLastSteering + 0.2 {
        set SteeringIsRunning to true.
        rcs on.

        if RadarAlt > FlipAltitude + 100 {
            lock throttle to 0.
        }

        set LngLatErrorList to LngLatError().

        if ship:body:atm:sealevelpressure > 0.5 {
            set PitchPID:maxoutput to min(abs(LngLatErrorList[0] / (12 * Scale) + 2), 36).
        }
        else {
            set PitchPID:maxoutput to min(abs(LngLatErrorList[0] / (15 * Scale) + 2), 24).
        }
        set PitchPID:minoutput to -PitchPID:maxoutput.
        set YawPID:maxoutput to min(abs(LngLatErrorList[1] / 20 + 1), 50).
        set YawPID:minoutput to -YawPID:maxoutput.

        if aoa:typename = "String" {set aoa to (aoa):toscalar.}
        set pitchctrl to -PitchPID:UPDATE(TIME:SECONDS, LngLatErrorList[0]).
        set DesiredAoA to aoa + pitchctrl + TRJCorrection.
        set yawctrl to YawPID:UPDATE(TIME:SECONDS, LngLatErrorList[1]).
        if RadarAlt > 5000 {
            set SRFPRGD to srfprograde.
        }
        else if time:seconds > t + 5 {
            set t to time:seconds.
            set SRFPRGD to srfprograde.
        }
        set result to SRFPRGD * R(-DesiredAoA * cos(yawctrl), 0, 0).
        set result to angleaxis(yawctrl, srfprograde:vector) * result.
        set result to lookdirup(result:vector, -vxcl(result:vector, SRFPRGD:vector)).
        if LandSomewhereElse {
            set result to srfprograde * R(-75, 0, 0).
        }

        clearscreen.
        //set ReEntryVector to vecdraw(v(0, 0, 0), 1.5 * result:vector, green, "Re-Entry Vector", 25, true, 0.005, true, true).
        print "LngError: " + round(LngLatErrorList[0]).
        print "LatError: " + round(LngLatErrorList[1]).
        print "Desired AoA: " + round(DesiredAoA, 2).
        print "PitchCtrl: " + round(pitchctrl, 2).
        print "MaxOutput: " + round(PitchPID:maxoutput, 2).
        print "YawCtrl: " + round(yawctrl, 2).

        if ship:body:atm:sealevelpressure < 0.5 {
            print " ".
            print "Mass: " + round(ship:mass).
            print " ".
            print "CancelTime: " + round(CancelTime).
            print "CancelDist: " + round(CancelDist).
            print "Dist: " + round(vxcl(up:vector, ship:position - landingzone:position):mag).
            print "Dist2LandProc: " + round(Dist2LandProc).
        }

        set TimeSinceLastSteering to time:seconds.
        set SteeringIsRunning to false.
        return result.
    }
    else {
        return result.
    }
}


function ReEntryData {
    BackGroundUpdate().
    LogToFile("Re-Entry Telemetry").

    if airspeed < 450 and kuniverse:timewarp:warp > 1 {set kuniverse:timewarp:warp to 1.}
    if RadarAlt < 1500 and kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
    if ship:body:atm:sealevelpressure < 0.5 {
        if vxcl(up:vector, ship:position - landingzone:position):mag < CancelDist + 10000 and kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
    }

    if airspeed > 300 {
        set runningprogram to "De-orbit & Landing".
        set status1:style:textcolor to green.
    }
    else if RadarAlt > 10000 {
        set runningprogram to "Final Approach".
        set status1:style:textcolor to green.
    }
    else {
        set runningprogram to "Landing".
        set status1:style:textcolor to green.
        if time:seconds > tLZ + 10 {
            if RSS {
                set ship:control:translation to v(LngLatErrorList[1] / 15, 0, -LngLatErrorList[0] / 100).
            }
            else {
                set ship:control:translation to v(LngLatErrorList[1] / 30, 0, -LngLatErrorList[0] / 25).
            }
        }
    }

    //if hastarget and not (LZsettoOLM) and not (NewTargetSet) {
    //    if target:name:contains("OrbitalLaunchMount") {
    //        set landingzone to target:geoposition.
    //        LandAtOLM().
    //        set NewTargetSet to true.
    //    }
    //}

    if result = V(0,0,0) {
        set result to lookdirup(facing:forevector, facing:topvector).
    }
    if altitude < ship:body:atm:height - 5000 and vang(facing:forevector, result:vector) > 29 or CargoMass > 25000 * Scale {
        if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).}
        if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
        Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
        }
        Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
        set tt to time:seconds.

    }
    if time:seconds > tt + 15 {
        if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 9).}
        if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
        Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 9).
        }
        Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 9).
    }

    if DynamicPitch and altitude < 0.75 * ship:body:atm:height {
        if time:seconds > t + 15 {
            set PitchInput to SLEngines[0]:gimbal:pitchangle.
            set t to time:seconds.
            set FWDFlapDefault to max(min(70 - (PitchInput * 10 / Scale),80),60).
            set AFTFlapDefault to max(min(65 + (PitchInput * 12 / Scale),75),55).
            if airspeed > 300 {
                if ship:body:atm:sealevelpressure < 0.5 {
                    setflaps(FWDFlapDefault - 10, AFTFlapDefault - 10, 1, 15).
                } else if altitude > 28000 {
                    setflaps(FWDFlapDefault, AFTFlapDefault, 1, 35).
                }
                else {
                    setflaps(FWDFlapDefault, AFTFlapDefault, 1, 40).
                }
            }
            else {
                if ship:body:atm:sealevelpressure < 0.5 {
                    setflaps(FWDFlapDefault - 20, AFTFlapDefault - 20, 1, 12).
                }
                else if not (RSS) or altitude > 10000 {
                    setflaps(FWDFlapDefault, AFTFlapDefault, 1, 35).
                }
                else {
                    setflaps(FWDFlapDefault, AFTFlapDefault, 1, 24).
                }
            }
        }
    }

    if ship:partsnamed("NOSE.PEZ.BLOCK-2"):length = 0 {
        //print("FuelBalancing Active").
        if CoGFuelBalancing {
        if altitude < ship:body:ATM:height - 10000 and RadarAlt > FlipAltitude + 100 {
            if not (RebalanceCoGox:status = "Transferring") or (RebalanceCoGlf:status = "Transferring") {
                set PitchInput to SLEngines[0]:gimbal:pitchangle.
                if PitchInput > 0.005 and PitchInput < 0.95 {
                    for res in HeaderTank:resources {
                        if res:name = "Oxidizer" {
                            if res:amount < abs(FuelBalanceSpeed * PitchInput) {}
                            for res in Tank:resources {
                                if res:name = "Oxidizer" {
                                    if res:amount > res:capacity - abs(FuelBalanceSpeed * PitchInput) {}
                                    else {
                                        set RebalanceCoGox to TRANSFER("Oxidizer", HeaderTank, Tank, abs(FuelBalanceSpeed * PitchInput)).
                                    }
                                }
                            }
                        }
                        else if res:name = "LiquidFuel" {
                            if res:amount < abs(FuelBalanceSpeed/(11/9) * PitchInput) {}
                            for res in Tank:resources {
                                if res:name = "LiquidFuel" {
                                    if res:amount > res:capacity - abs(FuelBalanceSpeed/(11/9) * PitchInput) {}
                                    else {
                                        set RebalanceCoGlf to TRANSFER("LiquidFuel", HeaderTank, Tank, abs(FuelBalanceSpeed/(11/9) * PitchInput)).
                                    }
                                }
                            }
                        }
                        else if res:name = "LqdMethane" {
                            if res:amount < abs(FuelBalanceSpeed/(1/3) * PitchInput) {}
                            for res in Tank:resources {
                                if res:name = "LqdMethane" {
                                    if res:amount > res:capacity - abs(FuelBalanceSpeed/(1/3) * PitchInput) {}
                                    else {
                                        set RebalanceCoGlf to TRANSFER("LqdMethane", HeaderTank, Tank, abs(FuelBalanceSpeed/(1/3) * PitchInput)).
                                    }
                                }
                            }
                        }
                    }
                }
                else if PitchInput < -0.005 and PitchInput > -0.95 {
                    for res in Tank:resources {
                        if res:name = "Oxidizer" {
                            if res:amount < abs(FuelBalanceSpeed * PitchInput) {}
                            for res in HeaderTank:resources {
                                if res:name = "Oxidizer" {
                                    if res:amount > res:capacity - abs(FuelBalanceSpeed * PitchInput) {}
                                    else {
                                        set RebalanceCoGox to TRANSFER("Oxidizer", Tank, HeaderTank, abs(FuelBalanceSpeed * PitchInput)).
                                    }
                                }
                            }
                        }
                        else if res:name = "LiquidFuel" {
                            if res:amount < abs(FuelBalanceSpeed/(11/9) * PitchInput) {}
                            for res in HeaderTank:resources {
                                if res:name = "LiquidFuel" {
                                    if res:amount > res:capacity - abs(FuelBalanceSpeed/(11/9) * PitchInput) {}
                                    else {
                                        set RebalanceCoGlf to TRANSFER("LiquidFuel", Tank, HeaderTank, abs(FuelBalanceSpeed/(11/9) * PitchInput)).
                                    }
                                }
                            }
                        }
                        else if res:name = "LqdMethane" {
                            if res:amount < abs(FuelBalanceSpeed/(1/3) * PitchInput) {}
                            for res in HeaderTank:resources {
                                if res:name = "LqdMethane" {
                                    if res:amount > res:capacity - abs(FuelBalanceSpeed/(1/3) * PitchInput) {}
                                    else {
                                        set RebalanceCoGlf to TRANSFER("LqdMethane", Tank, HeaderTank, abs(FuelBalanceSpeed/(1/3) * PitchInput)).
                                    }
                                }
                            }
                        }
                    }
                }
                set RebalanceCoGox:ACTIVE to true.
                set RebalanceCoGlf:ACTIVE to true.
            }
        }
        } 
    } else 
        //print("FuelBalancing NOT active").
    set LngDistanceToTarget to 0.
    SetPlanetData().
    if (landingzone:lng - ship:geoposition:lng) < -180 {
        set LngDistanceToTarget to ((landingzone:lng - ship:geoposition:lng + 360) * Planet1Degree).
    }
    else {
        set LngDistanceToTarget to ((landingzone:lng - ship:geoposition:lng) * Planet1Degree).
    }
    set LatDistanceToTarget to max(landingzone:lat - ship:geoposition:lat, ship:geoposition:lat - landingzone:lat) * Planet1Degree.
    if LatDistanceToTarget < 0 {set LatDistanceToTarget to -1 * LatDistanceToTarget.}
    print(LngDistanceToTarget).
    set DistanceToTarget to sqrt(LngDistanceToTarget * LngDistanceToTarget + LatDistanceToTarget * LatDistanceToTarget).

    if not ClosingIsRunning {
        if FindNewTarget and addons:tr:hasimpact {
            if Slope < 2.5 {
                set message1:text to "<b>Remaining Flight Time:</b>  " + timeSpanCalculator(ADDONS:TR:TIMETILLIMPACT) + "     <color=green><b>Slope:  </b>" + round(Slope, 1) + "°</color>".
            }
            else if Slope > 2.5 and Slope < 5 {
                set message1:text to "<b>Remaining Flight Time:</b>  " + timeSpanCalculator(ADDONS:TR:TIMETILLIMPACT) + "     <color=yellow><b>Slope:  </b>" + round(Slope, 1) + "°</color>".
            }
            else {
                set message1:text to "<b>Remaining Flight Time:</b>  " + timeSpanCalculator(ADDONS:TR:TIMETILLIMPACT) + "     <color=red><b>Slope:  </b>" + round(Slope, 1) + "°</color>".
            }
        }
        else if addons:tr:hasimpact {
            if ADDONS:TR:TIMETILLIMPACT > 15 {
                set message1:text to "<b>Remaining Flight Time:</b>  " + timeSpanCalculator(ADDONS:TR:TIMETILLIMPACT).
            }
            else {
                set message1:text to "<b>Radar / Flip Altitude:</b>        " + round(RadarAlt) + "m / " + round(FlipAltitude) + "m".
            }
        }

        if DistanceToTarget < 10 {
            set message2:text to "<b>Distance to Target:</b>           " + round(DistanceToTarget, 2) + "km".
        }
        else {
            if ship:body:atm:sealevelpressure > 0.5 {
                set message2:text to "<b>Distance to Target:</b>           " + round(DistanceToTarget) + "km".
            }
            else {
                set message2:text to "<b>Distance to Target:</b>           " + round(DistanceToTarget) + "km <color=grey>/ " + round(Dist2LandProc / 1000) + "km</color>".
            }
        }

        if abs(LngLatErrorList[0]) < 100 and abs(LngLatErrorList[1]) < 100 and RadarAlt < 10000 and ship:body:atm:sealevelpressure > 0.5 {
            set message3:text to "<b>Track/X-Trk Error:</b>             " + round(LngLatErrorList[0]) + "m  " + round(LngLatErrorList[1]) + "m".
        }
        else if vang(ApproachVector, velocity:surface) < 90 {
            set message3:text to "<b>Track/X-Trk Error:</b>             " + round(LngLatErrorList[0] / 1000, 2) + "km  " + round((LngLatErrorList[1] / 1000), 2) + "km".
        }
        else {
            set message3:text to "<b>Track Error:          </b>             " + round(LngLatErrorList[0] / 1000, 2) + "km".
        }
    }

    if RadarAlt < 15000 and not ClosingIsRunning {
        if altitude < RadarAlt {
            SetRadarAltitude().
        }
        if ship:body:atm:sealevelpressure > 0.5 {
            if abs(LngLatErrorList[0]) > 5000 * Scale or abs(LngLatErrorList[1]) > 25 * Scale {
                set message3:style:textcolor to yellow.
            }
            else {
                set message3:style:textcolor to white.
            }
        }
        if ship:body:atm:sealevelpressure < 0.5 {
            if abs(LngLatErrorList[0]) > 7500 * Scale or abs(LngLatErrorList[1]) > 150 {
                set message3:style:textcolor to yellow.
            }
            else {
                set message3:style:textcolor to white.
            }
        }
    }
    if RadarAlt < 2500 {
        if abs(LngLatErrorList[0]) > 10 and ship:body:atm:sealevelpressure > 0.5 or abs(LngLatErrorList[1]) > 5 or abs(LngLatErrorList[0]) > 500 and ship:body:atm:sealevelpressure < 0.5 {
            if not ClosingIsRunning {
                set message3:style:textcolor to yellow.
            }
        }
        else {set message3:style:textcolor to white.}
    }
}


    
//-----------------------Landing---------------------------///



        if LandButtonIsRunning and not LaunchButtonIsRunning and not cancelconfirmed {
            set config:ipu to 1000.
            unlock throttle.
            rcs off.
            set steeringManager:maxstoppingtime to 2.
            set LandingFlipStart to time:seconds.
            set ship:control:pitch to 1.
            if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).}
            else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).}
            Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
            set ThrottleMin to 0.42.
            if STOCK {
                set FlipAngleFactor to 0.5.
                set CatchVS to -0.3.
            }
            else if KSRSS {
                set FlipAngleFactor to 0.5.
                set CatchVS to -0.25.
            }
            else {
                set FlipAngleFactor to 0.7.
                set CatchVS to -0.24.
            }
            
            wait 0.001.
            lock throttle to 0.5.
            if RSS {lock throttle to 0.33.}

            set landingzone to latlng(landingzone:lat, landingzone:lng - 0.0001).
            addons:tr:settarget(landingzone).
            SetRadarAltitude().


            if ship:body:atm:sealevelpressure > 0.5 and airspeed < 130 {
                if abs(LngLatErrorList[0]) > 20 or abs(LngLatErrorList[1]) > 15 {
                    set LandSomewhereElse to true.
                    lock throttle to 0.55.
                    if RSS {lock throttle to 0.33.}
                    SetRadarAltitude().
                    LogToFile("Landing parameters out of bounds (Lng: " + LngLatErrorList[0] + "m,Lat: " + LngLatErrorList[1] + "m), Landing Off-Target").
                }
                wait 0.001.
                Tank:shutdown.
                //if not (TargetOLM = "False") {sendMessage(Vessel(TargetOLM), "RetractMechazillaRails").}
                SLEngines[1]:getmodule("ModuleEnginesFX"):SetField("thrust limiter", 0).
                SLEngines[2]:getmodule("ModuleEnginesFX"):SetField("thrust limiter", 0).
                SLEngines[0]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
                when time:seconds > LandingFlipStart + 0.7 then {
                    SLEngines[1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
                    SLEngines[1]:getmodule("ModuleEnginesFX"):SetField("thrust limiter", 100).
                    when time:seconds > LandingFlipStart + 1.0 then {
                        if not Nose:name:contains("SEP.23.SHIP.FLAPS") {SLEngines[2]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).}
                        if not Nose:name:contains("SEP.23.SHIP.FLAPS") {SLEngines[2]:getmodule("ModuleEnginesFX"):SetField("thrust limiter", 100).}
                        setflaps(0, 87, 1, 0).
                        if not (TargetOLM = "False") {
                            sendMessage(Vessel(TargetOLM), "ExtendMechazillaRails").
                            sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + 1*Scale + ", 2")).
                        }
                    }
                }
            } else if ship:body:atm:sealevelpressure > 0.5 and airspeed > 130 {
                if abs(LngLatErrorList[0]) > 20 or abs(LngLatErrorList[1]) > 15 {
                    set LandSomewhereElse to true.
                    lock throttle to 1.
                    if RSS {lock throttle to 1.}
                    SetRadarAltitude().
                    LogToFile("Landing parameters out of bounds (Lng: " + LngLatErrorList[0] + "m,Lat: " + LngLatErrorList[1] + "m), Landing Off-Target").
                }
                wait 0.001.
                Tank:shutdown.
                if not (TargetOLM = "False") {sendMessage(Vessel(TargetOLM), "ExtendMechazillaRails").}
                //if not (TargetOLM = "False") {sendMessage(Vessel(TargetOLM), "RetractMechazillaRails").}
                SLEngines[1]:getmodule("ModuleEnginesFX"):SetField("thrust limiter", 0).
                SLEngines[2]:getmodule("ModuleEnginesFX"):SetField("thrust limiter", 0).
                SLEngines[0]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
                when time:seconds > LandingFlipStart + 0.3 then {
                    SLEngines[1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
                    SLEngines[1]:getmodule("ModuleEnginesFX"):SetField("thrust limiter", 100).
                    when time:seconds > LandingFlipStart + 0.5 then {
                        if not Nose:name:contains("SEP.23.SHIP.FLAPS") {SLEngines[2]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).}
                        if not Nose:name:contains("SEP.23.SHIP.FLAPS") {SLEngines[2]:getmodule("ModuleEnginesFX"):SetField("thrust limiter", 100).}
                        setflaps(0, 87, 1, 0).
                    }
                }
            }
            else {
                set FlipAngleFactor to 0.75.
                set CancelVelocityHasStarted to true.
            }

            InhibitButtons(1, 1, 1).
            set SteeringManager:ROLLCONTROLANGLERANGE to 10.
            set STEERINGMANAGER:PITCHTS to 0.5.
            set STEERINGMANAGER:YAWTS to 0.5.
            set FlipAngle to vang(-1 * velocity:surface, ship:facing:forevector).
            set LandingForwardDirection to facing:forevector.
            set LandingLateralDirection to facing:starvector.
            set LandingBurnStarted to false.
            set landingRatio to 0.
            set ShipLanded to false.
            set LandingFlipTime to 2.8.
            if KSRSS {
                set LandingFlipTime to 3.5.
            } else if RSS {
                set LandingFlipTime to 5.24.
            }
            set maxDecel to 0.
            set maxG to 4.
            set DesiredDecel to 0.
            lock steering to LandingVector().

            set message1:text to "<b>Performing Landing Flip..</b>".
            set message2:text to "<b><color=green>Engine Light-Up confirmed..</color></b>".
            set message3:text to "".
            set Hover to false.
            set Slow to false.
            if not (TargetOLM = "false") {
                when Vessel(TargetOLM):distance < 1600 then {
                    set Vessel(TargetOLM):loaddistance:landed:unpack to 1400.
                    set Vessel(TargetOLM):loaddistance:prelaunch:unpack to 1400.
                    when Vessel(TargetOLM):distance < 1300 then
                        sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + 1*Scale + ", 2")).
                }
                when vAng(facing:forevector, up:vector) < 3 then {
                    HUDTEXT("Distance Check 1", 3, 2, 15, white, false).
                    if vxcl(up:vector, Tank:position - Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position):mag > 2.4*ShipHeight and vAng(vxcl(up:vector, Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position - Tank:position), LandingForwardDirection) < 90 {
                        set LandSomewhereElse to true.
                        lock RadarAlt to alt:radar - ShipHeight.
                        HUDTEXT("Mechazilla too far away ("+vxcl(up:vector, Tank:position - Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position):mag+"m)", 3, 2, 20, red, false).
                    } else {
                        when groundspeed < 2 then {
                            HUDTEXT("Distance Check 2", 3, 2, 15, white, false).
                            if vxcl(up:vector, Tank:position - Vessel(TargetOLM):partsnamed("SLE.SS.OLIT.MZ")[0]:position):mag > 1.4*ShipHeight {
                                set LandSomewhereElse to true.
                                lock RadarAlt to alt:radar - ShipHeight.
                                HUDTEXT("Mechazilla too far away ("+vxcl(up:vector, Tank:position - Vessel(TargetOLM):partsnamed("SLE.SS.OLIT.MZ")[0]:position):mag+"m)", 3, 2, 20, red, false).
                            }
                        }
                    }
                }
            }
            set CancelVelocityHasFinished to false.
            if defined watchdog {
                Watchdog:deactivate().
            }
            LogToFile("Landing Procedure started. Starting Landing Flip Now!").
            
            when vang(-1 * velocity:surface, ship:facing:forevector) < FlipAngleFactor * FlipAngle then {
                set config:ipu to 1.2*CPUSPEED.
                setflaps(60, 60, 1, 0).
                rcs on.
                if not (TargetOLM = "false") and not (LandSomewhereElse) and not (FindNewTarget) {
                    if not RSS lock RadarAlt to vdot(up:vector, FLflap:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position) - 6.4.
                    else lock RadarAlt to vdot(up:vector, FLflap:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position) - 10.8.
                }
                set ship:control:neutralize to true.
                
                set LandingBurnStarted to true.
                lock throttle to LandingThrottle().
                

                if TargetOLM {
                    when RadarAlt < 24 * ShipHeight then {
                        when RadarAlt < 22 * ShipHeight then {
                            sendMessage(Vessel(TargetOLM), ("MechazillaArms,8.5,26,80,true")).
                            sendMessage(Vessel(TargetOLM), ("MechazillaPushers,0,2," + round(5 * Scale, 2) + ",true")).
                            sendMessage(Vessel(TargetOLM), ("RetractSQD")).
                        }

                        when RadarAlt < 2.85 * ShipHeight then {
                            setflaps(0, 85, 1, 0).
                            set steeringManager:maxstoppingtime to 0.9*Scale.
                        }
                        when RadarAlt < 0.85 * ShipHeight then {
                            setflaps(0, 85, 1, 0).
                            set steeringManager:maxstoppingtime to 0.45*Scale.
                        }

                        when RadarAlt < 2.8 * ShipHeight and RadarAlt > 0.14 * ShipHeight then {
                            set speed to ClosingSpeed().
                            set angle to ClosingAngle().
                            sendMessage(Vessel(TargetOLM), ("MechazillaArms," + round(ShipRot, 1) + "," + speed + "," + angle + ",true")).
                            wait 0.1.
                            if not ShipLanded preserve.
                        }
                            when RadarAlt <  0.1 * ShipHeight then {
                                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + round(ShipRot, 1) + ",4.2,24,false")).
                                sendMessage(Vessel(TargetOLM), ("CloseArms")).
                            }
                        if LandSomewhereElse {
                            set quickstatus3:pressed to true.
                        }
                        when WobblyTower then {
                            HUDTEXT("Wobbly Tower detected..", 3, 2, 20, red, false).
                            HUDTEXT("Landing at nearest suitable location..", 3, 2, 20, yellow, false).
                            sendMessage(Vessel(TargetOLM), "MechazillaArms,8.2,10,113.5,true").
                            set landingzone to ship:body:geopositionof(landingzone:position - 15 * Scale * TowerHeadingVector:normalized).
                            set LandSomewhereElse to true.
                            SetRadarAltitude().
                            ADDONS:TR:SETTARGET(landingzone).
                        }
                    }
                }
                else {
                    when ship:groundspeed > 44 and not (TargetOLM = "false") then {
                        set LandSomewhereElse to true.
                    }
                    when verticalspeed > -20 then {
                        GEAR on.
                        SLEngines[0]:shutdown.
                        SLEngines[0]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                        LogToFile("1st engine shutdown; performing a single engine landing..").
                    }
                }
                if ship:body:atm:sealevelpressure < 0.5 {
                    when LngError < 25 or vang(up:vector, facing:forevector) < 20 and ship:groundspeed < 25 and RSS then {
                        for eng in VACEngines {
                            eng:shutdown.
                        }
                        set CancelVelocityHasFinished to true.
                        set t to time:seconds.
                    }
                }
            }

            
            when (verticalspeed > -42 and throttle < ThrottleMin + 0.05 and ship:groundspeed < 6 and ThrottleMin * 3 * max(SLEngines[0]:availablethrust, 0.000001) / ship:mass > Planet1G and RadarAlt < 2*ShipHeight) or (verticalSpeed > -30 and throttle < 0.58) then {
                SLEngines[0]:shutdown.
                SLEngines[0]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                LogToFile("1st engine shutdown; performing a 2-engine landing..").
                set twoSL to true.
                set ThrottleMin to 0.33.
                if RSS set ThrottleMin to 0.24.
                when ThrottleMin * 2 * max(SLEngines[0]:availablethrust, 0.000001) / ship:mass > Planet1G and throttle < ThrottleMin + 0.003 and ship:groundspeed < 1 * Scale and verticalspeed > -8 * Scale and RadarAlt > 5 or verticalSpeed > CatchVS * 0.8 and RadarAlt > 4 then {
                    SLEngines[2]:shutdown.
                    SLEngines[2]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                    LogToFile("2nd engine shutdown; performing a single engine landing..").
                    set oneSL to true.
                }
            }

            until verticalspeed > CatchVS and RadarAlt < 15 * Scale and ship:groundspeed < 1 or Hover and ship:groundspeed < 1 {
                SendPing().
                if ship:body:atm:sealevelpressure > 0.5 {
                    if ErrorVector:MAG > (Scale * 2 * RadarAlt + 25) and RadarAlt > 55 and not (LandSomewhereElse) or RadarAlt < -1 and not (LandSomewhereElse) or verticalspeed > -15 and ErrorVector:MAG > 15 * Scale {
                        set LandSomewhereElse to true.
                        SetRadarAltitude().
                        LogToFile("Uh oh... Landing Off-Target").
                        lock throttle to LandingThrottle().
                    }
                }
                else {
                    if ErrorVector:MAG > 2 * RadarAlt + 10 and not LandSomewhereElse and RadarAlt < 250 {
                        set LandSomewhereElse to true.
                        LogToFile("Uh oh... Landing Off-Target").
                    }
                }
                if RadarAlt > 5 {
                    LogToFile("Re-Entry Telemetry").
                    BackGroundUpdate().
                }
                else {
                    set DesiredDecel to 11 - Planet1G.
                }
                if KUniverse:activevessel = ship {}
                else {
                    HUDTEXT("Setting focus to Ship..", 3, 2, 20, yellow, false).
                    KUniverse:forceactive(ship).
                }
                wait 0.01.
            }
            if not (TargetOLM = "False") {
                unlock throttle.
                wait 0.001.
                set t to time:seconds.
                //lock steering to lookDirUp(up:vector - 0.01 * velocity:surface, RollVector).
                lock throttle to max((Planet1G + (verticalspeed / CatchVS - 1)) / (max(ship:availablethrust, 0.000001) / ship:mass * 1/cos(vang(-velocity:surface, up:vector))), ThrottleMin).
                until time:seconds > t + 8 or ship:status = "LANDED" and verticalspeed > -0.01 or RadarAlt < -1 {
                    SendPing().
                    BackGroundUpdate().
                    print "slowly lowering down ship..".
                    rcs on.
                    wait 0.01.
                }
                set LngLatErrorList to LngLatError().
                wait 1.
                if RadarAlt < -1 and ErrorVector:mag < 10 * Scale {
                    set LandSomewhereElse to true.
                    SetRadarAltitude().
                    LogToFile("Uh oh... Ship not caught..").
                    lock steering to LandingVector().
                    lock throttle to LandingThrottle.
                    until ship:status = "LANDED" and verticalspeed > -0.01 {
                        SendPing().
                        LogToFile("Re-Entry Telemetry").
                        BackGroundUpdate().
                        if KUniverse:activevessel = ship {}
                        else {
                            HUDTEXT("Setting focus to Ship..", 3, 2, 20, yellow, false).
                            KUniverse:forceactive(ship).
                        }
                        rcs on.
                        wait 0.01.
                    }
                }
                sendMessage(Vessel(TargetOLM), "RetractMechazillaRails").
            }
            print "Ship Landing Confirmed!".
            set ShipLanded to true.
            LogToFile("Ship Landing Confirmed!").



//------------------Landing Loop-----------------------///
function ClosingAngle {
    if (53/(1+constant:e^(-3.3*((RadarAlt/ShipHeight) - 2)))) + 28 > 30 {
        set angle to (53/(1+constant:e^(-3.3*((RadarAlt/ShipHeight) - 2)))) + 28.
    } else {
        set angle to (30/(1+constant:e^(-10*((RadarAlt/ShipHeight) - 0.4)))) + 0.2.
    }
    if angle > 80 set angle to 80.
    return round(angle,1).
}

function ClosingSpeed {
    set currentDec to shipThrust / (ship:mass).
    if currentDec = 0 set currentDec to 0.00001.
    set currentSpeed to verticalSpeed.
    if currentSpeed = 0 set currentSpeed to 0.00001.
    if currentSpeed < 0 set currentSpeed to -currentSpeed.

    set speed to min(max((angle/(currentSpeed/currentDec))*1.5,2),12).

    if currentSpeed < 10 set speed to currentSpeed.

    return round(speed,1).
}


function LandingThrottle {
    set minDecel to (Planet1G - 1.2) / (max(ship:availablethrust, 0.000001) / ship:mass * 1/cos(vang(-velocity:surface * 0.9, up:vector))).
    if LandSomewhereElse {
        set minDecel to (Planet1G - 1.5) / (max(ship:availablethrust, 0.000001) / ship:mass * 1/cos(vang(-velocity:surface * 0.9, up:vector))).
    }
    if verticalSpeed < 8*CatchVS and Hover {
        set Hover to false.
    }
    if verticalSpeed < 14*CatchVS and Hover {
        set Slow to false.
    }
    if verticalSpeed > 0 {
        return minDecel*0.5.
    }
    if verticalspeed > CatchVS or Hover {
        set Hover to true.
        return minDecel.
    }
    set maxDecel to max(ship:availablethrust, 0.000001) / ship:mass - Planet1G.
    set DesiredDecel to 0.6 * maxDecel.
    set stopTime to airspeed / DesiredDecel.
    set stopDist to 0.5 * airspeed * stopTime.
    
    if verticalspeed > 3*CatchVS or Slow {
        set Slow to true.
        return (minDecel+DesiredDecel)/2.
    }
    if not (TargetOLM = "False") {
        set landingRatio to stopDist / (RadarAlt - 0.6).
    }
    else {
        set landingRatio to stopDist / RadarAlt.
    }

    if ship:body:atm:sealevelpressure > 0.5 {
        return max(max(min((landingRatio * (DesiredDecel + Planet1G)) / maxDecel, maxG * Planet1G / maxDecel), minDecel), ThrottleMin).
    }
    else {
        if not (CancelVelocityHasFinished) {
            return max(CancelDist / (vxcl(up:vector, ship:position - landingzone:position):mag - 200) * CancelDist / (vxcl(up:vector, ship:position - landingzone:position):mag - 200) * 0.825 * maxDecel / maxDecel, ThrottleMin).
        }
        else {
            return max(max(min((landingRatio * (DesiredDecel + Planet1G)) / maxDecel, maxG * Planet1G / maxDecel), minDecel), 0.5 * ThrottleMin).
        }
    }
}



function LandingVector {
    if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
    if addons:tr:hasimpact {
        set LngLatErrorList to LngLatError().
        set LngError to vdot(LandingForwardDirection, ErrorVector).
        set LatError to vdot(LandingLateralDirection, ErrorVector).

        if ship:body:atm:sealevelpressure > 0.5 {
            rcs off.
            if ErrorVector:mag > max(min(RadarAlt / 20, 10), min(RadarAlt / 2, 10)) {
                set ErrorVector to ErrorVector:normalized * max(min(RadarAlt / 20, 10), min(RadarAlt / 2, 10)).
            }
        }
        if ship:body:atm:sealevelpressure < 0.5 {
            rcs on.
            if ErrorVector:mag > min(RadarAlt / 5, 7.5) {
                set ErrorVector to ErrorVector:normalized * min(max(RadarAlt / 5, 1), 7.5).
            }
        }

        if time:seconds < LandingFlipStart + LandingFlipTime {
            if LandSomewhereElse {
                set result to (angleaxis((min(time:seconds - LandingFlipStart, LandingFlipTime) / (LandingFlipTime)) * -FlipAngle, LandingLateralDirection) * LandingForwardDirection:direction):vector.
            }
            else {
                set result to (angleaxis((min(time:seconds - LandingFlipStart, LandingFlipTime) / (LandingFlipTime)) * -FlipAngle, LandingLateralDirection) * LandingForwardDirection:direction):vector.
            }
        }
        else {
            if LandSomewhereElse {
                set DesiredDecel to maxDecel.
                if ship:body:atm:sealevelpressure > 0.5 {
                    if ErrorVector:MAG < (RadarAlt + 10) and abs(LngError) < 15 and abs(LatError) < 15 and RadarAlt > 150 and LandSomewhereElse {
                        set LandSomewhereElse to false.
                        set message1:text to "<b>Target Re-acquired..</b>".
                        SetRadarAltitude().
                        LogToFile("Re-acquired Target").
                    }
                }
                if ship:body:atm:sealevelpressure < 0.5 {
                    if ErrorVector:MAG < 2 * RadarAlt {
                        set LandSomewhereElse to false.
                        set message1:text to "<b>Target Re-acquired..</b>".
                        SetRadarAltitude().
                        LogToFile("Re-acquired Target").
                    }
                }
                if verticalspeed < -30 {
                    set result to up:vector - 0.01 * vxcl(up:vector, velocity:surface).
                }
                else {
                    set result to up:vector - 0.025 * vxcl(up:vector, velocity:surface).
                }
                set message1:text to "<b>Landing Off-Target..</b>".
                if ErrorVector:MAG < 10000 {
                    set message2:text to "<b>Target Error:</b>                " + round(LngError) + "m " + round(LatError) + "m".
                }
                else {
                    set message2:text to "<b>Target Error:</b>               " + round(ErrorVector:MAG / 1000, 2) + "km".
                }
                set message1:style:textcolor to yellow.
                set message2:style:textcolor to yellow.
                set message3:style:textcolor to yellow.
            }
            else {
                if ship:body:atm:sealevelpressure > 0.5 {
                    if TargetOLM and altitude < 1000 set TowerRotationVector to vCrs(vxcl(up:vector, Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Mount")[0]:position - Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0]:position),up:vector).
                    else set TowerRotationVector to north:vector.
                    if verticalspeed < -38 and not twoSL {
                        if ErrorVector:MAG > 40 * Scale {
                            set result to up:vector - 0.015 * vxcl(TowerRotationVector, ErrorVector) - 0.015 * ErrorVector - 0.003 * GSVec.
                        } else if ErrorVector:MAG > 20 * Scale {
                            set result to up:vector - 0.01 * vxcl(TowerRotationVector, ErrorVector) - 0.01 * ErrorVector - 0.003 * GSVec.
                        } else {
                            set result to up:vector - 0.01 * ErrorVector - 0.003 * GSVec.
                        }
                    }
                    else if vxcl(TowerRotationVector, ErrorVector):mag > 8 and not twoSL {
                        if ErrorVector:MAG > 12 * Scale and ship:groundspeed > 3.5 {
                            set result to up:vector - 0.01 * vxcl(TowerRotationVector, ErrorVector) - 0.01 * GSVec - 0.005 * ErrorVector.
                        } else {
                            set result to up:vector - 0.01 * GSVec - 0.013 * vxcl(TowerRotationVector, ErrorVector) - 0.004 * vxcl(vCrs(TowerRotationVector, up:vector), ErrorVector).
                        }
                    } 
                    else if not twoSL {
                        if ErrorVector:MAG > 9 * Scale and ship:groundspeed > 3.5 {
                            set result to 1.4 * up:vector - 0.015 * GSVec - 0.011 * vxcl(TowerRotationVector, ErrorVector) - 0.007 * vxcl(vCrs(TowerRotationVector, up:vector), ErrorVector).
                        } else {
                            set result to 1.8 * up:vector - 0.02 * GSVec - 0.01 * vxcl(TowerRotationVector, ErrorVector) - 0.002 * vxcl(vCrs(TowerRotationVector, up:vector), ErrorVector).
                        }
                    } 
                    else {
                        if ErrorVector:MAG > 5 * Scale {
                            set result to up:vector - 0.03 * GSVec - 0.008 * vxcl(TowerRotationVector, ErrorVector) - 0.001 * vxcl(vCrs(TowerRotationVector, up:vector), ErrorVector) - 0.02*facing:topvector.
                            if RSS set result to up:vector - 0.034 * GSVec - 0.006 * vxcl(TowerRotationVector, ErrorVector) - 0.001 * vxcl(vCrs(TowerRotationVector, up:vector), ErrorVector) - 0.022*facing:topvector.
                        } else {
                            set result to up:vector - 0.024 * GSVec - 0.021*facing:topvector.
                        }
                        if oneSL {
                            if ErrorVector:MAG > 5 * Scale {
                                set result to up:vector - 0.03 * GSVec - 0.005 * vxcl(TowerRotationVector, ErrorVector) - 0.001 * vxcl(vCrs(TowerRotationVector, up:vector), ErrorVector) - 0.02*facing:topvector - 0.023*facing:starvector.
                                if RSS set result to up:vector - 0.034 * GSVec - 0.003 * vxcl(TowerRotationVector, ErrorVector) - 0.001 * vxcl(vCrs(TowerRotationVector, up:vector), ErrorVector) - 0.02*facing:topvector - 0.023*facing:starvector.
                            } else {
                                set result to up:vector - 0.024 * GSVec - 0.02*facing:topvector - 0.023*facing:starvector.
                            }
                        }
                        if vAng(result, facing:forevector) > 3 set result to facing:forevector + result.
                    }
                }

                if ship:body:atm:sealevelpressure < 0.5 {
                    if not (CancelVelocityHasFinished) {
                        set result to -velocity:surface.
                    }
                    else if RadarAlt > 400 {
                        set result to ship:up:vector - 0.01 * vxcl(up:vector, velocity:surface) - 0.01 * ErrorVector.
                    }
                    else if verticalspeed < -5 and RadarAlt > 25 {
                        set result to ship:up:vector - 0.0125 * vxcl(up:vector, velocity:surface) - 0.0125 * ErrorVector.
                    }
                    else {
                        set result to ship:up:vector - 0.035 * vxcl(up:vector, velocity:surface).
                    }
                }
                set message2:text to "<b>Target Error:</b>                " + round(vdot(LandingForwardDirection, vxcl(up:vector, ship:position - landingzone:position))) + "m " + round(vdot(LandingLateralDirection, vxcl(up:vector, ship:position - landingzone:position))) + "m".
                set message1:style:textcolor to white.
                set message2:style:textcolor to white.
                set message3:style:textcolor to white.
            }
        }
        //set LdgVectorDraw to vecdraw(v(0, 0, 0), 2 * result, green, "Landing Vector", 20, true, 0.005, true, true).

        clearscreen.
        print "Radar Altitude: " + round(RadarAlt, 2).
        if ship:body:atm:sealevelpressure > 0.5 {
            print "Landing Ratio:  " + round(landingRatio, 2).
        }
        else {
            print "Landing Ratio:  " + round(CancelDist / vxcl(up:vector, ship:position - landingzone:position):mag, 2).
        }
        print "desired decel:  " + round(DesiredDecel, 2).
        print "max decel: " + round(maxDecel, 2) + "m/s2".
        print "Ship Rotation:  " + round(ShipRot, 1).
        print "Ship Mass: " + round(ship:mass, 3).

        //if not maxDecel = 0 {
        //    print "current decel: " + round(throttle * maxDecel, 2) + "m/s2".
        //    print "vs: " + round(verticalspeed,2).
        //    print "close arms at: " + round((0.5 * DesiredDecel * 3 * 3), 2) + "m RA".
        //}
        set message3:text to "<b>Radar Altimeter:</b>        " + round(RadarAlt) + "m".
    }

    set ShipRot to GetShipRotation().
    DetectWobblyTower().

    wait 0.001.
    if TargetOLM and RadarAlt < 70 * Scale and not (LandSomewhereElse) {
        set RollVector to vxcl(up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - Nose:position).
        return lookDirUp(result, RollVector).
    }
    else {
        return lookDirUp(result, -LandingForwardDirection).
    }
}



//----------------After Landing------------------//



            set runningprogram to "After Landing".
            rcs off.
            set ShutdownComplete to false.
            set ShutdownProcedureStart to time:seconds.
            LogToFile("Vehicle Touchdown, performing self-check").
            if not LandSomewhereElse and not (TargetOLM) {
                set message1:text to "<b><color=green>Successful Landing Confirmed!</color></b> (" + round((SLEngines[0]:position - landingzone:position):mag - 0.5) + "m)".
            }
            else if LandSomewhereElse {
                set message1:text to "<b>Successful Landing Confirmed!</b> (" + round((SLEngines[0]:position - landingzone:position):mag) + "m)".
                set message1:style:textcolor to yellow.
            }
            else {
                rcs off.
                set message1:text to "<b><color=green>Successful Landing Confirmed!</color></b>".
            }
            set message2:text to "<b>Performing Vehicle Self-Check..</b>".
            set message2:style:textcolor to white.
            set message3:style:textcolor to white.
            lock steering to lookdirup(ship:up:vector,ship:facing:topvector).
            lock throttle to 0.
            set ship:control:translation to v(0,0,0).
            SteeringManager:RESETTODEFAULT().
            ALflap:getmodule("ModuleSEPControlSurface"):DoAction("activate yaw control", true).
            ARflap:getmodule("ModuleSEPControlSurface"):DoAction("activate yaw control", true).
            set FWDFlapDefault to 60.
            set AFTFlapDefault to 60.
            set FlapsYawEngaged to true.
            if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).}
            else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
            Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
            }
            Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
            SLEngines[0]:shutdown. SLEngines[1]:shutdown. SLEngines[2]:shutdown.
            //if GEAR {
            //    Tank:getmodule("ModuleLevelingBase"):doaction("auto-level", true).
            //}

            if TargetOLM {
                when time:seconds > ShutdownProcedureStart + 5 then {
                    sendMessage(Vessel(TargetOLM), ("MechazillaPushers,0,0.5," + round(1.32 * Scale,2) + ",false")).
                    sendMessage(Vessel(TargetOLM), ("MechazillaStabilizers," + maxstabengage)).
                }
                when time:seconds > ShutdownProcedureStart + 10 then {
                    sendMessage(Vessel(TargetOLM), ("MechazillaPushers,0,0.25," + round(1.32 * Scale, 2) + ",false")).
                    sendMessage(Vessel(TargetOLM), ("MechazillaArms,8.2,0.25,60,false")).
                }
                when time:seconds > ShutdownProcedureStart + 15 then {
                    sendMessage(Vessel(TargetOLM), ("MechazillaPushers,0,0.1," + round(1.32 * Scale, 2) + ",false")).
                }
            }

            until ShutdownComplete {
                set message3:text to "<b>Please Standby..</b> (" + round((ShutdownProcedureStart + 30) - time:seconds) + "s)".
                BackGroundUpdate().
                if time:seconds > ShutdownProcedureStart + 30 {
                    set ShutdownComplete to true.
                }
            }
            rcs off.
            sas on.
            unlock throttle.
            set ship:control:neutralize to true.
            unlock steering.
            if TargetOLM {
                setflaps(0, 0, 0, 0).
            }
            else {
                setflaps(80, 85, 1, 0).
            }
            if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 0).}
            else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
            Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 0).
            }
            Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 0).
            set message1:text to "<b><color=green>Vehicle Self-Check OK!</color></b>".
            set message1:style:textcolor to white.
            set message2:text to "<b>Re-Entry & Land Program completed..</b>".
            set message3:text to "<b>Hatches may now be opened..</b>".
            set runningprogram to "None".
            if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).}
            else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
            Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
            }
            Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
            unlock steering.
            LogToFile("Self-Check Complete, Re-Entry & Land Program Complete.").
            set textbox:style:bg to "starship_img/starship_main_square_bg".
            wait 3.
            ClearInterfaceAndSteering().
            if TargetOLM and not (RSS) {
                //HUDTEXT("Loading current Ship quicksave for safe docking! (Avoid Kraken..)", 10, 2, 20, green, false).
                sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + (1 * Scale) + ",0.4")).
                wait 2.5.
                when kuniverse:canquicksave and KUniverse:activevessel = ship then {
                    //kuniverse:quicksave().
                    wait 0.1.
                    when kuniverse:canquicksave then {
                        //kuniverse:quickload().
                    }
                }
            }
        }
    }
    else if altitude > ship:body:atm:height {
        ClearInterfaceAndSteering().
    }.
}.
print "De-Orbit & Land Program Ended".
reboot.



//----------------Other Functions---------------------//



function LngLatError {
    if addons:tr:hasimpact {
        set ErrorVector to ADDONS:TR:IMPACTPOS:POSITION - landingzone:POSITION.

        if ship:body:atm:exists {
            set ApproachUPVector to landingzone:position - ship:body:position + 100*up:vector.

            if periapsis > 0 and vang(positionat(ship, time:seconds + eta:periapsis) - ship:body:position, ApproachUPVector) < 90 {
                set ApproachVector to vxcl(ApproachUPVector, velocityat(ship, time:seconds + eta:periapsis):surface):normalized - 0.1 * up:vector:normalized.
            }
            else if periapsis > 0 and vang(positionat(ship, time:seconds + eta:periapsis) - ship:body:position, ApproachUPVector) > 90 {
                set ApproachVector to -vxcl(ApproachUPVector, velocityat(ship, time:seconds + eta:periapsis):surface):normalized - 0.1 * up:vector:normalized.
            }
            else if RadarAlt < 10000 and ship:body:atm:sealevelpressure > 0.5 {
                set ApproachVector to vxcl(up:vector, facing:forevector):normalized.
            }
            else {
                set ApproachVector to vxcl(ApproachUPVector, velocityat(ship, time:seconds + addons:tr:TIMETILLIMPACT - 120):surface):normalized - 0.1 * up:vector:normalized.
            }
        }
        else {
            set ApproachUPVector to (landingzone:position - body:position):normalized.
            if ApproachVector = v(0,0,0) or not (CancelVelocityHasStarted) {
                set ApproachVector to vxcl(ApproachUPVector, velocityat(ship, time:seconds + addons:tr:TIMETILLIMPACT - 120):surface):normalized.
            }
            else if not (LandingFacingVector = v(0, 0, 0)) {
                set ApproachVector to LandingFacingVector.
            }
        }

        //print " ".
        //print "periapsis: " + round(periapsis/1000,3).
        //print "angle: " + round(vang(positionat(ship, time:seconds + eta:periapsis) - ship:body:position, ApproachUPVector),2).

        //clearvecdraws().

        //set ApproachVectorDraw to vecdraw(v(0, 0, 0), ApproachVector, green, "Approach Vector", 20, true, 0.005, true, true).
        //set ApproachSideVectorDraw to vecdraw(v(0, 0, 0), AngleAxis(-90, ApproachUPVector) * ApproachVector, cyan, "Approach Side Vector", 20, true, 0.005, true, true).
        //set SFCVectorDraw to vecdraw(v(0, 0, 0), 5*velocity:surface:normalized, white, "Velocity Vector", 20, true, 0.005, true, true).
        //set ApproachUPVectorDraw to vecdraw(v(0, 0, 0), 5*ApproachUPVector, Blue, "Approach UP Vector", 20, true, 0.005, true, true).
        //set ApproachRAWVectorDraw to vecdraw(v(0, 0, 0), velocityat(ship, time:seconds + addons:tr:TIMETILLIMPACT - 120):surface, Magenta, "Approach Raw Vector", 20, true, 0.005, true, true).

        //set LDGFacingVectorDraw to vecdraw(v(0, 0, 0), LandingFacingVector, red, "LandingFacingVector", 20, true, 0.005, true, true).
        //set ErrorVectorDraw to vecdraw(v(0, 0, 0), ErrorVector, yellow, "ErrorVector", 20, true, 0.005, true, true).
        //set CorrectedSFVVectorDraw to vecdraw(v(0, 0, 0), vxcl(ApproachUPVector, velocity:surface), cyan, "Corrected SFC", 20, true, 0.005, true, true).


        set lngresult to vdot(ApproachVector, ErrorVector).
        if vang(ApproachVector, velocity:surface) < 90 or (landingzone:position - ship:position):mag < 25000 {
            set latresult to vdot(AngleAxis(-90, ApproachUPVector) * ApproachVector, ErrorVector).
        }
        else {
            set latresult to 0.
        }

        if ship:body:atm:sealevelpressure > 0.5 {
            if TargetOLM {
                if STOCK {
                    if ShipType:contains("Block1"){
                        set LngLatOffset to -29.
                    } else {
                        set LngLatOffset to -30.
                    }
                }
                else if KSRSS {
                    if ShipType:contains("Block1"){
                        set LngLatOffset to -33.
                    } else {
                        set LngLatOffset to -33.
                    }
                }
                else {
                    if ShipType:contains("Block1"){
                        set LngLatOffset to -116.
                    } else {
                        set LngLatOffset to -116.
                    }
                }
            }
            else {
                if STOCK {
                    set LngLatOffset to -42.
                }
                else if KSRSS {
                    set LngLatOffset to -50.
                }
                else {
                    set LngLatOffset to -112.
                    
                    
                }
            }
            if ShipType = "Crew" {
                if STOCK {
                    set LngLatOffset to LngLatOffset - 8.
                }
                if KSRSS {
                    set LngLatOffset to LngLatOffset + 8.5.
                }
                else {
                    set LngLatOffset to LngLatOffset + 12.5.
                }
            }
        }
        else if ship:body:atm:sealevelpressure < 0.5 and ship:body:atm:exists {
            if RSS {
                set LngLatOffset to (ship:mass - 125) / 150 * 20000.
            }
            else if KSRSS {
                set LngLatOffset to ship:mass / 65 * 1000.
            }
            else {
                set LngLatOffset to ship:mass / 55 * 500.
            }
        }
        else {
            set LngLatOffset to 0.
        }

        set lngresult to lngresult - LngLatOffset.

        if LandSomewhereElse {
            set lngresult to 0.
            set latresult to 0.
        }

        return list(lngresult, latresult).
    }
    else {
        return list(0, 0).
    }
}


function CalculateDeOrbitBurn {
    parameter x.
    set config:ipu to 2000.
    set idealLng to 0.
    set lngPredict to 9999.
    set AngleAccuracy to 10.

    if kuniverse:timewarp:warp > 0 {
        set kuniverse:timewarp:warp to 0.
    }

    if ship:body:atm:exists {
        if RSS {
            if ship:body:atm:sealevelpressure > 0.5 {
                set DegreestoLDGzone to 140.
            }
            else {
                set DegreestoLDGzone to 100.
            }
        }
        else if not KSRSS {
            set DegreestoLDGzone to 95.
        } else {
            set DegreestoLDGzone to 100.
        }
    }
    else if ship:body:radius > 199999 {
        set DegreestoLDGzone to 60.
    }
    else {
        set DegreestoLDGzone to 45.
    }
    if abs(ship:orbit:inclination) > 90 {
        set DegreestoLDGzone to -DegreestoLDGzone.
    }

    set idealLng to mod(landingzone:lng - DegreestoLDGzone, 360).
    if idealLng > 180 {
        set idealLng to idealLng - 360.
    }
    if idealLng < -180 {
        set idealLng to idealLng + 360.
    }

    until lngPredict > idealLng - 2 and lngPredict < idealLng + 2 {
        SendPing().

        set lngPredict to mod(body:geopositionof(positionat(ship, time:seconds + x)):lng - x / body:rotationperiod * 360, 360).
        if lngPredict > 180 {
            set lngPredict to lngPredict - 360.
        }
        if lngPredict < -180 {
            set lngPredict to lngPredict + 360.
        }

        set x to x + 10.
        if lngPredict > idealLng - 2 and lngPredict < idealLng + 2 {
            break.
        }
    }

    if ship:body:atm:exists {
        local LZPos to -angleaxis((x + DegreestoLDGzone / 360 * ship:orbit:period) / body:rotationperiod * 360, latlng(90,0):position - body:position) * (landingzone:position - body:position).

        local normalvec to normal(ship:orbit).
        local NormalVdot to vdot(normalvec, (ship:position - LZPos)).

        //clearvecdraws().
        //vecdraw(body:position, 1.25 * LZPos, white, "LZPos", 1, true).

        set message2:text to "<b>Day:  </b>" + round(x / body:rotationperiod) + " / 31     (" + round(100 * x / (body:rotationperiod * 31), 1) + "%)".

        if x > 31 * body:rotationperiod {
            return 0.
        }
        else if x < 120 {
            print "Progress: " + round(100 * x / (body:rotationperiod * 31), 1) + "%".
            print "looking 1 orbit further along..".
            return CalculateDeOrbitBurn(0.5 * ship:orbit:period - 120).
        }
        else if abs(NormalVdot) < LateralAcceptanceLimit {
            clearscreen.
            print "x: " + round(x).
            print "Progress: " + round(100 * x / (body:rotationperiod * 31), 1) + "%".
            //print "angle : " + round(VecAngle, 2).
            print "Lat. Error: " + abs(round(NormalVdot / 1000, 1)) + "km / " + (LateralAcceptanceLimit / 1000) + "km".
            return x.
        }
        else {
            print "x: " + round(x).
            print "Progress: " + round(100 * x / (body:rotationperiod * 31), 1) + "%".
            //print "angle : " + round(VecAngle, 2).
            print "Lat. Error: " + abs(round(NormalVdot / 1000, 1)) + "km / " + (LateralAcceptanceLimit / 1000) + "km".
            return CalculateDeOrbitBurn(x + ship:orbit:period).
        }
    }
    else {
        return x.
    }
}


function DeOrbitVelocity {
    set Error to 999999.
    set PrevError to Error.
    set message3:style:textcolor to white.
    set message2:text to "".
    if ship:body:atm:sealevelpressure > 0.5 {
        if RSS {
            set StartPoint to -altitude / 4000.
        }
        else if KSRSS {
            set StartPoint to -altitude / 1250.
        }
        else {
            set StartPoint to -altitude / 1000.
        }
    }
    else if ship:body:atm:sealevelpressure < 0.5 {
        if RSS {
            set StartPoint to -altitude / 2000.
        }
        else if KSRSS {
            set StartPoint to -altitude / 2000.
        }
        else {
            if ship:body:name = "minmus" {
                set StartPoint to -altitude / 1500.
            }
            else {
                set StartPoint to -altitude / 1000.
            }
        }
    }
    else {
        set StartPoint to 0.
    }
    set ProgradeVelocity to StartPoint.
    //print "Prograde before correction: " + round(ProgradeVelocity, 1).

    local RotationTime to (TimeToBurn + DegreestoLDGzone / 360 * ship:orbit:period).
    local BodyRotation to mod(RotationTime / body:rotationperiod * 360, 360).
    local OrbitRotation to mod(RotationTime / ship:orbit:period, 360).

    if ship:body:atm:exists {
        set LngError to 9999.
        //clearvecdraws().

        local LZPos to -angleaxis(BodyRotation, latlng(90,0):position - body:position) * (landingzone:position - body:position).
        set ApproachUPVector to LZPos:normalized.
        set ApproachVector to velocityat(ship, time:seconds + RotationTime):orbit:normalized.

        //local NewPos to positionat(ship, time:seconds + RotationTime).
        //set apprvec to vecdraw(NewPos, 2500000 * ApproachVector, green, "Approach Vector", 1, true).
        //set apprupvec to vecdraw(NewPos, 2500000 * ApproachUpVector, cyan, "Approach Up Vector", 1, true).

        until abs(LngError) < 2500 {
            SendPing().
            set burn to node(deorbitburnstarttime, 0, 0, ProgradeVelocity).
            add burn.
            set calcTime to time:seconds.

            until addons:tr:hasimpact {
                if time:seconds > calcTime + 0.25 {
                    set config:ipu to CPUSPEED.
                    return 0.
                }
            }

            if addons:tr:hasimpact {
                set ErrorVector to -angleaxis(BodyRotation, latlng(90,0):position - body:position) * (ADDONS:TR:IMPACTPOS:POSITION - landingzone:POSITION).
                //set errvec to vecdraw(NewPos, 2 * ErrorVector, Blue, "Error Vector", 1, true).
                wait 0.001.

                set LngError to vdot(ApproachVector, vxcl(ApproachUPVector, ErrorVector)).
                //set message2:text to "<b>Longitudinal Error: </b>" + round(LngError / 1000, 1) + "km".
                print "Lng Error: " + round(LngError).

                if abs(LngError) < 1000 {
                    break.
                }

                if RSS {
                    set ProgradeVelocity to ProgradeVelocity - LngError / 500000.
                }
                else if KSRSS {
                    set ProgradeVelocity to ProgradeVelocity - LngError / 35000.
                }
                else {
                    set ProgradeVelocity to ProgradeVelocity - LngError / 10000.
                }
            }
            else {
                set config:ipu to CPUSPEED.
                return 0.
            }
            if abs(ProgradeVelocity) > 250 {
                set config:ipu to CPUSPEED.
                return 0.
            }
            remove burn.
            wait until not (addons:tr:hasimpact).
        }
        if addons:tr:hasimpact {
            if (landingzone:position - addons:tr:impactpos:position):mag > LateralAcceptanceLimit {
                //wait 3.
                remove burn.
                //print TimeToBurn.
                set TimeToBurn to CalculateDeOrbitBurn(TimeToBurn + 0.9 * ship:orbit:period).
                set deorbitburnstarttime to timestamp(time:seconds + TimeToBurn).
                //print TimeToBurn.
                return DeOrbitVelocity().
            }
        }
    }
    else {
        set NormalVelocity to 0.
        if ship:body:name = "Minmus" or ship:body:name = "Gilly" or ship:body:name = "Ike" {
            set SafeAltOverLZ to 500.
        }
        set GoalAltOverLZ to landingzone:terrainheight + SafeAltOverLZ.
        set x to (deorbitburnstarttime + 0.24 * ship:orbit:period):seconds - time:seconds.
        set OVHDlng to -9999.
        until OVHDlng > landingzone:lng {
            set OVHDlng to ship:body:geopositionof(positionat(ship, time:seconds + x)):lng.
            set x to x + 1.
        }
        set TimeToOVHD to x.

        local LZPos to -angleaxis(BodyRotation, latlng(90,0):position - body:position) * (landingzone:position - body:position).
        set ApproachUPVector to LZPos:normalized.
        set ApproachVector to velocityat(ship, time:seconds + RotationTime):orbit:normalized.

        //set ApproachUPVector to (landingzone:position - body:position):normalized.
        //set ApproachVector to vxcl(ApproachUPVector, velocityat(ship, timestamp(time:seconds + x)):surface):normalized.
        until false {
            SendPing().
            set burn to node(deorbitburnstarttime, 0, NormalVelocity, ProgradeVelocity).
            add burn.

            if addons:tr:hasimpact {
                if RSS {
                    set x to min(x - 5, addons:tr:TIMETILLIMPACT - 60).
                }
                else {
                    set x to min(x - 5, addons:tr:TIMETILLIMPACT - 20).
                }
            }
            else {
                set x to x - 5.
            }
            set OVHDlng to -9999.
            until OVHDlng > landingzone:lng + x / ship:body:rotationperiod * 360 {
                set OVHDlng to ship:body:geopositionof(positionat(ship, time:seconds + x)):lng.
                set x to x + 1.
            }
            set TimeToOVHD to x.
            set AltitudeOverLZ to ship:body:altitudeof(positionat(ship, time:seconds + TimeToOVHD)).

            //print "OVHD Point: " + ship:body:geopositionof(positionat(ship, time:seconds + TimeToOVHD)):lng.
            print "Time to overhead: " + round(TimeToOVHD).
            print "Altitude over LZ: " + round(AltitudeOverLZ) + "   /   " + round(GoalAltOverLZ).

            //set OVHDpoint to vecdraw(positionat(ship, time:seconds + TimeToOVHD), ship:position - positionat(ship, time:seconds + TimeToOVHD), green, "OVHD Point", 1, true).

            set ApproachVector to vxcl(ApproachUPVector, velocityat(ship, timestamp(time:seconds + x)):surface):normalized.
            set LZatNewTime to latlng(landingzone:lat, landingzone:lng + TimeToOVHD / body:rotationperiod * 360).
            set ToLZVector to (LZatNewTime:position - positionat(ship, time:seconds + TimeToOVHD)).
            set ApproachLateralError to vdot(AngleAxis(-90, ApproachUPVector) * ApproachVector, ToLZVector).

            //set apprvec to vecdraw(ship:position, 25 * ApproachVector, green, "Approach Vector", 1, true).
            //set tolzvec to vecdraw(positionat(ship, time:seconds + TimeToOVHD), ToLZVector, blue, "toLZ Vector", 1, true).
            wait 0.001.

            print "Lateral Difference: " + ApproachLateralError.

            if abs(AltitudeOverLZ - GoalAltOverLZ) < 100 and abs(ApproachLateralError) < 1 {
                break.
            }
            set ProgradeVelocity to ProgradeVelocity - ((ship:body:altitudeof(positionat(ship, time:seconds + TimeToOVHD)) - GoalAltOverLZ) / 10000).
            set NormalVelocity to NormalVelocity + ApproachLateralError / 5000.
            remove burn.
            wait until not (addons:tr:hasimpact).

            if abs(ProgradeVelocity) > 1000 or abs(NormalVelocity) > 250 {
                set ProgradeVelocity to 0.
                set NormalVelocity to 0.
                clearscreen.
                break.
            }
        }
        remove burn.
        set config:ipu to CPUSPEED.
        set AltitudeOverLZ to AltitudeOverLZ - landingzone:terrainheight.
        return list(ProgradeVelocity, NormalVelocity, AltitudeOverLZ).
    }
    remove burn.
    set config:ipu to CPUSPEED.
    return ProgradeVelocity.
}



function timeSpanCalculator {
    parameter InputTimeSpan.
    local input to timespan(InputTimeSpan).
    set inputprocessed to "".
    if input > 0 {
        if input:year > 0 {set inputprocessed to input:year + "y".}
        if input:day > 0 {set inputprocessed to inputprocessed + input:day + "d".}
        if input:hour > 0 {set inputprocessed to inputprocessed + input:hour + "h".}
        if input:minute > 0 and input:year = 0 {set inputprocessed to inputprocessed + input:minute + "m".}
        if input:year = 0 and input:day = 0 {
            set inputprocessed to inputprocessed + input:second + "s".
        }
    }
    else {
        if input:year < -1 {set inputprocessed to (input:year + 1) + "y".}
        if input:day < -1 {set inputprocessed to inputprocessed + (input:day + 1) + "d".}
        if input:hour < -1 {set inputprocessed to inputprocessed + (input:hour + 1) + "h".}
        if input:minute < -1 and input:year = -1 {set inputprocessed to inputprocessed + (input:minute + 1) + "m".}
        if input:year = -1 and input:day = -1 {
            set inputprocessed to inputprocessed + (input:second + 1) + "s".
        }
    }
    return inputprocessed.
}






function ClearInterfaceAndSteering {
    ShowHomePage().
    wait 0.001.
    lock throttle to 0.
    set ship:control:pilotmainthrottle to 0.
    set ApproachVector to v(0,0,0).
    ShutDownAllEngines().
    set ship:control:translation to v(0, 0, 0).
    unlock steering.
    set runningprogram to "None".
    if hasnode {
        remove nextnode.
        wait 0.001.
    }
    InhibitButtons(0, 1, 1).
    set message1:text to "".
    set message2:text to "".
    set message3:text to "".
    set message1:style:textcolor to white.
    set message2:style:textcolor to white.
    set message3:style:textcolor to white.
    set maneuver2label1:text to "".
    set maneuver3label1:text to "".
    set maneuver3label2:text to "".
    set maneuver3label3:text to "".
    set executeconfirmed to false.
    set cancelconfirmed to false.
    set cancel:text to "<b>CANCEL</b>".
    //set TwoVacEngineLanding to false.
    //set FourVacBrakingBurn to false.
    set landbutton:pressed to false.
    set launchbutton:pressed to false.
    wait 0.001.
    unlock throttle.
    set LandButtonIsRunning to false.
    set LaunchButtonIsRunning to false.
    wait 0.001.
    ToggleHeaderTank(1).
    if Boosterconnected {
        HideEngineToggles(1).
    }
    else {
        HideEngineToggles(0).
    }
    wait 0.001.
    if ShipType = "Cargo" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_cargo".
        if Nose:name:contains("SEP.23.SHIP.FLAPS") {set textbox:style:bg to "starship_img/starship_main_square_bg_cargoFLAPS".}
    }
    if ShipType = "Crew" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_crew".
    }
    if ShipType = "Block1" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1".
    }
    if ShipType = "Block1Cargo" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1cargo".
    }
    if ShipType = "Block1CargoExp" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1cargoexp".
    }
    if ShipType = "Block1Exp" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1exp".
    }
    if ShipType = "Block1PEZ" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1PEZ".
    }
    if ShipType = "Block1PEZExp" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1PEZexp".
    }
    if ShipType = "Tanker" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_tanker".
    }
    if ShipType = "Expendable" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_expendable".
    }
    if ShipType = "Depot" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_depot".
    }
    set launchlabel:style:textcolor to white.
    set launchlabel:style:bg to "starship_img/starship_background_dark".
    set landlabel:style:textcolor to white.
    set landlabel:style:bg to "starship_img/starship_background_dark".
    if defined AltitudeOverLZ {
        unset AltitudeOverLZ.
    }
    set ApproachVector to v(0,0,0).
    set LZFinderCancelled to false.
    set config:ipu to CPUSPEED.
    if kuniverse:timewarp:warp > 0 {
        set kuniverse:timewarp:warp to 0.
    }
    set t to 0.
    LogToFile("Interface cleared").
}














//-----------------Engine Functions----------------------//

function ActivateEngines {
    parameter WhichEngines.
    if WhichEngines = 0 {
        SLEngines[0]:activate.
        SLEngines[1]:activate.
        SLEngines[2]:activate.
        SLEngines[0]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
        SLEngines[1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
        SLEngines[2]:getmodule("ModuleGimbal"):SetField("gimbal limit", 100).
        LogToFile("SL Engine Start Successful!").
    }
    else {
        for eng in VACEngines {
            eng:activate.
        }
        LogToFile("VAC Engine Start Successful!").
    }
    if not (ShipType = "Expendable") and not (ShipType = "Depot") and not (ShipType:contains("Block1")) {
        Nose:shutdown.
    } else if ShipType = "Block1" or ShipType = "Block1Cargo" or ShipType = "Block1PEZ" {
        HeaderTank:shutdown.
    } 
    Tank:shutdown.
}


function ShutDownAllEngines {
    if quickengine1:pressed = true {
        set quickengine1:pressed to false.
    }
    set quickengine1:pressed to true.
}


function confirm {
    set executeconfirmed to 0.
    set cancelconfirmed to 0.
    Droppriority().
    until executeconfirmed or cancelconfirmed {
        BackGroundUpdate().
    }
    if executeconfirmed {set action to 1.}
    if cancelconfirmed {set action to 0.}
    set executeconfirmed to 0.
    set cancelconfirmed to 0.
    return action.
}




function SendPing {
    if defined watchdog {
        sendMessage(Processor(volume("watchdog")), "ping").
    }
}


function ShowButtons {
    parameter show.
    if show = 0 {
        launchbutton:hide().
        landbutton:hide().
        wait until not (launchbutton:visible) and not (landbutton:visible).
        launchlabel:show().
        landlabel:show().
    }
    if show = 1 {
        launchlabel:hide().
        landlabel:hide().
        wait until not (launchlabel:visible) and not (landlabel:visible).
        launchbutton:show().
        landbutton:show().
    }
}


function ShowHomePage {
    set settingsbutton:pressed to false.
    set cargobutton:pressed to false.
    set statusbutton:pressed to false.
    set orbitbutton:pressed to false.
    set attitudebutton:pressed to false.
    set enginebutton:pressed to false.
    set crewbutton:pressed to false.
    set towerbutton:pressed to false.
    set maneuverbutton:pressed to false.
    mainbox:showonly(flightstack).
    LogToFile("Interface set to Main Screen").
}


function LogToFile {
    parameter msg.
    if quicksetting3:pressed {
        if homeconnection:isconnected {
            if msg = "Re-Entry Telemetry" {
                if defined PrevLogTimeLanding {
                    set TimeStep to 1.
                    if RadarAlt > 550 {set TimeStep to 1.}
                    else {set TimeStep to 0.25.}
                    if timestamp(time:seconds) > PrevLogTimeLanding + TimeStep {
                        if (landingzone:lng - ship:geoposition:lng) < -180 {
                            set LngDistanceToTarget to ((landingzone:lng - ship:geoposition:lng + 360) * Planet1Degree).
                            set LatDistanceToTarget to max(landingzone:lat - ship:geoposition:lat, ship:geoposition:lat - landingzone:lat) * Planet1Degree.
                            if LatDistanceToTarget < 0 {set LatDistanceToTarget to -1 * LatDistanceToTarget.}
                            set DistanceToTarget to sqrt(LngDistanceToTarget * LngDistanceToTarget + LatDistanceToTarget * LatDistanceToTarget).
                        }
                        else {
                            set LngDistanceToTarget to ((landingzone:lng - ship:geoposition:lng) * Planet1Degree).
                            set LatDistanceToTarget to max(landingzone:lat - ship:geoposition:lat, ship:geoposition:lat - landingzone:lat) * Planet1Degree.
                            if LatDistanceToTarget < 0 {set LatDistanceToTarget to -1 * LatDistanceToTarget.}
                            set DistanceToTarget to sqrt(LngDistanceToTarget * LngDistanceToTarget + LatDistanceToTarget * LatDistanceToTarget).
                        }
                        if alt:radar > 1500 {
                            if homeconnection:isconnected {
                                LOG ("Time: " + timestamp():clock + "   Dist: " + round(DistanceToTarget, 3) + "km   Alt: " + round(altitude) + "m   Vert Speed: " + round(ship:verticalspeed,1) + "m/s   Airspeed: " + round(airspeed, 1) + "m/s   Trk/X-Trk Error: " + round((LngLatErrorList[0] + LngLatOffset) / 1000, 3) + "km  " + round((LngLatErrorList[1] / 1000), 3) + "km") to "0:/FlightData.txt".
                            }
                            if homeconnection:isconnected {
                                LOG ("                 Actual AoA: " + round(vang(ship:facing:forevector, velocity:surface), 1) + "°   Throttle: " + (100 * throttle) + "%   Battery: " + round(100 * (ship:electriccharge / ELECcap), 2) + "%   Mass: " + round(ship:mass * 1000, 3) + "kg") to "0:/FlightData.txt".
                            }
                            if homeconnection:isconnected {
                                LOG ("                 Radar Altitude: " + round(RadarAlt, 1) + "m") to "0:/FlightData.txt".
                            }
                            if homeconnection:isconnected {
                                LOG "" to "0:/FlightData.txt".
                            }
                            if homeconnection:isconnected {
                                LOG (timestamp():clock + "," + DistanceToTarget + "," + altitude + "," + ship:verticalspeed + "," + airspeed + "," + (LngLatErrorList[0] + LngLatOffset) + "," + LngLatErrorList[1] + "," + vang(ship:facing:forevector, velocity:surface) + "," + (100 * throttle) + "," + (100 * (LFShip / LFShipCap)) + "," + (ship:mass * 1000) + "," + RadarAlt) to "0:/LandingData.csv".
                            }
                        }
                        else {
                            LOG ("Time: " + timestamp():clock + "   Dist: " + round(DistanceToTarget, 3) + "km   Alt: " + round(altitude) + "m   Vert Speed: " + round(ship:verticalspeed,1) + "m/s   Airspeed: " + round(airspeed, 1) + "m/s   Trk/X-Trk Error: " + round((LngLatErrorList[0] + LngLatOffset) / 1000, 3) + "km  " + round((LngLatErrorList[1] / 1000), 3) + "km") to "0:/FlightData.txt".
                            LOG ("                 Actual AoA: " + round(vang(ship:facing:forevector, velocity:surface), 1) + "°   Throttle: " + (100 * throttle) + "%   Battery: " + round(100 * (ship:electriccharge / ELECcap), 2) + "%   Mass: " + round(ship:mass * 1000, 3) + "kg") to "0:/FlightData.txt".
                            LOG ("                 Radar Altitude: " + round(RadarAlt, 1) + "m   Groundspeed: " + round(groundspeed,1) + "m/s") to "0:/FlightData.txt".
                            LOG "" to "0:/FlightData.txt".
                            LOG (timestamp():clock + "," + DistanceToTarget + "," + altitude + "," + ship:verticalspeed + "," + airspeed + "," + (LngLatErrorList[0] + LngLatOffset) + "," + LngLatErrorList[1] + "," + vang(ship:facing:forevector, velocity:surface) + "," + (100 * throttle) + "," + (100 * (ship:electriccharge / ELECcap)) + "," + (ship:mass * 1000) + "," + RadarAlt) to "0:/LandingData.csv".
                        }
                        set PrevLogTimeLanding to timestamp(time:seconds).
                    }
                }
                else {
                    set PrevLogTimeLanding to timestamp(time:seconds).
                    if homeconnection:isconnected {
                        LOG "Time, Distance to Target (km), Altitude (m), Vertical Speed (m/s), Airspeed (m/s), Track Error (m), Cross-Track Error (m), Actual AoA (°), Throttle (%), Battery (%), Mass (kg), Radar Altitude" to "0:/LandingData.csv".
                    }
                }
            }
            else if msg = "Launch Telemetry" {
                if defined PrevLogTimeLaunch {
                    set TimeStep to 1.
                    if timestamp(time:seconds) > PrevLogTimeLaunch + TimeStep {
                        set DistanceToTarget to ((landingzone:lng - ship:geoposition:lng) * Planet1Degree).
                        LOG ("Time: " + timestamp():clock + "   Dist: " + round(DistanceToTarget, 3) + "km   Alt: " + round(altitude) + "m   Vert Speed: " + round(ship:verticalspeed,1) + "m/s   Airspeed: " + round(airspeed, 1) + "m/s   Trk/X-Trk Error: " + 0 + "km  " + 0 + "km") to "0:/FlightData.txt".
                        LOG ("                 Actual AoA: " + round(vang(ship:facing:forevector, velocity:surface), 1) + "°   Throttle: " + (100 * throttle) + "%   Battery: " + round(100 * (ship:electriccharge / ELECcap), 2) + "%   Mass: " + round(ship:mass * 1000, 3) + "kg") to "0:/FlightData.txt".
                        LOG ("                 Radar Altitude: " + round(RadarAlt,1) + "m") to "0:/FlightData.txt".
                        LOG "" to "0:/FlightData.txt".
                        LOG (timestamp():clock + "," + DistanceToTarget + "," + altitude + "," + ship:verticalspeed + "," + airspeed + "," + 0 + "," + 0 + "," + vang(ship:facing:forevector, velocity:surface) + "," + (100 * throttle) + "," + (100 * (ship:electriccharge / ELECcap)) + "," + (ship:mass * 1000) + "," + RadarAlt) to "0:/LaunchData.csv".
                        set PrevLogTimeLaunch to timestamp(time:seconds).
                    }
                }
                else {
                    set PrevLogTimeLaunch to timestamp(time:seconds).
                    LOG "Time, Distance to Target (km), Altitude (m), Vertical Speed (m/s), Airspeed (m/s), Track Error (m), Cross-Track Error (m), Actual AoA (°), Throttle (%), Battery (%), Mass (kg), Radar Altitude" to "0:/LaunchData.csv".
                }
            }
            else {
                if homeconnection:isconnected {
                    LOG "" to "0:/FlightData.txt".
                }
                if homeconnection:isconnected {
                    LOG "Time: " + timestamp():clock + "   " + msg to "0:/FlightData.txt".
                }
                if homeconnection:isconnected {
                    LOG "" to "0:/FlightData.txt".
                }
                if homeconnection:isconnected {
                    LOG "" to "0:/FlightData.txt".
                }
            }
        }
    }
}


function SaveToSettings {
    parameter key.
    parameter value.
    if homeconnection:isconnected {
        set L to readjson("0:/settings.json").
        set L[key] to value.
        writejson(L, "0:/settings.json").
    }
    else {
        print "No connection, " + (key) + " : " +  (value) + " not saved".
    }
}


function HideEngineToggles {
    parameter hide.
    if hide {
        set EngineTogglesHidden to true.
        enginecheckboxes:hide().
        set engine1label1:style:margin:left to 35.
        set engine2label1:style:margin:left to 35.
        set engine2label2:style:overflow:left to 131.
        set engine2label2:style:overflow:right to -70.
        set engine3label1:style:margin:left to 37.
        set engine3label2:style:align to "LEFT".
        set engine1label4:style:align to "RIGHT".
        set engine3label2:style:margin:left to 15.
        set engine3label4:style:margin:left to 35.
        set engine2label4:style:margin:left to 35.
        set engine2label4:style:overflow:left to -79.
        set engine2label4:style:overflow:right to 139.
        if Boosterconnected {
            set engine1label4:text to "".
            set engine2label3:style:overflow:left to 23.
            set engine2label3:style:overflow:right to 43.
            set engine2label3:style:overflow:top to 8.
            set engine2label3:style:overflow:bottom to 71.
        }
        else {
            set engine2label3:style:overflow:left to 65.
            set engine2label3:style:overflow:right to 65.
            set engine2label3:style:overflow:top to -5.
            set engine2label3:style:overflow:bottom to 55.
            if NrOfVacEngines = 6 {
                set engine2label3:style:bg to "starship_img/starship_9engine_none_active".
            }
            if NrOfVacEngines = 3 {
                set engine2label3:style:bg to "starship_img/starship_6engine_none_active".
            }
            set engine1label4:text to "-".
        }
    }
    else {
        set EngineTogglesHidden to false.
        enginecheckboxes:show().
        set engine1label1:style:margin:left to 5.
        set engine2label1:style:margin:left to 10.
        set engine2label2:style:overflow:left to 110.
        set engine2label2:style:overflow:right to -50.
        set engine3label1:style:margin:left to 8.
        set engine3label2:style:align to "CENTER".
        set engine3label2:style:margin:left to 5.
        set engine3label4:style:margin:left to 0.
        set engine2label4:style:margin:left to 20.
        set engine2label3:style:overflow:left to 65.
        set engine2label3:style:overflow:right to 65.
        set engine2label3:style:overflow:top to -5.
        set engine2label3:style:overflow:bottom to 55.
        set engine2label4:style:overflow:left to -50.
        set engine2label4:style:overflow:right to 110.
        set engine1label4:text to "-".
        set engine1label4:style:align to "LEFT".
    }
}



function updateCargoPage {
    if not CargoPageIsRunning {
        set CargoPageIsRunning to true.
        if time:seconds > prevCargoPageTime + 0.1 {
            if NrofCargoItems = 0 {
                set cargo1label2:style:textcolor to grey.
                set cargo2label2:style:textcolor to grey.
                set cargo3label2:style:textcolor to grey.
                set cargo2label2:text to "-".
                set cargo3label2:text to "-".
            }
            else {
                set cargo1label2:style:textcolor to white.
                set cargo2label2:style:textcolor to white.
                set cargo3label2:style:textcolor to white.
                set cargo2label2:text to round(CargoMass) + " kg".
                if NrofCargoItems = 1 {
                    set cargo3label2:text to "1 Item<size=14> (" + round(CargoCG) + "i.u.)</size>".
                }
                else {
                    if Boosterconnected {
                        set cargo3label2:text to NrofCargoItems + " Items".
                    }
                    else {
                        if CargoCG > 100 {
                            set cargo3label2:text to NrofCargoItems + " Items<size=12> (" + round(CargoCG) + "i.u.)</size>".
                        }
                        else {
                            set cargo3label2:text to NrofCargoItems + " Items<size=14> (" + round(CargoCG) + "i.u.)</size>".
                        }
                    }
                }
            }
            if ShipType = "Crew" or ShipType = "Cargo" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp" or ShipType = "Block1PEZ" {
                for x in range(0, Nose:modules:length) {
                    if ShipType = "Crew" {
                        if Nose:getmodulebyindex(x):hasaction("toggle airlock") {
                            set AirlockStatus to Nose:getmodulebyindex(x):getfield("status").
                            if Nose:getmodulebyindex(x):hasevent("open airlock") and not (AirlockStatus = "Moving...") {
                                set AirlockStatus to "Closed".
                            }
                            else if Nose:getmodulebyindex(x):hasevent("close airlock") and not (AirlockStatus = "Moving...") {
                                set AirlockStatus to "Open".
                            }
                        }
                        if Nose:getmodulebyindex(x):hasaction("toggle docking hatch") {
                            set DockingHatchStatus to Nose:getmodulebyindex(x):getfield("status").
                            if Nose:getmodulebyindex(x):hasevent("open docking hatch") and not (DockingHatchStatus = "Moving...") {
                                set DockingHatchStatus to "Closed".
                            }
                            else if Nose:getmodulebyindex(x):hasevent("close docking hatch") and not (DockingHatchStatus = "Moving...") {
                                set DockingHatchStatus to "Open".
                            }
                        }
                    }
                    if ShipType = "Cargo" or ShipType = "Expendable" or ShipType = "Block1CargoExp" or ShipType = "Block1Exp" or ShipType = "Block1PEZExp"  or ShipType = "Block1PEZ" {
                        if Nose:getmodulebyindex(x):hasaction("toggle cargo door") {
                            set DockingHatchStatus to Nose:getmodulebyindex(x):getfield("status").
                        } else if Nose:getmodulebyindex(x):hasaction("toggle pez door") {
                            set DockingHatchStatus to Nose:getmodulebyindex(x):getfield("status").
                        }
                        if DockingHatchStatus = "Locked" and Nose:getmodulebyindex(x):hasevent("open cargo door") {
                            set cargoimage:style:bg to "starship_img/starship_cargobay_closed".
                            set cargo1text:style:textcolor to green.
                            set cargo1text:text to "Closed".
                        }
                        else if DockingHatchStatus = "Moving..." {
                            set cargoimage:style:bg to "starship_img/starship_cargobay_moving".
                            set cargo1text:style:textcolor to yellow.
                            set cargo1text:text to "Moving...".
                        }
                        else if DockingHatchStatus = "Locked" and Nose:getmodulebyindex(x):hasevent("close cargo door") {
                            set cargoimage:style:bg to "starship_img/starship_cargobay_open".
                            set cargo1text:style:textcolor to green.
                            set cargo1text:text to "Open".
                        } 
                        
                        else if DockingHatchStatus = "Locked" and Nose:getmodulebyindex(x):hasevent("open pez door") {
                            set cargoimage:style:bg to "starship_img/starship_cargobay_closed".
                            set cargo1text:style:textcolor to green.
                            set cargo1text:text to "Closed".
                        }
                        else if DockingHatchStatus = "Moving..." {
                            set cargoimage:style:bg to "starship_img/starship_cargobay_moving".
                            set cargo1text:style:textcolor to yellow.
                            set cargo1text:text to "Moving...".
                        }
                        else if DockingHatchStatus = "Locked" and Nose:getmodulebyindex(x):hasevent("close pez door") {
                            set cargoimage:style:bg to "starship_img/starship_cargobay_open".
                            set cargo1text:style:textcolor to green.
                            set cargo1text:text to "Open".
                        }
                    }
                }
                if ShipType = "Crew" {
                    if AirlockStatus = "Open" and DockingHatchStatus = "Open" and not (AirlockStatus = "Moving...") and not (DockingHatchStatus = "Moving...") {
                        set cargo1text:text to "Open".
                        set cargo1text:style:textcolor to green.
                    }
                    else if AirlockStatus = "Moving..." or DockingHatchStatus = "Moving..." {
                        set cargo1text:text to "Moving...".
                        set cargo1text:style:textcolor to yellow.
                    }
                    else {
                        set cargo1text:text to "Closed".
                        set cargo1text:style:textcolor to green.
                    }
                    if AirlockStatus = "Closed" and DockingHatchStatus = "Closed" {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_closed_airlock_closed".
                    }
                    if AirlockStatus = "Open" and DockingHatchStatus = "Open" {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_open_airlock_open".
                    }
                    if AirlockStatus = "Moving..." and DockingHatchStatus = "Open" {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_open_airlock_moving".
                    }
                    if AirlockStatus = "Open" and DockingHatchStatus = "Moving..." {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_moving_airlock_open".
                    }
                    if AirlockStatus = "Moving..." and DockingHatchStatus = "Closed" {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_closed_airlock_moving".
                    }
                    if AirlockStatus = "Closed" and DockingHatchStatus = "Moving..." {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_moving_airlock_closed".
                        set cargo1text:style:textcolor to yellow.
                    }
                    if AirlockStatus = "Moving" and DockingHatchStatus = "Moving..." {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_moving_airlock_moving".
                    }
                    if AirlockStatus = "Open" and DockingHatchStatus = "Closed" {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_closed_airlock_open".
                    }
                    if AirlockStatus = "Closed" and DockingHatchStatus = "Open" {
                        set cargoimage:style:bg to "starship_img/starship_crew_hatch_open_airlock_closed".
                    }
                }
            }
            set prevCargoPageTime to time:seconds.
        }
        set CargoPageIsRunning to false.
    }
}


function updateTower {
    if not towerPageIsRunning {
        set towerPageIsRunning to true.
        if TargetOLM or OnOrbitalMount {
            if OnOrbitalMount {
                if homeconnection:isconnected {
                    if exists("0:/settings.json") {
                        set L to readjson("0:/settings.json").
                        if L:haskey("Tower:arms:rotation") {
                            set tower4label2:text to "<b>" + round(L["Tower:arms:rotation"], 1):tostring + "/" + towerrot + "°</b>".
                            set tower4label3:text to "<b>" + round(L["Tower:arms:angle"], 1):tostring + "/" + towerang + "°</b>".
                            if RSS {
                                set tower4label4:text to "<b>" + round(104 - L["Tower:arms:height"], 1):tostring + "/" + towerhgt + "m</b>".
                            }
                            else {
                                set tower4label4:text to "<b>" + round(65 - L["Tower:arms:height"], 1):tostring + "/" + towerhgt + "m</b>".
                            }
                            set tower12label2:text to "<b>" + round(L["Tower:pushers:extension"], 2):tostring + "/" + towerpushfwd + "m</b>".
                            if towerstab = 0 {
                                set tower12label3:text to "<b>STOWED</b>".
                            }
                            else {
                                set tower12label3:text to "<b>ACTIVE</b>".
                            }
                        }
                    }
                }
            }
            else if Vessel(TargetOLM):distance < 500 {
                if homeconnection:isconnected {
                    if exists("0:/settings.json") {
                        set L to readjson("0:/settings.json").
                        if L:haskey("Tower:arms:rotation") {
                            set tower4label2:text to "<b>" + round(L["Tower:arms:rotation"], 1):tostring + "/" + towerrot + "°</b>".
                            set tower4label3:text to "<b>" + round(L["Tower:arms:angle"], 1):tostring + "/" + towerang + "°</b>".
                            if RSS {
                                set tower4label4:text to "<b>" + round(104 - L["Tower:arms:height"], 1):tostring + "/" + towerhgt + "m</b>".
                            }
                            else {
                                set tower4label4:text to "<b>" + round(65 - L["Tower:arms:height"], 1):tostring + "/" + towerhgt + "m</b>".
                            }
                            set tower12label2:text to "<b>" + round(L["Tower:pushers:extension"], 2):tostring + "/" + towerpushfwd + "m</b>".
                            if L["Tower:Stabilizers:extension"] = 0 {
                                set tower12label3:text to "<b>STOWED</b>".
                            }
                            else {
                                set tower12label3:text to "<b>ACTIVE</b>".
                            }
                        }
                    }
                }
            }
        }
        set towerPageIsRunning to false.
    }
}


function SetRadarAltitude {
    if ship:rootpart = "SEP.23.SHIP.CREW" or ship:rootpart = "SEP.23.SHIP.CARGO" or ship:rootpart = "SEP.23.SHIP.TANKER" or ship:rootpart = "SEP.24.SHIP.NOSECONE" {
        if RSS {
            set ShipBottomRadarHeight to 39.5167.
        }
        else {
            set ShipBottomRadarHeight to 24.698.
        }
    }
    else {
        if RSS {
            set ShipBottomRadarHeight to 14.64.
        }
        else {
            set ShipBottomRadarHeight to 9.15.
        }
    }
    if TargetOLM and not (LandSomewhereElse) {
        if RSS {
            lock RadarAlt to altitude - max(ship:geoposition:terrainheight, 0) - ArmsHeight + (39.5167 - ShipBottomRadarHeight) - 0.1.
        }
        else {
            lock RadarAlt to altitude - max(ship:geoposition:terrainheight, 0) - ArmsHeight + (24.698 - ShipBottomRadarHeight) - 0.1.
        }
        LogToFile("Radar Altitude set.. (" + round(ArmsHeight + (39.5167 - ShipBottomRadarHeight) - 0.1, 1) + ")").
    }
    else {
        lock RadarAlt to alt:radar - ShipBottomRadarHeight + 0.1.
        LogToFile("Radar Altitude set (no OLM)").
    }
}


function SetPlanetData {
    set Planet1Degree to (ship:body:radius / 1000 * 2 * constant:pi) / 360.
    set Planet1G to CONSTANT():G * (ship:body:mass / (ship:body:radius * ship:body:radius)).
    if ship:body:atm:sealevelpressure > 0.5 {
        if alt:radar < 10000 and airspeed < 300 and verticalspeed < -10 {
            set aoa to LandingAoA.
            set DescentAngles to list(aoa, aoa, aoa, LandingAoA).
        }
        else {
            set DescentAngles to list(aoa, aoa, aoa, LandingAoA).
        }
        if RSS {
            set LongitudinalAcceptanceLimit to 460000.
            set LateralAcceptanceLimit to 90000.
        }
        else if KSRSS {
            set LongitudinalAcceptanceLimit to 65000.
            set LateralAcceptanceLimit to 46000.
        }
        else {
            set LongitudinalAcceptanceLimit to 40000.
            set LateralAcceptanceLimit to 35000.
        }
    }
    if ship:body:atm:sealevelpressure < 0.5 {
        set DescentAngles to list(aoa, aoa, aoa, aoa).
        if RSS {
            set LongitudinalAcceptanceLimit to 130000.
            set LateralAcceptanceLimit to 48000.
        }
        else if KSRSS {
            set LongitudinalAcceptanceLimit to 90000.
            set LateralAcceptanceLimit to 46000.
        }
        else {
            set LongitudinalAcceptanceLimit to 20000.
            set LateralAcceptanceLimit to 12000.
        }
    }
    if KUniverse:activevessel = vessel(ship:name) {
        wait 0.001.
        if KUniverse:activevessel = vessel(ship:name) {
            set addons:tr:descentmodes to list(true, true, true, true).
            set addons:tr:descentgrades to list(false, false, false, false).
            if KUniverse:activevessel = vessel(ship:name) {
                set addons:tr:descentangles to DescentAngles.
                if defined landingzone {
                    ADDONS:TR:SETTARGET(landingzone).
                }
            }
        }
    }
}


function CheckSlope {
    parameter SetNewLZNow.
    set config:ipu to 2000.
    set IsLandingZoneOkay to false.
    set SuggestedLZ to landingzone.
    set OffsetTargetLat to 0.
    set OffsetTargetLng to 0.
    set NewOffsetTargetLat to 0.
    set NewOffsetTargetLng to 0.
    set iteration to 0.
    set number to 0.
    set targetLZheight to landingzone:terrainheight.
    set StepDistance to 50 / (1000 * Planet1Degree).
    set IsOriginalTarget to false.
    set LowestSlopeDictionary to lexicon().
    set multiplier to 2.
    if SetNewLZNow {
        if addons:tr:hasimpact {
            set impactpos to addons:tr:impactpos.
            set landingzone to latlng(impactpos:lat, impactpos:lng).
        }
        else {
            set landingzone to latlng(ship:geoposition:lat, ship:geoposition:lng).
        }
    }
    until IsLandingZoneOkay or cancelconfirmed {
        if ClosingIsRunning or cancelconfirmed or SetNewLZNow and iteration > 3 {
            break.
        }
        if landingzone:terrainheight < 0 {
            set IsLandingZoneOkay to true.
            set DistanceFromTargetLZ to 0.
            set SuggestedLZ to latlng(round(landingzone:lat + OffsetTargetLat, 4), round(landingzone:lng + OffsetTargetLng, 4)).
            set Slope to 0.
            break.
        }
        SendPing().
        set heightWest to latlng(landingzone:lat + OffsetTargetLat, landingzone:lng + OffsetTargetLng - 0.125 * StepDistance):terrainheight.
        set heightEast to latlng(landingzone:lat + OffsetTargetLat, landingzone:lng + OffsetTargetLng + 0.125 * StepDistance):terrainheight.
        set heightNorth to latlng(landingzone:lat + OffsetTargetLat + 0.125 * StepDistance, landingzone:lng + OffsetTargetLng):terrainheight.
        set heightSouth to latlng(landingzone:lat + OffsetTargetLat - 0.125 * StepDistance, landingzone:lng + OffsetTargetLng):terrainheight.
        set targetLZheight to latlng(landingzone:lat + OffsetTargetLat, landingzone:lng + OffsetTargetLng):terrainheight.
        set SlopeWest to arctan((heightWest - targetLZheight) / (0.125 * StepDistance * 1000 * Planet1Degree)).
        set SlopeEast to arctan((heightEast - targetLZheight) / (0.125 * StepDistance * 1000 * Planet1Degree)).
        set SlopeNorth to arctan((heightNorth - targetLZheight) / (0.125 * StepDistance * 1000 * Planet1Degree)).
        set SlopeSouth to arctan((heightSouth - targetLZheight) / (0.125 * StepDistance * 1000 * Planet1Degree)).
        //clearscreen.
        //print "iteration: " + iteration.
        //print "number: " + number.
        //print latlng(landingzone:lat + OffsetTargetLat, landingzone:lng + OffsetTargetLng).
        //print "Max Upslope: " + max(max(max(SlopeWest, SlopeEast), SlopeNorth), SlopeSouth).
        //print "Max Downslope: " + min(min(min(SlopeWest, SlopeEast), SlopeNorth), SlopeSouth).
        //print "Max Slope: " + max(max(max(max(SlopeWest, SlopeEast), SlopeNorth), SlopeSouth), -1 * min(min(min(SlopeWest, SlopeEast), SlopeNorth), SlopeSouth)).
        //print "LatOffset: " + OffsetTargetLat.
        //print "LngOffset: " + OffsetTargetLng.
        //print "StepDistance: " + StepDistance.
        //print "Slope to West: " + SlopeWest.
        //print "Slope to East: " + SlopeEast.
        //print "Slope to North: " + SlopeNorth.
        //print "Slope to South: " + SlopeSouth.
        //print "Target Height: " + TargetLZheight.
        //print heightWest.
        //print heightEast.
        //print heightNorth.
        //print heightSouth.

        if SlopeWest > MaxTilt or SlopeWest < -MaxTilt or SlopeEast > MaxTilt or SlopeEast < -MaxTilt or SlopeNorth > MaxTilt or SlopeNorth < -MaxTilt or SlopeSouth > MaxTilt or SlopeSouth < -MaxTilt {
            if OffsetTargetLat = iteration * multiplier * StepDistance and OffsetTargetLng = iteration * -multiplier * StepDistance and number > 1 {
                set iteration to iteration + 1.
                set number to 0.
                set OffsetTargetLat to iteration * multiplier * StepDistance.
                set OffsetTargetLng to iteration * -multiplier * StepDistance.
            }
            else {
                set number to number + 1.
                set NewOffsetTargetLat to OffsetTargetLat.
                set NewOffsetTargetLng to OffsetTargetLng.
                if round(OffsetTargetLat, 4) = round(iteration * multiplier * StepDistance, 4) {
                    if round(OffsetTargetLng, 4) = round(iteration * multiplier * StepDistance, 4) {}
                    else {
                        set NewOffsetTargetLng to OffsetTargetLng + multiplier * StepDistance.
                    }
                }
                if round(OffsetTargetLng, 4) = round(iteration * multiplier * StepDistance, 4) {
                    if round(OffsetTargetLat, 4) = round(iteration * -multiplier * StepDistance, 4) {}
                    else {
                        set NewOffsetTargetLat to OffsetTargetLat - multiplier * StepDistance.
                    }
                }
                if round(OffsetTargetLat, 4) = round(iteration * -multiplier * StepDistance, 4) {
                    if round(OffsetTargetLng, 4) = round(iteration * -multiplier * StepDistance, 4) {}
                    else {
                        set NewOffsetTargetLng to OffsetTargetLng - multiplier * StepDistance.
                    }
                }
                if round(OffsetTargetLng, 4) = round(iteration * -multiplier * StepDistance, 4) {
                    if round(OffsetTargetLat, 4) = round(iteration * multiplier * StepDistance, 4) {}
                    else {
                        set NewOffsetTargetLat to OffsetTargetLat + multiplier * StepDistance.
                    }
                }
                if SetNewLZNow {
                    set Slope to max(max(max(max(SlopeWest, SlopeEast), SlopeNorth), SlopeSouth), -1 * min(min(min(SlopeWest, SlopeEast), SlopeNorth), SlopeSouth)).
                    LowestSlopeDictionary:add(((landingzone:lat + OffsetTargetLat) + "," + (landingzone:lng + OffsetTargetLng)), Slope).
                }
                if number > 0 {
                    set OffsetTargetLat to NewOffsetTargetLat.
                    set OffsetTargetLng to NewOffsetTargetLng.
                }
                if number > iteration * 8 {
                    set iteration to iteration + 1.
                    set number to 0.
                    set OffsetTargetLat to iteration * multiplier * StepDistance.
                    set OffsetTargetLng to iteration * -multiplier * StepDistance.
                }
            }
        }
        else {
            set IsLandingZoneOkay to true.
            set SuggestedLZ to latlng(round(landingzone:lat + OffsetTargetLat, 4), round(landingzone:lng + OffsetTargetLng, 4)).
        }
        set Slope to max(max(max(max(SlopeWest, SlopeEast), SlopeNorth), SlopeSouth), -1 * min(min(min(SlopeWest, SlopeEast), SlopeNorth), SlopeSouth)).
        set DistanceFromTargetLZ to sqrt((OffsetTargetLat * 1000 * Planet1Degree) * (OffsetTargetLat * 1000 * Planet1Degree) + (OffsetTargetLng * 1000 * Planet1Degree) * (OffsetTargetLng * 1000 * Planet1Degree)).
        set SlopeAzimuth to vang(latlng(landingzone:lat + OffsetTargetLat, landingzone:lng + OffsetTargetLng):position - landingzone:position, north:vector).
        if OffsetTargetLng < 0 {
            set SlopeAzimuth to 360 - SlopeAzimuth.
        }
        set message3:text to "<b>Distance:</b>  " + round(DistanceFromTargetLZ) + "m     <b>Slope:</b>  <color=red>" + round(Slope, 1) + "°</color>     <b>Az:</b>  " + round(SlopeAzimuth) + "°".
    }
    if SetNewLZNow and not IsLandingZoneOkay {
        set LowestSlopeFound to 90.
        for pos in LowestSlopeDictionary:keys {
            if LowestSlopeDictionary[pos] < LowestSlopeFound {
                set LowestSlopeFound to LowestSlopeDictionary[pos].
                set LowestSlopeLZ to pos.
            }
        }
        set LowestSlopeLZ to LowestSlopeLZ:split(",").
        set SuggestedLZ to latlng(round(LowestSlopeLZ[0]:toscalar, 4), round(LowestSlopeLZ[1]:toscalar, 4)).
        print "Suggested LZ: " + SuggestedLZ + "   Slope: " + round(Slope, 1).
    }
    if landingzone:lat = SuggestedLZ:lat and landingzone:lng = SuggestedLZ:lng {
        set IsOriginalTarget to true.
    }
    set LZAlt to max(SuggestedLZ:terrainheight, 0).
    print "New LDG Zone Terrain Height: " + round(LZAlt) + "m".
    set config:ipu to CPUSPEED.
    return list(IsOriginalTarget, SuggestedLZ, DistanceFromTargetLZ, Slope, LZAlt).
}


function LandAtOLM {
    if not (LandAtOLMisrunning) {
        set LandAtOLMisrunning to true.
        set TargetOLM to false.
        if STOCK {
            if ShipType:contains("Block1"){
                set FlipAltitude to 580.
            } else {
                set FlipAltitude to 584.
            }
        }
        else if KSRSS {
            if ShipType:contains("Block1"){
                set FlipAltitude to 624.
            } else {
                set FlipAltitude to 624.
            }
        }
        else {
            if ShipType:contains("Block1"){
                set FlipAltitude to 610.
            } else {
                set FlipAltitude to 610.
            }
        }
        list targets in shiplist.
        if shiplist:length > 0 {
            for x in shiplist {
                if x:name:contains("OrbitalLaunchMount") {
                    if vxcl(up:vector, x:position - landingzone:position):mag < 800 {
                        set TargetOLM to x:name.
                        LogToFile(("TargetOLM set to " + TargetOLM)).
                        SetRadarAltitude().
                        set TowerHeadingVector to angleAxis(-6,up:vector) * vCrs(up:vector, north:vector).
                        if alt:radar > 1000 and alt:radar < 10100 {
                            if not (Vessel(TargetOLM):isdead) {
                                when Vessel(TargetOLM):unpacked then {
                                    wait 0.01.
                                    set TowerHeadingVector to vxcl(up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0]:position).
                                    sendMessage(Vessel(TargetOLM), "MechazillaHeight,0.5,2").
                                    sendMessage(Vessel(TargetOLM), "MechazillaArms,8.2,10,90,true").
                                    sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,1,12,false").
                                    sendMessage(Vessel(TargetOLM), "MechazillaStabilizers,0").
                                    if RSS {
                                        set landingzone to latlng(round(body:geopositionof(Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position):lat, 6), round(body:geopositionof(Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position):lng, 6)).
                                    }
                                    else {
                                        set landingzone to latlng(round(body:geopositionof(Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position):lat, 4), round(body:geopositionof(Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position):lng, 4)).
                                    }
                                    set LZsettoOLM to true.
                                    set tLZ to time:seconds.
                                }
                            }
                        }
                        set LandAtOLMisrunning to false.
                        return true.
                    }
                }
            }
            set LandAtOLMisrunning to false.
            set FlipAltitude to FlipAltitude * 1.1.
            return false.
        }
        else {
            set LandAtOLMisrunning to false.
            set FlipAltitude to FlipAltitude * 1.1.
            return false.
        }
    }
}


function ShipsInOrbit {
    list targets in shiplist.
    set ShipsInOrbitList to list().
    set b to 0.
    set t to 0.
    set OLMname to false.
    for var in LaunchSites:keys {
        if round(LaunchSites[var]:split(",")[0]:toscalar(9999), 2) = round(body:geopositionof(ship:position):lat, 2) and round(LaunchSites[var]:split(",")[1]:toscalar(9999), 2) = round(body:geopositionof(ship:position):lng, 2) {
                set OLMname to var + " OrbitalLaunchMount".
                break.
        }
    }
    if OLMname = false {
        set OLMname to "OrbitalLaunchMount".
    }
    if shiplist:length > 0 {
        for x in shiplist {
            if x:name = ship:name {
                RenameShip().
            }
            if x:name = "Booster" {
                set b to b + 1.
            }
            if x:name = OLMname {
                set t to t + 1.
            }
            if x:status = "ORBITING" and x:body = ship:body {
                if x:name:contains("Crew") or x:name:contains("Cargo") or x:name:contains("Tanker") or x:name:contains("Depot") or x:name:contains("Starship") {
                    if RSS and x:orbit:apoapsis < 500000 and x:orbit:periapsis > 140000 {
                        ShipsInOrbitList:add(Vessel(x:name)).
                    }
                    else if KSRSS and x:orbit:apoapsis < 250000 and x:orbit:periapsis > 90000 {
                        ShipsInOrbitList:add(Vessel(x:name)).
                    }
                    else if x:orbit:apoapsis < 150000 and x:orbit:periapsis > 70000 {
                        ShipsInOrbitList:add(Vessel(x:name)).
                    }
                }
            }
        }
    }
    if b > 0 {
        set BoosterAlreadyExists to true.
    }
    else {
        set BoosterAlreadyExists to false.
    }
    if t > 0 {
        set TowerAlreadyExists to true.
    }
    else {
        set TowerAlreadyExists to false.
    }
    return ShipsInOrbitList.
}


function RenameShip {
    for x in shiplist {
        if x:name = ship:name {
            if x:name:contains(" (s") {
                set shipindex to x:name:find(" (s").
                set shipnameonly to x:name:substring(0, shipindex).
                set shipnr to x:name:substring(shipindex + 3, 2).
                set ship:name to shipnameonly + " (S" + (shipnr:toscalar(0) + 1) + ")".
            }
            else {
                for y in range(SNStart, 10000) {
                    set ship:name to ship:name + " (S" + y + ")".
                    if x:name = ship:name {
                        set y to y + 1.
                    }
                    else {
                        break.
                    }
                }
            }
            RenameShip().
        }
    }
}


function LandingZoneFinder {
    set config:ipu to 2000.
    set AvailableLandingSpots to list(true, landingzone, 1, 1, 0).
    for var in LaunchSites:keys {
        if BodyExists("Kerbin") {
            if LaunchSites[var] = setting1:text and ship:body = BODY("Kerbin") {
                set AvailableLandingSpots to list(true, landingzone, 0, 0, 0).
                break.
            }
        }
        if BodyExists("Earth") {
            if LaunchSites[var] = setting1:text and ship:body = BODY("Earth") {
                set AvailableLandingSpots to list(true, landingzone, 0, 0, 0).
                break.
            }
        }
    }
    if AvailableLandingSpots[2] = 0 and AvailableLandingSpots[3] = 0 {}
    else {
        set message1:text to "<b>Error: Landing Zone Slope too steep!</b>".
        set message1:style:textcolor to yellow.
        set message2:text to "<b>Looking for suitable Landing Zones..</b>".
        set message3:text to "<b>This may take a while..</b>".
        InhibitButtons(0, 1, 0).
        set AvailableLandingSpots to CheckSlope(0).
        set message1:text to "".
        set message2:text to "".
        set message3:text to "".
        set message1:style:textcolor to white.
        if AvailableLandingSpots[0] = true {}
        else {
            set message1:text to "<b>Suggested Landing Zone:</b>  <color=yellow>" + round(AvailableLandingSpots[1]:lat, 4) + "," + round(AvailableLandingSpots[1]:lng, 4) + "</color>".
            set message2:text to "<b>Distance:  </b><color=yellow>" + round(AvailableLandingSpots[2]) + "m away</color>      <b>Slope:  </b><color=yellow>" + round(AvailableLandingSpots[3],1) + "°</color>".
            set message3:text to "<b>Execute <color=white>or</color> Cancel?</b>".
            set message3:style:textcolor to cyan.
            InhibitButtons(0, 0, 0).
            if confirm() {
                LogToFile("Flatter Landing Zone found and accepted!").
                set landingzone to AvailableLandingSpots[1].
                addons:tr:settarget(landingzone).
                SaveToSettings("Landing Coordinates", (round(landingzone:lat, 4) + "," + round(landingzone:lng, 4)):tostring).
                set setting1:text to (round(landingzone:lat, 4) + "," + round(landingzone:lng, 4)):tostring.
            }
            else {
                LogToFile("Landing Zone Finder Function cancelled").
                set message1:text to "".
                set message3:text to "".
                set LZFinderCancelled to true.
            }
        }
    }
    set config:ipu to CPUSPEED.
}


function CheckLZReachable {
    set LngLatErrorList to LngLatError().
    if ship:body:atm:sealevelpressure > 0.5 {
        if abs(LngLatErrorList[0]) > 7000 or abs(LngLatErrorList[1]) > 2000 {
            set AvailableLandingSpots to CheckSlope(1).
            wait 0.1.
            set FindNewTarget to true.
            print AvailableLandingSpots.
            set landingzone to AvailableLandingSpots[1].
            wait 0.1.
            addons:tr:settarget(landingzone).
            wait 0.1.
            HUDTEXT("New Landing Zone Found and activated!", 10, 2, 20, green, false).
            SetRadarAltitude().
        }
        LogToFile("Dense Atmo Planet Automated Landing Activated").
    }
    else if ship:body:atm:sealevelpressure < 0.5 and ship:body:atm:exists {
        if abs(LngLatErrorList[0]) > 7500 and not (RSS) or abs(LngLatErrorList[0]) > 200000 and RSS or abs(LngLatErrorList[1]) > 2500 and not (RSS) or abs(LngLatErrorList[1]) > 10000 and RSS {
            set AvailableLandingSpots to CheckSlope(1).
            wait 0.1.
            set FindNewTarget to true.
            set landingzone to AvailableLandingSpots[1].
            wait 0.1.
            addons:tr:settarget(landingzone).
            wait 0.1.
            HUDTEXT("New Landing Zone Found and activated!", 10, 2, 20, green, false).
            LogToFile("New Landing Zone Found and activated!").
            SetRadarAltitude().
        }
        LogToFile("Thin Atmo Planet Automated Landing Activated").
    }
    else {
        if abs(LngLatErrorList[0]) > 1000 or abs(LngLatErrorList[1]) > 500 {
            set AvailableLandingSpots to CheckSlope(1).
            wait 0.1.
            set FindNewTarget to true.
            set landingzone to AvailableLandingSpots[1].
            wait 0.1.
            addons:tr:settarget(landingzone).
            wait 0.1.
            HUDTEXT("New Landing Zone Found and activated!", 10, 2, 20, green, false).
            SetRadarAltitude().
        }
        LogToFile("Automated Landing Activated").
    }
    set runningprogram to "Landing".
}


function updateManeuver {
    if not ManeuverPageIsRunning {
        set ManeuverPageIsRunning to true.
        if time:seconds > prevTargetFindingTime + 5 {
            list targets in targetlist.
            if targetlist:length > 0 {
                TargetPicker:clear().
                set TargetPicker:options to list("<color=grey><b>Select Target</b></color>").
                for x in targetlist {
                    if x:status = "ORBITING" and x:distance < 10000 {
                        TargetPicker:addoption(x:name).
                        set TargetPicker:index to 1.
                    }
                }
            }
            set prevTargetFindingTime to time:seconds.
        }
        if hastarget and TargetSelected and ManeuverPicker:text = "<b><color=white>Auto-Dock</color></b>" {
            set maneuver3label1:text to "<b>Distance:  </b><color=yellow>" + round(target:distance, 2) + "m</color>".
            set maneuver3label2:text to "<b>Rel. Velocity:  </b><color=yellow>" + round((target:velocity:orbit - ship:velocity:orbit):mag, 2) + "m/s</color>".
            set maneuver3label3:text to "".
        }
        else if hastarget and ManeuverPicker:text = "<b><color=white>Align Planes</color></b>" {
            set maneuver2label1:text to "<b>Target:  </b><color=yellow>" + target:name + "</color>".
            set maneuver3label1:text to "<b>Target Orbit:  </b>" + round(target:apoapsis / 1000, 1) + "km x " + round(target:periapsis / 1000, 1) + "km".
            set maneuver3label2:text to "<b>                        Rel. Inclination:  </b><color=yellow>" + round(relative_inc(ship:orbit, target:orbit), 2) + "°</color>".
            set maneuver3label3:text to "".
        }
        set ManeuverPageIsRunning to false.
    }
}


function PerformBurn {
    set mST to steeringManager:maxstoppingtime.
    if ShipType:contains("Block1") {
        set steeringManager:maxstoppingtime to mST/2.
    }
    parameter Burntime, ProgradeVelocity, NormalVelocity, RadialVelocity, BurnType.
    set config:ipu to CPUSPEED.
    set textbox:style:bg to "starship_img/starship_main_square_bg".
    set SingleEngineDeOrbitBurn to false.
    if BurnTime:istype("TimeStamp") {
        if BurnType = "Execute" {}
        else {
            set burn to node(BurnTime, 0, NormalVelocity, ProgradeVelocity).
            add burn.
        }
        set burnstarttime to BurnTime.
    }
    else {
        if BurnType = "Execute" {}
        else {
            set burn to node(timespan(BurnTime), 0, NormalVelocity, ProgradeVelocity).
            add burn.
        }
        set burnstarttime to timestamp(time:seconds + BurnTime).
    }
    if burnstarttime - 1 < timestamp(time:seconds) {
        ShowHomePage().
        LogToFile("Stopping De-Orbit Burn due to wrong orientation").
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        set message1:text to "<b>Burn Cancelled.</b>".
        set message1:style:textcolor to yellow.
        set message2:text to "<b>Planned Burn is too close to perform..</b>".
        set message2:style:textcolor to yellow.
        wait 3.
        ClearInterfaceAndSteering().
        return.
    }
    lock deltaV to nextnode:deltav:mag.
    if deltaV < rcsRaptorBoundary and deltaV / (RCSThrust / ship:mass) < RCSBurnTimeLimit {
        lock MaxAccel to RCSThrust / ship:mass.
        set UseRCSforBurn to true.
    }
    else {
        lock MaxAccel to (VACEngines[0]:possiblethrust * NrOfVacEngines) / ship:mass.
        set UseRCSforBurn to false.
    }
    if BurnType = "DeOrbit" {
        set SingleEngineDeOrbitBurn to true.
        set UseRCSforBurn to false.
        lock MaxAccel to SLEngines[0]:possiblethrust / ship:mass.
    }
    lock BurnAccel to min(19.62, MaxAccel).
    lock BurnDuration to deltaV / BurnAccel.
    ShowHomePage().
    set runningprogram to "Input".
    if BurnType = "Execute" {
        set message1:text to "<b>Execute Custom Burn:</b>".
        if UseRCSforBurn {
            set message2:text to "<b>@:</b>  <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b>  <color=yellow>" + round(DeltaV, 1) + "m/s</color>   <b><color=magenta>(RCS Thrusters)</color></b>".
        }
        else {
            set message2:text to "<b>@:</b>  <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b>  <color=yellow>" + round(DeltaV, 1) + "m/s</color>   <b><color=magenta>(VAC Engines)</color></b>".
        }
    }
    else if defined AltitudeOverLZ and BurnType = "DeOrbit" {
        set message1:text to "<size=19><b>Suggested De-Orbit Burn to Point OVHD LZ:</b></size>".
        set message2:text to "<size=19><b>@:</b>  <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b>  <color=yellow>" + round(DeltaV, 1) + "m/s</color>   <b>Alt over LZ:</b>  <color=yellow>" + round(AltitudeOverLZ/1000, 1) + "km</color></size>".
    }
    else if BurnType = "DeOrbit" {
        set message1:text to "<b>Suggested De-Orbit Burn:</b>".
        for var in LaunchSites:keys {
            if BodyExists("Kerbin") {
                if LaunchSites[var] = setting1:text and ship:body = BODY("Kerbin") {
                    set message2:text to "<b>@:</b> <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b> <color=yellow>" + round(DeltaV, 1) + "m/s</color>   <b>LZ: <color=green>" + var +  "</color></b>".
                    break.
                }
                set message2:text to "<b>@:</b> <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b> <color=yellow>" + round(DeltaV, 1) + "m/s</color>   <b>LZ:</b> <size=17><color=yellow>" + landingzone:lat + "," + landingzone:lng + "</color></size>".
            }
            if BodyExists("Earth") {
                if LaunchSites[var] = setting1:text and ship:body = BODY("Earth") {
                    set message2:text to "<b>@:</b> <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b> <color=yellow>" + round(DeltaV, 1) + "m/s</color>   <b>LZ: <color=green>" + var +  "</color></b>".
                    break.
                }
                set message2:text to "<b>@:</b> <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b> <color=yellow>" + round(DeltaV, 1) + "m/s</color>   <b>LZ:</b> <size=17><color=yellow>" + landingzone:lat + "," + landingzone:lng + "</color></size>".
            }
        }
    }
    else if BurnType = "Circ"{
        set message1:text to "<b>Circularize at Altitude:</b>  <color=yellow>" + round(((positionat(ship, burnstarttime) - ship:body:position):mag - ship:body:radius) / 1000, 1) + "km</color>".
        set message2:text to "<b>@:</b>  <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b>  <color=yellow>" + round(DeltaV, 1) + "m/s</color>".
    }
    else if BurnType = "Align"{
        set message1:text to "<b>Align to Plane of:</b>  <color=yellow>" + target:name + "</color>".
        set message2:text to "<b>@:</b>  <color=yellow>" + burnstarttime:hour + ":" + burnstarttime:minute + ":" + burnstarttime:second + "<b>UT</b></color>   <b>ΔV:</b>  <color=yellow>" + round(DeltaV, 1) + "m/s</color>".
    }
    set message3:style:textcolor to cyan.
    set message3:text to "<b>Execute <color=white>or</color> Cancel?</b>".
    InhibitButtons(0, 0, 0).
    if confirm() {
        if not hasnode {
            ShowHomePage().
            LogToFile("Stopping De-Orbit Burn due to loss of node").
            set textbox:style:bg to "starship_img/starship_main_square_bg".
            set message1:text to "<b>Burn Cancelled.</b>".
            set message1:style:textcolor to yellow.
            set message2:text to "<b>Maneuver Node was lost..</b>".
            set message2:style:textcolor to yellow.
            set message3:text to "".
            InhibitButtons(0,1,1).
            wait 3.
            ClearInterfaceAndSteering().
            return.
        }
        if nextnode:eta < 0.5 * BurnDuration + 10 {
            ShowHomePage().
            LogToFile("Stopping De-Orbit Burn due to wrong orientation").
            set textbox:style:bg to "starship_img/starship_main_square_bg".
            set message1:text to "<b>Burn Cancelled.</b>".
            set message1:style:textcolor to yellow.
            set message2:text to "<b>Planned Burn is too close to perform..</b>".
            set message2:style:textcolor to yellow.
            set message3:text to "".
            InhibitButtons(0,1,1).
            wait 3.
            ClearInterfaceAndSteering().
            return.
        }
        LogToFile("Re-orienting for Burn").
        InhibitButtons(1, 1, 0).
        ShowButtons(0).
        ShutDownAllEngines().
        if not (KUniverse:activevessel = vessel(ship:name)) {
            set KUniverse:activevessel to vessel(ship:name).
        }
        set message3:style:textcolor to white.
        set runningprogram to "Standby for Burn".
        HideEngineToggles(1).
        if defined Nose {
            if ShipType:contains("Block1") and not ShipType:contains("EXP") {HeaderTank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).}
            else if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
                Nose:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).
            }
        }
        Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 75).
        sas off.
        rcs off.
        if SingleEngineDeOrbitBurn {
            set OffsetAngle to vang(ship:position - SLEngines[0]:position, facing:forevector).
            lock BVec to nextnode:burnvector * AngleAxis(OffsetAngle, up:vector).
            SLEngines[0]:getmodule("ModuleSEPRaptor"):doaction("enable actuate out", true).
            SLEngines[0]:getmodule("ModuleSEPRaptor"):setfield("actuate limit", 100 * OffsetAngle / 11).
        }
        else {
            lock BVec to nextnode:burnvector.
        }
        if BurnType = "DeOrbit" {
            lock steering to lookdirup(BVec, north:vector).
        }
        else {
            lock steering to lookdirup(BVec, facing:topvector).
        }
        set bTime to time:seconds + 9999.
        until time:seconds > bTime or cancelconfirmed and not ClosingIsRunning {
            if hasnode {
                set bTime to time:seconds + nextnode:eta - 0.5 * BurnDuration.
            }
            else {
                set cancelconfirmed to true.
            }
            TimeWarp(bTime, 45).
            set message1:text to "<b>Starting Burn in:</b>  " + timeSpanCalculator(nextnode:eta - 0.5 * BurnDuration).
            set message2:text to "<b>Target Attitude:</b>    Burnvector".
            set message3:text to "<b>Burn Duration:</b>      " + round(BurnDuration) + "s".
            BackGroundUpdate().
        }
        if hasnode {
            if vang(BVec, ship:facing:forevector) < 15 and cancelconfirmed = false or vang(-BVec, ship:facing:forevector) < 15 and cancelconfirmed = false and BurnType = "DeOrbit" and UseRCSforBurn {
                LogToFile("Starting Burn").
                set runningprogram to "Performing Burn".
                if UseRCSforBurn {}
                else if SingleEngineDeOrbitBurn {
                    SLEngines[0]:activate.
                }
                else {
                    set quickengine3:pressed to true.
                }
                until vdot(facing:forevector, nextnode:deltav) < 0 and not (BurnType = "DeOrbit" and UseRCSforBurn) or vdot(-facing:forevector, nextnode:deltav) < 0 and BurnType = "DeOrbit" and UseRCSforBurn or cancelconfirmed = true and not ClosingIsRunning {
                    BackGroundUpdate().
                    if vang(facing:forevector, BVec) < 10 {
                        if UseRCSforBurn {
                            rcs on.
                            set ship:control:translation to v(0, 0, 1).
                            set ship:control:rotation to v(0, 0, 0).
                        }
                        else {
                            lock throttle to min(nextnode:deltav:mag / MaxAccel, BurnAccel / MaxAccel).
                            //lock throttle to max(min(nextnode:deltav:mag / MaxAccel, BurnAccel / MaxAccel), 0.33).
                        }
                    }
                    if nextnode:deltav:mag > 5 {
                        lock steering to lookdirup(BVec, ship:facing:topvector).
                    }
                    else {
                        lock steering to "kill".
                    }
                    if kuniverse:timewarp:warp > 0 {
                        set kuniverse:timewarp:warp to 0.
                    }
                    set message1:text to "<b>Performing Burn..</b>".
                    set message3:text to "<b>Burn Duration:</b>      " + round(BurnDuration) + "s".
                }
                if UseRCSforBurn {
                    rcs off.
                    set ship:control:translation to v(0, 0, 0).
                    set ship:control:rotation to v(0, 0, 0).
                }
                else if SingleEngineDeOrbitBurn {
                    SLEngines[0]:shutdown.
                }
                else {
                    set quickengine3:pressed to false.
                }
                remove nextnode.
                sas on.
                lock throttle to 0.
                unlock steering.
                HideEngineToggles(0).
                rcs off.
                LogToFile("Stopping Burn").
                ClearInterfaceAndSteering().
            }
            else if not cancelconfirmed {
                remove nextnode.
                lock throttle to 0.
                unlock steering.
                unlock throttle.
                sas on.
                HideEngineToggles(0).
                ShowHomePage().
                LogToFile("Stopping Burn due to wrong orientation").
                set message1:text to "<b>Burn Cancelled.</b>".
                set message1:style:textcolor to yellow.
                set message2:text to "<b>Incorrect orientation or stopped..</b>".
                set message2:style:textcolor to yellow.
                set message3:text to "".
                InhibitButtons(0,1,1).
                wait 3.
                ClearInterfaceAndSteering().
            }
            else {
                HideEngineToggles(0).
                lock throttle to 0.
                set kuniverse:timewarp:warp to 0.
                rcs off.
                sas on.
                LogToFile("Stopping Burn due to user cancellation").
                ClearInterfaceAndSteering().
            }
        }
        else {
            lock throttle to 0.
            rcs off.
            sas on.
            HideEngineToggles(0).
            LogToFile("Stopping Burn due to loss of node").
            ClearInterfaceAndSteering().
        }
    }
    else {
        LogToFile("User cancelled Burn").
        ClearInterfaceAndSteering().
    }
    if SLEngines[0]:getmodule("ModuleSEPRaptor"):hasaction("disable actuate out") {
        SLEngines[0]:getmodule("ModuleSEPRaptor"):doaction("disable actuate out", true).
        SLEngines[0]:getmodule("ModuleSEPRaptor"):setfield("actuate limit", 100).
    }
    unlock BVec.
    if ShipType:contains("Block1") {
        set steeringManager:maxstoppingtime to mST.
    }
}


function SetInterfaceLocation {
    if KUniverse:activevessel = vessel(ship:name) or BoosterExists() {
        if ShipIsDocked and ShipType = "Tanker" and not (LaunchButtonIsRunning) {
            set g:y to 100 + 250.
        }
        else {
            set g:y to 100.
        }
    }
    else if LaunchButtonIsRunning or ship:status = "LANDED" or ship:status = "PRELAUNCH" or ship:status = "SUB_ORBITAL" {
        set g:y to 100.
    }
    else {
        set g:y to 100 + 250.
    }
}


function BoosterExists {
    list targets in shiplist.
    set ShipsInOrbitList to list().
    if shiplist:length > 0 {
        for x in shiplist {
            if x:status = "SUB_ORBITAL" or x:status = "FLYING" {
                if x:name:contains("Booster") {
                    return true.
                }
            }
        }
    }
    return false.
}


FUNCTION launchWindow {
    PARAMETER target.
    parameter iteration.

    clearscreen.
    if iteration > 31 {
        set launchWindowList to list(-1,0,0).
        return.
    }

    if LaunchIntoLAN {
        set SimOrbit to createorbit(max(ship:geoposition:lat + 0.001, target:orbit:inclination), target:orbit:eccentricity, target:orbit:semimajoraxis, target:orbit:lan, target:orbit:argumentofperiapsis, target:orbit:meananomalyatepoch, target:orbit:epoch, ship:body).
        local INC is SimOrbit:inclination.
        local LAN is SimOrbit:lan.
        set Nt to V(0,1,0) * ANGLEAXIS(-INC, ANGLEAXIS(-LAN, V(0,1,0)) * SOLARPRIMEVECTOR).
    }
    else {
        set Nt to VCRS(TARGET:VELOCITY:OBT, TARGET:POSITION-BODY:POSITION):NORMALIZED.
    }
    LOCAL R0 IS SHIP:POSITION-BODY:POSITION.
    LOCAL Rh IS VXCL(BODY:ANGULARVEL, R0).
    LOCAL Rv IS R0-Rh.
    LOCAL Ph IS VCRS(BODY:ANGULARVEL:NORMALIZED, Rh).
    LOCAL A  IS Nt * Rh.
    LOCAL B  IS Nt * Ph.
    LOCAL C  IS -Nt * Rv.
    LOCAL ARG IS C/SQRT(A^2+B^2).
    IF ABS(ARG) > 1 {
        print "no match possible".
        if LaunchIntoLAN {
            set launchWindowList to list(-2,0,0).
            return.
        }
        set LaunchIntoLAN to true.
        return launchWindow(target, 0).
    }
    LOCAL phi IS ARCTAN2(B,A).
    LOCAL theta1 IS MOD(360+ARCCOS(ARG)+PHI,360).
    LOCAL theta2 IS MOD(360-ARCCOS(ARG)+PHI,360).
    LOCAL next_launch_angle IS MIN(theta1,theta2).
    LOCAL time_to_next_launch IS next_launch_angle/(BODY:ANGULARVEL:MAG * CONSTANT:RADTODEG) + iteration * body:rotationperiod - RendezvousOrbitLeadFactor * abs(target:orbit:inclination / 90) * LaunchTimeSpanInSeconds.

    local DegreesToRendezvous to 360 * cos(target:orbit:inclination) * 0.5 * LaunchTimeSpanInSeconds / target:orbit:period.
    local IdealLaunchTargetShipsLongitude to mod(ship:geoposition:lng - DegreesToRendezvous, 360).

    if hastarget and TargetShip = 0 {
        if LaunchIntoLAN {
            set launchWindowList to list(time_to_next_launch, SimOrbit:inclination).
        }
        else {
            set launchWindowList to list(time_to_next_launch, target:orbit:inclination).
        }
    }
    else {
        local LngAtNode to mod(body:geopositionof(positionat(target, time:seconds + time_to_next_launch)):lng - time_to_next_launch / body:rotationperiod * 360, 360).

        if LngAtNode > 180 {
            set LngAtNode to LngAtNode - 360.
        }
        if LngAtNode < -180 {
            set LngAtNode to LngAtNode + 360.
        }

        local NodeAngle to mod(IdealLaunchTargetShipsLongitude - LngAtNode, 360).

        print "Iteration: " + iteration.
        print "Ideal Degrees: " + round(DegreesToRendezvous, 1).
        print "Target LNG at Launch: " + round(IdealLaunchTargetShipsLongitude, 1) + "  --->  " + round(IdealLaunchTargetShipsLongitude + 2 * DegreesToRendezvous, 1).
        print "Predicted LNG at Launch: " + round(LngAtNode, 1).
        print "Launch Lead Angle: " + round(-NodeAngle, 1).
        print "Launch on Node: " + round(time_to_next_launch) + "s".
        print "Node Time: " + timestamp(time:seconds + time_to_next_launch):full.
        print " ".
        set DegreesToRendezvous to -DegreesToRendezvous.

        if NodeAngle < -0.5 and NodeAngle > 2 * DegreesToRendezvous and time_to_next_launch > 20 {
            set launchWindowList to list(time_to_next_launch, target:orbit:inclination).
        }
        else {
            launchWindow(target, iteration + 1).
            return.
        }
    }
}


function normal {
    parameter obt_in.
    local lan is obt_in:lan.
    local inc is obt_in:inclination.
    local an_nrm is lookdirup(solarprimevector, V(0,1,0)) * R(0, -lan, -inc).
    return an_nrm:topvector.
}


function relative_asc_node {
    parameter ref_obt, test_obt.
    return vcrs(normal(test_obt), normal(ref_obt)):normalized.
}


function relative_inc {
    parameter ref_obt, test_obt.
    return vang(normal(test_obt), normal(ref_obt)).
}


function SetLoadDistances {
    parameter shp.
    parameter distance.

    if distance = "default" {
        set shp:loaddistance:flying:unload to 22500.
        set shp:loaddistance:flying:load to 2250.
        wait 0.001.
        set shp:loaddistance:flying:pack to 25000.
        set shp:loaddistance:flying:unpack to 2000.
        wait 0.001.
        set shp:loaddistance:suborbital:unload to 15000.
        set shp:loaddistance:suborbital:load to 2250.
        wait 0.001.
        set shp:loaddistance:suborbital:pack to 10000.
        set shp:loaddistance:suborbital:unpack to 700.
        wait 0.001.
        set shp:loaddistance:orbit:unload to 2500.
        set shp:loaddistance:orbit:load to 2250.
        wait 0.001.
        set shp:loaddistance:orbit:pack to 550.
        set shp:loaddistance:orbit:unpack to 400.
        wait 0.001.
    }
    else {
        set shp:loaddistance:flying:unload to distance.
        set shp:loaddistance:flying:load to distance - 5000.
        wait 0.001.
        set shp:loaddistance:flying:pack to distance - 2500.
        set shp:loaddistance:flying:unpack to distance - 10000.
        wait 0.001.
        set shp:loaddistance:suborbital:unload to distance.
        set shp:loaddistance:suborbital:load to distance - 5000.
        wait 0.001.
        set shp:loaddistance:suborbital:pack to distance - 2500.
        set shp:loaddistance:suborbital:unpack to distance - 10000.
        wait 0.001.
        set shp:loaddistance:orbit:unload to distance.
        set shp:loaddistance:orbit:load to distance - 5000.
        wait 0.001.
        set shp:loaddistance:orbit:pack to distance - 2500.
        set shp:loaddistance:orbit:unpack to distance - 10000.
        wait 0.001.
        set shp:loaddistance:prelaunch:unload to distance.
        set shp:loaddistance:prelaunch:load to distance - 250.
        wait 0.001.
        set shp:loaddistance:prelaunch:pack to distance - 500.
        set shp:loaddistance:prelaunch:unpack to distance - 750.
    }
}


function DisengageYawRCS {
    parameter boolean.
    if boolean = 1 {
        if tank:getmodule("MODULERCSFX"):hasevent("show actuation toggles") {
            tank:getmodule("MODULERCSFX"):doevent("show actuation toggles").
        }
        tank:getmodule("MODULERCSFX"):setfield("yaw", false).
        tank:getmodule("MODULERCSFX"):doevent("hide actuation toggles").
        if defined nose {
            if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
                if nose:getmodule("MODULERCSFX"):hasevent("show actuation toggles") {
                  nose:getmodule("MODULERCSFX"):doevent("show actuation toggles").
                }
                nose:getmodule("MODULERCSFX"):setfield("yaw", false).
                nose:getmodule("MODULERCSFX"):doevent("hide actuation toggles").
            }
        }
    }
    else {
        if tank:getmodule("MODULERCSFX"):hasevent("show actuation toggles") {
            tank:getmodule("MODULERCSFX"):doevent("show actuation toggles").
        }
        tank:getmodule("MODULERCSFX"):setfield("yaw", true).
        tank:getmodule("MODULERCSFX"):doevent("hide actuation toggles").
        if defined nose {
            if not Nose:name:contains("SEP.23.SHIP.FLAPS") {
                if nose:getmodule("MODULERCSFX"):hasevent("show actuation toggles") {
                    nose:getmodule("MODULERCSFX"):doevent("show actuation toggles").
                }
                nose:getmodule("MODULERCSFX"):setfield("yaw", true).
                nose:getmodule("MODULERCSFX"):doevent("hide actuation toggles").
            }
        }
    }
}


function VehicleSelfCheck {
    set FuelFail to false.
    if STOCK and 1=2{
        if not (ShipType = "Depot") and not (ShipType = "Expendable") and not (ShipType = "Block1CargoExp") and not (ShipType = "Block1Exp") and not (ShipType = "Block1PEZExp") {
            for res in HeaderTank:resources {
                if Methane {
                    if res:name = "LqdMethane" and res:amount < res:capacity + 1 {
                        if round(res:capacity) = 4200 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("Header-CH4").
                        }
                    }
                    if res:name = "Oxidizer" and res:amount < res:capacity + 1 {
                        if round(res:capacity) = 1400 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("Header-LOX").
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 720 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 880 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
        if ShipType = "Tanker" {
            for res in Nose:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        if round(res:capacity) = 36706 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if round(res:capacity) = 12235 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 6912 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 8448 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
        for res in Tank:resources {
            if Methane {
                if res:name = "LqdMethane" {
                    if ShipType = "Depot" {
                        if round(res:capacity) = 119487 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if round(res:capacity) = 80625 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("S-CH4").
                        }
                    }
                }
                if res:name = "Oxidizer" {
                    if ShipType = "Depot" {
                        if round(res:capacity) = 39829 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if round(res:capacity) = 26875 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("S-LOX").
                        }
                    }
                }
            }
            else {
                if res:name = "Liquid Fuel" {
                    if ShipType = "Depot" {
                        if res:capacity = 22500 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if res:capacity = 6210 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                if res:name = "Oxidizer" {
                    if ShipType = "Depot" {
                        if res:capacity = 27500 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if res:capacity = 7590 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
        if SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length > 0 {
            for res in BoosterCore[0]:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        if round(res:capacity) = 393000 and res:amount < res:capacity + 1 {}
                         else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-CH4").
                        }
                    }
                    if res:name = "Oxidizer" {
                        if round(res:capacity) = 131000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-LOX").
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 33120 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 40480 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }

        if SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length > 0 {
            for res in BoosterCore[0]:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        if round(res:capacity) = 175125 and res:amount < res:capacity + 1 {}
                         else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-CH4").
                        }
                    }
                    if res:name = "Oxidizer" {
                        if round(res:capacity) = 58375 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-LOX").
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 306000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 374000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
    }
    if KSRSS and 1=2{
        if not (ShipType = "Depot") and not (ShipType = "Expendable") and not (ShipType = "Block1CargoExp") and not (ShipType = "Block1Exp") and not (ShipType = "Block1PEZExp") {
            for res in HeaderTank:resources {
                if Methane {
                    if res:name = "LqdMethane" and res:amount < res:capacity + 1 {
                        if round(res:capacity) = 3824 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" and res:amount < res:capacity + 1 {
                        if round(res:capacity) = 1275 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 720 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 880 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
        if ShipType = "Tanker" {
            for res in Nose:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        //if round(res:capacity) = 59744 and res:amount < res:capacity + 1 {}
                        if round(res:capacity) = 36706 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        //if round(res:capacity) = 19914 and res:amount < res:capacity + 1 {}
                        if round(res:capacity) = 12235 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 6912 and res:amount < res:capacity + 1 {}
                        //if res:capacity = 11250 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 8448 and res:amount < res:capacity + 1 {}
                        //if res:capacity = 13750 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
        for res in Tank:resources {
            if Methane {
                if res:name = "LqdMethane" {
                    if ShipType = "Depot" {
                        if round(res:capacity) = 133825 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if round(res:capacity) = 86031 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                if res:name = "Oxidizer" {
                    if ShipType = "Depot" {
                        if round(res:capacity) = 44608 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if round(res:capacity) = 28677 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
            else {
                if res:name = "Liquid Fuel" {
                    if ShipType = "Depot" {
                        //if res:capacity = 43200 and res:amount < res:capacity + 1 {}
                        if res:capacity = 25200 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if res:capacity = 16200 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                if res:name = "Oxidizer" {
                    if ShipType = "Depot" {
                        //if res:capacity = 52800 and res:amount < res:capacity + 1 {}
                        if res:capacity = 30800 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if res:capacity = 19800 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
        if SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length > 0 {
            for res in BoosterCore[0]:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        if round(res:capacity) = 420594 and res:amount < res:capacity + 1 {}
                         else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if round(res:capacity) = 140198 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 79200 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 96800 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }

        if SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length > 0 {
            for res in BoosterCore[0]:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        if round(res:capacity) = 175125 and res:amount < res:capacity + 1 {}
                         else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-CH4").
                        }
                    }
                    if res:name = "Oxidizer" {
                        if round(res:capacity) = 58375 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-LOX").
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 306000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 374000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
    }
    if RSS and 1=2 {
        if not (ShipType = "Depot") and not (ShipType = "Expendable") and not (ShipType = "Block1CargoExp") and not (ShipType = "Block1Exp") and not (ShipType = "Block1PEZExp") {
            for res in HeaderTank:resources {
                if Methane {
                    if res:name = "LqdMethane" and res:amount < res:capacity + 1 {
                        if round(res:capacity) = 9894 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" and res:amount < res:capacity + 1 {
                        if round(res:capacity) = 3298 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 1863 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 2277 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        
        if ShipType = "Tanker" {
            for res in Nose:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        if round(res:capacity) = 71692 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if round(res:capacity) = 23897 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 13500 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 16500 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }
        for res in Tank:resources {
            
                if Methane {
                if res:name = "LqdMethane" {
                    if ShipType = "Depot" {
                        if round(res:capacity) = 812512 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if round(res:capacity) = 450000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                if res:name = "Oxidizer" {
                    if ShipType = "Depot" {
                        if round(res:capacity) = 270837 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if round(res:capacity) = 450000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
            else {
                if res:name = "Liquid Fuel" {
                    if ShipType = "Depot" {
                        if res:capacity = 153000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if res:capacity = 108000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
                if res:name = "Oxidizer" {
                    if ShipType = "Depot" {
                        if res:capacity = 187000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    else {
                        if res:capacity = 132000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
            }
        }
        if SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length > 0 {
            for res in BoosterCore[0]:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        if round(res:capacity) = 1625023 and res:amount < res:capacity + 1 {}
                         else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-CH4").
                        }
                    }
                    if res:name = "Oxidizer" {
                        if round(res:capacity) = 541674 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-LOX").
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 306000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 374000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }

        if SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length > 0 {
            for res in BoosterCore[0]:resources {
                if Methane {
                    if res:name = "LqdMethane" {
                        if round(res:capacity) = 175125 and res:amount < res:capacity + 1 {}
                         else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-CH4").
                        }
                    }
                    if res:name = "Oxidizer" {
                        if round(res:capacity) = 58375 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                            print("B-LOX").
                        }
                    }
                }
                else {
                    if res:name = "Liquid Fuel" {
                        if res:capacity = 306000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                    if res:name = "Oxidizer" {
                        if res:capacity = 374000 and res:amount < res:capacity + 1 {}
                        else {
                            set FuelFail to true.
                            print res:amount.
                            print res:capacity.
                        }
                    }
                }
            }
        }

    }
    
    if FuelFail {
        print "Fuel Tanks mismatch detected!".
        print "Planet Pack: " + planetpack.
        print "LqdMethane: " + (Methane).
        print "Interface Disabled..".
        LogToFile("Fuel Tanks mismatch detected! Interface Disabled..").
        InhibitButtons(1, 1, 1).
        ShowButtons(0).
        ShowHomePage().
        set message1:text to "<b>Fuel Amount vs. Capacity mismatch!</b>".
        set message2:text to "<b>Check the readme on the github page..</b>".
        set message3:text to "<b>Interface has been disabled!</b>".
        set message1:style:textcolor to red.
        set message2:style:textcolor to yellow.
        set message3:style:textcolor to grey.
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        set runningprogram to "Self-Test Failed".
        updatestatusbar().
    }
    if ship:name:contains("Real Size") and not (RSS) {
        print "Wrong Craft detected!".
        print "Interface Disabled..".
        LogToFile("Wrong Craft detected! Interface Disabled..").
        InhibitButtons(1, 1, 1).
        ShowButtons(0).
        ShowHomePage().
        set message1:text to "<b>You are using the wrong craft!</b>".
        set message2:text to "<b>Use 'Starship..' craft..</b>".
        set message3:text to "<b>Interface has been disabled!</b>".
        set message1:style:textcolor to red.
        set message2:style:textcolor to yellow.
        set message3:style:textcolor to grey.
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        set runningprogram to "Self-Test Failed".
        updatestatusbar().
    }
    if methane and LF {
        print "Fuel Tanks mismatch detected!".
        print "Planet Pack: " + planetpack.
        print "LqdMethane: " + (Methane).
        print "LF:" + (LF).
        print "Interface Disabled..".
        LogToFile("Fuel Tanks mismatch detected! LF and LqdMethane found simultaneously. Interface Disabled..").
        InhibitButtons(1, 1, 1).
        ShowButtons(0).
        ShowHomePage().
        set message1:text to "<b>LF and Lqd CH4 detected simultaneously!</b>".
        set message2:text to "<b>Load a fresh craft..</b>".
        set message3:text to "<b>Interface has been disabled!</b>".
        set message1:style:textcolor to red.
        set message2:style:textcolor to yellow.
        set message3:style:textcolor to grey.
        set textbox:style:bg to "starship_img/starship_main_square_bg".
        set runningprogram to "Self-Test Failed".
        updatestatusbar().
    }
}


function Timewarp {
    parameter GoalTime.
    parameter BufferTime.
    //clearscreen.
    //print "countdown: " + round(GoalTime - time:seconds).

    if STOCK {
        if GoalTime - time:seconds < 3600 * 24 and kuniverse:timewarp:warp = 7 {
            set kuniverse:timewarp:warp to 6.
        }
        if GoalTime - time:seconds < 3600 * 6 and kuniverse:timewarp:warp > 6 {
            set kuniverse:timewarp:warp to 6.
        }
        if GoalTime - time:seconds < 3600 * 3 and kuniverse:timewarp:warp > 5 {
            set kuniverse:timewarp:warp to 5.
        }
        if GoalTime - time:seconds < 3600 * 0.25 and kuniverse:timewarp:warp > 4 {
            set kuniverse:timewarp:warp to 4.
        }
        if GoalTime - time:seconds < 180 and kuniverse:timewarp:warp > 2 {
            set kuniverse:timewarp:warp to 2.
        }
        if GoalTime - time:seconds < 60 and kuniverse:timewarp:warp > 1 {
            set kuniverse:timewarp:warp to 1.
        }
        if GoalTime - time:seconds < 15 + BufferTime {
            if kuniverse:timewarp:warp > 0 {
                set kuniverse:timewarp:warp to 0.
            }
            if not (ship:status = "PRELAUNCH") {
                rcs on.
            }
        }
        else {
            rcs off.
        }
    }
    else if KSRSS {
        if GoalTime - time:seconds < 3600 * 24 and kuniverse:timewarp:warp = 7 {
            set kuniverse:timewarp:warp to 6.
        }
        if GoalTime - time:seconds < 3600 * 6 and kuniverse:timewarp:warp > 6 {
            set kuniverse:timewarp:warp to 6.
        }
        if GoalTime - time:seconds < 3600 * 3 and kuniverse:timewarp:warp > 5 {
            set kuniverse:timewarp:warp to 5.
        }
        if GoalTime - time:seconds < 3600 * 0.25 and kuniverse:timewarp:warp > 4 {
            set kuniverse:timewarp:warp to 4.
        }
        if GoalTime - time:seconds < 120 and kuniverse:timewarp:warp > 2 {
            set kuniverse:timewarp:warp to 2.
        }
        if GoalTime - time:seconds < 60 and kuniverse:timewarp:warp > 1 {
            set kuniverse:timewarp:warp to 1.
        }
        if GoalTime - time:seconds < 15 + BufferTime {
            if kuniverse:timewarp:warp > 0 {
                set kuniverse:timewarp:warp to 0.
            }
            if not (ship:status = "PRELAUNCH") {
                rcs on.
            }
        }
        else {
            rcs off.
        }
    }
    else {
        if kuniverse:timewarp:warp > 6 {
            set kuniverse:timewarp:warp to 6.
        }
        if GoalTime - time:seconds < 3600 * 24 * 12.5 and kuniverse:timewarp:warp > 5 {
            set kuniverse:timewarp:warp to 5.
        }
        if GoalTime - time:seconds < 3600 * 24 * 1.5 and kuniverse:timewarp:warp > 4 {
            set kuniverse:timewarp:warp to 4.
        }
        if GoalTime - time:seconds < 3600 * 3 and kuniverse:timewarp:warp > 3 {
            set kuniverse:timewarp:warp to 3.
        }
        if GoalTime - time:seconds < 3600 * 0.25 and kuniverse:timewarp:warp > 2 {
            set kuniverse:timewarp:warp to 2.
        }
        if GoalTime - time:seconds < 90 and kuniverse:timewarp:warp > 1 {
            set kuniverse:timewarp:warp to 1.
        }
        if GoalTime - time:seconds < 15 + BufferTime {
            if kuniverse:timewarp:warp > 0 {
                set kuniverse:timewarp:warp to 0.
            }
            if not (ship:status = "PRELAUNCH") {
                rcs on.
            }
        }
        else {
            rcs off.
        }
    }
}


function CheckFullTanks {
    if Boosterconnected {
        set LowCargoMass to false.
        set FullTanks to true.
        local amount to 0.
        local cap to 0.
        if not (ShipType = "Depot") and not (ShipType = "Expendable") and not (ShipType = "Block1CargoExp") and not (ShipType = "Block1Exp") and not (ShipType = "Block1PEZExp") {
            for res in HeaderTank:resources {
                if res:amount < res:capacity - 1 and not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") {
                    set res:enabled to true.
                    set FullTanks to false.
                    set amount to amount + res:amount.
                    set cap to cap + res:capacity.
                } else {
                    set res:enabled to false.
                }
            }
        }
        if ShipType = "Tanker" {
            for res in Nose:resources {
                if res:amount < res:capacity - 1 and not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") {
                    set FullTanks to false.
                    set amount to amount + res:amount.
                    set cap to cap + res:capacity.
                }
            }
        }
        if ShipType = "Block1" or ShipType = "Block1Cargo" or ShipType = "Block1PEZ" {
            for res in HeaderTank:resources {
                if res:amount < res:capacity - 1 and not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") {
                    set res:enabled to true.
                    set FullTanks to false.
                    set amount to amount + res:amount.
                    set cap to cap + res:capacity.
                } else {
                    set res:enabled to false.
                }
            }
        }
        for res in Tank:resources {
            if res:amount < res:capacity - 1 and not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") and not ShipType = "Block1" and not ShipType = "Block1Cargo" and not ShipType = "Block1PEZ" and not ShipType = "Cargo" {
                set FullTanks to false.
                set amount to amount + res:amount.
                set cap to cap + res:capacity.
            } else {
                for res2 in BoosterCore[0]:resources {
                    if res2:name = "Oxidizer" or res2:name = "LqdMethane" {
                        set res2:enabled to true.
                    }
                }
            }
        }

        

        if SHIP:PARTSNAMED("SEP.23.BOOSTER.INTEGRATED"):length > 0 and FullTanks {
            for res in BoosterCore[0]:resources {
                if res:amount < res:capacity - 1 and not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") and CargoMass > 24000 {
                    set FullTanks to false.
                    set amount to amount + res:amount.
                    set cap to cap + res:capacity.
                } else if res:amount < res:capacity * 0.9 - 1 and not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") and CargoMass <= 24000 {
                    set FullTanks to false.
                    set LowCargoMass to true.
                    set amount to amount + res:amount.
                    set cap to cap + res:capacity.
                } else if ShipType = "Block1" or ShipType = "Cargo" or ShipType = "Block1Cargo" or ShipType = "Block1CargoExp" or ShipType = "Block1PEZExp" or ShipType = "Block1PEZ" {
                    for res2 in Tank:resources {
                        if res2:amount < res2:capacity - 1 and not (res2:name = "ElectricCharge") and not (res2:name = "SolidFuel") and CargoMass > 16000 {
                            for res3 in BoosterCore[0]:resources {
                                if res3:name = "Oxidizer" or res3:name = "LqdMethane" {
                                    set res3:enabled to false.
                                }
                            }
                            set FullTanks to false.
                            set amount to amount + res2:amount.
                            set cap to cap + res2:capacity.
                        } else if res2:amount < res2:capacity * 0.9 - 1 and not (res2:name = "ElectricCharge") and not (res2:name = "SolidFuel") and CargoMass <= 16000 {
                            for res3 in BoosterCore[0]:resources {
                                if res3:name = "Oxidizer" or res3:name = "LqdMethane" {
                                    set res3:enabled to false.
                                }
                            }
                            set FullTanks to false.
                            set LowCargoMass to true.
                            set amount to amount + res2:amount.
                            set cap to cap + res2:capacity.
                        } else {
                            for res3 in BoosterCore[0]:resources {
                                if res3:name = "Oxidizer" or res3:name = "LqdMethane" {
                                    set res3:enabled to true.
                                }
                            }
                        }
                    }
                }
            }
        }

        if SHIP:PARTSNAMED("SEP.25.BOOSTER.CORE"):length > 0 and FullTanks {
            for res in BoosterCore[0]:resources {
                if res:amount < res:capacity - 1 and not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") and CargoMass > 24000 {
                    set FullTanks to false.
                    set amount to amount + res:amount.
                    set cap to cap + res:capacity.
                } else if res:amount < res:capacity * 0.9 - 1 and not (res:name = "ElectricCharge") and not (res:name = "SolidFuel") and CargoMass <= 24000 {
                    set FullTanks to false.
                    set LowCargoMass to true.
                    set amount to amount + res:amount.
                    set cap to cap + res:capacity.
                } else if ShipType = "Block1" or ShipType = "Cargo" or ShipType = "Block1Cargo" or ShipType = "Block1CargoExp" or ShipType = "Block1PEZExp" or ShipType = "Block1PEZ" {
                    for res2 in Tank:resources {
                        if res2:amount < res2:capacity - 1 and not (res2:name = "ElectricCharge") and not (res2:name = "SolidFuel") and CargoMass > 16000 {
                            for res3 in BoosterCore[0]:resources {
                                if res3:name = "Oxidizer" or res3:name = "LqdMethane" {
                                    set res3:enabled to false.
                                }
                            }
                            set FullTanks to false.
                            set amount to amount + res2:amount.
                            set cap to cap + res2:capacity.
                        } else if res2:amount < res2:capacity * 0.9 - 1 and not (res2:name = "ElectricCharge") and not (res2:name = "SolidFuel") and CargoMass <= 16000 {
                            for res3 in BoosterCore[0]:resources {
                                if res3:name = "Oxidizer" or res3:name = "LqdMethane" {
                                    set res3:enabled to false.
                                }
                            }
                            set FullTanks to false.
                            set LowCargoMass to true.
                            set amount to amount + res2:amount.
                            set cap to cap + res2:capacity.
                        } else {
                            for res3 in BoosterCore[0]:resources {
                                if res3:name = "Oxidizer" or res3:name = "LqdMethane" {
                                    set res3:enabled to true.
                                }
                            }
                        }
                    }
                }
            }
        }

        set totalfuel to amount.
        set totalcap to cap.
        //print round(totalfuel) + "/" + round(totalcap).
        return FullTanks.
    }
}


function Refuel {
    if OnOrbitalMount {
        if not (Refueling) and not (CheckFullTanks) {
            set Refueling to true.
            Droppriority().
            sendMessage(Processor(volume("OrbitalLaunchMount")), "ToggleReFueling,true").
            set tower11button4:text to "<b><color=cyan>FUEL</color></b>".
            if BoosterCore:length > 0 {
                BoosterCore[0]:getmodule("ModuleToggleCrossfeed"):DoAction("enable crossfeed", true).
                HSR[0]:getmodule("ModuleToggleCrossfeed"):DoAction("enable crossfeed", true).
            }
            Until CheckFullTanks() or not (Refueling) {
                set message1:text to "<b>Loading LqdMethane and Lqd Oxygen..</b>".
                set message2:text to "<b>Progress: </b>" + round(100 * (totalfuel / totalcap), 1) + "%".
                if CargoMass < 24 {
                    set message3:text to "Low Cargo mass detected, Loading to 90%...".
                }
                
                BackGroundUpdate().
            }
            set Refueling to false.
            sendMessage(Processor(volume("OrbitalLaunchMount")), "ToggleReFueling,false").
            set message1:text to "".
            set message2:text to "".
            set tower11button4:text to "<b>FUEL</b>".
            if BoosterCore:length > 0 {
                BoosterCore[0]:getmodule("ModuleToggleCrossfeed"):DoAction("disable crossfeed", true).
                HSR[0]:getmodule("ModuleToggleCrossfeed"):DoAction("disable crossfeed", true).
            }
        }
        else {
            set Refueling to false.
            sendMessage(Processor(volume("OrbitalLaunchMount")), "ToggleReFueling,false").
            set message1:text to "".
            set message2:text to "".
            set Refueling to false.
            set tower11button4:text to "<b>FUEL</b>".
            if BoosterCore:length > 0 {
                BoosterCore[0]:getmodule("ModuleToggleCrossfeed"):DoAction("disable crossfeed", true).
                HSR[0]:getmodule("ModuleToggleCrossfeed"):DoAction("disable crossfeed", true).
            }
        }
    }
}


function ToggleHeaderTank {
    parameter bool.
    if defined HeaderTank {
        for res in HeaderTank:resources {
            set res:enabled to bool.
        }
    }
}


function SetShipBGPage {
    if ShipType = "Cargo" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_cargo".
        if Nose:name:contains("SEP.23.SHIP.FLAPS") {set textbox:style:bg to "starship_img/starship_main_square_bg_cargoFLAPS".}
    }
    if ShipType = "Block1" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1".
    }
    if ShipType = "Block1Cargo" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1cargo".
    }
    if ShipType = "Block1CargoExp" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1cargoexp".
    }
    if ShipType = "Block1Exp" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1exp".
    }
    if ShipType = "Block1PEZ" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1PEZ".
    }
    if ShipType = "Block1PEZExp" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_block1PEZexp".
    }
    if ShipType = "Crew" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_crew".
    }
    if ShipType = "Tanker" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_tanker".
    }
    if ShipType = "Expendable" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_expendable".
    }
    if ShipType = "Depot" {
        set textbox:style:bg to "starship_img/starship_main_square_bg_depot".
    }
}


function GetShipRotation {
    if not (TargetOLM = "false") {
        set TowerHeadingVector to AngleAxis(8, up:vector) * vxcl(up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0]:position).
        //print vang(TowerHeadingVector, heading(90,0):vector).

        set varR to vang(vxcl(up:vector, Nose:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position), AngleAxis(-30, up:vector) * TowerHeadingVector) - 21.8.

        //set THVd to vecdraw(v(0, 0, 0), TowerHeadingVector, blue, "Tower Heading", 20, true, 0.005, true, true).
        //set THVc to vecdraw(v(0, 0, 0), AngleAxis(-30, up:vector) * TowerHeadingVector, red, "Tower Arms Measuring", 20, true, 0.005, true, true).
        //set ShpAng to vecdraw(v(0, 0, 0), vxcl(up:vector, Nose:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position), yellow, "Ship Angle", 20, true, 0.005, true, true).

        return min(max(varR, -22), 38).
    }
}


function DetectWobblyTower {
    if not (TargetOLM = "false") and RadarAlt < 50 and 1=2 {
        if Vessel(TargetOLM):distance < 2000 {
            set ErrorPos to vxcl(up:vector, Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0]:position - Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Rooftop")[0]:position):mag.
            if ErrorPos > 1 * Scale {
                set WobblyTower to true.
            }
        }
    }
}


function updateTelemetry {

    if Boosterconnected {
        if vAng(facing:vector,up:vector) < 23 {
            set sAttitude:style:bg to "starship_img/FullstackShip".
        } else if vAng(facing:vector,up:vector) < 67 and vAng(facing:vector,up:vector) > 23 {
            set sAttitude:style:bg to "starship_img/FullstackShip-45".
        }
    } else {
        if vAng(facing:forevector, vxcl(up:vector, velocity:surface)) < 90 set currentPitch to 360-vang(facing:forevector,up:vector).
        else set currentPitch to vang(facing:forevector,up:vector).
        set sAttitude:style:bg to "starship_img/ShipAttitude/"+round(currentPitch):tostring.
    }


    set shipAltitude to RadarAlt.
    set shipSpeed to ship:airspeed.
    
    set ch4 to 0.
    set mch4 to 0.
    set lox to 0.
    set mlox to 0.


    if defined HeaderTank {
        for res in HeaderTank:resources {
            if res:name = "LiquidFuel" {
                set ch4 to res:amount.
                set mch4 to res:capacity.
            }
            if res:name = "LqdMethane" {
                set ch4 to res:amount.
                set mch4 to res:capacity.
            }
            if res:name = "Oxidizer" or res:name = "LqdOxygen" {
                set lox to res:amount.
                set mlox to res:capacity.
            }
        }
    }
        for res in Tank:resources {
            if res:name = "LiquidFuel" {
                set ch4 to ch4 + res:amount.
                set mch4 to mch4 + res:capacity.
            }
            if res:name = "LqdMethane" {
                set ch4 to ch4 + res:amount.
                set mch4 to mch4 + res:capacity.
            }
            if res:name = "Oxidizer" or res:name = "LqdOxygen" {
                set lox to lox + res:amount.
                set mlox to mlox + res:capacity.
            }
        }


    set shipLOX to lox*100/mlox.
    set shipCH4 to ch4*100/mch4.

    set engCount to 0.
    set engCountVar to 1.
    for eng in SLEngines {
        if eng:thrust > 0 set engCount to engCount + engCountVar.
        set engCountVar to engCountVar*2.
    }
    for eng in VACEngines {
        if eng:thrust > 0 set engCount to engCount + engCountVar.
        set engCountVar to engCountVar*2.
    }
    set picPath to "starship_img/EngPic" + VACEngines:length + "Vac/" + engCount:tostring.
    set sEngines:style:bg to picPath.

    
    set sSpeed:text to "<b><size=24>SPEED</size>          </b> " + round(shipSpeed*3.6) + " <size=24>KM/H</size>".
    if shipAltitude > 99999 {
        set sAltitude:text to "<b><size=24>ALTITUDE</size>       </b> " + round(shipAltitude/1000) + " <size=24>KM</size>".
    } else if shipAltitude > 999 {
        set sAltitude:text to "<b><size=24>ALTITUDE</size>       </b> " + round(shipAltitude/1000,1) + " <size=24>KM</size>".
    } else {
        set sAltitude:text to "<b><size=24>ALTITUDE</size>      </b> " + round(shipAltitude) + " <size=24>M</size>".
    }

    set sLOXLabel:text to "<b>LOX</b>   ".// + round(shipLOX,1) + " %".
    set sLOXSlider:style:overflow:right to -196 + 2*round(shipLOX,1).
    set sLOXNumber:text to round(shipLOX,1) + "%".

    if methane {
        set sCH4Label:text to "<b>CH4</b>   ".// + round(shipCH4,1) + " %".
        set sCH4Slider:style:overflow:right to -196 + 2*round(shipCH4,1).
        set sCH4Number:text to round(shipCH4,1) + "%".
    } else {
        set sCH4Label:text to "<b>Fuel</b>   ".// + round(shipCH4,1) + " %".
        set sCH4Slider:style:overflow:right to -196 + 2*round(shipCH4,1).
        set sCH4Number:text to round(shipCH4,1) + "%".
    }

    set shipThrust to 0.
    for eng in SLEngines {
        set shipThrust to shipThrust + eng:thrust.
    }
    for eng in VACEngines {
        set shipThrust to shipThrust + eng:thrust.
    }

    if Boosterconnected set currentThr to 0.
    else set currentThr to throttle.

    set sThrust:text to "<b>Thrust: </b> " + round(shipThrust) + " kN" + "          Throttle: " + min(round(currentThr,2)*100,100) + "%".

    set missionTimerNow to time:seconds-missionTimer.
    if missionTimerNow < 0 {
        set missionTimerNow to -missionTimerNow.
        set TMinus to true.
    } 
    else set TMinus to false.

    set hoursV to missionTimerNow/60/60.
    set Thours to round(hoursV).
    if hoursV < Thours {
        set Thours to Thours - 1.
    }

    set minV to missionTimerNow/60 - Thours*60.
    set Tminutes to round(minV).
    if minV < Tminutes {
        set Tminutes to Tminutes - 1.
    }
    
    set Tseconds to missionTimerNow - Thours*60*60 - Tminutes*60.
    set Tseconds to round(Tseconds).

    if Thours < 9.1 {
        set Thours to "0"+Thours.
    }
    if Tminutes < 9.1 {
        set Tminutes to "0"+Tminutes.
    }
    if Tseconds < 9.1 {
        set Tseconds to "0"+Tseconds.
    }
    if Boosterconnected or runningprogram = "LAUNCH" {
        set missionTimeLabel:text to "".
        VersionDisplay:hide().
    } else if TMinus {
        set missionTimeLabel:text to "T- "+Thours+":"+Tminutes+":"+Tseconds.
        VersionDisplay:show().
    } else {
        set missionTimeLabel:text to "T+ "+Thours+":"+Tminutes+":"+Tseconds.
        VersionDisplay:show().
    }
    
}

