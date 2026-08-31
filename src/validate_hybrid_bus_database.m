function Validation = validate_hybrid_bus_database(inputDatabase)
%VALIDATE_HYBRID_BUS_DATABASE Validate workbook schema and physical ranges.
if isstruct(inputDatabase)
    Database = inputDatabase;
else
    Database = load_hybrid_bus_database(string(inputDatabase));
end
required = ["Dashboard","Tyre_Catalog", ...
    "Final_Drive_Catalog","Bus_Mass_Catalog","Vehicle_Parameters", ...
    "Aux_Load_Profiles","Environment","Control_Calibration","Energy_Prices", ...
    "Optimization_Settings","Units_and_Definitions","Change_Log"];
errors = strings(0,1); warnings = strings(0,1);
for sheet = required
    if ~ismember(sheet,string(Database.SheetNames))
        errors(end+1,1) = "Missing required sheet: "+sheet; %#ok<AGROW>
    end
end
requiredComponentFields=["Battery_Catalog","Motor_Catalog","Genset_Catalog", ...
    "Engine_Catalog","Generator_Catalog","Engine_Fuel_Map", ...
    "Generator_Efficiency_Map","BatteryFiles","Battery_Maps", ...
    "MotorFiles","GensetFiles","Genset_Assembly"];
for field=requiredComponentFields
    if ~isfield(Database,field)
        errors(end+1,1)="Missing MATLAB component-file dataset: "+field; %#ok<AGROW>
    end
end
requiredRouteFields=["Route_Catalog","Route_Geometry","Route_Time_Speed", ...
    "Route_Distance_Speed","Route_Grade","RouteFiles"];
for field=requiredRouteFields
    if ~isfield(Database,field)
        errors(end+1,1)="Missing per-route MAT-file dataset: "+field; %#ok<AGROW>
    end
end
if ~isempty(errors)
    Validation=finish(false,errors,warnings);
    return
end
if numel(Database.RouteFiles)~=height(Database.Route_Catalog) || ...
        any(~isfile(Database.RouteFiles))
    errors(end+1,1)="Route MAT-file index does not match Route_Catalog";
end
if numel(Database.BatteryFiles)~=height(Database.Battery_Catalog) || ...
        any(~isfile(Database.BatteryFiles))
    errors(end+1,1)="Battery MATLAB-file index does not match Battery_Catalog";
end
if numel(Database.Battery_Maps)~=height(Database.Battery_Catalog)
    errors(end+1,1)="Battery dynamic-map index does not match Battery_Catalog";
else
    mapIDs=string({Database.Battery_Maps.ComponentID});
    if numel(unique(mapIDs))~=numel(mapIDs) || ...
            ~all(ismember(string(Database.Battery_Catalog.ComponentID),mapIDs))
        errors(end+1,1)="Battery dynamic maps contain missing or duplicate ComponentID values";
    end
end
if numel(Database.MotorFiles)~=height(Database.Motor_Catalog) || ...
        any(~isfile(Database.MotorFiles))
    errors(end+1,1)="Motor MATLAB-file index does not match Motor_Catalog";
end
if numel(Database.GensetFiles)~=height(Database.Genset_Catalog) || ...
        any(~isfile(Database.GensetFiles))
    errors(end+1,1)="Genset MATLAB-file index does not match Genset_Catalog";
end
if height(Database.Engine_Catalog)~=height(Database.Genset_Catalog) || ...
        height(Database.Generator_Catalog)~=height(Database.Genset_Catalog)
    errors(end+1,1)="Genset assembly catalogs have inconsistent row counts";
end
assembly=Database.Genset_Assembly;
requiredAssemblyColumns={'GensetID','EngineID','GeneratorID'};
if ~all(ismember(requiredAssemblyColumns,assembly.Properties.VariableNames)) || ...
        height(assembly)~=height(Database.Genset_Catalog) || ...
        numel(unique(lower(string(assembly.GensetID))))~=height(assembly) || ...
        ~all(ismember(lower(string(Database.Genset_Catalog.ComponentID)), ...
        lower(string(assembly.GensetID)))) || ...
        ~all(ismember(lower(string(assembly.EngineID)), ...
        lower(string(Database.Engine_Catalog.ComponentID)))) || ...
        ~all(ismember(lower(string(assembly.GeneratorID)), ...
        lower(string(Database.Generator_Catalog.ComponentID))))
    errors(end+1,1)="Genset assembly links are incomplete or inconsistent";
end
mapGensets=unique(string(Database.Engine_Fuel_Map.GensetID));
generatorMapGensets=unique(string(Database.Generator_Efficiency_Map.GensetID));
if ~all(ismember(string(Database.Genset_Catalog.ComponentID),mapGensets)) || ...
        ~all(ismember(string(Database.Genset_Catalog.ComponentID),generatorMapGensets))
    errors(end+1,1)="One or more gensets lack an engine or generator performance map";
end
if isfield(Database,'Route_Catalog') && isfield(Database,'Route_Time_Speed')
    routeCatalog=Database.Route_Catalog;
    if numel(unique(routeCatalog.RouteID))~=height(routeCatalog)
        errors(end+1,1)="Route_Catalog contains duplicate RouteID values";
    end
    listedRoutes=unique(Database.Route_Time_Speed.RouteID,'stable');
    if ~all(ismember(routeCatalog.RouteID,listedRoutes))
        errors(end+1,1)="Route_Catalog references routes missing from Route_Time_Speed";
    end
end
if isfield(Database,'Route_Catalog') && isfield(Database,'Route_Geometry')
    routeCatalog=Database.Route_Catalog; geometry=Database.Route_Geometry;
    requiredGeometryColumns={'RouteID','Sequence','Latitude_deg','Longitude_deg', ...
        'CumulativeDistance_km','Elevation_m','GeometrySource','RetrievedUTC', ...
        'ElevationSource','ElevationRetrievedUTC'};
    if ~all(ismember(requiredGeometryColumns,geometry.Properties.VariableNames))
        errors(end+1,1)="Route_Geometry lacks required coordinate/provenance columns";
    else
        geographicIDs=routeCatalog.RouteID(logical(routeCatalog.HasGeolocation));
        if ~all(ismember(geographicIDs,unique(geometry.RouteID)))
            errors(end+1,1)="Route_Catalog marks routes geographic that are missing from Route_Geometry";
        end
        if any(~isfinite(geometry.Latitude_deg) | geometry.Latitude_deg<-90 | geometry.Latitude_deg>90 | ...
                ~isfinite(geometry.Longitude_deg) | geometry.Longitude_deg<-180 | geometry.Longitude_deg>180)
            errors(end+1,1)="Route_Geometry contains invalid latitude/longitude values";
        end
        if any(~isfinite(geometry.Elevation_m) | geometry.Elevation_m < -500 | ...
                geometry.Elevation_m > 9000)
            errors(end+1,1)="Route_Geometry contains invalid terrain elevation values";
        end
        for routeID=unique(geometry.RouteID,'stable')'
            G=geometry(geometry.RouteID==routeID,:);
            if height(G)<2 || any(diff(G.Sequence)<=0) || any(diff(G.CumulativeDistance_km)<0)
                errors(end+1,1)=routeID+": invalid geometry sequence or distance"; %#ok<AGROW>
            end
        end
    end
end
if ~isempty(errors)
    Validation = finish(false,errors,warnings);
    return
end

catalogs = ["Battery_Catalog","Motor_Catalog","Genset_Catalog", ...
    "Engine_Catalog","Generator_Catalog", ...
    "Tyre_Catalog","Final_Drive_Catalog","Bus_Mass_Catalog", ...
    "Aux_Load_Profiles","Environment","Control_Calibration"];
for catalog = catalogs
    tableData = Database.(catalog);
    if ~ismember('ComponentID',tableData.Properties.VariableNames)
        errors(end+1,1) = catalog+" lacks ComponentID"; %#ok<AGROW>
    elseif numel(unique(lower(string(tableData.ComponentID)))) ~= height(tableData)
        errors(end+1,1) = catalog+" contains duplicate ComponentID values"; %#ok<AGROW>
    end
end

B = Database.Battery_Catalog;
badBattery = B.UsableEnergy_kWh<=0 | B.ReferenceDischargeCurrent_A<=0 | ...
    B.ReferenceChargeCurrent_A<=0 | B.MinSOE<0 | B.MaxSOE>1 | B.MinSOE>=B.MaxSOE | ...
    B.ChargeEfficiency<=0 | B.ChargeEfficiency>1 | ...
    B.DischargeEfficiency<=0 | B.DischargeEfficiency>1;
if any(badBattery), errors(end+1,1) = "Battery catalog contains invalid limits"; end
for mapIndex=1:numel(Database.Battery_Maps)
    map=Database.Battery_Maps(mapIndex);
    row=B(string(B.ComponentID)==string(map.ComponentID),:);
    expectedSize=[numel(map.TemperatureBreakpoints_C),numel(map.SOEBreakpoints)];
    if ~isequal(size(map.MaxDischargeCurrentMap_A),expectedSize) || ...
            ~isequal(size(map.MaxChargeCurrentMap_A),expectedSize) || ...
            ~isequal(size(map.OpenCircuitVoltageMap_V),expectedSize) || ...
            ~isequal(size(map.InternalResistanceMap_Ohm),expectedSize) || ...
            any(map.MaxDischargeCurrentMap_A<0,'all') || ...
            any(map.MaxChargeCurrentMap_A<0,'all') || ...
            any(map.OpenCircuitVoltageMap_V<=row.MinVoltage_V(1),'all') || ...
            any(map.OpenCircuitVoltageMap_V>=row.MaxVoltage_V(1),'all') || ...
            any(map.InternalResistanceMap_Ohm<=0,'all')
        errors(end+1,1)=string(map.ComponentID)+": invalid dynamic battery-map dimensions or values"; %#ok<AGROW>
    end
end
M = Database.Motor_Catalog;
if any(M.PeakPower_kW<M.ContinuousPower_kW | M.MaxSpeed_rpm<=M.BaseSpeed_rpm)
    errors(end+1,1) = "Motor catalog contains inconsistent ratings";
end
for mapIndex=1:numel(Database.Motor_Maps)
    map=Database.Motor_Maps(mapIndex);
    expectedSize=[numel(map.SpeedBreakpoints_rpm),numel(map.TorqueBreakpoints_Nm)];
    if ~isequal(size(map.MotorLossMap_kW),expectedSize) || ...
            any(map.MotorLossMap_kW<0,'all') || ...
            any(~isfinite(map.MotorLossMap_kW),'all') || ...
            map.MotorLossMap_kW(1,1)~=0
        errors(end+1,1)=string(map.ComponentID)+": invalid motor torque-speed loss map"; %#ok<AGROW>
    end
end
L = Database.Bus_Mass_Catalog;
if ~ismember('TotalVehicleMass_kg',L.Properties.VariableNames)
    errors(end+1,1) = "Bus mass catalog lacks TotalVehicleMass_kg";
elseif any(~isfinite(L.TotalVehicleMass_kg) | L.TotalVehicleMass_kg<=0)
    errors(end+1,1) = "Bus mass catalog contains invalid total vehicle mass";
end

routeIDs = unique(Database.Route_Time_Speed.RouteID,'stable');
for routeID = routeIDs'
    R = Database.Route_Time_Speed(Database.Route_Time_Speed.RouteID==routeID,:);
    if height(R)<2 || R.Time_s(end)<=R.Time_s(1)
        errors(end+1,1) = routeID+": zero-duration route"; %#ok<AGROW>
        continue
    end
    if any(~isfinite(R.Time_s)) || any(~isfinite(R.Speed_kmh)) || any(~isfinite(R.Grade_pct))
        errors(end+1,1) = routeID+": missing/non-finite route values"; %#ok<AGROW>
    end
    if any(diff(R.Time_s)<=0), errors(end+1,1) = routeID+": non-monotonic or duplicate time"; end %#ok<AGROW>
    if any(R.Speed_kmh<0), errors(end+1,1) = routeID+": negative speed"; end %#ok<AGROW>
    dt = diff(R.Time_s); dv = diff(R.Speed_kmh/3.6);
    if any(dt>30), warnings(end+1,1) = routeID+": sample interval exceeds 30 s"; end %#ok<AGROW>
    if any(abs(dv./dt)>3.0), warnings(end+1,1) = routeID+": acceleration exceeds 3 m/s^2"; end %#ok<AGROW>
    if trapz(R.Time_s,R.Speed_kmh/3.6)<=0
        errors(end+1,1) = routeID+": zero-distance route"; %#ok<AGROW>
    end
end
Validation = finish(isempty(errors),errors,warnings);
end

function result = finish(valid,errors,warnings)
result = struct('IsValid',valid,'Errors',errors,'Warnings',warnings, ...
    'Timestamp',datetime('now'));
if ~valid
    warning('HybridBus:InvalidDatabase','Database validation found %d error(s).',numel(errors));
end
end
