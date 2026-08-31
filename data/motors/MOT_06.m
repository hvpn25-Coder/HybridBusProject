% MOT-06 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=6;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-06";
MotorData.Component.Name="Rear Hub Motor 06";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=243.636363636364;
MotorData.Component.ContinuousPower_kW=160;
MotorData.Component.PeakTorque_Nm=3018.18181818182;
MotorData.Component.ContinuousTorque_Nm=1690.90909090909;
MotorData.Component.MaxSpeed_rpm=4636.36363636364;
MotorData.Component.BaseSpeed_rpm=1263.63636363636;
MotorData.Component.MotoringEfficiency=0.927272727272727;
MotorData.Component.RegenEfficiency=0.839090909090909;
MotorData.Component.Mass_kg=135.454545454545;
MotorData.Component.VoltageClass_V=700;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=9.63636363636364;
MotorData.Component.MaxReductionRatio=15.4545454545455;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 603.636363636364 1207.27272727273 1810.90909090909 2414.54545454545 3018.18181818182];
MotorData.SpeedBreakpoints_rpm=[0 927.272727272727 1854.54545454545 2781.81818181818 3709.09090909091 4636.36363636364];
MotorData.MotorLossMap_kW=[0 0.243636363636364 0.974545454545455 2.19272727272727 3.89818181818182 6.09090909090909;0.261497986023248 0.583097986023248 1.39197071329598 2.68811616784143 4.47153434965961 6.74222525875052;0.739627996734655 1.13919163309829 2.02602799673466 3.40013708764375 5.26151890582556 7.61017345128011;1.35878339360761 1.83631066633488 2.80111066633488 4.25318339360761 6.19252884815306 8.61914702997124;2.09198388818599 2.64747479727689 3.69023843364053 5.22027479727689 7.23758388818599 9.74216570636781;2.92363636363636 3.55709090909091 4.67781818181818 6.28581818181818 8.38109090909091 10.9636363636364];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
