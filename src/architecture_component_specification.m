function specification = architecture_component_specification(database,selections,componentKey)
%ARCHITECTURE_COMPONENT_SPECIFICATION Build user-facing architecture specifications.
%   The returned rows are deliberately curated. Catalog-backed values come
%   from the selected database records; functional blocks report implemented
%   rules and explicitly identify ratings that are not parameterized.

arguments
    database (1,1) struct
    selections (1,1) struct
    componentKey (1,1) string
end

key=lower(componentKey);
battery1=catalogRow(database.Battery_Catalog,selectedID(selections,"SelectedBattery1"));
battery2=catalogRow(database.Battery_Catalog,selectedID(selections,"SelectedBattery2"));
motor=catalogRow(database.Motor_Catalog,selectedID(selections,"SelectedMotor"));
genset=catalogRow(database.Genset_Catalog,selectedID(selections,"SelectedGenset"));
tyre=catalogRow(database.Tyre_Catalog,selectedID(selections,"SelectedTyre"));
drive=catalogRow(database.Final_Drive_Catalog,selectedID(selections,"SelectedFinalDrive"));
auxiliary=catalogRow(database.Aux_Load_Profiles,selectedID(selections,"SelectedAuxProfile"));
control=catalogRow(database.Control_Calibration,selectedID(selections,"SelectedControl"));
vehicle=database.Vehicle_Parameters(1,:);
isBEV=strcmpi(string(fieldValue(selections,"PowertrainMode","Hybrid")),"BEV");
multiplier=double(fieldValue(selections,"BatterySetMultiplier",1));
if isBEV
    totalPackCount=round(2*multiplier);
    battery1Count=ceil(totalPackCount/2);
    battery2Count=floor(totalPackCount/2);
else
    battery1Count=round(multiplier);
    battery2Count=round(multiplier);
    totalPackCount=battery1Count+battery2Count;
end
loadMassTonnes=double(fieldValue(selections,"LoadMass_t",0));
calculatedMass=calculate_vehicle_mass(battery1.Mass_kg,battery1Count, ...
    battery2.Mass_kg,battery2Count,genset.Mass_kg, ...
    string(fieldValue(selections,"PowertrainMode","Hybrid")),loadMassTonnes);

suffix=extractAfter(string(genset.ComponentID),"-");
engine=catalogRow(database.Engine_Catalog,"ENG-"+suffix);
generator=catalogRow(database.Generator_Catalog,"GNR-"+suffix);

switch key
    case "grid_charger"
        specification=makeSpecification("Grid / Depot Charger", ...
            "Recharges the BEV battery pack(s) from external electrical infrastructure while parked",{
            'Energy source','External grid / depot supply','-';
            'Battery set multiplier',numberValue(multiplier,1),'sets';
            'Connected packs',numberValue(totalPackCount,0),'packs';
            'Battery voltage class',numberValue(battery1.VoltageClass_V,0),'V';
            'Grid-charge efficiency',percentValue(vehicle.GridChargeEfficiency),'%';
            'On-route traction connection','None while driving','-';
            'Charger power rating','Not parameterized in mission model','-';
            'Charging schedule','Outside simulated drive mission','-'});
    case "bev_controller"
        specification=makeSpecification("BEV Parallel Contactor and BMS", ...
            "Connects the selected battery banks to the traction bus and coordinates bounded parallel power sharing",{
            'Operating architecture','Battery electric vehicle','-';
            'Battery set multiplier',numberValue(multiplier,1),'sets';
            'Connected batteries',numberValue(totalPackCount,0),'packs';
            'Battery 1 bank',sprintf('%s x %d',textValue(battery1.ComponentID),battery1Count),'-';
            'Battery 2 bank',sprintf('%s x %d',textValue(battery2.ComponentID),battery2Count),'-';
            'Initial SOE',percentValue(fieldValue(selections,"InitialBattery1SOE",0.85)),'%';
            'Power-sharing rule','Proportional to instantaneous pack capability','-';
            'Odd-pack allocation','Additional pack uses Battery 1 selection','-';
            'Genset / fuel path','Absent','-';
            'Regen priority','Auxiliary > connected pack(s) > resistor bank','-'});
    case "fuel"
        specification=makeSpecification("Diesel Fuel System", ...
            "Stores the chemical energy used only by the isolated standby-battery genset",{
            'Fuel type',textValue(genset.FuelType),'-';
            'Tank capacity',numberValue(vehicle.FuelTank_L,1),'L';
            'Fuel density',numberValue(genset.FuelDensity_kg_L,3),'kg/L';
            'Selected genset',textValue(genset.ComponentID),'-';
            'Idle fuel rate',numberValue(genset.IdleFuel_Lph,2),'L/h';
            'Start fuel allowance',numberValue(genset.StartFuel_L,3),'L';
            'Traction connection','None - electrically isolated','-';
            'Data status',textValue(genset.Notes),'-'});
    case "engine"
        specification=makeSpecification("Diesel Engine", ...
            "Runs the generator at the selected genset's constant best-efficiency operating point",{
            'Component ID',textValue(engine.ComponentID),'-';
            'Name',textValue(engine.Name),'-';
            'Manufacturer',textValue(engine.Manufacturer),'-';
            'Rated mechanical power',numberValue(engine.RatedPower_kW,1),'kW';
            'Best BSFC',numberValue(engine.BestBSFC_g_kWh,1),'g/kWh';
            'Low-load BSFC',numberValue(engine.LowLoadBSFC_g_kWh,1),'g/kWh';
            'High-load BSFC',numberValue(engine.HighLoadBSFC_g_kWh,1),'g/kWh';
            'Commanded genset point',numberValue(genset.OptimumPower_kW,1),'kW';
            'Data status',textValue(engine.Notes),'-'});
    case "generator"
        specification=makeSpecification("Generator", ...
            "Converts engine shaft power to electrical power for the standby charging path",{
            'Component ID',textValue(generator.ComponentID),'-';
            'Name',textValue(generator.Name),'-';
            'Manufacturer',textValue(generator.Manufacturer),'-';
            'Rated electrical power',numberValue(generator.RatedPower_kW,1),'kW';
            'Peak efficiency',percentValue(generator.PeakEfficiency),'%';
            'Low-load efficiency',percentValue(generator.LowLoadEfficiency),'%';
            'Voltage class',numberValue(generator.VoltageClass_V,0),'V';
            'Selected genset assembly',textValue(genset.ComponentID),'-';
            'Data status',textValue(generator.Notes),'-'});
    case "charger"
        specification=makeSpecification("Fixed-Point Charger", ...
            "Conditions generator output and charges only the battery assigned to standby",{
            'Selected genset',textValue(genset.ComponentID),'-';
            'Constant operating point',numberValue(genset.OptimumPower_kW,1),'kW';
            'Generator rated power',numberValue(genset.GeneratorRatedPower_kW,1),'kW';
            'Maximum genset power',numberValue(genset.MaxPower_kW,1),'kW';
            'Generator peak efficiency',percentValue(generator.PeakEfficiency),'%';
            'Target battery','Standby pack only','-';
            'Traction-bus connection','None','-';
            'Converter switching detail','Not represented in concept energy model','-'});
    case "standby_selector"
        specification=makeSpecification("Standby Charge Selector", ...
            "Routes the isolated charger output to whichever battery is currently in standby",{
            'Battery 1',textValue(battery1.ComponentID),'-';
            'Battery 2',textValue(battery2.ComponentID),'-';
            'Packs per role bank',numberValue(battery1Count,0),'packs';
            'Role-swap threshold',percentValue(control.SwitchLowSOE),'% SOE';
            'Genset start threshold',percentValue(control.GensetStartSOE),'% SOE';
            'Genset stop threshold',percentValue(control.GensetStopSOE),'% SOE';
            'Genset target',percentValue(control.GensetTargetSOE),'% SOE';
            'Minimum genset time',numberValue(control.MinGensetTime_s,0),'s';
            'Implemented rule','Charge standby battery only','-'});
    case "battery1"
        specification=batterySpecification(battery1,"Battery 1",selections, ...
            "InitialBattery1SOE",battery1Count);
    case "active_selector"
        initialActive=fieldValue(selections,"InitialActiveBattery",database.Dashboard.InitialActiveBattery);
        specification=makeSpecification("Active Battery Selector", ...
            "Connects one battery bank to traction while assigning the equal-sized alternate bank to standby charging",{
            'Battery 1',textValue(battery1.ComponentID),'-';
            'Battery 2',textValue(battery2.ComponentID),'-';
            'Packs per bank',numberValue(battery1Count,0),'packs';
            'Initial active battery',numberValue(initialActive,0),'-';
            'Role-swap threshold',percentValue(control.SwitchLowSOE),'% SOE';
            'Minimum active time',numberValue(control.MinActiveTime_s,0),'s';
            'Swap condition','Active SOE at/below threshold and alternate pack ready','-';
            'Traction connection','Active bank only','-';
            'Genset connection','Standby bank only','-'});
    case "battery2"
        specification=batterySpecification(battery2,"Battery 2",selections, ...
            "InitialBattery2SOE",battery2Count);
    case "traction_bus"
        voltageCompatible=battery1.VoltageClass_V==battery2.VoltageClass_V && ...
            battery1.VoltageClass_V==motor.VoltageClass_V;
        if isBEV, sourceText=sprintf('%d parallel battery packs',totalPackCount);
        else, sourceText=sprintf('%d-pack active bank',battery1Count); end
        specification=makeSpecification("Traction DC Bus", ...
            "Distributes battery energy to traction and auxiliaries and receives motor-inverter regeneration",{
            'Battery 1 voltage class',numberValue(battery1.VoltageClass_V,0),'V';
            'Battery 2 voltage class',numberValue(battery2.VoltageClass_V,0),'V';
            'Motor voltage class',numberValue(motor.VoltageClass_V,0),'V';
            'Voltage compatibility',yesNo(voltageCompatible),'-';
            'Traction source',sourceText,'-';
            'Genset connection','None - isolated','-';
            'Regeneration priority','Auxiliary > active battery > resistor bank','-';
            'Electrical transient rating','Not parameterized in concept model','-'});
    case "motors"
        specification=makeSpecification("Rear Hub Motor Pair and Inverters", ...
            "Provides wheel-side propulsion and converts braking torque into DC regeneration",{
            'Component ID',textValue(motor.ComponentID),'-';
            'Name',textValue(motor.Name),'-';
            'Manufacturer',textValue(motor.Manufacturer),'-';
            'Quantity','2','motors';
            'Peak power per motor',numberValue(motor.PeakPower_kW,1),'kW';
            'Pair peak power',numberValue(2*motor.PeakPower_kW,1),'kW';
            'Continuous power per motor',numberValue(motor.ContinuousPower_kW,1),'kW';
            'Peak torque per motor',numberValue(motor.PeakTorque_Nm,0),'N m';
            'Maximum speed',numberValue(motor.MaxSpeed_rpm,0),'rpm';
            'Motoring efficiency',percentValue(motor.MotoringEfficiency),'%';
            'Regeneration efficiency',percentValue(motor.RegenEfficiency),'%';
            'Voltage class',numberValue(motor.VoltageClass_V,0),'V';
            'Data status',textValue(motor.Notes),'-'});
    case "reduction"
        specification=makeSpecification("Fixed Reduction Gear", ...
            "Matches motor speed and torque to the driven wheels in traction and regeneration",{
            'Component ID',textValue(drive.ComponentID),'-';
            'Name',textValue(drive.Name),'-';
            'Manufacturer',textValue(drive.Manufacturer),'-';
            'Reduction ratio',numberValue(drive.Ratio,2),':1';
            'Motoring efficiency',percentValue(drive.MotoringEfficiency),'%';
            'Regeneration efficiency',percentValue(drive.RegenEfficiency),'%';
            'Mass',numberValue(drive.Mass_kg,1),'kg';
            'Motor compatible range',sprintf('%.1f to %.1f',motor.MinReductionRatio,motor.MaxReductionRatio),':1';
            'Ratio compatibility',yesNo(drive.Ratio>=motor.MinReductionRatio && drive.Ratio<=motor.MaxReductionRatio),'-';
            'Data status',textValue(drive.Notes),'-'});
    case "vehicle"
        specification=makeSpecification("Wheels and Vehicle", ...
            "Converts wheel torque into longitudinal motion against inertia, grade, drag, and rolling resistance",{
            'Mass method','Calculated from installed hardware and load','-';
            'Minimum base curb mass',numberValue(calculatedMass.BaseCurbMass_kg,0),'kg';
            'Installed battery mass',numberValue(calculatedMass.BatteryMass_kg,0),'kg';
            'Installed genset mass',numberValue(calculatedMass.GensetMass_kg,0),'kg';
            'Calculated curb mass',numberValue(calculatedMass.CurbMass_kg,0),'kg';
            'User-entered load',numberValue(calculatedMass.LoadMass_t,3),'t';
            'Total vehicle mass',numberValue(calculatedMass.TotalVehicleMass_kg,0),'kg';
            'Tyre component',textValue(tyre.ComponentID),'-';
            'Loaded tyre radius',numberValue(tyre.LoadedRadius_m,3),'m';
            'Tyre maximum load',numberValue(tyre.MaxLoad_kg,0),'kg';
            'Drag coefficient',numberValue(vehicle.DragCoefficient,3),'-';
            'Frontal area',numberValue(vehicle.FrontalArea_m2,2),'m^2';
            'Rolling resistance coefficient',numberValue(vehicle.RollingResistanceCoefficient,4),'-'});
    case "auxiliary"
        specification=makeSpecification("DC Auxiliary Loads", ...
            "Operates throughout the mission; regeneration supplies it first whenever braking energy is available",{
            'Component ID',textValue(auxiliary.ComponentID),'-';
            'Name',textValue(auxiliary.Name),'-';
            'Base electrical power',numberValue(auxiliary.BasePower_kW,2),'kW';
            'Cold HVAC slope',numberValue(auxiliary.ColdHVAC_kW_per_C,3),'kW/degC';
            'Hot HVAC slope',numberValue(auxiliary.HotHVAC_kW_per_C,3),'kW/degC';
            'Comfort temperature',numberValue(auxiliary.ComfortTemperature_C,1),'degC';
            'Normal source','Active battery through traction DC bus','-';
            'Regeneration priority','Priority 1','-';
            'Data status',textValue(auxiliary.Notes),'-'});
    case "resistor"
        specification=makeSpecification("Resistor Load Bank", ...
            "Dissipates regenerative energy that cannot be used by auxiliaries or accepted by the active battery",{
            'Regeneration priority','Priority 3 (last)','-';
            'Activation condition','Regen remains after auxiliary demand and active-battery limits','-';
            'Energy conversion','Electrical energy to waste heat','-';
            'Rated power','Not parameterized','-';
            'Thermal capacity','Not parameterized','-';
            'Temperature dynamics','Not represented','-';
            'Model treatment','Unbounded concept-level energy sink','-';
            'Engineering requirement','Size and thermally validate before hardware design','-'});
    case "friction_brake"
        specification=makeSpecification("Pneumatic Friction Braking", ...
            "Supplies wheel-braking demand that exceeds regenerative-braking capability",{
            'Braking strategy','Regenerative braking first; pneumatic braking supplies residual','-';
            'Implemented command','max(0, wheel braking demand - regenerative wheel braking)','kW';
            'Energy destination','Mechanical braking energy converted to friction heat','-';
            'Actuation model','Ideal residual-demand actuator in prescribed-speed backward model','-';
            'Rated braking power','Not parameterized','kW';
            'Pneumatic pressure dynamics','Not represented','-';
            'ABS / EBS modulation','Not represented','-';
            'Tyre adhesion and axle split','Not represented','-';
            'Thermal fade, wear and temperature','Not represented','-';
            'Engineering requirement','Size and validate in a forward-dynamics brake model','-'});
    case "controller"
        specification=makeSpecification("Supervisory Energy Manager", ...
            "Coordinates battery roles, standby charging, regeneration allocation, and genset hysteresis",{
            'Calibration ID',textValue(control.ComponentID),'-';
            'Name',textValue(control.Name),'-';
            'Role-swap threshold',percentValue(control.SwitchLowSOE),'% SOE';
            'Genset start threshold',percentValue(control.GensetStartSOE),'% SOE';
            'Genset stop threshold',percentValue(control.GensetStopSOE),'% SOE';
            'Regen redirect threshold',percentValue(control.RegenRedirectSOE),'% SOE';
            'Minimum active time',numberValue(control.MinActiveTime_s,0),'s';
            'Minimum genset time',numberValue(control.MinGensetTime_s,0),'s';
            'Genset target',percentValue(control.GensetTargetSOE),'% SOE';
            'Core policy','30% role swap; standby-only optimum-point charging','-';
            'Data status',textValue(control.Notes),'-'});
    otherwise
        error('HybridBus:UnknownArchitectureComponent', ...
            'Unknown architecture component key: %s',componentKey);
end
end

function specification=batterySpecification(row,titleText,selections,initialField,packCount)
initialSOE=fieldValue(selections,initialField,NaN);
isBEV=strcmpi(string(fieldValue(selections,"PowertrainMode","Hybrid")),"BEV");
if isBEV, roleText="Operates on the BEV traction bus when selected by the parallel contactor/BMS";
else, roleText="Alternates between traction-active and genset-charged standby roles"; end
specification=makeSpecification(titleText, ...
    roleText,{
    'Component ID',textValue(row.ComponentID),'-';
    'Name',textValue(row.Name),'-';
    'Manufacturer',textValue(row.Manufacturer),'-';
    'Chemistry',textValue(row.Chemistry),'-';
    'Initial SOE',percentValue(initialSOE),'%';
    'Parallel pack count',numberValue(packCount,0),'packs';
    'Nominal energy',numberValue(row.NominalEnergy_kWh,1),'kWh';
    'Bank nominal energy',numberValue(packCount*row.NominalEnergy_kWh,1),'kWh';
    'Usable energy',numberValue(row.UsableEnergy_kWh,1),'kWh';
    'Bank usable energy',numberValue(packCount*row.UsableEnergy_kWh,1),'kWh';
    'Nominal voltage',numberValue(row.NominalVoltage_V,0),'V';
    'Voltage range',sprintf('%.0f to %.0f',row.MinVoltage_V,row.MaxVoltage_V),'V';
    'Maximum discharge power',numberValue(row.MaxDischarge_kW,1),'kW';
    'Bank maximum discharge',numberValue(packCount*row.MaxDischarge_kW,1),'kW';
    'Maximum charge power',numberValue(row.MaxCharge_kW,1),'kW';
    'Maximum regenerative power',numberValue(row.MaxRegen_kW,1),'kW';
    'Bank maximum regeneration',numberValue(packCount*row.MaxRegen_kW,1),'kW';
    'SOE operating range',sprintf('%.0f to %.0f',100*row.MinSOE,100*row.MaxSOE),'%';
    'Charge / discharge efficiency',sprintf('%.1f / %.1f',100*row.ChargeEfficiency,100*row.DischargeEfficiency),'%';
    'Mass',numberValue(row.Mass_kg,1),'kg';
    'Bank mass',numberValue(packCount*row.Mass_kg,1),'kg';
    'Data status',textValue(row.Notes),'-'});
end

function specification=makeSpecification(titleText,roleText,rows)
specification=struct('Title',string(titleText),'Role',string(roleText), ...
    'Rows',{rows},'ColumnNames',{{'Specification','Value','Unit'}});
end

function row=catalogRow(catalog,id)
index=string(catalog.ComponentID)==string(id);
if ~any(index)
    error('HybridBus:MissingArchitectureComponent', ...
        'Selected component %s is missing from its catalog.',string(id));
end
row=catalog(find(index,1),:);
end

function id=selectedID(selections,fieldName)
if ~isfield(selections,fieldName)
    error('HybridBus:MissingArchitectureSelection', ...
        'Architecture selection %s is unavailable.',fieldName);
end
id=string(selections.(fieldName));
end

function value=fieldValue(structure,fieldName,fallback)
if isfield(structure,fieldName)
    value=structure.(fieldName);
else
    value=fallback;
end
end

function text=textValue(value)
text=char(string(value));
end

function text=numberValue(value,decimals)
text=sprintf(['%.' num2str(decimals) 'f'],double(value));
end

function text=percentValue(value)
if isnan(double(value))
    text='Not available';
else
    text=sprintf('%.1f',100*double(value));
end
end

function text=yesNo(value)
if value
    text='Yes';
else
    text='No';
end
end
