# Parameter Dictionary

| Area | Principal parameters | Source |
|---|---|---|
| Vehicle | mass, gravity, Cd, frontal area, Crr | Mass/Tyre/Vehicle sheets |
| Route | time, speed, grade, dwell, auxiliary multiplier | Route sheets |
| Hub drive | wheel radius, ratio, directional drive efficiency, torque/power/speed limits | Tyre/Final Drive/Motor sheets |
| Battery | usable energy, initial/min/max SOE, charge/discharge efficiency, regen acceptance | Per-battery MATLAB file + Dashboard |
| Battery dynamic maps | charge/discharge current limits and resistance versus SOE/temperature; open-circuit voltage versus SOC/temperature | Per-battery MATLAB file; synthetic LFP concept envelope; SOC uses the SOE proxy |
| Genset | optimum/max power, minimum times, BSFC, generator efficiency, fuel density | Genset/maps |
| Supervisor | fixed 30% role threshold, standby upper-SOE target, regeneration redirect | Architecture rule + Control sheet |
| Cost/range | fuel tank, fuel/electric prices, grid efficiency, terminal method/tolerance | Dashboard/Vehicle/Price/Optimization sheets |
| Performance driver | proportional speed gain, acceleration/deceleration bounds, stop approach and dwell thresholds | `Input.Performance` calibration in `prepare_hybrid_bus_inputs` |
| Performance feasibility | low-speed force protection, minimum regen speed, speed tolerance, stall time/force margin, route-completion distance tolerance, maximum duration | `Input.Performance` calibration in `prepare_hybrid_bus_inputs` |
| Constrained formulation | two acceleration-suppression passes, one final backward energy pass, original route-time horizon, 99.5% concept completion threshold | Fixed algorithm design in `simulate_hybrid_bus_constrained`; common driver/limit calibrations from `Input.Performance` |

The loader resolves all component IDs to scalar parameter structures. `assign_hybrid_bus_model_workspace` publishes only stable, unit-suffixed values required by the SLX.
