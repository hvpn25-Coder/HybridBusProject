# Assumptions and Limitations Register

| ID | Assumption / limitation | Consequence |
|---|---|---|
| A01 | The user selects Backward, Constrained, or Performance formulation | Backward calculates prescribed-speed energy; Constrained provides a fast fixed-time achievable-speed screening; Performance performs the detailed forward mission calculation |
| A01a | The forward driver is a bounded proportional speed controller, and route grade/auxiliary demand are indexed by actual travelled distance | Suitable for concept gradeability and mission-completion screening; it is not a calibrated human-driver or predictive cruise-control model |
| A01b | Forward speed and distance are constrained nonnegative; sustained inability to overcome road load declares a stall and leaves the route incomplete | No artificial rollback or route completion is credited, but reverse motion and hill-hold dynamics are outside scope |
| A01c | Constrained mode performs two acceleration-suppression passes plus a final backward energy pass over the original route-time horizon | It is materially faster than Performance mode and captures current/torque/force/depletion speed shortfalls, but it is an iterative quasi-forward approximation rather than a continuous closed-loop plant |
| A01d | Constrained mode considers 99.5% distance coverage a completed concept mission | Avoids rejecting numerically small startup-lag shortfalls; detailed timetable compliance should use Performance mode and explicit speed-error limits |
| A02 | Two identical selected hub motors share demand equally | No left/right fault or torque-vectoring behavior |
| A02a | Each motor uses a bilinear loss map indexed by absolute shaft torque and speed | Built-in maps are feasible concept data; replace with dynamometer maps for design sign-off |
| A03 | Energy-based batteries with first-order SOC- and temperature-dependent open-circuit voltage and SOE/temperature-dependent resistance | Terminal voltage/current and ohmic loss are estimated, but polarization transients are not represented |
| A03a | The energy-based state is used as an SOC proxy for OCV lookup, so SOC = SOE in the present concept model | Replace with coulomb-counted SOC and capacity/aging states when calibrated cell data becomes available |
| A04 | Synthetic scalar/map efficiencies | Replace with validated supplier maps for design decisions |
| A05 | Road grade angle uses `atan(grade/100)` in the detailed kernel | Consistent for ordinary road grades |
| A06 | One battery alone supplies traction residual | Conservative active-pack power sizing; matches architecture requirement |
| A07 | Genset fuel uses BSFC and generator maps with bounded interpolation | Concept fuel estimate, not emissions certification |
| A07a | Genset is electrically isolated from traction and runs at constant optimum power only while charging standby | Active battery and motor sizing cannot count genset power; rejected charge is explicit |
| A07b | Active-to-standby role threshold is fixed at 30% SOE | Alternate pack must be above 30% to prevent chattering when both packs are low |
| A07c | Battery charge/discharge current limits, OCV, and internal resistance use synthetic LFP maps versus SOE and temperature; terminal power is derived with a first-order Thevenin relation | Suitable for feasibility screening only; replace with supplier OCV characterization and HPPC/pulse-test maps before design release |
| A07d | Selected ambient temperature is used as battery temperature | Cold/hot derating is represented, but thermal mass, coolant dynamics, self-heating, ageing, and cell gradients are not |
| A08 | Terminal battery surplus receives no credit by default | Prevents artificial negative grid cost |
| A09 | Fuel-supported range with zero observed genset use is estimated at optimum genset point | Finite, documented extrapolation rather than infinite range |
| A10 | Fixed 1 s default step and 0.3 s acceleration filter | Appropriate for route energy, not electrical controls |
| A11 | Official VECTO distance cycles are converted to deterministic 1 Hz histories with bounded acceleration/deceleration and explicit stops | Suitable for backward energy studies; the converted time history is not an official VECTO certification result |
| A12 | OSM/OSRM long-route annotations are capped at 100 km/h and include a 45-minute stop after each 4.5-hour driving block | Geographic corridor and routed duration are preserved; trace is estimated rather than measured telemetry |
| L01 | No thermal derating dynamics, ageing, aftertreatment, slip, lateral, or driveline compliance | Out of concept energy-analysis scope |
| L02 | UIFigure app is delivered as source `.m` instead of binary `.mlapp` | Fully editable/run in R2025a; uses public App Designer-compatible components |
| L03 | VECTO Urban, Suburban, and Coach cycles are representative EU missions, not GPS traces of named German routes | Appropriate European/German regulatory context, but not a timetable or geographic route study |
| L04 | OSRM annotations contain no elevation. Copernicus DEM GLO-90 heights are now cached for the 3D Route Map, but the simulation-grade channel remains zero | Mountain corridors still understate climbing energy and regeneration; derive and validate a road-aligned grade trace before detailed design use |
| A13 | Battery-electric and conventional-diesel comparisons use transparent analytical screening assumptions | Appropriate for architecture discussion only; replace with calibrated reference-vehicle models for investment decisions |
| A14 | Sensitivity results are deterministic one-at-a-time perturbations | They show local decision robustness but are not probability distributions or confidence intervals |
| L05 | MATLAB and Simulink currently fail the declared signal-level equivalence gate | Reconcile wheel/motor transients, battery SOEs, genset scheduling, fuel, and energy residual before claiming equivalent implementations |
| L06 | Motor temperature and inverter switching dynamics are not modeled | The loss map is quasi-static and has no thermal derating or transient loss state |
| L06 | No validated supplier maps or measured CAN/GPS/dynamometer dataset is available | The model is verified at concept level but is not calibrated or vehicle-validated |
| L07 | A concept forward-facing driver and longitudinal plant are implemented, but no tyre-adhesion envelope, hill-hold transient, calibrated brake pressure dynamics, thermal network, ageing model, or formal fault analysis is included | Achievable-speed screening is available; detailed handling, stopping-distance certification, thermal endurance, lifetime, and safety claims remain outside the valid decision boundary |
