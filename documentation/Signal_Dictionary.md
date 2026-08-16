# Signal Dictionary

| Group | Signal | Unit | Meaning |
|---|---|---:|---|
| Vehicle | Speed_m_s | m/s | Prescribed route speed |
| Vehicle | Acceleration_m_s2 | m/s² | 0.3 s filtered finite difference |
| Wheel | Demand_kW / Delivered_kW | kW | Requested and limited wheel power |
| Wheel | UnmetTraction_kW / UnmetRegen_kW | kW | Limit shortfalls |
| Motors | ElectricalPower_kW | kW | Positive DC load, negative regeneration |
| Motors | MotorSpeed_rpm | rpm | Fixed-ratio motor speed |
| Auxiliary | Power_kW | kW | Base + HVAC + route multiplier |
| Battery1/2 | Power_kW | kW | Positive discharge, negative charge |
| Battery1/2 | Energy_kWh / SOE | kWh / 1 | Usable stored energy and normalized state |
| Genset | ElectricalPower_kW | kW | Constant standby-charger output when on |
| Genset | MechanicalPower_kW | kW | Engine shaft equivalent |
| Genset | FuelRate_L_s | L/s | Map-based instantaneous fuel rate |
| Genset | ChargeDestinationBattery | 0, 1 or 2 | Standby pack receiving genset power; zero when off |
| Controller | ActiveBattery | 1 or 2 | Sole traction-discharge pack |
| Controller | StandbyBattery | 1 or 2 | Pack isolated from traction and eligible for genset charging |
| Controller | BatteryRoleSwitchSOE | 1 | Fixed 0.30 architecture threshold |
| Controller | Mode | integer | Supervisory operating mode |
| Energy | BalanceResidual_kW | kW | DC power conservation residual |
| Energy | UnmetDCPower_kW | kW | Load not supplied after limits |
| Energy | RejectedCharge_kW | kW | Regen/genset source not accepted |
