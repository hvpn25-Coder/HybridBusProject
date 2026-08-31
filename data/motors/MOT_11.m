% MOT-11 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=11;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-11";
MotorData.Component.Name="Rear Hub Motor 11";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=307.272727272727;
MotorData.Component.ContinuousPower_kW=210;
MotorData.Component.PeakTorque_Nm=3836.36363636364;
MotorData.Component.ContinuousTorque_Nm=2281.81818181818;
MotorData.Component.MaxSpeed_rpm=5772.72727272727;
MotorData.Component.BaseSpeed_rpm=1627.27272727273;
MotorData.Component.MotoringEfficiency=0.954545454545454;
MotorData.Component.RegenEfficiency=0.898181818181818;
MotorData.Component.Mass_kg=180.909090909091;
MotorData.Component.VoltageClass_V=800;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=13.2727272727273;
MotorData.Component.MaxReductionRatio=20.9090909090909;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 767.272727272727 1534.54545454545 2301.81818181818 3069.09090909091 3836.36363636364];
MotorData.SpeedBreakpoints_rpm=[0 1154.54545454545 2309.09090909091 3463.63636363636 4618.18181818182 5772.72727272727];
MotorData.MotorLossMap_kW=[0 0.307272727272727 1.22909090909091 2.76545454545455 4.91636363636364 7.68181818181818;0.329799698790515 0.735399698790514 1.75554515333597 3.39023606242688 5.63947242606324 8.50325424424506;0.932814413792214 1.43674168651949 2.55521441379221 4.2882325956104 6.63579623197403 9.59790532288312;1.71368950387825 2.31594404933279 3.53274404933279 5.36408950387825 7.80998041296916 10.8704167766055;2.63839759032412 3.33897940850593 4.65410668123321 6.58377940850593 9.12799759032412 12.2867612266878;3.68727272727273 4.48618181818182 5.89963636363636 7.92763636363636 10.5701818181818 13.8272727272727];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
