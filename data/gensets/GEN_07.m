% GEN-07 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=7;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-07";
GensetData.Genset.Name="Engine Genset 07";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=196.363636363636;
GensetData.Genset.GeneratorRatedPower_kW=186.363636363636;
GensetData.Genset.MinStablePower_kW=35.9090909090909;
GensetData.Genset.OptimumPower_kW=142.272727272727;
GensetData.Genset.MaxPower_kW=186.363636363636;
GensetData.Genset.IdleFuel_Lph=2.1;
GensetData.Genset.StartFuel_L=0.0618181818181818;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=33.6363636363636;
GensetData.Genset.MinOnTime_s=81.8181818181818;
GensetData.Genset.MinOffTime_s=61.3636363636364;
GensetData.Genset.RampRate_kW_s=51.3636363636364;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=945.454545454545;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-07";
GensetData.Engine.Name="Diesel Engine 07";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=196.363636363636;
GensetData.Engine.BestBSFC_g_kWh=209.090909090909;
GensetData.Engine.LowLoadBSFC_g_kWh=226.818181818182;
GensetData.Engine.HighLoadBSFC_g_kWh=264.545454545455;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-07";
GensetData.Generator.Name="Generator 07";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=186.363636363636;
GensetData.Generator.PeakEfficiency=0.937272727272727;
GensetData.Generator.LowLoadEfficiency=0.902727272727273;
GensetData.Generator.VoltageClass_V=700;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.763414634146341;0.8;0.9;1], ...
    [240.022727272727;232.672495215918;226.818181818182;222.286011996359;217.945036522337;214.131132190221;211.180175794118;209.428044128132;209.090909090909;211.162014588269;232.765655125473;264.545454545455], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.763414634146341;0.8;0.9;1], ...
    [0.852727272727273;0.882489186528772;0.902727272727273;0.912976855281378;0.921762215063544;0.928824904312664;0.933906475267632;0.936748480167342;0.937272727272727;0.936977946346711;0.933551942221459;0.927272727272727], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
