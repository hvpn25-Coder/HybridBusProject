function [RouteTime,RouteDistance,Metadata] = convert_vecto_distance_cycle( ...
    cycleFile,routeID,routeName,routeType)
%CONVERT_VECTO_DISTANCE_CYCLE Convert an official VECTO mission to 1 Hz.
% VECTO declaration cycles prescribe target speed and gradient by distance.
% This converter applies a deterministic, physically plausible bus driver
% (1.0 m/s^2 acceleration, 1.3 m/s^2 braking) and honors declared stops.
arguments
    cycleFile (1,1) string
    routeID (1,1) string
    routeName (1,1) string
    routeType (1,1) string
end
assert(isfile(cycleFile),'HybridBus:RouteSourceMissing', ...
    'VECTO source cycle not found: %s',cycleFile);
raw = readmatrix(cycleFile,'FileType','text','Delimiter',',','NumHeaderLines',1);
raw = raw(all(isfinite(raw(:,1:4)),2),:);
distanceRaw = raw(:,1);
speedRaw = raw(:,2);
gradeRaw = raw(:,3);
stopDuration = raw(:,4);
assert(numel(distanceRaw)>2 && all(diff(distanceRaw)>=0), ...
    'HybridBus:InvalidVECTOCycle','Cycle distance must be monotonic.');

dt = 1.0;
accelLimit = 1.0;
decelLimit = 1.3;
endDistance = distanceRaw(end);
stopIndices = find(stopDuration>0);
stopDistances = distanceRaw(stopIndices);
stopDurations = stopDuration(stopIndices);
stopServed = false(size(stopIndices));

capacity = max(1000,ceil(endDistance/4));
time = zeros(capacity,1);
speed = zeros(capacity,1);
grade = zeros(capacity,1);
stopFlag = false(capacity,1);
count = 1;
position = distanceRaw(1);
velocity = 0;
dwellRemaining = 0;
maxSteps = 100000;
while (position < endDistance-0.05 || velocity>0.1) && count < maxSteps
    if count>capacity
        capacity = 2*capacity;
        time(capacity,1)=0; speed(capacity,1)=0;
        grade(capacity,1)=0; stopFlag(capacity,1)=false;
    end
    time(count)=(count-1)*dt;
    speed(count)=velocity*3.6;
    grade(count)=interp1(distanceRaw,gradeRaw,position,'linear','extrap');

    nextStop = find(~stopServed & stopDistances>=position-0.05,1);
    if ~isempty(nextStop) && abs(stopDistances(nextStop)-position)<=0.05 && velocity<=0.1
        stopServed(nextStop)=true;
        dwellRemaining=max(dwellRemaining,stopDurations(nextStop));
    end
    if dwellRemaining>0
        stopFlag(count)=true;
        nextVelocity=0;
        dwellRemaining=max(0,dwellRemaining-dt);
        travel=0;
    else
        targetSampleDistance=min(endDistance,position+max(10,velocity*dt));
        targetVelocity=max(0,interp1(distanceRaw,speedRaw,targetSampleDistance, ...
            'linear','extrap')/3.6);
        nextStop=find(~stopServed & stopDistances>=position-0.05,1);
        snapToStop=false;
        if ~isempty(nextStop)
            distanceToStop=max(0,stopDistances(nextStop)-position);
            snapToStop=velocity<=0.1 && distanceToStop<=25.0;
            brakingDistance=velocity^2/(2*decelLimit)+velocity*dt;
            if distanceToStop<=brakingDistance
                targetVelocity=0;
            end
        end
        if snapToStop
            position=stopDistances(nextStop);
            nextVelocity=0;
            stopServed(nextStop)=true;
            dwellRemaining=stopDurations(nextStop);
            travel=0;
        else
            velocityChange=min(accelLimit*dt,max(-decelLimit*dt,targetVelocity-velocity));
            nextVelocity=max(0,velocity+velocityChange);
            travel=0.5*(velocity+nextVelocity)*dt;
            if ~isempty(nextStop) && travel>=stopDistances(nextStop)-position
                position=stopDistances(nextStop);
                travel=0;
            end
        end
    end
    position=min(endDistance,position+travel);
    velocity=nextVelocity;
    count=count+1;
end
assert(count<maxSteps,'HybridBus:VECTOConversion', ...
    'VECTO conversion exceeded the deterministic step limit at %.3f of %.3f m.', ...
    position,endDistance);
time(count)=(count-1)*dt;
speed(count)=0;
grade(count)=gradeRaw(end);
stopFlag(count)=true;

time=time(1:count);
speed=speed(1:count);
grade=grade(1:count);
stopFlag=stopFlag(1:count);
routeIDs=repmat(routeID,count,1);
routeNames=repmat(routeName,count,1);
routeTypes=repmat(routeType,count,1);
auxMultiplier=ones(count,1);
auxMultiplier(stopFlag)=1.10;
RouteTime=table(routeIDs,routeNames,routeTypes,time,speed,grade,stopFlag,auxMultiplier, ...
    'VariableNames',{'RouteID','RouteName','RouteType','Time_s','Speed_kmh', ...
    'Grade_pct','StopFlag','AuxMultiplier'});

rawCount=numel(distanceRaw);
RouteDistance=table(repmat(routeID,rawCount,1),repmat(routeName,rawCount,1), ...
    repmat(routeType,rawCount,1),distanceRaw,speedRaw,gradeRaw,stopDuration>0, ...
    1+0.10*(stopDuration>0), ...
    'VariableNames',{'RouteID','RouteName','RouteType','Distance_m','Speed_kmh', ...
    'Grade_pct','StationFlag','AuxMultiplier'});
Metadata=struct('Distance_km',endDistance/1000,'Duration_s',time(end), ...
    'MaximumSpeed_kmh',max(speed),'AverageSpeed_kmh',3.6*endDistance/max(time(end),eps), ...
    'DeclaredStops',numel(stopIndices),'SourcePoints',rawCount, ...
    'Conversion','1 Hz acceleration-limited conversion from distance-based VECTO target cycle');
end
