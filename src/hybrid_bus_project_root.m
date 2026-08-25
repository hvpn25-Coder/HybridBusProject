function rootFolder=hybrid_bus_project_root()
%HYBRID_BUS_PROJECT_ROOT Return the repository root from the src folder.
rootFolder=fileparts(fileparts(mfilename('fullpath')));
end
