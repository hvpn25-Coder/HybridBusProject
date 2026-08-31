% GEN-05 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=5;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-05";
GensetData.Genset.Name="Engine Genset 05";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=170.909090909091;
GensetData.Genset.GeneratorRatedPower_kW=160.909090909091;
GensetData.Genset.MinStablePower_kW=32.2727272727273;
GensetData.Genset.OptimumPower_kW=123.181818181818;
GensetData.Genset.MaxPower_kW=160.909090909091;
GensetData.Genset.IdleFuel_Lph=1.9;
GensetData.Genset.StartFuel_L=0.0545454545454545;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=29.0909090909091;
GensetData.Genset.MinOnTime_s=74.5454545454545;
GensetData.Genset.MinOffTime_s=55.9090909090909;
GensetData.Genset.RampRate_kW_s=45.9090909090909;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=863.636363636364;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-05";
GensetData.Engine.Name="Diesel Engine 05";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=170.909090909091;
GensetData.Engine.BestBSFC_g_kWh=202.727272727273;
GensetData.Engine.LowLoadBSFC_g_kWh=219.545454545455;
GensetData.Engine.HighLoadBSFC_g_kWh=256.363636363636;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-05";
GensetData.Generator.Name="Generator 05";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=160.909090909091;
GensetData.Generator.PeakEfficiency=0.928181818181818;
GensetData.Generator.LowLoadEfficiency=0.891818181818182;
GensetData.Generator.VoltageClass_V=650;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.765536723163842;0.8;0.9;1], ...
    [232.431818181818;225.231977823131;219.545454545455;215.224580884629;211.1110179454;207.509568566216;204.725035585524;203.062221841774;202.727272727273;204.547242917076;225.400159379187;256.363636363636], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.765536723163842;0.8;0.9;1], ...
    [0.841818181818182;0.871458364515834;0.891818181818182;0.902477845957394;0.911679030508347;0.919127377725593;0.924528529863685;0.927588129177175;0.928181818181818;0.927916910157865;0.924521021927451;0.918181818181818], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
