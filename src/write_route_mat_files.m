function files=write_route_mat_files(routeFolder,RouteCatalog,RouteTime, ...
    RouteDistance,RouteGrade,RouteGeometry)
%WRITE_ROUTE_MAT_FILES Store each route as one self-contained MAT file.
arguments
    routeFolder (1,1) string
    RouteCatalog table
    RouteTime table
    RouteDistance table
    RouteGrade table
    RouteGeometry table
end

if ~isfolder(routeFolder),mkdir(routeFolder);end
existing=dir(fullfile(routeFolder,'*.mat'));
for index=1:numel(existing)
    delete(fullfile(existing(index).folder,existing(index).name));
end

files=strings(height(RouteCatalog),1);
for index=1:height(RouteCatalog)
    routeID=string(RouteCatalog.RouteID(index));
    safeName=regexprep(routeID,'[^A-Za-z0-9_.-]','_');
    files(index)=fullfile(routeFolder,safeName+'.mat');
    RouteData=struct( ...
        'SchemaVersion',"1.0.0", ...
        'StorageOrder',index, ...
        'Metadata',RouteCatalog(index,:), ...
        'TimeSpeed',RouteTime(RouteTime.RouteID==routeID,:), ...
        'DistanceSpeed',RouteDistance(RouteDistance.RouteID==routeID,:), ...
        'Grade',RouteGrade(RouteGrade.RouteID==routeID,:), ...
        'Geometry',RouteGeometry(RouteGeometry.RouteID==routeID,:));
    assert(height(RouteData.TimeSpeed)>=2,'HybridBus:RouteMatTimeData', ...
        'Route %s has insufficient time-domain data.',routeID);
    save(files(index),'RouteData','-v7.3');
end
end
