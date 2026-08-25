function slope_percent = compute_route_slope_percent(distance_km,elevation_m)
%COMPUTE_ROUTE_SLOPE_PERCENT Derive pointwise road grade from route elevation.
%   Grade is 100*d(elevation)/d(path distance). Repeated coordinate samples
%   receive zero segment grade so the visualization remains finite.

arguments
    distance_km (:,1) double {mustBeFinite,mustBeNonnegative}
    elevation_m (:,1) double {mustBeFinite}
end

if numel(distance_km)~=numel(elevation_m)
    error('HybridBus:RouteSlopeLengthMismatch', ...
        'Distance and elevation must have the same number of samples.');
end
if isempty(distance_km)
    slope_percent=zeros(0,1);
    return
end
if any(diff(distance_km)<0)
    error('HybridBus:RouteSlopeDistanceOrder', ...
        'Cumulative route distance must be nondecreasing.');
end
if isscalar(distance_km)
    slope_percent=0;
    return
end

distanceStep_m=1000*diff(distance_km);
elevationStep_m=diff(elevation_m);
segmentSlope=zeros(size(distanceStep_m));
moving=distanceStep_m>eps(max(distance_km(end)*1000,1));
segmentSlope(moving)=100*elevationStep_m(moving)./distanceStep_m(moving);

slope_percent=zeros(size(elevation_m));
slope_percent(1)=segmentSlope(1);
slope_percent(end)=segmentSlope(end);
if numel(elevation_m)>2
    slope_percent(2:end-1)=0.5*(segmentSlope(1:end-1)+segmentSlope(2:end));
end
end
