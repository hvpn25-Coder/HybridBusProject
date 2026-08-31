function Input = prepare_hybrid_bus_inputs(Database, overrides)
%PREPARE_HYBRID_BUS_INPUTS Resolve dashboard selections and route inputs.
arguments
    Database (1,1) struct
    overrides (1,1) struct = struct
end
D = Database.Dashboard;
D = apply_overrides(D,overrides);
Input = struct;
Input.DatabaseFile = Database.Filename;
Input.DatabaseVersion = Database.Version;
Input.SelectedIDs = struct('Route',string(D.SelectedRoute), ...
    'Battery1',string(D.SelectedBattery1),'Battery2',string(D.SelectedBattery2), ...
    'Motor',string(D.SelectedMotor),'Genset',string(D.SelectedGenset), ...
    'Tyre',string(D.SelectedTyre),'FinalDrive',string(D.SelectedFinalDrive), ...
    'Mass',string(D.SelectedMass),'Aux',string(D.SelectedAuxProfile), ...
    'Environment',string(D.SelectedEnvironment),'Control',string(D.SelectedControl));

if isfield(D,'PowertrainMode')
    Input.PowertrainMode=string(D.PowertrainMode);
else
    Input.PowertrainMode="Hybrid";
end
if isfield(D,'BatterySetMultiplier')
    Input.BatterySetMultiplier=double(D.BatterySetMultiplier);
elseif isfield(D,'BEVUseTwoBatteries') && strcmpi(Input.PowertrainMode,"BEV")
    % Backward compatibility for saved configurations created before the
    % battery-set multiplier replaced the BEV two-battery checkbox.
    Input.BatterySetMultiplier=0.5+0.5*double(logical(D.BEVUseTwoBatteries));
else
    Input.BatterySetMultiplier=1;
end
if strcmpi(Input.PowertrainMode,"BEV")
    assert(Input.BatterySetMultiplier>=0.5 && ...
        abs(2*Input.BatterySetMultiplier-round(2*Input.BatterySetMultiplier))<=1e-9, ...
        'HybridBus:InvalidBEVBatterySetMultiplier', ...
        'BEV BatterySetMultiplier must be 0.5 or greater in 0.5-set increments.');
    Input.TotalBatteryPackCount=round(2*Input.BatterySetMultiplier);
    Input.Battery1PackCount=ceil(Input.TotalBatteryPackCount/2);
    Input.Battery2PackCount=floor(Input.TotalBatteryPackCount/2);
else
    assert(Input.BatterySetMultiplier>=1 && ...
        abs(Input.BatterySetMultiplier-round(Input.BatterySetMultiplier))<=1e-9, ...
        'HybridBus:InvalidHybridBatterySetMultiplier', ...
        'Hybrid BatterySetMultiplier must be a positive whole number.');
    Input.Battery1PackCount=round(Input.BatterySetMultiplier);
    Input.Battery2PackCount=round(Input.BatterySetMultiplier);
    Input.TotalBatteryPackCount=Input.Battery1PackCount+Input.Battery2PackCount;
end
Input.BEVUseTwoBatteries=strcmpi(Input.PowertrainMode,"BEV") && Input.Battery2PackCount>0;
Input.SelectedIDs.PowertrainMode=Input.PowertrainMode;

Input.BaseBattery1 = attach_battery_maps( ...
    select_row(Database.Battery_Catalog,Input.SelectedIDs.Battery1), ...
    Database.Battery_Maps,Input.SelectedIDs.Battery1);
Input.BaseBattery2 = attach_battery_maps( ...
    select_row(Database.Battery_Catalog,Input.SelectedIDs.Battery2), ...
    Database.Battery_Maps,Input.SelectedIDs.Battery2);
Input.Battery1 = scale_battery_bank(Input.BaseBattery1,Input.Battery1PackCount);
% A zero-count Battery-2 bank remains numerically defined but disconnected.
% This avoids artificial divide-by-zero states in the common two-bank core.
Input.Battery2 = scale_battery_bank(Input.BaseBattery2,max(1,Input.Battery2PackCount));
Input.Motor = attach_motor_loss_map( ...
    select_row(Database.Motor_Catalog,Input.SelectedIDs.Motor), ...
    Database.Motor_Maps,Input.SelectedIDs.Motor);
Input.Genset = select_row(Database.Genset_Catalog,Input.SelectedIDs.Genset);
Input.Tyre = select_row(Database.Tyre_Catalog,Input.SelectedIDs.Tyre);
Input.FinalDrive = select_row(Database.Final_Drive_Catalog,Input.SelectedIDs.FinalDrive);
Input.LegacyMassSelection = select_row(Database.Bus_Mass_Catalog,Input.SelectedIDs.Mass);
if isfield(D,'LoadMass_t')
    Input.LoadMass_t=double(D.LoadMass_t);
else
    Input.LoadMass_t=0;
end
Input.Mass=calculate_vehicle_mass(Input.BaseBattery1.Mass_kg, ...
    Input.Battery1PackCount,Input.BaseBattery2.Mass_kg, ...
    Input.Battery2PackCount,Input.Genset.Mass_kg,Input.PowertrainMode, ...
    Input.LoadMass_t);
Input.Aux = select_row(Database.Aux_Load_Profiles,Input.SelectedIDs.Aux);
Input.Environment = select_row(Database.Environment,Input.SelectedIDs.Environment);
Input.Battery1=condition_battery_temperature(Input.Battery1,Input.Environment.Temperature_C);
Input.Battery2=condition_battery_temperature(Input.Battery2,Input.Environment.Temperature_C);
Input.Control = select_row(Database.Control_Calibration,Input.SelectedIDs.Control);
% The battery-role threshold is an architectural safety rule, not a tunable
% calibration: the active pack hands traction duty over at 30% SOE.
Input.Control.SwitchLowSOE = 0.30;
% A pack keeps charging for as long as it remains standby, up to the lower
% selected-pack upper-SOE limit used by the simplified SLX relay.
Input.Control.GensetTargetSOE = min(Input.Battery1.MaxSOE,Input.Battery2.MaxSOE);
Input.Vehicle = table2struct(Database.Vehicle_Parameters(1,:));
Input.Prices = table2struct(Database.Energy_Prices(1,:));
Input.Optimization = table2struct(Database.Optimization_Settings(1,:));
Input.FuelMap = selected_genset_map(Database.Engine_Fuel_Map,Input.SelectedIDs.Genset);
Input.GeneratorMap = selected_genset_map( ...
    Database.Generator_Efficiency_Map,Input.SelectedIDs.Genset);
Input.InitialBattery1SOE = double(D.InitialBattery1SOE);
Input.InitialBattery2SOE = double(D.InitialBattery2SOE);
Input.InitialActiveBattery = double(D.InitialActiveBattery);
Input.AuxiliaryScalarOverride = double(D.AuxiliaryScalarOverride);
Input.Vehicle.FuelTank_L = double(D.FuelTankCapacity);
Input.Prices.FuelPrice_per_L = double(D.FuelPrice);
Input.Prices.ElectricityPrice_per_kWh = double(D.ElectricityPrice);
Input.RepeatUntilDepleted = isfield(D,'RepeatUntilDepleted') && logical(D.RepeatUntilDepleted);
if isfield(D,'SimulationFormulation')
    Input.SimulationFormulation=string(D.SimulationFormulation);
else
    Input.SimulationFormulation="BackwardDemand";
end
assert(any(Input.SimulationFormulation==["BackwardDemand","ConstrainedBackward","ForwardPerformance"]), ...
    'HybridBus:SimulationFormulation', ...
    'SimulationFormulation must be BackwardDemand, ConstrainedBackward, or ForwardPerformance.');
Input.Performance=struct( ...
    'DriverProportionalGain_s',0.45, ...
    'MaximumAcceleration_m_s2',1.0, ...
    'MaximumDeceleration_m_s2',2.5, ...
    'ComfortableStopDeceleration_m_s2',1.2, ...
    'MinimumStationDwell_s',20, ...
    'StationPositionTolerance_m',1.5, ...
    'StationStopSpeed_m_s',0.15, ...
    'PostStopLookAhead_m',3, ...
    'LowSpeedProtection_m_s',0.5, ...
    'MinimumRegenerationSpeed_m_s',1.0, ...
    'ZeroSpeedThreshold_m_s',0.05, ...
    'TargetMovingThreshold_m_s',0.5, ...
    'SpeedTrackingTolerance_m_s',1.0, ...
    'StallDetectionTime_s',30, ...
    'StallForceMargin_N',100, ...
    'CompletionTolerance_m',2, ...
    'MaximumDurationFactor',3, ...
    'MaximumExtraTime_s',3600);
if isfield(overrides,'Performance')
    Input.Performance=apply_overrides(Input.Performance,overrides.Performance);
end
if strcmpi(Input.PowertrainMode,"BEV")
    % All connected BEV packs start at a common SOE. A 0.5-set BEV has one
    % Battery-1 pack and a numerically retained but electrically isolated B2.
    Input.InitialBattery2SOE=Input.InitialBattery1SOE;
    if Input.Battery2PackCount>0
        assert(Input.Battery1.VoltageClass_V==Input.Battery2.VoltageClass_V, ...
            'HybridBus:BEVBatteryVoltageMismatch', ...
            'Two-battery BEV operation requires matching battery voltage classes.');
    end
end

R = Database.Route_Time_Speed(Database.Route_Time_Speed.RouteID==Input.SelectedIDs.Route,:);
assert(height(R)>=2,'HybridBus:RouteMissing','Selected route %s was not found.',Input.SelectedIDs.Route);
dt = Input.Vehicle.SampleTime_s;
time = (R.Time_s(1):dt:R.Time_s(end))';
Input.Route = table(time,interp1(R.Time_s,R.Speed_kmh,time,'linear'), ...
    interp1(R.Time_s,R.Grade_pct,time,'linear'), ...
    interp1(R.Time_s,double(R.StopFlag),time,'previous')>0.5, ...
    interp1(R.Time_s,R.AuxMultiplier,time,'linear'), ...
    'VariableNames',{'Time_s','Speed_kmh','Grade_pct','StopFlag','AuxMultiplier'});
Input.Route.Distance_m = cumtrapz(time,Input.Route.Speed_kmh/3.6);
Input.RouteDistance_km = Input.Route.Distance_m(end)/1000;
if Input.SimulationFormulation=="ConstrainedBackward"
    % The constrained formulation is deliberately a single fast route-time
    % pass. Detailed repeated-route depletion remains a Performance feature.
    Input.RepeatUntilDepleted=false;
end
if Input.RepeatUntilDepleted
    % Build a continuous repeated mission long enough to exceed any credible
    % tank-supported range. The core truncates at physical depletion.
    repetitions=max(2,ceil(10000/Input.RouteDistance_km));
    baseRoute=Input.Route; cycleTime=baseRoute.Time_s(end)-baseRoute.Time_s(1);
    cycleDistance=baseRoute.Distance_m(end);
    repeated=baseRoute;
    for cycle=2:repetitions
        next=baseRoute(2:end,:);
        next.Time_s=next.Time_s+(cycle-1)*cycleTime;
        next.Distance_m=next.Distance_m+(cycle-1)*cycleDistance;
        repeated=[repeated;next]; %#ok<AGROW>
    end
    Input.Route=repeated;
end
if isfield(Database,'Route_Catalog')
    routeMask=Database.Route_Catalog.RouteID==Input.SelectedIDs.Route;
    if any(routeMask), Input.RouteMetadata=table2struct(Database.Route_Catalog(routeMask,:)); end
end
assert(Input.RouteDistance_km>0,'HybridBus:ZeroDistance','Route distance must be positive.');
end

function map=selected_genset_map(map,gensetID)
% Each genset script owns its maps; remove the index column before simulation.
if ismember('GensetID',map.Properties.VariableNames)
    map=map(map.GensetID==gensetID,:);
    map.GensetID=[];
end
assert(height(map)>=2,'HybridBus:GensetMapMissing', ...
    'No performance map was found for selected genset %s.',gensetID);
end

function bank=scale_battery_bank(pack,count)
bank=pack;
scalableFields={'NominalEnergy_kWh','UsableEnergy_kWh','ReferenceDischargeCurrent_A', ...
    'ReferenceChargeCurrent_A','Mass_kg'};
for index=1:numel(scalableFields)
    fieldName=scalableFields{index};
    bank.(fieldName)=count*pack.(fieldName);
end
bank.ParallelPackCount=count;
bank.MaxDischargeCurrentMap_A=count*pack.MaxDischargeCurrentMap_A;
bank.MaxChargeCurrentMap_A=count*pack.MaxChargeCurrentMap_A;
bank.OpenCircuitVoltageMap_V=pack.OpenCircuitVoltageMap_V;
bank.InternalResistanceMap_Ohm=pack.InternalResistanceMap_Ohm/max(count,eps);
end

function battery=attach_battery_maps(battery,maps,id)
index=find(string({maps.ComponentID})==string(id));
assert(isscalar(index),'HybridBus:BatteryMapSelection', ...
    'Expected one dynamic battery-map record for %s.',id);
fields={'SOEBreakpoints','SOCBreakpoints','TemperatureBreakpoints_C','MaxDischargeCurrentMap_A', ...
    'MaxChargeCurrentMap_A','OpenCircuitVoltageMap_V','InternalResistanceMap_Ohm','MapBasis'};
for fieldIndex=1:numel(fields)
    field=fields{fieldIndex};
    battery.(field)=maps(index).(field);
end
end

function motor=attach_motor_loss_map(motor,maps,id)
index=find(string({maps.ComponentID})==string(id));
assert(isscalar(index),'HybridBus:MotorMapSelection', ...
    'Expected one motor loss-map record for %s.',id);
fields={'TorqueBreakpoints_Nm','SpeedBreakpoints_rpm','MotorLossMap_kW','MapBasis'};
for fieldIndex=1:numel(fields)
    field=fields{fieldIndex};
    motor.(field)=maps(index).(field);
end
end

function battery=condition_battery_temperature(battery,temperature_C)
temperature_C=min(max(temperature_C,battery.TemperatureBreakpoints_C(1)), ...
    battery.TemperatureBreakpoints_C(end));
battery.ConditionedTemperature_C=temperature_C;
battery.DischargeCurrentVsSOE_A=interp1(battery.TemperatureBreakpoints_C, ...
    battery.MaxDischargeCurrentMap_A,temperature_C,'linear');
battery.ChargeCurrentVsSOE_A=interp1(battery.TemperatureBreakpoints_C, ...
    battery.MaxChargeCurrentMap_A,temperature_C,'linear');
battery.OpenCircuitVoltageVsSOC_V=interp1(battery.TemperatureBreakpoints_C, ...
    battery.OpenCircuitVoltageMap_V,temperature_C,'linear');
battery.InternalResistanceVsSOE_Ohm=interp1(battery.TemperatureBreakpoints_C, ...
    battery.InternalResistanceMap_Ohm,temperature_C,'linear');
end

function row = select_row(T,id)
mask = string(T.ComponentID)==string(id);
assert(nnz(mask)==1,'HybridBus:Selection','Expected one catalog row for %s.',id);
row = table2struct(T(mask,:));
end

function D = apply_overrides(D,O)
fields = fieldnames(O);
for index = 1:numel(fields)
    D.(fields{index}) = O.(fields{index});
end
end
