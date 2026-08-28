function Assessment = assess_matlab_simulink_equivalence(databaseFile,overrides)
%ASSESS_MATLAB_SIMULINK_EQUIVALENCE Compare independent model implementations.
arguments
    databaseFile (1,1) string = fullfile(hybrid_bus_project_root(), ...
        "data","HybridBus_ComponentDatabase.xlsx")
    overrides (1,1) struct = struct
end

[Input,variables]=assign_hybrid_bus_model_workspace(databaseFile,overrides);
MatlabResult=simulate_hybrid_bus_core(Input);
if strcmpi(string(Input.PowertrainMode),"BEV")
    modelName="HybridBus_BEVModel";
else
    modelName="HybridBus_BackwardModel";
end
in=Simulink.SimulationInput(modelName);
names=fieldnames(variables);
for index=1:numel(names)
    in=in.setVariable(names{index},variables.(names{index}));
end
in=in.setModelParameter('StopTime',num2str(variables.model_stop_time_s), ...
    'SolverType','Fixed-step','FixedStep',num2str(variables.model_sample_time_s));
out=sim(in);

t=MatlabResult.Time(:);
checks={ ...
    'Vehicle speed','log_vehicle_speed',MatlabResult.Signals.Vehicle.Speed_m_s,0.02,'m/s'; ...
    'Wheel demand','log_wheel_power',MatlabResult.Signals.Wheel.Demand_kW,5.0,'kW'; ...
    'Motor DC power','log_motor_dc_power',MatlabResult.Signals.Motors.ElectricalPower_kW,8.0,'kW'; ...
    'Pneumatic friction brake','log_friction_brake_power', ...
        MatlabResult.Signals.Wheel.FrictionBrakePower_kW,5.0,'kW'; ...
    'Auxiliary power','log_aux_power',MatlabResult.Signals.Auxiliary.Power_kW,0.05,'kW'; ...
    'Battery 1 SOE','log_battery1_soe',MatlabResult.Signals.Battery1.SOE,0.025,'fraction'; ...
    'Battery 2 SOE','log_battery2_soe',MatlabResult.Signals.Battery2.SOE,0.025,'fraction'; ...
    'Genset power','log_genset_power',MatlabResult.Signals.Genset.ElectricalPower_kW,1.0,'kW'};
n=size(checks,1); signal=strings(n+2,1); maxAbs=zeros(n+2,1); rmsError=zeros(n+2,1);
tolerance=zeros(n+2,1); unit=strings(n+2,1); status=strings(n+2,1);
for index=1:n
    signal(index)=checks{index,1};
    simData=sampleOutput(out,checks{index,2},t);
    delta=simData-checks{index,3}(:);
    maxAbs(index)=max(abs(delta)); rmsError(index)=sqrt(mean(delta.^2));
    tolerance(index)=checks{index,4}; unit(index)=checks{index,5};
    status(index)=passFail(maxAbs(index)<=tolerance(index));
end

dt=[diff(t);0];
simFuel=sampleOutput(out,'log_fuel_rate',t);
matlabFuel=sum(MatlabResult.Signals.Genset.FuelRate_L_s.*dt);
simulinkFuel=sum(simFuel.*dt);
index=n+1; signal(index)="Total fuel"; maxAbs(index)=abs(simulinkFuel-matlabFuel);
rmsError(index)=maxAbs(index); tolerance(index)=0.10; unit(index)="L";
status(index)=passFail(maxAbs(index)<=tolerance(index));

simResidual=sampleOutput(out,'log_balance_residual',t);
index=n+2; signal(index)="Energy-balance integral";
maxAbs(index)=sum(abs(simResidual).*dt)/3600; rmsError(index)=sqrt(mean(simResidual.^2));
tolerance(index)=0.01; unit(index)="kWh";
status(index)=passFail(maxAbs(index)<=tolerance(index));

Assessment=struct;
Assessment.SignalChecks=table(signal,maxAbs,rmsError,tolerance,unit,status, ...
    'VariableNames',{'Signal','MaxAbsoluteError','RMSError','Tolerance','Unit','Status'});
Assessment.OverallStatus=passFail(all(status=="PASS"));
Assessment.MatlabResult=MatlabResult;
Assessment.SimulinkOutput=out;
Assessment.Note="Equivalence establishes agreement between implementations; it is not measured-vehicle validation.";
end

function values=sampleOutput(out,name,targetTime)
series=out.get(name);
if isa(series,'timeseries')
    sourceTime=series.Time(:); sourceData=double(series.Data(:));
    if isscalar(sourceTime)
        values=repmat(sourceData(1),size(targetTime));
    else
        values=interp1(sourceTime,sourceData,targetTime,'previous','extrap');
    end
elseif isstruct(series) && isfield(series,'time') && isfield(series,'signals')
    sourceTime=series.time(:); sourceData=double(series.signals.values(:));
    if isscalar(sourceTime)
        values=repmat(sourceData(1),size(targetTime));
    else
        values=interp1(sourceTime,sourceData,targetTime,'previous','extrap');
    end
else
    error('HybridBus:EquivalenceOutput','Unsupported Simulink output format for %s.',name);
end
end

function value=passFail(condition)
if condition,value="PASS";else,value="FAIL";end
end
