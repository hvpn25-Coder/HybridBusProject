# Signal Dictionary

| Group | Signal | Unit | Meaning |
|---|---|---:|---|
| Vehicle | Speed_m_s | m/s | Prescribed speed in Backward mode; achieved speed in Constrained and Performance modes |
| Vehicle | DesiredSpeed_m_s | m/s | Route target speed; equals prescribed speed in Backward mode |
| Vehicle | SpeedError_m_s | m/s | Desired minus achieved speed; zero in prescribed-speed Backward mode |
| Vehicle | Acceleration_m_s2 | m/s² | Filtered prescribed acceleration in Backward mode; component-limited integrated acceleration in Constrained and Performance modes |
| Vehicle | DesiredAcceleration_m_s2 | m/s² | Driver acceleration command before component capability limits |
| Vehicle | Distance_m | m | Prescribed route distance in Backward mode; nonnegative actual travelled distance in Constrained and Performance modes |
| Vehicle | Grade_pct | % | Route grade sampled at actual distance in Constrained and Performance modes |
| Vehicle | TractiveForceDemand_N / TractiveForce_N | N | Driver/road-load force request and force delivered by the limited powertrain |
| Vehicle | LimitingCause | text | Dominant instantaneous battery, motor, regeneration, or sustained-stall limitation |
| Wheel | Demand_kW / Delivered_kW | kW | Requested and limited wheel power |
| Wheel | UnmetTraction_kW / UnmetRegen_kW | kW | Limit shortfalls |
| Motors | ElectricalPower_kW | kW | Positive DC load, negative regeneration |
| Motors | MechanicalPower_kW | kW | Signed motor-pair shaft power after fixed-reduction losses |
| Motors | LossPower_kW | kW | Nonnegative combined loss of both motors from the torque-speed map |
| Motors | PairTorque_Nm / PerMotorTorque_Nm | N m | Signed shaft torque for the pair and one motor |
| Motors | MotorSpeed_rpm | rpm | Fixed-ratio motor speed |
| Auxiliary | Power_kW | kW | Base + HVAC + route multiplier |
| Battery1/2 | Power_kW | kW | Positive discharge, negative charge |
| Battery1/2 | Energy_kWh / SOE | kWh / 1 | Usable stored energy and normalized state |
| Genset | ElectricalPower_kW | kW | Constant standby-charger output when on |
| Genset | MechanicalPower_kW | kW | Engine shaft equivalent |
| Genset | FuelRate_L_s | L/s | Map-based instantaneous fuel rate |
| Genset | ChargeDestinationBattery | 0, 1 or 2 | Standby pack receiving genset power; zero when off |
| Battery1/2 | Temperature_C | degC | Temperature used for dynamic battery-map lookup; ambient proxy |
| Battery1/2 | InternalResistance_Ohm | ohm | SOE/temperature-dependent first-order resistance |
| Battery1/2 | OpenCircuitVoltage_V | V | Bilinearly interpolated SOE/temperature open-circuit voltage estimate |
| Battery1/2 | OhmicLoss_kW | kW | Estimated resistance loss, I-squared-R |
| Battery1/2 | DischargeCurrentLimit_A | A | Instantaneous SOE/temperature-, voltage-, and energy-bounded discharge-current limit |
| Battery1/2 | ChargeCurrentLimit_A | A | Instantaneous SOE/temperature-, voltage-, and energy-bounded charge-current limit |
| Battery1/2 | DerivedDischargePowerCapability_kW | kW | Terminal discharge capability derived from current limit, OCV, and resistance |
| Battery1/2 | DerivedChargePowerCapability_kW | kW | Terminal charge capability derived from current limit, OCV, and resistance |
| Controller | ActiveBattery | 1 or 2 | Sole traction-discharge pack |
| Controller | StandbyBattery | 1 or 2 | Pack isolated from traction and eligible for genset charging |
| Controller | BatteryRoleSwitchSOE | 1 | Fixed 0.30 architecture threshold |
| Controller | Mode | integer | Supervisory operating mode |
| Energy | BalanceResidual_kW | kW | DC power conservation residual |
| Energy | UnmetDCPower_kW | kW | Load not supplied after limits |
| Energy | RejectedCharge_kW | kW | Regen/genset source not accepted |
