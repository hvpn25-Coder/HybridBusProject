% GEN-02 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=2;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-02";
GensetData.Genset.Name="Engine Genset 02";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=132.727272727273;
GensetData.Genset.GeneratorRatedPower_kW=122.727272727273;
GensetData.Genset.MinStablePower_kW=26.8181818181818;
GensetData.Genset.OptimumPower_kW=94.5454545454545;
GensetData.Genset.MaxPower_kW=122.727272727273;
GensetData.Genset.IdleFuel_Lph=1.6;
GensetData.Genset.StartFuel_L=0.0436363636363636;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=22.2727272727273;
GensetData.Genset.MinOnTime_s=63.6363636363636;
GensetData.Genset.MinOffTime_s=47.7272727272727;
GensetData.Genset.RampRate_kW_s=37.7272727272727;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=740.909090909091;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-02";
GensetData.Engine.Name="Diesel Engine 02";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=132.727272727273;
GensetData.Engine.BestBSFC_g_kWh=193.181818181818;
GensetData.Engine.LowLoadBSFC_g_kWh=208.636363636364;
GensetData.Engine.HighLoadBSFC_g_kWh=244.090909090909;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-02";
GensetData.Generator.Name="Generator 02";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=122.727272727273;
GensetData.Generator.PeakEfficiency=0.914545454545455;
GensetData.Generator.LowLoadEfficiency=0.875454545454545;
GensetData.Generator.VoltageClass_V=600;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.77037037037037;0.8;0.9;1], ...
    [221.045454545455;214.069134181342;208.636363636364;204.640559182299;200.874179513962;197.594384208635;195.0583328436;193.523184996141;193.181818181818;194.529855712229;214.194773953446;244.090909090909], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.77037037037037;0.8;0.9;1], ...
    [0.825454545454545;0.854922618484793;0.875454545454545;0.886689456408831;0.896486874527501;0.904502204441832;0.910390850783103;0.913808218182589;0.914545454545455;0.91434108072147;0.910996140883416;0.904545454545455], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
