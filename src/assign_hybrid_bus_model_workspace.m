function [Input,variables] = assign_hybrid_bus_model_workspace(databaseFile,overrides)
%ASSIGN_HYBRID_BUS_MODEL_WORKSPACE Prepare stable variables for the SLX model.
arguments
    databaseFile (1,1) string = fullfile(hybrid_bus_project_root(), ...
        "data","HybridBus_ComponentDatabase.xlsx")
    overrides (1,1) struct = struct
end
Database=load_hybrid_bus_database(databaseFile);
Input=prepare_hybrid_bus_inputs(Database,overrides);
B1=Input.Battery1; B2=Input.Battery2; M=Input.Motor; F=Input.FinalDrive;
if isfield(Input.Mass,'TotalVehicleMass_kg')
    mass=Input.Mass.TotalVehicleMass_kg;
else
    batteryMass=B1.Mass_kg;
    if ~strcmpi(Input.PowertrainMode,"BEV") || Input.Battery2PackCount>0
        batteryMass=batteryMass+B2.Mass_kg;
    end
    gensetMass=Input.Genset.Mass_kg;
    if strcmpi(Input.PowertrainMode,"BEV"), gensetMass=0; end
    mass=Input.Mass.CurbMass_kg+Input.Mass.PassengerCount*Input.Mass.PassengerMass_kg+ ...
        Input.Mass.CargoMass_kg+batteryMass+2*M.Mass_kg+gensetMass+2*F.Mass_kg;
end
variables=struct;
variables.BEVUseTwoBatteries=double(Input.BEVUseTwoBatteries);
variables.battery_set_multiplier=Input.BatterySetMultiplier;
variables.battery1_pack_count=Input.Battery1PackCount;
variables.battery2_pack_count=Input.Battery2PackCount;
variables.total_battery_pack_count=Input.TotalBatteryPackCount;
variables.route_speed=[Input.Route.Time_s Input.Route.Speed_kmh/3.6];
variables.route_grade=[Input.Route.Time_s Input.Route.Grade_pct];
variables.route_aux_multiplier=[Input.Route.Time_s Input.Route.AuxMultiplier];
variables.model_sample_time_s=Input.Vehicle.SampleTime_s;
variables.model_stop_time_s=Input.Route.Time_s(end);
variables.acceleration_filter_tau_s=Input.Vehicle.AccelerationFilterTau_s;
variables.vehicle_mass_kg=mass;
variables.gravity_m_s2=Input.Vehicle.Gravity_m_s2;
variables.rolling_coefficient=Input.Tyre.RollingResistanceCoefficient;
variables.air_density_kg_m3=Input.Environment.AirDensity_kg_m3;
variables.drag_coefficient=Input.Vehicle.DragCoefficient;
variables.frontal_area_m2=Input.Vehicle.FrontalArea_m2;
variables.headwind_m_s=Input.Environment.Headwind_m_s;
variables.final_drive_ratio=F.Ratio;
variables.tyre_radius_m=Input.Tyre.LoadedRadius_m;
variables.motor_max_speed_rpm=M.MaxSpeed_rpm;
variables.motor_peak_power_kw=M.PeakPower_kW;
variables.motor_peak_torque_nm=M.PeakTorque_Nm;
variables.motor_loss_torque_breakpoints_nm=M.TorqueBreakpoints_Nm;
variables.motor_loss_speed_breakpoints_rpm=M.SpeedBreakpoints_rpm;
variables.motor_loss_map_kw=M.MotorLossMap_kW';
variables.motor_traction_limit_kw=2*M.PeakPower_kW*F.MotoringEfficiency;
[battery1DischargeCurrent,battery1ChargeCurrent,battery1OCV,battery1Resistance]=initial_limits(B1,Input.InitialBattery1SOE, ...
    Input.Environment.Temperature_C);
[battery2DischargeCurrent,battery2ChargeCurrent,battery2OCV,battery2Resistance]=initial_limits(B2,Input.InitialBattery2SOE, ...
    Input.Environment.Temperature_C);
battery1DischargeCurrent=battery1DischargeCurrent*B1.DeratingFactor;
battery2DischargeCurrent=battery2DischargeCurrent*B2.DeratingFactor;
battery1ChargeCurrent=battery1ChargeCurrent*B1.DeratingFactor;
battery2ChargeCurrent=battery2ChargeCurrent*B2.DeratingFactor;
battery1ChargePower=battery1ChargeCurrent*(battery1OCV+ ...
    battery1ChargeCurrent*battery1Resistance)/1000;
battery2ChargePower=battery2ChargeCurrent*(battery2OCV+ ...
    battery2ChargeCurrent*battery2Resistance)/1000;
if strcmpi(Input.PowertrainMode,"BEV")
    batteryRegen=battery1ChargePower+battery2ChargePower*variables.BEVUseTwoBatteries;
else
    batteryRegen=min(battery1ChargePower,battery2ChargePower);
end
variables.battery_regen_limit_kw=batteryRegen;
initialBattery1Power=battery1DischargeCurrent*(battery1OCV- ...
    battery1DischargeCurrent*battery1Resistance)/1000;
initialBattery2Power=battery2DischargeCurrent*(battery2OCV- ...
    battery2DischargeCurrent*battery2Resistance)/1000;
if strcmpi(Input.PowertrainMode,"BEV")
    initialBatteryPower=initialBattery1Power+variables.BEVUseTwoBatteries*initialBattery2Power;
elseif Input.InitialActiveBattery==1
    initialBatteryPower=initialBattery1Power;
else
    initialBatteryPower=initialBattery2Power;
end
variables.motor_regen_limit_kw=2*M.PeakPower_kW*F.RegenEfficiency;
variables.final_drive_motoring_efficiency=F.MotoringEfficiency;
variables.final_drive_regen_efficiency=F.RegenEfficiency;
variables.motor_motoring_efficiency=M.MotoringEfficiency;
variables.motor_regen_efficiency=M.RegenEfficiency;
variables.auxiliary_base_power_kw=Input.Aux.BasePower_kW+ ...
    abs(Input.Environment.Temperature_C-Input.Aux.ComfortTemperature_C)* ...
    max(Input.Aux.ColdHVAC_kW_per_C,Input.Aux.HotHVAC_kW_per_C);
variables.auxiliary_override=Input.AuxiliaryScalarOverride;
variables.performance_battery_available_power_kw=max(0,initialBatteryPower- ...
    variables.auxiliary_base_power_kw*variables.auxiliary_override);
routeDistance=round(Input.Route.Distance_m(:),3);
[variables.performance_route_distance_m,~,routeGroups]=unique(routeDistance,'stable');
variables.performance_route_speed_m_s=splitapply(@max,Input.Route.Speed_kmh(:)/3.6,routeGroups);
variables.performance_route_grade_pct=splitapply(@mean,Input.Route.Grade_pct(:),routeGroups);
variables.performance_route_aux_multiplier=splitapply(@mean,Input.Route.AuxMultiplier(:),routeGroups);
variables.performance_driver_kp_s=Input.Performance.DriverProportionalGain_s;
variables.performance_max_acceleration_m_s2=Input.Performance.MaximumAcceleration_m_s2;
variables.performance_max_deceleration_m_s2=Input.Performance.MaximumDeceleration_m_s2;
variables.performance_low_speed_protection_m_s=Input.Performance.LowSpeedProtection_m_s;
variables.performance_motor_wheel_force_limit_n=2*M.PeakTorque_Nm*F.Ratio* ...
    F.MotoringEfficiency/max(Input.Tyre.LoadedRadius_m,0.1);
variables.battery_role_switch_soe=0.30;
variables.battery_full_detection_margin=1e-4;
variables.initial_active_battery_is_1=double(Input.InitialActiveBattery==1);
variables.genset_start_soe=Input.Control.GensetStartSOE;
variables.genset_stop_soe=Input.Control.GensetStopSOE;
% The implemented supervisory rule charges the standby pack to its usable
% upper bound. Keep the independent Simulink relay aligned with the same
% rule rather than the legacy intermediate calibration target.
variables.genset_charge_target_soe=min(B1.MaxSOE,B2.MaxSOE);
variables.genset_optimum_power_kw=Input.Genset.OptimumPower_kW;
variables.genset_max_power_kw=Input.Genset.MaxPower_kW;
loadFraction=Input.Genset.OptimumPower_kW/Input.Genset.MaxPower_kW;
eta=interp1(Input.GeneratorMap.NormalizedGeneratorLoad, ...
    Input.GeneratorMap.Efficiency,loadFraction,'linear','extrap');
bsfc=interp1(Input.FuelMap.NormalizedEngineLoad,Input.FuelMap.BSFC_g_kWh, ...
    loadFraction,'linear','extrap');
variables.genset_fuel_L_per_kWh=bsfc/1000/Input.Genset.FuelDensity_kg_L/max(eta,0.7);
variables.fuel_price_per_L=Input.Prices.FuelPrice_per_L;
variables.electricity_price_per_kWh=Input.Prices.ElectricityPrice_per_kWh;
variables.grid_charge_efficiency=Input.Vehicle.GridChargeEfficiency;
variables.battery_temperature_c=Input.Environment.Temperature_C;
variables=battery_variables(variables,B1,Input.InitialBattery1SOE, ...
    Input.Environment.Temperature_C,'battery1');
variables=battery_variables(variables,B2,Input.InitialBattery2SOE, ...
    Input.Environment.Temperature_C,'battery2');
names=fieldnames(variables);
for index=1:numel(names),assignin('base',names{index},variables.(names{index}));end
end

function V=battery_variables(V,B,initialSOE,temperature_C,prefix)
[dischargeLimit,chargeLimit]=initial_limits(B,initialSOE,temperature_C);
V.(prefix+"_max_discharge_a")=dischargeLimit*B.DeratingFactor;
V.(prefix+"_max_charge_a")=chargeLimit*B.DeratingFactor;
V.(prefix+"_soe_breakpoints")=B.SOEBreakpoints;
V.(prefix+"_soc_breakpoints")=B.SOCBreakpoints;
V.(prefix+"_temperature_breakpoints_c")=B.TemperatureBreakpoints_C;
% Simulink n-D Lookup Table dimension 1 is SOE and dimension 2 is temperature.
V.(prefix+"_discharge_current_map_a")=B.MaxDischargeCurrentMap_A';
V.(prefix+"_charge_current_map_a")=B.MaxChargeCurrentMap_A';
V.(prefix+"_ocv_map_v")=B.OpenCircuitVoltageMap_V';
V.(prefix+"_internal_resistance_map_ohm")=B.InternalResistanceMap_Ohm';
V.(prefix+"_nominal_voltage_v")=B.NominalVoltage_V;
V.(prefix+"_min_voltage_v")=B.MinVoltage_V;
V.(prefix+"_max_voltage_v")=B.MaxVoltage_V;
V.(prefix+"_discharge_efficiency")=B.DischargeEfficiency;
V.(prefix+"_charge_efficiency")=B.ChargeEfficiency;
V.(prefix+"_usable_energy_kwh")=B.UsableEnergy_kWh;
V.(prefix+"_max_soe")=B.MaxSOE;
V.(prefix+"_min_soe")=B.MinSOE;
V.(prefix+"_initial_energy_kwh")=initialSOE*B.UsableEnergy_kWh;
V.(prefix+"_max_energy_kwh")=B.MaxSOE*B.UsableEnergy_kWh;
V.(prefix+"_min_energy_kwh")=B.MinSOE*B.UsableEnergy_kWh;
end

function [dischargeLimit,chargeLimit,openCircuitVoltage,resistance]= ...
        initial_limits(B,soe,temperature_C)
soe=min(max(soe,B.SOEBreakpoints(1)),B.SOEBreakpoints(end));
temperature_C=min(max(temperature_C,B.TemperatureBreakpoints_C(1)), ...
    B.TemperatureBreakpoints_C(end));
dischargeLimit=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.MaxDischargeCurrentMap_A,soe,temperature_C,'linear');
chargeLimit=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.MaxChargeCurrentMap_A,soe,temperature_C,'linear');
openCircuitVoltage=interp2(B.SOCBreakpoints,B.TemperatureBreakpoints_C, ...
    B.OpenCircuitVoltageMap_V,soe,temperature_C,'linear');
resistance=interp2(B.SOEBreakpoints,B.TemperatureBreakpoints_C, ...
    B.InternalResistanceMap_Ohm,soe,temperature_C,'linear');
end
