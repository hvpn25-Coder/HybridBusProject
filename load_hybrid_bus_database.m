function Database = load_hybrid_bus_database(databaseFile)
%LOAD_HYBRID_BUS_DATABASE Load the HybridBus Excel workbook into a structure.
arguments
    databaseFile (1,1) string = fullfile(fileparts(mfilename('fullpath')), ...
        "HybridBus_ComponentDatabase.xlsx")
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
if isfield(Database,'Change_Log') && ~isempty(Database.Change_Log)
    Database.Version = string(Database.Change_Log.Version(end));
else
    Database.Version = "unknown";
end
assert(isfield(Database,'Battery_Catalog') && height(Database.Battery_Catalog)>=1);
assert(isfield(Database,'Route_Time_Speed') && height(Database.Route_Time_Speed)>=2);
end

