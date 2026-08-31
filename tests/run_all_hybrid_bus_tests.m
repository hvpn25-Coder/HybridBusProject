function TestResults=run_all_hybrid_bus_tests()
%RUN_ALL_HYBRID_BUS_TESTS Execute base-MATLAB assertion tests.
root=fileparts(fileparts(mfilename('fullpath')));
previousFolder=pwd; folderCleanup=onCleanup(@()cd(previousFolder));
cd(root);
addpath(fullfile(root,'src'),fullfile(root,'models'));
databaseFile=fullfile(root,'data','HybridBus_ComponentDatabase.xlsx');
DB=load_hybrid_bus_database(databaseFile);
cases={
 'ConstantSpeedLevel','Constant-speed wheel power matches hand calculation',@testConstantSpeed;
 'StationaryAuxiliary','Auxiliary load consumes battery energy at zero speed',@testStationaryAux;
 'LevelAcceleration','Acceleration increases wheel demand',@testAcceleration;
 'PositiveGrade','Positive grade increases wheel power',@testPositiveGrade;
 'DownhillRegeneration','Negative grade produces regenerative DC power',@testRegeneration;
 'PneumaticBrakeBlending','Friction brakes supply braking demand beyond regeneration',@testPneumaticBrakeBlending;
 'RegenerationPriority','Regeneration supplies auxiliaries, then the active battery, then the load bank',@testRegenerationPriority;
 'BatterySwitching','Low active pack deterministically switches to standby pack',@testSwitching;
 'StandbyGensetCharge','Genset charges only the standby battery',@testStandbyCharge;
 'GensetTractionIsolation','Genset output never offsets traction-bus demand',@testGensetIsolation;
 'GensetHysteresis','Genset starts for low standby SOE without chattering',@testGensetHysteresis;
 'BatteryUpperLimit','Battery energy never exceeds upper limit',@testUpperLimit;
 'BatteryLowerLimit','Battery energy never falls below lower limit',@testLowerLimit;
 'MotorSaturation','Motor saturation reports unmet wheel power',@testMotorSaturation;
 'GensetBestEfficiencyPoint','Genset runs at one constant optimum power',@testGensetBestPoint;
 'RouteGeolocation','Every geographic corridor has ordered valid latitude and longitude geometry',@testRouteGeolocation;
 'RouteMatStorage','Each route is loaded from one self-contained MAT file',@testRouteMatStorage;
 'ComponentMFileStorage','Each battery and motor is loaded from one versioned MATLAB data script',@testComponentMFileStorage;
 'MotorLossMaps','Motor torque-speed maps are valid and determine conversion loss',@testMotorLossMaps;
 'BatteryDynamicMaps','Battery current limits, OCV, and resistance respond to SOE and temperature',@testBatteryDynamicMaps;
 'GensetMFileStorage','Each complete genset assembly is loaded from one versioned MATLAB data script',@testGensetMFileStorage;
 'ComponentExtension','Arbitrary battery, motor, and genset IDs load and simulate without central code changes',@testComponentExtension;
 'RouteValidationFailure','Duplicate route time is rejected',@testRouteFailure;
 'IncompatibleSelection','Compatibility filter records rejection reason',@testIncompatible;
 'EnergyConservation','Cumulative DC residual remains within tolerance',@testEnergyBalance;
 'Repeatability','Identical inputs produce identical scalar KPIs',@testRepeatability;
 'ZeroSpeedStability','Zero-speed calculation remains finite',@testZeroSpeed;
 'ComponentPhysicalSignals','Architecture component electrical and mechanical signals obey their defining equations',@testComponentPhysicalSignals;
 'TerminalCostCorrection','Grid-equivalent terminal correction matches hand calculation',@testCostCorrection;
 'ChargeSustainingComparison','Terminal combined-SOE tolerance is enforced',@testChargeSustaining;
 'OptimizationRanking','Feasible configurations are sorted by total cost per kilometre',@testOptimizationRanking;
 'ForwardFlatRoute','Forward plant completes a feasible flat route with achieved speed and distance',@testForwardFlatRoute;
 'ForwardSevereGradeStall','An underpowered vehicle stalls without rollback and leaves the route incomplete',@testForwardSevereGradeStall;
 'ForwardDistanceIndexedGrade','Terrain changes are sampled at actual travelled distance',@testForwardDistanceIndexedGrade;
 'ForwardPowertrainModes','Forward formulation supports both BEV and Hybrid energy systems',@testForwardPowertrainModes;
 'FormulationDispatcher','The dispatcher preserves the legacy backward-demand result',@testFormulationDispatcher;
 'ForwardSimulinkStructure','Editable forward Simulink plant compiles with the expected feature subsystems',@testForwardSimulinkStructure};
cases=[cases; {
 'ConstrainedAccelerationSuppression','Available current, torque, power, and force suppress achieved acceleration and speed',@testConstrainedAccelerationSuppression;
 'ConstrainedEnergyDepletion','A depleted battery leaves the vehicle stopped without rollback',@testConstrainedEnergyDepletion;
 'ConstrainedDistanceTerrain','The fast constrained pass samples terrain at actual distance',@testConstrainedDistanceTerrain;
 'ConstrainedPowertrainModes','The fast constrained pass supports both BEV and Hybrid',@testConstrainedPowertrainModes;
 'ConstrainedFixedHorizon','Constrained mode uses one route-time horizon and suppresses repeat-route expansion',@testConstrainedFixedHorizon}];
cases=[cases; {
 'BEVDualBattery','BEV uses both equal-SOE batteries in parallel with no fuel or genset',@testBEVDualBattery;
 'BEVSingleBattery','One-battery BEV electrically isolates Battery 2',@testBEVSingleBattery;
 'HybridDoubleBatterySet','Two Hybrid sets scale both role banks equally',@testHybridDoubleBatterySet;
 'BEVThreeBatterySet','A 1.5-set BEV connects three packs with deterministic bank allocation',@testBEVThreeBatterySet;
 'BatterySetValidation','Hybrid and BEV multipliers enforce their permitted increments',@testBatterySetValidation;
 'HybridCalculatedMass','Hybrid mass includes base curb, all batteries, genset, and load',@testHybridCalculatedMass;
 'BEVCalculatedMass','BEV mass includes base curb, all batteries, and load but no genset',@testBEVCalculatedMass;
 'BEVRegeneration','BEV regeneration follows auxiliary, batteries, resistor priority',@testBEVRegeneration}];

n=size(cases,1); names=strings(n,1); purposes=strings(n,1); actual=strings(n,1);
status=strings(n,1); elapsed=zeros(n,1);
for k=1:n
    names(k)=cases{k,1}; purposes(k)=cases{k,2}; timer=tic;
    try
        actual(k)=string(cases{k,3}(DB,databaseFile)); status(k)="PASS";
    catch exception
        actual(k)=string(exception.message); status(k)="FAIL";
    end
    elapsed(k)=toc(timer);
end
TestResults=table(names,purposes,repmat("See test function",n,1), ...
    repmat("Assertion passes",n,1),actual,status,elapsed, ...
    'VariableNames',{'Test','Purpose','Inputs','Expected','Actual','Status','Elapsed_s'});
resultsFolder=fullfile(root,'results'); if ~isfolder(resultsFolder),mkdir(resultsFolder);end
writetable(TestResults,fullfile(resultsFolder,'HybridBus_TestResults.csv'));
save(fullfile(resultsFolder,'HybridBus_TestResults.mat'),'TestResults');
disp(TestResults(:,{'Test','Status','Actual'}));
assert(all(status=="PASS"),'HybridBus:TestFailure','%d of %d tests failed.',sum(status=="FAIL"),n);
end

function text=testConstantSpeed(DB,~)
I=baseInput(DB); I=setRoute(I,(0:100)',36*ones(101,1),zeros(101,1)); R=simulate_hybrid_bus_core(I);
assert(R.Summary.EstimatedVehicleMass_kg==I.Mass.TotalVehicleMass_kg);
v=10; vAir=v+I.Environment.Headwind_m_s; expected=(R.Summary.EstimatedVehicleMass_kg*I.Vehicle.Gravity_m_s2* ...
    I.Tyre.RollingResistanceCoefficient+0.5*I.Environment.AirDensity_kg_m3* ...
    I.Vehicle.DragCoefficient*I.Vehicle.FrontalArea_m2*vAir^2)*v/1000;
actual=median(R.Signals.Wheel.Demand_kW(10:end)); assert(abs(actual-expected)/expected<0.02);
text=sprintf('%.0f kg: actual %.3f kW, hand %.3f kW', ...
    R.Summary.EstimatedVehicleMass_kg,actual,expected);
end

function text=testRouteGeolocation(DB,~)
catalog=DB.Route_Catalog;
geographicIDs=catalog.RouteID(logical(catalog.HasGeolocation));
assert(numel(geographicIDs)==17 && height(DB.Route_Geometry)>=16000);
assert(~any(contains(catalog.RouteType,"Synthetic",'IgnoreCase',true)));
for routeID=geographicIDs'
    row=catalog(catalog.RouteID==routeID,:);
    geometry=sortrows(DB.Route_Geometry(DB.Route_Geometry.RouteID==routeID,:),'Sequence');
    assert(height(geometry)>=2 && all(diff(geometry.Sequence)>0));
    assert(all(geometry.Latitude_deg>=-90 & geometry.Latitude_deg<=90));
    assert(all(geometry.Longitude_deg>=-180 & geometry.Longitude_deg<=180));
    assert(all(isfinite(geometry.Elevation_m)));
    assert(all(strlength(geometry.ElevationSource)>0));
    assert(all(diff(geometry.CumulativeDistance_km)>=0));
    assert(abs(geometry.Latitude_deg(1)-row.OriginLatitude_deg)<1e-9 && ...
        abs(geometry.Longitude_deg(end)-row.DestinationLongitude_deg)<1e-9);
end
text=sprintf('%d geographic routes, %d coordinate rows', ...
    numel(geographicIDs),height(DB.Route_Geometry));
end

function text=testRouteMatStorage(DB,databaseFile)
routeSheets=["Route_Catalog","Route_Time_Speed","Route_Distance_Speed", ...
    "Route_Grade","Route_Geometry"];
assert(~any(ismember(routeSheets,sheetnames(databaseFile))));
assert(numel(DB.RouteFiles)==height(DB.Route_Catalog) && all(isfile(DB.RouteFiles)));
for index=1:numel(DB.RouteFiles)
    payload=load(DB.RouteFiles(index),'RouteData');
    assert(string(payload.RouteData.Metadata.RouteID)==string(DB.Route_Catalog.RouteID(index)));
    assert(height(payload.RouteData.TimeSpeed)>=2);
end
text=sprintf('%d independent route MAT files loaded',numel(DB.RouteFiles));
end

function text=testComponentMFileStorage(DB,databaseFile)
sheets=sheetnames(databaseFile);
assert(~any(ismember(["Battery_Catalog","Motor_Catalog"],sheets)));
assert(numel(DB.BatteryFiles)==height(DB.Battery_Catalog) && all(isfile(DB.BatteryFiles)));
assert(numel(DB.MotorFiles)==height(DB.Motor_Catalog) && all(isfile(DB.MotorFiles)));
BatteryData=[]; MotorData=[];
run(DB.BatteryFiles(1)); run(DB.MotorFiles(1));
assert(BatteryData.SchemaVersion=="4.0.0" && MotorData.SchemaVersion=="2.0.0");
assert(all(isfield(MotorData,{'TorqueBreakpoints_Nm','SpeedBreakpoints_rpm', ...
    'MotorLossMap_kW','MapBasis'})));
assert(string(BatteryData.Component.ComponentID)==string(DB.Battery_Catalog.ComponentID(1)));
assert(string(MotorData.Component.ComponentID)==string(DB.Motor_Catalog.ComponentID(1)));
text=sprintf('%d battery and %d motor MATLAB files loaded', ...
    numel(DB.BatteryFiles),numel(DB.MotorFiles));
end

function text=testMotorLossMaps(DB,~)
assert(numel(DB.Motor_Maps)==height(DB.Motor_Catalog));
for index=1:numel(DB.Motor_Maps)
    map=DB.Motor_Maps(index);
    assert(isequal(size(map.MotorLossMap_kW), ...
        [numel(map.SpeedBreakpoints_rpm),numel(map.TorqueBreakpoints_Nm)]));
    assert(all(diff(map.TorqueBreakpoints_Nm)>0) && ...
        all(diff(map.SpeedBreakpoints_rpm)>0));
    assert(all(map.MotorLossMap_kW>=0,'all') && map.MotorLossMap_kW(1,1)==0);
    assert(all(diff(map.MotorLossMap_kW,1,2)>=-1e-12,'all'));
    assert(all(diff(map.MotorLossMap_kW,1,1)>=-1e-12,'all'));
end
I=baseInput(DB); R=simulate_hybrid_bus_core(I);
expected=abs(R.Signals.Motors.ElectricalPower_kW- ...
    R.Signals.Motors.MechanicalPower_kW);
assert(max(abs(expected-R.Signals.Motors.LossPower_kW))<1e-9);
assert(any(R.Signals.Motors.LossPower_kW>0));
text=sprintf('%d motor loss maps validated; peak pair loss %.3f kW', ...
    numel(DB.Motor_Maps),max(R.Signals.Motors.LossPower_kW));
end

function text=testComponentExtension(DB,~)
root=string(tempname); mkdir(root); cleanup=onCleanup(@()rmdir(root,'s'));
batteryFolder=fullfile(root,'batteries'); motorFolder=fullfile(root,'motors');
gensetFolder=fullfile(root,'gensets'); mkdir(batteryFolder); mkdir(motorFolder); mkdir(gensetFolder);
batterySource=DB.BatteryFiles(string(DB.Battery_Catalog.ComponentID)=="BAT-12");
motorSource=DB.MotorFiles(string(DB.Motor_Catalog.ComponentID)=="MOT-12");
gensetSource=DB.GensetFiles(string(DB.Genset_Catalog.ComponentID)=="GEN-12");
assert(isscalar(batterySource) && isscalar(motorSource) && isscalar(gensetSource));
cloneComponentScript(batterySource,fullfile(batteryFolder,'user_battery.m'), ...
    ["BAT-12","Bat_Series_1"]);
cloneComponentScript(motorSource,fullfile(motorFolder,'user_motor.m'), ...
    ["MOT-12","Motor_HighTorque_A"]);
cloneComponentScript(gensetSource,fullfile(gensetFolder,'user_genset.m'), ...
    ["GEN-12","Gen_Euro7_300kW";"ENG-12","Diesel_Engine_A"; ...
    "GNR-12","Generator_800V_A"]);
B=load_component_m_files(batteryFolder,"Battery");
M=load_component_m_files(motorFolder,"Motor"); G=load_genset_m_files(gensetFolder);
custom=DB; custom.BatteryFiles=B.Files; custom.Battery_Catalog=B.Catalog;
custom.Battery_Maps=B.Maps; custom.MotorFiles=M.Files; custom.Motor_Catalog=M.Catalog;
custom.Motor_Maps=M.Maps;
custom.GensetFiles=G.Files; custom.Genset_Catalog=G.GensetCatalog;
custom.Engine_Catalog=G.EngineCatalog; custom.Generator_Catalog=G.GeneratorCatalog;
custom.Genset_Assembly=G.AssemblyCatalog; custom.Engine_Fuel_Map=G.EngineFuelMap;
custom.Generator_Efficiency_Map=G.GeneratorEfficiencyMap;
V=validate_hybrid_bus_database(custom); assert(V.IsValid);
I=prepare_hybrid_bus_inputs(custom,struct('SelectedBattery1',"Bat_Series_1", ...
    'SelectedBattery2',"Bat_Series_1",'SelectedMotor',"Motor_HighTorque_A", ...
    'SelectedGenset',"Gen_Euro7_300kW"));
R=simulate_hybrid_bus_core(I);
assert(string(R.SelectedConfiguration.Battery1)=="Bat_Series_1" && ...
    string(R.SelectedConfiguration.Motor)=="Motor_HighTorque_A" && ...
    string(R.SelectedConfiguration.Genset)=="Gen_Euro7_300kW");
clear cleanup
text='custom battery, motor, and independent genset assembly IDs completed simulation';
end

function cloneComponentScript(source,destination,replacements)
lines=readlines(source); lines=lines(~contains(lines,'.StorageOrder='));
for index=1:size(replacements,1)
    lines=replace(lines,replacements(index,1),replacements(index,2));
end
writelines(lines,destination);
end

function text=testStationaryAux(DB,~)
I=baseInput(DB); I=setRoute(I,(0:100)',zeros(101,1),zeros(101,1)); R=simulate_hybrid_bus_core(I);
expected=sum(R.Signals.Battery1.Power_kW(1:end-1))/I.Battery1.DischargeEfficiency/3600;
actual=R.Signals.Battery1.Energy_kWh(1)-R.Signals.Battery1.Energy_kWh(end);
assert(all(R.Signals.Auxiliary.Power_kW>0) && abs(actual-expected)<1e-9);
text=sprintf('battery delta %.6f kWh',actual);
end

function text=testAcceleration(DB,~)
I=baseInput(DB); t=(0:40)'; I=setRoute(I,t,min(50,t*2),zeros(size(t))); R=simulate_hybrid_bus_core(I);
assert(max(R.Signals.Wheel.Demand_kW)>50); text=sprintf('peak %.1f kW',max(R.Signals.Wheel.Demand_kW));
end

function text=testPositiveGrade(DB,~)
I=baseInput(DB); t=(0:60)'; I=setRoute(I,t,36*ones(size(t)),zeros(size(t))); A=simulate_hybrid_bus_core(I);
I=setRoute(I,t,36*ones(size(t)),5*ones(size(t))); B=simulate_hybrid_bus_core(I);
assert(mean(B.Signals.Wheel.Demand_kW)>mean(A.Signals.Wheel.Demand_kW)); text='grade demand increased';
end

function text=testRegeneration(DB,~)
I=baseInput(DB); t=(0:60)'; I=setRoute(I,t,36*ones(size(t)),-8*ones(size(t))); R=simulate_hybrid_bus_core(I);
assert(any(R.Signals.Motors.ElectricalPower_kW<0)); text=sprintf('regen %.2f kWh',R.Summary.RegeneratedEnergy_kWh);
end

function text=testPneumaticBrakeBlending(DB,~)
I=baseInput(DB); t=(0:10)';
% Use a deliberately severe stop so the required wheel-braking power is
% above the selected motor pair's regenerative capability. This keeps the
% test valid when a higher-power motor variant becomes the dashboard default.
I=setRoute(I,t,linspace(160,0,numel(t))',zeros(size(t)));
R=simulate_hybrid_bus_core(I); W=R.Signals.Wheel;
braking=W.BrakingDemand_kW>1e-9;
balance=W.BrakingDemand_kW-W.RegenerativeBraking_kW- ...
    W.FrictionBrakePower_kW-W.UnmetBraking_kW;
assert(any(braking) && any(W.FrictionBrakePower_kW>1e-6));
assert(max(abs(balance))<1e-9);
assert(all(W.FrictionBrakePower_kW(~braking)==0));
assert(all(W.FrictionBrakePower_kW>=0) && all(W.UnmetBraking_kW>=0));
expected=sum(W.FrictionBrakePower_kW.*[diff(R.Time);0])/3600;
assert(abs(expected-R.Summary.FrictionBrakeEnergy_kWh)<1e-12);
assert(R.Summary.UnmetBrakingEnergy_kWh<1e-12);
text=sprintf('friction %.3f kWh; peak %.1f kW; braking balance closed', ...
    R.Summary.FrictionBrakeEnergy_kWh,max(W.FrictionBrakePower_kW));
end

function text=testRegenerationPriority(DB,~)
I=baseInput(DB); t=(0:60)'; I=setRoute(I,t,36*ones(size(t)),-10*ones(size(t)));
I.InitialBattery1SOE=0.70; I.InitialBattery2SOE=0.70; I.InitialActiveBattery=1;
R=simulate_hybrid_bus_core(I); G=R.Signals.Regeneration;
assert(max(abs(G.ToAuxiliary_kW-min(G.Available_kW,R.Signals.Auxiliary.Power_kW)))<1e-12);
assert(any(G.ToActiveBattery_kW>0) && all(G.ResistorLoadBank_kW<1e-12));

I.InitialBattery1SOE=I.Battery1.MaxSOE; R=simulate_hybrid_bus_core(I); G=R.Signals.Regeneration;
assert(all(R.Signals.Controller.ActiveBattery==1) && any(G.Available_kW>G.ToAuxiliary_kW));
assert(all(G.ToActiveBattery_kW<1e-12) && any(G.ResistorLoadBank_kW>0));
allocationError=G.Available_kW-G.ToAuxiliary_kW-G.ToActiveBattery_kW-G.ResistorLoadBank_kW;
assert(max(abs(allocationError))<1e-9);
text=sprintf('auxiliary first; %.3f kWh diverted to resistor bank at full active SOE', ...
    R.Summary.ResistorLoadBankEnergy_kWh);
end

function text=testSwitching(DB,~)
I=baseInput(DB); I.InitialBattery1SOE=0.299; I.InitialBattery2SOE=0.8;
R=simulate_hybrid_bus_core(I);
assert(R.Signals.Controller.ActiveBattery(1)==2 && ...
    all(R.Signals.Controller.BatteryRoleSwitchSOE==0.30));
text='battery 2 became active immediately below 30%';
end

function text=testStandbyCharge(DB,~)
I=baseInput(DB); I=setRoute(I,(0:150)',zeros(151,1),zeros(151,1));
I.InitialBattery1SOE=0.8; I.InitialBattery2SOE=0.2; R=simulate_hybrid_bus_core(I);
on=R.Signals.Genset.On;
assert(any(on) && all(R.Signals.Genset.ChargeDestinationBattery(on)==2));
assert(any(R.Signals.Battery1.Power_kW(on)>0) && any(R.Signals.Battery2.Power_kW(on)<0) && ...
    R.Summary.Fuel_L>0);
fuelCheck=sum(R.Signals.Genset.FuelRate_L_s(1:end-1)); assert(abs(fuelCheck-R.Summary.Fuel_L)<1e-12);
text=sprintf('B1 supplied auxiliaries while genset charged B2; fuel %.4f L',R.Summary.Fuel_L);
end

function text=testGensetIsolation(DB,~)
I=baseInput(DB); I=setRoute(I,(0:40)',50*ones(41,1),zeros(41,1));
I.InitialBattery1SOE=0.8; I.InitialBattery2SOE=0.2;
withGenset=simulate_hybrid_bus_core(I);
I.Genset.MaxPower_kW=0; withoutGenset=simulate_hybrid_bus_core(I);
assert(any(withGenset.Signals.Genset.On) && ...
    max(abs(withGenset.Signals.Battery1.Power_kW-withoutGenset.Signals.Battery1.Power_kW))<1e-12);
text='active-battery traction power is identical with genset enabled and disabled';
end

function text=testGensetHysteresis(DB,~)
I=baseInput(DB); I.InitialBattery1SOE=0.2; I.InitialBattery2SOE=0.2; R=simulate_hybrid_bus_core(I);
transitionIndex=find(abs(diff(double(R.Signals.Genset.On)))>0)+1;
transitions=numel(transitionIndex);
assert(R.Summary.GensetStarts>=1 && transitions<=2*R.Summary.GensetStarts && ...
    (numel(transitionIndex)<2 || all(diff(R.Time(transitionIndex))>= ...
    min(I.Genset.MinOnTime_s,I.Genset.MinOffTime_s)-I.Vehicle.SampleTime_s)));
text=sprintf('%d deliberate start(s), %d well-spaced transition(s)',R.Summary.GensetStarts,transitions);
end

function text=testUpperLimit(DB,~)
I=baseInput(DB); I.InitialBattery1SOE=I.Battery1.MaxSOE-1e-4; I.InitialBattery2SOE=I.Battery2.MaxSOE-1e-4;
I=setRoute(I,(0:100)',36*ones(101,1),-10*ones(101,1)); R=simulate_hybrid_bus_core(I);
assert(max(R.Signals.Battery1.SOE)<=I.Battery1.MaxSOE+eps && max(R.Signals.Battery2.SOE)<=I.Battery2.MaxSOE+eps);
text='upper SOE limits respected';
end

function text=testLowerLimit(DB,~)
I=baseInput(DB); I.InitialBattery1SOE=I.Battery1.MinSOE+1e-5; I.InitialBattery2SOE=I.Battery2.MinSOE+1e-5;
I.Genset.MaxPower_kW=0; I.Control.GensetStartSOE=0; I=setRoute(I,(0:50)',50*ones(51,1),5*ones(51,1)); R=simulate_hybrid_bus_core(I);
assert(min(R.Signals.Battery1.SOE)>=I.Battery1.MinSOE-eps && R.Summary.UnmetTractionEnergy_kWh>0); text='lower limit clamped with unmet power';
end

function text=testMotorSaturation(DB,~)
I=baseInput(DB); I.Motor.PeakPower_kW=10; I.Motor.PeakTorque_Nm=100; t=(0:30)'; I=setRoute(I,t,2*t,zeros(size(t))); R=simulate_hybrid_bus_core(I);
assert(any(R.Signals.Wheel.UnmetTraction_kW>0)); text=sprintf('unmet %.3f kWh',R.Summary.UnmetTractionEnergy_kWh);
end

function text=testGensetBestPoint(DB,~)
I=baseInput(DB); I.InitialBattery1SOE=0.8; I.InitialBattery2SOE=0.2; R=simulate_hybrid_bus_core(I);
power=R.Signals.Genset.ElectricalPower_kW(R.Signals.Genset.On);
expected=min(I.Genset.OptimumPower_kW,I.Genset.MaxPower_kW);
assert(~isempty(power) && max(abs(power-expected))<1e-12);
text=sprintf('constant at %.1f kW',expected);
end

function text=testRouteFailure(DB,~)
longRoutes=DB.Route_Catalog(DB.Route_Catalog.RouteType=="Long-distance coach",:);
assert(height(longRoutes)==8 && all(longRoutes.Distance_km>=600 & longRoutes.Distance_km<=1000));
for routeID=longRoutes.RouteID'
    R=DB.Route_Time_Speed(DB.Route_Time_Speed.RouteID==routeID,:);
    assert(all(isfinite(R.Time_s)) && all(diff(R.Time_s)>0) && ...
        max(R.Speed_kmh)<=100+eps && any(R.StopFlag));
end
DB.Route_Time_Speed.Time_s(2)=DB.Route_Time_Speed.Time_s(1); V=validate_hybrid_bus_database(DB);
assert(~V.IsValid && any(contains(V.Errors,'non-monotonic'))); text='duplicate time rejected';
end

function text=testIncompatible(~,file)
O=optimize_hybrid_bus_configuration(string(file),Vary="Battery1",MaxConfigurations=12,SaveResults=false);
assert(any(contains(O.EvaluatedConfigurations.RejectionReason,'voltage'))); text='voltage mismatch recorded';
end

function text=testEnergyBalance(DB,~)
R=simulate_hybrid_bus_core(baseInput(DB)); assert(R.Summary.EnergyBalanceError_kWh<1e-9); text='residual < 1e-9 kWh';
end

function text=testRepeatability(DB,~)
I=baseInput(DB); A=simulate_hybrid_bus_core(I); B=simulate_hybrid_bus_core(I);
assert(isequal(A.Summary.CostPer_km,B.Summary.CostPer_km)); text='bitwise-identical cost KPI';
end

function text=testZeroSpeed(DB,~)
I=baseInput(DB); I=setRoute(I,(0:20)',zeros(21,1),zeros(21,1)); R=simulate_hybrid_bus_core(I);
assert(all(isfinite(R.Signals.Motors.MotorSpeed_rpm)) && all(isfinite(R.Signals.Wheel.Demand_kW))); text='all signals finite';
end

function text=testComponentPhysicalSignals(DB,~)
for mode=["Hybrid","BEV"]
    I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',mode, ...
        'BatterySetMultiplier',1,'InitialBattery1SOE',0.85,'InitialBattery2SOE',0.85));
    R=simulate_hybrid_bus_core(I); S=R.Signals;
    assert(isequal(S.Vehicle.Distance_m(:),R.Route.Distance_m(:)));
    assert(all(isfinite(S.Motors.PairTorque_Nm)) && ...
        all(S.Motors.DrivingPowerLimit_kW>=0) && all(S.Motors.RegenerationPowerLimit_kW>=0));
    rotating=abs(S.Motors.MotorSpeed_rpm)>1e-9;
    omega=S.Motors.MotorSpeed_rpm*2*pi/60;
    assert(max(abs(S.Motors.MechanicalPower_kW(rotating)- ...
        S.Motors.PairTorque_Nm(rotating).*omega(rotating)/1000))<1e-9);
    for batteryName=["Battery1","Battery2"]
        B=S.(batteryName);
        assert(all(isfinite(B.Voltage_V)) && all(isfinite(B.Current_A)));
        assert(max(abs(B.Power_kW-B.Voltage_V.*B.Current_A/1000))<1e-9);
        assert(all(max(B.Current_A,0)<=B.DischargeCurrentLimit_A+1e-9));
        assert(all(max(-B.Current_A,0)<=B.ChargeCurrentLimit_A+1e-9));
    end
    assert(max(abs(S.DCBus.NetPower_kW-S.DCBus.Voltage_V.*S.DCBus.Current_A/1000))<1e-9);
end
text='Hybrid and BEV component signal identities close';
end

function text=testCostCorrection(DB,~)
R=simulate_hybrid_bus_core(baseInput(DB)); expected=(max(0,R.Signals.Battery1.Energy_kWh(1)-R.Signals.Battery1.Energy_kWh(end))+ ...
    max(0,R.Signals.Battery2.Energy_kWh(1)-R.Signals.Battery2.Energy_kWh(end)))/R.InputParameters.Vehicle.GridChargeEfficiency;
assert(abs(expected-R.Summary.GridEquivalentEnergy_kWh)<1e-12); text=sprintf('grid correction %.4f kWh',expected);
end

function text=testChargeSustaining(DB,~)
R=simulate_hybrid_bus_core(baseInput(DB)); C=evaluate_hybrid_bus_comparison(R,"ChargeSustaining",1e-6);
assert(C.TerminalSOECompliant==(abs(C.TerminalSOEDeviation)<=1e-6)); text=sprintf('deviation %.6f',C.TerminalSOEDeviation);
end

function text=testOptimizationRanking(~,file)
O=optimize_hybrid_bus_configuration(string(file),Vary="Motor",MaxConfigurations=12, ...
    BaseOverrides=struct('SelectedRoute',"DE-MAN-CITY",'SelectedBattery1',"BAT-12", ...
    'SelectedBattery2',"BAT-12",'SelectedFinalDrive',"FD-08"),SaveResults=false);
cost=O.TopConfigurations.CostPer_km; assert(~isempty(cost) && all(diff(cost)>=0)); text=sprintf('%d ranked feasible cases',height(O.TopConfigurations));
end

function text=testForwardFlatRoute(DB,~)
I=forwardInput(DB,"BEV");
I=setRoute(I,(0:60)',36*ones(61,1),zeros(61,1));
R=simulate_hybrid_bus(I);
assert(R.Summary.RouteCompleted && R.Summary.RouteCompletion_pct>=99.5);
assert(all(R.Signals.Vehicle.Speed_m_s>=0) && all(diff(R.Signals.Vehicle.Distance_m)>=-1e-12));
assert(any(R.Signals.Vehicle.Speed_m_s>0) && R.Summary.EnergyBalanceError_kWh<1e-8);
assert(strcmp(R.Summary.SimulationFormulation,'ForwardPerformance'));
text=sprintf('completed %.3f km in %.1f s; max speed %.1f km/h', ...
    R.Summary.RouteDistance_km,R.Summary.ActualCompletionTime_s, ...
    R.Summary.MaximumAchievedSpeed_kmh);
end

function text=testForwardSevereGradeStall(DB,~)
I=forwardInput(DB,"BEV");
I=setRoute(I,(0:60)',36*ones(61,1),60*ones(61,1));
I.Motor.PeakTorque_Nm=50; I.Motor.PeakPower_kW=5;
I.Performance.StallDetectionTime_s=5;
R=simulate_hybrid_bus(I);
assert(~R.Summary.RouteCompleted && R.Summary.RouteCompletion_pct<1);
assert(contains(R.Summary.TerminationReason,'stalled','IgnoreCase',true));
assert(all(R.Signals.Vehicle.Speed_m_s>=0) && all(diff(R.Signals.Vehicle.Distance_m)>=-1e-12));
assert(R.Signals.Vehicle.Distance_m(end)>=0);
text=sprintf('%s; completion %.2f%%',R.Summary.TerminationReason,R.Summary.RouteCompletion_pct);
end

function text=testForwardDistanceIndexedGrade(DB,~)
I=forwardInput(DB,"BEV"); t=(0:200)'; grade=zeros(size(t)); grade(t>=100)=8;
I=setRoute(I,t,18*ones(size(t)),grade);
R=simulate_hybrid_bus(I);
transition=find(R.Signals.Vehicle.Grade_pct>=4,1,'first');
assert(~isempty(transition)); transitionDistance=R.Signals.Vehicle.Distance_m(transition);
assert(abs(transitionDistance-500)<12);
assert(R.Time(transition)>95);
text=sprintf('4%% grade crossing occurred at %.1f m and %.1f s', ...
    transitionDistance,R.Time(transition));
end

function text=testForwardPowertrainModes(DB,~)
details=strings(2,1); modes=["BEV","Hybrid"];
for index=1:2
    I=forwardInput(DB,modes(index));
    I=setRoute(I,(0:40)',25*ones(41,1),zeros(41,1));
    R=simulate_hybrid_bus(I);
    assert(R.Summary.RouteCompleted && R.Summary.EnergyBalanceError_kWh<1e-8);
    assert(strcmpi(R.Summary.PowertrainMode,modes(index)));
    if modes(index)=="BEV", assert(R.Summary.Fuel_L==0); end
    details(index)=sprintf('%s %.1f%%',modes(index),R.Summary.RouteCompletion_pct);
end
text=strjoin(details,', ');
end

function text=testFormulationDispatcher(DB,~)
I=baseInput(DB); I=setRoute(I,(0:40)',30*ones(41,1),zeros(41,1));
direct=simulate_hybrid_bus_core(I); dispatched=simulate_hybrid_bus(I);
assert(isequaln(direct.Summary.CostPer_km,dispatched.Summary.CostPer_km));
assert(isequaln(direct.Signals.Vehicle.Speed_m_s,dispatched.Signals.Vehicle.Speed_m_s));
assert(strcmp(dispatched.Summary.SimulationFormulation,'BackwardDemand'));
text='legacy backward-demand result preserved exactly';
end

function text=testForwardSimulinkStructure(~,databaseFile)
model='HybridBus_PerformanceModel'; load_system(model); cleanup=onCleanup(@()close_system(model,0));
[~,variables]=assign_hybrid_bus_model_workspace(string(databaseFile),struct( ...
    'SimulationFormulation',"ForwardPerformance",'SelectedRoute',"DE-MAN-CITY"));
variableNames=fieldnames(variables);
for index=1:numel(variableNames)
    assignin('base',variableNames{index},variables.(variableNames{index}));
end
variableCleanup=onCleanup(@()clearBaseVariables(variableNames));
required=["Route_Target_and_Terrain","Driver_and_Force_Demand", ...
    "Component_Force_Limits","Forward_Vehicle_Plant"];
blocks=string(get_param(find_system(model,'SearchDepth',1,'BlockType','SubSystem'),'Name'));
assert(all(ismember(required,blocks)));
set_param(model,'SimulationCommand','update');
for block=required
    docs=find_system(string(model)+"/"+block,'LookUnderMasks','all','MaskType','DocBlock');
    assert(~isempty(docs));
end
clear variableCleanup cleanup
text='four documented feature subsystems compile successfully';
end

function text=testConstrainedAccelerationSuppression(DB,~)
t=(0:60)'; target=36*ones(size(t)); grade=zeros(size(t));
capable=constrainedInput(DB,"BEV"); capable=setRoute(capable,t,target,grade);
capableResult=simulate_hybrid_bus(capable);
limited=capable; limited.Motor.PeakTorque_Nm=50; limited.Motor.PeakPower_kW=5;
limited.Battery1.MaxDischargeCurrentMap_A(:)=5;
limited.Battery2.MaxDischargeCurrentMap_A(:)=5;
limitedResult=simulate_hybrid_bus(limited);
assert(max(limitedResult.Signals.Vehicle.Speed_m_s)< ...
    max(capableResult.Signals.Vehicle.Speed_m_s));
assert(any(limitedResult.Signals.Vehicle.SpeedError_m_s>1));
assert(all(limitedResult.Signals.Vehicle.Speed_m_s>=0) && ...
    all(diff(limitedResult.Signals.Vehicle.Distance_m)>=-1e-12));
assert(any(contains(limitedResult.Signals.Vehicle.LimitingCause, ...
    ["Battery","Motor"]),'all'));
text=sprintf('capable %.1f km/h; limited %.1f km/h', ...
    capableResult.Summary.MaximumAchievedSpeed_kmh, ...
    limitedResult.Summary.MaximumAchievedSpeed_kmh);
end

function text=testConstrainedEnergyDepletion(DB,~)
I=constrainedInput(DB,"BEV"); I.BatterySetMultiplier=0.5;
I.Battery2PackCount=0; I.TotalBatteryPackCount=1;
I.InitialBattery1SOE=I.Battery1.MinSOE;
t=(0:120)'; I=setRoute(I,t,36*ones(size(t)),zeros(size(t)));
R=simulate_hybrid_bus(I);
assert(max(R.Signals.Vehicle.Speed_m_s)<=I.Performance.ZeroSpeedThreshold_m_s);
assert(~R.Summary.RouteCompleted && contains(R.Summary.TerminationReason,'stopped','IgnoreCase',true));
assert(all(diff(R.Signals.Vehicle.Distance_m)>=-1e-12));
assert(R.Summary.FinalBattery1SOE>=I.Battery1.MinSOE-1e-12);
text=sprintf('stopped at %.3f km with B1 SOE %.1f%%', ...
    R.Summary.RouteDistance_km,100*R.Summary.FinalBattery1SOE);
end

function text=testConstrainedDistanceTerrain(DB,~)
I=constrainedInput(DB,"BEV"); t=(0:200)'; grade=zeros(size(t)); grade(t>=100)=8;
I=setRoute(I,t,18*ones(size(t)),grade);
R=simulate_hybrid_bus(I);
transition=find(R.Signals.Vehicle.Grade_pct>=4,1,'first');
assert(~isempty(transition)); transitionDistance=R.Signals.Vehicle.Distance_m(transition);
assert(abs(transitionDistance-500)<12 && R.Time(transition)>95);
text=sprintf('terrain transition %.1f m at %.1f s',transitionDistance,R.Time(transition));
end

function text=testConstrainedPowertrainModes(DB,~)
modes=["BEV","Hybrid"]; details=strings(2,1);
for index=1:2
    I=constrainedInput(DB,modes(index));
    I=setRoute(I,(0:40)',25*ones(41,1),zeros(41,1));
    R=simulate_hybrid_bus(I);
    assert(strcmp(R.Summary.SimulationFormulation,'ConstrainedBackward'));
    assert(strcmpi(R.Summary.PowertrainMode,modes(index)));
    assert(R.Summary.EnergyBalanceError_kWh<1e-8);
    if modes(index)=="BEV", assert(R.Summary.Fuel_L==0); end
    details(index)=sprintf('%s %.1f%%',modes(index),R.Summary.RouteCompletion_pct);
end
text=strjoin(details,', ');
end

function text=testConstrainedFixedHorizon(DB,~)
I=prepare_hybrid_bus_inputs(DB,struct('SimulationFormulation',"ConstrainedBackward", ...
    'RepeatUntilDepleted',true));
assert(~I.RepeatUntilDepleted);
R=simulate_hybrid_bus(I);
assert(numel(R.Time)==height(I.Route));
assert(R.Summary.ActualCompletionTime_s==I.Route.Time_s(end)-I.Route.Time_s(1));
text=sprintf('%d samples; one %.1f min route-time pass', ...
    numel(R.Time),R.Summary.ActualCompletionTime_s/60);
end

function text=testBEVDualBattery(DB,~)
I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"BEV", ...
    'BatterySetMultiplier',1,'InitialBattery1SOE',0.85,'InitialBattery2SOE',0.20));
R=simulate_hybrid_bus_core(I);
assert(I.InitialBattery1SOE==0.85 && I.InitialBattery2SOE==0.85);
assert(R.Summary.Fuel_L==0 && all(R.Signals.Genset.ElectricalPower_kW==0));
assert(any(R.Signals.Battery1.Power_kW~=0) && any(R.Signals.Battery2.Power_kW~=0));
assert(all(R.Signals.Controller.ConnectedBatteryCount==2));
assert(R.Summary.EnergyBalanceError_kWh<1e-9);
text=sprintf('two packs connected; final SOE %.3f / %.3f', ...
    R.Summary.FinalBattery1SOE,R.Summary.FinalBattery2SOE);
end

function text=testBEVSingleBattery(DB,~)
I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"BEV", ...
    'BatterySetMultiplier',0.5,'InitialBattery1SOE',0.85));
R=simulate_hybrid_bus_core(I);
assert(all(R.Signals.Battery2.Power_kW==0));
assert(max(R.Signals.Battery2.Energy_kWh)-min(R.Signals.Battery2.Energy_kWh)==0);
assert(all(R.Signals.Battery2.Voltage_V==0) && all(R.Signals.Battery2.Current_A==0));
assert(all(R.Signals.Battery2.DischargeCurrentLimit_A==0) && ...
    all(R.Signals.Battery2.ChargeCurrentLimit_A==0));
assert(all(R.Signals.Controller.ConnectedBatteryCount==1) && R.Summary.Fuel_L==0);
text='Battery 1 supplied the mission; Battery 2 remained disconnected';
end

function text=testHybridDoubleBatterySet(DB,~)
single=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"Hybrid", ...
    'BatterySetMultiplier',1));
doubleSet=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"Hybrid", ...
    'BatterySetMultiplier',2));
assert(doubleSet.Battery1PackCount==2 && doubleSet.Battery2PackCount==2);
assert(doubleSet.TotalBatteryPackCount==4);
assert(abs(doubleSet.Battery1.UsableEnergy_kWh-2*single.Battery1.UsableEnergy_kWh)<1e-12);
assert(abs(doubleSet.Battery2.ReferenceDischargeCurrent_A- ...
    2*single.Battery2.ReferenceDischargeCurrent_A)<1e-12);
text='two-pack active and standby banks; energy and current capability doubled';
end

function text=testBEVThreeBatterySet(DB,~)
I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"BEV", ...
    'BatterySetMultiplier',1.5,'InitialBattery1SOE',0.85));
assert(I.Battery1PackCount==2 && I.Battery2PackCount==1 && I.TotalBatteryPackCount==3);
R=simulate_hybrid_bus_core(I);
assert(all(R.Signals.Controller.ConnectedBatteryCount==3));
assert(R.Summary.ConnectedBatteryCount==3 && R.Summary.BatterySetMultiplier==1.5);
text='Battery 1 x2 plus Battery 2 x1 connected in parallel';
end

function text=testBatterySetValidation(DB,~)
hybridRejected=false; bevRejected=false;
try
    prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"Hybrid",'BatterySetMultiplier',1.5));
catch exception
    hybridRejected=strcmp(exception.identifier,'HybridBus:InvalidHybridBatterySetMultiplier');
end
try
    prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"BEV",'BatterySetMultiplier',1.25));
catch exception
    bevRejected=strcmp(exception.identifier,'HybridBus:InvalidBEVBatterySetMultiplier');
end
assert(hybridRejected && bevRejected);
text='Hybrid fractional and BEV quarter-set inputs rejected';
end

function text=testHybridCalculatedMass(DB,~)
I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"Hybrid", ...
    'BatterySetMultiplier',2,'LoadMass_t',5));
expected=15000+2*I.BaseBattery1.Mass_kg+2*I.BaseBattery2.Mass_kg+ ...
    I.Genset.Mass_kg+5000;
assert(abs(I.Mass.CurbMass_kg-(expected-5000))<1e-9);
assert(abs(I.Mass.TotalVehicleMass_kg-expected)<1e-9);
R=simulate_hybrid_bus_core(I);
assert(abs(R.Summary.EstimatedVehicleMass_kg-expected)<1e-9);
text=sprintf('Hybrid curb %.3f t; total %.3f t',I.Mass.CurbMass_kg/1000,expected/1000);
end

function text=testBEVCalculatedMass(DB,~)
I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"BEV", ...
    'BatterySetMultiplier',1.5,'LoadMass_t',3));
expected=15000+2*I.BaseBattery1.Mass_kg+I.BaseBattery2.Mass_kg+3000;
assert(I.Mass.GensetMass_kg==0);
assert(abs(I.Mass.TotalVehicleMass_kg-expected)<1e-9);
[~,variables]=assign_hybrid_bus_model_workspace(DB.Filename,struct( ...
    'PowertrainMode',"BEV",'BatterySetMultiplier',1.5,'LoadMass_t',3));
assert(abs(variables.vehicle_mass_kg-expected)<1e-9);
text=sprintf('BEV curb %.3f t; total %.3f t; genset excluded', ...
    I.Mass.CurbMass_kg/1000,expected/1000);
end

function text=testBEVRegeneration(DB,~)
I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',"BEV", ...
    'BatterySetMultiplier',1,'InitialBattery1SOE',0.70));
t=(0:60)'; I=setRoute(I,t,36*ones(size(t)),-10*ones(size(t)));
R=simulate_hybrid_bus_core(I); G=R.Signals.Regeneration;
allocationError=G.Available_kW-G.ToAuxiliary_kW-G.ToActiveBattery_kW-G.ResistorLoadBank_kW;
assert(max(abs(allocationError))<1e-9 && any(G.ToActiveBattery_kW>0));
I.InitialBattery1SOE=I.Battery1.MaxSOE; I.InitialBattery2SOE=I.Battery2.MaxSOE;
R=simulate_hybrid_bus_core(I);
assert(any(R.Signals.Regeneration.ResistorLoadBank_kW>0));
text='auxiliary > parallel packs > resistor allocation conserved';
end

function text=testGensetMFileStorage(DB,databaseFile)
sheets=sheetnames(databaseFile);
assert(~any(ismember(["Genset_Catalog","Engine_Catalog","Generator_Catalog", ...
    "Engine_Fuel_Map","Generator_Efficiency_Map"],sheets)));
assert(numel(DB.GensetFiles)==height(DB.Genset_Catalog) && all(isfile(DB.GensetFiles)));
GensetData=[]; run(DB.GensetFiles(1));
assert(GensetData.SchemaVersion=="1.0.0");
assert(all(isfield(GensetData,{'Genset','Engine','Generator', ...
    'EngineFuelMap','GeneratorEfficiencyMap'})));
suffix=extractAfter(string(GensetData.Genset.ComponentID),"-");
assert(string(GensetData.Engine.ComponentID)=="ENG-"+suffix && ...
    string(GensetData.Generator.ComponentID)=="GNR-"+suffix);
I=prepare_hybrid_bus_inputs(DB,struct('SelectedGenset',string(GensetData.Genset.ComponentID)));
assert(height(I.FuelMap)==height(GensetData.EngineFuelMap) && ...
    height(I.GeneratorMap)==height(GensetData.GeneratorEfficiencyMap));
text=sprintf('%d complete genset assembly files with selected maps',numel(DB.GensetFiles));
end

function text=testBatteryDynamicMaps(DB,~)
warm=prepare_hybrid_bus_inputs(DB,struct('SelectedEnvironment',"ENV-08", ...
    'InitialBattery1SOE',0.50,'InitialBattery2SOE',0.50));
cold=prepare_hybrid_bus_inputs(DB,struct('SelectedEnvironment',"ENV-01", ...
    'InitialBattery1SOE',0.50,'InitialBattery2SOE',0.50));
nearFull=prepare_hybrid_bus_inputs(DB,struct('SelectedEnvironment',"ENV-08", ...
    'InitialBattery1SOE',0.94,'InitialBattery2SOE',0.94));
warmResult=simulate_hybrid_bus_core(warm); coldResult=simulate_hybrid_bus_core(cold);
fullResult=simulate_hybrid_bus_core(nearFull);
warmBattery=warmResult.Signals.Battery1; coldBattery=coldResult.Signals.Battery1;
assert(coldBattery.DischargeCurrentLimit_A(1)<warmBattery.DischargeCurrentLimit_A(1));
assert(coldBattery.InternalResistance_Ohm(1)>warmBattery.InternalResistance_Ohm(1));
assert(coldBattery.OpenCircuitVoltage_V(1)<warmBattery.OpenCircuitVoltage_V(1));
assert(fullResult.Signals.Battery1.ChargeCurrentLimit_A(1)< ...
    warmBattery.ChargeCurrentLimit_A(1));
assert(all(max(warmBattery.Current_A,0)<=warmBattery.DischargeCurrentLimit_A+1e-9));
assert(all(max(-warmBattery.Current_A,0)<=warmBattery.ChargeCurrentLimit_A+1e-9));
assert(max(abs(warmBattery.Power_kW-0.001*warmBattery.Voltage_V.* ...
    warmBattery.Current_A))<1e-8);
assert(max(abs(warmBattery.OhmicLoss_kW-0.001*warmBattery.Current_A.^2.* ...
    warmBattery.InternalResistance_Ohm))<1e-10);
highSOE=prepare_hybrid_bus_inputs(DB,struct('SelectedEnvironment',"ENV-08", ...
    'InitialBattery1SOE',0.85,'InitialBattery2SOE',0.85));
highSOEResult=simulate_hybrid_bus_core(highSOE);
assert(highSOEResult.Signals.Battery1.OpenCircuitVoltage_V(1)> ...
    warmBattery.OpenCircuitVoltage_V(1));
text=sprintf('25C %.1f A / %.4f ohm; -10C %.1f A / %.4f ohm', ...
    warmBattery.DischargeCurrentLimit_A(1),warmBattery.InternalResistance_Ohm(1), ...
    coldBattery.DischargeCurrentLimit_A(1),coldBattery.InternalResistance_Ohm(1));
end

function I=baseInput(DB)
I=prepare_hybrid_bus_inputs(DB);
end

function I=forwardInput(DB,mode)
I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',mode, ...
    'BatterySetMultiplier',1,'InitialBattery1SOE',0.85, ...
    'InitialBattery2SOE',0.85,'SimulationFormulation',"ForwardPerformance", ...
    'Performance',struct('MaximumDurationFactor',4,'MaximumExtraTime_s',180, ...
    'StallDetectionTime_s',15)));
end

function I=constrainedInput(DB,mode)
I=prepare_hybrid_bus_inputs(DB,struct('PowertrainMode',mode, ...
    'BatterySetMultiplier',1,'InitialBattery1SOE',0.85, ...
    'InitialBattery2SOE',0.85,'SimulationFormulation',"ConstrainedBackward", ...
    'Performance',struct('StallDetectionTime_s',15)));
end

function clearBaseVariables(variableNames)
for index=1:numel(variableNames)
    evalin('base',sprintf('clear(''%s'')',variableNames{index}));
end
end

function I=setRoute(I,t,speedKmh,grade)
t=t(:); speedKmh=speedKmh(:); grade=grade(:); n=numel(t);
I.Route=table(t,speedKmh,grade,false(n,1),ones(n,1), ...
    'VariableNames',{'Time_s','Speed_kmh','Grade_pct','StopFlag','AuxMultiplier'});
I.Route.Distance_m=cumtrapz(t,speedKmh/3.6); I.RouteDistance_km=I.Route.Distance_m(end)/1000;
end
