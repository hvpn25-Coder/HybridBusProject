# Model Credibility Report

Generated: 15-Aug-2026 20:19:43
Database version: 1.6.1

This report distinguishes verified concept behavior, implementation equivalence, and measured-vehicle validation. A PASS at one level does not imply a PASS at a higher level.

## Credibility gates

| Gate | Status | Evidence | Decision |
|---|---|---|---|
| Requirements traceability | PASS | Requirement-equation-signal-test matrix | Release evidence is traceable |
| Physics and control verification | PASS | 23 automated behavioral scenarios | Concept behavior verified |
| MATLAB-Simulink equivalence | FAIL | Signal-level independent implementation comparison | Resolve numerical differences before claiming implementation equivalence |
| Uncertainty screening | PASS | Deterministic one-at-a-time parameter study | Use ranges for decision robustness, not statistical confidence |
| Concept baseline comparison | PASS | Hybrid result plus transparent BEV and diesel screening equations | Suitable for concept screening, not procurement |
| Supplier-data calibration | NOT AVAILABLE | Synthetic catalog values only | Obtain validated supplier maps |
| Measured-vehicle validation | NOT AVAILABLE | No CAN/GPS/dynamometer dataset supplied | Collect vehicle measurements and define validation tolerances |
| Forward-facing feasibility | NOT IMPLEMENTED | Backward-facing prescribed-speed model | Add driver and speed-tracking dynamics |
| Thermal and ageing validation | NOT IMPLEMENTED | Energy-state model only | Add temperature, voltage, current, and degradation states |
| Safety and fault analysis | NOT IMPLEMENTED | Architecture rules and nominal tests only | Perform FMEA/STPA and fault-injection verification |

## Independent implementation equivalence

| Signal | MaxAbsoluteError | RMSError | Tolerance | Unit | Status |
|---|---|---|---|---|---|
| Vehicle speed | 0 | 0 | 0.02 | m/s | PASS |
| Wheel demand | 114.6263 | 13.9877 | 5 | kW | FAIL |
| Motor DC power | 129.966 | 22.4914 | 8 | kW | FAIL |
| Auxiliary power | 0 | 0 | 0.05 | kW | PASS |
| Battery 1 SOE | 0.16634 | 0.098364 | 0.025 | fraction | FAIL |
| Battery 2 SOE | 0.046517 | 0.020263 | 0.025 | fraction | FAIL |
| Genset power | 123.1818 | 23.1418 | 1 | kW | FAIL |
| Total fuel | 2.7561 | 2.7561 | 0.1 | L | FAIL |
| Energy-balance integral | 0.13105 | 0.65849 | 0.01 | kWh | FAIL |

## Powertrain concept screening

| Concept | Fuel_L | GridEnergy_kWh | OperatingCost_EUR | Cost_EUR_per_km | SourceEnergy_kWh_per_km | EvidenceLevel |
|---|---|---|---|---|---|---|
| Proposed dual-battery hybrid | 43.624 | 69.1757 | 84.4312 | 2.1221 | 5.8548 | Implemented model |
| Battery-electric screening baseline | 0 | 65.8907 | 11.8603 | 0.2981 | 1.6561 | Analytical screening |
| Conventional-diesel screening baseline | 23.9303 | 0 | 39.4851 | 0.99241 | 5.8943 | Analytical screening |

## Sensitivity screening

| Parameter | Perturbation_pct | LowCost_EUR_per_km | HighCost_EUR_per_km | CostSwing_pct | LowEnergy_kWh_per_km | HighEnergy_kWh_per_km | EnergySwing_pct |
|---|---|---|---|---|---|---|---|
| Auxiliary-load scalar | 20 | 2.1021 | 2.142 | 1.8815 | 5.7439 | 5.9657 | 3.7887 |
| Total vehicle mass | 10 | 2.1047 | 2.1398 | 1.6504 | 5.7584 | 5.953 | 3.3232 |
| Rolling resistance coefficient | 10 | 2.1154 | 2.1288 | 0.63421 | 5.8174 | 5.8922 | 1.2771 |
| Aerodynamic drag coefficient | 10 | 2.1177 | 2.1265 | 0.41578 | 5.8303 | 5.8793 | 0.83723 |
| Motor motoring efficiency | 3 | 2.1323 | 2.1125 | -0.93238 | 5.9114 | 5.8014 | -1.8775 |
| Battery discharge efficiency | 3 | 2.1348 | 2.1113 | -1.1074 | 5.9256 | 5.7951 | -2.2298 |

## Interpretation boundary

The current project is a verified concept energy model. It is not yet calibrated to supplier hardware or validated against measured vehicle telemetry. Screening baselines and sensitivity results support architecture decisions only.
