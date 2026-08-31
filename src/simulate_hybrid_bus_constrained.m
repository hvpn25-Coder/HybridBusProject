function Results=simulate_hybrid_bus_constrained(Input)
%SIMULATE_HYBRID_BUS_CONSTRAINED Fast acceleration-suppressed backward model.
% The backward energy kernel is iterated over an achievable speed trace.
% Route speed remains the time-indexed target; terrain and auxiliaries are
% sampled at actual distance. Positive battery power is discharge.

targetRoute=Input.Route;
targetSpeed_m_s=targetRoute.Speed_kmh/3.6;
catalogDistance_m=targetRoute.Distance_m(end);
workInput=Input;
workInput.SimulationFormulation="BackwardDemand";
workInput.RepeatUntilDepleted=false;

% Two backward/constraint passes are a deliberate speed/consistency trade:
% capability follows the updated energy state without a long forward run.
actualSpeed_m_s=zeros(height(targetRoute),1);
state=struct;
for iteration=1:2
    workInput.Route=route_from_actual_state(targetRoute,actualSpeed_m_s,state);
    workInput.RouteDistance_km=workInput.Route.Distance_m(end)/1000;
    backwardResult=simulate_hybrid_bus_core(workInput);
    state=integrate_limited_speed(Input,targetRoute,backwardResult);
    actualSpeed_m_s=state.Speed_m_s;
end

workInput.Route=route_from_actual_state(targetRoute,actualSpeed_m_s,state);
workInput.RouteDistance_km=workInput.Route.Distance_m(end)/1000;
Results=simulate_hybrid_bus_core(workInput);
Results.InputParameters=Input;
Results.Route=targetRoute;
Results.Route.Distance_m=state.Distance_m;

Results.Signals.Vehicle=struct( ...
    'Speed_m_s',state.Speed_m_s,'DesiredSpeed_m_s',targetSpeed_m_s, ...
    'SpeedError_m_s',targetSpeed_m_s-state.Speed_m_s, ...
    'Acceleration_m_s2',state.Acceleration_m_s2, ...
    'DesiredAcceleration_m_s2',state.DesiredAcceleration_m_s2, ...
    'Grade_pct',state.Grade_pct,'TractiveForce_N',state.DeliveredForce_N, ...
    'TractiveForceDemand_N',state.DemandForce_N,'Distance_m',state.Distance_m, ...
    'LimitingCause',state.LimitingCause);
Results.Signals.Wheel.Demand_kW=state.DemandForce_N.*state.Speed_m_s/1000;
Results.Signals.Wheel.TotalDelivered_kW=state.DeliveredForce_N.*state.Speed_m_s/1000;
Results.Signals.Wheel.UnmetTraction_kW=state.UnmetForce_N.*state.Speed_m_s/1000;

dt=[diff(targetRoute.Time_s);0];
distance_km=state.Distance_m(end)/1000;
catalogDistance_km=catalogDistance_m/1000;
completion_pct=min(100,100*distance_km/max(catalogDistance_km,eps));
completed=completion_pct>=99.5 || ...
    catalogDistance_m-state.Distance_m(end)<=Input.Performance.CompletionTolerance_m;
speedError=targetSpeed_m_s-state.Speed_m_s;
movingTarget=targetSpeed_m_s>Input.Performance.TargetMovingThreshold_m_s;
belowTarget=movingTarget & speedError>Input.Performance.SpeedTrackingTolerance_m_s;
dominantLimit=dominant_cause(state.LimitingCause);
terminationReason="Route time horizon ended before distance completion";
if completed
    terminationReason="Route completed within the route time horizon";
elseif sustained_stop(state.Speed_m_s,targetSpeed_m_s,Input.Performance,dt)
    terminationReason="Vehicle stopped: available battery/motor force cannot follow the route";
end

Results.Summary.RouteDistance_km=distance_km;
Results.Summary.RouteCatalogDistance_km=catalogDistance_km;
Results.Summary.RouteCompletion_pct=completion_pct;
Results.Summary.RouteCompleted=completed;
Results.Summary.DistanceShortfall_km=max(0,catalogDistance_km-distance_km);
Results.Summary.ActualCompletionTime_s=targetRoute.Time_s(end)-targetRoute.Time_s(1);
Results.Summary.NominalRouteTime_s=targetRoute.Time_s(end)-targetRoute.Time_s(1);
Results.Summary.MaximumAchievedSpeed_kmh=max(state.Speed_m_s)*3.6;
Results.Summary.MaximumSpeedError_kmh=max(max(0,speedError))*3.6;
Results.Summary.RMSSpeedError_kmh=sqrt(mean(speedError.^2))*3.6;
Results.Summary.TimeBelowTarget_s=sum(belowTarget.*dt);
Results.Summary.PerformanceLimitingCause=char(dominantLimit);
Results.Summary.TerminationReason=char(terminationReason);
Results.Summary.SimulationFormulation='ConstrainedBackward';
Results.Summary.UnmetTractionEnergy_kWh=sum( ...
    Results.Signals.Wheel.UnmetTraction_kW.*dt)/3600+ ...
    sum(Results.Signals.Energy.UnmetDCPower_kW.*dt)/3600;

warnings=string(Results.Validation.Warnings(:));
warnings=warnings(~contains(warnings,"Unmet traction/DC energy present"));
if ~completed, warnings(end+1,1)="Constrained route-time pass did not cover the full catalog distance"; end
if any(belowTarget), warnings(end+1,1)="Achieved speed fell below the route target"; end
Results.Validation.Warnings=unique(warnings,'stable');
Results.Validation.ConstraintViolations=Results.Validation.Warnings;
Results.Validation.IsFeasible=completed && ...
    Results.Summary.EnergyBalanceError_kWh<=Input.Vehicle.EnergyBalanceTolerance_kWh;
end

function route=route_from_actual_state(targetRoute,speed_m_s,state)
route=targetRoute;
route.Speed_kmh=3.6*speed_m_s;
route.Distance_m=cumtrapz(route.Time_s,speed_m_s);
if ~isempty(fieldnames(state))
    route.Distance_m=state.Distance_m;
    route.Grade_pct=state.Grade_pct;
    route.AuxMultiplier=state.AuxMultiplier;
end
end

function state=integrate_limited_speed(Input,targetRoute,capabilityResult)
n=height(targetRoute); dt=[diff(targetRoute.Time_s);0];
targetSpeed=targetRoute.Speed_kmh/3.6;
[distanceReference,gradeReference,auxReference]=distance_references(targetRoute);
speed=zeros(n,1); acceleration=zeros(n,1); desiredAcceleration=zeros(n,1);
distance=zeros(n,1); grade=zeros(n,1); auxiliary=zeros(n,1);
demandForce=zeros(n,1); deliveredForce=zeros(n,1); unmetForce=zeros(n,1);
cause=repmat("None",n,1);
mass=Input.Mass.TotalVehicleMass_kg;
isBEV=strcmpi(string(Input.PowertrainMode),"BEV");
discharge1=capabilityResult.Signals.Battery1.DerivedDischargePowerCapability_kW;
discharge2=capabilityResult.Signals.Battery2.DerivedDischargePowerCapability_kW;
active=capabilityResult.Signals.Controller.ActiveBattery;
if isBEV
    dischargeCapability=discharge1;
    if Input.Battery2PackCount>0, dischargeCapability=dischargeCapability+discharge2; end
else
    dischargeCapability=discharge1;
    dischargeCapability(active==2)=discharge2(active==2);
end
auxPower=capabilityResult.Signals.Auxiliary.Power_kW;
motorMechanical=capabilityResult.Signals.Motors.MechanicalPower_kW;
motorElectrical=capabilityResult.Signals.Motors.ElectricalPower_kW;
motorEfficiency=0.94*ones(n,1);
motoring=motorMechanical>0 & motorElectrical>0;
motorEfficiency(motoring)=min(0.99,max(0.70, ...
    motorMechanical(motoring)./motorElectrical(motoring)));

for index=1:n
    queryDistance=min(distanceReference(end),max(distanceReference(1),distance(index)));
    grade(index)=interp1(distanceReference,gradeReference,queryDistance,'linear','extrap');
    auxiliary(index)=interp1(distanceReference,auxReference,queryDistance,'linear','extrap');
    speedError=targetSpeed(index)-speed(index);
    desiredAcceleration(index)=min(Input.Performance.MaximumAcceleration_m_s2, ...
        max(-Input.Performance.MaximumDeceleration_m_s2, ...
        Input.Performance.DriverProportionalGain_s*speedError));
    theta=atan(grade(index)/100);
    roadLoad=mass*Input.Vehicle.Gravity_m_s2* ...
        Input.Tyre.RollingResistanceCoefficient*cos(theta)+ ...
        mass*Input.Vehicle.Gravity_m_s2*sin(theta)+ ...
        0.5*Input.Environment.AirDensity_kg_m3*Input.Vehicle.DragCoefficient* ...
        Input.Vehicle.FrontalArea_m2*max(0,speed(index)+Input.Environment.Headwind_m_s)^2;
    demandForce(index)=mass*desiredAcceleration(index)+roadLoad;
    if demandForce(index)>=0
        [motorForce,motorPowerLimit]=motor_force_limit(Input,speed(index));
        availableDC=max(0,dischargeCapability(index)-auxPower(index));
        batteryWheelPower=availableDC*motorEfficiency(index)*Input.FinalDrive.MotoringEfficiency;
        batteryForce=1000*batteryWheelPower/max(speed(index), ...
            Input.Performance.LowSpeedProtection_m_s);
        availableForce=min(motorForce,batteryForce);
        deliveredForce(index)=min(demandForce(index),max(0,availableForce));
        unmetForce(index)=max(0,demandForce(index)-deliveredForce(index));
        if unmetForce(index)>Input.Performance.StallForceMargin_N
            if batteryWheelPower+1e-6<motorPowerLimit*Input.FinalDrive.MotoringEfficiency
                cause(index)="Battery current/energy capability";
            else
                cause(index)="Motor torque-speed capability";
            end
        end
    else
        % Pneumatic/friction braking supplies any regeneration shortfall.
        deliveredForce(index)=demandForce(index);
    end
    if index<n
        acceleration(index)=(deliveredForce(index)-roadLoad)/mass;
        nextSpeed=max(0,speed(index)+acceleration(index)*dt(index));
        if speed(index)<=Input.Performance.ZeroSpeedThreshold_m_s && acceleration(index)<0
            acceleration(index)=0; nextSpeed=0;
        end
        speed(index+1)=nextSpeed;
        distance(index+1)=min(distanceReference(end), ...
            distance(index)+0.5*(speed(index)+nextSpeed)*dt(index));
    end
end
state=struct('Speed_m_s',speed,'Acceleration_m_s2',acceleration, ...
    'DesiredAcceleration_m_s2',desiredAcceleration,'Distance_m',distance, ...
    'Grade_pct',grade,'AuxMultiplier',auxiliary,'DemandForce_N',demandForce, ...
    'DeliveredForce_N',deliveredForce,'UnmetForce_N',unmetForce,'LimitingCause',cause);
end

function [wheelForce,mechanicalPowerLimit]=motor_force_limit(Input,speed)
omega=Input.FinalDrive.Ratio*speed/max(Input.Tyre.LoadedRadius_m,0.1);
rpm=omega*60/(2*pi);
torque=Input.Motor.PeakTorque_Nm;
if rpm>Input.Motor.BaseSpeed_rpm
    torque=min(torque,Input.Motor.PeakPower_kW*1000/max(omega,1));
end
if rpm>Input.Motor.MaxSpeed_rpm, torque=0; end
mechanicalPowerLimit=min(2*Input.Motor.PeakPower_kW,2*torque*omega/1000);
wheelForce=2*torque*Input.FinalDrive.Ratio*Input.FinalDrive.MotoringEfficiency/ ...
    max(Input.Tyre.LoadedRadius_m,0.1);
end

function [distance,grade,auxiliary]=distance_references(route)
rounded=round(max(0,route.Distance_m(:)),3);
[distance,~,groups]=unique(rounded,'stable');
grade=splitapply(@mean,route.Grade_pct(:),groups);
auxiliary=splitapply(@mean,route.AuxMultiplier(:),groups);
end

function value=dominant_cause(cause)
limited=cause(cause~="None");
if isempty(limited), value="None"; return; end
[names,~,groups]=unique(limited); counts=accumarray(groups,1);
[~,index]=max(counts); value=names(index);
end

function stopped=sustained_stop(speed,target,P,dt)
duration=0; stopped=false;
for index=1:numel(speed)
    if speed(index)<=P.ZeroSpeedThreshold_m_s && ...
            target(index)>P.TargetMovingThreshold_m_s
        duration=duration+dt(index);
        if duration>=P.StallDetectionTime_s, stopped=true; return; end
    else
        duration=0;
    end
end
end
