function Sequence = run_powertrain_sequence(Database,overrides,runBoth,options)
%RUN_POWERTRAIN_SEQUENCE Run the selected mode or an ordered BEV/Hybrid pair.
arguments
    Database (1,1) struct
    overrides (1,1) struct = struct
    runBoth (1,1) logical = false
    options.ProgressFcn = []
    options.CancelFcn = []
end

validation=validate_hybrid_bus_database(Database);
assert(validation.IsValid,'HybridBus:InvalidDatabase', ...
    'Database validation failed:\n%s',strjoin(validation.Errors,newline));

if ~isfield(overrides,'PowertrainMode')
    overrides.PowertrainMode="Hybrid";
end
if runBoth
    multiplier=fieldValue(overrides,'BatterySetMultiplier',1);
    assert(multiplier>=1 && abs(multiplier-round(multiplier))<=1e-9, ...
        'HybridBus:ComparisonRequiresWholeBatterySets', ...
        ['BEV-then-Hybrid comparison requires a positive whole-number Battery set multiplier ' ...
        'because Hybrid mode cannot use half sets.']);
    runOrder=["BEV","Hybrid"];
else
    selectedMode=string(overrides.PowertrainMode);
    assert(any(selectedMode==["BEV","Hybrid"]), ...
        'HybridBus:InvalidPowertrainMode','PowertrainMode must be BEV or Hybrid.');
    runOrder=selectedMode;
end

results=cell(numel(runOrder),1);
sequenceBEV=[]; sequenceHybrid=[];
for index=1:numel(runOrder)
    if ~isempty(options.CancelFcn) && options.CancelFcn()
        error('HybridBus:PowertrainSequenceCancelled','Powertrain comparison was cancelled.');
    end
    mode=runOrder(index);
    if ~isempty(options.ProgressFcn)
        options.ProgressFcn(mode,index,numel(runOrder));
    end
    modeOverrides=overrides;
    modeOverrides.PowertrainMode=mode;
    if mode=="BEV"
        initialSOE=fieldValue(modeOverrides,'InitialBattery1SOE',0.85);
        modeOverrides.InitialBattery1SOE=initialSOE;
        modeOverrides.InitialBattery2SOE=initialSOE;
    end
    input=prepare_hybrid_bus_inputs(Database,modeOverrides);
    result=simulate_hybrid_bus_core(input);
    result.Validation.Database=validation;
    results{index}=result;
    if mode=="BEV", sequenceBEV=result;
    else, sequenceHybrid=result; end
end

Sequence=struct;
Sequence.RunOrder=runOrder;
Sequence.Results=results;
Sequence.BEV=sequenceBEV;
Sequence.Hybrid=sequenceHybrid;
Sequence.SelectedResult=results{end};
Sequence.IsComparison=runBoth;
Sequence.Timestamp=datetime('now');
end

function value=fieldValue(structure,name,defaultValue)
if isfield(structure,name), value=structure.(name);
else, value=defaultValue; end
end
