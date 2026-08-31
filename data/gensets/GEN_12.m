% GEN-12 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=12;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-12";
GensetData.Genset.Name="Engine Genset 12";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=260;
GensetData.Genset.GeneratorRatedPower_kW=250;
GensetData.Genset.MinStablePower_kW=45;
GensetData.Genset.OptimumPower_kW=190;
GensetData.Genset.MaxPower_kW=250;
GensetData.Genset.IdleFuel_Lph=2.6;
GensetData.Genset.StartFuel_L=0.08;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=45;
GensetData.Genset.MinOnTime_s=100;
GensetData.Genset.MinOffTime_s=75;
GensetData.Genset.RampRate_kW_s=65;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=1150;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-12";
GensetData.Engine.Name="Diesel Engine 12";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=260;
GensetData.Engine.BestBSFC_g_kWh=225;
GensetData.Engine.LowLoadBSFC_g_kWh=245;
GensetData.Engine.HighLoadBSFC_g_kWh=285;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-12";
GensetData.Generator.Name="Generator 12";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=250;
GensetData.Generator.PeakEfficiency=0.96;
GensetData.Generator.LowLoadEfficiency=0.93;
GensetData.Generator.VoltageClass_V=800;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.76;0.8;0.9;1], ...
    [259;251.270687964289;245;239.950895998794;235.04883491199;230.706670626057;227.337257027463;225.353448002675;225;227.579365079365;251.006944444444;285], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.76;0.8;0.9;1], ...
    [0.88;0.910085396681359;0.93;0.939159357092591;0.946869156529607;0.952959749170604;0.957261485875138;0.959604717502765;0.96;0.959649470899471;0.95615162037037;0.95], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
