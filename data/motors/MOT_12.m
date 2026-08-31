% MOT-12 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=12;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-12";
MotorData.Component.Name="Rear Hub Motor 12";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=320;
MotorData.Component.ContinuousPower_kW=220;
MotorData.Component.PeakTorque_Nm=4000;
MotorData.Component.ContinuousTorque_Nm=2400;
MotorData.Component.MaxSpeed_rpm=12000;
MotorData.Component.BaseSpeed_rpm=3800;
MotorData.Component.MotoringEfficiency=0.96;
MotorData.Component.RegenEfficiency=0.91;
MotorData.Component.Mass_kg=190;
MotorData.Component.VoltageClass_V=800;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=14;
MotorData.Component.MaxReductionRatio=22;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 800 1600 2400 3200 4000];
MotorData.SpeedBreakpoints_rpm=[0 1200 2400 3600 8800 12000];
MotorData.MotorLossMap_kW=[0 0.32 1.28 2.88 5.12 8;0.343460041343968 0.765860041343968 1.82826004134397 3.53066004134397 5.87306004134397 8.85546004134397;0.971451697203726 1.49625169720373 2.66105169720373 4.46585169720373 6.91065169720373 9.99545169720373;1.78467072593238 2.41187072593238 3.67907072593238 5.58627072593238 8.13347072593238 11.3206707259324;2.74768033075174 3.47728033075174 4.84688033075174 6.85648033075174 9.50608033075174 12.7956803307517;3.84 4.672 6.144 8.256 11.008 14.4];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
