function Comparison = evaluate_hybrid_bus_comparison(Results,method,terminalSOETolerance)
%EVALUATE_HYBRID_BUS_COMPARISON Apply charge-sustaining or replenishment rules.
arguments
    Results (1,1) struct
    method (1,1) string {mustBeMember(method,["EquivalentReplenishment","ChargeSustaining"])}
    terminalSOETolerance (1,1) double {mustBeNonnegative} = 0.03
end
input=Results.InputParameters;
weight1=input.Battery1.UsableEnergy_kWh;
weight2=input.Battery2.UsableEnergy_kWh;
if strcmpi(string(input.PowertrainMode),"BEV") && input.Battery2PackCount==0
    weight2=0;
end
totalWeight=max(weight1+weight2,eps);
initialCombined=(weight1*input.InitialBattery1SOE+ ...
    weight2*input.InitialBattery2SOE)/totalWeight;
finalCombined=(weight1*Results.Summary.FinalBattery1SOE+ ...
    weight2*Results.Summary.FinalBattery2SOE)/totalWeight;
terminalDeviation=finalCombined-initialCombined;
terminalOK=method=="EquivalentReplenishment" || abs(terminalDeviation)<=terminalSOETolerance;
Comparison=struct('Method',method,'InitialCombinedSOE',initialCombined, ...
    'FinalCombinedSOE',finalCombined,'TerminalSOEDeviation',terminalDeviation, ...
    'TerminalSOECompliant',terminalOK,'EquivalentReplenishmentCostPer_km', ...
    Results.Summary.CostPer_km,'Feasible',Results.Validation.IsFeasible && terminalOK);
end
