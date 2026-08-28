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
 'RouteValidationFailure','Duplicate route time is rejected',@testRouteFailure;
 'IncompatibleSelection','Compatibility filter records rejection reason',@testIncompatible;
 'EnergyConservation','Cumulative DC residual remains within tolerance',@testEnergyBalance;
 'Repeatability','Identical inputs produce identical scalar KPIs',@testRepeatability;
 'ZeroSpeedStability','Zero-speed calculation remains finite',@testZeroSpeed;
 'TerminalCostCorrection','Grid-equivalent terminal correction matches hand calculation',@testCostCorrection;
 'ChargeSustainingComparison','Terminal combined-SOE tolerance is enforced',@testChargeSustaining;
 'OptimizationRanking','Feasible configurations are sorted by total cost per kilometre',@testOptimizationRanking};
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
I=baseInput(DB); t=(0:20)';
I=setRoute(I,t,linspace(120,20,numel(t))',zeros(size(t)));
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
O=optimize_hybrid_bus_configuration(string(file),Vary="Motor",MaxConfigurations=7, ...
    BaseOverrides=struct('SelectedRoute',"DE-MAN-CITY",'SelectedBattery1',"BAT-04", ...
    'SelectedBattery2',"BAT-04",'SelectedFinalDrive',"FD-05"),SaveResults=false);
cost=O.TopConfigurations.CostPer_km; assert(~isempty(cost) && all(diff(cost)>=0)); text=sprintf('%d ranked feasible cases',height(O.TopConfigurations));
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
assert(abs(doubleSet.Battery2.MaxDischarge_kW-2*single.Battery2.MaxDischarge_kW)<1e-12);
text='two-pack active and standby banks; energy and power doubled';
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

function I=baseInput(DB)
I=prepare_hybrid_bus_inputs(DB);
end

function I=setRoute(I,t,speedKmh,grade)
t=t(:); speedKmh=speedKmh(:); grade=grade(:); n=numel(t);
I.Route=table(t,speedKmh,grade,false(n,1),ones(n,1), ...
    'VariableNames',{'Time_s','Speed_kmh','Grade_pct','StopFlag','AuxMultiplier'});
I.Route.Distance_m=cumtrapz(t,speedKmh/3.6); I.RouteDistance_km=I.Route.Distance_m(end)/1000;
end
