% GEN-09 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=9;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-09";
GensetData.Genset.Name="Engine Genset 09";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=221.818181818182;
GensetData.Genset.GeneratorRatedPower_kW=211.818181818182;
GensetData.Genset.MinStablePower_kW=39.5454545454545;
GensetData.Genset.OptimumPower_kW=161.363636363636;
GensetData.Genset.MaxPower_kW=211.818181818182;
GensetData.Genset.IdleFuel_Lph=2.3;
GensetData.Genset.StartFuel_L=0.0690909090909091;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=38.1818181818182;
GensetData.Genset.MinOnTime_s=89.0909090909091;
GensetData.Genset.MinOffTime_s=66.8181818181818;
GensetData.Genset.RampRate_kW_s=56.8181818181818;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=1027.27272727273;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-09";
GensetData.Engine.Name="Diesel Engine 09";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=221.818181818182;
GensetData.Engine.BestBSFC_g_kWh=215.454545454545;
GensetData.Engine.LowLoadBSFC_g_kWh=234.090909090909;
GensetData.Engine.HighLoadBSFC_g_kWh=272.727272727273;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-09";
GensetData.Generator.Name="Generator 09";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=211.818181818182;
GensetData.Generator.PeakEfficiency=0.946363636363636;
GensetData.Generator.LowLoadEfficiency=0.913636363636364;
GensetData.Generator.VoltageClass_V=750;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.761802575107296;0.8;0.9;1], ...
    [247.613636363636;240.112227780485;234.090909090909;229.350353226581;224.783941031754;220.75839622626;217.640442529932;215.796803662601;215.454545454545;217.744958437816;240.084284091573;272.727272727273], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.761802575107296;0.8;0.9;1], ...
    [0.863636363636364;0.893524574538489;0.913636363636364;0.923459945435937;0.931820131373669;0.938494570841188;0.943260913230128;0.945896807932118;0.946363636363636;0.946044060098983;0.942589002630553;0.936363636363636], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
