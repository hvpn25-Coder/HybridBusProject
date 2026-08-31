function Results=simulate_hybrid_bus(Input)
%SIMULATE_HYBRID_BUS Route to the selected simulation formulation.
formulation="BackwardDemand";
if isfield(Input,'SimulationFormulation'), formulation=string(Input.SimulationFormulation); end
switch formulation
    case "ConstrainedBackward"
        Results=simulate_hybrid_bus_constrained(Input);
    case "ForwardPerformance"
        Results=simulate_hybrid_bus_performance(Input);
    otherwise
        Results=simulate_hybrid_bus_core(Input);
end
end
