function Comparison = evaluate_hybrid_bus_comparison(Results,method,terminalSOETolerance)
%EVALUATE_HYBRID_BUS_COMPARISON Apply charge-sustaining or replenishment rules.
arguments
    Results (1,1) struct
    method (1,1) string {mustBeMember(method,["EquivalentReplenishment","ChargeSustaining"])}
    terminalSOETolerance (1,1) double {mustBeNonnegative} = 0.03
end
initialCombined=(Results.InputParameters.InitialBattery1SOE+ ...
    Results.InputParameters.InitialBattery2SOE)/2;
finalCombined=(Results.Summary.FinalBattery1SOE+Results.Summary.FinalBattery2SOE)/2;
terminalDeviation=finalCombined-initialCombined;
terminalOK=method=="EquivalentReplenishment" || abs(terminalDeviation)<=terminalSOETolerance;
Comparison=struct('Method',method,'InitialCombinedSOE',initialCombined, ...
    'FinalCombinedSOE',finalCombined,'TerminalSOEDeviation',terminalDeviation, ...
    'TerminalSOECompliant',terminalOK,'EquivalentReplenishmentCostPer_km', ...
    Results.Summary.CostPer_km,'Feasible',Results.Validation.IsFeasible && terminalOK);
end

