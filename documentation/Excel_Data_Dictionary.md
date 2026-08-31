# Excel Data Dictionary

| Sheet | Purpose |
|---|---|
| Dashboard | Selected IDs, prices, initial SOEs, mode, fuel tank, warnings, summary |
| Tyre_Catalog | Loaded radius, rolling resistance, load capability |
| Final_Drive_Catalog | Ratio and directional efficiency |
| Bus_Mass_Catalog | Legacy/reference total-mass variants from 19,000 to 60,000 kg; the app now calculates mass from the 15-tonne base curb, installed hardware, and editable load |
| Vehicle_Parameters | Gravity, aero, tank, charger, filter, tolerance, sample time |
| Aux_Load_Profiles | Base and temperature-sensitive auxiliary loads |
| Environment | Temperature, density, headwind |
| Control_Calibration | SOE thresholds, hysteresis/dwell, target SOE |
| Energy_Prices | Fuel/electricity prices and surplus-credit switch |
| Optimization_Settings | Bound, compatibility filter, terminal tolerance, method |
| Units_and_Definitions | Central term and unit definitions |
| Change_Log | Database version history |

All component sheets use unique IDs and `OptimizationEnabled`; numeric column names carry units.
The app presents initial battery SOE in percent but converts it to the model's internal fraction at
the app/model boundary. Energy prices use `EUR/L` and `EUR/kWh`.

## Route MAT-file database

Routes are not stored in the Excel workbook. Each route is stored independently in
`data/routes/<RouteID>.mat` as one `RouteData` structure with these fields:

| Field | Purpose |
|---|---|
| `SchemaVersion` | Per-route file schema version |
| `StorageOrder` | Stable ordering used by the app route dropdown |
| `Metadata` | One-row route catalog table with name, type, region, source, licence, statistics, and endpoints |
| `TimeSpeed` | Time, speed, grade, stop flag, and auxiliary multiplier used by simulation |
| `DistanceSpeed` | Distance-domain speed, grade, station flag, and auxiliary multiplier |
| `Grade` | Distance/grade profile |
| `Geometry` | Ordered latitude, longitude, cumulative distance, elevation, and provenance; empty for non-geographic cycles |

`load_hybrid_bus_database` validates and combines these files into the legacy in-memory
`Route_Catalog`, `Route_Time_Speed`, `Route_Distance_Speed`, `Route_Grade`, and
`Route_Geometry` tables used by the rest of the project.

## Battery and motor MATLAB-file database

Battery and motor catalogs are not stored in Excel. Each selectable component is a
human-readable MATLAB data script:

- `data/batteries/BAT_01.m` populates one versioned `BatteryData` structure whose `ComponentID` remains `BAT-01`.
- `data/motors/MOT_01.m` populates one versioned `MotorData` structure whose `ComponentID` remains `MOT-01`.

Each structure contains `SchemaVersion`, `StorageOrder`, and a scalar `Component`
record. The component record uses the same field names and units as the former
catalog row. `load_hybrid_bus_database` validates the scripts and rebuilds the
in-memory `Battery_Catalog` and `Motor_Catalog` tables used by the application,
optimizer, compatibility filter, mass calculation, and simulation.

Component files are discovered recursively, so add-ons may be organized in
subfolders. `StorageOrder` is optional for user additions; files without it are
placed after explicitly ordered components and sorted by ComponentID. Valid IDs
start with a letter and may contain letters, digits, dots, underscores, and
hyphens. IDs are not restricted to a numeric series.

Battery files use schema 4.0.0 and additionally contain two-dimensional maps
whose rows are battery temperature and whose columns are SOE:

| Field | Unit | Purpose |
|---|---|---|
| SOEBreakpoints | fraction | Stored-energy lookup axis from 0.10 to 0.95 |
| TemperatureBreakpoints_C | degC | Temperature lookup axis from -20 to 50 degC |
| MaxDischargeCurrentMap_A | A | Maximum terminal discharge current versus SOE and temperature |
| MaxChargeCurrentMap_A | A | Maximum accepted charging current versus SOE and temperature |
| SOCBreakpoints | 1 | State-of-charge axis used by the OCV map; equal to SOE at this concept-model fidelity |
| OpenCircuitVoltageMap_V | V | Pack open-circuit voltage versus SOC and temperature |
| InternalResistanceMap_Ohm | ohm | First-order pack internal resistance |
| MapBasis | text | Data provenance and calibration status |

The power maps derate cold operation and both SOE extremes. Charging is disabled
at -20 degC in this concept dataset and tapers to zero at the upper SOE breakpoint.
Resistance rises at cold temperature and near the lower and upper SOE limits. These
are synthetic feasibility envelopes, not supplier-characterized production data.

Motor files use schema 2.0.0 and contain a per-motor torque-speed loss map:

| Field | Unit | Purpose |
|---|---|---|
| TorqueBreakpoints_Nm | N m | Absolute motor-shaft torque lookup axis |
| SpeedBreakpoints_rpm | rpm | Absolute motor-shaft speed lookup axis |
| MotorLossMap_kW | kW | Per-motor conversion loss; rows are speed and columns are torque |
| MapBasis | text | Map orientation, units, provenance, and calibration status |

The application interpolates this map bilinearly. For the two-motor axle, the
per-motor loss is multiplied by two and added to shaft power in motoring; in
regeneration it reduces the DC power returned to the traction bus.

## Genset MATLAB-file database

Genset assemblies are not stored in Excel. Each selection has one self-contained,
human-readable MATLAB data script, for example `data/gensets/GEN_01.m` for the
internal ID `GEN-01`. Every `GensetData` structure contains:

- `SchemaVersion` and `StorageOrder`;
- the complete `Genset` assembly record;
- its matching `Engine` record (`ENG-xx`);
- its matching `Generator` record (`GNR-xx`);
- its normalized `EngineFuelMap` from engine load to BSFC; and
- its normalized `GeneratorEfficiencyMap` from generator load to efficiency.

The loader validates map schemas, unique IDs, file counts, and explicit assembly
links derived from the three records in each file. Genset, engine, and generator
IDs do not require matching suffixes. It rebuilds the existing in-memory genset,
engine, generator, assembly-link, and map tables. At
simulation preparation, only the two maps owned by the selected genset are passed
to the MATLAB and Simulink models.
