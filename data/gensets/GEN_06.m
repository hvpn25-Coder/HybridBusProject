% GEN-06 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=6;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-06";
GensetData.Genset.Name="Engine Genset 06";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=183.636363636364;
GensetData.Genset.GeneratorRatedPower_kW=173.636363636364;
GensetData.Genset.MinStablePower_kW=34.0909090909091;
GensetData.Genset.OptimumPower_kW=132.727272727273;
GensetData.Genset.MaxPower_kW=173.636363636364;
GensetData.Genset.IdleFuel_Lph=2;
GensetData.Genset.StartFuel_L=0.0581818181818182;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=31.3636363636364;
GensetData.Genset.MinOnTime_s=78.1818181818182;
GensetData.Genset.MinOffTime_s=58.6363636363636;
GensetData.Genset.RampRate_kW_s=48.6363636363636;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=904.545454545455;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-06";
GensetData.Engine.Name="Diesel Engine 06";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=183.636363636364;
GensetData.Engine.BestBSFC_g_kWh=205.909090909091;
GensetData.Engine.LowLoadBSFC_g_kWh=223.181818181818;
GensetData.Engine.HighLoadBSFC_g_kWh=260.454545454545;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-06";
GensetData.Generator.Name="Generator 06";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=173.636363636364;
GensetData.Generator.PeakEfficiency=0.932727272727273;
GensetData.Generator.LowLoadEfficiency=0.897272727272727;
GensetData.Generator.VoltageClass_V=700;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.764397905759162;0.8;0.9;1], ...
    [236.227272727273;228.952347416353;223.181818181818;218.754876577724;214.527311901349;210.819504458738;207.951834555933;206.244682498979;205.909090909091;207.859380865065;229.090130500289;260.454545454545], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.764397905759162;0.8;0.9;1], ...
    [0.847272727272727;0.876973167695427;0.897272727272727;0.907729538984923;0.916724182011276;0.923980160535209;0.929220978740144;0.932170140809503;0.932727272727273;0.932446662029776;0.929035522868642;0.922727272727273], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
