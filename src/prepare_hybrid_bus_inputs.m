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

Input.BaseBattery1 = select_row(Database.Battery_Catalog,Input.SelectedIDs.Battery1);
Input.BaseBattery2 = select_row(Database.Battery_Catalog,Input.SelectedIDs.Battery2);
Input.Battery1 = scale_battery_bank(Input.BaseBattery1,Input.Battery1PackCount);
% A zero-count Battery-2 bank remains numerically defined but disconnected.
% This avoids artificial divide-by-zero states in the common two-bank core.
Input.Battery2 = scale_battery_bank(Input.BaseBattery2,max(1,Input.Battery2PackCount));
Input.Motor = select_row(Database.Motor_Catalog,Input.SelectedIDs.Motor);
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
Input.FuelMap = Database.Engine_Fuel_Map;
Input.GeneratorMap = Database.Generator_Efficiency_Map;
Input.InitialBattery1SOE = double(D.InitialBattery1SOE);
Input.InitialBattery2SOE = double(D.InitialBattery2SOE);
Input.InitialActiveBattery = double(D.InitialActiveBattery);
Input.AuxiliaryScalarOverride = double(D.AuxiliaryScalarOverride);
Input.Vehicle.FuelTank_L = double(D.FuelTankCapacity);
Input.Prices.FuelPrice_per_L = double(D.FuelPrice);
Input.Prices.ElectricityPrice_per_kWh = double(D.ElectricityPrice);
Input.RepeatUntilDepleted = isfield(D,'RepeatUntilDepleted') && logical(D.RepeatUntilDepleted);
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

function bank=scale_battery_bank(pack,count)
bank=pack;
scalableFields={'NominalEnergy_kWh','UsableEnergy_kWh','MaxDischarge_kW', ...
    'MaxCharge_kW','MaxRegen_kW','Mass_kg'};
for index=1:numel(scalableFields)
    fieldName=scalableFields{index};
    bank.(fieldName)=count*pack.(fieldName);
end
bank.ParallelPackCount=count;
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
