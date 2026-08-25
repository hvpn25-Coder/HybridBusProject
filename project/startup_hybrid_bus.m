function Project = startup_hybrid_bus()
%STARTUP_HYBRID_BUS Open or initialize the Hybrid Bus MATLAB project.
rootFolder = fileparts(fileparts(mfilename('fullpath')));
try
    Project = currentProject;
    if ~strcmpi(Project.RootFolder, rootFolder)
        close(Project);
        Project = openProject(rootFolder);
    end
catch
    projectFiles = dir(fullfile(rootFolder, '*.prj'));
    if ~isempty(projectFiles)
        Project = openProject(rootFolder);
    else
        Project = matlab.project.createProject(rootFolder);
        Project.Name = 'HybridBusProject';
    end
end

folders = {rootFolder,fullfile(rootFolder,'src'),fullfile(rootFolder,'models'), ...
    fullfile(rootFolder,'data'),fullfile(rootFolder,'project'), ...
    fullfile(rootFolder,'tests'),fullfile(rootFolder,'documentation')};
for index = 1:numel(folders)
    if isfolder(folders{index})
        addPath(Project, folders{index});
    end
end
Project.SimulinkCacheFolder = fullfile(rootFolder, 'work');
Project.SimulinkCodeGenFolder = fullfile(rootFolder, 'work');
Project.DependencyCacheFile = fullfile(rootFolder, 'work', 'dependency_cache.graphml');

databaseFile=fullfile(rootFolder,'data','HybridBus_ComponentDatabase.xlsx');
if ~isfile(databaseFile)
    create_default_database(databaseFile);
end
fprintf('HybridBusProject ready at %s\n', rootFolder);
end
