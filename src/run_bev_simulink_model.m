function [simulationOutput,Input] = run_bev_simulink_model(databaseFile,batterySetMultiplier,initialSOE)
%RUN_BEV_SIMULINK_MODEL Configure and run the editable BEV Simulink model.
arguments
    databaseFile (1,1) string = fullfile(hybrid_bus_project_root(), ...
        "data","HybridBus_ComponentDatabase.xlsx")
    batterySetMultiplier (1,1) double {mustBeGreaterThanOrEqual(batterySetMultiplier,0.5)} = 1
    initialSOE (1,1) double {mustBeGreaterThanOrEqual(initialSOE,0.10), ...
        mustBeLessThanOrEqual(initialSOE,0.95)} = 0.85
end
assert(abs(2*batterySetMultiplier-round(2*batterySetMultiplier))<=1e-9, ...
    'HybridBus:InvalidBEVBatterySetMultiplier', ...
    'BEV batterySetMultiplier must use 0.5-set increments.');
if strlength(databaseFile)==0
    databaseFile=fullfile(hybrid_bus_project_root(),"data", ...
        "HybridBus_ComponentDatabase.xlsx");
end
overrides=struct('PowertrainMode',"BEV",'BatterySetMultiplier',batterySetMultiplier, ...
    'InitialBattery1SOE',initialSOE,'InitialBattery2SOE',initialSOE);
[Input,variables]=assign_hybrid_bus_model_workspace(databaseFile,overrides);
simulationInput=Simulink.SimulationInput("HybridBus_BEVModel");
variableNames=fieldnames(variables);
for index=1:numel(variableNames)
    simulationInput=simulationInput.setVariable(variableNames{index},variables.(variableNames{index}));
end
simulationInput=simulationInput.setModelParameter( ...
    'StopTime',num2str(variables.model_stop_time_s),'SolverType','Fixed-step', ...
    'FixedStep',num2str(variables.model_sample_time_s));
simulationOutput=sim(simulationInput);
end
