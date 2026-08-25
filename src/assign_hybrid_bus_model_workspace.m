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
variables.vehicle_mass_kg=mass;
variables.gravity_m_s2=Input.Vehicle.Gravity_m_s2;
variables.rolling_coefficient=Input.Tyre.RollingResistanceCoefficient;
variables.air_density_kg_m3=Input.Environment.AirDensity_kg_m3;
variables.drag_coefficient=Input.Vehicle.DragCoefficient;
variables.frontal_area_m2=Input.Vehicle.FrontalArea_m2;
variables.final_drive_ratio=F.Ratio;
variables.tyre_radius_m=Input.Tyre.LoadedRadius_m;
variables.motor_max_speed_rpm=M.MaxSpeed_rpm;
variables.motor_traction_limit_kw=2*M.PeakPower_kW*F.MotoringEfficiency;
if strcmpi(Input.PowertrainMode,"BEV")
    batteryRegen=B1.MaxRegen_kW+variables.BEVUseTwoBatteries*B2.MaxRegen_kW;
else
    batteryRegen=min(B1.MaxRegen_kW,B2.MaxRegen_kW);
end
variables.motor_regen_limit_kw=min(2*M.PeakPower_kW*F.RegenEfficiency,batteryRegen);
variables.final_drive_motoring_efficiency=F.MotoringEfficiency;
variables.final_drive_regen_efficiency=F.RegenEfficiency;
variables.motor_motoring_efficiency=M.MotoringEfficiency;
variables.motor_regen_efficiency=M.RegenEfficiency;
variables.auxiliary_base_power_kw=Input.Aux.BasePower_kW+ ...
    abs(Input.Environment.Temperature_C-Input.Aux.ComfortTemperature_C)* ...
    max(Input.Aux.ColdHVAC_kW_per_C,Input.Aux.HotHVAC_kW_per_C);
variables.auxiliary_override=Input.AuxiliaryScalarOverride;
variables.battery_role_switch_soe=0.30;
variables.battery_full_detection_margin=1e-4;
variables.initial_active_battery_is_1=double(Input.InitialActiveBattery==1);
variables.genset_start_soe=Input.Control.GensetStartSOE;
variables.genset_stop_soe=Input.Control.GensetStopSOE;
variables.genset_charge_target_soe=Input.Control.GensetTargetSOE;
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
variables=battery_variables(variables,B1,Input.InitialBattery1SOE,'battery1');
variables=battery_variables(variables,B2,Input.InitialBattery2SOE,'battery2');
names=fieldnames(variables);
for index=1:numel(names),assignin('base',names{index},variables.(names{index}));end
end

function V=battery_variables(V,B,initialSOE,prefix)
V.(prefix+"_max_discharge_kw")=B.MaxDischarge_kW*B.DeratingFactor;
V.(prefix+"_max_charge_kw")=min(B.MaxCharge_kW,B.MaxRegen_kW)*B.DeratingFactor;
V.(prefix+"_discharge_efficiency")=B.DischargeEfficiency;
V.(prefix+"_charge_efficiency")=B.ChargeEfficiency;
V.(prefix+"_usable_energy_kwh")=B.UsableEnergy_kWh;
V.(prefix+"_max_soe")=B.MaxSOE;
V.(prefix+"_min_soe")=B.MinSOE;
V.(prefix+"_initial_energy_kwh")=initialSOE*B.UsableEnergy_kWh;
V.(prefix+"_max_energy_kwh")=B.MaxSOE*B.UsableEnergy_kWh;
V.(prefix+"_min_energy_kwh")=B.MinSOE*B.UsableEnergy_kWh;
end
