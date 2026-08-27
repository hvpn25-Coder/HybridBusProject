# Excel Data Dictionary

| Sheet | Purpose |
|---|---|
| Dashboard | Selected IDs, prices, initial SOEs, mode, fuel tank, warnings, summary |
| Battery_Catalog | Two-pack energy, voltage, power, efficiency, SOE, regen, mass, chemistry variants |
| Motor_Catalog | Hub motor power, torque, speed, efficiency, voltage, ratio compatibility |
| Genset_Catalog | Engine-generator ratings, stable/optimum points, timers, ramp, fuel, mass |
| Engine_Catalog | Twelve synthetic engine variants |
| Generator_Catalog | Twelve synthetic generator variants |
| Engine_Fuel_Map | Normalized load to BSFC |
| Generator_Efficiency_Map | Normalized load to generator efficiency |
| Tyre_Catalog | Loaded radius, rolling resistance, load capability |
| Final_Drive_Catalog | Ratio and directional efficiency |
| Bus_Mass_Catalog | Legacy/reference total-mass variants from 19,000 to 60,000 kg; the app now calculates mass from the 15-tonne base curb, installed hardware, and editable load |
| Vehicle_Parameters | Gravity, aero, tank, charger, filter, tolerance, sample time |
| Aux_Load_Profiles | Base and temperature-sensitive auxiliary loads |
| Route_Catalog | Route display name, type, region, source, version, licence, statistics, and enable flag |
| Route_Time_Speed | Long-format time route, grade, dwell, auxiliary multiplier |
| Route_Distance_Speed | Distance-domain equivalent route |
| Route_Grade | Distance/grade profile |
| Environment | Temperature, density, headwind |
| Control_Calibration | SOE thresholds, hysteresis/dwell, target SOE |
| Energy_Prices | Fuel/electricity prices and surplus-credit switch |
| Optimization_Settings | Bound, compatibility filter, terminal tolerance, method |
| Units_and_Definitions | Central term and unit definitions |
| Change_Log | Database version history |

All component sheets use unique IDs and `OptimizationEnabled`; numeric column names carry units.
The app presents initial battery SOE in percent but converts it to the model's internal fraction at
the app/model boundary. Energy prices use `EUR/L` and `EUR/kWh`.
