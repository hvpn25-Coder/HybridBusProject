% MOT-09 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=9;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-09";
MotorData.Component.Name="Rear Hub Motor 09";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=281.818181818182;
MotorData.Component.ContinuousPower_kW=190;
MotorData.Component.PeakTorque_Nm=3509.09090909091;
MotorData.Component.ContinuousTorque_Nm=2045.45454545455;
MotorData.Component.MaxSpeed_rpm=5318.18181818182;
MotorData.Component.BaseSpeed_rpm=1481.81818181818;
MotorData.Component.MotoringEfficiency=0.943636363636364;
MotorData.Component.RegenEfficiency=0.874545454545455;
MotorData.Component.Mass_kg=162.727272727273;
MotorData.Component.VoltageClass_V=750;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=11.8181818181818;
MotorData.Component.MaxReductionRatio=18.7272727272727;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 701.818181818182 1403.63636363636 2105.45454545455 2807.27272727273 3509.09090909091];
MotorData.SpeedBreakpoints_rpm=[0 1063.63636363636 2127.27272727273 3190.90909090909 4254.54545454545 5318.18181818182];
MotorData.MotorLossMap_kW=[0 0.281818181818182 1.12727272727273 2.53636363636364 4.50909090909091 7.04545454545455;0.302479013683608 0.674479013683608 1.61011537731997 3.1093881045927 5.17229719550179 7.79884265004724;0.855539846969191 1.31772166515101 2.34353984696919 3.93299439242374 6.08608530151465 8.80281257424192;1.57172705976999 2.12409069613363 3.24009069613363 4.91972705976999 7.16299978704272 9.96990887795181;2.41983210946886 3.06237756401432 4.26855938219614 6.03837756401432 8.37183210946886 11.2689230185598;3.38181818181818 4.11454545454546 5.41090909090909 7.27090909090909 9.69454545454546 12.6818181818182];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
