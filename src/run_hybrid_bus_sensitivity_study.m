function Study = run_hybrid_bus_sensitivity_study(databaseFile,overrides)
%RUN_HYBRID_BUS_SENSITIVITY_STUDY Deterministic one-at-a-time uncertainty screen.
arguments
    databaseFile (1,1) string = fullfile(hybrid_bus_project_root(), ...
        "data","HybridBus_ComponentDatabase.xlsx")
    overrides (1,1) struct = struct
end
Database=load_hybrid_bus_database(databaseFile);
baseInput=prepare_hybrid_bus_inputs(Database,overrides);
baseResult=simulate_hybrid_bus_core(baseInput);

definitions={ ...
    'Total vehicle mass','Mass.TotalVehicleMass_kg',0.10; ...
    'Aerodynamic drag coefficient','Vehicle.DragCoefficient',0.10; ...
    'Rolling resistance coefficient','Tyre.RollingResistanceCoefficient',0.10; ...
    'Auxiliary-load scalar','AuxiliaryScalarOverride',0.20; ...
    'Motor motoring efficiency','Motor.MotoringEfficiency',0.03; ...
    'Battery discharge efficiency','BatteryEfficiency',0.03};
n=size(definitions,1); parameter=strings(n,1); perturbation=zeros(n,1);
lowCost=zeros(n,1); highCost=zeros(n,1); lowEnergy=zeros(n,1); highEnergy=zeros(n,1);
for index=1:n
    parameter(index)=definitions{index,1}; perturbation(index)=100*definitions{index,3};
    lowInput=perturb(baseInput,definitions{index,2},1-definitions{index,3});
    highInput=perturb(baseInput,definitions{index,2},1+definitions{index,3});
    low=simulate_hybrid_bus_core(lowInput); high=simulate_hybrid_bus_core(highInput);
    lowCost(index)=low.Summary.CostPer_km; highCost(index)=high.Summary.CostPer_km;
    lowEnergy(index)=low.Summary.TotalSourceEnergy_kWh_per_km;
    highEnergy(index)=high.Summary.TotalSourceEnergy_kWh_per_km;
end
costSwing_pct=100*(highCost-lowCost)/max(baseResult.Summary.CostPer_km,eps);
energySwing_pct=100*(highEnergy-lowEnergy)/max(baseResult.Summary.TotalSourceEnergy_kWh_per_km,eps);
Study=struct;
Study.Baseline=struct('Cost_EUR_per_km',baseResult.Summary.CostPer_km, ...
    'SourceEnergy_kWh_per_km',baseResult.Summary.TotalSourceEnergy_kWh_per_km);
Study.Results=sortrows(table(parameter,perturbation,lowCost,highCost,costSwing_pct, ...
    lowEnergy,highEnergy,energySwing_pct,'VariableNames',{'Parameter','Perturbation_pct', ...
    'LowCost_EUR_per_km','HighCost_EUR_per_km','CostSwing_pct', ...
    'LowEnergy_kWh_per_km','HighEnergy_kWh_per_km','EnergySwing_pct'}), ...
    'CostSwing_pct','descend');
Study.Method="Deterministic one-at-a-time screen; not a probability distribution or Monte Carlo confidence interval.";
end

function Input=perturb(Input,path,factor)
switch path
    case 'Mass.TotalVehicleMass_kg'
        Input.Mass.TotalVehicleMass_kg=Input.Mass.TotalVehicleMass_kg*factor;
    case 'Vehicle.DragCoefficient'
        Input.Vehicle.DragCoefficient=Input.Vehicle.DragCoefficient*factor;
    case 'Tyre.RollingResistanceCoefficient'
        Input.Tyre.RollingResistanceCoefficient=Input.Tyre.RollingResistanceCoefficient*factor;
    case 'AuxiliaryScalarOverride'
        Input.AuxiliaryScalarOverride=Input.AuxiliaryScalarOverride*factor;
    case 'Motor.MotoringEfficiency'
        Input.Motor.MotoringEfficiency=min(0.999,max(0.5,Input.Motor.MotoringEfficiency*factor));
    case 'BatteryEfficiency'
        Input.Battery1.DischargeEfficiency=min(0.999,max(0.5,Input.Battery1.DischargeEfficiency*factor));
        Input.Battery2.DischargeEfficiency=min(0.999,max(0.5,Input.Battery2.DischargeEfficiency*factor));
end
end
