function mass = calculate_vehicle_mass(battery1MassKg,battery1Count, ...
    battery2MassKg,battery2Count,gensetMassKg,powertrainMode,loadTonnes)
%CALCULATE_VEHICLE_MASS Resolve curb and total mass from installed hardware.
arguments
    battery1MassKg (1,1) double {mustBeNonnegative}
    battery1Count (1,1) double {mustBeNonnegative,mustBeInteger}
    battery2MassKg (1,1) double {mustBeNonnegative}
    battery2Count (1,1) double {mustBeNonnegative,mustBeInteger}
    gensetMassKg (1,1) double {mustBeNonnegative}
    powertrainMode (1,1) string {mustBeMember(powertrainMode,["Hybrid","BEV"])}
    loadTonnes (1,1) double {mustBeNonnegative}
end

baseCurbMassKg=15000;
batteryMassKg=battery1Count*battery1MassKg+battery2Count*battery2MassKg;
installedGensetMassKg=gensetMassKg;
if powertrainMode=="BEV"
    installedGensetMassKg=0;
end
loadMassKg=1000*loadTonnes;
curbMassKg=baseCurbMassKg+batteryMassKg+installedGensetMassKg;
totalMassKg=curbMassKg+loadMassKg;

mass=struct( ...
    'ComponentID',"CALCULATED", ...
    'Name',"Calculated vehicle mass", ...
    'BaseCurbMass_kg',baseCurbMassKg, ...
    'BatteryMass_kg',batteryMassKg, ...
    'GensetMass_kg',installedGensetMassKg, ...
    'LoadMass_t',loadTonnes, ...
    'LoadMass_kg',loadMassKg, ...
    'CurbMass_kg',curbMassKg, ...
    'TotalVehicleMass_kg',totalMassKg);
end
