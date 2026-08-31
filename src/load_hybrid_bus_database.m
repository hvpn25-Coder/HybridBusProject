function Database = load_hybrid_bus_database(databaseFile)
%LOAD_HYBRID_BUS_DATABASE Load the HybridBus Excel workbook into a structure.
arguments
    databaseFile (1,1) string = fullfile(hybrid_bus_project_root(), ...
        "data","HybridBus_ComponentDatabase.xlsx")
end
assert(isfile(databaseFile),'HybridBus:DatabaseMissing', ...
    'Database file does not exist: %s',databaseFile);
sheetNames = sheetnames(databaseFile);
Database = struct;
Database.Filename = databaseFile;
Database.SheetNames = sheetNames;
for index = 1:numel(sheetNames)
    sheet = sheetNames(index);
    field = matlab.lang.makeValidName(sheet);
    if sheet == "Dashboard"
        raw = readcell(databaseFile,'Sheet',sheet);
        Dashboard = struct;
        for row = 2:size(raw,1)
            if ~ismissing(string(raw{row,1})) && strlength(string(raw{row,1})) > 0
                key = matlab.lang.makeValidName(string(raw{row,1}));
                Dashboard.(key) = raw{row,2};
            end
        end
        Database.Dashboard = Dashboard;
    else
        Database.(field) = readtable(databaseFile,'Sheet',sheet,'TextType','string', ...
            'VariableNamingRule','preserve');
    end
end
dataFolder=fileparts(databaseFile);
BatteryComponents=load_component_m_files(fullfile(dataFolder,'batteries'),"Battery");
MotorComponents=load_component_m_files(fullfile(dataFolder,'motors'),"Motor");
GensetComponents=load_genset_m_files(fullfile(dataFolder,'gensets'));
Database.BatteryFolder=BatteryComponents.Folder;
Database.BatteryFiles=BatteryComponents.Files;
Database.Battery_Catalog=BatteryComponents.Catalog;
Database.Battery_Maps=BatteryComponents.Maps;
Database.MotorFolder=MotorComponents.Folder;
Database.MotorFiles=MotorComponents.Files;
Database.Motor_Catalog=MotorComponents.Catalog;
Database.Motor_Maps=MotorComponents.Maps;
Database.GensetFolder=GensetComponents.Folder;
Database.GensetFiles=GensetComponents.Files;
Database.Genset_Catalog=GensetComponents.GensetCatalog;
Database.Engine_Catalog=GensetComponents.EngineCatalog;
Database.Generator_Catalog=GensetComponents.GeneratorCatalog;
Database.Genset_Assembly=GensetComponents.AssemblyCatalog;
Database.Engine_Fuel_Map=GensetComponents.EngineFuelMap;
Database.Generator_Efficiency_Map=GensetComponents.GeneratorEfficiencyMap;
routeFolder=fullfile(fileparts(databaseFile),'routes');
Routes=load_route_mat_files(routeFolder);
Database.RouteFolder=Routes.Folder;
Database.RouteFiles=Routes.Files;
Database.Route_Catalog=Routes.Catalog;
Database.Route_Time_Speed=Routes.TimeSpeed;
Database.Route_Distance_Speed=Routes.DistanceSpeed;
Database.Route_Grade=Routes.Grade;
Database.Route_Geometry=Routes.Geometry;
if isfield(Database,'Change_Log') && ~isempty(Database.Change_Log)
    Database.Version = string(Database.Change_Log.Version(end));
else
    Database.Version = "unknown";
end
assert(isfield(Database,'Battery_Catalog') && height(Database.Battery_Catalog)>=1);
assert(isfield(Database,'Route_Time_Speed') && height(Database.Route_Time_Speed)>=2);
end
