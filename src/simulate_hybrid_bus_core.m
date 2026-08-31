function Results = simulate_hybrid_bus_core(Input)
%SIMULATE_HYBRID_BUS_CORE Backward-facing dual-battery hybrid-bus model.
% Sign convention: positive DC battery power discharges a pack to the bus;
% negative battery power charges it. Positive wheel power is traction.

R = Input.Route; t = R.Time_s; n = height(R); dt = [diff(t); 0];
isBEV=isfield(Input,'PowertrainMode') && strcmpi(string(Input.PowertrainMode),"BEV");
if isfield(Input,'Battery2PackCount')
    useTwoBEVBatteries=isBEV && Input.Battery2PackCount>0;
else
    useTwoBEVBatteries=isBEV && isfield(Input,'BEVUseTwoBatteries') && ...
        logical(Input.BEVUseTwoBatteries);
end
v = R.Speed_kmh/3.6;
tau = max(Input.Vehicle.AccelerationFilterTau_s,eps);
aRaw = [0; diff(v)./diff(t)]; a = zeros(n,1);
for k=2:n, a(k)=a(k-1)+dt(k-1)/(tau+dt(k-1))*(aRaw(k)-a(k-1)); end

componentMass = Input.Battery1.Mass_kg + 2*Input.Motor.Mass_kg + 2*Input.FinalDrive.Mass_kg;
if ~isBEV || useTwoBEVBatteries, componentMass=componentMass+Input.Battery2.Mass_kg; end
if ~isBEV, componentMass=componentMass+Input.Genset.Mass_kg; end
if isfield(Input.Mass,'TotalVehicleMass_kg')
    mass = Input.Mass.TotalVehicleMass_kg;
else
    mass = Input.Mass.CurbMass_kg + Input.Mass.PassengerCount*Input.Mass.PassengerMass_kg + ...
        Input.Mass.CargoMass_kg + componentMass;
end
theta = atan(R.Grade_pct/100);
vAir = max(0,v + Input.Environment.Headwind_m_s);
FInertia = mass*a;
FRoll = mass*Input.Vehicle.Gravity_m_s2*Input.Tyre.RollingResistanceCoefficient.*cos(theta);
FGrade = mass*Input.Vehicle.Gravity_m_s2*sin(theta);
FAero = 0.5*Input.Environment.AirDensity_kg_m3*Input.Vehicle.DragCoefficient* ...
    Input.Vehicle.FrontalArea_m2.*vAir.^2;
FTractive = FInertia+FRoll+FGrade+FAero;
PWheelDemand = FTractive.*v/1000;

wWheel = v/max(Input.Tyre.LoadedRadius_m,0.1);
wMotor = Input.FinalDrive.Ratio*wWheel;
rpmMotor = wMotor*60/(2*pi);
torqueEnvelope = Input.Motor.PeakTorque_Nm*ones(n,1);
aboveBase = rpmMotor>Input.Motor.BaseSpeed_rpm;
torqueEnvelope(aboveBase) = min(torqueEnvelope(aboveBase), ...
    Input.Motor.PeakPower_kW*1000./max(wMotor(aboveBase),1));
perMotorMechLimit = min(Input.Motor.PeakPower_kW,torqueEnvelope.*wMotor/1000);
perMotorMechLimit(rpmMotor>Input.Motor.MaxSpeed_rpm) = 0;
tractionLimit = 2*perMotorMechLimit*Input.FinalDrive.MotoringEfficiency;
regenLimit = 2*perMotorMechLimit*Input.FinalDrive.RegenEfficiency;
PWheelDelivered = min(max(PWheelDemand,-regenLimit),tractionLimit);
motorMechanicalPower=zeros(size(PWheelDelivered));
motoring=PWheelDelivered>=0;
motorMechanicalPower(motoring)=PWheelDelivered(motoring)./ ...
    max(Input.FinalDrive.MotoringEfficiency,eps);
motorMechanicalPower(~motoring)=PWheelDelivered(~motoring).* ...
    Input.FinalDrive.RegenEfficiency;
motorPairTorque=zeros(size(wMotor)); rotating=abs(wMotor)>1e-9;
motorPairTorque(rotating)=1000*motorMechanicalPower(rotating)./wMotor(rotating);
mapTorque=min(max(abs(motorPairTorque)/2,Input.Motor.TorqueBreakpoints_Nm(1)), ...
    Input.Motor.TorqueBreakpoints_Nm(end));
mapSpeed=min(max(abs(rpmMotor),Input.Motor.SpeedBreakpoints_rpm(1)), ...
    Input.Motor.SpeedBreakpoints_rpm(end));
mappedPairMotorLoss=2*interp2(Input.Motor.TorqueBreakpoints_Nm, ...
    Input.Motor.SpeedBreakpoints_rpm,Input.Motor.MotorLossMap_kW, ...
    mapTorque,mapSpeed,'linear');
PMotorDC=zeros(n,1);
PMotorDC(motoring)=motorMechanicalPower(motoring)+mappedPairMotorLoss(motoring);
PMotorDC(~motoring)=min(0,motorMechanicalPower(~motoring)+mappedPairMotorLoss(~motoring));
motorLossPower=abs(PMotorDC-motorMechanicalPower);
unmetTraction = max(0,PWheelDemand-PWheelDelivered);
brakingDemand=max(0,-PWheelDemand);
regenerativeWheelBraking=max(0,-PWheelDelivered);
% Backward-model blended braking: regeneration is used first and the
% pneumatic/friction system supplies the remaining prescribed wheel demand.
% The friction actuator is ideal at this concept level; pressure dynamics,
% tyre adhesion, fade, wear, and brake temperature are not represented.
frictionBrakePower=max(0,brakingDemand-regenerativeWheelBraking);
totalWheelDelivered=PWheelDelivered-frictionBrakePower;
unmetBraking=max(0,brakingDemand-regenerativeWheelBraking-frictionBrakePower);
unmetRegen=frictionBrakePower; % Legacy alias: formerly the unserved regen remainder.
ambientDelta = abs(Input.Environment.Temperature_C-Input.Aux.ComfortTemperature_C);
hvacSlope = Input.Aux.HotHVAC_kW_per_C;
if Input.Environment.Temperature_C<Input.Aux.ComfortTemperature_C
    hvacSlope = Input.Aux.ColdHVAC_kW_per_C;
end
PAux = (Input.Aux.BasePower_kW+hvacSlope*ambientDelta).*R.AuxMultiplier* ...
    Input.AuxiliaryScalarOverride;
PNet = PMotorDC+PAux;

E1 = zeros(n,1); E2 = zeros(n,1);
E1(1)=Input.InitialBattery1SOE*Input.Battery1.UsableEnergy_kWh;
E2(1)=Input.InitialBattery2SOE*Input.Battery2.UsableEnergy_kWh;
batteryTemperature_C=Input.Environment.Temperature_C;
P1=zeros(n,1); P2=zeros(n,1); PGen=zeros(n,1); fuelRate=zeros(n,1);
mode=zeros(n,1); active=zeros(n,1); gensetOn=false(n,1); starts=false(n,1);
unmetDC=zeros(n,1); rejectedCharge=zeros(n,1); residual=zeros(n,1);
batteryLoss=zeros(n,1); genMechanical=zeros(n,1); gensetChargeDestination=zeros(n,1);
regenAvailable=max(0,-PMotorDC); regenToAuxiliary=min(regenAvailable,PAux);
regenAfterAuxiliary=max(0,regenAvailable-regenToAuxiliary);
regenToActiveBattery=zeros(n,1); resistorLoadBank=zeros(n,1);
rejectedGensetCharge=zeros(n,1);
active(1)=min(2,max(1,Input.InitialActiveBattery));
timeSinceGenTransition=Input.Genset.MinOffTime_s;
switchSOE=0.30;
fuelUsed_L=0;
depletionIndex=[];

for k=1:n
    if k>1
        active(k)=active(k-1);
    end
    soe1=E1(k)/Input.Battery1.UsableEnergy_kWh;
    soe2=E2(k)/Input.Battery2.UsableEnergy_kWh;

    if isBEV
        % BEV architecture: the engine-genset path is absent. Battery 1 is
        % always connected; Battery 2 is either disconnected or paralleled
        % through the coordinated contactor/BMS. Parallel requests are
        % shared in proportion to instantaneous pack capability.
        active(k)=1+2*useTwoBEVBatteries;
        totalRequest=PNet(k);
        if PNet(k)<0, totalRequest=-regenAfterAuxiliary(k); end
        [request1,request2]=parallel_battery_requests(totalRequest,E1(k),E2(k), ...
            Input.Battery1,Input.Battery2,dt(k),useTwoBEVBatteries,batteryTemperature_C);
        [P1(k),nextE1,loss1]=battery_step(request1,E1(k),Input.Battery1, ...
            dt(k),request1<0,batteryTemperature_C);
        [P2(k),nextE2,loss2]=battery_step(request2,E2(k),Input.Battery2, ...
            dt(k),request2<0,batteryTemperature_C);
        batteryLoss(k)=loss1+loss2;
        if PNet(k)>=0
            unmetDC(k)=max(0,PNet(k)-max(0,P1(k))-max(0,P2(k)));
        else
            regenToActiveBattery(k)=max(0,-P1(k))+max(0,-P2(k));
            resistorLoadBank(k)=max(0,regenAfterAuxiliary(k)-regenToActiveBattery(k));
            rejectedCharge(k)=resistorLoadBank(k);
        end
        if unmetDC(k)>0
            mode(k)=7;
        elseif PNet(k)<0
            mode(k)=10;
        elseif useTwoBEVBatteries
            mode(k)=9;
        else
            mode(k)=8;
        end
        residual(k)=P1(k)+P2(k)-PNet(k)+unmetDC(k)-rejectedCharge(k);
        if k<n
            E1(k+1)=nextE1;
            E2(k+1)=nextE2;
        end
        if isfield(Input,'RepeatUntilDepleted') && Input.RepeatUntilDepleted && unmetDC(k)>0
            pack1Empty=E1(k)<=Input.Battery1.MinSOE*Input.Battery1.UsableEnergy_kWh+1e-9;
            pack2Unavailable=~useTwoBEVBatteries || ...
                E2(k)<=Input.Battery2.MinSOE*Input.Battery2.UsableEnergy_kWh+1e-9;
            if pack1Empty && pack2Unavailable, depletionIndex=k; break; end
        end
        continue
    end
    activeSOE=soe1; standbySOE=soe2;
    if active(k)==2, activeSOE=soe2; standbySOE=soe1; end

    % Battery-role rule: a traction pack becomes standby at 30% SOE. The
    % alternate pack must be above 30%; otherwise the current pack remains
    % active until the charging standby pack is ready, preventing chatter.
    if activeSOE<=switchSOE && standbySOE>switchSOE
        active(k)=3-active(k);
        if active(k)==1, standbySOE=soe2; else, standbySOE=soe1; end
    end
    if active(k)==1
        standbyChargeTargetSOE=Input.Battery2.MaxSOE;
    else
        standbyChargeTargetSOE=Input.Battery1.MaxSOE;
    end

    % The genset is electrically isolated from the traction bus. It starts
    % only for a depleted standby pack and runs at one best-efficiency point
    % until that pack reaches the calibrated recovery target.
    previousOn = k>1 && gensetOn(k-1);
    gensetAvailable=Input.Genset.OptimumPower_kW>0 && Input.Genset.MaxPower_kW>0 && ...
        fuelUsed_L<Input.Vehicle.FuelTank_L;
    if previousOn
        gensetOn(k)=gensetAvailable && ~(standbySOE>=standbyChargeTargetSOE && ...
            timeSinceGenTransition>=Input.Genset.MinOnTime_s);
    else
        gensetOn(k)=gensetAvailable && standbySOE<=switchSOE && ...
            timeSinceGenTransition>=Input.Genset.MinOffTime_s;
    end
    if gensetOn(k)~=previousOn, timeSinceGenTransition=0; else, timeSinceGenTransition=timeSinceGenTransition+dt(k); end
    starts(k)=gensetOn(k) && ~previousOn;
    if gensetOn(k), PGen(k)=min(Input.Genset.OptimumPower_kW,Input.Genset.MaxPower_kW); end

    % Build independent commands for the traction/regen path and the
    % dedicated standby charger. Regeneration has a strict allocation order:
    % auxiliaries first, then the active battery, then the resistor load bank.
    % Positive battery power is discharge.
    request1=0; request2=0;
    if PNet(k)>=0
        if active(k)==1, request1=PNet(k); else, request2=PNet(k); end
    else
        if active(k)==1, request1=-regenAfterAuxiliary(k); else, request2=-regenAfterAuxiliary(k); end
    end
    if PGen(k)>0
        gensetChargeDestination(k)=3-active(k);
        if gensetChargeDestination(k)==1
            request1=request1-PGen(k);
        else
            request2=request2-PGen(k);
        end
    end

    [P1(k),nextE1,loss1]=battery_step(request1,E1(k),Input.Battery1, ...
        dt(k),request1<0,batteryTemperature_C);
    [P2(k),nextE2,loss2]=battery_step(request2,E2(k),Input.Battery2, ...
        dt(k),request2<0,batteryTemperature_C);
    batteryLoss(k)=loss1+loss2;
    if PNet(k)>=0
        if active(k)==1, activePower=max(0,P1(k)); else, activePower=max(0,P2(k)); end
        unmetDC(k)=max(0,PNet(k)-activePower);
    end
    if PNet(k)<0
        if active(k)==1
            regenToActiveBattery(k)=max(0,-P1(k));
            standbyAcceptedCharge=max(0,-P2(k));
        else
            regenToActiveBattery(k)=max(0,-P2(k));
            standbyAcceptedCharge=max(0,-P1(k));
        end
        resistorLoadBank(k)=max(0,regenAfterAuxiliary(k)-regenToActiveBattery(k));
    elseif active(k)==1
        standbyAcceptedCharge=max(0,-P2(k));
    else
        standbyAcceptedCharge=max(0,-P1(k));
    end
    rejectedGensetCharge(k)=max(0,PGen(k)-standbyAcceptedCharge);
    rejectedCharge(k)=resistorLoadBank(k)+rejectedGensetCharge(k);
    if unmetDC(k)>0
        mode(k)=7;
    elseif PNet(k)<0
        mode(k)=6;
    elseif gensetOn(k)
        mode(k)=active(k)+2;
    else
        mode(k)=active(k);
    end
    residual(k)=PGen(k)+P1(k)+P2(k)-PNet(k)+unmetDC(k)-rejectedCharge(k);
    loadFraction=min(1,max(0,PGen(k)/max(Input.Genset.MaxPower_kW,eps)));
    etaGen=interp1(Input.GeneratorMap.NormalizedGeneratorLoad, ...
        Input.GeneratorMap.Efficiency,loadFraction,'linear','extrap');
    etaGen=min(0.98,max(0.70,etaGen));
    genMechanical(k)=PGen(k)/etaGen;
    bsfc=interp1(Input.FuelMap.NormalizedEngineLoad,Input.FuelMap.BSFC_g_kWh, ...
        loadFraction,'linear','extrap');
    if gensetOn(k)
        fuelRate(k)=max(Input.Genset.IdleFuel_Lph/3600, ...
            genMechanical(k)*bsfc/1000/Input.Genset.FuelDensity_kg_L/3600);
    end
    if starts(k), fuelRate(k)=fuelRate(k)+Input.Genset.StartFuel_L/max(dt(k),eps); end
    fuelRate(k)=min(fuelRate(k),max(0,Input.Vehicle.FuelTank_L-fuelUsed_L)/max(dt(k),eps));
    fuelUsed_L=fuelUsed_L+fuelRate(k)*dt(k);
    if k<n
        E1(k+1)=nextE1;
        E2(k+1)=nextE2;
    end
    if isfield(Input,'RepeatUntilDepleted') && Input.RepeatUntilDepleted && ...
            fuelUsed_L>=Input.Vehicle.FuelTank_L-1e-9 && unmetDC(k)>0
        noUsablePack=(active(k)==1 && ...
            E1(k)<=Input.Battery1.MinSOE*Input.Battery1.UsableEnergy_kWh+1e-9 && ...
            E2(k)<=switchSOE*Input.Battery2.UsableEnergy_kWh+1e-9) || ...
            (active(k)==2 && E2(k)<=Input.Battery2.MinSOE*Input.Battery2.UsableEnergy_kWh+1e-9 && ...
            E1(k)<=switchSOE*Input.Battery1.UsableEnergy_kWh+1e-9);
        if noUsablePack, depletionIndex=k; break; end
    end
end

if isfield(Input,'RepeatUntilDepleted') && Input.RepeatUntilDepleted
    if ~isempty(depletionIndex)
        keep=1:depletionIndex;
        R=R(keep,:); t=t(keep); dt=dt(keep); v=v(keep); a=a(keep); FTractive=FTractive(keep);
        PWheelDemand=PWheelDemand(keep); PWheelDelivered=PWheelDelivered(keep);
        perMotorMechLimit=perMotorMechLimit(keep);
        motorMechanicalPower=motorMechanicalPower(keep); motorPairTorque=motorPairTorque(keep);
        motorLossPower=motorLossPower(keep);
        regenLimit=regenLimit(keep);
        totalWheelDelivered=totalWheelDelivered(keep); brakingDemand=brakingDemand(keep);
        regenerativeWheelBraking=regenerativeWheelBraking(keep);
        frictionBrakePower=frictionBrakePower(keep); unmetBraking=unmetBraking(keep);
        unmetTraction=unmetTraction(keep); unmetRegen=unmetRegen(keep); PMotorDC=PMotorDC(keep);
        rpmMotor=rpmMotor(keep); PAux=PAux(keep); PNet=PNet(keep);
        P1=P1(keep); P2=P2(keep); PGen=PGen(keep);
        E1=E1(keep); E2=E2(keep); fuelRate=fuelRate(keep); active=active(keep);
        gensetOn=gensetOn(keep); starts=starts(keep); gensetChargeDestination=gensetChargeDestination(keep);
        mode=mode(keep); unmetDC=unmetDC(keep); rejectedCharge=rejectedCharge(keep);
        residual=residual(keep); batteryLoss=batteryLoss(keep); genMechanical=genMechanical(keep);
        regenAvailable=regenAvailable(keep); regenToAuxiliary=regenToAuxiliary(keep);
        regenToActiveBattery=regenToActiveBattery(keep); resistorLoadBank=resistorLoadBank(keep);
        rejectedGensetCharge=rejectedGensetCharge(keep);
    end
end

Signals = struct;
motorDrivingLimit=2*perMotorMechLimit;
motorRegenerationLimit=regenLimit/max(Input.FinalDrive.RegenEfficiency,eps);
[battery1Voltage,battery1Current,battery1DischargeCurrentLimit,battery1ChargeCurrentLimit, ...
    battery1DischargePowerCapability,battery1ChargePowerCapability, ...
    battery1OCV,battery1Resistance,battery1OhmicLoss]=battery_electrical_signals( ...
    P1,E1,Input.Battery1,dt,Input.Battery1PackCount,batteryTemperature_C);
[battery2Voltage,battery2Current,battery2DischargeCurrentLimit,battery2ChargeCurrentLimit, ...
    battery2DischargePowerCapability,battery2ChargePowerCapability, ...
    battery2OCV,battery2Resistance,battery2OhmicLoss]=battery_electrical_signals( ...
    P2,E2,Input.Battery2,dt,Input.Battery2PackCount,batteryTemperature_C);
dcBusVoltage=Input.Motor.VoltageClass_V*ones(size(PNet));
dcBusCurrent=1000*PNet./max(dcBusVoltage,eps);
Signals.Vehicle=struct('Speed_m_s',v,'DesiredSpeed_m_s',v,'SpeedError_m_s',zeros(size(v)), ...
    'Acceleration_m_s2',a,'DesiredAcceleration_m_s2',a,'Grade_pct',R.Grade_pct, ...
    'TractiveForce_N',FTractive,'TractiveForceDemand_N',FTractive, ...
    'Distance_m',R.Distance_m,'LimitingCause',repmat("Prescribed speed",numel(v),1));
Signals.Wheel=struct('Demand_kW',PWheelDemand,'Delivered_kW',PWheelDelivered, ...
    'TotalDelivered_kW',totalWheelDelivered,'BrakingDemand_kW',brakingDemand, ...
    'RegenerativeBraking_kW',regenerativeWheelBraking, ...
    'FrictionBrakePower_kW',frictionBrakePower, ...
    'UnmetTraction_kW',unmetTraction,'UnmetBraking_kW',unmetBraking, ...
    'UnmetRegen_kW',unmetRegen);
Signals.Motors=struct('ElectricalPower_kW',PMotorDC,'MechanicalPower_kW',motorMechanicalPower, ...
    'MotorSpeed_rpm',rpmMotor,'PairTorque_Nm',motorPairTorque, ...
    'PerMotorTorque_Nm',motorPairTorque/2, ...
    'LossPower_kW',motorLossPower, ...
    'DrivingPowerLimit_kW',motorDrivingLimit, ...
    'RegenerationPowerLimit_kW',motorRegenerationLimit);
Signals.Auxiliary=struct('Power_kW',PAux);
Signals.Regeneration=struct('Available_kW',regenAvailable, ...
    'ToAuxiliary_kW',regenToAuxiliary,'ToActiveBattery_kW',regenToActiveBattery, ...
    'ResistorLoadBank_kW',resistorLoadBank);
Signals.Battery1=struct('Power_kW',P1,'Energy_kWh',E1,'SOE',E1/Input.Battery1.UsableEnergy_kWh, ...
    'Voltage_V',battery1Voltage,'OpenCircuitVoltage_V',battery1OCV, ...
    'Current_A',battery1Current,'Temperature_C',batteryTemperature_C*ones(size(P1)), ...
    'InternalResistance_Ohm',battery1Resistance,'OhmicLoss_kW',battery1OhmicLoss, ...
    'DischargeCurrentLimit_A',battery1DischargeCurrentLimit, ...
    'ChargeCurrentLimit_A',battery1ChargeCurrentLimit, ...
    'DerivedDischargePowerCapability_kW',battery1DischargePowerCapability, ...
    'DerivedChargePowerCapability_kW',battery1ChargePowerCapability);
Signals.Battery2=struct('Power_kW',P2,'Energy_kWh',E2,'SOE',E2/Input.Battery2.UsableEnergy_kWh, ...
    'Voltage_V',battery2Voltage,'OpenCircuitVoltage_V',battery2OCV, ...
    'Current_A',battery2Current,'Temperature_C',batteryTemperature_C*ones(size(P2)), ...
    'InternalResistance_Ohm',battery2Resistance,'OhmicLoss_kW',battery2OhmicLoss, ...
    'DischargeCurrentLimit_A',battery2DischargeCurrentLimit, ...
    'ChargeCurrentLimit_A',battery2ChargeCurrentLimit, ...
    'DerivedDischargePowerCapability_kW',battery2DischargePowerCapability, ...
    'DerivedChargePowerCapability_kW',battery2ChargePowerCapability);
Signals.DCBus=struct('Voltage_V',dcBusVoltage,'Current_A',dcBusCurrent, ...
    'NetPower_kW',PNet,'VoltageModel',"Nominal traction voltage class");
Signals.Genset=struct('ElectricalPower_kW',PGen,'MechanicalPower_kW',genMechanical, ...
    'FuelRate_L_s',fuelRate,'On',gensetOn,'StartEvent',starts, ...
    'ChargeDestinationBattery',gensetChargeDestination);
if isBEV
    standbyBattery=zeros(size(active));
    connectedBatteryCount=ones(size(active))*Input.TotalBatteryPackCount;
else
    standbyBattery=3-active;
    connectedBatteryCount=ones(size(active))*Input.Battery1PackCount;
end
Signals.Controller=struct('ActiveBattery',active,'StandbyBattery',standbyBattery,'Mode',mode, ...
    'ConnectedBatteryCount',connectedBatteryCount, ...
    'BatteryRoleSwitchSOE',switchSOE*ones(numel(t),1));
Signals.Energy=struct('BalanceResidual_kW',residual,'UnmetDCPower_kW',unmetDC, ...
    'RejectedCharge_kW',rejectedCharge,'RejectedGensetCharge_kW',rejectedGensetCharge, ...
    'BatteryLoss_kW',batteryLoss);

integrate = @(p) sum(p.*dt)/3600;
distanceKm=R.Distance_m(end)/1000; fuelL=sum(fuelRate.*dt);
gridEnergy=max(0,E1(1)-E1(end));
if ~isBEV || useTwoBEVBatteries, gridEnergy=gridEnergy+max(0,E2(1)-E2(end)); end
gridEnergy=gridEnergy/Input.Vehicle.GridChargeEfficiency;
fuelCost=fuelL*Input.Prices.FuelPrice_per_L;
electricCost=gridEnergy*Input.Prices.ElectricityPrice_per_kWh;
usableInitial=max(0,E1(1)-Input.Battery1.MinSOE*Input.Battery1.UsableEnergy_kWh);
if ~isBEV || useTwoBEVBatteries
    usableInitial=usableInitial+max(0,E2(1)-Input.Battery2.MinSOE*Input.Battery2.UsableEnergy_kWh);
end
routeDCEnergyPerKm=max(0.1,integrate(PNet)/max(distanceKm,eps));
batteryOnlyRange=usableInitial/routeDCEnergyPerKm;
fuelPerKm=fuelL/max(distanceKm,eps);
if isBEV
    hybridFuelRange=0;
elseif fuelPerKm<=1e-9
    % When the example route never starts the genset, estimate supported range
    % at its selected optimum point instead of reporting infinite range.
    optimumFraction=Input.Genset.OptimumPower_kW/max(Input.Genset.MaxPower_kW,eps);
    optimumEta=interp1(Input.GeneratorMap.NormalizedGeneratorLoad, ...
        Input.GeneratorMap.Efficiency,optimumFraction,'linear','extrap');
    optimumBSFC=interp1(Input.FuelMap.NormalizedEngineLoad, ...
        Input.FuelMap.BSFC_g_kWh,optimumFraction,'linear','extrap');
    electricPerKm=max(gridEnergy/max(distanceKm,eps),0.1);
    fuelPerKm=electricPerKm/max(optimumEta,0.7)*optimumBSFC/1000/ ...
        Input.Genset.FuelDensity_kg_L;
    hybridFuelRange=Input.Vehicle.FuelTank_L/max(fuelPerKm,1e-9);
else
    hybridFuelRange=Input.Vehicle.FuelTank_L/max(fuelPerKm,1e-9);
end
Summary=struct('RouteDistance_km',distanceKm,'Fuel_L',fuelL, ...
    'RouteCatalogDistance_km',Input.RouteDistance_km,'RouteCompletion_pct',100, ...
    'RouteCompleted',true,'DistanceShortfall_km',0,'ActualCompletionTime_s',t(end), ...
    'NominalRouteTime_s',Input.Route.Time_s(end),'MaximumAchievedSpeed_kmh',max(v)*3.6, ...
    'MaximumSpeedError_kmh',0,'RMSSpeedError_kmh',0,'TimeBelowTarget_s',0, ...
    'PerformanceLimitingCause','Not evaluated in prescribed-speed mode', ...
    'TerminationReason','Prescribed route completed','SimulationFormulation','BackwardDemand', ...
    'Fuel_L_per_100km',100*fuelL/max(distanceKm,eps),'GridEquivalentEnergy_kWh',gridEnergy, ...
    'Electrical_kWh_per_km',gridEnergy/max(distanceKm,eps), ...
    'TotalSourceEnergy_kWh_per_km',(gridEnergy+integrate(genMechanical))/max(distanceKm,eps), ...
    'GensetElectricalEnergy_kWh',integrate(PGen),'BatteryThroughput_kWh',integrate(abs(P1)+abs(P2)), ...
    'BatteryOhmicLossEnergy_kWh',integrate(battery1OhmicLoss+battery2OhmicLoss), ...
    'RegeneratedEnergy_kWh',integrate(regenAvailable), ...
    'RegenerationToAuxiliaryEnergy_kWh',integrate(regenToAuxiliary), ...
    'RegenerationToActiveBatteryEnergy_kWh',integrate(regenToActiveBattery), ...
    'ResistorLoadBankEnergy_kWh',integrate(resistorLoadBank), ...
    'WheelBrakingDemandEnergy_kWh',integrate(brakingDemand), ...
    'RegenerativeWheelBrakingEnergy_kWh',integrate(regenerativeWheelBraking), ...
    'FrictionBrakeEnergy_kWh',integrate(frictionBrakePower), ...
    'UnmetBrakingEnergy_kWh',integrate(unmetBraking), ...
    'AuxiliaryEnergy_kWh',integrate(PAux), ...
    'FinalBattery1SOE',E1(end)/Input.Battery1.UsableEnergy_kWh, ...
    'FinalBattery2SOE',E2(end)/Input.Battery2.UsableEnergy_kWh, ...
    'FuelCost',fuelCost,'ElectricCost',electricCost,'TotalOperatingCost',fuelCost+electricCost, ...
    'CostPer_km',(fuelCost+electricCost)/max(distanceKm,eps), ...
    'BatteryOnlyEquivalentRange_km',batteryOnlyRange,'FuelSupportedRange_km',hybridFuelRange, ...
    'TotalMissionRange_km',batteryOnlyRange+hybridFuelRange, ...
    'RouteRepeatEquivalentRange_km',floor((batteryOnlyRange+hybridFuelRange)/distanceKm)*distanceKm, ...
    'UnmetTractionEnergy_kWh',integrate(unmetTraction)+integrate(unmetDC), ...
    'EnergyBalanceError_kWh',integrate(abs(residual)), ...
    'GensetStarts',sum(starts),'GensetRuntime_s',sum(gensetOn.*dt), ...
    'EstimatedVehicleMass_kg',mass,'ComponentMass_kg',componentMass, ...
    'BaseCurbMass_kg',Input.Mass.BaseCurbMass_kg, ...
    'InstalledBatteryMass_kg',Input.Mass.BatteryMass_kg, ...
    'InstalledGensetMass_kg',Input.Mass.GensetMass_kg, ...
    'CalculatedCurbMass_kg',Input.Mass.CurbMass_kg, ...
    'LoadMass_t',Input.Mass.LoadMass_t, ...
    'LoadMass_kg',Input.Mass.LoadMass_kg, ...
    'PowertrainMode',char(string(Input.PowertrainMode)), ...
    'BatterySetMultiplier',Input.BatterySetMultiplier, ...
    'Battery1PackCount',Input.Battery1PackCount, ...
    'Battery2PackCount',Input.Battery2PackCount, ...
    'TotalInstalledBatteryCount',Input.TotalBatteryPackCount, ...
    'ConnectedBatteryCount',connectedBatteryCount(end));

warnings=strings(0,1);
if Summary.EnergyBalanceError_kWh>Input.Vehicle.EnergyBalanceTolerance_kWh
    warnings(end+1,1)="Energy balance tolerance exceeded";
end
if Summary.UnmetTractionEnergy_kWh>1e-3, warnings(end+1,1)="Unmet traction/DC energy present"; end
Results=struct('Metadata',struct('DatabaseFilename',Input.DatabaseFile, ...
    'DatabaseVersion',Input.DatabaseVersion,'MATLABRelease',version('-release'), ...
    'ModelVersion','1.1.0','SimulationTimestamp',datetime('now')), ...
    'SelectedConfiguration',Input.SelectedIDs,'InputParameters',Input, ...
    'Route',R,'Time',t,'Signals',Signals,'Summary',Summary, ...
    'Validation',struct('Warnings',warnings,'ConstraintViolations',warnings, ...
    'IsFeasible',isempty(warnings) || all(warnings~="Unmet traction/DC energy present")));
end

function [request1,request2]=parallel_battery_requests(totalRequest,E1,E2,B1,B2,dt,useTwo,temperature_C)
if ~useTwo
    request1=totalRequest; request2=0; return
end
isCharge=totalRequest<0;
cap1=battery_power_capability(E1,B1,dt,isCharge,temperature_C);
cap2=battery_power_capability(E2,B2,dt,isCharge,temperature_C);
magnitude=abs(totalRequest);
accepted=min(magnitude,cap1+cap2);
if cap1+cap2<=eps
    share1=0;
else
    share1=accepted*cap1/(cap1+cap2);
end
share2=accepted-share1;
if isCharge
    request1=-share1; request2=-share2;
else
    request1=share1; request2=share2;
end
end

function capability=battery_power_capability(energy,B,dt,isCharge,temperature_C)
[~,~,dischargePower,chargePower]=battery_current_capability( ...
    energy,B,dt,temperature_C);
if isCharge
    capability=chargePower;
else
    capability=dischargePower;
end
end

function [power,energy,loss] = battery_step(request,energy,B,dt,isCharge,temperature_C)
emin=B.MinSOE*B.UsableEnergy_kWh; emax=B.MaxSOE*B.UsableEnergy_kWh;
[~,~,dischargePower,chargePower]=battery_current_capability( ...
    energy,B,dt,temperature_C);
if ~isCharge
    power=min(max(0,request),dischargePower);
    delta=-power/B.DischargeEfficiency*dt/3600;
    loss=power*(1/B.DischargeEfficiency-1);
else
    magnitude=min(-min(0,request),chargePower);
    power=-magnitude; delta=magnitude*B.ChargeEfficiency*dt/3600;
    loss=magnitude*(1-B.ChargeEfficiency);
end
energy=min(emax,max(emin,energy+delta));
end

function [voltage,current,dischargeCurrentLimit,chargeCurrentLimit, ...
        dischargePowerCapability,chargePowerCapability,openCircuitVoltage, ...
        resistance,ohmicLoss]=battery_electrical_signals( ...
        power,energy,B,dt,packCount,temperature_C)
% First-order Thevenin terminal quantities with SOE/temperature resistance.
if packCount==0
    voltage=zeros(size(power)); current=zeros(size(power));
    dischargeCurrentLimit=zeros(size(power)); chargeCurrentLimit=zeros(size(power));
    dischargePowerCapability=zeros(size(power)); chargePowerCapability=zeros(size(power));
    openCircuitVoltage=zeros(size(power)); resistance=zeros(size(power));
    ohmicLoss=zeros(size(power));
    return
end
[dischargeCurrentLimit,chargeCurrentLimit,dischargePowerCapability, ...
    chargePowerCapability,openCircuitVoltage,resistance]= ...
    battery_current_capability(energy,B,dt,temperature_C);
discriminant=max(0,openCircuitVoltage.^2-4.*resistance.*1000.*power);
current=(openCircuitVoltage-sqrt(discriminant))./max(2.*resistance,eps);
voltage=openCircuitVoltage-current.*resistance;
ohmicLoss=current.^2.*resistance/1000;
end

function [dischargeCurrent,chargeCurrent,dischargePower,chargePower, ...
        openCircuitVoltage,resistance]=battery_current_capability(energy,B,dt,temperature_C)
soe=energy/max(B.UsableEnergy_kWh,eps);
[mapDischarge,mapCharge,openCircuitVoltage,resistance]= ...
    battery_dynamic_current_limits(B,soe,temperature_C);
dischargeCurrent=max(0,mapDischarge*B.DeratingFactor);
chargeCurrent=max(0,mapCharge*B.DeratingFactor);
dischargeCurrent=min(dischargeCurrent,max(0,(openCircuitVoltage-B.MinVoltage_V)./max(resistance,eps)));
chargeCurrent=min(chargeCurrent,max(0,(B.MaxVoltage_V-openCircuitVoltage)./max(resistance,eps)));
emin=B.MinSOE*B.UsableEnergy_kWh; emax=B.MaxSOE*B.UsableEnergy_kWh;
energyDischarge=max(0,(energy-emin).*3600.*B.DischargeEfficiency./max(dt,eps));
energyCharge=max(0,(emax-energy).*3600./max(dt,eps)./B.ChargeEfficiency);
dischargeCurrent=min(dischargeCurrent,current_from_power( ...
    energyDischarge,openCircuitVoltage,resistance,false));
chargeCurrent=min(chargeCurrent,current_from_power( ...
    energyCharge,openCircuitVoltage,resistance,true));
dischargePower=max(0,dischargeCurrent.*(openCircuitVoltage-dischargeCurrent.*resistance)/1000);
chargePower=max(0,chargeCurrent.*(openCircuitVoltage+chargeCurrent.*resistance)/1000);
end

function current=current_from_power(power,voltage,resistance,isCharge)
power=max(0,power);
if isCharge
    current=(-voltage+sqrt(voltage.^2+4.*resistance.*1000.*power))./ ...
        max(2.*resistance,eps);
else
    power=min(power,voltage.^2./max(4.*resistance.*1000,eps));
    current=(voltage-sqrt(max(0,voltage.^2-4.*resistance.*1000.*power)))./ ...
        max(2.*resistance,eps);
end
end

function [dischargeLimit,chargeLimit,openCircuitVoltage,resistance]= ...
        battery_dynamic_current_limits(B,soe,temperature_C)
soe=min(max(soe,B.SOEBreakpoints(1)),B.SOEBreakpoints(end));
if isfield(B,'DischargeCurrentVsSOE_A') && ...
        abs(B.ConditionedTemperature_C-temperature_C)<1e-12
    dischargeLimit=interp1(B.SOEBreakpoints,B.DischargeCurrentVsSOE_A,soe,'linear');
    chargeLimit=interp1(B.SOEBreakpoints,B.ChargeCurrentVsSOE_A,soe,'linear');
    openCircuitVoltage=interp1(B.SOCBreakpoints, ...
        B.OpenCircuitVoltageVsSOC_V,soe,'linear');
    resistance=interp1(B.SOEBreakpoints,B.InternalResistanceVsSOE_Ohm,soe,'linear');
    return
end
temperature_C=min(max(temperature_C,B.TemperatureBreakpoints_C(1)), ...
    B.TemperatureBreakpoints_C(end));
temperature_C=temperature_C+zeros(size(soe));
dischargeLimit=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.MaxDischargeCurrentMap_A,soe,temperature_C,'linear');
chargeLimit=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.MaxChargeCurrentMap_A,soe,temperature_C,'linear');
openCircuitVoltage=interp2(B.SOCBreakpoints,B.TemperatureBreakpoints_C, ...
    B.OpenCircuitVoltageMap_V,soe,temperature_C,'linear');
resistance=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.InternalResistanceMap_Ohm,soe,temperature_C,'linear');
end
