function Optimization = optimize_hybrid_bus_configuration(databaseFile, options)
%OPTIMIZE_HYBRID_BUS_CONFIGURATION Bounded toolbox-free configuration search.
arguments
    databaseFile (1,1) string = fullfile(fileparts(mfilename('fullpath')), ...
        "HybridBus_ComponentDatabase.xlsx")
    options.Vary (1,:) string = ["Battery1","Battery2","Motor","Genset","FinalDrive"]
    options.MaxConfigurations (1,1) double {mustBePositive,mustBeInteger} = 100
    options.BaseOverrides (1,1) struct = struct
    options.ProgressFcn = []
    options.CancelFcn = []
    options.SaveResults (1,1) logical = true
end
Database=load_hybrid_bus_database(databaseFile);
Validation=validate_hybrid_bus_database(Database);
assert(Validation.IsValid,'HybridBus:InvalidDatabase','Cannot optimize an invalid database.');

catalogMap=struct('Battery1','Battery_Catalog','Battery2','Battery_Catalog', ...
    'Motor','Motor_Catalog','Genset','Genset_Catalog','Tyre','Tyre_Catalog', ...
    'FinalDrive','Final_Drive_Catalog','Mass','Bus_Mass_Catalog', ...
    'Aux','Aux_Load_Profiles','Route','Route_Time_Speed','Control','Control_Calibration');
dashboardMap=struct('Battery1','SelectedBattery1','Battery2','SelectedBattery2', ...
    'Motor','SelectedMotor','Genset','SelectedGenset','Tyre','SelectedTyre', ...
    'FinalDrive','SelectedFinalDrive','Mass','SelectedMass','Aux','SelectedAuxProfile', ...
    'Route','SelectedRoute','Control','SelectedControl');
candidates=cell(1,numel(options.Vary));
for k=1:numel(options.Vary)
    category=options.Vary(k); assert(isfield(catalogMap,category),'Unknown category %s',category);
    T=Database.(catalogMap.(category));
    if category=="Route"
        ids=unique(string(T.RouteID),'stable');
    else
        if ismember('OptimizationEnabled',T.Properties.VariableNames)
            T=T(logical(T.OptimizationEnabled),:);
        end
        ids=string(T.ComponentID);
    end
    candidates{k}=ids;
end
radix=cellfun(@numel,candidates);
searchSpace=prod(double(radix));
attemptLimit=min(searchSpace,max(options.MaxConfigurations*20,options.MaxConfigurations));
rows=struct([]); feasibleResults=cell(0,1); evaluated=0;
for linearIndex=0:attemptLimit-1
    if ~isempty(options.CancelFcn) && options.CancelFcn(), break; end
    digit=linearIndex; overrides=options.BaseOverrides;
    for k=1:numel(options.Vary)
        idx=mod(digit,radix(k))+1; digit=floor(digit/radix(k));
        category=options.Vary(k);
        overrides.(dashboardMap.(category))=candidates{k}(idx);
    end
    [compatible,reason]=compatibility_check(Database,overrides);
    evaluated=evaluated+1;
    row=base_row(evaluated,overrides,reason);
    if compatible
        try
            Input=prepare_hybrid_bus_inputs(Database,overrides);
            result=simulate_hybrid_bus_core(Input);
            row=fill_row(row,result);
            comparison=evaluate_hybrid_bus_comparison(result, ...
                string(Database.Optimization_Settings.ComparisonMethod(1)), ...
                Database.Optimization_Settings.TerminalSOETolerance(1));
            terminalOK=comparison.TerminalSOECompliant;
            row.Feasible=result.Summary.UnmetTractionEnergy_kWh<1e-3 && ...
                result.Summary.EnergyBalanceError_kWh<=Input.Vehicle.EnergyBalanceTolerance_kWh && terminalOK;
            if ~terminalOK, row.RejectionReason="Terminal combined-SOE tolerance violated"; end
            if row.Feasible, feasibleResults{end+1,1}=result; end %#ok<AGROW>
        catch exception
            row.RejectionReason="Simulation error: "+string(exception.message);
        end
    end
    rows=[rows;row]; %#ok<AGROW>
    if ~isempty(options.ProgressFcn), options.ProgressFcn(evaluated,options.MaxConfigurations,row); end
    if sum([rows.Feasible])>=options.MaxConfigurations || evaluated>=options.MaxConfigurations, break; end
end
All=struct2table(rows,'AsArray',true);
feasibleMask=All.Feasible;
Feasible=sortrows(All(feasibleMask,:),{'CostPer_km','Fuel_L_per_100km'}, {'ascend','ascend'});
Top=Feasible(1:min(10,height(Feasible)),:);
best=[];
if ~isempty(Top)
    bestIndex=find([rows.Feasible] & [rows.Evaluation]==Top.Evaluation(1),1);
    feasibleOrdinal=sum([rows(1:bestIndex).Feasible]);
    best=feasibleResults{feasibleOrdinal};
end
Optimization=struct('DatabaseFile',databaseFile,'Vary',options.Vary, ...
    'SearchSpace',searchSpace,'EvaluatedConfigurations',All, ...
    'FeasibleConfigurations',Feasible,'TopConfigurations',Top,'BestResult',best, ...
    'Validation',Validation,'Timestamp',datetime('now'));
if options.SaveResults
    folder=fullfile(fileparts(mfilename('fullpath')),'results');
    if ~isfolder(folder),mkdir(folder);end
    stamp=string(datetime('now','Format','yyyyMMdd_HHmmss'));
    writetable(All,fullfile(folder,"HybridBus_AllConfigurations_"+stamp+".csv"));
    writetable(Top,fullfile(folder,"HybridBus_TopConfigurations_"+stamp+".csv"));
    save(fullfile(folder,"HybridBus_Optimization_"+stamp+".mat"),'Optimization','-v7.3');
end
end

function [ok,reason]=compatibility_check(DB,O)
D=DB.Dashboard; f=fieldnames(O); for k=1:numel(f),D.(f{k})=O.(f{k});end
B1=getrow(DB.Battery_Catalog,string(D.SelectedBattery1));
B2=getrow(DB.Battery_Catalog,string(D.SelectedBattery2));
M=getrow(DB.Motor_Catalog,string(D.SelectedMotor));
G=getrow(DB.Genset_Catalog,string(D.SelectedGenset));
T=getrow(DB.Tyre_Catalog,string(D.SelectedTyre));
F=getrow(DB.Final_Drive_Catalog,string(D.SelectedFinalDrive));
R=DB.Route_Time_Speed(DB.Route_Time_Speed.RouteID==string(D.SelectedRoute),:);
ok=false; reason="";
if abs(B1.VoltageClass_V-M.VoltageClass_V)>50 || abs(B2.VoltageClass_V-M.VoltageClass_V)>50
    reason="DC voltage incompatibility"; return
end
maxMotorRPM=max(R.Speed_kmh/3.6)/T.LoadedRadius_m*F.Ratio*60/(2*pi);
if maxMotorRPM>M.MaxSpeed_rpm, reason="Motor-speed feasibility"; return; end
if F.Ratio<M.MinReductionRatio || F.Ratio>M.MaxReductionRatio
    reason="Reduction ratio outside motor compatibility"; return
end
if max(B1.MaxDischarge_kW,B2.MaxDischarge_kW)<M.ContinuousPower_kW
    reason="Active battery continuous-power shortfall"; return
end
if G.OptimumPower_kW>G.MaxPower_kW
    reason="Genset optimum point exceeds rated power"; return
end
if G.OptimumPower_kW>min(B1.MaxCharge_kW,B2.MaxCharge_kW)
    reason="Genset optimum charging power exceeds standby battery charge capability"; return
end
ok=true;
end

function S=getrow(T,id)
S=table2struct(T(string(T.ComponentID)==id,:));
end

function row=base_row(index,O,reason)
names={'SelectedBattery1','SelectedBattery2','SelectedMotor','SelectedGenset', ...
    'SelectedTyre','SelectedFinalDrive','SelectedMass','SelectedAuxProfile', ...
    'SelectedRoute','SelectedControl'};
row=struct('Evaluation',index,'Battery1ID',"fixed",'Battery2ID',"fixed", ...
    'MotorID',"fixed",'GensetID',"fixed",'TyreID',"fixed",'FinalDriveID',"fixed", ...
    'MassID',"fixed",'AuxID',"fixed",'RouteID',"fixed",'ControlID',"fixed", ...
    'Feasible',false,'RejectionReason',reason,'CostPer_km',inf,'Fuel_L_per_100km',inf, ...
    'Electrical_kWh_per_km',inf,'TotalSourceEnergy_kWh_per_km',inf, ...
    'FinalBattery1SOE',nan,'FinalBattery2SOE',nan,'UnmetTractionEnergy_kWh',inf, ...
    'EstimatedVehicleMass_kg',nan);
outputs={'Battery1ID','Battery2ID','MotorID','GensetID','TyreID','FinalDriveID', ...
    'MassID','AuxID','RouteID','ControlID'};
for k=1:numel(names),if isfield(O,names{k}),row.(outputs{k})=string(O.(names{k}));end,end
end

function row=fill_row(row,R)
fields={'CostPer_km','Fuel_L_per_100km','Electrical_kWh_per_km', ...
    'TotalSourceEnergy_kWh_per_km','FinalBattery1SOE','FinalBattery2SOE', ...
    'UnmetTractionEnergy_kWh','EstimatedVehicleMass_kg'};
for k=1:numel(fields),row.(fields{k})=R.Summary.(fields{k});end
row.RejectionReason="";
end
