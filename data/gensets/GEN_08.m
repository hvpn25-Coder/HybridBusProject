% GEN-08 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=8;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-08";
GensetData.Genset.Name="Engine Genset 08";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=209.090909090909;
GensetData.Genset.GeneratorRatedPower_kW=199.090909090909;
GensetData.Genset.MinStablePower_kW=37.7272727272727;
GensetData.Genset.OptimumPower_kW=151.818181818182;
GensetData.Genset.MaxPower_kW=199.090909090909;
GensetData.Genset.IdleFuel_Lph=2.2;
GensetData.Genset.StartFuel_L=0.0654545454545455;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=35.9090909090909;
GensetData.Genset.MinOnTime_s=85.4545454545455;
GensetData.Genset.MinOffTime_s=64.0909090909091;
GensetData.Genset.RampRate_kW_s=54.0909090909091;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=986.363636363636;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-08";
GensetData.Engine.Name="Diesel Engine 08";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=209.090909090909;
GensetData.Engine.BestBSFC_g_kWh=212.272727272727;
GensetData.Engine.LowLoadBSFC_g_kWh=230.454545454545;
GensetData.Engine.HighLoadBSFC_g_kWh=268.636363636364;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-08";
GensetData.Generator.Name="Generator 08";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=199.090909090909;
GensetData.Generator.PeakEfficiency=0.941818181818182;
GensetData.Generator.LowLoadEfficiency=0.908181818181818;
GensetData.Generator.VoltageClass_V=750;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.762557077625571;0.8;0.9;1], ...
    [243.818181818182;236.392448160137;230.454545454545;225.817868581252;221.363970333252;217.444168882935;214.409782402692;212.612129064913;212.272727272727;214.456776860848;236.429646455112;268.636363636364], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.762557077625571;0.8;0.9;1], ...
    [0.858181818181818;0.888006341215434;0.908181818181818;0.918220219359891;0.926793984498925;0.933662753063858;0.938586164519631;0.941323858331179;0.941818181818182;0.941510484582994;0.938069869461538;0.931818181818182], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
