% MOT-01 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=1;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-01";
MotorData.Component.Name="Rear Hub Motor 01";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=180;
MotorData.Component.ContinuousPower_kW=110;
MotorData.Component.PeakTorque_Nm=2200;
MotorData.Component.ContinuousTorque_Nm=1100;
MotorData.Component.MaxSpeed_rpm=3500;
MotorData.Component.BaseSpeed_rpm=900;
MotorData.Component.MotoringEfficiency=0.9;
MotorData.Component.RegenEfficiency=0.78;
MotorData.Component.Mass_kg=90;
MotorData.Component.VoltageClass_V=600;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=6;
MotorData.Component.MaxReductionRatio=10;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 440 880 1320 1760 2200];
MotorData.SpeedBreakpoints_rpm=[0 700 1400 2100 2800 3500];
MotorData.MotorLossMap_kW=[0 0.18 0.72 1.62 2.88 4.5;0.193196273255982 0.430796273255982 1.02839627325598 1.98599627325598 3.30359627325598 4.98119627325598;0.546441579677096 0.841641579677096 1.4968415796771 2.5120415796771 3.8872415796771 5.6224415796771;1.00387728333696 1.35667728333696 2.06947728333696 3.14227728333696 4.57507728333696 6.36787728333696;1.54557018604786 1.95597018604786 2.72637018604786 3.85677018604785 5.34717018604786 7.19757018604786;2.16 2.628 3.456 4.644 6.192 8.1];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
