% MOT-08 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=8;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-08";
MotorData.Component.Name="Rear Hub Motor 08";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=269.090909090909;
MotorData.Component.ContinuousPower_kW=180;
MotorData.Component.PeakTorque_Nm=3345.45454545455;
MotorData.Component.ContinuousTorque_Nm=1927.27272727273;
MotorData.Component.MaxSpeed_rpm=5090.90909090909;
MotorData.Component.BaseSpeed_rpm=1409.09090909091;
MotorData.Component.MotoringEfficiency=0.938181818181818;
MotorData.Component.RegenEfficiency=0.862727272727273;
MotorData.Component.Mass_kg=153.636363636364;
MotorData.Component.VoltageClass_V=750;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=11.0909090909091;
MotorData.Component.MaxReductionRatio=17.6363636363636;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 669.090909090909 1338.18181818182 2007.27272727273 2676.36363636364 3345.45454545455];
MotorData.SpeedBreakpoints_rpm=[0 1018.18181818182 2036.36363636364 3054.54545454545 4072.72727272727 5090.90909090909];
MotorData.MotorLossMap_kW=[0 0.269090909090909 1.07636363636364 2.42181818181818 4.30545454545455 6.72727272727273;0.288818671130155 0.644018671130155 1.53740048931197 2.96896412567561 4.93870958022107 7.44663685294834;0.816902563557679 1.25821165446677 2.23770256355768 3.75537529083041 5.81122983628495 8.40526619992132;1.50074583771586 2.02816401953404 3.09376401953405 4.69754583771586 6.8395094740795 9.51965492862496;2.31054936904124 2.92407664176851 4.0757857326776 5.76567664176851 7.99374936904124 10.7600039144958;3.22909090909091 3.92872727272727 5.16654545454546 6.94254545454545 9.25672727272728 12.1090909090909];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
