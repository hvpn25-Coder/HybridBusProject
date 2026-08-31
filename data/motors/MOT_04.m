% MOT-04 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=4;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-04";
MotorData.Component.Name="Rear Hub Motor 04";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=218.181818181818;
MotorData.Component.ContinuousPower_kW=140;
MotorData.Component.PeakTorque_Nm=2690.90909090909;
MotorData.Component.ContinuousTorque_Nm=1454.54545454545;
MotorData.Component.MaxSpeed_rpm=4181.81818181818;
MotorData.Component.BaseSpeed_rpm=1118.18181818182;
MotorData.Component.MotoringEfficiency=0.916363636363636;
MotorData.Component.RegenEfficiency=0.815454545454545;
MotorData.Component.Mass_kg=117.272727272727;
MotorData.Component.VoltageClass_V=650;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=8.18181818181818;
MotorData.Component.MaxReductionRatio=13.2727272727273;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 538.181818181818 1076.36363636364 1614.54545454545 2152.72727272727 2690.90909090909];
MotorData.SpeedBreakpoints_rpm=[0 836.363636363636 1672.72727272727 2509.09090909091 3345.45454545455 4181.81818181818];
MotorData.MotorLossMap_kW=[0 0.218181818181818 0.872727272727273 1.96363636363636 3.49090909090909 5.45454545454546;0.234177300916342 0.522177300916342 1.24654093727998 2.40726821000725 4.00435911909816 6.03781366455271;0.662353429911632 1.02017161172981 1.81435342991163 3.04489888445709 4.71180797536618 6.81508070263891;1.21682094949935 1.64445731313571 2.50845731313571 3.80882094949935 5.54554822222662 7.71863913131753;1.87341840733073 2.37087295278528 3.30469113460346 4.67487295278528 6.48141840733073 8.72432749823983;2.61818181818182 3.18545454545455 4.18909090909091 5.62909090909091 7.50545454545455 9.81818181818182];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
