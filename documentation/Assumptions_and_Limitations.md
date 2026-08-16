# Assumptions and Limitations Register

| ID | Assumption / limitation | Consequence |
|---|---|---|
| A01 | Backward-facing prescribed speed; no driver or speed-tracking dynamics | Calculates required energy, not achievable closed-loop velocity |
| A02 | Two identical selected hub motors share demand equally | No left/right fault or torque-vectoring behavior |
| A03 | Energy-based batteries; SOE is primary state | No terminal voltage/current transient or thermal network |
| A04 | Synthetic scalar/map efficiencies | Replace with validated supplier maps for design decisions |
| A05 | Road grade angle uses `atan(grade/100)` in the detailed kernel | Consistent for ordinary road grades |
| A06 | One battery alone supplies traction residual | Conservative active-pack power sizing; matches architecture requirement |
| A07 | Genset fuel uses BSFC and generator maps with bounded interpolation | Concept fuel estimate, not emissions certification |
| A07a | Genset is electrically isolated from traction and runs at constant optimum power only while charging standby | Active battery and motor sizing cannot count genset power; rejected charge is explicit |
| A07b | Active-to-standby role threshold is fixed at 30% SOE | Alternate pack must be above 30% to prevent chattering when both packs are low |
| A08 | Terminal battery surplus receives no credit by default | Prevents artificial negative grid cost |
| A09 | Fuel-supported range with zero observed genset use is estimated at optimum genset point | Finite, documented extrapolation rather than infinite range |
| A10 | Fixed 1 s default step and 0.3 s acceleration filter | Appropriate for route energy, not electrical controls |
| A11 | Official VECTO distance cycles are converted to deterministic 1 Hz histories with bounded acceleration/deceleration and explicit stops | Suitable for backward energy studies; the converted time history is not an official VECTO certification result |
| A12 | OSM/OSRM long-route annotations are capped at 100 km/h and include a 45-minute stop after each 4.5-hour driving block | Geographic corridor and routed duration are preserved; trace is estimated rather than measured telemetry |
| L01 | No thermal derating dynamics, ageing, aftertreatment, slip, lateral, or driveline compliance | Out of concept energy-analysis scope |
| L02 | UIFigure app is delivered as source `.m` instead of binary `.mlapp` | Fully editable/run in R2025a; uses public App Designer-compatible components |
| L03 | VECTO Urban, Suburban, and Coach cycles are representative EU missions, not GPS traces of named German routes | Appropriate European/German regulatory context, but not a timetable or geographic route study |
| L04 | OSRM annotations contain no elevation, so long-route grade is set to zero | Mountain corridors will understate climbing energy and regeneration; add elevation before detailed design use |
| A13 | Battery-electric and conventional-diesel comparisons use transparent analytical screening assumptions | Appropriate for architecture discussion only; replace with calibrated reference-vehicle models for investment decisions |
| A14 | Sensitivity results are deterministic one-at-a-time perturbations | They show local decision robustness but are not probability distributions or confidence intervals |
| L05 | MATLAB and Simulink currently fail the declared signal-level equivalence gate | Reconcile wheel/motor transients, battery SOEs, genset scheduling, fuel, and energy residual before claiming equivalent implementations |
| L06 | No validated supplier maps or measured CAN/GPS/dynamometer dataset is available | The model is verified at concept level but is not calibrated or vehicle-validated |
| L07 | No forward-facing driver, thermal network, ageing model, or formal fault analysis is implemented | Achievable speed tracking, thermal endurance, lifetime, and safety claims remain outside the valid decision boundary |
