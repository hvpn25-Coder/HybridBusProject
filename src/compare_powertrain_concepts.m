function Comparison = compare_powertrain_concepts(Result,Input)
%COMPARE_POWERTRAIN_CONCEPTS Transparent screening baselines for management.
arguments
    Result (1,1) struct
    Input (1,1) struct
end
t=Result.Time(:); dt=[diff(t);0]; distance=max(Result.Summary.RouteDistance_km,eps);
integrate=@(power)sum(power(:).*dt)/3600;

% Battery-electric screening case: same DC mission, one external recharge.
bevNetDC=Result.Signals.Motors.ElectricalPower_kW+Result.Signals.Auxiliary.Power_kW;
bevGridEnergy=max(0,integrate(bevNetDC))/Input.Vehicle.GridChargeEfficiency;
bevCost=bevGridEnergy*Input.Prices.ElectricityPrice_per_kWh;

% Conventional-diesel screening case: same wheel demand and auxiliaries.
% These explicit concept assumptions are not calibration claims.
dieselEngineEfficiency=0.40;
dieselDrivelineEfficiency=0.90;
dieselAlternatorEfficiency=0.90;
dieselFuelLHV_kWh_L=9.80;
positiveWheel=max(0,Result.Signals.Wheel.Demand_kW);
dieselFuelEnergy=integrate(positiveWheel)/dieselDrivelineEfficiency/dieselEngineEfficiency + ...
    integrate(Result.Signals.Auxiliary.Power_kW)/dieselAlternatorEfficiency/dieselEngineEfficiency;
dieselFuel=dieselFuelEnergy/dieselFuelLHV_kWh_L;
dieselCost=dieselFuel*Input.Prices.FuelPrice_per_L;

concept=["Proposed dual-battery hybrid";"Battery-electric screening baseline"; ...
    "Conventional-diesel screening baseline"];
fuel_L=[Result.Summary.Fuel_L;0;dieselFuel];
grid_kWh=[Result.Summary.GridEquivalentEnergy_kWh;bevGridEnergy;0];
cost_EUR=[Result.Summary.TotalOperatingCost;bevCost;dieselCost];
cost_EUR_km=cost_EUR/distance;
source_kWh_km=[Result.Summary.TotalSourceEnergy_kWh_per_km;bevGridEnergy/distance;dieselFuelEnergy/distance];
evidenceLevel=["Implemented model";"Analytical screening";"Analytical screening"];
Comparison=table(concept,fuel_L,grid_kWh,cost_EUR,cost_EUR_km,source_kWh_km,evidenceLevel, ...
    'VariableNames',{'Concept','Fuel_L','GridEnergy_kWh','OperatingCost_EUR', ...
    'Cost_EUR_per_km','SourceEnergy_kWh_per_km','EvidenceLevel'});
Comparison.Properties.UserData=struct( ...
    'DieselEngineEfficiency',dieselEngineEfficiency, ...
    'DieselDrivelineEfficiency',dieselDrivelineEfficiency, ...
    'DieselAlternatorEfficiency',dieselAlternatorEfficiency, ...
    'DieselFuelLHV_kWh_L',dieselFuelLHV_kWh_L, ...
    'Caution',"Baselines are first-principles screening references, not calibrated vehicle models.");
end
