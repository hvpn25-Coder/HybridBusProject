function [RouteTime,RouteDistance,Metadata]=convert_osrm_city_route( ...
    sourceFile,routeID,routeName)
%CONVERT_OSRM_CITY_ROUTE Convert a geographic OSRM loop to an urban duty cycle.
arguments
    sourceFile (1,1) string
    routeID (1,1) string
    routeName (1,1) string
end
payload=jsondecode(fileread(sourceFile)); response=payload.OSRMResponse;
assert(string(payload.RouteID)==routeID && string(response.code)=="Ok", ...
    'HybridBus:InvalidOSRMCity','Invalid OSRM city source for %s.',routeID);
route=response.routes(1); segmentDistance=zeros(0,1); segmentDuration=zeros(0,1);
for legIndex=1:numel(route.legs)
    annotation=route.legs(legIndex).annotation;
    segmentDistance=[segmentDistance;double(annotation.distance(:))]; %#ok<AGROW>
    segmentDuration=[segmentDuration;double(annotation.duration(:))]; %#ok<AGROW>
end
valid=segmentDistance>0 & segmentDuration>0 & isfinite(segmentDistance) & isfinite(segmentDuration);
segmentDistance=segmentDistance(valid); segmentDuration=segmentDuration(valid);
assert(numel(segmentDistance)>2,'HybridBus:InvalidOSRMCity','Insufficient segments for %s.',routeID);

maximumUrbanSpeed=50/3.6;
turnCostScale=max(1,double(route.duration)/sum(segmentDuration));
segmentDuration=max(segmentDuration*turnCostScale,segmentDistance/maximumUrbanSpeed);
drivingTime=[0;cumsum(segmentDuration)]; drivingDistance=[0;cumsum(segmentDistance)];
stopDistance=(800:800:(drivingDistance(end)-400))'; dwellTime=20;
missionTime=drivingTime; missionDistance=drivingDistance;
for stopIndex=1:numel(stopDistance)
    driveStopTime=interp1(drivingDistance,drivingTime,stopDistance(stopIndex));
    shiftedStopTime=driveStopTime+(stopIndex-1)*dwellTime;
    future=missionTime>shiftedStopTime; missionTime(future)=missionTime(future)+dwellTime;
    insertIndex=find(missionTime>=shiftedStopTime,1);
    missionTime=[missionTime(1:insertIndex-1);shiftedStopTime; ...
        shiftedStopTime+dwellTime;missionTime(insertIndex:end)];
    missionDistance=[missionDistance(1:insertIndex-1);stopDistance(stopIndex); ...
        stopDistance(stopIndex);missionDistance(insertIndex:end)];
end
[missionTime,uniqueIndex]=unique(missionTime,'stable'); missionDistance=missionDistance(uniqueIndex);
time=(0:1:ceil(missionTime(end)))';
distance=interp1(missionTime,missionDistance,time,'linear','extrap');
speed=[0;diff(distance)]*3.6; speed=min(50,max(0,speed));
speedMps=speed/3.6;
for index=2:numel(speedMps)
    speedMps(index)=min(speedMps(index),speedMps(index-1)+1.0);
end
for index=numel(speedMps)-1:-1:1
    speedMps(index)=min(speedMps(index),speedMps(index+1)+1.3);
end
speed=3.6*speedMps;
distance=cumtrapz(time,speedMps);
stopFlag=speed<0.5; auxMultiplier=1+0.15*stopFlag; grade=zeros(size(time));
routeType=repmat("Geographic German city cycle",numel(time),1);
RouteTime=table(repmat(routeID,numel(time),1),repmat(routeName,numel(time),1), ...
    routeType,time,speed,grade,stopFlag,auxMultiplier, ...
    'VariableNames',{'RouteID','RouteName','RouteType','Time_s','Speed_kmh', ...
    'Grade_pct','StopFlag','AuxMultiplier'});
RouteDistance=table(repmat(routeID,numel(time),1),repmat(routeName,numel(time),1), ...
    routeType,distance,speed,grade,stopFlag,auxMultiplier, ...
    'VariableNames',{'RouteID','RouteName','RouteType','Distance_m','Speed_kmh', ...
    'Grade_pct','StationFlag','AuxMultiplier'});
Metadata=struct('Distance_km',distance(end)/1000,'Duration_s',time(end), ...
    'MaximumSpeed_kmh',max(speed),'RetrievedUTC',string(payload.RetrievedUTC));
end
