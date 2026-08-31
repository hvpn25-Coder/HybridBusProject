% GEN-11 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=11;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-11";
GensetData.Genset.Name="Engine Genset 11";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=247.272727272727;
GensetData.Genset.GeneratorRatedPower_kW=237.272727272727;
GensetData.Genset.MinStablePower_kW=43.1818181818182;
GensetData.Genset.OptimumPower_kW=180.454545454545;
GensetData.Genset.MaxPower_kW=237.272727272727;
GensetData.Genset.IdleFuel_Lph=2.5;
GensetData.Genset.StartFuel_L=0.0763636363636364;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=42.7272727272727;
GensetData.Genset.MinOnTime_s=96.3636363636364;
GensetData.Genset.MinOffTime_s=72.2727272727273;
GensetData.Genset.RampRate_kW_s=62.2727272727273;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=1109.09090909091;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-11";
GensetData.Engine.Name="Diesel Engine 11";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=247.272727272727;
GensetData.Engine.BestBSFC_g_kWh=221.818181818182;
GensetData.Engine.LowLoadBSFC_g_kWh=241.363636363636;
GensetData.Engine.HighLoadBSFC_g_kWh=280.909090909091;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-11";
GensetData.Generator.Name="Generator 11";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=237.272727272727;
GensetData.Generator.PeakEfficiency=0.955454545454545;
GensetData.Generator.LowLoadEfficiency=0.924545454545455;
GensetData.Generator.VoltageClass_V=800;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.760536398467433;0.8;0.9;1], ...
    [255.204545454545;247.551334271323;241.363636363636;236.416922377639;231.626473339295;227.389771121194;224.104297595929;222.16753463609;221.818181818182;224.305499942975;247.371778812949;280.909090909091], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.760536398467433;0.8;0.9;1], ...
    [0.874545454545455;0.904564126182455;0.924545454545455;0.93392936154143;0.941857388453972;0.948142612009414;0.952598108934087;0.955036955954326;0.955454545454545;0.95511367573058;0.951630032466285;0.945454545454545], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
