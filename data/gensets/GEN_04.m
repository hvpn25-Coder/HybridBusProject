% GEN-04 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=4;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-04";
GensetData.Genset.Name="Engine Genset 04";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=158.181818181818;
GensetData.Genset.GeneratorRatedPower_kW=148.181818181818;
GensetData.Genset.MinStablePower_kW=30.4545454545455;
GensetData.Genset.OptimumPower_kW=113.636363636364;
GensetData.Genset.MaxPower_kW=148.181818181818;
GensetData.Genset.IdleFuel_Lph=1.8;
GensetData.Genset.StartFuel_L=0.0509090909090909;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=26.8181818181818;
GensetData.Genset.MinOnTime_s=70.9090909090909;
GensetData.Genset.MinOffTime_s=53.1818181818182;
GensetData.Genset.RampRate_kW_s=43.1818181818182;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=822.727272727273;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-04";
GensetData.Engine.Name="Diesel Engine 04";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=158.181818181818;
GensetData.Engine.BestBSFC_g_kWh=199.545454545455;
GensetData.Engine.LowLoadBSFC_g_kWh=215.909090909091;
GensetData.Engine.HighLoadBSFC_g_kWh=252.272727272727;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-04";
GensetData.Generator.Name="Generator 04";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=148.181818181818;
GensetData.Generator.PeakEfficiency=0.923636363636364;
GensetData.Generator.LowLoadEfficiency=0.886363636363636;
GensetData.Generator.VoltageClass_V=650;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.766871165644172;0.8;0.9;1], ...
    [228.636363636364;221.511351959163;215.909090909091;211.695279238828;207.696445433346;204.201698723358;201.500148339578;199.880903512719;199.545454545455;201.223517549396;221.691758303924;252.272727272727], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.766871165644172;0.8;0.9;1], ...
    [0.836363636363636;0.865944888609926;0.886363636363636;0.897221195769094;0.906625603267299;0.914265014963661;0.919827586963588;0.923001475372491;0.923636363636364;0.923389053018182;0.920009011439897;0.913636363636364], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
