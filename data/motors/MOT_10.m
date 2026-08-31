% MOT-10 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=10;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-10";
MotorData.Component.Name="Rear Hub Motor 10";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=294.545454545455;
MotorData.Component.ContinuousPower_kW=200;
MotorData.Component.PeakTorque_Nm=3672.72727272727;
MotorData.Component.ContinuousTorque_Nm=2163.63636363636;
MotorData.Component.MaxSpeed_rpm=5545.45454545455;
MotorData.Component.BaseSpeed_rpm=1554.54545454545;
MotorData.Component.MotoringEfficiency=0.949090909090909;
MotorData.Component.RegenEfficiency=0.886363636363636;
MotorData.Component.Mass_kg=171.818181818182;
MotorData.Component.VoltageClass_V=750;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=12.5454545454545;
MotorData.Component.MaxReductionRatio=19.8181818181818;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 734.545454545455 1469.09090909091 2203.63636363636 2938.18181818182 3672.72727272727];
MotorData.SpeedBreakpoints_rpm=[0 1109.09090909091 2218.18181818182 3327.27272727273 4436.36363636364 5545.45454545455];
MotorData.MotorLossMap_kW=[0 0.294545454545455 1.17818181818182 2.65090909090909 4.71272727272727 7.36363636363636;0.316139356237061 0.704939356237061 1.68283026532797 3.24981208350979 5.40588481078252 8.15104844714615;0.894177130380703 1.37723167583525 2.4493771303807 4.11061349401707 6.36094076674434 9.20035894856252;1.64270828182412 2.22001737273321 3.38641737273321 5.14190828182412 7.48649010000594 10.4201628272787;2.52911484989649 3.20067848626013 4.46133303171467 6.31107848626013 8.74991484989649 11.7778421226238;3.53454545454545 4.30036363636364 5.65527272727273 7.59927272727273 10.1323636363636 13.2545454545455];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
