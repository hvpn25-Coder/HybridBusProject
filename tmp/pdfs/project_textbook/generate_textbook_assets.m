rootFolder = "C:\TempData\Hybrid_Vehicle\HybridBusProject";
assetFolder = fullfile(rootFolder,"tmp","pdfs","project_textbook");
cd(rootFolder);
addpath(fullfile(rootFolder,"src"),fullfile(rootFolder,"models"));

databaseFile=fullfile(rootFolder,"data","HybridBus_ComponentDatabase.xlsx");
Database = load_hybrid_bus_database(databaseFile);
Results = run_hybrid_bus_simulation(databaseFile, ...
    struct,'SaveResults',false);

sample = unique([1:10:numel(Results.Time),numel(Results.Time)]);
Signals = table(Results.Time(sample),Results.Signals.Vehicle.Speed_m_s(sample)*3.6, ...
    Results.Signals.Wheel.Demand_kW(sample),Results.Signals.Motors.ElectricalPower_kW(sample), ...
    Results.Signals.Auxiliary.Power_kW(sample),Results.Signals.Battery1.SOE(sample)*100, ...
    Results.Signals.Battery2.SOE(sample)*100,Results.Signals.Genset.ElectricalPower_kW(sample), ...
    Results.Signals.Regeneration.Available_kW(sample), ...
    Results.Signals.Regeneration.ToAuxiliary_kW(sample), ...
    Results.Signals.Regeneration.ToActiveBattery_kW(sample), ...
    Results.Signals.Regeneration.ResistorLoadBank_kW(sample), ...
    Results.Signals.Controller.ActiveBattery(sample),Results.Signals.Controller.Mode(sample), ...
    Results.Signals.Energy.BalanceResidual_kW(sample), ...
    'VariableNames',{'Time_s','Speed_kmh','WheelDemand_kW','MotorDC_kW','Auxiliary_kW', ...
    'Battery1SOE_pct','Battery2SOE_pct','Genset_kW','RegenAvailable_kW', ...
    'RegenToAuxiliary_kW','RegenToActiveBattery_kW','ResistorLoadBank_kW', ...
    'ActiveBattery','Mode','BalanceResidual_kW'});
writetable(Signals,fullfile(assetFolder,'default_signals.csv'));
writetable(struct2table(Results.Summary,'AsArray',true), ...
    fullfile(assetFolder,'default_summary.csv'));
writetable(Database.Route_Catalog,fullfile(assetFolder,'route_catalog.csv'));
writetable(Database.Bus_Mass_Catalog,fullfile(assetFolder,'mass_catalog.csv'));
writetable(Database.Battery_Catalog,fullfile(assetFolder,'battery_catalog.csv'));
writetable(Database.Motor_Catalog,fullfile(assetFolder,'motor_catalog.csv'));
writetable(Database.Genset_Catalog,fullfile(assetFolder,'genset_catalog.csv'));
writetable(Database.Engine_Fuel_Map,fullfile(assetFolder,'fuel_map.csv'));
writetable(Database.Generator_Efficiency_Map,fullfile(assetFolder,'generator_map.csv'));
writetable(Database.Route_Time_Speed(Database.Route_Time_Speed.RouteID=="VECTO-URBAN",:), ...
    fullfile(assetFolder,'vecto_urban_route.csv'));

% Focused full-active-battery downhill case for explaining the three-stage
% regenerative-energy allocation and resistor-bank operation.
PriorityInput=prepare_hybrid_bus_inputs(Database);
priorityTime=(0:60)'; prioritySpeed=36*ones(size(priorityTime));
PriorityInput.Route=table(priorityTime,prioritySpeed,-10*ones(size(priorityTime)), ...
    false(size(priorityTime)),ones(size(priorityTime)), ...
    'VariableNames',{'Time_s','Speed_kmh','Grade_pct','StopFlag','AuxMultiplier'});
PriorityInput.Route.Distance_m=cumtrapz(priorityTime,prioritySpeed/3.6);
PriorityInput.InitialBattery1SOE=PriorityInput.Battery1.MaxSOE;
PriorityInput.InitialBattery2SOE=0.70;
PriorityInput.InitialActiveBattery=1;
PriorityResults=simulate_hybrid_bus_core(PriorityInput);
PrioritySignals=table(PriorityResults.Time, ...
    PriorityResults.Signals.Regeneration.Available_kW, ...
    PriorityResults.Signals.Regeneration.ToAuxiliary_kW, ...
    PriorityResults.Signals.Regeneration.ToActiveBattery_kW, ...
    PriorityResults.Signals.Regeneration.ResistorLoadBank_kW, ...
    PriorityResults.Signals.Battery1.SOE*100, ...
    'VariableNames',{'Time_s','Available_kW','ToAuxiliary_kW', ...
    'ToActiveBattery_kW','ResistorLoadBank_kW','ActiveBatterySOE_pct'});
writetable(PrioritySignals,fullfile(assetFolder,'regen_priority_case.csv'));

% Refresh the studies quoted later in the textbook so all reported metrics
% use the calculated-mass model and current regeneration policy.
massCount=height(Database.Bus_Mass_Catalog);
massID=strings(massCount,1); totalMass=zeros(massCount,1); costPerKm=zeros(massCount,1);
gridEnergy=zeros(massCount,1); fuelLitres=zeros(massCount,1); unmetEnergy=zeros(massCount,1);
baseInput=prepare_hybrid_bus_inputs(Database);
baseCurbMass=baseInput.Mass.CurbMass_kg;
for index=1:massCount
    massID(index)=Database.Bus_Mass_Catalog.ComponentID(index);
    targetMass=Database.Bus_Mass_Catalog.TotalVehicleMass_kg(index);
    loadMass_t=max(0,(targetMass-baseCurbMass)/1000);
    MassResult=run_hybrid_bus_simulation(databaseFile, ...
        struct('LoadMass_t',loadMass_t),'SaveResults',false);
    totalMass(index)=MassResult.Summary.EstimatedVehicleMass_kg;
    costPerKm(index)=MassResult.Summary.CostPer_km;
    gridEnergy(index)=MassResult.Summary.GridEquivalentEnergy_kWh;
    fuelLitres(index)=MassResult.Summary.Fuel_L;
    unmetEnergy(index)=MassResult.Summary.UnmetTractionEnergy_kWh;
end
MassStudy=table(massID,totalMass,costPerKm,gridEnergy,fuelLitres,unmetEnergy, ...
    'VariableNames',{'MassID','TotalVehicleMass_kg','CostPer_km','GridEnergy_kWh', ...
    'Fuel_L','UnmetEnergy_kWh'});
writetable(MassStudy,fullfile(assetFolder,'mass_sweep.csv'));

% Ordered side-by-side manual comparison used by the app's new checkbox.
comparisonOverrides=struct('PowertrainMode',"Hybrid",'BatterySetMultiplier',1, ...
    'InitialBattery1SOE',Database.Dashboard.InitialBattery1SOE, ...
    'InitialBattery2SOE',Database.Dashboard.InitialBattery2SOE, ...
    'LoadMass_t',Database.Dashboard.LoadMass_t,'RepeatUntilDepleted',false);
Sequence=run_powertrain_sequence(Database,comparisonOverrides,true);
mode=["BEV";"Hybrid"];
comparisonResults={Sequence.BEV;Sequence.Hybrid};
vehicleMass=zeros(2,1); costPerKm=zeros(2,1); fuelL=zeros(2,1);
gridEnergy=zeros(2,1); finalB1=zeros(2,1); finalB2=zeros(2,1); feasible=false(2,1);
for index=1:2
    result=comparisonResults{index}; summaryRow=result.Summary;
    vehicleMass(index)=summaryRow.EstimatedVehicleMass_kg;
    costPerKm(index)=summaryRow.CostPer_km;
    fuelL(index)=summaryRow.Fuel_L;
    gridEnergy(index)=summaryRow.GridEquivalentEnergy_kWh;
    finalB1(index)=100*summaryRow.FinalBattery1SOE;
    finalB2(index)=100*summaryRow.FinalBattery2SOE;
    feasible(index)=result.Validation.IsFeasible;
end
PowertrainComparison=table(mode,vehicleMass,costPerKm,fuelL,gridEnergy, ...
    finalB1,finalB2,feasible,'VariableNames',{'Mode','VehicleMass_kg', ...
    'CostPer_km','Fuel_L','GridEquivalentEnergy_kWh','FinalB1SOE_pct', ...
    'FinalB2SOE_pct','Feasible'});
writetable(PowertrainComparison,fullfile(assetFolder,'powertrain_comparison.csv'));

longRoutes=Database.Route_Catalog(Database.Route_Catalog.RouteType=="Long-distance coach",:);
routeCount=height(longRoutes); routeID=strings(routeCount,1); routeName=strings(routeCount,1);
sourceDistance=zeros(routeCount,1); simulatedDistance=zeros(routeCount,1);
routeCost=zeros(routeCount,1); routeFuel=zeros(routeCount,1); routeUnmet=zeros(routeCount,1);
finalB1=zeros(routeCount,1); finalB2=zeros(routeCount,1);
routeFeasible=false(routeCount,1);
for index=1:routeCount
    routeID(index)=longRoutes.RouteID(index); routeName(index)=longRoutes.RouteName(index);
    sourceDistance(index)=longRoutes.Distance_km(index);
    LongResult=run_hybrid_bus_simulation(databaseFile, ...
        struct('SelectedRoute',routeID(index)),'SaveResults',false);
    simulatedDistance(index)=LongResult.Summary.RouteDistance_km;
    routeCost(index)=LongResult.Summary.CostPer_km;
    routeFuel(index)=LongResult.Summary.Fuel_L;
    routeUnmet(index)=LongResult.Summary.UnmetTractionEnergy_kWh;
    finalB1(index)=100*LongResult.Summary.FinalBattery1SOE;
    finalB2(index)=100*LongResult.Summary.FinalBattery2SOE;
    routeFeasible(index)=LongResult.Validation.IsFeasible;
end
LongStudy=table(routeID,routeName,sourceDistance,simulatedDistance,routeCost,routeFuel, ...
    routeUnmet,finalB1,finalB2,routeFeasible,'VariableNames',{'RouteID','RouteName','SourceDistance_km', ...
    'SimDistance_km','CostPer_km','Fuel_L','UnmetEnergy_kWh','FinalB1SOE_pct', ...
    'FinalB2SOE_pct','Feasible'});
writetable(LongStudy,fullfile(assetFolder,'long_route_study.csv'));

Optimization=optimize_hybrid_bus_configuration( ...
    databaseFile, ...
    Vary=["Battery1","Motor"],MaxConfigurations=144,SaveResults=false);
writetable(Optimization.TopConfigurations, ...
    fullfile(assetFolder,'current_top_configurations.csv'));

try
    modelName = 'HybridBus_BackwardModel';
    load_system(modelName);
    set_param(modelName,'ZoomFactor','FitSystem');
    print(['-s',modelName],'-dpng','-r180',fullfile(assetFolder,'simulink_top_level.png'));
catch exception
    warning('HybridBus:TextbookAsset','Simulink image export failed: %s',exception.message);
end

try
    app = HybridBusApp;
    drawnow;
    figures = findall(groot,'Type','figure','Name','Hybrid-Electric Bus Configuration Explorer');
    if ~isempty(figures)
        comparisonBox=findall(figures(1),'Type','uicheckbox', ...
            'Text','Run BEV first, then Hybrid');
        if ~isempty(comparisonBox), comparisonBox.Value=true; end
        drawnow;
        exportapp(figures(1),fullfile(assetFolder,'hybrid_bus_app.png'));
        architectureTab=findall(figures(1),'Type','uitab','Title','Powertrain Architecture');
        if ~isempty(architectureTab)
            architectureTab.Parent.SelectedTab=architectureTab;
            drawnow;
            exportapp(figures(1),fullfile(assetFolder,'hybrid_bus_app_architecture.png'));
        end
    end
    delete(app);
catch exception
    warning('HybridBus:TextbookAsset','App image export failed: %s',exception.message);
end

fprintf('TEXTBOOK_ASSETS_READY=%s\n',assetFolder);
