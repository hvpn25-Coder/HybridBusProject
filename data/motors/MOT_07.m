% MOT-07 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=7;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-07";
MotorData.Component.Name="Rear Hub Motor 07";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=256.363636363636;
MotorData.Component.ContinuousPower_kW=170;
MotorData.Component.PeakTorque_Nm=3181.81818181818;
MotorData.Component.ContinuousTorque_Nm=1809.09090909091;
MotorData.Component.MaxSpeed_rpm=4863.63636363636;
MotorData.Component.BaseSpeed_rpm=1336.36363636364;
MotorData.Component.MotoringEfficiency=0.932727272727273;
MotorData.Component.RegenEfficiency=0.850909090909091;
MotorData.Component.Mass_kg=144.545454545455;
MotorData.Component.VoltageClass_V=700;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=10.3636363636364;
MotorData.Component.MaxReductionRatio=16.5454545454545;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 636.363636363636 1272.72727272727 1909.09090909091 2545.45454545455 3181.81818181818];
MotorData.SpeedBreakpoints_rpm=[0 972.727272727273 1945.45454545455 2918.18181818182 3890.90909090909 4863.63636363636];
MotorData.MotorLossMap_kW=[0 0.256363636363636 1.02545454545455 2.30727272727273 4.10181818181818 6.40909090909091;0.275158328576701 0.613558328576702 1.46468560130397 2.82854014675852 4.70512196494034 7.09443105584943;0.778265280146167 1.19870164378253 2.13186528014617 3.57775618923708 5.53637437105526 8.00771982560071;1.42976461566173 1.93223734293446 2.94743734293446 4.47536461566173 6.51601916111628 9.0694009792981;2.20126662861361 2.7857757195227 3.88301208315907 5.4929757195227 7.61566662861361 10.2510848104318;3.07636363636364 3.74290909090909 4.92218181818182 6.61418181818182 8.81890909090909 11.5363636363636];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
