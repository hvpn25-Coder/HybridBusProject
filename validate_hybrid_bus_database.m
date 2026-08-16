function Validation = validate_hybrid_bus_database(inputDatabase)
%VALIDATE_HYBRID_BUS_DATABASE Validate workbook schema and physical ranges.
if isstruct(inputDatabase)
    Database = inputDatabase;
else
    Database = load_hybrid_bus_database(string(inputDatabase));
end
required = ["Dashboard","Battery_Catalog","Motor_Catalog","Genset_Catalog", ...
    "Engine_Fuel_Map","Generator_Efficiency_Map","Tyre_Catalog", ...
    "Final_Drive_Catalog","Bus_Mass_Catalog","Vehicle_Parameters", ...
    "Aux_Load_Profiles","Route_Catalog","Route_Geometry","Route_Time_Speed","Route_Distance_Speed", ...
    "Route_Grade","Environment","Control_Calibration","Energy_Prices", ...
    "Optimization_Settings","Units_and_Definitions","Change_Log"];
errors = strings(0,1); warnings = strings(0,1);
for sheet = required
    if ~ismember(sheet,string(Database.SheetNames))
        errors(end+1,1) = "Missing required sheet: "+sheet; %#ok<AGROW>
    end
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
        'CumulativeDistance_km','GeometrySource','RetrievedUTC'};
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
    "Tyre_Catalog","Final_Drive_Catalog","Bus_Mass_Catalog", ...
    "Aux_Load_Profiles","Environment","Control_Calibration"];
for catalog = catalogs
    tableData = Database.(catalog);
    if ~ismember('ComponentID',tableData.Properties.VariableNames)
        errors(end+1,1) = catalog+" lacks ComponentID"; %#ok<AGROW>
    elseif numel(unique(tableData.ComponentID)) ~= height(tableData)
        errors(end+1,1) = catalog+" contains duplicate ComponentID values"; %#ok<AGROW>
    end
end

B = Database.Battery_Catalog;
badBattery = B.UsableEnergy_kWh<=0 | B.MaxDischarge_kW<=0 | ...
    B.MaxCharge_kW<=0 | B.MinSOE<0 | B.MaxSOE>1 | B.MinSOE>=B.MaxSOE | ...
    B.ChargeEfficiency<=0 | B.ChargeEfficiency>1 | ...
    B.DischargeEfficiency<=0 | B.DischargeEfficiency>1;
if any(badBattery), errors(end+1,1) = "Battery catalog contains invalid limits"; end
M = Database.Motor_Catalog;
if any(M.PeakPower_kW<M.ContinuousPower_kW | M.MaxSpeed_rpm<=M.BaseSpeed_rpm)
    errors(end+1,1) = "Motor catalog contains inconsistent ratings";
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
