function [out,Input]=run_performance_simulink_model(databaseFile,overrides)
%RUN_PERFORMANCE_SIMULINK_MODEL Run the editable forward vehicle model.
arguments
    databaseFile (1,1) string = fullfile(hybrid_bus_project_root(), ...
        "data","HybridBus_ComponentDatabase.xlsx")
    overrides (1,1) struct = struct
end
overrides.SimulationFormulation="ForwardPerformance";
[Input,variables]=assign_hybrid_bus_model_workspace(databaseFile,overrides);
in=Simulink.SimulationInput("HybridBus_PerformanceModel");
names=fieldnames(variables);
for index=1:numel(names)
    in=in.setVariable(names{index},variables.(names{index}));
end
stopTime=max(Input.Route.Time_s(end)*Input.Performance.MaximumDurationFactor, ...
    Input.Route.Time_s(end)+Input.Performance.MaximumExtraTime_s);
in=in.setModelParameter('StopTime',num2str(stopTime), ...
    'SolverType','Fixed-step','FixedStep',num2str(variables.model_sample_time_s));
out=sim(in);
end
