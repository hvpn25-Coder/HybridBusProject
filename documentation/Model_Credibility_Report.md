# Model Credibility Report

Generated: 31-Aug-2026 06:51:00
Database version: 1.8.0

This report distinguishes verified concept behavior, implementation equivalence, and measured-vehicle validation. A PASS at one level does not imply a PASS at a higher level.

## Credibility gates

| Gate | Status | Evidence | Decision |
|---|---|---|---|
| Requirements traceability | PASS | Requirement-equation-signal-test matrix | Release evidence is traceable |
| Physics and control verification | PASS | 50 automated behavioral scenarios | Concept behavior verified |
| MATLAB-Simulink equivalence | PASS | Signal-level independent implementation comparison | Independent Hybrid and BEV implementations agree within declared tolerances; do not infer measured-vehicle validation |
| Uncertainty screening | PASS | Deterministic one-at-a-time parameter study | Use ranges for decision robustness, not statistical confidence |
| Concept baseline comparison | PASS | Hybrid result plus transparent BEV and diesel screening equations | Suitable for concept screening, not procurement |
| Supplier-data calibration | NOT AVAILABLE | Synthetic catalog values only | Obtain validated supplier maps |
| Measured-vehicle validation | NOT AVAILABLE | No CAN/GPS/dynamometer dataset supplied | Collect vehicle measurements and define validation tolerances |
| Forward-facing feasibility | PASS | 6 forward performance and Simulink structure scenarios | Use achieved-speed, gradeability, completion, and stall KPIs for concept screening |
| Fast constrained feasibility | PASS | 5 fast constrained acceleration/terrain/depletion scenarios | Use for rapid screening; retain Performance mode for detailed mission closure |
| Thermal and ageing validation | NOT IMPLEMENTED | Energy-state model only | Add dynamic battery temperature and degradation states |
| Safety and fault analysis | NOT IMPLEMENTED | Architecture rules and nominal tests only | Perform FMEA/STPA and fault-injection verification |

## Independent implementation equivalence

| Powertrain | Signal | MaxAbsoluteError | RMSError | Tolerance | Unit | Status |
|---|---|---|---|---|---|---|
| Hybrid | Vehicle speed | 0 | 0 | 0.02 | m/s | PASS |
| Hybrid | Wheel demand | 1.1369e-13 | 1.0779e-14 | 5 | kW | PASS |
| Hybrid | Motor DC power | 0.18133 | 0.0026207 | 8 | kW | PASS |
| Hybrid | Pneumatic friction brake | 0 | 0 | 5 | kW | PASS |
| Hybrid | Auxiliary power | 0 | 0 | 0.05 | kW | PASS |
| Hybrid | Battery 1 SOE | 4.328e-07 | 2.7036e-07 | 0.025 | fraction | PASS |
| Hybrid | Battery 2 SOE | 2.2204e-16 | 3.4425e-17 | 0.025 | fraction | PASS |
| Hybrid | Genset power | 0 | 0 | 1 | kW | PASS |
| Hybrid | Total fuel | 0.054545 | 0.054545 | 0.1 | L | PASS |
| Hybrid | Energy-balance integral | 0 | 0 | 0.01 | kWh | PASS |
| BEV | Vehicle speed | 0 | 0 | 0.02 | m/s | PASS |
| BEV | Wheel demand | 1.1369e-13 | 1.031e-14 | 5 | kW | PASS |
| BEV | Motor DC power | 0.17295 | 0.0024994 | 8 | kW | PASS |
| BEV | Pneumatic friction brake | 0 | 0 | 5 | kW | PASS |
| BEV | Auxiliary power | 0 | 0 | 0.05 | kW | PASS |
| BEV | Battery 1 SOE | 2.0638e-07 | 1.2892e-07 | 0.025 | fraction | PASS |
| BEV | Battery 2 SOE | 2.0638e-07 | 1.2892e-07 | 0.025 | fraction | PASS |
| BEV | Genset power | 0 | 0 | 1 | kW | PASS |
| BEV | Total fuel | 0 | 0 | 0.1 | L | PASS |
| BEV | Energy-balance integral | 0 | 0 | 0.01 | kWh | PASS |

## Powertrain concept screening

| Concept | Fuel_L | GridEnergy_kWh | OperatingCost_EUR | Cost_EUR_per_km | SourceEnergy_kWh_per_km | EvidenceLevel |
|---|---|---|---|---|---|---|
| Proposed dual-battery hybrid | 71.5584 | 66.0602 | 176.6966 | 4.4411 | 9.0626 | Implemented model |
| Battery-electric screening baseline | 0 | 62.7175 | 25.087 | 0.63053 | 1.5763 | Analytical screening |
| Conventional-diesel screening baseline | 23.7304 | 0 | 49.8338 | 1.2525 | 5.8451 | Analytical screening |

## Sensitivity screening

| Parameter | Perturbation_pct | LowCost_EUR_per_km | HighCost_EUR_per_km | CostSwing_pct | LowEnergy_kWh_per_km | HighEnergy_kWh_per_km | EnergySwing_pct |
|---|---|---|---|---|---|---|---|
| Auxiliary-load scalar | 20 | 4.3968 | 4.4854 | 1.996 | 8.9518 | 9.1734 | 2.4453 |
| Total vehicle mass | 10 | 4.409 | 4.4735 | 1.4507 | 8.9825 | 9.1436 | 1.7773 |
| Rolling resistance coefficient | 10 | 4.4264 | 4.4557 | 0.66115 | 9.0259 | 9.0993 | 0.80998 |
| Aerodynamic drag coefficient | 10 | 4.4314 | 4.4508 | 0.4376 | 9.0383 | 9.0869 | 0.53611 |
| Motor motoring efficiency | 3 | 4.4411 | 4.4411 | 0 | 9.0626 | 9.0626 | 0 |
| Battery discharge efficiency | 3 | 4.469 | 4.4176 | -1.1576 | 9.1324 | 9.0039 | -1.4182 |

## Interpretation boundary

The current project is a verified concept energy model. It is not yet calibrated to supplier hardware or validated against measured vehicle telemetry. Screening baselines and sensitivity results support architecture decisions only.
