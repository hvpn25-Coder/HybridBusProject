% MOT-02 — generated motor component data
MotorData=struct;
MotorData.SchemaVersion="2.0.0";
MotorData.StorageOrder=2;
MotorData.Component=struct;
MotorData.Component.ComponentID="MOT-02";
MotorData.Component.Name="Rear Hub Motor 02";
MotorData.Component.Manufacturer="Concept Manufacturer";
MotorData.Component.PeakPower_kW=192.727272727273;
MotorData.Component.ContinuousPower_kW=120;
MotorData.Component.PeakTorque_Nm=2363.63636363636;
MotorData.Component.ContinuousTorque_Nm=1218.18181818182;
MotorData.Component.MaxSpeed_rpm=3727.27272727273;
MotorData.Component.BaseSpeed_rpm=972.727272727273;
MotorData.Component.MotoringEfficiency=0.905454545454546;
MotorData.Component.RegenEfficiency=0.791818181818182;
MotorData.Component.Mass_kg=99.0909090909091;
MotorData.Component.VoltageClass_V=600;
MotorData.Component.WheelSideCompatibility="Rear wheel hub";
MotorData.Component.MinReductionRatio=6.72727272727273;
MotorData.Component.MaxReductionRatio=11.0909090909091;
MotorData.Component.OptimizationEnabled=true;
MotorData.Component.Notes="Synthetic rear-hub motor concept data with torque-speed loss map";
% Motor loss map: rows are speed, columns are absolute torque.
MotorData.TorqueBreakpoints_Nm=[0 472.727272727273 945.454545454545 1418.18181818182 1890.90909090909 2363.63636363636];
MotorData.SpeedBreakpoints_rpm=[0 745.454545454545 1490.90909090909 2236.36363636364 2981.81818181818 3727.27272727273];
MotorData.MotorLossMap_kW=[0 0.192727272727273 0.770909090909091 1.73454545454545 3.08363636363636 4.81818181818182;0.206856615809435 0.461256615809435 1.10111116126398 2.12642025217307 3.53718388853671 5.33340207035489;0.585078863088608 0.901151590361335 1.60267886308861 2.68966068127043 4.16209704490679 6.0199879539977;1.07485850539109 1.45260395993655 2.21580395993655 3.36445850539109 4.89856759630018 6.81813123266382;1.65485292647548 2.09427110829366 2.91914383556639 4.12947110829366 5.72525292647548 7.70648929011185;2.31272727272727 2.81381818181818 3.70036363636364 4.97236363636364 6.62981818181818 8.67272727272727];
MotorData.MapBasis="Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data";
