% GEN-03 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=3;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-03";
GensetData.Genset.Name="Engine Genset 03";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=145.454545454545;
GensetData.Genset.GeneratorRatedPower_kW=135.454545454545;
GensetData.Genset.MinStablePower_kW=28.6363636363636;
GensetData.Genset.OptimumPower_kW=104.090909090909;
GensetData.Genset.MaxPower_kW=135.454545454545;
GensetData.Genset.IdleFuel_Lph=1.7;
GensetData.Genset.StartFuel_L=0.0472727272727273;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=24.5454545454545;
GensetData.Genset.MinOnTime_s=67.2727272727273;
GensetData.Genset.MinOffTime_s=50.4545454545455;
GensetData.Genset.RampRate_kW_s=40.4545454545455;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=781.818181818182;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-03";
GensetData.Engine.Name="Diesel Engine 03";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=145.454545454545;
GensetData.Engine.BestBSFC_g_kWh=196.363636363636;
GensetData.Engine.LowLoadBSFC_g_kWh=212.272727272727;
GensetData.Engine.HighLoadBSFC_g_kWh=248.181818181818;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-03";
GensetData.Generator.Name="Generator 03";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=135.454545454545;
GensetData.Generator.PeakEfficiency=0.919090909090909;
GensetData.Generator.LowLoadEfficiency=0.880909090909091;
GensetData.Generator.VoltageClass_V=650;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.768456375838926;0.8;0.9;1], ...
    [224.840909090909;217.79042452791;212.272727272727;208.167177634941;204.283985532381;200.896401896059;198.277677656989;196.701063746186;196.363636363636;197.885531244498;217.959333005797;248.181818181818], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.768456375838926;0.8;0.9;1], ...
    [0.830909090909091;0.860432897701224;0.880909090909091;0.89195878146555;0.901562303366855;0.909390953195784;0.915116027535118;0.918408822967638;0.919090909090909;0.918863566715895;0.915500311849491;0.909090909090909], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
