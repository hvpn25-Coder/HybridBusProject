function ElevationCache = build_route_elevation_cache(databaseFile,outputFile)
%BUILD_ROUTE_ELEVATION_CACHE Cache terrain elevation for geographic routes.
%   Elevation is sourced from the Open-Meteo Elevation API, which uses the
%   Copernicus DEM 2021 GLO-90 dataset. Up to 100 points are requested per
%   route and linearly interpolated along the stored geographic polyline.
arguments
    databaseFile (1,1) string = fullfile(hybrid_bus_project_root(), ...
        "data","HybridBus_ComponentDatabase.xlsx")
    outputFile (1,1) string = fullfile(hybrid_bus_project_root(), ...
        "documentation","reference_routes","elevation", ...
        "Route_Elevation_GLO90.csv")
end

Database = load_hybrid_bus_database(databaseFile);
Geometry = Database.Route_Geometry;
routeIDs = unique(Geometry.RouteID,'stable');
retrievedUTC = string(datetime('now','TimeZone','UTC', ...
    'Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));
parts = cell(numel(routeIDs),1);
options = weboptions('Timeout',60,'ContentType','json');

for routeIndex = 1:numel(routeIDs)
    routeID = routeIDs(routeIndex);
    routeGeometry = sortrows(Geometry(Geometry.RouteID==routeID,:),'Sequence');
    sampleCount = min(100,height(routeGeometry));
    sampleIndex = unique(round(linspace(1,height(routeGeometry),sampleCount)))';
    sampleElevation = requestElevation( ...
        routeGeometry.Latitude_deg(sampleIndex), ...
        routeGeometry.Longitude_deg(sampleIndex),options);
    elevation = interp1(routeGeometry.CumulativeDistance_km(sampleIndex), ...
        sampleElevation,routeGeometry.CumulativeDistance_km,'linear');
    parts{routeIndex} = table(routeGeometry.RouteID,routeGeometry.Sequence, ...
        elevation,repmat(retrievedUTC,height(routeGeometry),1), ...
        'VariableNames',{'RouteID','Sequence','Elevation_m','RetrievedUTC'});
    fprintf('Elevation %d/%d: %s (%d stored samples)\n', ...
        routeIndex,numel(routeIDs),routeID,height(routeGeometry));
    pause(2);
end

ElevationCache = vertcat(parts{:});
outputFolder = fileparts(outputFile);
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
writetable(ElevationCache,outputFile);
fprintf('Created %s with %d elevation rows.\n',outputFile,height(ElevationCache));
end

function elevation = requestElevation(latitude,longitude,options)
batchSize = 100;
elevation = NaN(size(latitude));
for firstIndex = 1:batchSize:numel(latitude)
    lastIndex = min(firstIndex+batchSize-1,numel(latitude));
    indices = firstIndex:lastIndex;
    latitudeText = strjoin(compose('%.6f',latitude(indices)),',');
    longitudeText = strjoin(compose('%.6f',longitude(indices)),',');
    url = "https://api.open-meteo.com/v1/elevation?latitude=" + ...
        latitudeText + "&longitude=" + longitudeText;
    response = requestWithRetry(url,options);
    values = double(response.elevation(:));
    assert(numel(values)==numel(indices) && all(isfinite(values)), ...
        'HybridBus:ElevationResponse', ...
        'Elevation service returned an invalid response.');
    elevation(indices) = values;
end
end

function response = requestWithRetry(url,options)
maximumAttempts = 4;
for attempt = 1:maximumAttempts
    try
        response = webread(url,options);
        return
    catch exception
        if attempt == maximumAttempts
            rethrow(exception)
        end
        pause(10*attempt);
    end
end
end
