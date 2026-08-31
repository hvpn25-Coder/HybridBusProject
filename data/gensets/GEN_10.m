% GEN-10 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=10;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-10";
GensetData.Genset.Name="Engine Genset 10";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=234.545454545455;
GensetData.Genset.GeneratorRatedPower_kW=224.545454545455;
GensetData.Genset.MinStablePower_kW=41.3636363636364;
GensetData.Genset.OptimumPower_kW=170.909090909091;
GensetData.Genset.MaxPower_kW=224.545454545455;
GensetData.Genset.IdleFuel_Lph=2.4;
GensetData.Genset.StartFuel_L=0.0727272727272727;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=40.4545454545455;
GensetData.Genset.MinOnTime_s=92.7272727272727;
GensetData.Genset.MinOffTime_s=69.5454545454545;
GensetData.Genset.RampRate_kW_s=59.5454545454545;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=1068.18181818182;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-10";
GensetData.Engine.Name="Diesel Engine 10";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=234.545454545455;
GensetData.Engine.BestBSFC_g_kWh=218.636363636364;
GensetData.Engine.LowLoadBSFC_g_kWh=237.727272727273;
GensetData.Engine.HighLoadBSFC_g_kWh=276.818181818182;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-10";
GensetData.Generator.Name="Generator 10";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=224.545454545455;
GensetData.Generator.PeakEfficiency=0.950909090909091;
GensetData.Generator.LowLoadEfficiency=0.919090909090909;
GensetData.Generator.VoltageClass_V=750;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.761133603238866;0.8;0.9;1], ...
    [251.409090909091;243.831851630717;237.727272727273;232.883391392361;228.204812049387;224.073642648147;220.871991138438;218.981965470056;218.636363636364;221.027589443085;243.731231190003;276.818181818182], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.761133603238866;0.8;0.9;1], ...
    [0.869090909090909;0.899043845713003;0.919090909090909;0.928696267795435;0.936841142027485;0.943321019538904;0.947931388081541;0.950467735407242;0.950909090909091;0.950578502391406;0.947109114850942;0.940909090909091], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
