# HybridBusProject

Concept-level, backward-facing hybrid-electric bus energy model for route energy, diesel fuel, grid-equivalent electrical energy, operating cost, range, and bounded configuration comparison.

Component catalog values are synthetic engineering data and are not manufacturer claims. The
Urban, Suburban, and Coach mission profiles are official European Commission VECTO inputs. Eight
long European corridors and nine German city circuits use OpenStreetMap road data routed through
Project OSRM. The named geographic routes retain source and license metadata; their speed histories
remain deterministic engineering adaptations rather than measured bus telemetry.

## Software

- Developed and verified with MATLAB R2025a and Simulink R2025a.
- Functional model uses MATLAB, basic Simulink, standard Simulink blocks, and `uifigure` components only.
- No runtime dependency on Simscape, Stateflow, Powertrain Blockset, Vehicle Dynamics Blockset, Optimization Toolbox, Statistics Toolbox, Parallel Computing Toolbox, third-party libraries, or compiled S-functions.

## Quick start

```matlab
cd('C:\TempData\Hybrid_Vehicle\HybridBusProject')
addpath(fullfile(pwd,'project'))
project = startup_hybrid_bus;
Results = run_hybrid_bus_simulation;
open_system('HybridBus_BackwardModel')
app = HybridBusApp;
```

The Powertrain Architecture switch selects Hybrid or BEV operation. The BEV
alternative also has its own editable Simulink model:

```matlab
open_system('HybridBus_BEVModel')
[bevOutput, bevInput] = run_bev_simulink_model;                % 1 set = two packs, 85%
[bevOutput, bevInput] = run_bev_simulink_model("",0.5,0.85);  % 0.5 set = one pack
[bevOutput, bevInput] = run_bev_simulink_model("",1.5,0.85);  % 1.5 sets = three packs
```

The **Battery set multiplier** defaults to 1. Hybrid mode accepts positive whole
sets; every set adds one pack to the active bank and one pack to the standby bank.
BEV mode accepts 0.5-set increments, with two packs per set. Therefore 0.5, 1.0,
1.5, and 2.0 sets mean one, two, three, and four connected packs. When the total is
odd, the additional pack uses the Battery-1 selection. All connected BEV packs have
the same starting SOE and share DC power within their bank capabilities. Genset
power and fuel use remain zero in BEV mode.

In the app, choose a route and configuration, enter both initial battery SOEs in percent, then
press **Run Manual Case**. Fuel and electricity prices are entered in `EUR/L` and `EUR/kWh`.
The total-vehicle-mass selector provides 12 variants spanning 19,000 to 60,000 kg. Signals and
Detailed Plot provide synchronized **Time / Distance** switches. Time uses minutes for missions
shorter than two hours and hours for longer missions; Distance uses cumulative kilometres. The
simulation kernel continues to calculate in seconds and metres internally.

The **Route Map** keeps its geographic 2D view and reveals an **Elevation / Slope**
switch when 3D is selected. Elevation is displayed in metres; slope is displayed in percent and
is derived from successive elevation change divided by geographic path-distance change. Every
slider-style switch highlights its selected side in blue and its unselected side in gray.

Every component in the **Powertrain Architecture** tab is clickable. Its non-modal
specification window shows the selected catalog values, component role, units, control rules,
and concept-model limitations. Configuration selections are resolved when the block is clicked.

Run optimization:

```matlab
Optimization = optimize_hybrid_bus_configuration( ...
    fullfile("data","HybridBus_ComponentDatabase.xlsx"), ...
    Vary=["Battery1","Motor","Genset","FinalDrive"], ...
    MaxConfigurations=100);
```

Run verification:

```matlab
TestResults = run_all_hybrid_bus_tests;
```

Generate the complete model-credibility evidence package:

```matlab
Credibility = generate_model_credibility_report;
```

This regenerates the behavioral test report, requirements traceability matrix, MATLAB-Simulink
equivalence assessment, concept baselines, sensitivity study, and the data used by the app's
**Model Credibility** tab. A failed or unavailable gate is intentionally retained in the report.

## Project layout

Only `HybridBusApp.m` is kept as the user-facing root file. MATLAB Project and
Git metadata remain at the root because those tools require them there.

| Folder | Contents |
|---|---|
| `src/` | Simulation, optimization, route, reporting, and utility functions |
| `models/` | Hybrid and BEV Simulink models |
| `data/` | Engineer-editable Excel database |
| `project/` | MATLAB Project startup utility |
| `tests/` | Behavioral and integration tests |
| `documentation/` | README, design plan, reports, screenshots, and route provenance |
| `results/`, `output/` | Generated study results and released documents |

## Main files

| File | Responsibility |
|---|---|
| `data/HybridBus_ComponentDatabase.xlsx` | Engineer-editable master inputs, selectors, routes, maps, prices, and calibrations |
| `src/convert_vecto_distance_cycle.m` | Deterministic conversion of official distance-domain VECTO cycles to 1 Hz route inputs |
| `src/download_europe_long_routes.m` | Reproducible retrieval and provenance capture for OSM/OSRM long routes |
| `src/convert_osrm_coach_route.m` | Coach-profile adaptation of OSM/OSRM segment annotations, including EU driver breaks |
| `src/build_route_elevation_cache.m` | Reproducible Copernicus DEM GLO-90 elevation cache for the Route Map's 3D view |
| `models/HybridBus_BackwardModel.slx` | Editable fixed-step Simulink system model with ten top-level subsystems |
| `models/HybridBus_BEVModel.slx` | Editable fixed-step BEV model with parallel battery control and no genset |
| `src/run_bev_simulink_model.m` | Database-backed half-set BEV Simulink runner for one or more parallel packs |
| `HybridBusApp.m` | R2025a programmatic App Designer-compatible UIFigure app |
| `src/simulate_hybrid_bus_core.m` | Detailed discrete first-principles simulation used by batch runs and optimization |
| `src/run_hybrid_bus_simulation.m` | Validate, prepare, simulate, and save a selected case |
| `src/optimize_hybrid_bus_configuration.m` | Compatibility-filtered bounded enumeration using base MATLAB loops |
| `tests/run_all_hybrid_bus_tests.m` | Twenty-nine assertion-based hybrid/BEV physics, battery-set, isolation, control, limit, and ranking scenarios |
| `src/generate_model_credibility_report.m` | Release evidence orchestration and synchronized Markdown/CSV/MAT reports |
| `src/assess_matlab_simulink_equivalence.m` | Signal-level independent implementation comparison with declared tolerances |
| `src/compare_powertrain_concepts.m` | Transparent hybrid, battery-electric, and conventional-diesel concept screening |
| `src/run_hybrid_bus_sensitivity_study.m` | Deterministic one-at-a-time uncertainty screening |

The requested `.mlapp` binary is delivered as the documented R2025a fallback `HybridBusApp.m`. It provides the required UIFigure/App Designer behavior while remaining source-controllable and directly editable. No optional product is required.

## Workbook workflow

The `Dashboard` is the first sheet. Yellow cells are user inputs. Component and mode cells have validation lists. Each catalog is an Excel table with filters and frozen headers. To replace the workbook, preserve the required sheet and column names and run:

```matlab
db = load_hybrid_bus_database("MyDatabase.xlsx");
report = validate_hybrid_bus_database(db);
assert(report.IsValid, strjoin(report.Errors,newline));
```

Add a component by copying a catalog row, assigning a unique `ComponentID`, updating ratings/units/notes, and setting `OptimizationEnabled`. Add a route to `Route_Catalog`, then append rows with the same new `RouteID` and strictly increasing route-local time. Raw VECTO inputs and OSM/OSRM route snapshots with provenance are retained in `documentation/reference_routes`.

## Backward model

The route prescribes speed. A filtered finite difference (`tau = 0.3 s`) produces acceleration. The model computes inertia, rolling, grade, and aerodynamic forces, then wheel power. Two rear hub motors share wheel demand. Torque-speed, peak-power, maximum-speed, fixed-drive efficiency, regeneration, and battery acceptance limits are applied before DC demand is calculated.

Auxiliaries are active at zero speed and combine the catalog base load, route multiplier, user scalar, and ambient-sensitive HVAC load.

The detailed supervisory kernel enforces one traction-discharging battery at a time. The active pack changes role at 30% SOE when the alternate pack is ready. The genset is isolated from the traction bus, runs only at its selected best-efficiency power, and keeps charging only the standby pack until that pack reaches its upper SOE limit or becomes active. Regeneration, rejected charge, and unmet traction power are accounted independently.

## Sign convention

- `P_wheel > 0`: traction; `P_wheel < 0`: braking.
- `P_battery > 0`: pack discharges to the DC bus; `P_battery < 0`: pack charges.
- `P_genset > 0`: genset supplies the isolated standby charger only.
- `P_aux > 0`: electrical demand.

The traction and charger nodes are checked separately in the control design:

```text
P_active - P_motor_dc - P_aux + P_unmet = 0
P_genset + P_standby - P_rejected_charge = 0
```

The reported project-boundary balance is their sum:

```text
P_genset + P_battery1 + P_battery2 - P_motor_dc - P_aux
+ P_unmet - P_rejected_charge = P_residual
```

## Cost and comparison

Fuel cost is litres times the `EUR/L` price. Electrical cost uses the terminal battery deficit,
grid-charge efficiency, and `EUR/kWh` price. Terminal surplus is not credited. The primary KPI is
total operating cost in EUR divided by route distance.

`evaluate_hybrid_bus_comparison` supports equivalent-replenishment and charge-sustaining comparison. The optimizer rejects incompatible or constraint-violating cases before ranking feasible cases by cost/km.

## Results

Every saved run creates a timestamped MAT file containing `Results.Metadata`, `SelectedConfiguration`, `InputParameters`, `Route`, `Time`, grouped `Signals`, `Summary`, and `Validation`, plus a summary CSV. Optimization exports all evaluated cases, the top ten, and the complete optimization structure.

## Naming conventions

Signals use physical prefixes (`P_`, `E_`, `v_`, `a_`, `SOE_`, `eta_`); controller states use `active_` or `mode`; centralized model workspace parameters use descriptive lowercase names with unit suffixes. Simulink blocks use meaningful code-generation-safe names and deterministic sample times.

## Validation status

- MATLAB kernel: 23/23 automated scenarios pass, including regeneration priority, route geolocation, genset-to-traction isolation, and constant optimum-power checks.
- Database: valid with zero errors and zero warnings.
- Requirements traceability: PASS for the documented concept-level requirements.
- MATLAB-Simulink equivalence: FAIL at the current declared signal tolerances. Speed and auxiliary demand agree; wheel/motor transients, battery SOEs, genset scheduling, fuel, and balance residual require reconciliation.
- Supplier-data calibration and measured-vehicle validation: NOT AVAILABLE. Catalog values are synthetic and no CAN/GPS/dynamometer dataset has been supplied.
- App smoke test: percentage SOE labels, EUR price units, all 20 route selections, conditional 2D/3D and Elevation/Slope Route Map switching, blue/gray state styling on all switches, and specification pop-ups for all 15 architecture blocks verified.
- Plot x-axis selection: Time/Distance tests pass 4/4, the two tab switches remain synchronized, and all ten Detailed Plot selections redraw against cumulative distance. Adaptive minute/hour boundary tests also pass 3/3.
- Route terrain display: all 20,257 geographic coordinate samples have finite, traceable elevations; derived display slopes are finite for every route. Elevation tests pass 3/3 and slope tests pass 4/4.
- Model Credibility tab: verified at the normal app size with explicit PASS, FAIL, NOT AVAILABLE, and NOT IMPLEMENTED gates.

## Known limitations

This is a concept energy model: no electrical transients, thermal network, ageing, emissions aftertreatment, wheel slip, lateral dynamics, detailed engine warm-up emissions, or predictive route controller. Efficiency maps are synthetic and intentionally compact. VECTO cycles are representative EU regulatory mission profiles, not GPS traces of named German services. Long-route speed/duration values are OSM/OSRM routing estimates. Geographic routes include cached Copernicus DEM GLO-90 elevation and derived slope for the app's 3D visualization, but simulation grade remains zero because no road-aligned, validated grade trace has been introduced into the energy model. Fuel-supported range when a route never starts the genset is estimated at its optimum operating point and is explicitly finite.
