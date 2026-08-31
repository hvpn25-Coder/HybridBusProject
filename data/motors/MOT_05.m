% MOT-05 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=5;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-05";
MotorData.Component.Name="Rear Hub Motor 05";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=230.909090909091;
MotorData.Component.ContinuousPower_kW=150;
MotorData.Component.PeakTorque_Nm=2854.54545454545;
MotorData.Component.ContinuousTorque_Nm=1572.72727272727;
MotorData.Component.MaxSpeed_rpm=4409.09090909091;
MotorData.Component.BaseSpeed_rpm=1190.90909090909;
MotorData.Component.MotoringEfficiency=0.921818181818182;
MotorData.Component.RegenEfficiency=0.827272727272727;
MotorData.Component.Mass_kg=126.363636363636;
MotorData.Component.VoltageClass_V=650;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=8.90909090909091;
MotorData.Component.MaxReductionRatio=14.3636363636364;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 570.909090909091 1141.81818181818 1712.72727272727 2283.63636363636 2854.54545454545];
MotorData.SpeedBreakpoints_rpm=[0 881.818181818182 1763.63636363636 2645.45454545455 3527.27272727273 4409.09090909091];
MotorData.MotorLossMap_kW=[0 0.230909090909091 0.923636363636364 2.07818181818182 3.69454545454546 5.77272727272727;0.247837643469795 0.552637643469795 1.31925582528798 2.54769218892434 4.23794673437889 6.39001946165161;0.700990713323143 1.07968162241405 1.92019071332314 3.22251798605042 4.98666344059587 7.21262707695951;1.28780217155348 1.7403839897353 2.6547839897353 4.03100217155348 5.86903853518984 8.16889308064439;1.98270114775836 2.50917387503109 3.497464784122 4.94757387503109 6.85950114775836 9.23324660230382;2.77090909090909 3.37127272727273 4.43345454545455 5.95745454545454 7.94327272727273 10.3909090909091];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
