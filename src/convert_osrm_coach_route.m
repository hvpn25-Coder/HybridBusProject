function [RouteTime,RouteDistance,Metadata] = convert_osrm_coach_route( ...
    sourceFile,routeID,routeName,routeType)
%CONVERT_OSRM_COACH_ROUTE Convert OSRM annotations to a coach time history.
% OpenStreetMap/OSRM distance and duration annotations define the geographic
% road corridor. The adaptation caps speed at 100 km/h, samples at 10 s, and
% inserts a 45 minute stationary break after each 4.5 h driving block.
arguments
    sourceFile (1,1) string
    routeID (1,1) string
    routeName (1,1) string
    routeType (1,1) string = "Long-distance coach"
end
assert(isfile(sourceFile),'HybridBus:RouteSourceMissing', ...
    'OSRM route source not found: %s',sourceFile);
payload = jsondecode(fileread(sourceFile));
assert(string(payload.RouteID)==routeID,'HybridBus:RouteSourceMismatch', ...
    'Expected route %s in %s.',routeID,sourceFile);
response = payload.OSRMResponse;
assert(string(response.code)=="Ok" && ~isempty(response.routes), ...
    'HybridBus:InvalidOSRMRoute','OSRM source does not contain a valid route.');
route = response.routes(1);
annotation = route.legs(1).annotation;
segmentDistance = double(annotation.distance(:));
segmentDuration = double(annotation.duration(:));
assert(numel(segmentDistance)==numel(segmentDuration), ...
    'HybridBus:InvalidOSRMRoute','OSRM annotation lengths do not match.');
nonzeroSegment = segmentDistance>0 | segmentDuration>0;
segmentDistance = segmentDistance(nonzeroSegment);
segmentDuration = segmentDuration(nonzeroSegment);
assert(numel(segmentDistance)>2 && all(isfinite(segmentDistance)) && ...
    all(segmentDistance>0) && all(isfinite(segmentDuration)) && ...
    all(segmentDuration>0), ...
    'HybridBus:InvalidOSRMRoute','OSRM segment annotations are invalid.');

maximumCoachSpeedMps = 100/3.6;
turnCostScale = max(1,double(route.duration)/sum(segmentDuration));
segmentDuration = segmentDuration*turnCostScale;
segmentDuration = max(segmentDuration,segmentDistance/maximumCoachSpeedMps);
segmentSpeed = segmentDistance./segmentDuration;
cumulativeDrivingTime = [0;cumsum(segmentDuration)];
cumulativeDistance = [0;cumsum(segmentDistance)];
drivingDuration = cumulativeDrivingTime(end);

drivingBlock = 4.5*3600;
breakDuration = 45*60;
numberOfBreaks = floor((drivingDuration-eps)/drivingBlock);
missionDuration = drivingDuration+numberOfBreaks*breakDuration;
sampleTime = 10;
time = (0:sampleTime:floor(missionDuration/sampleTime)*sampleTime)';
if time(end)<missionDuration
    time(end+1,1)=missionDuration;
end
workCycle = drivingBlock+breakDuration;
completeCycles = floor(time/workCycle);
cycleTime = time-completeCycles*workCycle;
drivingTime = completeCycles*drivingBlock+min(cycleTime,drivingBlock);
drivingTime = min(drivingTime,drivingDuration);
stopFlag = cycleTime>=drivingBlock & drivingTime<drivingDuration;
distance = interp1(cumulativeDrivingTime,cumulativeDistance,drivingTime,'linear');
speed = max(0,min(100,3.6*gradient(distance,time)));
speed(stopFlag)=0;
speed(end)=0;
stopFlag(end)=true;
for index=2:numel(speed)
    speed(index)=min(speed(index),speed(index-1)+3.6*1.0*(time(index)-time(index-1)));
end
for index=numel(speed)-1:-1:1
    speed(index)=min(speed(index),speed(index+1)+3.6*1.3*(time(index+1)-time(index)));
end
grade = zeros(size(time));
auxMultiplier = ones(size(time));
auxMultiplier(stopFlag)=1.15;

count = numel(time);
RouteTime = table(repmat(routeID,count,1),repmat(routeName,count,1), ...
    repmat(routeType,count,1),time,speed,grade,stopFlag,auxMultiplier, ...
    'VariableNames',{'RouteID','RouteName','RouteType','Time_s','Speed_kmh', ...
    'Grade_pct','StopFlag','AuxMultiplier'});

rawCount = numel(cumulativeDistance);
distanceSpeed = [segmentSpeed;segmentSpeed(end)]*3.6;
RouteDistance = table(repmat(routeID,rawCount,1),repmat(routeName,rawCount,1), ...
    repmat(routeType,rawCount,1),cumulativeDistance,distanceSpeed, ...
    zeros(rawCount,1),false(rawCount,1),ones(rawCount,1), ...
    'VariableNames',{'RouteID','RouteName','RouteType','Distance_m','Speed_kmh', ...
    'Grade_pct','StationFlag','AuxMultiplier'});

convertedDistance = trapz(time,speed/3.6);
Metadata = struct('Distance_km',double(route.distance)/1000, ...
    'ConvertedDistance_km',convertedDistance/1000,'Duration_s',missionDuration, ...
    'DrivingDuration_s',drivingDuration,'MaximumSpeed_kmh',max(speed), ...
    'AverageSpeed_kmh',3.6*double(route.distance)/missionDuration, ...
    'MandatoryBreaks',numberOfBreaks,'SourceSegments',numel(segmentDistance), ...
    'RetrievedUTC',string(payload.RetrievedUTC), ...
    'Conversion',"10 s coach adaptation; 100 km/h cap; 45 min break per 4.5 h driving; zero grade");
assert(abs(Metadata.ConvertedDistance_km-Metadata.Distance_km)/Metadata.Distance_km<0.002, ...
    'HybridBus:OSRMConversion','Converted route distance differs from OSRM by more than 0.2%%.');
end
