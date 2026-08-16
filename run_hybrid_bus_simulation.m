function Results = run_hybrid_bus_simulation(databaseFile, overrides, options)
%RUN_HYBRID_BUS_SIMULATION Validate inputs, run, postprocess, and save results.
arguments
    databaseFile (1,1) string = fullfile(fileparts(mfilename('fullpath')), ...
        "HybridBus_ComponentDatabase.xlsx")
    overrides (1,1) struct = struct
    options.SaveResults (1,1) logical = true
    options.ResultsFolder (1,1) string = fullfile(fileparts(mfilename('fullpath')),"results")
end
Database=load_hybrid_bus_database(databaseFile);
Validation=validate_hybrid_bus_database(Database);
assert(Validation.IsValid,'HybridBus:InvalidDatabase','Database validation failed:\n%s', ...
    strjoin(Validation.Errors,newline));
Input=prepare_hybrid_bus_inputs(Database,overrides);
Results=simulate_hybrid_bus_core(Input);
Results.Validation.Database=Validation;
if options.SaveResults
    export_hybrid_bus_results(Results,options.ResultsFolder);
end
end

