% MOT-03 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=3;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-03";
MotorData.Component.Name="Rear Hub Motor 03";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=205.454545454545;
MotorData.Component.ContinuousPower_kW=130;
MotorData.Component.PeakTorque_Nm=2527.27272727273;
MotorData.Component.ContinuousTorque_Nm=1336.36363636364;
MotorData.Component.MaxSpeed_rpm=3954.54545454545;
MotorData.Component.BaseSpeed_rpm=1045.45454545455;
MotorData.Component.MotoringEfficiency=0.910909090909091;
MotorData.Component.RegenEfficiency=0.803636363636364;
MotorData.Component.Mass_kg=108.181818181818;
MotorData.Component.VoltageClass_V=650;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=7.45454545454546;
MotorData.Component.MaxReductionRatio=12.1818181818182;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 505.454545454545 1010.90909090909 1516.36363636364 2021.81818181818 2527.27272727273];
MotorData.SpeedBreakpoints_rpm=[0 790.909090909091 1581.81818181818 2372.72727272727 3163.63636363636 3954.54545454545];
MotorData.MotorLossMap_kW=[0 0.205454545454546 0.821818181818182 1.84909090909091 3.28727272727273 5.13636363636364;0.220516958362888 0.491716958362888 1.17382604927198 2.26684423109016 3.77077150381743 5.6856078674538;0.62371614650012 0.960661601045574 1.70851614650012 2.86727978286376 4.43695251013648 6.4175343283183;1.14583972744522 1.54853063653613 2.36213063653613 3.58663972744522 5.2220579092634 7.26838518199067;1.76413566690311 2.23257203053947 3.11191748508493 4.40217203053947 6.10333566690311 8.21540839417584;2.46545454545455 2.99963636363636 3.94472727272727 5.30072727272727 7.06763636363636 9.24545454545455];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
