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
project = startup_hybrid_bus;
Results = run_hybrid_bus_simulation;
open_system('HybridBus_BackwardModel.slx')
app = HybridBusApp;
```

In the app, choose a route and configuration, enter both initial battery SOEs in percent, then
press **Run Manual Case**. Fuel and electricity prices are entered in `EUR/L` and `EUR/kWh`.
The total-vehicle-mass selector provides 12 variants spanning 19,000 to 60,000 kg.

Run optimization:

```matlab
Optimization = optimize_hybrid_bus_configuration( ...
    "HybridBus_ComponentDatabase.xlsx", ...
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

## Main files

| File | Responsibility |
|---|---|
| `HybridBus_ComponentDatabase.xlsx` | Engineer-editable master inputs, selectors, routes, maps, prices, and calibrations |
| `convert_vecto_distance_cycle.m` | Deterministic conversion of official distance-domain VECTO cycles to 1 Hz route inputs |
| `download_europe_long_routes.m` | Reproducible retrieval and provenance capture for OSM/OSRM long routes |
| `convert_osrm_coach_route.m` | Coach-profile adaptation of OSM/OSRM segment annotations, including EU driver breaks |
| `HybridBus_BackwardModel.slx` | Editable fixed-step Simulink system model with ten top-level subsystems |
| `HybridBusApp.m` | R2025a programmatic App Designer-compatible UIFigure app |
| `simulate_hybrid_bus_core.m` | Detailed discrete first-principles simulation used by batch runs and optimization |
| `run_hybrid_bus_simulation.m` | Validate, prepare, simulate, and save a selected case |
| `optimize_hybrid_bus_configuration.m` | Compatibility-filtered bounded enumeration using base MATLAB loops |
| `tests/run_all_hybrid_bus_tests.m` | Twenty-three assertion-based physics, isolation, control, limit, and ranking scenarios |
| `generate_model_credibility_report.m` | Release evidence orchestration and synchronized Markdown/CSV/MAT reports |
| `assess_matlab_simulink_equivalence.m` | Signal-level independent implementation comparison with declared tolerances |
| `compare_powertrain_concepts.m` | Transparent hybrid, battery-electric, and conventional-diesel concept screening |
| `run_hybrid_bus_sensitivity_study.m` | Deterministic one-at-a-time uncertainty screening |

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
- App smoke test: percentage SOE labels, EUR price units, and all 20 route selections verified.
- Model Credibility tab: verified at the normal app size with explicit PASS, FAIL, NOT AVAILABLE, and NOT IMPLEMENTED gates.

## Known limitations

This is a concept energy model: no electrical transients, thermal network, ageing, emissions aftertreatment, wheel slip, lateral dynamics, detailed engine warm-up emissions, or predictive route controller. Efficiency maps are synthetic and intentionally compact. VECTO cycles are representative EU regulatory mission profiles, not GPS traces of named German services. Long-route speed/duration values are OSM/OSRM routing estimates, and route grade is zero because elevation is not supplied. Fuel-supported range when a route never starts the genset is estimated at its optimum operating point and is explicitly finite.
