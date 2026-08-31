% GEN-01 — complete engine-generator set data
% One self-contained record: genset, engine, generator, and performance maps.
GensetData=struct;
GensetData.SchemaVersion="1.0.0";
GensetData.StorageOrder=1;
GensetData.Genset=struct;
GensetData.Genset.ComponentID="GEN-01";
GensetData.Genset.Name="Engine Genset 01";
GensetData.Genset.Manufacturer="Concept Manufacturer";
GensetData.Genset.EngineRatedPower_kW=120;
GensetData.Genset.GeneratorRatedPower_kW=110;
GensetData.Genset.MinStablePower_kW=25;
GensetData.Genset.OptimumPower_kW=85;
GensetData.Genset.MaxPower_kW=110;
GensetData.Genset.IdleFuel_Lph=1.5;
GensetData.Genset.StartFuel_L=0.04;
GensetData.Genset.FuelDensity_kg_L=0.835;
GensetData.Genset.WarmupTime_s=20;
GensetData.Genset.MinOnTime_s=60;
GensetData.Genset.MinOffTime_s=45;
GensetData.Genset.RampRate_kW_s=35;
GensetData.Genset.StartStopEnable=true;
GensetData.Genset.Mass_kg=700;
GensetData.Genset.FuelType="Diesel";
GensetData.Genset.Notes="Synthetic engineering concept data";
GensetData.Engine=struct;
GensetData.Engine.ComponentID="ENG-01";
GensetData.Engine.Name="Diesel Engine 01";
GensetData.Engine.Manufacturer="Concept Manufacturer";
GensetData.Engine.RatedPower_kW=120;
GensetData.Engine.BestBSFC_g_kWh=190;
GensetData.Engine.LowLoadBSFC_g_kWh=205;
GensetData.Engine.HighLoadBSFC_g_kWh=240;
GensetData.Engine.OptimizationEnabled=true;
GensetData.Engine.Notes="Synthetic engineering concept data";
GensetData.Generator=struct;
GensetData.Generator.ComponentID="GNR-01";
GensetData.Generator.Name="Generator 01";
GensetData.Generator.Manufacturer="Concept Manufacturer";
GensetData.Generator.RatedPower_kW=110;
GensetData.Generator.PeakEfficiency=0.91;
GensetData.Generator.LowLoadEfficiency=0.87;
GensetData.Generator.VoltageClass_V=600;
GensetData.Generator.OptimizationEnabled=true;
GensetData.Generator.Notes="Synthetic engineering concept data";
GensetData.EngineFuelMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.772727272727273;0.8;0.9;1], ...
    [217.25;210.347394819844;205;201.115826516426;197.467801620259;194.296661897641;191.843143934715;190.347984317624;190;191.152171428571;210.385866666667;240], ...
    'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
GensetData.GeneratorEfficiencyMap=table( ...
    [0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.772727272727273;0.8;0.9;1], ...
    [0.82;0.849414384760659;0.87;0.881411545324337;0.891396034452369;0.899594425506923;0.905647676610826;0.909196745886904;0.91;0.909822422857143;0.906498382222222;0.9], ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
