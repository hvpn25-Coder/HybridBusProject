function Results=simulate_hybrid_bus_performance(Input)
%SIMULATE_HYBRID_BUS_PERFORMANCE Forward longitudinal performance model.
% Route speed is a driver target. Grade and auxiliary demand are sampled at
% actual travelled distance. Positive battery power is discharge.

reference=distance_reference(Input.Route);
dt_s=Input.Vehicle.SampleTime_s;
formulation=string(Input.SimulationFormulation);
isConstrained=formulation=="ConstrainedBackward";
nominalDuration_s=Input.Route.Time_s(end)-Input.Route.Time_s(1);
if isConstrained
    t=Input.Route.Time_s(:)-Input.Route.Time_s(1);
    maximumSteps=numel(t);
else
    maximumDuration_s=max(Input.Performance.MaximumDurationFactor*nominalDuration_s, ...
        nominalDuration_s+Input.Performance.MaximumExtraTime_s);
    maximumSteps=ceil(maximumDuration_s/dt_s)+1;
    t=(0:maximumSteps-1)'*dt_s;
end
isBEV=strcmpi(string(Input.PowertrainMode),"BEV");
useBattery2=isBEV && Input.Battery2PackCount>0;
mass_kg=Input.Mass.TotalVehicleMass_kg;

v=zeros(maximumSteps,1); a=zeros(maximumSteps,1); distance=zeros(maximumSteps,1);
desiredSpeed=zeros(maximumSteps,1); desiredAcceleration=zeros(maximumSteps,1);
grade=zeros(maximumSteps,1); auxMultiplier=ones(maximumSteps,1);
tractiveForceDemand=zeros(maximumSteps,1); deliveredDriveForce=zeros(maximumSteps,1);
wheelDemand=zeros(maximumSteps,1); wheelDelivered=zeros(maximumSteps,1);
frictionBrake=zeros(maximumSteps,1); brakingDemand=zeros(maximumSteps,1);
regenerativeWheelBraking=zeros(maximumSteps,1); unmetTraction=zeros(maximumSteps,1);
motorMechanical=zeros(maximumSteps,1); motorDC=zeros(maximumSteps,1);
motorLoss=zeros(maximumSteps,1); motorSpeed=zeros(maximumSteps,1);
motorPairTorque=zeros(maximumSteps,1); motorDriveLimit=zeros(maximumSteps,1);
motorRegenLimit=zeros(maximumSteps,1); auxiliaryPower=zeros(maximumSteps,1);
P1=zeros(maximumSteps,1); P2=zeros(maximumSteps,1); PGen=zeros(maximumSteps,1);
E1=zeros(maximumSteps,1); E2=zeros(maximumSteps,1); fuelRate=zeros(maximumSteps,1);
gensetMechanical=zeros(maximumSteps,1); batteryLoss=zeros(maximumSteps,1);
active=zeros(maximumSteps,1); mode=zeros(maximumSteps,1); gensetOn=false(maximumSteps,1);
starts=false(maximumSteps,1); gensetDestination=zeros(maximumSteps,1);
unmetDC=zeros(maximumSteps,1); rejectedCharge=zeros(maximumSteps,1);
rejectedGensetCharge=zeros(maximumSteps,1); residual=zeros(maximumSteps,1);
regenAvailable=zeros(maximumSteps,1); regenToAuxiliary=zeros(maximumSteps,1);
regenToBattery=zeros(maximumSteps,1); resistorLoad=zeros(maximumSteps,1);
limitCause=repmat("None",maximumSteps,1);

E1(1)=Input.InitialBattery1SOE*Input.Battery1.UsableEnergy_kWh;
E2(1)=Input.InitialBattery2SOE*Input.Battery2.UsableEnergy_kWh;
active(1)=min(2,max(1,Input.InitialActiveBattery));
batteryTemperature_C=Input.Environment.Temperature_C;
switchSOE=0.30; fuelUsed_L=0; timeSinceGenTransition=Input.Genset.MinOffTime_s;
nextStation=1; dwellRemaining_s=0; stallDuration_s=0;
completed=false; terminationReason="Maximum simulation duration reached";
lastIndex=maximumSteps;

for k=1:maximumSteps
    if k>1, active(k)=active(k-1); end
    if isConstrained
        [targetSpeed,grade(k),auxMultiplier(k)]=constrained_route_state( ...
            reference,Input.Route,k,distance(k));
    else
        [targetSpeed,grade(k),auxMultiplier(k),nextStation,dwellRemaining_s]= ...
            route_state(reference,distance(k),v(k),nextStation,dwellRemaining_s, ...
            dt_s,Input.Performance);
    end
    desiredSpeed(k)=targetSpeed;
    speedError=targetSpeed-v(k);
    desiredAcceleration(k)=min(Input.Performance.MaximumAcceleration_m_s2, ...
        max(-Input.Performance.MaximumDeceleration_m_s2, ...
        Input.Performance.DriverProportionalGain_s*speedError));

    theta=atan(grade(k)/100);
    relativeAirSpeed=max(0,v(k)+Input.Environment.Headwind_m_s);
    rollingForce=mass_kg*Input.Vehicle.Gravity_m_s2* ...
        Input.Tyre.RollingResistanceCoefficient*cos(theta);
    gradeForce=mass_kg*Input.Vehicle.Gravity_m_s2*sin(theta);
    aerodynamicForce=0.5*Input.Environment.AirDensity_kg_m3* ...
        Input.Vehicle.DragCoefficient*Input.Vehicle.FrontalArea_m2*relativeAirSpeed^2;
    roadLoadForce=rollingForce+gradeForce+aerodynamicForce;
    tractiveForceDemand(k)=mass_kg*desiredAcceleration(k)+roadLoadForce;
    wheelDemand(k)=tractiveForceDemand(k)*v(k)/1000;

    auxiliaryPower(k)=auxiliary_demand(Input,auxMultiplier(k));
    [dischargeCapability,~]=connected_battery_capability( ...
        Input,E1(k),E2(k),active(k),dt_s,batteryTemperature_C,isBEV,useBattery2);
    [motorLimits,motorSpeed(k)]=motor_limits(Input,v(k));
    motorDriveLimit(k)=motorLimits.DriveMechanical_kW;
    motorRegenLimit(k)=motorLimits.RegenMechanical_kW;

    if tractiveForceDemand(k)>=0
        availableMotorDC=max(0,dischargeCapability-auxiliaryPower(k));
        if isConstrained
            availableShaftPower=motor_mechanical_from_dc_fast(Input,availableMotorDC, ...
                motorSpeed(k),motorLimits.DriveMechanical_kW);
        else
            availableShaftPower=motor_mechanical_from_dc(Input,availableMotorDC, ...
                motorSpeed(k),motorLimits.DriveMechanical_kW);
        end
        forceFromPower=1000*availableShaftPower*Input.FinalDrive.MotoringEfficiency/ ...
            max(v(k),Input.Performance.LowSpeedProtection_m_s);
        availableForce=min(motorLimits.DriveWheelForce_N,forceFromPower);
        if isConstrained && v(k)<=Input.Performance.ZeroSpeedThreshold_m_s
            availableForce=min(motorLimits.DriveWheelForce_N, ...
                motor_launch_force_from_dc(Input,availableMotorDC,motorSpeed(k)));
        elseif ~isConstrained && v(k)<Input.Performance.LowSpeedProtection_m_s
            availableForce=motorLimits.DriveWheelForce_N;
        end
        deliveredDriveForce(k)=min(max(0,tractiveForceDemand(k)),max(0,availableForce));
        wheelDelivered(k)=deliveredDriveForce(k)*v(k)/1000;
        motorMechanical(k)=wheelDelivered(k)/max(Input.FinalDrive.MotoringEfficiency,eps);
        [motorDC(k),motorLoss(k),motorPairTorque(k)]=motor_dc_power( ...
            Input,motorMechanical(k),motorSpeed(k));
        unmetTraction(k)=max(0,tractiveForceDemand(k)-deliveredDriveForce(k))*v(k)/1000;
        if deliveredDriveForce(k)+1e-6<tractiveForceDemand(k)
            if availableMotorDC+1e-6<motorLimits.DriveMechanical_kW
                limitCause(k)="Battery discharge capability";
            else
                limitCause(k)="Motor torque-speed capability";
            end
        end
    else
        requestedBrakeForce=max(0,-tractiveForceDemand(k));
        brakingDemand(k)=requestedBrakeForce*v(k)/1000;
        if v(k)>Input.Performance.MinimumRegenerationSpeed_m_s
            regenerativeForce=min(requestedBrakeForce,motorLimits.RegenWheelForce_N);
        else
            regenerativeForce=0;
        end
        regenerativeWheelBraking(k)=regenerativeForce*v(k)/1000;
        wheelDelivered(k)=-regenerativeWheelBraking(k);
        motorMechanical(k)=wheelDelivered(k)*Input.FinalDrive.RegenEfficiency;
        [motorDC(k),motorLoss(k),motorPairTorque(k)]=motor_dc_power( ...
            Input,motorMechanical(k),motorSpeed(k));
        frictionBrake(k)=max(0,brakingDemand(k)-regenerativeWheelBraking(k));
        deliveredDriveForce(k)=-requestedBrakeForce;
        if frictionBrake(k)>1e-9, limitCause(k)="Regeneration limit; friction braking active"; end
    end

    totalDCRequest=motorDC(k)+auxiliaryPower(k);
    regenAvailable(k)=max(0,-motorDC(k));
    regenToAuxiliary(k)=min(regenAvailable(k),auxiliaryPower(k));

    if isBEV
        [request1,request2]=parallel_battery_requests(totalDCRequest,E1(k),E2(k), ...
            Input.Battery1,Input.Battery2,dt_s,useBattery2,batteryTemperature_C);
        [P1(k),nextE1,loss1]=battery_step(request1,E1(k),Input.Battery1, ...
            dt_s,request1<0,batteryTemperature_C);
        [P2(k),nextE2,loss2]=battery_step(request2,E2(k),Input.Battery2, ...
            dt_s,request2<0,batteryTemperature_C);
        batteryLoss(k)=loss1+loss2;
        if totalDCRequest>=0
            unmetDC(k)=max(0,totalDCRequest-max(0,P1(k))-max(0,P2(k)));
        else
            regenToBattery(k)=max(0,-P1(k))+max(0,-P2(k));
            resistorLoad(k)=max(0,regenAvailable(k)-regenToAuxiliary(k)-regenToBattery(k));
        end
        active(k)=1+2*useBattery2;
        mode(k)=8+useBattery2;
        residual(k)=P1(k)+P2(k)-totalDCRequest+unmetDC(k)-resistorLoad(k);
    else
        soe1=E1(k)/Input.Battery1.UsableEnergy_kWh;
        soe2=E2(k)/Input.Battery2.UsableEnergy_kWh;
        activeSOE=soe1; standbySOE=soe2;
        if active(k)==2, activeSOE=soe2; standbySOE=soe1; end
        if activeSOE<=switchSOE && standbySOE>switchSOE, active(k)=3-active(k); end
        if active(k)==1, standbySOE=soe2; else, standbySOE=soe1; end
        previousOn=k>1 && gensetOn(k-1);
        gensetAvailable=Input.Genset.OptimumPower_kW>0 && ...
            fuelUsed_L<Input.Vehicle.FuelTank_L;
        if previousOn
            gensetOn(k)=gensetAvailable && ~(standbySOE>=Input.Control.GensetTargetSOE && ...
                timeSinceGenTransition>=Input.Genset.MinOnTime_s);
        else
            gensetOn(k)=gensetAvailable && standbySOE<=switchSOE && ...
                timeSinceGenTransition>=Input.Genset.MinOffTime_s;
        end
        if gensetOn(k)~=previousOn, timeSinceGenTransition=0;
        else, timeSinceGenTransition=timeSinceGenTransition+dt_s; end
        starts(k)=gensetOn(k) && ~previousOn;
        if gensetOn(k), PGen(k)=min(Input.Genset.OptimumPower_kW,Input.Genset.MaxPower_kW); end
        request1=0; request2=0;
        if active(k)==1, request1=totalDCRequest; else, request2=totalDCRequest; end
        if PGen(k)>0
            gensetDestination(k)=3-active(k);
            if gensetDestination(k)==1, request1=request1-PGen(k);
            else, request2=request2-PGen(k); end
        end
        [P1(k),nextE1,loss1]=battery_step(request1,E1(k),Input.Battery1, ...
            dt_s,request1<0,batteryTemperature_C);
        [P2(k),nextE2,loss2]=battery_step(request2,E2(k),Input.Battery2, ...
            dt_s,request2<0,batteryTemperature_C);
        batteryLoss(k)=loss1+loss2;
        activePower=max(0,P1(k)); if active(k)==2, activePower=max(0,P2(k)); end
        if totalDCRequest>=0, unmetDC(k)=max(0,totalDCRequest-activePower); end
        activeCharge=max(0,-P1(k)); standbyCharge=max(0,-P2(k));
        if active(k)==2, activeCharge=max(0,-P2(k)); standbyCharge=max(0,-P1(k)); end
        regenToBattery(k)=min(max(0,regenAvailable(k)-regenToAuxiliary(k)),activeCharge);
        resistorLoad(k)=max(0,regenAvailable(k)-regenToAuxiliary(k)-regenToBattery(k));
        rejectedGensetCharge(k)=max(0,PGen(k)-standbyCharge);
        rejectedCharge(k)=resistorLoad(k)+rejectedGensetCharge(k);
        residual(k)=PGen(k)+P1(k)+P2(k)-totalDCRequest+unmetDC(k)-rejectedCharge(k);
        mode(k)=active(k); if gensetOn(k), mode(k)=active(k)+2; end
    end

    [gensetMechanical(k),fuelRate(k)]=genset_fuel_step(Input,PGen(k),starts(k), ...
        dt_s,max(0,Input.Vehicle.FuelTank_L-fuelUsed_L));
    fuelUsed_L=fuelUsed_L+fuelRate(k)*dt_s;

    if k<maximumSteps
        E1(k+1)=nextE1; E2(k+1)=nextE2;
        netForce=deliveredDriveForce(k)-roadLoadForce;
        acceleration=netForce/mass_kg;
        nextSpeed=max(0,v(k)+acceleration*dt_s);
        if v(k)<=Input.Performance.ZeroSpeedThreshold_m_s && acceleration<0
            acceleration=0; nextSpeed=0;
        end
        a(k)=acceleration;
        v(k+1)=nextSpeed;
        distance(k+1)=min(reference.Distance_m(end), ...
            distance(k)+0.5*(v(k)+v(k+1))*dt_s);
    end

    if distance(k)>=reference.Distance_m(end)-Input.Performance.CompletionTolerance_m
        completed=true; terminationReason="Route completed"; lastIndex=k; break
    end
    stalled=v(k)<=Input.Performance.ZeroSpeedThreshold_m_s && ...
        targetSpeed>Input.Performance.TargetMovingThreshold_m_s && ...
        deliveredDriveForce(k)<=roadLoadForce+Input.Performance.StallForceMargin_N;
    if stalled, stallDuration_s=stallDuration_s+dt_s; else, stallDuration_s=0; end
    recoverable=~isConstrained && ~isBEV && gensetOn(k) && ...
        fuelUsed_L<Input.Vehicle.FuelTank_L;
    if stallDuration_s>=Input.Performance.StallDetectionTime_s && ~recoverable
        terminationReason="Vehicle stalled: available traction cannot overcome road load";
        limitCause(k)="Sustained traction shortfall"; lastIndex=k; break
    end
end

if isConstrained && ~completed && lastIndex==maximumSteps && ...
        terminationReason=="Maximum simulation duration reached"
    terminationReason="Route time horizon ended before distance completion";
end

keep=1:lastIndex;
t=t(keep); v=v(keep); a=a(keep); distance=distance(keep); desiredSpeed=desiredSpeed(keep);
desiredAcceleration=desiredAcceleration(keep); grade=grade(keep); auxMultiplier=auxMultiplier(keep);
tractiveForceDemand=tractiveForceDemand(keep); deliveredDriveForce=deliveredDriveForce(keep);
wheelDemand=wheelDemand(keep); wheelDelivered=wheelDelivered(keep);
frictionBrake=frictionBrake(keep); brakingDemand=brakingDemand(keep);
regenerativeWheelBraking=regenerativeWheelBraking(keep); unmetTraction=unmetTraction(keep);
motorMechanical=motorMechanical(keep); motorDC=motorDC(keep); motorLoss=motorLoss(keep);
motorSpeed=motorSpeed(keep); motorPairTorque=motorPairTorque(keep);
motorDriveLimit=motorDriveLimit(keep); motorRegenLimit=motorRegenLimit(keep);
auxiliaryPower=auxiliaryPower(keep); P1=P1(keep); P2=P2(keep); PGen=PGen(keep);
E1=E1(keep); E2=E2(keep); fuelRate=fuelRate(keep); gensetMechanical=gensetMechanical(keep);
batteryLoss=batteryLoss(keep); active=active(keep); mode=mode(keep); gensetOn=gensetOn(keep);
starts=starts(keep); gensetDestination=gensetDestination(keep); unmetDC=unmetDC(keep);
rejectedCharge=rejectedCharge(keep); rejectedGensetCharge=rejectedGensetCharge(keep);
residual=residual(keep); regenAvailable=regenAvailable(keep);
regenToAuxiliary=regenToAuxiliary(keep); regenToBattery=regenToBattery(keep);
resistorLoad=resistorLoad(keep); limitCause=limitCause(keep);

Results=assemble_results(Input,reference,t,v,a,distance,desiredSpeed,desiredAcceleration, ...
    grade,auxMultiplier,tractiveForceDemand,deliveredDriveForce,wheelDemand,wheelDelivered, ...
    brakingDemand,regenerativeWheelBraking,frictionBrake,unmetTraction,motorDC, ...
    motorMechanical,motorLoss,motorSpeed,motorPairTorque,motorDriveLimit,motorRegenLimit, ...
    auxiliaryPower,P1,P2,E1,E2,PGen,gensetMechanical,fuelRate,gensetOn,starts, ...
    gensetDestination,active,mode,unmetDC,rejectedCharge,rejectedGensetCharge,residual, ...
    batteryLoss,regenAvailable,regenToAuxiliary,regenToBattery,resistorLoad,limitCause, ...
    completed,terminationReason,mass_kg,formulation);
end

function reference=distance_reference(route)
distance=max(0,route.Distance_m(:));
rounded=round(distance,3);
[uniqueDistance,~,groups]=unique(rounded,'stable');
speed=splitapply(@max,route.Speed_kmh(:)/3.6,groups);
grade=splitapply(@mean,route.Grade_pct(:),groups);
auxiliary=splitapply(@mean,route.AuxMultiplier(:),groups);
stop=splitapply(@any,logical(route.StopFlag(:)),groups);
sampleTime=median(diff(route.Time_s));
dwell=splitapply(@numel,route.Time_s(:),groups)*sampleTime;
reference=struct('Distance_m',uniqueDistance,'Speed_m_s',speed,'Grade_pct',grade, ...
    'AuxMultiplier',auxiliary,'StationDistance_m',uniqueDistance(stop), ...
    'StationDwell_s',dwell(stop));
if isempty(reference.StationDistance_m)
    reference.StationDwell_s=zeros(0,1);
end
end

function [speed,grade,auxiliary,nextStation,dwellRemaining]=route_state( ...
        reference,distance,vehicleSpeed,nextStation,dwellRemaining,dt_s,P)
queryDistance=min(reference.Distance_m(end),max(reference.Distance_m(1),distance));
if nextStation<=numel(reference.StationDistance_m)
    stationDistance=reference.StationDistance_m(nextStation);
    distanceToStation=stationDistance-distance;
    if dwellRemaining>0
        speed=0; dwellRemaining=max(0,dwellRemaining-dt_s);
        if dwellRemaining==0, nextStation=nextStation+1; end
    elseif abs(distanceToStation)<=P.StationPositionTolerance_m && ...
            vehicleSpeed<=P.StationStopSpeed_m_s
        dwellRemaining=max(P.MinimumStationDwell_s,reference.StationDwell_s(nextStation));
        speed=0;
    else
        speed=interp1(reference.Distance_m,reference.Speed_m_s,queryDistance,'linear','extrap');
        if distanceToStation>0
            stopApproach=sqrt(max(0,2*P.ComfortableStopDeceleration_m_s2*distanceToStation));
            speed=min(speed,stopApproach);
        end
    end
else
    speed=interp1(reference.Distance_m,reference.Speed_m_s,queryDistance,'linear','extrap');
end
if nextStation>1 && nextStation<=numel(reference.StationDistance_m)+1 && ...
        abs(distance-reference.StationDistance_m(nextStation-1))<=P.StationPositionTolerance_m && ...
        dwellRemaining==0
    speed=interp1(reference.Distance_m,reference.Speed_m_s, ...
        min(reference.Distance_m(end),queryDistance+P.PostStopLookAhead_m),'linear','extrap');
end
grade=interp1(reference.Distance_m,reference.Grade_pct,queryDistance,'linear','extrap');
auxiliary=interp1(reference.Distance_m,reference.AuxMultiplier,queryDistance,'linear','extrap');
speed=max(0,speed);
end

function [speed,grade,auxiliary]=constrained_route_state(reference,route,index,distance)
% Time-indexed speed target with terrain/load indexed by actual distance.
speed=max(0,route.Speed_kmh(index)/3.6);
queryDistance=min(reference.Distance_m(end),max(reference.Distance_m(1),distance));
grade=interp1(reference.Distance_m,reference.Grade_pct,queryDistance,'linear','extrap');
auxiliary=interp1(reference.Distance_m,reference.AuxMultiplier,queryDistance,'linear','extrap');
end

function power=auxiliary_demand(Input,multiplier)
ambientDelta=abs(Input.Environment.Temperature_C-Input.Aux.ComfortTemperature_C);
slope=Input.Aux.HotHVAC_kW_per_C;
if Input.Environment.Temperature_C<Input.Aux.ComfortTemperature_C
    slope=Input.Aux.ColdHVAC_kW_per_C;
end
power=(Input.Aux.BasePower_kW+slope*ambientDelta)*multiplier*Input.AuxiliaryScalarOverride;
end

function [capability,chargeCapability]=connected_battery_capability( ...
        Input,E1,E2,active,dt_s,temperature_C,isBEV,useBattery2)
cap1=battery_power_capability(E1,Input.Battery1,dt_s,false,temperature_C);
chg1=battery_power_capability(E1,Input.Battery1,dt_s,true,temperature_C);
cap2=battery_power_capability(E2,Input.Battery2,dt_s,false,temperature_C);
chg2=battery_power_capability(E2,Input.Battery2,dt_s,true,temperature_C);
if isBEV
    capability=cap1+useBattery2*cap2; chargeCapability=chg1+useBattery2*chg2;
elseif active==1
    capability=cap1; chargeCapability=chg1;
else
    capability=cap2; chargeCapability=chg2;
end
end

function [limits,rpm]=motor_limits(Input,speed)
omega=Input.FinalDrive.Ratio*speed/max(Input.Tyre.LoadedRadius_m,0.1);
rpm=omega*60/(2*pi);
torque=Input.Motor.PeakTorque_Nm;
if rpm>Input.Motor.BaseSpeed_rpm
    torque=min(torque,Input.Motor.PeakPower_kW*1000/max(omega,1));
end
if rpm>Input.Motor.MaxSpeed_rpm, torque=0; end
pairMechanicalPower=min(2*Input.Motor.PeakPower_kW,2*torque*omega/1000);
limits=struct('DriveMechanical_kW',pairMechanicalPower, ...
    'RegenMechanical_kW',pairMechanicalPower, ...
    'DriveWheelForce_N',2*torque*Input.FinalDrive.Ratio* ...
        Input.FinalDrive.MotoringEfficiency/max(Input.Tyre.LoadedRadius_m,0.1), ...
    'RegenWheelForce_N',2*torque*Input.FinalDrive.Ratio* ...
        Input.FinalDrive.RegenEfficiency/max(Input.Tyre.LoadedRadius_m,0.1));
end

function mechanical=motor_mechanical_from_dc(Input,dcAvailable,rpm,maximumMechanical)
low=0; high=max(0,maximumMechanical);
for iteration=1:24
    trial=0.5*(low+high);
    [dc,~,~]=motor_dc_power(Input,trial,rpm);
    if dc<=dcAvailable, low=trial; else, high=trial; end
end
mechanical=low;
end

function mechanical=motor_mechanical_from_dc_fast(Input,dcAvailable,rpm,maximumMechanical)
% Four fixed-point loss corrections retain map-based current/power limiting
% without the 24-step binary inversion used by the detailed formulation.
mechanical=min(max(0,maximumMechanical),max(0,dcAvailable));
for iteration=1:4
    [~,loss,~]=motor_dc_power(Input,mechanical,rpm);
    mechanical=min(max(0,maximumMechanical),max(0,dcAvailable-loss));
end
end

function wheelForce=motor_launch_force_from_dc(Input,dcAvailable,rpm)
% At zero shaft speed mechanical power is zero, but torque is supported by
% electrical copper/inverter loss. Bound launch torque using the loss map so
% a depleted/current-limited battery cannot receive free launch force.
low=0; high=max(0,Input.Motor.PeakTorque_Nm);
for iteration=1:8
    perMotorTorque=0.5*(low+high);
    mapTorque=min(perMotorTorque,Input.Motor.TorqueBreakpoints_Nm(end));
    mapSpeed=min(abs(rpm),Input.Motor.SpeedBreakpoints_rpm(end));
    pairLoss=2*interp2(Input.Motor.TorqueBreakpoints_Nm, ...
        Input.Motor.SpeedBreakpoints_rpm,Input.Motor.MotorLossMap_kW, ...
        mapTorque,mapSpeed,'linear');
    if pairLoss<=dcAvailable, low=perMotorTorque; else, high=perMotorTorque; end
end
wheelForce=2*low*Input.FinalDrive.Ratio*Input.FinalDrive.MotoringEfficiency/ ...
    max(Input.Tyre.LoadedRadius_m,0.1);
end

function [dcPower,lossPower,pairTorque]=motor_dc_power(Input,mechanicalPower,rpm)
omega=abs(rpm)*2*pi/60;
if omega<=1e-9, pairTorque=0; else, pairTorque=1000*mechanicalPower/omega; end
mapTorque=min(abs(pairTorque)/2,Input.Motor.TorqueBreakpoints_Nm(end));
mapSpeed=min(abs(rpm),Input.Motor.SpeedBreakpoints_rpm(end));
lossPower=2*interp2(Input.Motor.TorqueBreakpoints_Nm,Input.Motor.SpeedBreakpoints_rpm, ...
    Input.Motor.MotorLossMap_kW,mapTorque,mapSpeed,'linear');
if mechanicalPower>=0, dcPower=mechanicalPower+lossPower;
else, dcPower=min(0,mechanicalPower+lossPower); end
end

function [mechanical,fuelRate]=genset_fuel_step(Input,electrical,startEvent,dt_s,fuelRemaining)
if electrical<=0, mechanical=0; fuelRate=0; return; end
loadFraction=min(1,electrical/max(Input.Genset.MaxPower_kW,eps));
efficiency=interp1(Input.GeneratorMap.NormalizedGeneratorLoad, ...
    Input.GeneratorMap.Efficiency,loadFraction,'linear','extrap');
efficiency=min(0.98,max(0.70,efficiency));
mechanical=electrical/efficiency;
bsfc=interp1(Input.FuelMap.NormalizedEngineLoad,Input.FuelMap.BSFC_g_kWh, ...
    loadFraction,'linear','extrap');
fuelRate=max(Input.Genset.IdleFuel_Lph/3600, ...
    mechanical*bsfc/1000/Input.Genset.FuelDensity_kg_L/3600);
if startEvent, fuelRate=fuelRate+Input.Genset.StartFuel_L/max(dt_s,eps); end
fuelRate=min(fuelRate,max(0,fuelRemaining)/max(dt_s,eps));
end

function [request1,request2]=parallel_battery_requests(totalRequest,E1,E2,B1,B2,dt_s,useTwo,temperature_C)
if ~useTwo, request1=totalRequest; request2=0; return; end
isCharge=totalRequest<0;
cap1=battery_power_capability(E1,B1,dt_s,isCharge,temperature_C);
cap2=battery_power_capability(E2,B2,dt_s,isCharge,temperature_C);
accepted=min(abs(totalRequest),cap1+cap2);
if cap1+cap2<=eps, share1=0; else, share1=accepted*cap1/(cap1+cap2); end
share2=accepted-share1;
if isCharge, request1=-share1; request2=-share2;
else, request1=share1; request2=share2; end
end

function capability=battery_power_capability(energy,B,dt_s,isCharge,temperature_C)
[~,~,dischargePower,chargePower]=battery_current_capability(energy,B,dt_s,temperature_C);
if isCharge, capability=chargePower; else, capability=dischargePower; end
end

function [power,energy,loss]=battery_step(request,energy,B,dt_s,isCharge,temperature_C)
emin=B.MinSOE*B.UsableEnergy_kWh; emax=B.MaxSOE*B.UsableEnergy_kWh;
[~,~,dischargePower,chargePower]=battery_current_capability(energy,B,dt_s,temperature_C);
if ~isCharge
    power=min(max(0,request),dischargePower);
    delta=-power/B.DischargeEfficiency*dt_s/3600;
    loss=power*(1/B.DischargeEfficiency-1);
else
    magnitude=min(-min(0,request),chargePower);
    power=-magnitude; delta=magnitude*B.ChargeEfficiency*dt_s/3600;
    loss=magnitude*(1-B.ChargeEfficiency);
end
energy=min(emax,max(emin,energy+delta));
end

function [dischargeCurrent,chargeCurrent,dischargePower,chargePower,ocv,resistance]= ...
        battery_current_capability(energy,B,dt_s,temperature_C)
soe=energy/max(B.UsableEnergy_kWh,eps);
temperature_C=min(max(temperature_C,B.TemperatureBreakpoints_C(1)),B.TemperatureBreakpoints_C(end));
dischargeCurrent=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.MaxDischargeCurrentMap_A,soe,temperature_C,'linear')*B.DeratingFactor;
chargeCurrent=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.MaxChargeCurrentMap_A,soe,temperature_C,'linear')*B.DeratingFactor;
ocv=interp2(B.SOCBreakpoints,B.TemperatureBreakpoints_C, ...
    B.OpenCircuitVoltageMap_V,soe,temperature_C,'linear');
resistance=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.InternalResistanceMap_Ohm,soe,temperature_C,'linear');
dischargeCurrent=min(max(0,dischargeCurrent),max(0,(ocv-B.MinVoltage_V)/max(resistance,eps)));
chargeCurrent=min(max(0,chargeCurrent),max(0,(B.MaxVoltage_V-ocv)/max(resistance,eps)));
emin=B.MinSOE*B.UsableEnergy_kWh; emax=B.MaxSOE*B.UsableEnergy_kWh;
energyDischarge=max(0,(energy-emin)*3600*B.DischargeEfficiency/max(dt_s,eps));
energyCharge=max(0,(emax-energy)*3600/max(dt_s,eps)/B.ChargeEfficiency);
dischargeCurrent=min(dischargeCurrent,current_from_power(energyDischarge,ocv,resistance,false));
chargeCurrent=min(chargeCurrent,current_from_power(energyCharge,ocv,resistance,true));
dischargePower=max(0,dischargeCurrent*(ocv-dischargeCurrent*resistance)/1000);
chargePower=max(0,chargeCurrent*(ocv+chargeCurrent*resistance)/1000);
end

function current=current_from_power(power,voltage,resistance,isCharge)
power=max(0,power);
if isCharge
    current=(-voltage+sqrt(voltage^2+4*resistance*1000*power))/max(2*resistance,eps);
else
    power=min(power,voltage^2/max(4*resistance*1000,eps));
    current=(voltage-sqrt(max(0,voltage^2-4*resistance*1000*power)))/max(2*resistance,eps);
end
end

function Results=assemble_results(Input,reference,t,v,a,distance,desiredSpeed,desiredAcceleration, ...
        grade,auxMultiplier,tractiveForceDemand,deliveredDriveForce,wheelDemand,wheelDelivered, ...
        brakingDemand,regenWheel,frictionBrake,unmetTraction,motorDC,motorMechanical,motorLoss, ...
        motorSpeed,motorPairTorque,motorDriveLimit,motorRegenLimit,auxiliaryPower,P1,P2,E1,E2, ...
        PGen,gensetMechanical,fuelRate,gensetOn,starts,gensetDestination,active,mode,unmetDC, ...
        rejectedCharge,rejectedGensetCharge,residual,batteryLoss,regenAvailable,regenToAuxiliary, ...
        regenToBattery,resistorLoad,limitCause,completed,terminationReason,mass_kg,formulation)
dt=[diff(t);0]; isBEV=strcmpi(string(Input.PowertrainMode),"BEV");
useBattery2=isBEV && Input.Battery2PackCount>0;
[b1V,b1I,b1D,b1C,b1DP,b1CP,b1OCV,b1R,b1Loss]=battery_signals( ...
    P1,E1,Input.Battery1,dt,Input.Battery1PackCount,Input.Environment.Temperature_C);
[b2V,b2I,b2D,b2C,b2DP,b2CP,b2OCV,b2R,b2Loss]=battery_signals( ...
    P2,E2,Input.Battery2,dt,Input.Battery2PackCount,Input.Environment.Temperature_C);
dcVoltage=Input.Motor.VoltageClass_V*ones(size(t));
dcNet=motorDC+auxiliaryPower; dcCurrent=1000*dcNet./max(dcVoltage,eps);
speedError=desiredSpeed-v;
Signals.Vehicle=struct('Speed_m_s',v,'DesiredSpeed_m_s',desiredSpeed, ...
    'SpeedError_m_s',speedError,'Acceleration_m_s2',a, ...
    'DesiredAcceleration_m_s2',desiredAcceleration,'Grade_pct',grade, ...
    'TractiveForce_N',deliveredDriveForce,'TractiveForceDemand_N',tractiveForceDemand, ...
    'Distance_m',distance,'LimitingCause',limitCause);
Signals.Wheel=struct('Demand_kW',wheelDemand,'Delivered_kW',wheelDelivered, ...
    'TotalDelivered_kW',deliveredDriveForce.*v/1000,'BrakingDemand_kW',brakingDemand, ...
    'RegenerativeBraking_kW',regenWheel,'FrictionBrakePower_kW',frictionBrake, ...
    'UnmetTraction_kW',unmetTraction,'UnmetBraking_kW',zeros(size(t)), ...
    'UnmetRegen_kW',frictionBrake);
Signals.Motors=struct('ElectricalPower_kW',motorDC,'MechanicalPower_kW',motorMechanical, ...
    'MotorSpeed_rpm',motorSpeed,'PairTorque_Nm',motorPairTorque, ...
    'PerMotorTorque_Nm',motorPairTorque/2,'LossPower_kW',motorLoss, ...
    'DrivingPowerLimit_kW',motorDriveLimit,'RegenerationPowerLimit_kW',motorRegenLimit);
Signals.Auxiliary=struct('Power_kW',auxiliaryPower);
Signals.Regeneration=struct('Available_kW',regenAvailable,'ToAuxiliary_kW',regenToAuxiliary, ...
    'ToActiveBattery_kW',regenToBattery,'ResistorLoadBank_kW',resistorLoad);
Signals.Battery1=battery_struct(P1,E1,Input.Battery1,b1V,b1I,b1D,b1C,b1DP,b1CP,b1OCV,b1R,b1Loss);
Signals.Battery2=battery_struct(P2,E2,Input.Battery2,b2V,b2I,b2D,b2C,b2DP,b2CP,b2OCV,b2R,b2Loss);
Signals.DCBus=struct('Voltage_V',dcVoltage,'Current_A',dcCurrent,'NetPower_kW',dcNet, ...
    'VoltageModel',"Nominal traction voltage class");
Signals.Genset=struct('ElectricalPower_kW',PGen,'MechanicalPower_kW',gensetMechanical, ...
    'FuelRate_L_s',fuelRate,'On',gensetOn,'StartEvent',starts, ...
    'ChargeDestinationBattery',gensetDestination);
if isBEV, standby=zeros(size(active)); connected=Input.TotalBatteryPackCount*ones(size(active));
else, standby=3-active; connected=Input.Battery1PackCount*ones(size(active)); end
Signals.Controller=struct('ActiveBattery',active,'StandbyBattery',standby,'Mode',mode, ...
    'ConnectedBatteryCount',connected,'BatteryRoleSwitchSOE',0.30*ones(size(t)));
Signals.Energy=struct('BalanceResidual_kW',residual,'UnmetDCPower_kW',unmetDC, ...
    'RejectedCharge_kW',rejectedCharge,'RejectedGensetCharge_kW',rejectedGensetCharge, ...
    'BatteryLoss_kW',batteryLoss);

R=table(t,desiredSpeed*3.6,grade,false(size(t)),auxMultiplier,distance, ...
    'VariableNames',{'Time_s','Speed_kmh','Grade_pct','StopFlag','AuxMultiplier','Distance_m'});
integrate=@(p)sum(p.*dt)/3600;
distanceKm=distance(end)/1000; catalogDistanceKm=reference.Distance_m(end)/1000;
fuelL=sum(fuelRate.*dt); gridEnergy=max(0,E1(1)-E1(end));
if ~isBEV || useBattery2, gridEnergy=gridEnergy+max(0,E2(1)-E2(end)); end
gridEnergy=gridEnergy/Input.Vehicle.GridChargeEfficiency;
fuelCost=fuelL*Input.Prices.FuelPrice_per_L;
electricCost=gridEnergy*Input.Prices.ElectricityPrice_per_kWh;
usableInitial=max(0,E1(1)-Input.Battery1.MinSOE*Input.Battery1.UsableEnergy_kWh);
if ~isBEV || useBattery2
    usableInitial=usableInitial+max(0,E2(1)-Input.Battery2.MinSOE*Input.Battery2.UsableEnergy_kWh);
end
energyPerKm=max(0.1,integrate(max(0,dcNet))/max(distanceKm,eps));
batteryRange=usableInitial/energyPerKm;
fuelPerKm=fuelL/max(distanceKm,eps);
if isBEV, fuelRange=0; else, fuelRange=Input.Vehicle.FuelTank_L/max(fuelPerKm,1e-9); end
movingTarget=desiredSpeed>Input.Performance.TargetMovingThreshold_m_s;
belowTarget=movingTarget & speedError>Input.Performance.SpeedTrackingTolerance_m_s;
nonNone=limitCause(limitCause~="None");
if isempty(nonNone), dominantLimit="None";
else
    [names,~,g]=unique(nonNone); counts=accumarray(g,1); [~,idx]=max(counts); dominantLimit=names(idx);
end
Summary=struct('RouteDistance_km',distanceKm,'RouteCatalogDistance_km',catalogDistanceKm, ...
    'RouteCompletion_pct',min(100,100*distanceKm/max(catalogDistanceKm,eps)), ...
    'RouteCompleted',completed,'DistanceShortfall_km',max(0,catalogDistanceKm-distanceKm), ...
    'ActualCompletionTime_s',t(end),'NominalRouteTime_s',Input.Route.Time_s(end), ...
    'MaximumAchievedSpeed_kmh',max(v)*3.6,'MaximumSpeedError_kmh',max(max(0,speedError))*3.6, ...
    'RMSSpeedError_kmh',sqrt(mean(speedError.^2))*3.6, ...
    'TimeBelowTarget_s',sum(belowTarget.*dt),'PerformanceLimitingCause',char(dominantLimit), ...
    'TerminationReason',char(terminationReason),'SimulationFormulation',char(formulation), ...
    'Fuel_L',fuelL,'Fuel_L_per_100km',100*fuelL/max(distanceKm,eps), ...
    'GridEquivalentEnergy_kWh',gridEnergy,'Electrical_kWh_per_km',gridEnergy/max(distanceKm,eps), ...
    'TotalSourceEnergy_kWh_per_km',(gridEnergy+integrate(gensetMechanical))/max(distanceKm,eps), ...
    'GensetElectricalEnergy_kWh',integrate(PGen),'BatteryThroughput_kWh',integrate(abs(P1)+abs(P2)), ...
    'BatteryOhmicLossEnergy_kWh',integrate(b1Loss+b2Loss), ...
    'RegeneratedEnergy_kWh',integrate(regenAvailable), ...
    'RegenerationToAuxiliaryEnergy_kWh',integrate(regenToAuxiliary), ...
    'RegenerationToActiveBatteryEnergy_kWh',integrate(regenToBattery), ...
    'ResistorLoadBankEnergy_kWh',integrate(resistorLoad), ...
    'WheelBrakingDemandEnergy_kWh',integrate(brakingDemand), ...
    'RegenerativeWheelBrakingEnergy_kWh',integrate(regenWheel), ...
    'FrictionBrakeEnergy_kWh',integrate(frictionBrake),'UnmetBrakingEnergy_kWh',0, ...
    'AuxiliaryEnergy_kWh',integrate(auxiliaryPower), ...
    'FinalBattery1SOE',E1(end)/Input.Battery1.UsableEnergy_kWh, ...
    'FinalBattery2SOE',E2(end)/Input.Battery2.UsableEnergy_kWh, ...
    'FuelCost',fuelCost,'ElectricCost',electricCost,'TotalOperatingCost',fuelCost+electricCost, ...
    'CostPer_km',(fuelCost+electricCost)/max(distanceKm,eps), ...
    'BatteryOnlyEquivalentRange_km',batteryRange,'FuelSupportedRange_km',fuelRange, ...
    'TotalMissionRange_km',batteryRange+fuelRange, ...
    'RouteRepeatEquivalentRange_km',floor((batteryRange+fuelRange)/max(catalogDistanceKm,eps))*catalogDistanceKm, ...
    'UnmetTractionEnergy_kWh',integrate(unmetTraction)+integrate(unmetDC), ...
    'EnergyBalanceError_kWh',integrate(abs(residual)), ...
    'GensetStarts',sum(starts),'GensetRuntime_s',sum(gensetOn.*dt), ...
    'EstimatedVehicleMass_kg',mass_kg,'ComponentMass_kg', ...
    Input.Mass.BatteryMass_kg+Input.Mass.GensetMass_kg+ ...
    2*Input.Motor.Mass_kg+2*Input.FinalDrive.Mass_kg, ...
    'BaseCurbMass_kg',Input.Mass.BaseCurbMass_kg,'InstalledBatteryMass_kg',Input.Mass.BatteryMass_kg, ...
    'InstalledGensetMass_kg',Input.Mass.GensetMass_kg,'CalculatedCurbMass_kg',Input.Mass.CurbMass_kg, ...
    'LoadMass_t',Input.Mass.LoadMass_t,'LoadMass_kg',Input.Mass.LoadMass_kg, ...
    'PowertrainMode',char(string(Input.PowertrainMode)), ...
    'BatterySetMultiplier',Input.BatterySetMultiplier,'Battery1PackCount',Input.Battery1PackCount, ...
    'Battery2PackCount',Input.Battery2PackCount,'TotalInstalledBatteryCount',Input.TotalBatteryPackCount, ...
    'ConnectedBatteryCount',connected(end));
warnings=strings(0,1);
if Summary.EnergyBalanceError_kWh>Input.Vehicle.EnergyBalanceTolerance_kWh
    warnings(end+1,1)="Energy balance tolerance exceeded";
end
if ~completed && ~Input.RepeatUntilDepleted, warnings(end+1,1)="Route not completed"; end
Results=struct('Metadata',struct('DatabaseFilename',Input.DatabaseFile, ...
    'DatabaseVersion',Input.DatabaseVersion,'MATLABRelease',version('-release'), ...
    'ModelVersion','2.0.0','SimulationTimestamp',datetime('now')), ...
    'SelectedConfiguration',Input.SelectedIDs,'InputParameters',Input,'Route',R,'Time',t, ...
    'Signals',Signals,'Summary',Summary,'Validation',struct('Warnings',warnings, ...
    'ConstraintViolations',warnings,'IsFeasible',isempty(warnings)));
end

function S=battery_struct(P,E,B,V,I,D,C,DP,CP,OCV,R,loss)
S=struct('Power_kW',P,'Energy_kWh',E,'SOE',E/B.UsableEnergy_kWh, ...
    'Voltage_V',V,'OpenCircuitVoltage_V',OCV,'Current_A',I, ...
    'Temperature_C',B.ConditionedTemperature_C*ones(size(P)), ...
    'InternalResistance_Ohm',R,'OhmicLoss_kW',loss, ...
    'DischargeCurrentLimit_A',D,'ChargeCurrentLimit_A',C, ...
    'DerivedDischargePowerCapability_kW',DP,'DerivedChargePowerCapability_kW',CP);
end

function [V,I,D,C,DP,CP,OCV,R,loss]=battery_signals(P,E,B,dt,packCount,temperature_C)
if packCount==0
    [V,I,D,C,DP,CP,OCV,R,loss]=deal(zeros(size(P))); return
end
n=numel(P); [V,I,D,C,DP,CP,OCV,R,loss]=deal(zeros(n,1));
for k=1:n
    [D(k),C(k),DP(k),CP(k),OCV(k),R(k)]=battery_current_capability( ...
        E(k),B,max(dt(k),eps),temperature_C);
    discriminant=max(0,OCV(k)^2-4*R(k)*1000*P(k));
    I(k)=(OCV(k)-sqrt(discriminant))/max(2*R(k),eps);
    V(k)=OCV(k)-I(k)*R(k); loss(k)=I(k)^2*R(k)/1000;
end
end
